/*********************************************************************************************************************
Description: This batch process filters root certificates with Audit Update Status <> "Successful" and 
archives audit documents in File Archive object. These audit douments are download using meta data api.
Only unique document (external link) are saved in File archive and attached to associated CA Owner. 
Along with it Audit Type, Audit Date, Period Start Date, Period End Date are also copied. 
Audtior and Auditor Location are archived too. Except for Standard Audit Date all other audit fields are updated 
whenever they are modified. Blank values will not be copied to File Archive record.  

Data is processed in following ordeer - Standard Audit fields are updated last in File Archive
EV Code Signing Audit, EV SSL Audit, BR Audit & Standard Audit

When auditor and audit fields are modified, a workflow field update flips the Audit Update Status to "Not processed"
so that the next run of the batch process will pick the changed records.

This batch program could fail due to following reasons:
- Check the setting for MetsData API in Remote Site Setting
- Check the Audit link (the file will download only if it is downloadable)

This batch program also run for Intermediate certificates and check Audit urls. - 22 Dec 2017

This batch program assumes:
- If an audit file is used by multiple audit types and and multiple root certs then the audit dates must match on all records
*********************************************************************************************************************/

global class RunAuditArchiveBatch implements Database.Batchable<sObject>, Database.AllowsCallouts, Database.stateful {
    
    final String sessionId;
    List<File_Archive__c> lstFileArchive;
    
    Map<String, Set<String>> mapExternalUrlToDocTypes;
    Map<String, File_Archive__c> mapExistFileArchivesTosetPeriod;
    
    global RunAuditArchiveBatch(){
        
        this.sessionId = UserInfo.getSessionId();
        this.lstFileArchive = new List<File_Archive__c>();
        this.mapExternalUrlToDocTypes = new Map<String, Set<String>>();
        this.mapExistFileArchivesTosetPeriod = new Map<String, File_Archive__c>();
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC){
        
        //root certificate record type
        String rootCertRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Root Certificate').getRecordTypeId();
        
        //intermediate cert record type
        String IntermediateCertRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Intermediate Certificate').getRecordTypeId();
        
        //set of root and intermediate record types 
        set<Id> setRecordTypeIds = new set<Id>();
        setRecordTypeIds.add(rootCertRecordTypeId);
        setRecordTypeIds.add(IntermediateCertRecordTypeId);
        
        String soql = 'SELECT Id, ParentId, Name, CA_Owner_Id__c, Standard_Audit_Statement_Date__c, BR_Audit_Statement_Date__c, '+
        'Standard_Audit_Update_Status__c, EV_Audit_Statement_Date__c, BR_Audit_Update_Status__c, Standard_Audit__c, EV_Audit__c, '+
        'EV_Audit_Update_Status__c, BR_Audit__c, Standard_Audit_Statement_Internal_Link__c, RecordTypeId, '+
        'Standard_Audit_Period_Start_Date__c, Standard_Audit_Period_End_Date__c, ' + 
        'BR_Audit_Period_Start_Date__c, BR_Audit_Period_End_Date__c, ' + 
        'EV_Audit_Period_Start_Date__c, EV_Audit_Period_End_Date__c, ' + 
        'EV_Code_Signing_Audit_Period_Start_Date__c, EV_Code_Signing_Audit_Period_End_Date__c, ' + 
        'BR_Audit_Statement_Internal_Link__c, EV_Audit_Statement_Internal_Link__c, EV_Code_Signing_Audit_Statement_Date__c, '+
        'EV_Code_Signing_Audit__c, EV_Code_Signing_Audit_Update_Status__c, EV_Code_Signing_Audit_Stmt_Int_Link__c, ' +
        'Auditor_New__c, Auditor_New__r.Name, Auditor_Location_New__c, Auditor_Location_New__r.Name ' +
        'FROM Account '+
        'WHERE RecordTypeId in :setRecordTypeIds '+
        'and (Standard_Audit_Update_Status__c != \'Successful\' or BR_Audit_Update_Status__c != \'Successful\' ' +
        'or EV_Audit_Update_Status__c != \'Successful\' or EV_Code_Signing_Audit_Update_Status__c != \'Successful\')';
        
        
        /*
        //to test one particular account
        String soql = 'SELECT Id, ParentId, Name, Standard_Audit_Statement_Date__c, BR_Audit_Statement_Date__c, '+
        'Standard_Audit_Update_Status__c, EV_Audit_Statement_Date__c,BR_Audit_Update_Status__c, Standard_Audit__c, EV_Audit__c, '+
        'EV_Audit_Update_Status__c, BR_Audit__c, Standard_Audit_Statement_Internal_Link__c, '+
        'BR_Audit_Statement_Internal_Link__c, EV_Audit_Statement_Internal_Link__c '+
        'FROM Account '+
        'WHERE Id = \'0012100000FB6F1\' OR Id = \'0012100000FB6CE\'';//\'0012100000FB75zAAD\'';
        */
        return Database.getQueryLocator(soql);
    }
    
    global void execute(Database.BatchableContext BC, List<Account> lstAccounts){
        
        Set<String> existingRemoteSiteSettings = RunAuditArchiveBatchHelper.getExistingRemoteSettings(this.sessionId);
        //System.debug(existingRemoteSiteSettings);
        String folderId;// = [SELECT Id from Folder where Name = 'Audit Files' Limit 1][0].Id;
        
        RunAuditArchiveBatchHelper helper = new RunAuditArchiveBatchHelper(this.sessionId, folderId, existingRemoteSiteSettings);
        
        Map<String, Account> mapAccountToUpdate = new Map<String, Account>();
        Map<String, Map<String, Attachment>> mapAccountWithItsAuditDocuments = new Map<String, Map<String, Attachment>>();
        
        Map<String, File_Archive__c> mapExternalUrlToFileArchive = getExistingFileArchive();
        
        String IntermediateCertRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Intermediate Certificate').getRecordTypeId();
        
        for(Account acc : lstAccounts){
            //define parentid and check if it is intermediate cert then take ca owner id else take parent id for root certs
            string ParentId = '';
            if(acc.RecordTypeId == IntermediateCertRecordTypeId) {
                ParentId = acc.CA_Owner_Id__c;
            } else {
                ParentId = acc.ParentId;
            }
            
            System.debug('Processing Account: '+acc.Id);
            Map<String, Attachment> mapTemp = new Map<String, Attachment>();
            
            if(acc.Standard_Audit__c != null || acc.BR_Audit__c != null || acc.EV_Audit__c != null || acc.EV_Code_Signing_Audit__c != null){
                
               //check for EV Code Signing
                if(acc.EV_Code_Signing_Audit__c != null && acc.EV_Code_Signing_Audit_Update_Status__c != 'Successful' && !mapTemp.containsKey(acc.EV_Code_Signing_Audit__c)){
                    
                    String evKey = ParentId + '-' + acc.EV_Code_Signing_Audit__c;
                    if(mapExternalUrlToFileArchive.containsKey(evKey)){
                        
                        File_Archive__c fTemp = mapExternalUrlToFileArchive.get(evKey);
                        acc.EV_Code_Signing_Audit_Update_Status__c = 'Successful';
                        acc.EV_Code_Signing_Audit_Stmt_Int_Link__c = fTemp.Internal_Link__c;
                        if(acc.EV_Code_Signing_Audit_Period_Start_Date__c != null)
                            fTemp.Period_Start_Date__c = acc.EV_Code_Signing_Audit_Period_Start_Date__c;
                        if(acc.EV_Code_Signing_Audit_Period_End_Date__c != null)
                            fTemp.Period_End_Date__c = acc.EV_Code_Signing_Audit_Period_End_Date__c;
                        //added Audit Statement date - 28th Dec 2017
                        if(acc.EV_Code_Signing_Audit_Statement_Date__c != null)
                            fTemp.Audit_Statement_Date__c = acc.EV_Code_Signing_Audit_Statement_Date__c;
                        if(acc.Auditor_New__c != null)
                            fTemp.Auditor__c = acc.Auditor_New__r.Name;
                        if(acc.Auditor_Location_New__c != null)
                            fTemp.Auditor_Location__c = acc.Auditor_Location_New__r.Name;
                        mapExistFileArchivesTosetPeriod.put(evKey,fTemp);
                        Set<String> setTemp = mapExternalUrlToDocTypes.containsKey(evKey) ? mapExternalUrlToDocTypes.get(evKey) : new Set<String>();
                        setTemp.add('EV Code Signing Audit');
                        mapExternalUrlToDocTypes.put(evKey, setTemp);
                        
                    }else{
                        try {
                            helper.registerDomainToRemoteSiteSettings(acc.EV_Code_Signing_Audit__c);
                            RunAuditArchiveBatchHelper.CalloutResult evsignAuditDoc = helper.doFetchDocument(acc.Id, ParentId, acc.EV_Code_Signing_Audit_Statement_Date__c, acc.EV_Code_Signing_Audit__c, 'EV Code Signing Document');
                            
                            if(evsignAuditDoc.documentSO == null){//brAuditDoc.StatusCode == 500
                                acc.EV_Code_Signing_Audit_Update_Status__c = 'Failed';
                                acc.EV_Code_Signing_Audit_Update_Message__c = evsignAuditDoc.StatusCode != 500 ? 'Link is not pointing to PDF file.' : evsignAuditDoc.status;
                            }/*
                            else if(brAuditDoc.documentSO == null){
                                acc.BR_Audit_Update_Status__c = 'Failed';
                                acc.BR_Audit_Update_Message__c = 'Link is not pointing to PDF file.';
                            }*/ 
                            else if(evsignAuditDoc.documentSO.ParentId != null && evsignAuditDoc.documentSO.body != null){
                                mapTemp.put(acc.EV_Code_Signing_Audit__c, evsignAuditDoc.documentSO);
                            }
                        } catch (Exception ex){
                            acc.EV_Code_Signing_Audit_Update_Status__c = 'Failed';
                            acc.EV_Code_Signing_Audit_Update_Message__c = ex.getMessage();
                        }
                    }
                }
    
               if(acc.EV_Audit__c != null && acc.EV_Audit_Update_Status__c != 'Successful' && !mapTemp.containsKey(acc.EV_Audit__c)){
                    
                    String eKey = ParentId + '-' +acc.EV_Audit__c;
                    if(mapExternalUrlToFileArchive.containsKey(eKey)){
                        
                        File_Archive__c fTemp = mapExternalUrlToFileArchive.get(eKey);
                        acc.EV_Audit_Update_Status__c = 'Successful';
                        acc.EV_Audit_Statement_Internal_Link__c = fTemp.Internal_Link__c;
                        if(acc.EV_Audit_Period_Start_Date__c != null)
                            fTemp.Period_Start_Date__c = acc.EV_Audit_Period_Start_Date__c;
                        if(acc.EV_Audit_Period_End_Date__c != null)
                            fTemp.Period_End_Date__c = acc.EV_Audit_Period_End_Date__c;
                        //added Audit Statement date - 28th Dec 2017
                        if(acc.EV_Audit_Statement_Date__c != null)
                            fTemp.Audit_Statement_Date__c = acc.EV_Audit_Statement_Date__c;
                        if(acc.Auditor_New__c != null)
                            fTemp.Auditor__c = acc.Auditor_New__r.Name;
                        if(acc.Auditor_Location_New__c != null)
                            fTemp.Auditor_Location__c = acc.Auditor_Location_New__r.Name;
                        mapExistFileArchivesTosetPeriod.put(eKey,fTemp);  
                        Set<String> setTemp = mapExternalUrlToDocTypes.containsKey(eKey) ? mapExternalUrlToDocTypes.get(eKey) : new Set<String>();
                        setTemp.add('EV SSL Audit');
                        mapExternalUrlToDocTypes.put(acc.EV_Audit__c, setTemp); 
                        
                    }else{
                        try {
                            helper.registerDomainToRemoteSiteSettings(acc.EV_Audit__c);
                            RunAuditArchiveBatchHelper.CalloutResult evAuditDoc = helper.doFetchDocument(acc.Id, ParentId, acc.EV_Audit_Statement_Date__c, acc.EV_Audit__c, 'EV SSL Audit Document');
                            
                            
                            if(evAuditDoc.documentSO == null && evAuditDoc.StatusCode == 500){
                                acc.EV_Audit_Update_Status__c = 'Failed';
                                acc.EV_Audit_Update_Message__c = evAuditDoc.StatusCode != 500 ? 'Link is not pointing to PDF file.' : evAuditDoc.status;
                            }/*
                            else if(evAuditDoc.documentSO == null){
                                acc.EV_Audit_Update_Status__c = 'Failed';
                                acc.EV_Audit_Update_Message__c = 'Link is not pointing to PDF file.';
                            }*/ else if(evAuditDoc.documentSO.ParentId != null && evAuditDoc.documentSO.body != null){
                                mapTemp.put(acc.EV_Audit__c, evAuditDoc.documentSO);
                            }
                        } catch (Exception ex) {
                            acc.EV_Audit_Update_Status__c = 'Failed';
                            acc.EV_Audit_Update_Message__c = ex.getMessage();
                        }
                    }
                }
                
    
                if(acc.BR_Audit__c != null && acc.BR_Audit_Update_Status__c != 'Successful' && !mapTemp.containsKey(acc.BR_Audit__c)){
                    
                    String bKey = ParentId + '-' +acc.BR_Audit__c;
                    if(mapExternalUrlToFileArchive.containsKey(bKey)){
                        File_Archive__c fTemp = mapExternalUrlToFileArchive.get(bKey);
                        acc.BR_Audit_Update_Status__c = 'Successful';
                        acc.BR_Audit_Statement_Internal_Link__c = fTemp.Internal_Link__c;
                        if(acc.BR_Audit_Period_Start_Date__c != null)
                            fTemp.Period_Start_Date__c = acc.BR_Audit_Period_Start_Date__c;
                        if(acc.BR_Audit_Period_End_Date__c != null)
                            fTemp.Period_End_Date__c = acc.BR_Audit_Period_End_Date__c;
                        //added Audit Statement date - 28th Dec 2017
                        if(acc.BR_Audit_Statement_Date__c != null)
                            fTemp.Audit_Statement_Date__c = acc.BR_Audit_Statement_Date__c;
                        if(acc.Auditor_New__c != null)
                            fTemp.Auditor__c = acc.Auditor_New__r.Name;
                        if(acc.Auditor_Location_New__c != null)
                            fTemp.Auditor_Location__c = acc.Auditor_Location_New__r.Name;
                        mapExistFileArchivesTosetPeriod.put(bKey,fTemp);  
                        Set<String> setTemp = mapExternalUrlToDocTypes.containsKey(bKey) ? mapExternalUrlToDocTypes.get(bKey) : new Set<String>();
                        setTemp.add('BR Audit');
                        mapExternalUrlToDocTypes.put(bKey, setTemp);
                        
                    }else{
                        try {
                            helper.registerDomainToRemoteSiteSettings(acc.BR_Audit__c);
                            RunAuditArchiveBatchHelper.CalloutResult brAuditDoc = helper.doFetchDocument(acc.Id, ParentId, acc.BR_Audit_Statement_Date__c, acc.BR_Audit__c, 'BR Audit Document');
                        
                            if(brAuditDoc.documentSO == null){//brAuditDoc.StatusCode == 500
                                acc.BR_Audit_Update_Status__c = 'Failed';
                                acc.BR_Audit_Update_Message__c = brAuditDoc.StatusCode != 500 ? 'Link is not pointing to PDF file.' : brAuditDoc.status;
                            }/*
                            else if(brAuditDoc.documentSO == null){
                                acc.BR_Audit_Update_Status__c = 'Failed';
                                acc.BR_Audit_Update_Message__c = 'Link is not pointing to PDF file.';
                            }*/else if(brAuditDoc.documentSO.ParentId != null && brAuditDoc.documentSO.body != null){
                                mapTemp.put(acc.BR_Audit__c, brAuditDoc.documentSO);
                            }
                        } catch (Exception ex) {
                            acc.BR_Audit_Update_Status__c = 'Failed';
                            acc.BR_Audit_Update_Message__c = ex.getMessage();
                        }   
                    }
                }
                
                if(acc.Standard_Audit__c != null && acc.Standard_Audit_Update_Status__c != 'Successful'){// && !mapTemp.containsKey(acc.Standard_Audit__c)
                    
                    String sKey = ParentId + '-' +acc.Standard_Audit__c;
                    if(mapExternalUrlToFileArchive.containsKey(sKey)){
                        
                        File_Archive__c fTemp = mapExternalUrlToFileArchive.get(sKey);
                        acc.Standard_Audit_Update_Status__c = 'Successful';
                        acc.Standard_Audit_Statement_Internal_Link__c = fTemp.Internal_Link__c;
                        if(acc.Standard_Audit_Period_Start_Date__c != null)
                            fTemp.Period_Start_Date__c = acc.Standard_Audit_Period_Start_Date__c;
                        if(acc.Standard_Audit_Period_End_Date__c != null)
                            fTemp.Period_End_Date__c = acc.Standard_Audit_Period_End_Date__c;
                        //added Audit Statement date - 28th Dec 2017
                        if(acc.Standard_Audit_Statement_Date__c != null)
                            fTemp.Audit_Statement_Date__c = acc.Standard_Audit_Statement_Date__c;
                        if(acc.Auditor_New__c != null)
                            fTemp.Auditor__c = acc.Auditor_New__r.Name;
                        if(acc.Auditor_Location_New__c != null)
                            fTemp.Auditor_Location__c = acc.Auditor_Location_New__r.Name;
                        mapExistFileArchivesTosetPeriod.put(sKey,fTemp);          
                        Set<String> setTemp = mapExternalUrlToDocTypes.containsKey(sKey) ? mapExternalUrlToDocTypes.get(sKey) : new Set<String>();
                        setTemp.add('Standard Audit');
                        mapExternalUrlToDocTypes.put(sKey, setTemp); 
                        
                    }else{
                        try {
                            helper.registerDomainToRemoteSiteSettings(acc.Standard_Audit__c);
                            RunAuditArchiveBatchHelper.CalloutResult stdAuditDoc = helper.doFetchDocument(acc.Id, ParentId, acc.Standard_Audit_Statement_Date__c, acc.Standard_Audit__c, 'Standard Audit Document');
                        
                            if(stdAuditDoc.documentSO == null){// && stdAuditDoc.StatusCode == 500
                                acc.Standard_Audit_Update_Status__c = 'Failed';
                                acc.Standard_Audit_Update_Message__c =  stdAuditDoc.StatusCode != 500 ? 'Link is not pointing to PDF file.' : stdAuditDoc.status;
                            }/*
                            else if(stdAuditDoc.documentSO == null){
                                acc.Standard_Audit_Update_Status__c = 'Failed';
                                acc.Standard_Audit_Update_Message__c = 'Link is not pointing to PDF file.';
                            }*/
                            else if(stdAuditDoc.documentSO.ParentId != null && stdAuditDoc.documentSO.body != null){
                                mapTemp.put(acc.Standard_Audit__c, stdAuditDoc.documentSO);
                            }
                        } catch (Exception ex) {
                            acc.Standard_Audit_Update_Status__c = 'Failed';
                            acc.Standard_Audit_Update_Message__c = ex.getMessage();
                        }
                    }   
                }    
                
                mapAccountToUpdate.put(acc.Id, acc);
                mapAccountWithItsAuditDocuments.put(acc.Id, mapTemp);
            }
        }
        
        if(mapAccountWithItsAuditDocuments.size() > 0){
            
            List<String> lstAuditInfo = new List<String>{'EV_Code_Signing_Audit__c','EV_Audit__c','BR_Audit__c','Standard_Audit__c'};
            List<Map<String, Attachment>> lstTempMap = mapAccountWithItsAuditDocuments.values();
            List<Attachment> lstAttachments = new List<Attachment>();
            for(Map<String, Attachment> mapTemp : lstTempMap){
                lstAttachments.addAll(mapTemp.values());
            }
            insert lstAttachments;
            
            for(String accountId : mapAccountWithItsAuditDocuments.keySet()){     
                Map<String, Attachment> mapTemp = mapAccountWithItsAuditDocuments.get(accountId);
                
                for(String externalURL : mapTemp.keySet()){
                    
                    Attachment doc = mapTemp.get(externalURL);
                    Account acc = mapAccountToUpdate.get(accountId);
                    
                    List<String> lstDocumentTypes = new List<String>();
                    
                    String internalAuditLink = System.URL.getSalesforceBaseUrl().toExternalForm() + '/servlet/servlet.FileDownload?file=' + doc.Id;
                    File_Archive__c fileArchived = new File_Archive__c(Internal_Link__c = internalAuditLink,
                    External_Link__c = externalURL,
                    //Period_Start_Date__c = caseSO.Standard_Audit_Period_Start_Date__c,
                    //Period_End_Date__c = caseSO.Standard_Audit_Period_End_Date__c,
                    CA_Owner__c = doc.ParentId);
                    
                    for(String auditinfo : lstAuditInfo){
                        String auditURL = String.valueOf(acc.get(auditinfo));
                        System.debug('auditURL: '+auditURL);
                        System.debug('external URL: '+externalURL);
                        if(auditURL == externalURL){
                            
                            if(auditinfo == 'EV_Code_Signing_Audit__c'){
                                
                                fileArchived.Audit_Statement_Date__c = acc.EV_Code_Signing_Audit_Statement_Date__c;
                                if(acc.EV_Code_Signing_Audit_Period_Start_Date__c != null)
                                    fileArchived.Period_Start_Date__c = acc.EV_Code_Signing_Audit_Period_Start_Date__c;
                                if(acc.EV_Code_Signing_Audit_Period_End_Date__c != null)
                                    fileArchived.Period_End_Date__c = acc.EV_Code_Signing_Audit_Period_End_Date__c;
                                lstDocumentTypes.add('EV Code Signing Audit');
                                
                                acc.EV_Code_Signing_Audit_Stmt_Int_Link__c = internalAuditLink;
                                acc.EV_Code_Signing_Audit_Update_Status__c = 'Successful';
                                acc.EV_Code_Signing_Audit_Update_Message__c = null;
                            } 
                            if(auditinfo == 'EV_Audit__c'){
                                
                                fileArchived.Audit_Statement_Date__c = acc.EV_Audit_Statement_Date__c;
                                if(acc.EV_Audit_Period_Start_Date__c != null)
                                    fileArchived.Period_Start_Date__c = acc.EV_Audit_Period_Start_Date__c;
                                if(acc.EV_Audit_Period_End_Date__c != null)
                                    fileArchived.Period_End_Date__c = acc.EV_Audit_Period_End_Date__c;
                                lstDocumentTypes.add('EV SSL Audit');
                                
                                acc.EV_Audit_Statement_Internal_Link__c = internalAuditLink;
                                acc.EV_Audit_Update_Status__c = 'Successful';
                                acc.EV_Audit_Update_Message__c = null;
                            }
                             
                            if(auditinfo == 'BR_Audit__c'){
                                
                                fileArchived.Audit_Statement_Date__c = acc.BR_Audit_Statement_Date__c;
                                if(acc.BR_Audit_Period_Start_Date__c != null)
                                    fileArchived.Period_Start_Date__c = acc.BR_Audit_Period_Start_Date__c;
                                if(acc.BR_Audit_Period_End_Date__c != null)
                                    fileArchived.Period_End_Date__c = acc.BR_Audit_Period_End_Date__c;
                                lstDocumentTypes.add('BR Audit');
                                
                                acc.BR_Audit_Statement_Internal_Link__c = internalAuditLink;
                                acc.BR_Audit_Update_Status__c = 'Successful';
                                acc.BR_Audit_Update_Message__c = null;
                            }
                            if(auditinfo == 'Standard_Audit__c'){
                                
                                fileArchived.Audit_Statement_Date__c = acc.Standard_Audit_Statement_Date__c;
                                if(acc.Standard_Audit_Period_Start_Date__c != null)
                                    fileArchived.Period_Start_Date__c = acc.Standard_Audit_Period_Start_Date__c;
                                if(acc.Standard_Audit_Period_End_Date__c != null)
                                    fileArchived.Period_End_Date__c = acc.Standard_Audit_Period_End_Date__c;
                                lstDocumentTypes.add('Standard Audit');
                                acc.Standard_Audit_Statement_Internal_Link__c = internalAuditLink;
                                acc.Standard_Audit_Update_Status__c = 'Successful';
                                acc.Standard_Audit_Update_Message__c = null;
                            }
                              
                            if(acc.Auditor_New__c != null)
                                fileArchived.Auditor__c = acc.Auditor_New__r.Name;
                            if(acc.Auditor_Location_New__c != null)
                                fileArchived.Auditor_Location__c = acc.Auditor_Location_New__r.Name;
                        }
                    }
                    fileArchived.Document_Type__c = String.join(lstDocumentTypes, ';');
                    lstFileArchive.add(fileArchived);
                }
            }
        }
        
        if(!mapAccountToUpdate.isEmpty()){
            //update mapAccountToUpdate.values();
            Database.update(mapAccountToUpdate.values(), false);
            //System.debug('Sucessfully Updated Root Accounts With Internal Links: '+ mapAccountToUpdate.values());
        }         
    }
    
    global void finish(Database.BatchableContext BC){
       
        Map<String, File_Archive__c> mapFileArchiveInsert = new Map<String, File_Archive__c>();
        List<Attachment> lstAttachments = new List<Attachment>();
        System.debug('TOTAL FILE ARCHIVE: '+this.lstFileArchive.size());
        
        Map<String, File_Archive__c> mapFileArchiveUpsert = getExistingFileArchive();
        for(String externalUrl : mapExternalUrlToDocTypes.keySet()){
            
            File_Archive__c fArchive = mapFileArchiveUpsert.get(externalUrl);
            if(fArchive != null){
                String fKey = fArchive.CA_Owner__c + '-' + fArchive.External_Link__c;
                Set<String> setTemp = mapExternalUrlToDocTypes.get(fKey);
                List<String> lstTemp = fArchive.Document_Type__c != null ? fArchive.Document_Type__c.split(';') : new List<String>();
                setTemp.addAll(lstTemp);
                lstTemp.clear();
                lstTemp.addAll(setTemp);
                fArchive.Document_Type__c = String.join(lstTemp, ';');
                if(mapExistFileArchivesTosetPeriod.containskey(fKey) && mapExistFileArchivesTosetPeriod.get(fKey) != null) {
                    fArchive.Period_Start_Date__c = mapExistFileArchivesTosetPeriod.get(fKey).Period_Start_Date__c;
                    fArchive.Period_End_Date__c = mapExistFileArchivesTosetPeriod.get(fKey).Period_End_Date__c;
                    //copy Audit statement date - 28th Dec 2017
                    fArchive.Audit_Statement_Date__c = mapExistFileArchivesTosetPeriod.get(fKey).Audit_Statement_Date__c;
                    fArchive.Auditor__c = mapExistFileArchivesTosetPeriod.get(fKey).Auditor__c;
                    fArchive.Auditor_Location__c = mapExistFileArchivesTosetPeriod.get(fKey).Auditor_Location__c;
                }
                mapFileArchiveInsert.put(fKey, fArchive);
            } 
        }
        
        for(File_Archive__c fArchive : this.lstFileArchive){  
            
            String fKey = fArchive.CA_Owner__c + '-' + fArchive.External_Link__c;
            
            if(mapFileArchiveInsert.containsKey(fKey)){
                
                String internalUrl = fArchive.Internal_Link__c;
                internalUrl = internalUrl.substring(internalUrl.indexOf('=') + 1, internalUrl.length());
                lstAttachments.add(new Attachment(Id = internalUrl));
                
                File_Archive__c fArchiveTemp = mapFileArchiveInsert.get(fKey);
                String availableDocType = fArchiveTemp.Document_Type__c;
                
                if(availableDocType != null){
                    
                    List<String> tempDocTypes = availableDocType.split(';');
                    List<String> lstExistingDocTypes = fArchive.Document_Type__c != null ? fArchive.Document_Type__c.split(';') : new List<String>();
                    Set<String> setTempDocTypes = new Set<String>();
                    setTempDocTypes.addAll(tempDocTypes);
                    setTempDocTypes.addAll(lstExistingDocTypes);
                    tempDocTypes.clear();
                    tempDocTypes.addAll(setTempDocTypes);
                    setTempDocTypes.clear();
                    
                    String newDocType = String.join(tempDocTypes, ';');
                    
                    fArchiveTemp.Document_Type__c = newDocType;
                    mapFileArchiveInsert.put(fArchiveTemp.CA_Owner__c + '-' + fArchiveTemp.External_Link__c, fArchiveTemp);
                }
               
            }else{ 
                
                mapFileArchiveInsert.put(fKey, fArchive); 
            }
        } 
        
        if(mapFileArchiveInsert.size() > 0){
            upsert mapFileArchiveInsert.values();
        }
        
        System.debug('INSERTING FILE ARCHIVE: '+mapFileArchiveInsert.values().size());
        
        System.debug('DELETING ATTACHMENT: '+lstAttachments.size());
        
        if(lstAttachments.size() > 0){
            delete lstAttachments;
        }
        
        //root certificate record type
        String rootCertRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Root Certificate').getRecordTypeId();
        //intermediate certificate record type
        String IntermediateCertRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Intermediate Certificate').getRecordTypeId();
        //set of root and intermediate recordtypes
        set<Id> setRecordTypeIds = new set<Id>();
        setRecordTypeIds.add(rootCertRecordTypeId);
        setRecordTypeIds.add(IntermediateCertRecordTypeId);
        
        String soql = 'SELECT Id, ParentId, Name, RecordTypeId, CA_Owner_ID__c, Standard_Audit_Statement_Date__c, BR_Audit_Statement_Date__c, '+
        'Standard_Audit_Update_Status__c, EV_Audit_Statement_Date__c,BR_Audit_Update_Status__c, Standard_Audit__c, EV_Audit__c, '+
        'EV_Audit_Update_Status__c, BR_Audit__c, Standard_Audit_Statement_Internal_Link__c, '+
        'BR_Audit_Statement_Internal_Link__c, EV_Audit_Statement_Internal_Link__c, EV_Code_Signing_Audit_Statement_Date__c, '+
        'EV_Code_Signing_Audit__c, EV_Code_Signing_Audit_Update_Status__c, EV_Code_Signing_Audit_Stmt_Int_Link__c ' + 
        'FROM Account '+
        'WHERE RecordTypeId in :setRecordTypeIds';
        
        List<Account> lstAccountUpdate = new List<Account>();
        
        System.debug('mapFileArchiveInsert '+mapFileArchiveInsert);
        
        for(Account acc : Database.query(soql)){ 
            //define parentid and check if it is intermediate cert then take ca owner id else take parent id for root certs 
            string ParentId = '';
            if(acc.RecordTypeId == IntermediateCertRecordTypeId){
                ParentId = acc.CA_Owner_Id__c;
            } else {
                ParentId = acc.ParentId;
            }
            
            String sKey = ParentId + '-' + acc.Standard_Audit__c;
            String bKey = ParentId + '-' + acc.BR_Audit__c;
            String esKey = ParentId + '-' + acc.EV_Audit__c;
            String ecKey = ParentId + '-' + acc.EV_Code_Signing_Audit__c;
            
            //added one more condition if standard audit and external link matched
            if(mapFileArchiveInsert.containsKey(sKey) && acc.Standard_Audit__c == mapFileArchiveInsert.get(sKey).External_Link__c){
                
                acc.Standard_Audit_Statement_Internal_Link__c = mapFileArchiveInsert.get(sKey).Internal_Link__c;
                acc.Standard_Audit_Update_Message__c = null;
                acc.Standard_Audit_Update_Status__c = 'Successful';  
            }
            //added one more condition if standard audit and external link matched
            if(mapFileArchiveInsert.containsKey(bKey) && acc.BR_Audit__c == mapFileArchiveInsert.get(bKey).External_Link__c){
                
                acc.BR_Audit_Statement_Internal_Link__c = mapFileArchiveInsert.get(bKey).Internal_Link__c;
                acc.BR_Audit_Update_Message__c = null;
                acc.BR_Audit_Update_Status__c = 'Successful'; 
            }
            //added one more condition if standard audit and external link matched
            if(mapFileArchiveInsert.containsKey(esKey) && acc.EV_Audit__c == mapFileArchiveInsert.get(esKey).External_Link__c){
                
                acc.EV_Audit_Statement_Internal_Link__c= mapFileArchiveInsert.get(esKey).Internal_Link__c;
                acc.EV_Audit_Update_Status__c = 'Successful';
                acc.EV_Audit_Update_Message__c = null;   
            }
            //added one more condition if standard audit and external link matched
            if(mapFileArchiveInsert.containsKey(ecKey)  && acc.EV_Code_Signing_Audit__c == mapFileArchiveInsert.get(ecKey).External_Link__c){
                
                acc.EV_Code_Signing_Audit_Stmt_Int_Link__c = mapFileArchiveInsert.get(ecKey).Internal_Link__c;
                acc.EV_Code_Signing_Audit_Update_Status__c = 'Successful';
                acc.EV_Code_Signing_Audit_Update_Message__c = null;   
            }
            
            System.debug('lstAccountUpdate '+lstAccountUpdate);
            
            lstAccountUpdate.add(acc);   
        }
        
        Database.update(lstAccountUpdate, false);
    }
    
    private Map<String, File_Archive__c> getExistingFileArchive(){ 
       Map<String, File_Archive__c> mapFileArchive = new Map<String, File_Archive__c>();
       for(File_Archive__c fArch : [SELECT Id, Document_Type__c, Internal_Link__c, External_Link__c,Auditor__c, 
                   Auditor_Location__c, CA_Owner__c,Period_Start_Date__c,Period_End_Date__c,Audit_Statement_Date__c FROM File_Archive__c]){
            mapFileArchive.put(fArch.CA_Owner__c + '-' +fArch.External_Link__c, fArch); 
       }
        return mapFileArchive;
    }
}
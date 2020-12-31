/*
    Description: Apex class for Audit Archive Program. Account trigger calls the Future method
    in this program to create unique CA Owner + Audit file entries in File Archive and File 
    Association objects. Trigger is invoked whenever Standard Audit/BR Audit/EV SSL Audit/
    EV Code Signing Audit file links or dates are updated.
    
    The future method uses named credentials to create a session, sets remote site
    settings for external websites, downloads audit files from remote sites, saves them 
    in File Archive and File Association objects and updated Audit Archive Update Status 
    and Message fields.
                 
    Important: Note that File Archive does not check for valid data in audit statement date, 
    period start date, period end date on root/inter cert records. The program will run 
    fine when these fields are blank. Later when these fields are updated on root/inter 
    certs, the archive process will copy those dates to file archive records.
    
    If Data Loader or any bulk processing tool is used to inserting/updating audit data 
    on root/intermediate certs there is a possibility that duplicate File Archive & 
    Association records may get created. This is because multiple future call treads are
    processing the data. Extra lines of code has been added to minumize the occurence 
    of duplicates records. Additional query is done just before upserting the reoords.
   
    Date Created: 3/5/2018
    
    **Modifications:
    28th March 18        Fixed error for community users while creating attachment on CA Owner as they have read only 
                         access. Changed class from with sharing to without sharing.
    28th March 18        Added SendEmail method to send exception emails. Added Try and Catch for exceptions and send 
                         email to "CCADB Admin" orgwide default address.
    2nd Aug 18           Update Audit Deviation Types based on Audit Deviation is selected on root certificates.
    
*/
public without sharing class FileArchiveFutureCallForAccount {
    
    /*
    *
    If the audit file is already archived check for the audit date, period start date and period end date. 
    If they do not match then copy the dates from the root or inter cert to file archive record. Do not copy a date if it is null.
    */
    public static void UpdateFileArchiveOnAuditDateChange(List<Account> lstAccounts, map<Id,Account> mapOldAccounts){
        
        //map of CA owner along with all its accounts that are in File Archive; this map will hold
        //all the account underneath specified CA owner which has file archive record and date change happen to that
        Map<String, List<Account>> mapCAOwnerIdWithAccount = new Map<String, List<Account>>();
        
        for(Account acc : lstAccounts){
            
            //check if there is a date change
            if(acc.Name != '<Fill in Cert Name>' && (Trigger.IsInsert || (acc.Standard_Audit_Statement_Date__c != mapOldAccounts.get(acc.Id).Standard_Audit_Statement_Date__c ||
                acc.Standard_Audit_Period_Start_Date__c != mapOldAccounts.get(acc.Id).Standard_Audit_Period_Start_Date__c || 
                acc.Standard_Audit_Period_End_Date__c != mapOldAccounts.get(acc.Id).Standard_Audit_Period_End_Date__c ||
                
                acc.BR_Audit_Statement_Date__c != mapOldAccounts.get(acc.Id).BR_Audit_Statement_Date__c ||
                acc.BR_Audit_Period_Start_Date__c != mapOldAccounts.get(acc.Id).BR_Audit_Period_Start_Date__c || 
                acc.BR_Audit_Period_End_Date__c != mapOldAccounts.get(acc.Id).BR_Audit_Period_End_Date__c ||
                
                acc.EV_Audit_Statement_Date__c != mapOldAccounts.get(acc.Id).EV_Audit_Statement_Date__c ||
                acc.EV_Audit_Period_Start_Date__c != mapOldAccounts.get(acc.Id).EV_Audit_Period_Start_Date__c || 
                acc.EV_Audit_Period_End_Date__c != mapOldAccounts.get(acc.Id).EV_Audit_Period_End_Date__c ||
                
                acc.EV_Code_Signing_Audit_Statement_Date__c != mapOldAccounts.get(acc.Id).EV_Code_Signing_Audit_Statement_Date__c ||
                acc.EV_Code_Signing_Audit_Period_Start_Date__c != mapOldAccounts.get(acc.Id).EV_Code_Signing_Audit_Period_Start_Date__c || 
                acc.EV_Code_Signing_Audit_Period_End_Date__c != mapOldAccounts.get(acc.Id).EV_Code_Signing_Audit_Period_End_Date__c ||
                
                acc.Code_Signing_Audit_Statement_Date__c != mapOldAccounts.get(acc.Id).Code_Signing_Audit_Statement_Date__c ||
                acc.Code_Signing_Audit_Period_Start_Date__c != mapOldAccounts.get(acc.Id).Code_Signing_Audit_Period_Start_Date__c || 
                acc.Code_Signing_Audit_Period_End_Date__c != mapOldAccounts.get(acc.Id).Code_Signing_Audit_Period_End_Date__c ||
                
                (acc.Name != mapOldAccounts.get(acc.id).Name  && mapOldAccounts.get(acc.id).Name == '<Fill in Cert Name>')))){
                
                //fill the map
                List<Account> lstTemp = mapCAOwnerIdWithAccount.containsKey(acc.CA_Owner_ID__c) ? mapCAOwnerIdWithAccount.get(acc.CA_Owner_ID__c) : new List<Account>();
                lstTemp.add(acc);
                mapCAOwnerIdWithAccount.put(acc.CA_Owner_ID__c, lstTemp);
            }
        }
        
        //if map is not empty then process
        if(!mapCAOwnerIdWithAccount.isEmpty()){
            
            //get all the file archive which has date change
            List<File_Archive__c> lstFileArchive = [SELECT Id, CA_Owner__c, Document_Type__c, External_Link__c
                                                    FROM File_Archive__c WHERE CA_Owner__c IN :mapCAOwnerIdWithAccount.keySet()];
            
            if(!lstFileArchive.isEmpty()){
                
                for(File_Archive__c fArc : lstFileArchive){
                    
                    set<string> setOfDaviation = new set<string>();
                    
                    //Iterate to all accounts which has one of the date change
                    for(Account acc : mapCAOwnerIdWithAccount.get(fArc.CA_Owner__c)){
                        
                        //Update Std Audit details
                        if(fArc.Document_Type__c != null && fArc.Document_Type__c.contains('Standard Audit') && acc.Standard_Audit__c == fArc.External_Link__c){
                            
                            fArc.Audit_Statement_Date__c =  acc.Standard_Audit_Statement_Date__c;
                            fArc.Period_Start_Date__c = acc.Standard_Audit_Period_Start_Date__c;
                            fArc.Period_End_Date__c = acc.Standard_Audit_Period_End_Date__c;
                            if(acc.Standard_Deviation__c) {
                                setOfDaviation.add('Standard Audit');
                            }
                        }
                        
                        //update BR audit details
                        if(fArc.Document_Type__c != null && fArc.Document_Type__c.contains('BR Audit') && acc.BR_Audit__c == fArc.External_Link__c){
                            
                            fArc.Audit_Statement_Date__c =  acc.BR_Audit_Statement_Date__c;
                            fArc.Period_Start_Date__c = acc.BR_Audit_Period_Start_Date__c;
                            fArc.Period_End_Date__c = acc.BR_Audit_Period_End_Date__c;
                            if(acc.BR_Deviation__c) {
                                setOfDaviation.add('BR Audit');
                            }
                        }
                        
                        //update Code signing Audit details
                        if(fArc.Document_Type__c != null && fArc.Document_Type__c.contains('Code Signing Audit') && acc.Code_Signing_Audit__c == fArc.External_Link__c){
                            
                            fArc.Audit_Statement_Date__c =  acc.Code_Signing_Audit_Statement_Date__c;
                            fArc.Period_Start_Date__c = acc.Code_Signing_Audit_Period_Start_Date__c;
                            fArc.Period_End_Date__c = acc.Code_Signing_Audit_Period_End_Date__c;
                            if(acc.Code_Signing_Deviation__c) {
                                setOfDaviation.add('Code Signing Audit');
                            }
                        }
                        
                        //Update EV SSL audit details
                        if(fArc.Document_Type__c != null && fArc.Document_Type__c.contains('EV SSL Audit') && acc.EV_Audit__c == fArc.External_Link__c){
                            
                            fArc.Audit_Statement_Date__c =  acc.EV_Audit_Statement_Date__c;
                            fArc.Period_Start_Date__c = acc.EV_Audit_Period_Start_Date__c;
                            fArc.Period_End_Date__c = acc.EV_Audit_Period_End_Date__c;
                            if(acc.EV_SSL_Deviation__c) {
                                setOfDaviation.add('EV SSL Audit');
                            }
                        }
                        
                        //update EV Code signing Audit details
                        if(fArc.Document_Type__c != null && fArc.Document_Type__c.contains('EV Code Signing Audit') && acc.EV_Code_Signing_Audit__c == fArc.External_Link__c){
                            
                            fArc.Audit_Statement_Date__c =  acc.EV_Code_Signing_Audit_Statement_Date__c;
                            fArc.Period_Start_Date__c = acc.EV_Code_Signing_Audit_Period_Start_Date__c;
                            fArc.Period_End_Date__c = acc.EV_Code_Signing_Audit_Period_End_Date__c;
                            if(acc.EV_Code_Signing_Deviation__c) {
                                setOfDaviation.add('EV Code Signing Audit');
                            }
                        }
                    }
                    if(setOfDaviation.size() > 0){
                        List<String> lstOfDaviation = new List<String>();
                        lstOfDaviation.addAll(setOfDaviation);
                        fArc.Audit_Deviation__c = string.join(lstOfDaviation, ';');
                    }
                }
                
                update lstFileArchive;
            }
        }
    }
    
    /*
        Description: This method is call from trigger.
                     1. We are checking Root/Intermediate cert name should not be <Fill in Cert Name>
                     2. Trigger should only fire when Audit URL changes or Name is changed from <Fill in Cert Name>
                     Once we found any account that updated URLs or changed name, we call future method to download file archive.
    */
    public static boolean isRecursive = false;
    public static void CreateFileArchiveRecords(List<Account> lstAccounts, map<Id,Account> mapOldAccounts){
        if(!isRecursive){
            set<Id> setAccountIds = new set<Id>();
            
            //create set of account which has changed Audit URL or Name changed from <Fill in Cert Name>.
            for(Account objAccount: lstAccounts){
                if(objAccount.Name != '<Fill in Cert Name>' && (objAccount.Standard_Audit__c != null || objAccount.BR_Audit__c != null || objAccount.EV_Audit__c != null || objAccount.EV_Code_Signing_Audit__c != null) &&
                (Trigger.IsInsert || (objAccount.Standard_Audit__c != mapOldAccounts.get(objAccount.id).Standard_Audit__c || objAccount.Code_Signing_Audit__c != mapOldAccounts.get(objAccount.id).Code_Signing_Audit__c ||
                objAccount.BR_Audit__c != mapOldAccounts.get(objAccount.id).BR_Audit__c || objAccount.EV_Audit__c != mapOldAccounts.get(objAccount.id).EV_Audit__c ||
                objAccount.EV_Code_Signing_Audit__c != mapOldAccounts.get(objAccount.id).EV_Code_Signing_Audit__c ||
                (objAccount.Name != mapOldAccounts.get(objAccount.id).Name  && mapOldAccounts.get(objAccount.id).Name == '<Fill in Cert Name>')))
                ){
                    setAccountIds.add(objAccount.Id);
                }
            }
            //once any account found call future method.
            if(setAccountIds.size() > 0) {
                for(Id accid: setAccountIds){
                    isRecursive = true;
                    FileArchiveFutureCallForAccount.FutureCallCreateAuditFiles(accid);
                }
            }
        }
        
    }
    
    /*
        Description: This Future method to call from "CreateFileArchiveRecords" if there any change made on audit urls or name.
    */
    @future(callout=true)
    public static void FutureCallCreateAuditFiles(string accountId){
        //call static method check and download audit files
        createAuditFiles(accountId);
    }
    
    /*
        Description: Common function, that accept account id as parameter.
                     1. First check if any of audit status is not Successful then that account check audit files. if audit status is successful then it will not update any thing.
                     2. Checking if File Archive is already exist, then create File archive association records for that root/inter certs.
                     3. If File Archive is not exist then make callout to audit URLs, download attachment and create file archive records and file archive association record for that root/inter certs.
                     4. Update audit status and internal link and message (if there is any error)
    */
    public static void createAuditFiles(string accountId){
        String soql = 'SELECT Id, ParentId, Name, CA_Owner_Id__c, Standard_Audit_Statement_Date__c, BR_Audit_Statement_Date__c, '+
                'Standard_Audit_Update_Status__c, EV_Audit_Statement_Date__c, BR_Audit_Update_Status__c, Standard_Audit__c, EV_Audit__c, '+
                'EV_Audit_Update_Status__c, BR_Audit__c, Standard_Audit_Statement_Internal_Link__c, RecordTypeId, '+
                'Standard_Audit_Period_Start_Date__c, Standard_Audit_Period_End_Date__c, ' + 
                'BR_Audit_Period_Start_Date__c, BR_Audit_Period_End_Date__c, EV_Audit_Period_Start_Date__c, EV_Audit_Period_End_Date__c,' + 
                'EV_Code_Signing_Audit_Period_Start_Date__c, EV_Code_Signing_Audit_Period_End_Date__c, ' + 
                'BR_Audit_Statement_Internal_Link__c, EV_Audit_Statement_Internal_Link__c, EV_Code_Signing_Audit_Statement_Date__c, '+
                'EV_Code_Signing_Audit__c, EV_Code_Signing_Audit_Update_Status__c, EV_Code_Signing_Audit_Stmt_Int_Link__c, ' +
                'Code_Signing_Audit__c, Code_Signing_Audit_Period_End_Date__c, Code_Signing_Audit_Period_Start_Date__c, Code_Signing_Audit_Statement_Date__c, ' +
                'Code_Signing_Audit_Type__c, Code_Signing_Audit_Update_Message__c, Code_Signing_Audit_Update_Status__c, Code_Signing_Statement_Internal_Link__c, ' + 
                'Auditor_New__c, Auditor_New__r.Name, Auditor_Location_New__c, Auditor_Location_New__r.Name, ' +
                'Standard_Deviation__c, Code_Signing_Deviation__c, BR_Deviation__c, EV_SSL_Deviation__c, EV_Code_Signing_Deviation__c ' + 
                'FROM Account '+
                'WHERE Id=: accountId '+
                'and (Standard_Audit_Update_Status__c != \'Successful\' or BR_Audit_Update_Status__c != \'Successful\' ' +
                'or EV_Audit_Update_Status__c != \'Successful\' or EV_Code_Signing_Audit_Update_Status__c != \'Successful\')';

        List<Account> lstAccount = Database.Query(soql);
        
        if(lstAccount.size() > 0) {
            //make callout and get session id to create remote site setting if it is not exist.
            string sessionId = getSessionId();
            
            if(string.isnotblank(sessionId)){
        
                Account objAccount =  lstAccount[0];  
                
                //get existing remote site settings.    
                Set<String> existingRemoteSiteSettings = RunAuditArchiveBatchHelper.getExistingRemoteSettings(sessionId);
                
                Map<String, File_Archive__c> mapExistingFileArchive = new Map<String, File_Archive__c>();
                Map<String, File_Archive__c> mapExistFileArchivesTosetPeriod = new Map<String, File_Archive__c>();
                Map<String, Set<String>> mapExternalUrlToDocTypes = new Map<String, Set<String>>();
                Map<String, Set<String>> mapDeviationTypes = new Map<String, Set<String>>();
                
                //get existing file archive records and fill in map
                for(File_Archive__c fArch : [SELECT Id, Document_Type__c, Internal_Link__c, External_Link__c,Auditor__c, 
                    Auditor_Location__c, CA_Owner__c,Period_Start_Date__c,Period_End_Date__c,Audit_Statement_Date__c 
                    FROM File_Archive__c Where CA_Owner__c =: objAccount.CA_Owner_Id__c]){
                    mapExistingFileArchive.put(fArch.External_Link__c, fArch); 
                }
                
                RunAuditArchiveBatchHelper helper = new RunAuditArchiveBatchHelper(sessionId, '', existingRemoteSiteSettings);
                
                Map<String, Attachment> mapTemp = new Map<String, Attachment>();
                
                if(objAccount.Standard_Audit__c != null || objAccount.Code_Signing_Audit__c != null || objAccount.BR_Audit__c != null || objAccount.EV_Audit__c != null || objAccount.EV_Code_Signing_Audit__c != null){
                    
                    //check for EV Code Signing
                    if(objAccount.EV_Code_Signing_Audit__c != null && objAccount.EV_Code_Signing_Audit_Update_Status__c != 'Successful' && !mapTemp.containsKey(objAccount.EV_Code_Signing_Audit__c)){
                        String evKey = objAccount.EV_Code_Signing_Audit__c;
    
                        if(mapExistingFileArchive.containsKey(evKey)){
                            
                            File_Archive__c fTemp = mapExistingFileArchive.get(evKey);
                            objAccount.EV_Code_Signing_Audit_Update_Status__c = 'Successful';
                            objAccount.EV_Code_Signing_Audit_Stmt_Int_Link__c = fTemp.Internal_Link__c;
                            if(objAccount.EV_Code_Signing_Audit_Period_Start_Date__c != null)
                                fTemp.Period_Start_Date__c = objAccount.EV_Code_Signing_Audit_Period_Start_Date__c;
                            if(objAccount.EV_Code_Signing_Audit_Period_End_Date__c != null)
                                fTemp.Period_End_Date__c = objAccount.EV_Code_Signing_Audit_Period_End_Date__c;
                            //added Audit Statement date - 28th Dec 2017
                            if(objAccount.EV_Code_Signing_Audit_Statement_Date__c != null)
                                fTemp.Audit_Statement_Date__c = objAccount.EV_Code_Signing_Audit_Statement_Date__c;
                            if(objAccount.Auditor_New__c != null)
                                fTemp.Auditor__c = objAccount.Auditor_New__r.Name;
                            if(objAccount.Auditor_Location_New__c != null)
                                fTemp.Auditor_Location__c = objAccount.Auditor_Location_New__r.Name;
                            //check for deviation
                            mapExistFileArchivesTosetPeriod.put(evKey,fTemp);
                            Set<String> setTemp = mapExternalUrlToDocTypes.containsKey(evKey) ? mapExternalUrlToDocTypes.get(evKey) : new Set<String>();
                            setTemp.add('EV Code Signing Audit');
                            mapExternalUrlToDocTypes.put(evKey, setTemp);
                            //fill map for deviation
                            if(objAccount.EV_Code_Signing_Deviation__c){
                                Set<String> setDeviation = mapDeviationTypes.containsKey(evKey) ? mapDeviationTypes.get(evKey) : new Set<String>();
                                setDeviation.add('EV Code Signing Audit');
                                mapDeviationTypes.put(evKey, setDeviation);
                            }
                        }else{
                            try {
                                helper.registerDomainToRemoteSiteSettings(objAccount.EV_Code_Signing_Audit__c);
                                RunAuditArchiveBatchHelper.CalloutResult evsignAuditDoc = helper.doFetchDocument(objAccount.Id, objAccount.CA_Owner_Id__c, objAccount.EV_Code_Signing_Audit_Statement_Date__c, objAccount.EV_Code_Signing_Audit__c, 'EV Code Signing Document');
                                
                                if(evsignAuditDoc.documentSO.Body == null){//brAuditDoc.StatusCode == 500
                                    objAccount.EV_Code_Signing_Audit_Update_Status__c = 'Failed';
                                    objAccount.EV_Code_Signing_Audit_Update_Message__c = evsignAuditDoc.StatusCode != 500 ? 'Link is not pointing to PDF file.' : evsignAuditDoc.status;
                                } else if(evsignAuditDoc.documentSO.ParentId != null && evsignAuditDoc.documentSO.body != null){
                                    mapTemp.put(objAccount.EV_Code_Signing_Audit__c, evsignAuditDoc.documentSO);
                                }
                            } catch (Exception ex){
                                objAccount.EV_Code_Signing_Audit_Update_Status__c = 'Failed';
                                objAccount.EV_Code_Signing_Audit_Update_Message__c = ex.getMessage();
                            }
                        }
                    }
                    //check EV SSL Audit
                    if(objAccount.EV_Audit__c != null && objAccount.EV_Audit_Update_Status__c != 'Successful' && !mapTemp.containsKey(objAccount.EV_Audit__c)){
                        
                        String eKey = objAccount.EV_Audit__c;
                        if(mapExistingFileArchive.containsKey(eKey)){
                            
                            File_Archive__c fTemp = mapExistingFileArchive.get(eKey);
                            objAccount.EV_Audit_Update_Status__c = 'Successful';
                            objAccount.EV_Audit_Statement_Internal_Link__c = fTemp.Internal_Link__c;
                            if(objAccount.EV_Audit_Period_Start_Date__c != null)
                                fTemp.Period_Start_Date__c = objAccount.EV_Audit_Period_Start_Date__c;
                            if(objAccount.EV_Audit_Period_End_Date__c != null)
                                fTemp.Period_End_Date__c = objAccount.EV_Audit_Period_End_Date__c;
                            //added Audit Statement date - 28th Dec 2017
                            if(objAccount.EV_Audit_Statement_Date__c != null)
                                fTemp.Audit_Statement_Date__c = objAccount.EV_Audit_Statement_Date__c;
                            if(objAccount.Auditor_New__c != null)
                                fTemp.Auditor__c = objAccount.Auditor_New__r.Name;
                            if(objAccount.Auditor_Location_New__c != null)
                                fTemp.Auditor_Location__c = objAccount.Auditor_Location_New__r.Name;
                            mapExistFileArchivesTosetPeriod.put(eKey,fTemp);  
                            Set<String> setTemp = mapExternalUrlToDocTypes.containsKey(eKey) ? mapExternalUrlToDocTypes.get(eKey) : new Set<String>();
                            setTemp.add('EV SSL Audit');
                            mapExternalUrlToDocTypes.put(eKey, setTemp); 
                            //fill map for deviation
                            if(objAccount.EV_SSL_Deviation__c){
                                Set<String> setDeviation = mapDeviationTypes.containsKey(eKey) ? mapDeviationTypes.get(eKey) : new Set<String>();
                                setDeviation.add('EV SSL Audit');
                                mapDeviationTypes.put(eKey, setDeviation);
                            }
                        }else{
                            try {
                                helper.registerDomainToRemoteSiteSettings(objAccount.EV_Audit__c);
                                RunAuditArchiveBatchHelper.CalloutResult evAuditDoc = helper.doFetchDocument(objAccount.Id, objAccount.CA_Owner_Id__c, objAccount.EV_Audit_Statement_Date__c, objAccount.EV_Audit__c, 'EV SSL Audit Document');
                                
                                if(evAuditDoc.documentSO.Body == null){
                                    objAccount.EV_Audit_Update_Status__c = 'Failed';
                                    objAccount.EV_Audit_Update_Message__c = evAuditDoc.StatusCode != 500 ? 'Link is not pointing to PDF file.' : evAuditDoc.status;
                                }/*
                                else if(evAuditDoc.documentSO == null){
                                    objAccount.EV_Audit_Update_Status__c = 'Failed';
                                    objAccount.EV_Audit_Update_Message__c = 'Link is not pointing to PDF file.';
                                }*/ else if(evAuditDoc.documentSO.ParentId != null && evAuditDoc.documentSO.body != null){
                                    mapTemp.put(objAccount.EV_Audit__c, evAuditDoc.documentSO);
                                }
                            } catch (Exception ex) {
                                objAccount.EV_Audit_Update_Status__c = 'Failed';
                                objAccount.EV_Audit_Update_Message__c = ex.getMessage();
                            }
                        }
                    }
                    
                    //check for BR Audit
                    if(objAccount.BR_Audit__c != null && objAccount.BR_Audit_Update_Status__c != 'Successful' && !mapTemp.containsKey(objAccount.BR_Audit__c)){
                        
                        String bKey = objAccount.BR_Audit__c;
                        if(mapExistingFileArchive.containsKey(bKey)){
                            File_Archive__c fTemp = mapExistingFileArchive.get(bKey);
                            objAccount.BR_Audit_Update_Status__c = 'Successful';
                            objAccount.BR_Audit_Statement_Internal_Link__c = fTemp.Internal_Link__c;
                            if(objAccount.BR_Audit_Period_Start_Date__c != null)
                                fTemp.Period_Start_Date__c = objAccount.BR_Audit_Period_Start_Date__c;
                            if(objAccount.BR_Audit_Period_End_Date__c != null)
                                fTemp.Period_End_Date__c = objAccount.BR_Audit_Period_End_Date__c;
                            //added Audit Statement date - 28th Dec 2017
                            if(objAccount.BR_Audit_Statement_Date__c != null)
                                fTemp.Audit_Statement_Date__c = objAccount.BR_Audit_Statement_Date__c;
                            if(objAccount.Auditor_New__c != null)
                                fTemp.Auditor__c = objAccount.Auditor_New__r.Name;
                            if(objAccount.Auditor_Location_New__c != null)
                                fTemp.Auditor_Location__c = objAccount.Auditor_Location_New__r.Name;
                            mapExistFileArchivesTosetPeriod.put(bKey,fTemp);  
                            Set<String> setTemp = mapExternalUrlToDocTypes.containsKey(bKey) ? mapExternalUrlToDocTypes.get(bKey) : new Set<String>();
                            setTemp.add('BR Audit');
                            mapExternalUrlToDocTypes.put(bKey, setTemp);
                            //fill map for deviation
                            if(objAccount.BR_Deviation__c){
                                Set<String> setDeviation = mapDeviationTypes.containsKey(bKey) ? mapDeviationTypes.get(bKey) : new Set<String>();
                                setDeviation.add('BR Audit');
                                mapDeviationTypes.put(bKey, setDeviation);
                            }
                        }else{
                            try {
                                helper.registerDomainToRemoteSiteSettings(objAccount.BR_Audit__c);
                                RunAuditArchiveBatchHelper.CalloutResult brAuditDoc = helper.doFetchDocument(objAccount.Id, objAccount.CA_Owner_Id__c, objAccount.BR_Audit_Statement_Date__c, objAccount.BR_Audit__c, 'BR Audit Document');
                            
                                if(brAuditDoc.documentSO.Body == null){//brAuditDoc.StatusCode == 500
                                    objAccount.BR_Audit_Update_Status__c = 'Failed';
                                    objAccount.BR_Audit_Update_Message__c = brAuditDoc.StatusCode != 500 ? 'Link is not pointing to PDF file.' : brAuditDoc.status;
                                }/*
                                else if(brAuditDoc.documentSO == null){
                                    objAccount.BR_Audit_Update_Status__c = 'Failed';
                                    objAccount.BR_Audit_Update_Message__c = 'Link is not pointing to PDF file.';
                                }*/else if(brAuditDoc.documentSO.ParentId != null && brAuditDoc.documentSO.body != null){
                                    mapTemp.put(objAccount.BR_Audit__c, brAuditDoc.documentSO);
                                }
                            } catch (Exception ex) {
                                objAccount.BR_Audit_Update_Status__c = 'Failed';
                                objAccount.BR_Audit_Update_Message__c = ex.getMessage();
                            }   
                        }
                    }
                    
                    //check for Code Signing Audit
                    if(objAccount.Code_Signing_Audit__c != null && objAccount.Code_Signing_Audit_Update_Status__c != 'Successful' && !mapTemp.containsKey(objAccount.Code_Signing_Audit__c)){
                        String csKey = objAccount.Code_Signing_Audit__c;
    
                        if(mapExistingFileArchive.containsKey(csKey)){
                            
                            File_Archive__c fTemp = mapExistingFileArchive.get(csKey);
                            objAccount.Code_Signing_Audit_Update_Status__c = 'Successful';
                            objAccount.Code_Signing_Statement_Internal_Link__c = fTemp.Internal_Link__c;
                            if(objAccount.Code_Signing_Audit_Period_Start_Date__c != null)
                                fTemp.Period_Start_Date__c = objAccount.Code_Signing_Audit_Period_Start_Date__c;
                            if(objAccount.Code_Signing_Audit_Period_End_Date__c != null)
                                fTemp.Period_End_Date__c = objAccount.Code_Signing_Audit_Period_End_Date__c;
                            if(objAccount.Code_Signing_Audit_Statement_Date__c != null)
                                fTemp.Audit_Statement_Date__c = objAccount.Code_Signing_Audit_Statement_Date__c;
                            if(objAccount.Auditor_New__c != null)
                                fTemp.Auditor__c = objAccount.Auditor_New__r.Name;
                            if(objAccount.Auditor_Location_New__c != null)
                                fTemp.Auditor_Location__c = objAccount.Auditor_Location_New__r.Name;
                            mapExistFileArchivesTosetPeriod.put(csKey,fTemp);
                            Set<String> setTemp = mapExternalUrlToDocTypes.containsKey(csKey) ? mapExternalUrlToDocTypes.get(csKey) : new Set<String>();
                            setTemp.add('Code Signing Audit');
                            mapExternalUrlToDocTypes.put(csKey, setTemp);
                            //fill map for deviation
                            if(objAccount.Code_Signing_Deviation__c){
                                Set<String> setDeviation = mapDeviationTypes.containsKey(csKey) ? mapDeviationTypes.get(csKey) : new Set<String>();
                                setDeviation.add('Code Signing Audit');
                                mapDeviationTypes.put(csKey, setDeviation);
                            }
                        }else{
                            try {
                                helper.registerDomainToRemoteSiteSettings(objAccount.Code_Signing_Audit__c);
                                RunAuditArchiveBatchHelper.CalloutResult evsignAuditDoc = helper.doFetchDocument(objAccount.Id, objAccount.CA_Owner_Id__c, objAccount.Code_Signing_Audit_Statement_Date__c, objAccount.Code_Signing_Audit__c, 'Code Signing Document');
                                
                                if(evsignAuditDoc.documentSO.Body == null){//brAuditDoc.StatusCode == 500
                                    objAccount.Code_Signing_Audit_Update_Status__c = 'Failed';
                                    objAccount.Code_Signing_Audit_Update_Message__c = evsignAuditDoc.StatusCode != 500 ? 'Link is not pointing to PDF file.' : evsignAuditDoc.status;
                                } else if(evsignAuditDoc.documentSO.ParentId != null && evsignAuditDoc.documentSO.body != null){
                                    mapTemp.put(objAccount.Code_Signing_Audit__c, evsignAuditDoc.documentSO);
                                }
                            } catch (Exception ex){
                                objAccount.Code_Signing_Audit_Update_Status__c = 'Failed';
                                objAccount.Code_Signing_Audit_Update_Message__c = ex.getMessage();
                            }
                        }
                    }
                    
                    //check for standard audit
                    if(objAccount.Standard_Audit__c != null && objAccount.Standard_Audit_Update_Status__c != 'Successful'){// && !mapTemp.containsKey(objAccount.Standard_Audit__c)
                        
                        String sKey = objAccount.Standard_Audit__c;
                        if(mapExistingFileArchive.containsKey(sKey)){
                            
                            File_Archive__c fTemp = mapExistingFileArchive.get(sKey);
                            objAccount.Standard_Audit_Update_Status__c = 'Successful';
                            objAccount.Standard_Audit_Statement_Internal_Link__c = fTemp.Internal_Link__c;
                            if(objAccount.Standard_Audit_Period_Start_Date__c != null)
                                fTemp.Period_Start_Date__c = objAccount.Standard_Audit_Period_Start_Date__c;
                            if(objAccount.Standard_Audit_Period_End_Date__c != null)
                                fTemp.Period_End_Date__c = objAccount.Standard_Audit_Period_End_Date__c;
                            //added Audit Statement date - 28th Dec 2017
                            if(objAccount.Standard_Audit_Statement_Date__c != null)
                                fTemp.Audit_Statement_Date__c = objAccount.Standard_Audit_Statement_Date__c;
                            if(objAccount.Auditor_New__c != null)
                                fTemp.Auditor__c = objAccount.Auditor_New__r.Name;
                            if(objAccount.Auditor_Location_New__c != null)
                                fTemp.Auditor_Location__c = objAccount.Auditor_Location_New__r.Name;
                            mapExistFileArchivesTosetPeriod.put(sKey,fTemp);          
                            Set<String> setTemp = mapExternalUrlToDocTypes.containsKey(sKey) ? mapExternalUrlToDocTypes.get(sKey) : new Set<String>();
                            setTemp.add('Standard Audit');
                            mapExternalUrlToDocTypes.put(sKey, setTemp); 
                            //fill map for deviation
                            if(objAccount.Standard_Deviation__c){
                                Set<String> setDeviation = mapDeviationTypes.containsKey(sKey) ? mapDeviationTypes.get(sKey) : new Set<String>();
                                setDeviation.add('Standard Audit');
                                mapDeviationTypes.put(sKey, setDeviation);
                            }
                        }else{
                            try {
                                helper.registerDomainToRemoteSiteSettings(objAccount.Standard_Audit__c);
                                RunAuditArchiveBatchHelper.CalloutResult stdAuditDoc = helper.doFetchDocument(objAccount.Id, objAccount.CA_Owner_Id__c, objAccount.Standard_Audit_Statement_Date__c, objAccount.Standard_Audit__c, 'Standard Audit Document');
                                //system.debug('stdAuditDoc  ::::'+stdAuditDoc );
                                if(stdAuditDoc.documentSO.Body == null){// && stdAuditDoc.StatusCode == 500
                                    objAccount.Standard_Audit_Update_Status__c = 'Failed';
                                    objAccount.Standard_Audit_Update_Message__c =  stdAuditDoc.StatusCode != 500 ? 'Link is not pointing to PDF file.' : stdAuditDoc.status;
                                }/*
                                else if(stdAuditDoc.documentSO == null){
                                    objAccount.Standard_Audit_Update_Status__c = 'Failed';
                                    objAccount.Standard_Audit_Update_Message__c = 'Link is not pointing to PDF file.';
                                }*/
                                else if(stdAuditDoc.documentSO.ParentId != null && stdAuditDoc.documentSO.body != null){
                                    mapTemp.put(objAccount.Standard_Audit__c, stdAuditDoc.documentSO);
                                }
                            } catch (Exception ex) {
                                objAccount.Standard_Audit_Update_Status__c = 'Failed';
                                objAccount.Standard_Audit_Update_Message__c = ex.getMessage();
                            }
                        }   
                    }
                } 
                
                //check document
                List<String> lstAuditInfo = new List<String>{'Code_Signing_Audit__c','EV_Code_Signing_Audit__c','EV_Audit__c','BR_Audit__c','Standard_Audit__c'};
                List<File_Archive__c> lstFileArchive = new List<File_Archive__c>();
                
                try {
                
                    insert mapTemp.values();
                    for(String externalURL : mapTemp.keySet()){
                        Attachment doc = mapTemp.get(externalURL);
                        
                        List<String> lstDocumentTypes = new List<String>();
                        List<String> lstDeviationTypes = new List<String>();
                        
                        String internalAuditLink = System.URL.getSalesforceBaseUrl().toExternalForm() + '/servlet/servlet.FileDownload?file=' + doc.Id;
                        File_Archive__c fileArchived = new File_Archive__c(Internal_Link__c = internalAuditLink,
                                        External_Link__c = externalURL,
                                        //Period_Start_Date__c = caseSO.Standard_Audit_Period_Start_Date__c,
                                        //Period_End_Date__c = caseSO.Standard_Audit_Period_End_Date__c,
                                        CA_Owner__c = doc.ParentId);
                        
                        for(String auditinfo : lstAuditInfo){
                            String auditURL = String.valueOf(objAccount.get(auditinfo));
                            //System.debug('auditURL: '+auditURL);
                            //System.debug('external URL: '+externalURL);
                            if(auditURL == externalURL){
                                
                                if(auditinfo == 'EV_Code_Signing_Audit__c'){
                                    
                                    fileArchived.Audit_Statement_Date__c = objAccount.EV_Code_Signing_Audit_Statement_Date__c;
                                    if(objAccount.EV_Code_Signing_Audit_Period_Start_Date__c != null)
                                        fileArchived.Period_Start_Date__c = objAccount.EV_Code_Signing_Audit_Period_Start_Date__c;
                                    if(objAccount.EV_Code_Signing_Audit_Period_End_Date__c != null)
                                        fileArchived.Period_End_Date__c = objAccount.EV_Code_Signing_Audit_Period_End_Date__c;
                                    lstDocumentTypes.add('EV Code Signing Audit');
                                    
                                    if(objAccount.EV_Code_Signing_Deviation__c){
                                        lstDeviationTypes.add('EV Code Signing Audit');
                                    }
                                    
                                    objAccount.EV_Code_Signing_Audit_Stmt_Int_Link__c = internalAuditLink;
                                    objAccount.EV_Code_Signing_Audit_Update_Status__c = 'Successful';
                                    objAccount.EV_Code_Signing_Audit_Update_Message__c = null;
                                } 
                                if(auditinfo == 'EV_Audit__c'){
                                    
                                    fileArchived.Audit_Statement_Date__c = objAccount.EV_Audit_Statement_Date__c;
                                    if(objAccount.EV_Audit_Period_Start_Date__c != null)
                                        fileArchived.Period_Start_Date__c = objAccount.EV_Audit_Period_Start_Date__c;
                                    if(objAccount.EV_Audit_Period_End_Date__c != null)
                                        fileArchived.Period_End_Date__c = objAccount.EV_Audit_Period_End_Date__c;
                                    lstDocumentTypes.add('EV SSL Audit');
                                    
                                    if(objAccount.EV_SSL_Deviation__c){
                                        lstDeviationTypes.add('EV SSL Audit');
                                    }
                                    
                                    objAccount.EV_Audit_Statement_Internal_Link__c = internalAuditLink;
                                    objAccount.EV_Audit_Update_Status__c = 'Successful';
                                    objAccount.EV_Audit_Update_Message__c = null;
                                }
                                 
                                if(auditinfo == 'BR_Audit__c'){
                                    
                                    fileArchived.Audit_Statement_Date__c = objAccount.BR_Audit_Statement_Date__c;
                                    if(objAccount.BR_Audit_Period_Start_Date__c != null)
                                        fileArchived.Period_Start_Date__c = objAccount.BR_Audit_Period_Start_Date__c;
                                    if(objAccount.BR_Audit_Period_End_Date__c != null)
                                        fileArchived.Period_End_Date__c = objAccount.BR_Audit_Period_End_Date__c;
                                    lstDocumentTypes.add('BR Audit');
                                    
                                    if(objAccount.BR_Deviation__c){
                                        lstDeviationTypes.add('BR Audit');
                                    }
                                    
                                    objAccount.BR_Audit_Statement_Internal_Link__c = internalAuditLink;
                                    objAccount.BR_Audit_Update_Status__c = 'Successful';
                                    objAccount.BR_Audit_Update_Message__c = null;
                                }
                                
                                if(auditinfo == 'Code_Signing_Audit__c'){
                                    
                                    fileArchived.Audit_Statement_Date__c = objAccount.Code_Signing_Audit_Statement_Date__c;
                                    if(objAccount.Code_Signing_Audit_Period_Start_Date__c != null)
                                        fileArchived.Period_Start_Date__c = objAccount.Code_Signing_Audit_Period_Start_Date__c;
                                    if(objAccount.Code_Signing_Audit_Period_End_Date__c != null)
                                        fileArchived.Period_End_Date__c = objAccount.Code_Signing_Audit_Period_End_Date__c;
                                    lstDocumentTypes.add('Code Signing Audit');
                                    
                                    if(objAccount.Code_Signing_Deviation__c){
                                        lstDeviationTypes.add('Code Signing Audit');
                                    }
                                    
                                    objAccount.Code_Signing_Statement_Internal_Link__c = internalAuditLink;
                                    objAccount.Code_Signing_Audit_Update_Status__c = 'Successful';
                                    objAccount.Code_Signing_Audit_Update_Message__c = null;
                                } 
                                
                                if(auditinfo == 'Standard_Audit__c'){
                                    
                                    fileArchived.Audit_Statement_Date__c = objAccount.Standard_Audit_Statement_Date__c;
                                    if(objAccount.Standard_Audit_Period_Start_Date__c != null)
                                        fileArchived.Period_Start_Date__c = objAccount.Standard_Audit_Period_Start_Date__c;
                                    if(objAccount.Standard_Audit_Period_End_Date__c != null)
                                        fileArchived.Period_End_Date__c = objAccount.Standard_Audit_Period_End_Date__c;
                                    lstDocumentTypes.add('Standard Audit');
                                    
                                    if(objAccount.Standard_Deviation__c){
                                        lstDeviationTypes.add('Standard Audit');
                                    }
                                    
                                    objAccount.Standard_Audit_Statement_Internal_Link__c = internalAuditLink;
                                    objAccount.Standard_Audit_Update_Status__c = 'Successful';
                                    objAccount.Standard_Audit_Update_Message__c = null;
                                }
                                  
                                if(objAccount.Auditor_New__c != null)
                                    fileArchived.Auditor__c = objAccount.Auditor_New__r.Name;
                                if(objAccount.Auditor_Location_New__c != null)
                                    fileArchived.Auditor_Location__c = objAccount.Auditor_Location_New__r.Name;
                            }
                        }
                        fileArchived.Document_Type__c = String.join(lstDocumentTypes, ';');
                        fileArchived.Audit_Deviation__c = String.join(lstDeviationTypes, ';');
                        lstFileArchive.add(fileArchived);
                    }
                    
                    for(string fKey: mapExistFileArchivesTosetPeriod.keyset()){
                        if(mapExistFileArchivesTosetPeriod.containskey(fKey) && mapExistFileArchivesTosetPeriod.get(fKey) != null) {
                            File_Archive__c fArchive = mapExistFileArchivesTosetPeriod.get(fKey);
        
                            fArchive.Period_Start_Date__c = mapExistFileArchivesTosetPeriod.get(fKey).Period_Start_Date__c;
                            fArchive.Period_End_Date__c = mapExistFileArchivesTosetPeriod.get(fKey).Period_End_Date__c;
                            //copy Audit statement date - 28th Dec 2017
                            fArchive.Audit_Statement_Date__c = mapExistFileArchivesTosetPeriod.get(fKey).Audit_Statement_Date__c;
                            fArchive.Auditor__c = mapExistFileArchivesTosetPeriod.get(fKey).Auditor__c;
                            fArchive.Auditor_Location__c = mapExistFileArchivesTosetPeriod.get(fKey).Auditor_Location__c;
                            if(mapExternalUrlToDocTypes.containskey(fKey) && mapExternalUrlToDocTypes.get(fKey) != null){
                                Set<String> setTemp = mapExternalUrlToDocTypes.get(fKey);
                                List<String> lstTemp = fArchive.Document_Type__c != null ? fArchive.Document_Type__c.split(';') : new List<String>();
                                setTemp.addAll(lstTemp);
                                lstTemp.clear();
                                lstTemp.addAll(setTemp);
                                fArchive.Document_Type__c = String.join(lstTemp, ';');
                            }
                            //set audit deviation for existing file archives
                            if(mapDeviationTypes.containskey(fKey) && mapDeviationTypes.get(fKey) != null){
                                Set<String> setTemp = mapDeviationTypes.get(fKey);
                                List<String> lstTemp = fArchive.Audit_Deviation__c != null ? fArchive.Audit_Deviation__c.split(';') : new List<String>();
                                setTemp.addAll(lstTemp);
                                lstTemp.clear();
                                lstTemp.addAll(setTemp);
                                fArchive.Audit_Deviation__c = String.join(lstTemp, ';');
                            }
                            lstFileArchive.add(fArchive);
                        }
                    }
                    
                    
                    /*
                        Query all File Archive records related to CA owner and fill map. Before upsering into File Archive, 
                        again check for duplicate File Archive records with same External url. If record exists, then update 
                        that record. This situation can happen when ETL tool such as Data Loader is used to update root and 
                        intermediate certs. 
                    */
                    mapExistingFileArchive = new map<string,File_Archive__c>();
                    for(File_Archive__c fArch : [SELECT Id, Document_Type__c, Internal_Link__c, External_Link__c,Auditor__c, 
                        Auditor_Location__c, CA_Owner__c,Period_Start_Date__c,Period_End_Date__c,Audit_Statement_Date__c 
                        FROM File_Archive__c Where CA_Owner__c =: objAccount.CA_Owner_Id__c]){
                        mapExistingFileArchive.put(fArch.External_Link__c, fArch); 
                    }
                    
                    //upsert lstFileArchive
                    if(lstFileArchive.size() > 0){
                        //check if file archive is already exist
                        for(File_Archive__c fa: lstFileArchive){
                            if(mapExistingFileArchive.containskey(fa.External_Link__c)){
                                fa.Id = mapExistingFileArchive.get(fa.External_Link__c).Id;
                            }
                        }
                        try {
                            upsert lstFileArchive;
                        } catch(Exception ex){
                            string ErrorMessage = 'Following error occurred when Upserting File Archive Records : ' + ex.getMessage() + ' at line ' + ex.getLineNumber();
                            sendEmail(ErrorMessage);
                        }
                    }
                    
                    //update account
                    update objAccount;
                    
                    //create and check existing File archive detail
                    List<File_Archive_Association__c> lstFileArchiveAssociation = new List<File_Archive_Association__c>();
                    for(File_Archive__c objFA: [select Id,External_Link__c,CA_Owner__c, (select Id,File_Archive__c, Certificate_Name__c from File_Archive_Associations__r) 
                            from File_Archive__c Where Id in: lstFileArchive and CA_Owner__c =: objAccount.CA_Owner_Id__c]){
                        boolean isAccountExist = false;
                        if(objAccount.EV_Code_Signing_Audit__c != null && objAccount.EV_Code_Signing_Audit__c == objFA.External_Link__c){
                            for(File_Archive_Association__c objFAD: objFA.File_Archive_Associations__r){
                                if(objFAD.Certificate_Name__c == objAccount.Id){
                                    isAccountExist = true;
                                }
                            }
                        } 
                        else if(objAccount.EV_Audit__c != null && objAccount.EV_Audit__c == objFA.External_Link__c){
                            for(File_Archive_Association__c objFAD: objFA.File_Archive_Associations__r){
                                if(objFAD.Certificate_Name__c == objAccount.Id){
                                    isAccountExist = true;
                                }
                            }
                        }
                        else if(objAccount.BR_Audit__c != null && objAccount.BR_Audit__c == objFA.External_Link__c){
                            for(File_Archive_Association__c objFAD: objFA.File_Archive_Associations__r){
                                if(objFAD.Certificate_Name__c == objAccount.Id){
                                    isAccountExist = true;
                                }
                            }
                        }
                        else if(objAccount.Standard_Audit__c != null && objAccount.Standard_Audit__c == objFA.External_Link__c){
                            for(File_Archive_Association__c objFAD: objFA.File_Archive_Associations__r){
                                if(objFAD.Certificate_Name__c == objAccount.Id){
                                    isAccountExist = true;
                                }
                            }
                        } else if(objAccount.Code_Signing_Audit__c != null && objAccount.Code_Signing_Audit__c == objFA.External_Link__c){
                            for(File_Archive_Association__c objFAD: objFA.File_Archive_Associations__r){
                                if(objFAD.Certificate_Name__c == objAccount.Id){
                                    isAccountExist = true;
                                }
                            }
                        } 
                        if(!isAccountExist){
                            File_Archive_Association__c objFAD = new File_Archive_Association__c();
                            objFAD.Certificate_Name__c = objAccount.Id;
                            objFAD.File_Archive__c = objFA.Id;
                            lstFileArchiveAssociation.add(objFAD);
                        }
                    }
                    
                    //insert File Archieve detail
                    if(lstFileArchiveAssociation.size() > 0){
                        insert lstFileArchiveAssociation;
                    }
                } catch (Exception ex){
                    string ErrorMessage = 'Following error occurred: ' + ex.getMessage() + ' at line ' + ex.getLineNumber();
                    sendEmail(ErrorMessage);
                }
            }
        }
    }
    
    /*
        Description: This method used to get user session Id.
    */
    private static final String NS_SOAP = 'http://schemas.xmlsoap.org/soap/envelope/';
    private static final String NS_SF = 'urn:partner.soap.sforce.com';
    
    public static string getSessionId(){ 
        try {
            HttpRequest req = new HttpRequest();
            req.setEndpoint('callout:Named_Credential_for_File_Archive/services/Soap/u/39.0');
            req.setMethod('POST');
            req.setHeader('Content-Type', 'text/xml;charset=UTF-8');        
            req.setHeader('SOAPAction', '""');
            req.setBody('<Envelope xmlns="http://schemas.xmlsoap.org/soap/envelope/"><Header/><Body><login xmlns="urn:partner.soap.sforce.com"><username>{!$Credential.Username}</username><password>{!$Credential.Password}</password></login></Body></Envelope>');  
            Http http = new Http();
            HTTPResponse res;
            if(!Test.isRunningTest()){
                res = http.send(req);
            } else {
                res = new HttpResponse();
                res.setStatusCode(200);
                res.setStatus('Completed');
                string sessionIdReponse = '<?xml version="1.0" encoding="UTF-8"?>'  +
                    '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns="urn:partner.soap.sforce.com" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">'  +
                        '<soapenv:Body> ' +
                            '<loginResponse> ' +
                                '<result> ' +
                                    '<metadataServerUrl>https://ccadb--Mozilla.cs91.my.salesforce.com/services/Soap/m/39.0/00D2F0000008aKa</metadataServerUrl> ' +
                                    '<passwordExpired>false</passwordExpired> ' +
                                    '<sandbox>true</sandbox> ' +
                                    '<serverUrl>https://ccadb--Mozilla.cs91.my.salesforce.com/services/Soap/u/39.0/00D2F0000008aKa</serverUrl> ' +
                                    '<sessionId>00D2F0000008aKa!AQ8AQEtTiiy96XT987YT7cpaBC5TB0bKREMBWs1XCLkkRi.o74cElMPb_fIse8e0otC19_V1T0Euepq7VlED_DOPR9uuQcdH</sessionId> ' +
                                    '<userId>0052F000000XLy9QAG</userId> ' +
                                    '<userInfo> ' +
                                        '<accessibilityMode>false</accessibilityMode> ' +
                                        '<currencySymbol>$</currencySymbol>'+
                                        '<orgAttachmentFileSizeLimit>5242880</orgAttachmentFileSizeLimit>'+
                                        '<orgDefaultCurrencyIsoCode>USD</orgDefaultCurrencyIsoCode>'+
                                        '<orgDefaultCurrencyLocale>en_US</orgDefaultCurrencyLocale>'+
                                        '<orgDisallowHtmlAttachments>false</orgDisallowHtmlAttachments>'+
                                        '<orgHasPersonAccounts>false</orgHasPersonAccounts>'+
                                        '<organizationId>00D2F0000008aKaUAI</organizationId>'+
                                        '<organizationMultiCurrency>false</organizationMultiCurrency>'+
                                        '<organizationName>Mozilla</organizationName>'+
                                        '<profileId>00eo0000000GTxgAAG</profileId>'+
                                        '<roleId>00Eo0000000QYdkEAG</roleId>'+
                                        '<sessionSecondsValid>7200</sessionSecondsValid>'+
                                        '<userDefaultCurrencyIsoCode xsi:nil="true"/>'+
                                        '<userEmail>test@gmail.com</userEmail>'+
                                        '<userFullName>Sunil Patel</userFullName>'+
                                        '<userId>0052F000000XLy9QAG</userId>'+
                                        '<userLanguage>en_US</userLanguage>'+
                                        '<userLocale>en_US</userLocale>'+
                                        '<userName>sunil@mozilla.org.mozilla</userName>'+
                                        '<userTimeZone>America/Los_Angeles</userTimeZone>'+
                                        '<userType>Standard</userType>'+
                                        '<userUiSkin>Theme3</userUiSkin>'+
                                    '</userInfo>'+
                                '</result>'+
                            '</loginResponse>'+
                        '</soapenv:Body>'+
                    '</soapenv:Envelope>';
                res.setBody(sessionIdReponse);
            }
            if(res.getStatusCode() != 200)
            {
                Dom.Document responseDocument = res.getBodyDocument();
                Dom.Xmlnode rootElm = responseDocument.getRootElement(); // soapenv:Envelope
                Dom.Xmlnode bodyElm = rootElm.getChildElement('Body', NS_SOAP); // soapenv:Body 
                Dom.Xmlnode faultElm = bodyElm.getChildElement('Fault', NS_SOAP); // soapenv:Fault
                Dom.Xmlnode faultStringElm = faultElm.getChildElement('faultstring', null); // faultstring   
            }
            Dom.Document responseDocument = res.getBodyDocument();
            Dom.Xmlnode rootElm = responseDocument.getRootElement(); // soapenv:Envelope
            Dom.Xmlnode bodyElm = rootElm.getChildElement('Body', NS_SOAP); // soapenv:Body 
            Dom.Xmlnode loginResponseElm = bodyElm.getChildElement('loginResponse', NS_SF); // loginResponse
            Dom.Xmlnode resultElm = loginResponseElm.getChildElement('result', NS_SF); // result
            Dom.Xmlnode sessionIdElm = resultElm.getChildElement('sessionId', NS_SF); // sessionId
            return sessionIdElm.getText();
        } catch (Exception ex){
            string ErrorMessage = 'Following error occurred: ' + ex.getMessage() + ' at line ' + ex.getLineNumber();
            ErrorMessage += '<br/>' + 'Please review Named Credential settings and make sure you have correct URL, Username and Password (Password+Security Token).';
            sendEmail(ErrorMessage);
            return null;
        }
    }
    
    /*
        This is method created to send exception email
    */
    public static void sendEmail(String customException) {
        List<OrgWideEmailAddress> lstOrgWideAdmin = [select id, Address, DisplayName from 
                    OrgWideEmailAddress where DisplayName = 'CCADB Admin'];
        if(lstOrgWideAdmin.size() > 0){
            String[] toAddresses = new String[]{};
            toAddresses.add(lstOrgWideAdmin[0].Address);
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            
            if(toAddresses.size() > 0) {
                mail.setToAddresses(toAddresses);
                //mail.setReplyTo(toAddresses[0]);    
            }
            mail.setSenderDisplayName('File Archive Exception');
            mail.setSubject('File Archive Future Exception');
            mail.setBccSender(false);
            mail.setUseSignature(false);
            mail.setPlainTextBody(customException);
            if(!Test.IsRunningTest()){
                Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
            }
        }
    }
    
    /*
    **
        Description: This method is used to copy File Archive Records when Intermediate certs is Audit same as parent.
    **
    public Static void CopyFileArchiveRecords(List<Account> lstAccounts, map<Id,Account> mapOldAccounts){
        
        String IntermediateCertRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Intermediate Certificate').getRecordTypeID();
        List<Account> lstAccountsToProcess = new List<Account>();
        List<Account> lstAccountsProcessToFetchFile = new List<Account>();
        
        if(Trigger.isAfter && (Trigger.isInsert || Trigger.isUpdate)){
        
            for(Account acc : lstAccounts){
                
                if(acc.Audits_Same_as_Parent__c && IntermediateCertRecordTypeId == acc.RecordTypeId && 
                    (Trigger.isInsert || (Trigger.isUpdate && acc.Audits_Same_as_Parent__c && !mapOldAccounts.get(acc.Id).Audits_Same_as_Parent__c))){
                    
                    lstAccountsToProcess.add(acc);
                }
                
                if(!acc.Audits_Same_as_Parent__c && Trigger.isUpdate){
                    
                    lstAccountsProcessToFetchFile.add(acc);
                }
            }
        }
        
        if(!lstAccountsToProcess.isEmpty()){
            CreateFileArchiveDetail(lstAccountsToProcess);
        }
        
        if(!lstAccountsProcessToFetchFile.isEmpty()){
            CreateFileArchiveRecords(lstAccountsProcessToFetchFile, mapOldAccounts);
        }
    }
    
    public static void CreateFileArchiveDetail(List<Account> lstAccountsNew){
        
        Map<String, List<String>> MapInterCertWithRootCert = new Map<String, List<String>>();
        List<File_Archive_Association__c> lstFileArchiveDetails = new List<File_Archive_Association__c>();
        
        for(Account acc : lstAccountsNew){
            
            List<string> lstTemp = MapInterCertWithRootCert.containsKey(acc.ParentId) ? MapInterCertWithRootCert.get(acc.ParentId) : new List<String>();
            lstTemp.add(acc.Id);
            MapInterCertWithRootCert.put(acc.ParentId, lstTemp);
        }
        
        if(!MapInterCertWithRootCert.isEmpty()){
            
            for(File_Archive_Association__c frd : [SELECT Id, Certificate_Name__c, File_Archive__c FROM
                                              File_Archive_Association__c
                                              WHERE Certificate_Name__c IN :MapInterCertWithRootCert.keySet()]){
                
                for(String intermediateCert : MapInterCertWithRootCert.get(frd.Certificate_Name__c)){
                    File_Archive_Association__c frdCopy = new File_Archive_Association__c(File_Archive__c = frd.File_Archive__c);
                    frdCopy.Certificate_Name__c = intermediateCert;
                    lstFileArchiveDetails.add(frdCopy);
                }
            }
        }
        
        if(!lstFileArchiveDetails.isEmpty()){
            
            insert lstFileArchiveDetails;
        }
    }*/

}
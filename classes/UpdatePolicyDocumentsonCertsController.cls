/*
    Description: Update Policy Documents on Certificates
*/
public with sharing class UpdatePolicyDocumentsonCertsController {
    
    public Id recordId;
    public Account objAccount {get; set;}
    public List<wrapAdditionalPolicyDocs> lstwrapAdditionalPolicyDocs {get; set;}
    public List<string> lstPolicyIdentifiers {get; set;} 
    
    public UpdatePolicyDocumentsonCertsController(){
        recordId = Apexpages.currentpage().getParameters().get('id');
        
        if(recordId  != null) {
            List<Account> lstAccount = new List<Account>([select Id,Name,Parent.Policy_Identifiers__c,
                    CA_Document_Repository__c,Policy_Documentation__c from Account where Id =: recordId]);
            if(lstAccount.size() > 0){
                objAccount = lstAccount[0];
                
                lstPolicyIdentifiers = new List<string>();
                if(objAccount.Parent.Policy_Identifiers__c != null){
                    string[] arrPolicyIdentifiers = objAccount.Parent.Policy_Identifiers__c.split(';');
                    for(string str: arrPolicyIdentifiers){
                        if(string.isnotblank(str)){
                            lstPolicyIdentifiers.add(str.trim());
                        }
                    }
                }
                lstPolicyIdentifiers.sort();
            }
            LoadAdditionalPolicyDocs();
        }
    }
    
    public void LoadAdditionalPolicyDocs(){
        try {
            lstwrapAdditionalPolicyDocs = new List<wrapAdditionalPolicyDocs>();
            
            List<Account> lstRootCases = new List<Account>([select Id, Name, Status__c, Microsoft_Status__c,
                                Revocation_Status__c, Valid_From_GMT__c, Valid_To_GMT__c, SHA_256_Fingerprint__c, 
                                Trust_Bits__c, Microsoft_Trust_Bits__c FROM
                                Account WHERE RecordType.Name = 'Root Certificate' and ParentId =: objAccount.ParentId 
                                AND (Status__c in ('Included','Change Requested') OR
                                Microsoft_Status__c In ('Included','Change Requested')) Order By Name]);
            
            set<Id> setOfPDCertificates = new set<Id>();
            for(PolicyDocumentAssociation_On_Certificate__c PDA: [select Id,Policy_Document__c,Certificate_Name__c from PolicyDocumentAssociation_On_Certificate__c Where Certificate_Name__c =: objAccount.Id]){
                setOfPDCertificates.add(PDA.Policy_Document__c);
            }
            
            if(setOfPDCertificates.size() > 0) {
            
                List<Policy_Document_On_Certificate__c> lstAdditionalPolicyDocs = new List<Policy_Document_On_Certificate__c>([select Id, Name, Associated_Trust_Bits__c,
                        Comments__c, Document_Last_Updated_Date__c, Document_Link__c, Document_Type__c,Policy_Identifiers__c,
                        (Select Id, Name, Certificate_Name__c,Policy_Document__c from Policy_Document_Associations__r)
                        FROM Policy_Document_On_Certificate__c
                        WHERE Id =: setOfPDCertificates]);
                //fill map of id with existing Ids. key as Certificate id and value as record
                map<string, PolicyDocumentAssociation_On_Certificate__c > mapOfApplyPolicyDocs = new map<string, PolicyDocumentAssociation_On_Certificate__c>();
                for(Policy_Document_On_Certificate__c Policy: lstAdditionalPolicyDocs){
                    for(PolicyDocumentAssociation_On_Certificate__c applyPolicy: Policy.Policy_Document_Associations__r){
                        string strKey = Policy.ID + '#' + applyPolicy.Certificate_Name__c;
                        mapOfApplyPolicyDocs.put(strKey, applyPolicy);
                    }
                }
                //system.debug('mapOfApplyPolicyDocs ::: '+mapOfApplyPolicyDocs);
                //fill wrapper with all root cases
                for(Policy_Document_On_Certificate__c Policydoc: lstAdditionalPolicyDocs){
                    wrapAdditionalPolicyDocs wrapPolicyDoc = new wrapAdditionalPolicyDocs();
                    wrapPolicyDoc.additionalPolicyDoc = Policydoc;
                    List<wrapApplyPolicyDocs> lstTempApplyPolicyDocs = new List<wrapApplyPolicyDocs>();
                    Integer count = 0;
                    for(Account objRoot: lstRootCases){
                        string Key = Policydoc.Id + '#' + objRoot.Id;
                        system.debug('Key  ::: '+Key );
                        if(mapOfApplyPolicyDocs.containskey(Key)){
                            lstTempApplyPolicyDocs.add(new wrapApplyPolicyDocs(true, objRoot, mapOfApplyPolicyDocs.get(Key)));
                            count++;
                        } else {
                            lstTempApplyPolicyDocs.add(new wrapApplyPolicyDocs(false, objRoot, new PolicyDocumentAssociation_On_Certificate__c (Certificate_Name__c = objRoot.Id, 
                                                    Policy_Document__c = Policydoc.Id)));
                        }
                    }
                    if(Policydoc.Policy_Identifiers__c != null && string.isnotblank(Policydoc.Policy_Identifiers__c)){
                        List<string> lstAllPI = Policydoc.Policy_Identifiers__c.split(';');
                        if(lstAllPI.size() > 0) {
                            lstAllPI.sort();
                            wrapPolicyDoc.lstdocPolicyIdentifiers  = lstAllPI;
                        }
                    }
                    wrapPolicyDoc.countRootCerts = count;
                    wrapPolicyDoc.lstApplyPolicyDocs = lstTempApplyPolicyDocs;
                    lstwrapAdditionalPolicyDocs.add(wrapPolicyDoc);
                }
            } else {
                //no association records.
                ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,'There is no Association records.');
                ApexPages.addMessage(myMsg);
                return;
            }
        } catch (Exception ex){
            Apexpages.addMessages(ex);
        }
    }
    
    public void SaveChanges(){
        //Create a savepoint
        Savepoint sp = Database.setSavepoint();
        try {
            //update Account
            update objAccount;
            
            List<Policy_Document_On_Certificate__c> lstAdditionalPolicyUpserts = new List<Policy_Document_On_Certificate__c>();
            
            map<Policy_Document_On_Certificate__c, List<PolicyDocumentAssociation_On_Certificate__c>> mapAdditionalPolicy = new map<Policy_Document_On_Certificate__c, List<PolicyDocumentAssociation_On_Certificate__c>>();
            
            List<PolicyDocumentAssociation_On_Certificate__c> lstApplyPolicyDelete = new List<PolicyDocumentAssociation_On_Certificate__c>();
            
            for(wrapAdditionalPolicyDocs wrapPolicy: lstwrapAdditionalPolicyDocs){
                if(wrapPolicy.additionalPolicyDoc.Document_Link__c == null || wrapPolicy.additionalPolicyDoc.Document_Type__c == null){
                    ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,'Document Type and Document Link is required for Doc Id - ' + (wrapPolicy.additionalPolicyDoc.ID != null ? wrapPolicy.additionalPolicyDoc.Name : 'New'));
                    ApexPages.addMessage(myMsg);
                }
                List<PolicyDocumentAssociation_On_Certificate__c> lstApplyPolicy = new List<PolicyDocumentAssociation_On_Certificate__c>();
                for(wrapApplyPolicyDocs applyPolicy: wrapPolicy.lstApplyPolicyDocs){
                    if(applyPolicy.isSelected){
                        if(applyPolicy.objApplyPolicyDoc.Certificate_Name__c == null && applyPolicy.objAcc.Id != null){
                            applyPolicy.objApplyPolicyDoc.Certificate_Name__c = applyPolicy.objAcc.Id;
                        }
                        lstApplyPolicy.add(applyPolicy.objApplyPolicyDoc);
                    } else if(applyPolicy.objApplyPolicyDoc.Id != null){
                        lstApplyPolicyDelete.add(applyPolicy.objApplyPolicyDoc);
                    }
                }
                lstAdditionalPolicyUpserts.add(wrapPolicy.additionalPolicyDoc);
                if(lstApplyPolicy.size() > 0) {
                    mapAdditionalPolicy.put(wrapPolicy.additionalPolicyDoc, lstApplyPolicy);
                }
            }
            //upsert additional CP CPS Upserts.
            upsert lstAdditionalPolicyUpserts;
            
            List<PolicyDocumentAssociation_On_Certificate__c> lstApplyPolicyUpsert = new List<PolicyDocumentAssociation_On_Certificate__c>();
            for(Policy_Document_On_Certificate__c addPolicy: lstAdditionalPolicyUpserts){
                if(mapAdditionalPolicy.containskey(addPolicy)){
                    for(PolicyDocumentAssociation_On_Certificate__c ApplyPolicy: mapAdditionalPolicy.get(addPolicy)){
                        /*PolicyDocumentAssociation_On_Certificate__c applyPolicyDoc = new PolicyDocumentAssociation_On_Certificate__c(Case__c = objCase.Id);
                        applyPolicyDoc.Policy_Document_On_Certificate__c = addPolicy.Id;
                        applyPolicyDoc.Certificate_Name__c = ApplyPolicy.Certificate_Name__c;
                        if(ApplyPolicy.Id != null) {
                            applyPolicyDoc.Id = ApplyPolicy.Id;
                        }*/
                        if(ApplyPolicy.Policy_Document__c == null){
                            ApplyPolicy.Policy_Document__c = addPolicy.Id;
                        }
                        lstApplyPolicyUpsert.add(ApplyPolicy);
                    }
                }
            }
            system.debug('lstApplyPolicyUpsert::: '+lstApplyPolicyUpsert);
            //upsert apply CP CPS 
            upsert lstApplyPolicyUpsert;
            
            if(lstApplyPolicyDelete.size() > 0){
                delete lstApplyPolicyDelete;
            }
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.CONFIRM,'Saved Sucessfully.');
            ApexPages.addMessage(myMsg);
            /*PageReference pg = new PageReference('/'+objCase.Id);
            return pg;*/
            return;
        } catch (Exception ex){
            Database.rollback(sp);
            Apexpages.addMessages(ex);
            return;
        }
    }
    
    public PageReference BackToRecord(){
        PageReference pg = new PageReference('/'+recordId);
        return pg;
    }
    
    public class wrapAdditionalPolicyDocs {
        public Policy_Document_On_Certificate__c additionalPolicyDoc {get; set;}
        public List<string> lstdocPolicyIdentifiers {get; set;}
        public Integer countRootCerts {get; set;}
        public List<wrapApplyPolicyDocs> lstApplyPolicyDocs {get; set;}
        public wrapAdditionalPolicyDocs(){
            additionalPolicyDoc = new Policy_Document_On_Certificate__c();
            lstdocPolicyIdentifiers = new List<string>();
            lstApplyPolicyDocs = new List<wrapApplyPolicyDocs>();
            countRootCerts = 0;
        }
    }
    
    public class wrapApplyPolicyDocs {
        public boolean isSelected {get; set;}
        public Account objAcc {get; set;}
        public PolicyDocumentAssociation_On_Certificate__c objApplyPolicyDoc {get; set;}
        public wrapApplyPolicyDocs(boolean isSel, Account acc, PolicyDocumentAssociation_On_Certificate__c PolicyDoc){
            this.isSelected = isSel;
            this.objAcc = acc;
            this.objApplyPolicyDoc = PolicyDoc;
        }
    }
}
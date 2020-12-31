/*
    Description: This class is created for Audit Cases intermediate page. When a user needs to add a new 
    root case an intermediate page display all root certifcates for user to select and edit fields
    
    This is class used for Audit and Inclusion type of cases to add or update root certs.
    
    Updates:
    06/23/2019    Changed on Line 59 to Copy PEM info each time, doesn't if root case is already exist or new root case is being created.
*/
public with sharing class RootCaseAddUpdateRootCertsController {
    
    Id caseOwnerId;
    public Case objCase;
    public boolean isCaseCompleted {get; set;}
    
    public List<WrapperRootCases> lstWrapAllRootCases{get; set;}
    
    public RootCaseAddUpdateRootCertsController(Apexpages.standardcontroller controller) {
        caseOwnerId = controller.getId();
        isCaseCompleted = false;
        lstWrapAllRootCases = new List<WrapperRootCases>();
        List<Case> lstCases = new List<Case>([select Id,AccountId,CaseNumber,Account.Name,Request_Status__c,
                    RecordType.Name from Case Where Id =: caseOwnerId]);
        
        if(lstCases.size() > 0) {
            objCase = lstCases[0];
            
            //get record type id for root cases
            string RCAuditUpdateRTId = ''; 
            string CaseRecordTypeName = objCase.RecordType.Name;
            if(Schema.SObjectType.Root_Case__c.getRecordTypeInfosByName().get(CaseRecordTypeName) != null){
                RCAuditUpdateRTId = Schema.SObjectType.Root_Case__c.getRecordTypeInfosByName().get(CaseRecordTypeName).getRecordTypeId();
            }
            
            if(objCase.Request_Status__c == 'Complete') {
                isCaseCompleted = true;
            }
            map<Id,Root_Case__c> mapExistingRootCases = new map<Id,Root_Case__c>();
            
            //fill map to find existing root cases.
            for(Root_Case__c rc: [Select Id, Root_Certificate_Name_Existing__c, Request_Status__c,
                                         Apply_Standard_Audit__c, Apply_Code_Signing_Audit__c,
                                         Apply_BR_Audit__c, Apply_EV_Audit__c, Apply_EV_Code_Signing_Audit__c,
                                         Mozilla_Status__c, Microsoft_Status__c, SHA_256_Fingerprint__c
                                  from   Root_Case__c Where Case_No__c =: objCase.Id]){
                mapExistingRootCases.put(rc.Root_Certificate_Name_Existing__c,rc);
            }
            
            //loop on all root certificates. 
            for(Account objAccount: [select Id, Name, Status__c, Microsoft_Status__c, SHA_256_Fingerprint__c,X_509_Certificate_PEM__c from 
                            Account Where Type = 'Root' 
                                      And ParentId =: objCase.AccountId 
                                      And Valid_To_GMT__c >= Today
                                      And (Status__c in ('Not Yet Included','Included','Change Requested') 
                                      or  Microsoft_Status__c In ('Not Included','Included','Change Requested','Pending','Not Before')) 
                                      Order By Name]){
                
            Root_Case__c objRC = new Root_Case__c();
            //boolean isDisable = false;
            boolean isReadOnly = false;
            boolean isSelected = false;
            objRC.Case_No__c = objCase.Id;
            objRC.X_509_Certificate_PEM__c = objAccount.X_509_Certificate_PEM__c;
            //if existing root case found, disable select option and copy values from existing root cases
               if(mapExistingRootCases.containskey(objAccount.Id)) {
                    objRC = mapExistingRootCases.get(objAccount.Id);
                    objRC.X_509_Certificate_PEM__c = objAccount.X_509_Certificate_PEM__c;
                    if(objRC.Request_Status__c != 'Initial Request Received') {
                        isReadOnly = true;
                    }
                    isSelected = true;
                } else {
                    //for new root certificates
                    objRC.CA_Owner_Name_Existing__c = objCase.AccountId;
                    if(string.isnotblank(RCAuditUpdateRTId)){
                        objRC.RecordTypeId = RCAuditUpdateRTId;
                    }
                    objRC.Root_Certificate_Name_Existing__c = objAccount.Id;
                    // objRC.Apply_Standard_Audit__c = true; do not set default
                }
                lstWrapAllRootCases.add(new WrapperRootCases(isSelected ,isReadOnly ,objRC,objAccount));
            }
        }
    }
    
    //method is used to upsert root cases based on selected root certificates
    public PageReference NextToRootCase(){
        List<Root_Case__c> lstRootCasesToUpsert = new List<Root_Case__c>();
        List<Root_Case__c> lstRootCasesToDelete = new List<Root_Case__c>();
        set<Id> setofRootCertIds = new set<Id>();
        for(WrapperRootCases objWrap: lstWrapAllRootCases){
            if(objWrap.objRootCase.Apply_Standard_Audit__c || objWrap.objRootCase.Apply_Code_Signing_Audit__c || objWrap.objRootCase.Apply_BR_Audit__c ||
                objWrap.objRootCase.Apply_EV_Audit__c || objWrap.objRootCase.Apply_EV_Code_Signing_Audit__c){
                if(objWrap.objRootCase.Root_Certificate_Name_Existing__c != null) {
                    setofRootCertIds.add(objWrap.objRootCase.Root_Certificate_Name_Existing__c);
                }
                lstRootCasesToUpsert.add(objWrap.objRootCase);
            } else if(objWrap.objRootCase.Id != null) {
                lstRootCasesToDelete.add(objWrap.objRootCase);
            }
        }
        try {
            if(lstRootCasesToUpsert.size() > 0) {
                upsert lstRootCasesToUpsert; // update or insert root case if any Apply field has changed
                //create policy documents.
                //CreatePolicyDocuments(setofRootCertIds, objCase.Id);
                ApexPages.AddMessage( new ApexPages.Message( ApexPages.Severity.CONFIRM, 'Root Cases created Successfully.'));
            } else {
                ApexPages.AddMessage( new ApexPages.Message( ApexPages.Severity.Error, 'Please select at least one root certificate to create Root case.'));
                return null;
            }
            if(lstRootCasesToDelete.size() > 0){
                delete lstRootCasesToDelete;  // delete root case if all Apply fields are unchecked
            }
        } catch (Exception ex){
            Apexpages.addMessages(ex);
            return null;
        }
        
        PageReference pg = new Pagereference('/'+objCase.Id);
        pg.setReDirect(true);
        return pg;
    }
    
    /*public static void CreatePolicyDocuments(set<Id> setOfRootCertIds, Id caseId){
        try {
            set<Id> setOfPolicyDocIds = new set<Id>();
            List<Policy_Document_Association__c> lstPolicyDocumentAssociations = new List<Policy_Document_Association__c>([select 
                        Id, Policy_Document__c from Policy_Document_Association__c Where 
                        Certificate_Name__c in: setOfRootCertIds]);
            for(Policy_Document_Association__c PDA: lstPolicyDocumentAssociations){
                setOfPolicyDocIds.add(PDA.Policy_Document__c);
            }
            
            set<Id> setOfExistingPolicyDocumentIds = new set<Id>();
            for(Policy_Document_On_Case__c PDC: [select Id,Source_Policy_Doc_Id__c from Policy_Document_On_Case__c WHERE Case__c =: caseId and 
                    Action__c != 'Deleted' AND Source_Policy_Doc_Id__c =: setOfPolicyDocIds]){
                setOfExistingPolicyDocumentIds.add(PDC.Source_Policy_Doc_Id__c);
            }
            system.debug('setOfExistingPolicyDocumentIds  ::: '+setOfExistingPolicyDocumentIds + ' setOfPolicyDocIds  :::'+setOfPolicyDocIds );
            map<Integer, Policy_Document_On_Case__c> mapPolicyDocumentsOnCase = new map<Integer, Policy_Document_On_Case__c>();
            map<Integer, List<Policy_Document_Association_On_Case__c>> mapPolicyDocumentsAssociations = new map<Integer, List<Policy_Document_Association_On_Case__c>>();
            Integer index = 0;
            for(Policy_Document_On_Certificate__c PDC: [select Id, Name, Associated_Trust_Bits__c,
                        Comments__c, Document_Last_Updated_Date__c, Document_Link__c, Document_Type__c,Policy_Identifiers__c,
                        (Select Id, Name, Certificate_Name__c,Policy_Document__c from Policy_Document_Associations__r)
                        FROM Policy_Document_On_Certificate__c 
                        WHERE Id =: setOfPolicyDocIds and Sync_Action__c != 'Deleted'
                        and Id !=: setOfExistingPolicyDocumentIds]){
                Policy_Document_On_Case__c PDCase = new Policy_Document_On_Case__c();
                PDCase.Case__c = caseId;
                PDCase.Associated_Trust_Bits__c = PDC.Associated_Trust_Bits__c;
                PDCase.Comments__c  = PDC.Comments__c;
                PDCase.Document_Last_Updated_Date__c  = PDC.Document_Last_Updated_Date__c;
                PDCase.Document_Link__c  = PDC.Document_Link__c;
                PDCase.Document_Type__c  = PDC.Document_Type__c;
                PDCase.Policy_Identifiers__c  = PDC.Policy_Identifiers__c;
                PDCase.Source_Policy_Doc_Id__c = PDC.Id;
                PDCase.Action__c = 'Copied From Root Cert';
                mapPolicyDocumentsOnCase.put(index, PDCase);
                
                List<Policy_Document_Association_On_Case__c> lstPolicyDocs = new List<Policy_Document_Association_On_Case__c>();
                for(Policy_Document_Association__c PDA: PDC.Policy_Document_Associations__r){
                    Policy_Document_Association_On_Case__c PDAssociation = new Policy_Document_Association_On_Case__c();
                    PDAssociation.Case__c = caseId;
                    PDAssociation.Certificate_Name__c = PDA.Certificate_Name__c;
                    PDAssociation.Source_Policy_Doc_Assoc_Id__c = PDA.Id;
                    PDAssociation.Action__c = 'Copied From Root Cert';
                    lstPolicyDocs.add(PDAssociation);
                }
                mapPolicyDocumentsAssociations.put(index, lstPolicyDocs);
                index++;
            }
            if(mapPolicyDocumentsOnCase.size() > 0){
                insert mapPolicyDocumentsOnCase.values();
                List<Policy_Document_Association_On_Case__c> lstPolicyAssociationDocsToInsert = new List<Policy_Document_Association_On_Case__c>();
                for(Integer count: mapPolicyDocumentsAssociations.keyset()){
                    if(mapPolicyDocumentsOnCase.containskey(count)){
                        Policy_Document_On_Case__c pdc = mapPolicyDocumentsOnCase.get(count);
                        for(Policy_Document_Association_On_Case__c pdac: mapPolicyDocumentsAssociations.get(count)){
                            pdac.Policy_Document__c = pdc.Id;
                            lstPolicyAssociationDocsToInsert.add(pdac);
                        }
                    }
                }
                insert lstPolicyAssociationDocsToInsert;
            } 
        } catch (Exception ex){
            Apexpages.addMessages(Ex);
        }
    }*/
    
    //wrapper class for displaying root certificates 
    public class WrapperRootCases {
        public boolean isSelected {get; set;} // For Action column NOT BEING USED 
        //public boolean isDisabled {get; set;}
        public boolean isReadOnly {get; set;}  // depends on Request Status
        public Root_Case__c objRootCase {get; set;} // for Root Case fields
        public Account objAccount {get; set;}  // for account fields like SHA-1 etc
        public WrapperRootCases(boolean isSel, boolean isRead, Root_Case__c objRC, Account objAcc){
            this.isSelected = isSel;
            this.isReadOnly = isRead;
            this.objRootCase = objRC;
            this.objAccount = objAcc;
        }        
    }
    
    
}
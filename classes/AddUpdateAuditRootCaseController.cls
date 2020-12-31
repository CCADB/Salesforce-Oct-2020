/*
    Description: This class is created for Audit Cases intermediate page. When a user needs to add a new 
    root case an intermediate page display all root certifcates for user to select and edit fields
*/
public with sharing class AddUpdateAuditRootCaseController {
    
    Id caseOwnerId;
    public Case objCase;
    public boolean isCaseCompleted {get; set;}
    
    public List<WrapperRootCases> lstWrapAllRootCases{get; set;}
    
    public AddUpdateAuditRootCaseController(Apexpages.standardcontroller controller) {
        caseOwnerId = controller.getId();
        isCaseCompleted = false;
        lstWrapAllRootCases = new List<WrapperRootCases>();
        List<Case> lstCases = new List<Case>([select Id,AccountId,CaseNumber,Account.Name,Request_Status__c from Case Where Id =: caseOwnerId]);
        
        //get record type id for root cases
        String RCAuditUpdateRTId = ''; 
        if(Schema.SObjectType.Root_Case__c.getRecordTypeInfosByName().get('CA Audit Update Request') != null){
            RCAuditUpdateRTId = Schema.SObjectType.Root_Case__c.getRecordTypeInfosByName().get('CA Audit Update Request').getRecordTypeId();
        }
        if(lstCases.size() > 0) {
            objCase = lstCases[0];
            if(objCase.Request_Status__c == 'Complete') {
                isCaseCompleted = true;
            }
            map<Id,Root_Case__c> mapExistingRootCases = new map<Id,Root_Case__c>();
            
            //fill map to find existing root cases.
            for(Root_Case__c rc: [Select Id, Root_Certificate_Name_Existing__c, Request_Status__c,
                                         Apply_Standard_Audit__c, Apply_BR_Audit__c, Apply_EV_Audit__c, Apply_EV_Code_Signing_Audit__c,
                                         Mozilla_Status__c, Microsoft_Status__c, SHA_256_Fingerprint__c
                                  from   Root_Case__c Where Case_No__c =: objCase.Id]){
                mapExistingRootCases.put(rc.Root_Certificate_Name_Existing__c,rc);
            }
            
            //loop on all root certificates. 
            for(Account objAccount: [select Id, Name, Status__c, Microsoft_Status__c, SHA_256_Fingerprint__c from 
                            Account Where Type = 'Root' and ParentId =: objCase.AccountId And (Status__c in ('Included','Change Requested') or
                            Microsoft_Status__c In ('Included','Change Requested')) Order By Name]){
                Root_Case__c objRC = new Root_Case__c();
                //boolean isDisable = false;
                boolean isReadOnly = false;
                boolean isSelected = false;
                objRC.Case_No__c = objCase.Id;
                //if existing root case found, disable select option and copy values from existing root cases
                if(mapExistingRootCases.containskey(objAccount.Id)) {
                    objRC = mapExistingRootCases.get(objAccount.Id);
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
        for(WrapperRootCases objWrap: lstWrapAllRootCases){
            if(objWrap.objRootCase.Apply_Standard_Audit__c || objWrap.objRootCase.Apply_BR_Audit__c ||
                objWrap.objRootCase.Apply_EV_Audit__c || objWrap.objRootCase.Apply_EV_Code_Signing_Audit__c){
                lstRootCasesToUpsert.add(objWrap.objRootCase);
            } else if(objWrap.objRootCase.Id != null) {
                lstRootCasesToDelete.add(objWrap.objRootCase);
            }
        }
        try {
            if(lstRootCasesToUpsert.size() > 0) {
                upsert lstRootCasesToUpsert; // update or insert root case if any Apply field has changed
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
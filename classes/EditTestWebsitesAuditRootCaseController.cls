/*
    Description: This class is created for Audit Cases transient page. "Edit Test Websites" invokes 
    EditTestWebsitesAuditRootCase VF page for users to update Test websites on multiple root cases.
    
    Root Case with Request Status <> "Intial Request Received" are not editable.
    
    If user enters blank or invalid url, an error will display at the top.
*/

public with sharing class EditTestWebsitesAuditRootCaseController {
    
    Id caseOwnerId;
    public Case objCase;
    public boolean isCaseCompleted {get; set;}
    
    public List<Root_Case__c> lstAllRootCases {get; set;}
    
    public EditTestWebsitesAuditRootCaseController(Apexpages.standardcontroller controller) {
        caseOwnerId = controller.getId();
        isCaseCompleted = false;
        
        lstAllRootCases = new List<Root_Case__c>();
        
        List<Case> lstCases = new List<Case>([select Id,AccountId,CaseNumber,Account.Name,
                                                     Standard_Audit_Statement_Link__c, BR_Audit_Statement_Link__c,EV_Audit_Statement_Link__c,
                                                     Request_Status__c
                                               from Case Where Id =: caseOwnerId]);
        
        if(lstCases.size() > 0) {
            objCase = lstCases[0];
            if(objCase.Request_Status__c == 'Complete') {
                isCaseCompleted = true;
            }
            //fill map to find existing root cases.
            lstAllRootCases = [Select Id, Root_Certificate_Name_Existing__c, Root_Certificate_Name_Existing__r.Name, Request_Status__c,
                                          Apply_Standard_Audit__c, Apply_BR_Audit__c, Apply_EV_Audit__c, Apply_EV_Code_Signing_Audit__c,
                                          Test_Website_Valid__c, Test_Website_Revoked__c, Test_Website_Expired__c, SHA_256_Fingerprint__c,
                                          Trust_Bits__c, Microsoft_Trust_Bits__c, Test_Website_Verified__c 
                                   from   Root_Case__c Where Case_No__c =: objCase.Id];
            
        }
    }
    
    //method is used to upsert root cases based on selected root certificates
    public PageReference UpdateRootCases(){
        try {
            if(lstAllRootCases.size() > 0) {
                string ErrorMessage = 'Please provide valid test website link, URL must begin with \'https\' and can only contain letters, numbers and following characters: + & @ # / % ? = ~- _ | ! : , . ; [ ] ( ) ';
                Pattern httpPattern = Pattern.compile('^[hH][tT][tT][pP][sS][0-9A-Za-z+&@#/%?=~\\-_|!:,.;\\[\\]()]*$');
                
                for(Root_Case__c objRC: lstAllRootCases){
                    // The test websites are only required if the CA indicates that the BR and/or EV SSL Audit applies to that root cert.
                    if((objRC.Apply_BR_Audit__c || objRC.Apply_EV_Audit__c) && (string.isblank(objRC.Test_Website_Valid__c) || string.isblank(objRC.Test_Website_Revoked__c) || string.isblank(objRC.Test_Website_Expired__c))) {
                        ApexPages.AddMessage(new ApexPages.Message( ApexPages.Severity.Error, objRC.Root_Certificate_Name_Existing__r.Name + ' - Test website link cannot be blank when BR and/or EV SSL Audit applies'));
                        return null;
                    }
                    if((objRC.Test_Website_Valid__c != null && !httpPattern.matcher(objRC.Test_Website_Valid__c).matches()) || 
                                    (objRC.Test_Website_Revoked__c != null && !httpPattern.matcher(objRC.Test_Website_Revoked__c).matches()) || 
                                    (objRC.Test_Website_Expired__c != null && !httpPattern.matcher(objRC.Test_Website_Expired__c).matches())){
                        ApexPages.AddMessage(new ApexPages.Message( ApexPages.Severity.Error, objRC.Root_Certificate_Name_Existing__r.Name + ' - '+ErrorMessage));
                        return null;
                    }
                }
                
                update lstAllRootCases; // update root case if any Apply field has changed
            } 
        } catch (Exception ex){
            Apexpages.addMessages(ex);
            return null;
        }
        
        PageReference pg = new Pagereference('/'+objCase.Id);
        pg.setReDirect(true);
        return pg;
    }   
}
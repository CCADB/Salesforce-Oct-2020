/*
    Description: Controller class to delete Intermediate or Root certs.
    Display error if the cert has PEM info or has a child record
    
    Update Log:
    None
*/
public with sharing class DeleteCertsController {
    
    public string accountId;
    public boolean isNotValid {get; set;}
    public string strMessage {get; set;}
    
    public DeleteCertsController(Apexpages.standardcontroller controller){
        accountId = controller.getId();
        isNotValid = false;
        List<Account> lstAcc = new List<Account>([Select Id, X_509_Certificate_PEM__c, (select Id from ChildAccounts) from Account Where Id =: accountId]);
        if(lstAcc.size() > 0){
            if(lstAcc[0].ChildAccounts.size() > 0){
                //ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ''));
                //strMessage = 'You cannot delete certificate because it has child certificates.';
                strMessage = 'This intermediate cert is parent to another cert. Cannot proceed to delete.';
                isNotValid = true; 
            } /*else if(lstAcc[0].X_509_Certificate_PEM__c != null && lstAcc[0].X_509_Certificate_PEM__c.length() > 0){
                //ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ''));
                strMessage = 'PEM Info is provided. You cannot delete the certificate.';
                isNotValid = true;
            }*/
        }
    }
    
    public PageReference deleteAccount(){
        
        List<Account> lstAcc = new List<Account>([Select Id, X_509_Certificate_PEM__c, (select Id from ChildAccounts) from Account Where Id =: accountId]);
        if(lstAcc.size() > 0 && !isNotValid){
            try {
                delete lstAcc[0];
                PageReference pg = new PageReference('/001/o');
                return pg;
            } catch(Exception ex){
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'You don\'t have permission to delete this certificate.'));
                return null;
            }
        } else {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Account Record is not found.'));
            return null;
        }
    }
}
// This is the batch job which iterates over all the CA Owner account with status 'Included' or
// 'Change Requested' and determines the list to send out reminder email notification to 
// the email alias on the associated CA Owner account. If the email alias info is not available on the CA Owner account
// then we need to send out the email notification to the Contact whose record type is Primary POC in 
// the TO address and all other contacts whose record type is POC in the CC address
// This is batch job finds out dated Inter certs and send email notification. 
//Updated on 4th Dec 18, Sending Summary email to Mozilla CA Program Manager.
//Updated on 28th Feb 19, Added a Flag to Update only Audit Alert Field and Send Email to CA and Summary. In start of batch we are updating All Intermediate certs's Alert as blank.
global class AuditReminderICWithOutdatedAuditStBatch implements Database.Batchable<sObject>, Database.stateful
{

    // this method fetches the records for which the execute method would be executed. 
    // we fetch all the ca owner accounts which are included or change requested
    
    global String mailBodyPlainStr = '';
    global String mailBodyHTMLStr = '';
    global AuditReminderMailWrapper auditReminderSummaryEmailStr = New AuditReminderMailWrapper() ;
    global boolean isSendEmailToCAAndSummary;
    
    global AuditReminderICWithOutdatedAuditStBatch(boolean blnSendEmailToCAAndSummary){
        this.isSendEmailToCAAndSummary = blnSendEmailToCAAndSummary;
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC) {
        //update all root certs with Mozilla Audit Alert as blank.
        List<Account> lstICAccounts = new List<Account>([select Id,Mozilla_Audit_Alert__c 
                from Account Where RecordType.DeveloperName = 'Intermediate_Certificate' and Mozilla_Audit_Alert__c != null]);
        if(lstICAccounts.size() > 0){
            for(Account objAcc: lstICAccounts){
                objAcc.Mozilla_Audit_Alert__c = '';
            }
            //partial update
            Database.update(lstICAccounts,false);
        }
        //id accountId = '0012900000LRCLv';
        String query = 'SELECT Id, name, CA_Email_Alias_1__c, CA_Email_Alias_2__c, CA_Comments__c FROM Account where Type=\'Owner\'  and status__c in (\'Included\',\'Change Requested\') ';
        // system.debug('query='+query);
        return Database.getQueryLocator(query);
    }
     
    // this method is executed for each batch of records returned by the start() method.
    // we delegate the batch to the helper class which takes care of the logic to 
    // send out email notification based on the data available on parent/ca owner account 
    
    global void execute(Database.BatchableContext BC, List<Account> scope)
    {
        AuditReminderICWithOutdatedAuditStHelper auditReminderHelperInstance = new AuditReminderICWithOutdatedAuditStHelper();
        
        AuditReminderMailWrapper  tempMailWrapper = auditReminderHelperInstance.processInterCertAccount(scope, isSendEmailToCAAndSummary);
        
        // system.debug('tempMailWrapper.plaintextBody -->'+tempMailWrapper.plaintextBody );
        if(tempMailWrapper.plaintextBody !=null && tempMailWrapper.plaintextBody.length() > 0)
        {
            if(tempMailWrapper.plaintextBody.contains('____')){
                auditReminderSummaryEmailStr.plaintextBody = auditReminderSummaryEmailStr.plaintextBody +  tempMailWrapper.plaintextBody;
            } else {
                auditReminderSummaryEmailStr.plaintextBody = auditReminderSummaryEmailStr.plaintextBody +  tempMailWrapper.plaintextBody + '<br/>____<br/><br/>';
            }
            
            // system.debug('auditReminderSummaryEmailStr.plaintextBody -->'+auditReminderSummaryEmailStr.plaintextBody);
        }
        // system.debug('tempMailWrapper.htmltextBody-->'+tempMailWrapper.htmltextBody);  
        if(tempMailWrapper.htmltextBody!=null && tempMailWrapper.htmltextBody.length() > 0)
        {
            if(tempMailWrapper.htmltextBody.contains('____')) {
                auditReminderSummaryEmailStr.htmltextBody= auditReminderSummaryEmailStr.htmltextBody + tempMailWrapper.htmltextBody;  
            } else {
                auditReminderSummaryEmailStr.htmltextBody= auditReminderSummaryEmailStr.htmltextBody+  tempMailWrapper.htmltextBody + '<br/>____<br/><br/>';  
            }
            // system.debug('auditReminderSummaryEmailStr.htmltextBody -->'+auditReminderSummaryEmailStr.htmltextBody);
        }
    }   
    
    // implementation of the finish method . As of now we do not do 
    // any processing once the batch is finished executing
    global void finish(Database.BatchableContext BC)  { 
        if(isSendEmailToCAAndSummary){
            sendSummaryEmail();
        }
    }
   
    private void sendSummaryEmail() { 
        // create a new instance of singleEmailMessage
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        
        // Set the 'from' display name and email address by using Organization Wide Emails for 'Mozilla'  
        for(OrgWideEmailAddress orgWide : [select id, Address, DisplayName from OrgWideEmailAddress where DisplayName = 'Mozilla CA Program Manager']) {
        
        mail.setOrgWideEmailAddressId(orgWide.id); 
        
        // set the TO addresses on the email
        mail.setToAddresses(new List<String>{orgWide.address});
        
        }
        
        mail.setSubject('Summary of ' + system.now().format('MMMM') + ' ' +  system.now().format('Y') + ' Outdated Audit Statements for Intermediate Certs');
        mail.setPlainTextBody(auditReminderSummaryEmailStr.plaintextBody);   
        mail.setHtmlBody(auditReminderSummaryEmailStr.htmltextBody);
        if(!Test.IsRunningTest()){
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail }); 
        }
    } 
   
}
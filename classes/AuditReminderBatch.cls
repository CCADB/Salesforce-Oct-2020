/*******************************************************************************************************
 Name: AuditReminderBatch
 
 Dependencies: AuditReminderBatchUpdateAlertFieldSchdlr class, AuditReminderBatchHelper class, 
 AuditReminderMailWrapper class, RunAuditReminderBatch VF page, RunAuditReminderSummaryOnly VF page,
 
 Description: This is the batch job which iterates over all the CA Owner (Account records) with 
 Mozilla Status 'Included' or 'Change Requested'. Then a helper class generated a list of 
 root certs which are expired or soon to expire and sends out reminder email notifications and 
 summary email. Two boolean flags SendSummaryEmailOnly and SendEmailToCAAndSummary are also used
 in the logic to send emails.
 
 SendSummaryEmailOnly is true then reminder emails are send to CAs and 
                If SendEmailToCAAndSummary

 
 By updating 'Mozilla Audit Alert', it makes it easy for users to use the field in standard reports. 
 
 Instructions: 
 
 Revisions:
 
     3/8/2015 - Created new class
     2/6/2019 - Added constructor which accepts true/false for sending email. 
                If SendSummaryEmailOnly is true then send only summary email to Mozilla CA Program Manager (org wide id)
                If SendEmailToCAAndSummary is true then send reminder alerts to CAs and summary email to 
                   Mozilla CA Program Manager (ord wide id)
                If SendEmailToCAAndSummary is false then send only summary email to Mozilla CA Program Manager (org wide id)
              
 ******************************************************************************************************/

global class AuditReminderBatch implements Database.Batchable<sObject>, Database.stateful
{

    // this method fetches the records for which the execute method would be executed. 
    // we fetch all the root accounts where reminder days is greater than zero
    
    global String mailBodyPlainStr = '';
    global String mailBodyHTMLStr = '';
    global AuditReminderMailWrapper auditReminderSummaryEmailStr = New AuditReminderMailWrapper() ;
    global boolean isSendSummaryEmailOnly;
    global boolean isSendEmailToCAAndSummary;
    
    global AuditReminderBatch(boolean blnSendSummaryEmailOnly, boolean blnSendEmailToCAAndSummary){
        isSendSummaryEmailOnly = blnSendSummaryEmailOnly;
        isSendEmailToCAAndSummary = blnSendEmailToCAAndSummary;
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC){
        //update all root certs with Mozilla Audit Alert as blank.
        List<Account> lstRootAccounts = new List<Account>([select Id,Mozilla_Audit_Alert__c 
                from Account Where RecordType.DeveloperName = 'Root_Certificate' and Mozilla_Audit_Alert__c != null]);
        if(lstRootAccounts.size() > 0){
            for(Account objAcc: lstRootAccounts){
                objAcc.Mozilla_Audit_Alert__c = '';
            }
            //partial update
            Database.update(lstRootAccounts,false);
        }
        String query = 'SELECT Id, name, CA_Email_Alias_1__c, CA_Email_Alias_2__c, CA_Comments__c FROM Account where Type=\'Owner\'  and status__c in (\'Included\',\'Change Requested\')  ';
        //query += ' and Id = \'001e000001EvSaEAAV\'';
        // system.debug('query='+query);
        return Database.getQueryLocator(query);
    }
     
    // this method is executed for each batch of records returned by the start() method.
    // we delegate the batch to the helper class which takes care of the logic to 
    // send out email notification based on the data available on parent/root account 
    
    global void execute(Database.BatchableContext BC, List<Account> scope)
    {
        AuditReminderBatchHelper auditReminderHelperInstance = new AuditReminderBatchHelper();
        
        AuditReminderMailWrapper  tempMailWrapper= auditReminderHelperInstance.processRootAccount(scope, isSendSummaryEmailOnly, isSendEmailToCAAndSummary);
        
        // system.debug('tempMailWrapper.plaintextBody -->'+tempMailWrapper.plaintextBody );
        if(tempMailWrapper.plaintextBody !=null && tempMailWrapper.plaintextBody.length() > 0)
        {
            if(tempMailWrapper.plaintextBody.contains('____'))
            {
                auditReminderSummaryEmailStr.plaintextBody = auditReminderSummaryEmailStr.plaintextBody +  tempMailWrapper.plaintextBody;
            }
            else
            {
                auditReminderSummaryEmailStr.plaintextBody = auditReminderSummaryEmailStr.plaintextBody +  tempMailWrapper.plaintextBody + '<br/>____<br/><br/>';
            }
            
            // system.debug('auditReminderSummaryEmailStr.plaintextBody -->'+auditReminderSummaryEmailStr.plaintextBody);
        }
        // system.debug('tempMailWrapper.htmltextBody-->'+tempMailWrapper.htmltextBody);  
        if(tempMailWrapper.htmltextBody!=null && tempMailWrapper.htmltextBody.length() > 0)
        {
            if(tempMailWrapper.htmltextBody.contains('____'))
            {
                auditReminderSummaryEmailStr.htmltextBody= auditReminderSummaryEmailStr.htmltextBody + tempMailWrapper.htmltextBody;  
            }
            else
            {
                auditReminderSummaryEmailStr.htmltextBody= auditReminderSummaryEmailStr.htmltextBody+  tempMailWrapper.htmltextBody + '<br/>____<br/><br/>';  
            }
            // system.debug('auditReminderSummaryEmailStr.htmltextBody -->'+auditReminderSummaryEmailStr.htmltextBody);
        }
    }   
    
    // implementation of the finish method . As of now we do not do 
    // any processing once the batch is finished executing
    global void finish(Database.BatchableContext BC)  { 
        if(isSendSummaryEmailOnly || isSendEmailToCAAndSummary){
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
        
        mail.setSubject('Summary of ' + system.now().format('MMMM') + ' ' +  system.now().format('Y') + ' Audit Reminder Emails');
        mail.setPlainTextBody(auditReminderSummaryEmailStr.plaintextBody);   
        mail.setHtmlBody(auditReminderSummaryEmailStr.htmltextBody);
        if(!Test.IsRunningTest()){
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
        }
    } 
}
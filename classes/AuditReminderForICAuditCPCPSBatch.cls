// This is the batch job which iterates over all the CA Owner account with status 'Included' or
// 'Change Requested' and determines the list to send out reminder email notification to 
// the email alias on the associated CA Owner account. If the email alias info is not available on the CA Owner account
// then we need to send out the email notification to the Contact whose record type is Primary POC in 
// the TO address and all other contacts whose record type is POC in the CC address
// 7/20/2020 - Changed Summary subject to 'Weekly Summary of Intermediate Certs Missing Audits'

global class AuditReminderForICAuditCPCPSBatch implements Database.Batchable<sObject>, Database.stateful
{

    // this method fetches the records for which the execute method would be executed. 
    // we fetch all the ca owner accounts which are included or change requested
    
    global String mailBodyPlainStr = '';
    global String mailBodyHTMLStr = '';
    global AuditReminderMailWrapper auditReminderSummaryEmailStr = New AuditReminderMailWrapper() ;
    
    global Database.QueryLocator start(Database.BatchableContext BC)
    {
        //id accountId = '0011k00000UtmQf';
        String query = 'SELECT Id, name, CA_Email_Alias_1__c, CA_Email_Alias_2__c, CA_Comments__c FROM Account where Type=\'Owner\'  and status__c in (\'Included\',\'Change Requested\')  ';
        //system.debug('query='+query);
        //query += ' AND Id =: accountId ';
        return Database.getQueryLocator(query);
    }
     
    // this method is executed for each batch of records returned by the start() method.
    // we delegate the batch to the helper class which takes care of the logic to 
    // send out email notification based on the data available on parent/ca owner account 
    
    global void execute(Database.BatchableContext BC, List<Account> scope)
    {
        AuditReminderForICAuditCPCPSBatchHelper auditReminderHelperInstance = new AuditReminderForICAuditCPCPSBatchHelper();
        
         AuditReminderMailWrapper  tempMailWrapper= auditReminderHelperInstance.processInterCertAccount(scope);
         
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
    
    
    sendSummaryEmail();
   
   }
   
    private void sendSummaryEmail() { 
    
        // create a new instance of singleEmailMessage
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        
        //Set the 'from' display name and email address by using Organization Wide Emails for 'Mozilla'  
        for(OrgWideEmailAddress orgWide : [select id, Address, DisplayName from OrgWideEmailAddress where DisplayName = 'Mozilla CA Program Manager']) {
        
            mail.setOrgWideEmailAddressId(orgWide.id); 
            
            // set the TO addresses on the email
            mail.setToAddresses(new List<String>{orgWide.address});
        
        }
        
        //mail.setSubject('Summary of ' + system.now().format('MMMM') + ' ' +  system.now().format('Y') + ' Audit Reminder Emails For Intermediate Certs');
        mail.setSubject('Weekly Summary of Intermediate Certs Missing Audits');
        mail.setPlainTextBody(auditReminderSummaryEmailStr.plaintextBody);   
        mail.setHtmlBody(auditReminderSummaryEmailStr.htmltextBody);
        if(!Test.IsRunningTest()){
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail }); 
        }
    } 
   
}
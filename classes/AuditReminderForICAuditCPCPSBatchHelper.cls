// This is the helper class for the AuditReminderForInterCertBatch job 
// 
// Disclosure Incomplete Email Reminder Logic:
// For each CA owner, create one audit reminder email for all of the intermediate certs that they own 
// that have missing audit/cp/cps statements. Attach the activity to the CA Owner record. Also set
// one user as 'CA Program Manager' in User object. The sender will be copied as BCC.
// 'Compliance BCC Email' may or may not be enabled. 
//
// Org Wide Email Address is being used to set 'From' and 'Display Name' of the out going email
// 
// For each Intermediate Cert, send email when ...
//
// IF (Audits_Same_as_Parent__c = FALSE and Standard_Audit__c = NULL) 
// OR
// IF (CP_CPS_Same_as_Parent__c = FALSE and Certificate_Policy_CP_255_char_c__c = NULL and Certification_Practice_Stat_CPS_255_char__c = NULL) 
// 
// Email Template: 'Need Audit or CP/CPS for Intermediate Certificates'
// 
// From: Org wide email address (support@ccadb.org)  
// To: <Primary POCs>
// CC: <Alias1 and Alias2> and <POCs if Alias1 and 2 are blank>
// BCC: CA Program Manager email address  * only if Compliance BCC Email has been enabled *
//
// Subject: Mozilla: Need Audit or CP/CPS for Intermediate Certificates 
// 
// Email template body contains following merge fields 
// - <Intermediate Cert Name 1>,<SHA256>
// - <Intermediate Cert Name 2>,<SHA256>
// - <Intermediate Cert Name 3>,<SHA256> etc
// 
// =======
// Also send a summary of individual emails to org wide email id from AuditReminderForICAuditCPCPSBatch which has 
// different suject name "Weekly Summary of Intermediate Certs Missing Audits"
// =======
//

//Updates -> added condition to skip expired certiticates.
//
// Revision History
//


public class AuditReminderForICAuditCPCPSBatchHelper {


 // This method iterates over a list of intermediate cert records (account record type = "Intermediate Certificate")
 // and processes them for audit reminder email notification
 
 public AuditReminderMailWrapper processInterCertAccount(List<Account> caOwnerAccountSOLLst ) {
     
     Set<Account> interCertAccountSOSet;
     String templateNameStr = ' ';
     String subjectStr = ' ';
     String caComments = ' ';
     
     AuditReminderMailWrapper  summaryMailWrapperInstance = New AuditReminderMailWrapper ();
     AuditReminderMailWrapper  tempMailWrapperInstance = new AuditReminderMailWrapper ();
     
  // iterate over each intermediate cert accounts
   for(Account accountSO : caOwnerAccountSOLLst)
      {
           interCertAccountSOSet = new Set<Account>();
          
           templateNameStr = ' ';  // initialize
           subjectStr = ' ';       // initialize
           caComments = 'CA Comments: ' + accountSO.CA_Comments__c;
           
          for(Account interCertAccountSO: [select Id, Name, Parent.Name , Standard_audit__c,  
                                                  Audits_Same_As_Parent__c, CP_CPS_Same_As_Parent__c,
                                                  Certificate_Policy_CP_255_char__c, Certification_Practice_Stat_CPS_255_Char__c,
                                                  Sha_256_fingerprint__c                                  
                                           from account where ca_owner_id__c = :accountSO.id
                                           and Valid_To_GMT__c > Today 
                                           and Type = 'Intermediate Certificate' 
                                           and Name != '<Fill in Cert Name>'
                                           and Revocation_Status__c = 'Not Revoked'
                                           and OneCRL_Status__c != 'Added to OneCRL'
                                           and Technically_Constrained__c = false])
          {
                                           
                            
                 // system.debug('accountSo Id = ' + accountSo.Id);
                 // system.debug('interCertAccount ID = ' + interCertAccountSO.Id);
                 
                 templateNameStr = 'Need_Audit_or_CP_CPS_for_Intermediate_Certificates';                     
                 subjectStr = 'Need Audit or CP/CPS for Intermediate Certificates';  
                  
                 if ((interCertAccountSO.audits_same_as_parent__c == false && 
                     interCertAccountSO.standard_audit__c == null) || 
                     (interCertAccountSO.cp_cps_same_as_parent__c == false &&
                     interCertAccountSO.certificate_policy_cp_255_char__c == null && 
                     interCertAccountSO.certification_practice_stat_cps_255_char__c == null))
                 {           
                    interCertAccountSOSet.add(interCertAccountSO);  // <Certificate Name>, <SHA256 Fingerprint> must be displayed in email
                 }
               
          }
          
          // create the lists which will hold the TO and CC email addresses
          List<String> toAddressesLst = new List<String>();
          List<String> ccAddressesLst = new List<String>(); 
          
          // system.debug('Sending email for Account ' + accountSo.Id); 
             
          // check if the email alias info is available on the ca owner account then add to CC address list               
                      
          try {
               
                 // add email alias 1 to the list if it is not null
                 if(accountSO.CA_Email_Alias_1__c!=null && accountSO.CA_Email_Alias_1__c.length() > 0)
                 {
                     ccAddressesLst.add(accountSo.CA_Email_Alias_1__c); 
                 }

                 // add email alias 2 to the list if it is not null             
                 if(accountSO.CA_Email_Alias_2__c!=null && accountSO.CA_Email_Alias_2__c.length() > 0)
                 {
                      ccAddressesLst.add(accountSo.CA_Email_Alias_2__c); 
                 }                      
              }
              catch(Exception ex) {
                   // System.debug('Exception type caught: ' + ex.getTypeName());    
                   // System.debug('Message: ' + ex.getMessage());    
                   // System.debug('Cause: ' + ex.getCause());    // returns null
                   // System.debug('Line number: ' + ex.getLineNumber());    
                   // System.debug('Stack trace: ' + ex.getStackTraceString());    
              }
             
             // fetch the Primary POC and POC contacts from the ca owner account
             List<Contact> contactLst = [select id, email, Type__c from contact where account.id=:accountSO.id and (Type__c = 'Primary POC' or Type__c = 'POC')];
               
             // if such contacts exists
             if(contactLst!=null && contactLst.size()>0)
             {               
                 // iterate over each contact record and add email address to the TO list or CC list
                 // Primary POC email address is added to TO list and POC email address is added to the CC list 
                 // only if email alias1 and 2 are missing
                 
                 for(Contact contactSO: contactLst)
                 {
                   if(contactSO.Type__c == 'Primary POC')
                   {
                       toAddressesLst.add(contactSO.email);
                   }                   
                   else if(contactSO.Type__c == 'POC' && accountSO.CA_Email_Alias_1__c == null && accountSO.CA_Email_Alias_2__c == null)
                   {
                       ccAddressesLst.add(contactSO.email);
                   }                     
                }                                        
             }
          
          if((toAddressesLst.size()>0 || ccAddressesLst.size()>0) && interCertAccountSOSet.size() > 0 )
          {
             // system.debug('Sending email to =' );
             // system.debug('interCertAccountSet = ' + interCertAccountSOSet);
            
             tempMailWrapperInstance  = sendEmail(toAddressesLst,ccAddressesLst,accountSo, subjectStr, templateNameStr, 
                       interCertAccountSOSet, caComments, tempMailWrapperInstance  );
             summaryMailWrapperInstance.htmlTextBody =  summaryMailWrapperInstance.htmlTextBody + tempMailWrapperInstance.htmlTextBody +  '<br/>____<br/><br/>';
             summaryMailWrapperInstance.plainTextBody =  summaryMailWrapperInstance.plainTextBody + tempMailWrapperInstance.plaintextBody + '<br/>____<br/><br/>';   
            
          }
          
      }
      
    return summaryMailWrapperInstance ;    
  }
    
    
    // this method sends out the email to the Primary POC and POC contacts associated with the ca owner account
    
    public AuditReminderMailWrapper  sendEmail(List<String> toAddressesLst, List<String> ccAddressesLst, Account interCertAccountSO,
                                 String subjectStr,String templateNameStr, Set<Account> interCertAccountSOSet, 
                                 String caComments, AuditReminderMailWrapper  mailWrapperInstance) {

    // create a new instance of singleEmailMessage
    Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
    
    // get the email template
    EmailTemplate emailTemplate = [select Id, Subject, HtmlValue, Body from EmailTemplate where developername = :templateNameStr];
        
    // get the HTML body from the template
    String htmlBody = emailTemplate.HtmlValue;
    
      // set the TO addresses on the email
    mail.setToAddresses(toAddressesLst);
    
    string bodyStr;
    
    
    // Set the 'from' display name and email address by using Organization Wide Emails for 'Mozilla' 
    // Special Note: DMARC policy caused emails sent by Microsoft user to fail, thus changed to CCAADB Support email alias - change done by Poonam  
    map<string, OrgWideEmailAddress> mapOWDs = new map<string, OrgWideEmailAddress>();
         
    for(OrgWideEmailAddress orgWide : [select id, Address, DisplayName from OrgWideEmailAddress where 
            DisplayName in ('Mozilla CA Program Manager', 'Reply-To Mozilla CA Program Manager')]) {
        mapOWDs.put(orgWide.DisplayName, orgWide);
    }
    if(mapOWDs.containskey('Mozilla CA Program Manager')){
        bodyStr = 'From Address: ' + mapOWDs.get('Mozilla CA Program Manager').Address + '\n\n';
        mail.setOrgWideEmailAddressId(mapOWDs.get('Mozilla CA Program Manager').id); 
    }
    
    
    // set the CC addresses on the email
    if(toAddressesLst!=null && toAddressesLst.size()>0)
     {
         bodyStr = bodyStr + 'To Addresses: ' + toAddressesLst+ '\n\n';
     }
    
    // set the CC addresses on the email
    if(ccAddressesLst!=null && ccAddressesLst.size()>0)
     {
         mail.setCCAddresses(ccAddressesLst);
         bodyStr = bodyStr + 'CC Addresses: ' + ccAddressesLst + '\n\n';
     }
     
     // These lines of code is replaced by organization wide email setting    
     List<User> userLst = [select id, email,name,firstname,lastname,companyname,title,phone from user 
                           where CA_Program_Manager__c = true order by name];    
     if(userLst!=null && userLst.size()>0)
     {
         List<String> bccAddressesLst = new List<String>();
         bccAddressesLst.add(userLst[0].email);
         mail.setBccAddresses(bccAddressesLst); // set BCC
         bodyStr = bodyStr + 'BCC Addresses: ' + bccAddressesLst + '\n\n';
         //mail.setReplyTo(userLst[0].email);     // added by Poonam 
         // mail.setSenderDisplayName(userLst[0].name);
     }   
     
    //changed on 3rd Oct 2020 - query on OWD for reply to
    if(mapOWDs.containskey('Reply-To Mozilla CA Program Manager')){
        mail.setReplyTo(mapOWDs.get('Reply-To Mozilla CA Program Manager').address);
        bodyStr = bodyStr + 'Reply To: ' + mapOWDs.get('Reply-To Mozilla CA Program Manager').address + '\n\n';
    }

    // set other mandatory parameters like subject, replyTo etc
    mail.setSubject(subjectStr);

    String interCertAccountHTMLStr = '<ul>';
    String interCertAccountSummaryEmailStr= 'Intermediate Certificates for '+interCertAccountSO.Name+': <br/>';
    String interCertAccountPlainStr = '' ;

    
    for(Account accountSo: interCertAccountSOSet)
    {
            
      interCertAccountHTMLStr  =  interCertAccountHTMLStr + '<li>' +  accountSo.name+', ' +accountSo.sha_256_fingerprint__c + '</li><br/>' ;
      interCertAccountSummaryEmailStr = interCertAccountSummaryEmailStr + '&nbsp;&nbsp;&nbsp;' + accountSo.name+', ' +accountSo.sha_256_fingerprint__c + '<br/>';
      interCertAccountPlainStr = (interCertAccountPlainStr!=null & interCertAccountPlainStr.length()>0)?  interCertAccountPlainStr + '- ' + (accountSo.name+', ' +accountSo.sha_256_fingerprint__c) + '\n' : '- ' + (accountSo.name+', ' +accountSo.sha_256_fingerprint__c) + '\n';
      
    }
    

    if(interCertAccountHTMLStr.length()> 3)
    {
        interCertAccountHTMLStr += '</ul>';
    }
     
   
     // if the HTML body is not null, provide values for all the merge fields in the template
    if(htmlBody!=null && htmlBody.length() > 0)
     {
        
        if(userLst!=null && userLst.size() > 0)
        {
           htmlBody = htmlBody.replace('{!User.FirstName}', userLst[0].FirstName == null ? ' ' : userLst[0].FirstName);
           htmlBody = htmlBody.replace('{!User.LastName}', userLst[0].LastName == null ? ' ' : userLst[0].LastName);
           htmlBody = htmlBody.replace('{!User.CompanyName}', userLst[0].CompanyName  == null ? ' ' : userLst[0].CompanyName);
           htmlBody = htmlBody.replace('{!User.Title}', userLst[0].Title   == null ? ' ' : userLst[0].Title);
           htmlBody = htmlBody.replace('{!User.Phone}', userLst[0].phone  == null ? ' ' : userLst[0].phone);           
        }
        
         htmlBody = htmlBody.replace('{!IntermediateCertificateList}', interCertAccountHTMLStr );

        //TODO set userInfo details.       
         mail.setHtmlBody(htmlBody);
         mailWrapperInstance.htmlTextbody = subjectStr + '<br/>' +  interCertAccountSummaryEmailStr + caComments + '<br/>';
         
         // system.debug('htmlBody-->'+htmlBody);
         // system.debug('wrapper.htmlBody-->'+mailWrapperInstance.htmlTextBody);
     }
    
    // get the plain text body from the template
    String plainBody = emailTemplate.Body;
    
    // if the plain text body is not null, provide values for all the merge fields in the template
    if(plainBody!=null && plainBody.length() > 0)
     {
        plainBody = plainBody.replace('{!IntermediateCertificateList}', interCertAccountPlainStr);

       if(userLst!=null && userLst.size()>0)
        {
          plainBody = plainBody.replace('{!User.FirstName}', userLst[0].FirstName == null ? ' ' : userLst[0].FirstName);
          plainBody = plainBody.replace('{!User.LastName}', userLst[0].LastName == null ? ' ' : userLst[0].LastName);
          plainBody = plainBody.replace('{!User.CompanyName}', userLst[0].CompanyName  == null ? ' ' : userLst[0].CompanyName);
          plainBody = plainBody.replace('{!User.Title}', userLst[0].Title   == null ? ' ' : userLst[0].Title);
          plainBody = plainBody.replace('{!User.Phone}', userLst[0].phone  == null ? ' ' : userLst[0].phone);
        }
        plainBody = plainBody.replace('<br/>','\n');
        plainBody = plainBody.replace('<ul>',' ');
        plainBody = plainBody.replace('</ul>',' ');
        plainBody = plainBody.replace('<li>',' ');
        plainBody = plainBody.replace('</li>',' ');     
 
       mail.setPlainTextBody(plainBody);   
       
       mailWrapperInstance.plaintextBody=   subjectStr + '<br/>' + interCertAccountHTMLStr + '<br/>' + caComments + '<br/>';
       system.debug('plainBody-->'+plainBody);
       system.debug('wrapper.plainBody-->'+mailWrapperInstance.plaintextBody);
     }
    
   
    if(!Test.IsRunningTest()) {
        // send out the email
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
    }
    
    // create a task record for the sent email so that it shows up 
    // on the related list for the corresponding inter certaccount
    
    createTask(mail.getSubject(),bodyStr + mail.getPlainTextBody(),userLst != null && userLst.size() > 0 ? userLst[0].id : UserInfo.getUserId(),interCertAccountSO.id);
                           
    return mailWrapperInstance;                           
    }
    
    // this method creates the task that would be associated with the corresponding inter certaccount
    // this lets the users know that an email was sent out for the inter certaccount
    public void createTask(String subject, String mailBody, String userId, String accountId)
    {
        
        Task taskSo = new Task();
        taskSo.subject = subject;
        taskSo.Description = mailBody; 
        taskSo.status = 'Completed';
        taskSo.OwnerId = userId; //user id        
        taskSo.WhatId = accountId; //record id
    
        insert taskSo; 
    
    }

}
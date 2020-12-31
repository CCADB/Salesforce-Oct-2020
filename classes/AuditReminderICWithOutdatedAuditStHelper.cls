/**************************************************************************************************************
    Description: Audit reminder batch for intermediate certs sends out emails regarding 
    outdated intermediate certificates.
    
  Related public report: 'Intermediate Certs With Outdated Audit Statements' 
  Related standard report: 'My Outdated Audit Statements for ICs'
  
  Intermediate Records are filtered By:
        CA Owner/Certificate Record Type equals Intermediate Certificate
        AND <Root Cert that it chains up to is in Mozilla's root store>
        AND Revocation Status not equal to Revoked,Parent Cert Revoked
        AND Valid To (GMT) greater than TODAY  <i.e. cert is not expired>
        AND Standard Audit Statement Date less than (TODAY - 1 year) <i.e. audits due>
        Sort by Standard Audit Statement Date, with oldest on top

  Email Template Used: 'Intermediate_Certs_With_Outdated_Audit_Statements'
 
  Emails settings:
     From: Org wide email address (support@ccadb.org)  
     To: <Primary POCs>
     CC: <Alias1 and Alias2> and <POCs if Alias1 and 2 are blank>
     BCC: CA Program Manager email address  * only if Compliance BCC Email has been enabled *

  Email template body contains following merge fields 
     - Count of inter certs for CA
     - List of intermediate certs (less than 10 displayed)
         <Intermediate Cert Name 1>, <SHA256>, <Std Audit St Dt>, <BR Audit St Dt>, <EV SSL Audit St Dt>
         <Intermediate Cert Name 2>, <SHA256>, <Std Audit St Dt>, <BR Audit St Dt>, <EV SSL Audit St Dt>
         <Intermediate Cert Name 3>, <SHA256>, <Std Audit St Dt>, <BR Audit St Dt>, <EV SSL Audit St Dt> etc

  Summary email of individual emails to org wide email id is also sent
 
  *** Revision History ***
  Create Date: 7/15/2018
  Update Date: 
  7/25/2018 Added summary email
  2/12/2019 Changed Condition from Standard Audit Statement Date to Standard Period End date and 
            also changed condition from 1 year to (1 year + 3 months)
            Code Signing Audit was missing. I added Code signing audit details in body.
  2/28/2019 Passed Flag to send emails to CA and Summary Email. Added code Update Audit Alert Field. 
  4/01/2019 Added audit period end date fields to Summary email
***************************************************************************************************************/

public with sharing class AuditReminderICWithOutdatedAuditStHelper {
    
    // This method iterates over a list of intermediate cert records (account record type = "Intermediate Certificate")
    // and processes them for audit reminder email notification
 
    public AuditReminderMailWrapper processInterCertAccount(List<Account> caOwnerAccountSOLLst, boolean isSendEmailToCAAndSummary) {
     
        Set<Account> interCertAccountSOSet;
        String templateNameStr = ' ';
        String subjectStr = ' ';
        String caComments = ' ';
        
        AuditReminderMailWrapper  summaryMailWrapperInstance = New AuditReminderMailWrapper ();
        AuditReminderMailWrapper  tempMailWrapperInstance = new AuditReminderMailWrapper ();
     
        //iterate over each intermediate cert accounts
        for(Account accountSO : caOwnerAccountSOLLst)
        {
            interCertAccountSOSet = new Set<Account>();
            
            templateNameStr = ' ';  // initialize
            subjectStr = ' ';       // initialize
            caComments = 'CA Comments: ' + accountSO.CA_Comments__c;
           
            for(Account interCertAccountSO: [SELECT Name, CA_Owner__c, Standard_Audit__c, Standard_Audit_Period_End_Date__c,
                           BR_Audit_Period_End_Date__c, EV_Audit_Period_End_Date__c,SHA_256_Fingerprint__c,Code_Signing_Audit_Period_End_Date__c
                           FROM Account WHERE Name != '<Fill in Cert Name>' and ca_owner_id__c =: accountSO.id
                           AND Record_Type_Name__c = 'Intermediate Certificate'
                           AND Revocation_Status__c NOT IN ('Revoked', 'Parent Cert Revoked')
                           AND Valid_To_GMT__c > TODAY AND Standard_Audit_Period_End_Date__c < LAST_N_DAYS:455
                           AND Root_Status__c IN  ('Included','Change Requested')  ORDER BY Standard_Audit_Period_End_Date__c]){
                                  
                 templateNameStr = 'Intermediate_Certs_With_Outdated_Audit_Statements';                     
                 subjectStr = 'Mozilla: Outdated Audit Statements for Intermediate Certificates';  
                  
                 interCertAccountSOSet.add(interCertAccountSO);               
            }
          
            //create the lists which will hold the TO and CC email addresses
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
            } catch(Exception ex) {
                // System.debug('Exception type caught: ' + ex.getTypeName());    
                // System.debug('Message: ' + ex.getMessage());    
                // System.debug('Cause: ' + ex.getCause());    // returns null
                // System.debug('Line number: ' + ex.getLineNumber());    
                // System.debug('Stack trace: ' + ex.getStackTraceString());    
            }
            
            // fetch the Primary POC and POC contacts from the ca owner account
            List<Contact> contactLst = [select id, email, Type__c from contact where account.id=:accountSO.id and (Type__c = 'Primary POC' or Type__c = 'POC')];
            
            // if such contacts exists
            if(contactLst!=null && contactLst.size()>0) {               
                // iterate over each contact record and add email address to the TO list or CC list
                // Primary POC email address is added to TO list and POC email address is added to the CC list 
                // only if email alias1 and 2 are missing
            
                for(Contact contactSO: contactLst) {
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
                interCertAccountSOSet, caComments, tempMailWrapperInstance, isSendEmailToCAAndSummary);
                summaryMailWrapperInstance.htmlTextBody =  summaryMailWrapperInstance.htmlTextBody + tempMailWrapperInstance.htmlTextBody +  '<br/>____<br/><br/>';
                summaryMailWrapperInstance.plainTextBody =  summaryMailWrapperInstance.plainTextBody + tempMailWrapperInstance.plaintextBody + '<br/>____<br/><br/>';   
                
            }
          
        }
        return summaryMailWrapperInstance ;    
    }
    
    
    // this method sends out the email to the Primary POC and POC contacts associated with the ca owner account
    
    public AuditReminderMailWrapper  sendEmail(List<String> toAddressesLst, List<String> ccAddressesLst, Account interCertAccountSO,
                                 String subjectStr,String templateNameStr, Set<Account> interCertAccountSOSet, 
                                 String caComments, AuditReminderMailWrapper  mailWrapperInstance, boolean isSendEmailToCAAndSummary) {

        // create a new instance of singleEmailMessage
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        
        // get the email template
        EmailTemplate emailTemplate = [select Id, Subject, HtmlValue, Body from EmailTemplate where developername = :templateNameStr];
            
        // get the HTML body from the template
        String htmlBody = emailTemplate.HtmlValue;
        
        String bodyStr;
    
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
        
        
        // set the TO addresses on the email
        mail.setToAddresses(toAddressesLst);
        
        bodyStr += 'To Addresses: ' + toAddressesLst + '\n\n';
        
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
             
             //bodyStr = bodyStr + 'Reply To: ' + userLst[0].email + '\n\n';
     
        } 
         
        //changed on 3rd Oct 2020 - query on OWD for reply to
        if(mapOWDs.containskey('Reply-To Mozilla CA Program Manager')){
            mail.setReplyTo(mapOWDs.get('Reply-To Mozilla CA Program Manager').address);
            bodyStr = bodyStr + 'Reply To: ' + mapOWDs.get('Reply-To Mozilla CA Program Manager').address + '\n\n';
        } 
        
        // set other mandatory parameters like subject, replyTo etc
        mail.setSubject(subjectStr);
    
        String interCertAccountHTMLStr = '<ul>';
        String interCertAccountSummaryEmailStr = 'CA Owner: '+ interCertAccountSO.Name + '<br/>';
        //interCertAccountSummaryEmailStr += interCertAccountSO.Name + '<br/>';
        String interCertAccountPlainStr = '' ;
    
        Integer count = 1;
        
        //update Mozilla audit alert
        List<Account> lstAccountToUpdate = new List<Account>();
        for(Account accountSo: interCertAccountSOSet)
        {
            //only if intermediate certs count is < 10
            if(count < 10) {
                
                string dtAuditStDate = 'null';
                if(accountSo.Standard_Audit_Period_End_Date__c != null) {
                    dtAuditStDate = DateTime.NewInstance(accountSo.Standard_Audit_Period_End_Date__c.year(),accountSo.Standard_Audit_Period_End_Date__c.month(), accountSo.Standard_Audit_Period_End_Date__c.day(),0,0,0).format('MM/dd/yyyy');
                }  
                string dtCodeSigningAuditStDate = 'null';
                if(accountSo.Code_Signing_Audit_Period_End_Date__c != null) {
                    dtCodeSigningAuditStDate = DateTime.NewInstance(accountSo.Code_Signing_Audit_Period_End_Date__c.year(),accountSo.Code_Signing_Audit_Period_End_Date__c.month(), accountSo.Code_Signing_Audit_Period_End_Date__c.day(),0,0,0).format('MM/dd/yyyy');
                } 
                string dtBRAuditStDate = 'null';
                if(accountSo.BR_Audit_Period_End_Date__c != null) {
                    dtBRAuditStDate = DateTime.NewInstance(accountSo.BR_Audit_Period_End_Date__c.year(),accountSo.BR_Audit_Period_End_Date__c.month(), accountSo.BR_Audit_Period_End_Date__c.day(),0,0,0).format('MM/dd/yyyy');
                } 
                string dtEVAuditStDate = 'null';
                if(accountSo.EV_Audit_Period_End_Date__c != null) {
                    dtEVAuditStDate = DateTime.NewInstance(accountSo.EV_Audit_Period_End_Date__c.year(),accountSo.EV_Audit_Period_End_Date__c.month(), accountSo.EV_Audit_Period_End_Date__c.day(),0,0,0).format('MM/dd/yyyy');
                }
                
                interCertAccountHTMLStr =  interCertAccountHTMLStr + '<li> Certificate Name: ' + accountSo.name + '<br/>SHA-256 Fingerprint: ' + accountSo.sha_256_fingerprint__c + '<br/>Standard Audit Period End Date (mm/dd/yyyy): ' + dtAuditStDate;
                if (dtCodeSigningAuditStDate != 'null') 
                    interCertAccountHTMLStr += '<br/>Code Signing Audit Period End Date (mm/dd/yyyy): ' + dtCodeSigningAuditStDate;
                if (dtBRAuditStDate != 'null') 
                    interCertAccountHTMLStr += '<br/>BR Audit Period End Date (mm/dd/yyyy): ' + dtBRAuditStDate;
                if (dtEVAuditStDate != 'null')   
                    interCertAccountHTMLStr += '<br/>EV SSL Audit Period End Date (mm/dd/yyyy): ' + dtEVAuditStDate;
                interCertAccountHTMLStr += '</li><br/>';
                           
                interCertAccountPlainStr += '- Certificate Name: ' +  accountSo.name + '\n  SHA-256 Fingerprint: ' + accountSo.sha_256_fingerprint__c + '\n  Standard Audit Period End Date (mm/dd/yyyy): ' + dtAuditStDate;
                if (dtCodeSigningAuditStDate != 'null') 
                    interCertAccountPlainStr += '\n  Code Signing Audit Period End Date (mm/dd/yyyy): ' + dtCodeSigningAuditStDate;
                if (dtBRAuditStDate != 'null') 
                    interCertAccountPlainStr += '\n  BR Audit Period End Date (mm/dd/yyyy): '+ dtBRAuditStDate;
                if (dtEVAuditStDate != 'null')    
                    interCertAccountPlainStr += '\n  EV SSL Audit Period End Date (mm/dd/yyyy): ' + dtEVAuditStDate;                
                interCertAccountPlainStr += '\n\n';
                
                string strSummaryInterCert = '- Certificate Name: ' +  accountSo.name + '<br/>  SHA-256 Fingerprint: ' + accountSo.sha_256_fingerprint__c + '<br/>  Standard Audit Period End Date (mm/dd/yyyy): ' + dtAuditStDate;
                if (dtCodeSigningAuditStDate != 'null') 
                    strSummaryInterCert += '<br/>  Code Signing Audit Period End Date (mm/dd/yyyy): ' + dtCodeSigningAuditStDate;
                if (dtBRAuditStDate != 'null') 
                    strSummaryInterCert += '<br/>  BR Audit Period End Date (mm/dd/yyyy): '+ dtBRAuditStDate;
                if (dtEVAuditStDate != 'null')    
                    strSummaryInterCert += '<br/>  EV SSL Audit Period End Date (mm/dd/yyyy): ' + dtEVAuditStDate;                
                strSummaryInterCert += '<br/><br/>';
                //interCertAccountSummaryEmailStr = interCertAccountSummaryEmailStr + '&nbsp;&nbsp;&nbsp;' + ' - ' + accountSo.name+', ' +accountSo.sha_256_fingerprint__c + '<br/>';
                interCertAccountSummaryEmailStr = interCertAccountSummaryEmailStr + '&nbsp;&nbsp;&nbsp;' + strSummaryInterCert;
            }
            //when count is more than 10 then shows this message
            if(count == 10 && interCertAccountSOSet.size() > 10)  
                interCertAccountSummaryEmailStr += '<br/>' + '&nbsp;&nbsp;&nbsp;' + '(Only 10 of the ' + interCertAccountSOSet.size() + ' records displayed)';            
            
            // interCertAccountPlainStr += '- Certificate Name: ' +  accountSo.name + '\n  SHA-256 Fingerprint: ' +accountSo.sha_256_fingerprint__c + '\n  Standard Audit Statement Date(mm/dd/yyyy): ' + dtAuditStDate  + '\n  Standard Audit Period Start Date(mm/dd/yyyy): '+ dtBRAuditStDate + '\n Standard Audit Period End Date(mm/dd/yyyy): ' + dtEVAuditStDate + '\n';
            
            //if(count == 10) break;
 
            count++;
            
            //set mozilla audit alert
            Account objAccToUpdate = new Account(Id = accountSo.id, Mozilla_Audit_Alert__c = subjectStr);
            lstAccountToUpdate.add(objAccToUpdate);
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
            
            //replace #
            if(interCertAccountSOSet.size() > 10) {
                htmlBody = htmlBody.replace('(#10#)', '(Only 10 of the ' + interCertAccountSOSet.size() + ' records displayed. For more please check the report)');
            } else {
                htmlBody = htmlBody.replace('(#10#)','');
            }
            
            htmlBody = htmlBody.replace('<#>',string.valueof(interCertAccountSOSet.size()));
            // htmlBody = htmlBody.replace('<#link to My Outdated Audit Statements>','https://ccadb.my.salesforce.com/00O1J000006HTpc');
            
            //TODO set userInfo details.       
            mail.setHtmlBody(htmlBody);
            // mailWrapperInstance.htmlTextbody = subjectStr + '<br/>' +  interCertAccountSummaryEmailStr + caComments + '<br/>';
            mailWrapperInstance.htmlTextbody = interCertAccountSummaryEmailStr + '<br/>';
             
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
            
            //replace #
            if(interCertAccountSOSet.size() > 10) {
                plainBody = plainBody.replace('(#10#)', '(Only 10 of the ' + interCertAccountSOSet.size() + ' records displayed. For more please check the report)');
            } else {
                plainBody = plainBody.replace('(#10#)','');
            }
            plainBody = plainBody.replace('<#>',string.valueof(interCertAccountSOSet.size()));
            // plainBody = plainBody.replace('<#link to My Outdated Audit Statements>','https://ccadb.my.salesforce.com/00O1J000006HTpc'); 
            mail.setPlainTextBody(plainBody);   
           
            mailWrapperInstance.plaintextBody=   subjectStr + '<br/>' + interCertAccountHTMLStr + '<br/>' + caComments + '<br/>';
            system.debug('plainBody-->'+plainBody);
            system.debug('wrapper.plainBody-->'+mailWrapperInstance.plaintextBody);
        }
        
        if(isSendEmailToCAAndSummary){
       
            if(!Test.IsRunningTest()) {
                // send out the email
                Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
            }
            
            // create a task record for the sent email so that it shows up 
            // on the related list for the corresponding inter certaccount
            
            createTask(mail.getSubject(),bodyStr + mail.getPlainTextBody(),userLst != null && userLst.size() > 0 ? userLst[0].id : UserInfo.getUserId(),interCertAccountSO.id);
        }
        //update audit alerts on intermediate certs 
        if(lstAccountToUpdate.size() > 0) {
            update lstAccountToUpdate;
        }
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
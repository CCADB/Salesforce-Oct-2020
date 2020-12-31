// This is the helper class for the AuditReminderBatch job 
// 
// Audit Reminder Logic:
// For each CA owner, create one audit reminder email for all of the root certs that they own 
// that have outdated audit statements. Attach the activity to the CA Owner Object. Also set
// one user as 'CA Program Manager' in User object. The sender will be copied as BCC.
// 'Compliance BCC Email' may or may not be enabled. Ignore Root Certs which have 'Do NOT send Audit Reminder'
// checked. 
//
// Org Wide Email Address is being used to set 'From' and 'Display Name' of the out going email
// 
// For each Root Cert Object:
// Check Standard Audit Statement Date when 
// Root Status = Included or Change Requested
// and Chosen Trust Bits is not empty and not equal to "All Trust Bits Turned Off"
// (If the Std Audit Dt is due then send reminder email and don't check for BR and EV)
// Check BR Audit Statement Date when 
// Root Status = Included or Change Requested
// and Chosen Trust Bits includes Websites
// (If the BR Audit Dt is due then send reminder email and don't check for EV)
// Check EV Audit Statement Date when 
// Root Status = Included or Change Requested
// and Chosen Trust Bits includes Websites
// and EV Policy OID(s) is not empty and not "Not EV".
// (If the EV Audit Dt is due then send reminder email)
// 
// Audit Reminder Email Templates
// 
// "-30 to 120 days past due" = The audit statement date is older than 1 year minus 30 days. 
// For example if the program were run on January 20, 2015, and it found an audit statement dated December 12, 2013,
// which is now over 1 year old, the first  "courtesy reminder" email would be sent.
// 
// ** For the Overdue and Danger notices, send the email to all of the email addresses we have on file for the
// CA (the aliases, Primary POC, *and* POCs)
// 
// <Note: list each audit and corresponding date only once; check for unique 'Audit' and pick any date from corresponding root cert>
// <Note: only show BR Audit info if one of the roots has the Websites trust bit set; check for unique BR Audit>
// <Note: only show the EV Audit info if one of the roots has an EV Policy OID; check for unique EV Audit>
// 
// From: Org wide email (support@ccadb.org) ** to avoid email failures due to DMARC policy
// BCC: CA Program Manager email address  * Compliance BCC Email has been enabled *
// 
// ==== Reminder: Audit statements due (start with -30 to 120 days past due) ====
//      Email Template: Audit_Reminder_Level_1
//      TO: <Primary POC>, 
//      CC: <POCs, only if Alias1 and Alias2 null> and <Alias1 & Alias2>
//      Subject: Mozilla Audit Reminder 
// 
//      Email template body contains following merge fields 
//      - <Root Cert Name 1>
//      - <Root Cert Name 2>
//      - <Root Cert Name 3> etc    ** asterisk is added to root certs, if there is an open audit case for it
// 
//      Audit: <Standard Audit>
//      Audit Statement Date: <Standard Audit Statement Date>
// 
//      BR Audit: <BR Audit>
//      BR Audit Statement Date: <BR Audit Statement Date>
// 
//      EV Audit: <EV Audit>
//      EV Audit Statement Date: <EV Audit Statement Date>
// 
// ==== Overdue (start with 120 to 240 days past due) ====
//      Email Template: Audit_Reminder_Level_2
//      TO: <Primary POC>, 
//      CC: <POCs> and <Alias1 & Alias2>
//      Subject: Mozilla: Overdue Audit Statements
// 
//      Email template body is same as above
// 
// ==== Danger of root being removed (start with 240 days and over past due) ====
//      Email Template: Audit_Reminder_Level_3
//      TO: <Primary POC>, 
//      CC: <POCs> and <Alias1 & Alias2>
// 
//      Email template body is same as above
//
// =======
// A summary of individual emails is created and sent to org wide email id (Mozilla CA Program Manager)
// =======
//
// *** IMPORTANT *** FOR TESTING: Check for CCADB Support (from address) & Mozilla CA Manager (bcc address)
// Orgwide settings, Microsoft CA Program Manager in User record, Contact Email field, CA Owner Email Alias1 & 2 for email address
//
//
// 1/22/2019 Replace Audit Dates with Audit Period End Dates 
//
// 2/5/2019 Added blnSendEmail flag, if flag is true -> send email alerts to the CAs and summary email to Mozilla CA Program Manager.
//          else only send summary email to Mozilla CA Program Manager. Only summary can be send from tab "Run Audit Reminder Summary" 
//
// 2/7/2019 Changed date ranges for audit alerts in the controller class and email templates
//          FROM: Over 1 year -30 to 120 days past due       TO: Over 1 year plus 31 days to 93 days past due
//          FROM: Over 1 year plus 120 to 240 days past due  TO: Over 1 year plus 93 to 150 days past due 
//          FROM: Over 1 year plus 240 days past due         TO: Over 1 year plus 150 days past due
//
// 2/26/2019 Update Mozilla Audit Alert field with email 'Subject'
//
// !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
//
//  TODO ====> Update Activity record Standard Audit Statement Date for History Report
//
// !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!


public class AuditReminderBatchHelper {


    // This method iterates over a list of root accounts and processes them for audit reminder email notification
    public AuditReminderMailWrapper processRootAccount(List<Account> parentAccountSoLLst, 
                boolean blnSendSummaryEmail, boolean blnSendEmailToCAAndSummary) {
    
        Set<Account> rootAccountSOSet;
        String templateNameStr = ' ';
        String subjectStr = ' ';
        String caComments = ' ';
        String WEBSITES = 'Websites';
        Boolean showBRAuditInfo=FALSE;
        Boolean showEVAuditInfo=FALSE;
        Date consideredDate;
        AuditReminderMailWrapper  summaryMailWrapperInstance = New AuditReminderMailWrapper ();
        AuditReminderMailWrapper  tempMailWrapperInstance = new AuditReminderMailWrapper ();
        
        // iterate over each root account
        for(Account accountSO : parentAccountSoLLst){
            rootAccountSOSet = new Set<Account>();
            
            templateNameStr = ' ';  // initialize
            subjectStr = ' ';       // initialize
            showBRAuditInfo=FALSE;  // initialize
            showEVAuditInfo=FALSE;  // initialize
            caComments = 'CA Comments: ' + accountSO.CA_Comments__c;
        
            for(Account rootAccountSo: [select id, parentid, name, Standard_Audit__c,br_Audit__c,ev_Audit__c, 
                                    ev_policy_oid_s__c, trust_bits__c,Standard_Audit_Period_End_Date__c,
                                    BR_Audit_Period_End_Date__c,EV_Audit_Period_End_Date__c,parent.name                                    
                                    from account where parentid = :accountSO.id and Type = 'Root' 
                                    and status__c in ('Included','Change Requested')
                                    and name != '<Fill in Cert Name>'
                                    and Do_NOT_Send_Audit_Reminder__c = False]){
                if(!showBRAuditInfo){
                    showBRAuditInfo = (rootAccountSo.trust_bits__c!=null && rootAccountSo.trust_bits__c.length() > 0 && rootAccountSo.trust_bits__c.contains(WEBSITES)) ? true : false;
                }
                
                if(!showEVAuditInfo){
                    showEVAuditInfo = (rootAccountSo.trust_bits__c!=null && rootAccountSo.trust_bits__c.length()>0 && rootAccountSo.trust_Bits__c.contains(WEBSITES) 
                                && rootAccountSo.ev_policy_oid_s__c!=null && rootAccountSo.ev_policy_oid_s__c!='Not EV') ? true : false; 
                }
                
                if(rootAccountSo.trust_bits__c!=null && !rootAccountSo.trust_Bits__c.contains('Off') && rootAccountSo.Standard_Audit_Period_End_Date__c!=null 
                        && Math.abs(system.today().daysBetween(rootAccountSo.Standard_Audit_Period_End_Date__c)) > 396){
                    consideredDate = rootAccountSo.Standard_Audit_Period_End_Date__c;
                    rootAccountSOSet.add(rootAccountSo);
                } else if(rootAccountSo.trust_bits__c!=null && rootAccountSo.trust_Bits__c.contains(WEBSITES) && rootAccountSo.BR_Audit_Period_End_Date__c !=null 
                        && Math.abs(system.today().daysBetween(rootAccountSo.BR_Audit_Period_End_Date__c)) > 396){
                    consideredDate = rootAccountSo.BR_Audit_Period_End_Date__c;
                    rootAccountSOSet.add(rootAccountSo);
                } else if(rootAccountSo.trust_bits__c != null && rootAccountSo.trust_bits__c.length() > 0 && rootAccountSo.trust_Bits__c.contains(WEBSITES)
                        && rootAccountSo.ev_policy_oid_s__c != null && rootAccountSo.ev_policy_oid_s__c != 'Not EV' && rootAccountSo.EV_Audit_Period_End_Date__c !=null 
                        && Math.abs(system.today().daysBetween(rootAccountSo.EV_Audit_Period_End_Date__c)) > 396){
                    consideredDate = rootAccountSo.EV_Audit_Period_End_Date__c;
                    rootAccountSOSet.add(rootAccountSo);
                }
                
                if(consideredDate!=null){
                    If( consideredDate!=null &&  Math.abs(system.today().daysBetween(consideredDate)) > 396 &&  Math.abs(system.today().daysBetween(consideredDate)) <= 458){
                        templateNameStr='Audit_Reminder_Level_1';                        
                        subjectStr = 'Mozilla: Audit Reminder'; // Over 1 year plus 31 to 93 days past due 
                    }
                    else If(consideredDate!=null && Math.abs(system.today().daysBetween(consideredDate)) > 458 &&   Math.abs(system.today().daysBetween(consideredDate)) <= 515){
                        templateNameStr = 'Audit_Reminder_Level_2';                      
                        subjectStr = 'Mozilla: Overdue Audit Statements'; // Over 1 year plus 93 to 150 days past due  
                    }   
                    else if (consideredDate!=null && Math.abs(system.today().daysBetween(consideredDate)) > 515){   
                        templateNameStr = 'Audit_Reminder_Level_3';                     
                        subjectStr = 'Mozilla: Your root is in danger of being removed';  // Over 1 year plus 150 days past due
                    }
                }
            }
               
            //create the lists which will hold the TO and CC email addresses
            List<String> toAddressesLst = new List<String>();
            List<String> ccAddressesLst = new List<String>();  
        
            // check if the email alias info is available on the parent account and add to CC list 
            if((accountSO.CA_Email_Alias_1__c != null && accountSO.CA_Email_Alias_1__c.length() >0 ) || (accountSO.CA_Email_Alias_2__c != null && accountSO.CA_Email_Alias_2__c.length() >0 )){
        
                // if email alias info is available on the parent account then we need to send the 
                // the audit reminder email notification to these email addresses
                try {
                    // add email alias 1 to the list if it is not null
                    if(accountSO.CA_Email_Alias_1__c!=null && accountSO.CA_Email_Alias_1__c.length() > 0){
                        ccAddressesLst.add(accountSo.CA_Email_Alias_1__c); 
                    }
                    
                    // add email alias 2 to the list if it is not null             
                    if(accountSO.CA_Email_Alias_2__c!=null && accountSO.CA_Email_Alias_2__c.length() > 0){
                        ccAddressesLst.add(accountSo.CA_Email_Alias_2__c); 
                    }       
                }
                catch(Exception ex) {
                    // System.debug('Exception Message: ' + ex.getMessage());
                }
            }
            
            // fetch the Primary POC and POC contacts from the parent account
            List<Contact> contactLst = [select id, email, Type__c from contact where account.id=:accountSO.id and (Type__c = 'Primary POC' or Type__c = 'POC')];
             
             // iterate over each contact record and add their email address to their corresponding list based on the 
             // record type Primary POC email address is added to TO list and POC email address is added to the CC list
               
            if(contactLst!=null && contactLst.size()>0){               
                                                     
               for(Contact contactSO: contactLst) {
               
                   // For Audit_Reminder_Level_1, send email ...
                   // TO: Primary POC 
                   // CC: Alias1, Alias2 
                   // CC: POC <when Alias1 & Alias2 are blank>
                   
                   // For Audit_Reminder_Level_2 & Audit_Reminder_Level_3, send email ...
                   // TO: Primary POC 
                   // TO: Alias1, Alias2 
                   // CC: POC

                   if (templateNameStr == 'Audit_Reminder_Level_1') {
                   
                        if(contactSO.Type__c == 'Primary POC'){
                            toAddressesLst.add(contactSO.email);
                        }
                        else if(contactSO.Type__c == 'POC' && 
                                accountSO.CA_Email_Alias_1__c == null && 
                                accountSO.CA_Email_Alias_2__c == null){
                            ccAddressesLst.add(contactSO.email);
                        }       
                    }
                    else if (templateNameStr == 'Audit_Reminder_Level_2' || 
                             templateNameStr == 'Audit_Reminder_Level_3') {
                         if(contactSO.Type__c == 'Primary POC'){
                            toAddressesLst.add(contactSO.email);
                         }
                         else if(contactSO.Type__c == 'POC'){
                            ccAddressesLst.add(contactSO.email);
                         } 
                    }              
                }
            }                                   
        
            if((toAddressesLst.size()>0 || ccAddressesLst.size()>0) && rootAccountSoSet.size() > 0 ){
                tempMailWrapperInstance  = sendEmail(toAddressesLst,ccAddressesLst,accountSo, subjectStr, templateNameStr, 
                rootAccountSoSet, showBRAuditInfo, showEVAuditInfo, caComments, tempMailWrapperInstance, blnSendSummaryEmail, blnSendEmailToCAAndSummary);
                summaryMailWrapperInstance.htmlTextBody =  summaryMailWrapperInstance.htmlTextBody + tempMailWrapperInstance.htmlTextBody +  '<br/>____<br/><br/>';
                summaryMailWrapperInstance.plainTextBody =  summaryMailWrapperInstance.plainTextBody + tempMailWrapperInstance.plaintextBody + '<br/>____<br/><br/>';   
            }    
        }
        return summaryMailWrapperInstance ;    
    }


    // this method sends out the email to the Primary POC and POC contacts associated with the parent account
    public AuditReminderMailWrapper  sendEmail(List<String> toAddressesLst, List<String> ccAddressesLst, Account rootAccountSo,
                                 String subjectStr,String templateNameStr, Set<Account> rootAccountSoSet, Boolean showBRAuditInfo, 
                                 Boolean showEVAuditInfo, String caComments, AuditReminderMailWrapper  mailWrapperInstance, 
                                 boolean blnSendSummaryEmail, boolean blnSendEmailToCAAndSummary) {

        // create a new instance of singleEmailMessage
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        
        // grab the email template
        EmailTemplate emailTemplate = [select Id, Subject, HtmlValue, Body from EmailTemplate where developername = :templateNameStr];
        
        // get the HTML body from the template
        String htmlBody = emailTemplate.HtmlValue;
        
        string strCaseRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('CA Audit Update Request').getRecordTypeId();
        
        //fill set for existing cases and root cases - Fills set of existing Root cases if there is any open cases - later we will add asterisk to those root certificates
        set<string> setSubmittedRootCases = new set<string>();
        List<Root_Case__c> lstRootCases = new List<Root_Case__c>([select Id,Root_Certificate_Name_Existing__r.Name from Root_Case__c Where 
                            Root_Certificate_Name_Existing__c in: rootAccountSoSet
                            and Case_No__r.AccountId =: rootAccountSo.Id and Case_No__r.RecordTypeId =: strCaseRecordTypeId and Case_No__r.Status =: 'Open']);
        for(Root_Case__c objRC: lstRootCases) {
            setSubmittedRootCases.add(objRC.Root_Certificate_Name_Existing__r.Name);
        }
        // set the TO addresses for the email
        mail.setToAddresses(toAddressesLst);
        
        String bodyStr;
        
        // Set the 'From' display name and email address by using Organization Wide Emails for 'Mozilla' 
        // Special Note: DMARC policy caused emails sent by Microsoft user to fail, thus changed to CCAADB Support email alias - change done by Poonam 
        map<string, OrgWideEmailAddress> mapOWDs = new map<string, OrgWideEmailAddress>();
         
        for(OrgWideEmailAddress orgWide : [select id, Address, DisplayName from OrgWideEmailAddress where 
                DisplayName in ('Mozilla CA Program Manager', 'Reply-To Mozilla CA Program Manager')]) {
            mapOWDs.put(orgWide.DisplayName, orgWide);
        }
        if(mapOWDs.containskey('Mozilla CA Program Manager')){
            mail.setOrgWideEmailAddressId(mapOWDs.get('Mozilla CA Program Manager').id); 
            bodyStr = 'From Address: ' + mapOWDs.get('Mozilla CA Program Manager').Address + '\n\n';
        }
        
        bodyStr += 'To Addresses: ' + toAddressesLst + '\n\n';
        
        // set the CC addresses for the email
        if(ccAddressesLst!=null && ccAddressesLst.size() >0 ){
            mail.setCCAddresses(ccAddressesLst);
            bodyStr = bodyStr + 'CC Addresses: ' + ccAddressesLst + '\n\n';
        }
        
        // FOR LATER NEED TO MOVE THIS QUERY OUTSIDE FOR LOOP
        // set the BCC and ReplyTo address for the email  
        List<User> userLst = [select id, email,name,firstname,lastname,companyname,title,phone from user 
                    where CA_Program_Manager__c = true order by name];    
        if(userLst!=null && userLst.size() >0 ){
            List<String> bccAddressesLst = new List<String>();
            bccAddressesLst.add(userLst[0].email);
            mail.setBccAddresses(bccAddressesLst); // set BCC
            bodyStr = bodyStr + 'BCC Addresses: ' + bccAddressesLst + '\n\n';
            //mail.setReplyTo(userLst[0].email);     // added by Poonam   - commented on 3rd Oct 2020 by Sunil   
        }   
        
        //changed on 3rd Oct 2020 - query on OWD for reply to
        if(mapOWDs.containskey('Reply-To Mozilla CA Program Manager')){
            mail.setReplyTo(mapOWDs.get('Reply-To Mozilla CA Program Manager').address);
            bodyStr = bodyStr + 'Reply To: ' + mapOWDs.get('Reply-To Mozilla CA Program Manager').address + '\n\n';
        }
        
        // set other mandatory parameters like subject, replyTo etc
        mail.setSubject(subjectStr);
        
        String rootAccountHTMLStr = '<ul>';
        String rootAccountSummaryEmailStr = 'CA Owner: '+ rootAccountSo.Name + '<br/>';
        rootAccountSummaryEmailStr += 'Root Certificates:<br/>';
        String rootAccountPlainStr = '' ;
        Map<String,Account> standardAuditMap = new Map<String,Account>();
        Map<String,Account> brAuditMap = new Map<String,Account>();
        Map<String,Account> evAuditMap = new Map<String,Account>();
        
        List<Account> lstAccountToUpdate = new List<Account>();
        boolean isFoundOpenCases = false;
        for(Account accountSo: rootAccountSoSet){
            if(!isFoundOpenCases && setSubmittedRootCases.contains(accountSo.name)) isFoundOpenCases = true;
            rootAccountHTMLStr  =  rootAccountHTMLStr + '<li>' +  accountSo.name + (setSubmittedRootCases.contains(accountSo.name) ? '**' : '') + '</li>' ;
            rootAccountSummaryEmailStr = rootAccountSummaryEmailStr + '&nbsp;&nbsp;&nbsp;' + accountSo.name + (setSubmittedRootCases.contains(accountSo.name) ? '**' : '') + '<br/>';
            rootAccountPlainStr = (rootAccountPlainStr!=null & rootAccountPlainStr.length()>0)?  
                   rootAccountPlainStr + ('- ' + accountSo.name + (setSubmittedRootCases.contains(accountSo.name) ? '**' : '') + '\n'):
                                         ('- ' + accountSo.name + (setSubmittedRootCases.contains(accountSo.name) ? '**' : '') + '\n');
                                         
            // for audit+date key pull the record from root account set
            standardAuditMap.put(accountSo.Standard_Audit_Period_End_Date__c+accountSo.standard_audit__c,accountSo);
            brAuditMap.put(accountSo.BR_Audit_Period_End_Date__c+accountSo.br_audit__c,accountSo);
            if (accountSo.ev_policy_oid_s__c!='Not EV') {
                evAuditMap.put(accountSo.EV_Audit_Period_End_Date__c+accountSo.ev_audit__c,accountSo);
            }
            Account objAccToUpdate = new Account(Id = accountSo.id, Mozilla_Audit_Alert__c = subjectStr);
            lstAccountToUpdate.add(objAccToUpdate);
        }
        
        if(rootAccountHTMLStr.length() > 3){
            rootAccountHTMLStr += '</ul>';
        }
        
        if(isFoundOpenCases) {
            rootAccountHTMLStr  += '<br/>** Audit Case in the Common CA Database is under review for this root certificate.<br/><br/>';
            rootAccountSummaryEmailStr += '<br/>** Audit Case in the Common CA Database is under review for this root certificate.<br/><br/>';
            rootAccountPlainStr += '\n\n** Audit Case in the Common CA Database is under review for this root certificate.\n';
        }
        
        String standardAuditInfoStr = '';
        String brAuditInfoStr = '';
        String evAuditInfoStr = '';
        
        if(standardAuditMap.size()>0){    
            for(String mapKeyStr : standardAuditMap.keySet()){
                Account rootAccount = standardAuditMap.get(mapKeyStr);
                String auditStr = rootAccount.standard_audit__c == null ? ' ' : rootAccount.standard_audit__c ;
                String auditDate =  rootAccount.Standard_Audit_Period_End_Date__c == null ? ' ' : String.valueOf(rootAccount.Standard_Audit_Period_End_Date__c) ; 
                standardAuditInfoStr = standardAuditInfoStr + 'Standard Audit: ' + auditStr + '<br/>Standard Audit Period End Date: ' + auditDate + '<br/>';
            }
        }
        
        if(showBRAuditInfo && brAuditMap.size()>0 ){
            for(String mapKeyStr :brAuditMap.keySet()){
                Account rootAccount = brAuditMap.get(mapKeyStr);
                
                String auditStr = rootAccount.br_audit__c == null ? ' ' : rootAccount.br_audit__c;
                String auditDate =  rootAccount.BR_Audit_Period_End_Date__c == null ? ' ' : String.valueOf(rootAccount.BR_Audit_Period_End_Date__c); 
                brAuditInfoStr = brAuditInfoStr + 'BR Audit: ' + auditStr + '<br/>BR Audit Period End Date: ' + auditDate + '<br/>';
            }
        }
        
        if(showEVAuditInfo && evAuditMap.size()>0){
            for(String mapKeyStr :evAuditMap.keySet()){
                Account rootAccount = evAuditMap.get(mapKeyStr);
                
                String auditStr = rootAccount.ev_audit__c == null ? ' ' : rootAccount.ev_audit__c;
                String auditDate =  rootAccount.EV_Audit_Period_End_Date__c == null ? ' ' : String.valueOf(rootAccount.EV_Audit_Period_End_Date__c); 
                evAuditInfoStr = evAuditInfoStr + 'EV Audit: ' + auditStr + '<br/>EV Audit Period End Date: ' + auditDate + '<br/>';
            }     
        }
        
        // if the HTML body is not null, provide values for all the merge fields in the template
        if(htmlBody!=null && htmlBody.length() > 0){
        
            if(userLst!=null && userLst.size()>0) {
                htmlBody = htmlBody.replace('{!User.FirstName}', userLst[0].FirstName == null ? ' ' : userLst[0].FirstName);
                htmlBody = htmlBody.replace('{!User.LastName}', userLst[0].LastName == null ? ' ' : userLst[0].LastName);
                htmlBody = htmlBody.replace('{!User.CompanyName}', userLst[0].CompanyName  == null ? ' ' : userLst[0].CompanyName);
                htmlBody = htmlBody.replace('{!User.Title}', userLst[0].Title   == null ? ' ' : userLst[0].Title);
                htmlBody = htmlBody.replace('{!User.Phone}', userLst[0].phone  == null ? ' ' : userLst[0].phone); 
            }
            
            htmlBody = htmlBody.replace('{!RootCertificateList}', rootAccountHTMLStr );
            htmlBody = htmlBody.replace('{!standardAuditInfoStr}', standardAuditInfoStr);
            htmlBody = htmlBody.replace('{!brAuditInfoStr}', brAuditInfoStr);
            htmlBody = htmlBody.replace('{!evAuditInfoStr}', evAuditInfoStr);
            //TODO set userInfo details.       
            mail.setHtmlBody(htmlBody);
            mailWrapperInstance.htmlTextbody = subjectStr + '<br/>' +  rootAccountSummaryEmailStr +  standardAuditInfoStr +  brAuditInfoStr + evAuditInfoStr + caComments + '<br/>';
            // system.debug('htmlBody-->'+htmlBody);
            // system.debug('wrapper.htmlBody-->'+mailWrapperInstance.htmlTextBody);
        }
        
        // get the plain text body from the template
        String plainBody = emailTemplate.Body;
        
        // if the plain text body is not null, provide values for all the merge fields in the template
        if(plainBody!=null && plainBody.length() > 0)
        {
            plainBody = plainBody.replace('{!RootCertificateList}', rootAccountPlainStr);
            plainBody = plainBody.replace('{!standardAuditInfoStr}', standardAuditInfoStr);
            plainBody = plainBody.replace('{!brAuditInfoStr}', brAuditInfoStr);
            plainBody = plainBody.replace('{!evAuditInfoStr}', evAuditInfoStr);
            if(userLst!=null && userLst.size()>0){
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
            
            mailWrapperInstance.plaintextBody=   subjectStr + '<br/>' + rootAccountHTMLStr + '<br/>' + standardAuditInfoStr + '<br/>' + brAuditInfoStr + '<br/>' + evAuditInfoStr + '<br/>' + caComments + '<br/>';
            // system.debug('plainBody-->'+plainBody);
            // system.debug('wrapper.plainBody-->'+mailWrapperInstance.plaintextBody);
        }
        
        //if send email flag is true then it should send email and create task.         
        if(blnSendEmailToCAAndSummary){
            if(!Test.IsRunningTest()) {
                // send out the email
                Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
            }
            
            // create a task record for the sent email so that it shows up 
            // on the related list for the corresponding root account
            
            createTask(mail.getSubject(),bodyStr + mail.getPlainTextBody(),userLst != null && userLst.size() > 0 ? userLst[0].Id : UserInfo.getUserId(),rootAccountSo.id);
        }
        //update Mozilla Audit Alert on root certificate.
        if(lstAccountToUpdate.size() > 0){
            update lstAccountToUpdate;
        }
        return mailWrapperInstance;                           
    }
    
    // this method creates the task that would be associated with the corresponding root account
    // this lets the users know that an email was sent out for the root account
    public void createTask(String subject, String mailBody, String userId, String accountId){
    
        Task taskSo = new Task();
        taskSo.subject = subject;
        taskSo.Description = mailBody; 
        taskSo.status = 'Completed';
        taskSo.OwnerId = userId; //user id        
        taskSo.WhatId = accountId; //record id
        
        insert taskSo; 
    
    }
}
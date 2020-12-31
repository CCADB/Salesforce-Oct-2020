// This is the helper class for the AuditReminderBatchForMSFT job 
// 
// Audit Reminder Logic:
// For each CA Owner, create one audit reminder email for all of the root certs that they own 
// and have outdated audit statements. Attach the activity record to the CA Owner Object. 
// Root Certs which have 'Do NOT send Audit Reminder' set to true are ignored.
//
// Set one user as 'Microsoft CA Program Manager' in User object. Set one email id for 
// 'Microsoft CA Program Manager' in org wide address. Org Wide Email Address is being used to set 'From' 
// and 'Display Name' for the outgoing emails. The sender will be copied as BCC (uncomment code)
// 'Compliance BCC Email' may or may not be enabled. 
// 
// Two email templates are being used 'Microsoft Less Than 90 Days Audit Reminder' & 'Microsoft More Than 90 Days Audit Reminder'
//
// From: Org Wide Email (support@ccadb.org) ** to avoid email failures dure to DMARC policy
// To: CA Email Alias1 & CA Email Alias2
// CC: Email Contacts of type 'Primary POC' and 'POCs' of the CA Owner record
// BCC: Microsoft CA Program Manager org wide address
// Reply To: Microsoft CA Program Manager org wide address
// Subject: Microsoft Audit Reminder 
// 
// Email template body contains following merge fields 
// - <Root Cert Name 1> <Microsoft Audit Alert Email Text>
// - <Root Cert Name 2> <Microsoft Audit Alert Email Text>
// - <Root Cert Name 3> <Microsoft Audit Alert Email Text>
//    ...... etc
//
// *** IMPORTANT *** FOR TESTING: Check for CCADB Support (from address) & Microsoft CA Manager (bcc address)
// Orgwide settings, Microsoft CA Program Manager in User record, Contact Email field, CA Owner Email Alias1 & 2 for email address
//
// Updates on 28th May 2018
//    - Change reply To and used Org wide address instead of Microsoft Program manager user.
//    - Added From Address, Bcc Address and Reply To address in Activity Body.

// Updated on 30th Dec 2018
//    - Changed code to send alters to root certifticate has audit period end date less than 90 days or over 90 days due and send reminder
//    - If root certificate has only code signing audit alert then we are skipping that root certificate 
//      (that means not sending emails when there is only Code Signing alert)
//      but if it has any audit period end date has over or less 90 days then we are including root certifcate.
//    - it using two email template for 90 day less and over 90 days due.
//
// Updated on 15th Feb 2019
//    - Added summary email to go to org wide email address for 'Microsoft CA Program Manager' 
//    - Standalone summary can also be genrated by user from 'RunAuditReminderSummaryOnlyMSFT' vf page or cusom tab
// Updated on 30 Jan 2020
//    - commented line 121-158 as we don't need to send reminder for less than 90 days, requested by Microsoft
/*

For all Root Certs which Included, Change Requested in Microsoft Program find audits older than a year but less than 90 days grace period
{
     check if Standard_Audit_Period_End_Date > 365 and < 455 OR blank
          set alert for Standard Audit > 365 to true
     else 
     {
             if Microsoft_Trust_Bits has Server Authentication and BR_Audit_Period_End_Date > 365 and < 455 OR blank
                  set alert for BR Audit > 365 to true

              if Microsoft_Trust_Bits has Server Authentication and Microsoft_EV_Enabled = True and EV SSL_Audit_Period_End_Date > 365 and < 455 OR blank
                  set alert for EV SSL Audit > 365 to true

               // if Microsoft_Trust_Bits has Code Signing and Microsoft_EV_Enabled = True and EV Code Signing_Audit_Period_End_Date > 365 and < 455 OR blank
               //    set alert for EV Code Signing Audit > 365 to true

                // If one of the above audit alerts is true then only check for Code Signing Audit 
                // {
                         if Microsoft_Trust_Bits has Code Signing and Code Signing_Audit_Period_End_Date > 365 and < 455 OR blank
                                  set alert for  Code Signing Audit > 365 to true

                // }
      }
      
      ... same logic repeats for over 455 days old audits ...
}


*/

public class AuditReminderBatchHelperForMSFT {

    // This method iterates over a list of root accounts and processes them for audit reminder email notification
    public static string processRootAccount(List<Account> parentAccountSoLLst, boolean blnSendEmail) {
    
        Set<Account> rootAccountSOSet;
        String templateNameStr = '';
        String subjectStr = '';
        String summaryBodyStr = '';
        // iterate over each root account
        for(Account accountSO : parentAccountSoLLst) {
            rootAccountSOSet = new Set<Account>();
            boolean isAnyAuditOver455 = false;
            boolean isAnyAuditOver365 = false;
            map<Id, string> mapAuditRemForEachRoot = new map<Id,string>();
            
            for (Account rootAccountSo: [select id,  name, parentid, parent.name, Standard_Audit__c, br_Audit__c,ev_Audit__c, 
                                            Microsoft_Trust_Bits__c, Microsoft_EV_Enabled__c, Standard_Audit_Period_End_Date__c,SHA_1_Fingerprint__c,
                                            Code_Signing_Audit_Period_End_Date__c,BR_Audit_Period_End_Date__c,EV_Audit_Period_End_Date__c, 
                                            EV_Code_Signing_Audit_Period_End_Date__c, Microsoft_Audit_Alert_Email_Text__c  
                                            from account where parentid = :accountSO.id and Type = 'Root' 
                                            and Microsoft_Status__c in ('Included','Change Requested')
                                            //and Microsoft_Audit_Alert__c like 'Audit Alert%'
                                            and name != '<Fill in Cert Name>'
                                            and Microsoft_Do_NOT_Send_Audit_Reminder__c = False]){
                string strAuditReminderText = '';
                // system.debug('accountSo Id = ' + accountSo.Id);
                // system.debug('rootAccount ID = ' + rootAccountSo.Id);
                // system.debug('showEVAuditInfo = ' + showEVAuditInfo);
                // system.debug('rootAccountSo.trust_Bits__c = ' + rootAccountSo.trust_Bits__c);
                // system.debug('rootAccountSo.ev_policy_oid_s__c = ' + rootAccountSo.ev_policy_oid_s__c);                                 
                // system.debug('trustBits='+rootAccountSo.trust_Bits__c.contains('Off'));
                // system.debug('days='+system.today().daysBetween(rootAccountSo.standard_audit_statement_date__c));
                
                //checking for any root has less than 90 days due.
                string MicrosoftTrustBits = rootAccountSo.Microsoft_Trust_Bits__c != null ? rootAccountSo.Microsoft_Trust_Bits__c : '';
                boolean isAuditOver365 = false;
                boolean isStandardAuditOver365 = false;
                boolean isBRAuditOver365 = false;
                boolean isEVSSLAuditOver365 = false;
                boolean isEVCodeSigningAuditOver365 = false;
                boolean isCodeSigningAuditOver365 = false;
                
                //condition checking for overdue less than 90 days.
                //commented line 121-158 on 30th Jan 2020 as we don't need to send reminder for less than 90 days,requested by Microsoft
                /*if(rootAccountSo.Standard_Audit_Period_End_Date__c == null ||
                    (Math.abs(system.today().daysBetween(rootAccountSo.Standard_Audit_Period_End_Date__c)) > 365 &&
                    Math.abs(system.today().daysBetween(rootAccountSo.Standard_Audit_Period_End_Date__c)) < 455)) {
                    isStandardAuditOver365 = true;  
                    isAuditOver365 = true;  
                } else {
                    if(MicrosoftTrustBits.contains('Server Authentication') && (rootAccountSo.BR_Audit_Period_End_Date__c == null ||
                        (Math.abs(system.today().daysBetween(rootAccountSo.BR_Audit_Period_End_Date__c)) > 365 &&
                        Math.abs(system.today().daysBetween(rootAccountSo.BR_Audit_Period_End_Date__c)) < 455))){
                        isBRAuditOver365 = true;
                        isAuditOver365 = true;
                    }
                    
                    if(MicrosoftTrustBits.contains('Server Authentication') && rootAccountSo.Microsoft_EV_Enabled__c && (rootAccountSo.EV_Audit_Period_End_Date__c == null ||
                        (Math.abs(system.today().daysBetween(rootAccountSo.EV_Audit_Period_End_Date__c)) > 365 &&
                        Math.abs(system.today().daysBetween(rootAccountSo.EV_Audit_Period_End_Date__c)) < 455))){
                        isEVSSLAuditOver365 = true;
                        isAuditOver365 = true;
                    }
                    
                    // 1/22/2019 Karina made a request to not check for EV Code Signing Audits 
                    // if(MicrosoftTrustBits.contains('Code Signing') && rootAccountSo.Microsoft_EV_Enabled__c && (rootAccountSo.EV_Code_Signing_Audit_Period_End_Date__c == null ||
                    //    (Math.abs(system.today().daysBetween(rootAccountSo.EV_Code_Signing_Audit_Period_End_Date__c)) > 365 && 
                    //    Math.abs(system.today().daysBetween(rootAccountSo.EV_Code_Signing_Audit_Period_End_Date__c)) < 455))){
                    //    isEVCodeSigningAuditOver365 = true;
                    //    isAuditOver365 = true;
                    // }
                    
                    // Code Signing Audit should be checked only if there is an alert for another audit. 
                    // On 1/22/2018 Karina asked to remove the conditional check hence the IF statement is commented 
                    // if(isAuditOver365){ 
                    if(MicrosoftTrustBits.contains('Code Signing') && (rootAccountSo.Code_Signing_Audit_Period_End_Date__c == null ||
                        (Math.abs(system.today().daysBetween(rootAccountSo.Code_Signing_Audit_Period_End_Date__c)) > 365 &&
                        Math.abs(system.today().daysBetween(rootAccountSo.Code_Signing_Audit_Period_End_Date__c)) < 455))){
                        isCodeSigningAuditOver365 = true;
                    }
                    //}
                }*/
                
                //checking for any root has over 90 days due.
                boolean isAuditOver455 = false;
                boolean isStandardAuditOver455 = false;
                boolean isBRAuditOver455 = false;
                boolean isEVSSLAuditOver455 = false;
                boolean isEVCodeSigningAuditOver455 = false;
                boolean isCodeSigningAuditOver455 = false;
                if(rootAccountSo.Standard_Audit_Period_End_Date__c == null ||
                    Math.abs(system.today().daysBetween(rootAccountSo.Standard_Audit_Period_End_Date__c)) > 455) {
                    isStandardAuditOver455 = true;
                    isAuditOver455 = true;
                } else {
                    if(MicrosoftTrustBits.contains('Server Authentication') && (rootAccountSo.BR_Audit_Period_End_Date__c == null ||
                        Math.abs(system.today().daysBetween(rootAccountSo.BR_Audit_Period_End_Date__c)) > 455)){
                        isBRAuditOver455 = true;
                        isAuditOver455 = true;
                    }
                    
                    if(MicrosoftTrustBits.contains('Server Authentication') && rootAccountSo.Microsoft_EV_Enabled__c && (rootAccountSo.EV_Audit_Period_End_Date__c == null ||
                        Math.abs(system.today().daysBetween(rootAccountSo.EV_Audit_Period_End_Date__c)) > 455)){
                        isEVSSLAuditOver455 = true;
                        isAuditOver455 = true;
                    }
                    
                    // 1/22/2019 Karina made a request to not check for EV Code Signing Audits
                    // if(MicrosoftTrustBits.contains('Code Signing') && rootAccountSo.Microsoft_EV_Enabled__c && (rootAccountSo.EV_Code_Signing_Audit_Period_End_Date__c == null ||
                    //     Math.abs(system.today().daysBetween(rootAccountSo.EV_Code_Signing_Audit_Period_End_Date__c)) > 455)){
                    //     isEVCodeSigningAuditOver455 = true;
                    //     isAuditOver455 = true;
                    // }
                    
                    // Code Signing Audit should be checked only if there is an alert for another audit. 
                    // On 1/22/2018 Karina asked to remove the conditional check hence the IF statement is commented 
                    // if(isAuditOver455){ 
                    if(MicrosoftTrustBits.contains('Code Signing') && (rootAccountSo.Code_Signing_Audit_Period_End_Date__c == null ||
                        Math.abs(system.today().daysBetween(rootAccountSo.Code_Signing_Audit_Period_End_Date__c)) > 455)){
                        isCodeSigningAuditOver455 = true;
                    }
                    //}
                }
                
                //generate text conditionally based on days overdue.
                if(isStandardAuditOver455 || isStandardAuditOver365){
                    if(isStandardAuditOver455){
                        strAuditReminderText += 'Audit Alert : Standard Audit Period End Date is Null or Over 90 days past due\n';
                    } else if(isStandardAuditOver365) {
                        strAuditReminderText += 'Audit Alert : Standard Audit Period End Date is Null or Less than 90 days past due\n';
                    }
                } else {
                    //br audit
                    if(isBRAuditOver455){
                        strAuditReminderText += 'Audit Alert : Microsoft Trust Bits has Server Authentication but BR Audit Period End Date is Null or Over 90 days past due\n';
                    } else if(isBRAuditOver365){
                        strAuditReminderText += 'Audit Alert : Microsoft Trust Bits has Server Authentication but BR Audit Period End Date is Null or Less than 90 days past due\n';
                    }
                    //code signing audit
                    if(isCodeSigningAuditOver455){
                        strAuditReminderText += 'Audit Alert : Microsoft Trust Bits has Code Signing but Code Signing Audit Period End Date is Null or Over 90 days past due\n';
                    } else if(isCodeSigningAuditOver365){
                        strAuditReminderText += 'Audit Alert : Microsoft Trust Bits has Code Signing but Code Signing Audit Period End Date is Null or Less than 90 days past due\n';
                    }
                    //ev ssl audit
                    if(isEVSSLAuditOver455){
                        strAuditReminderText += 'Audit Alert : Microsoft Trust Bits has Server Authentication and Microsoft EV Enabled is True but EV SSL Audit Period End Date is Null or Over 90 days past due\n';
                    } else if(isEVSSLAuditOver365){
                        strAuditReminderText += 'Audit Alert : Microsoft Trust Bits has Server Authentication and Microsoft EV Enabled is True but EV SSL Audit Period End Date is Null or Less than 90 days past due\n';
                    }
                    
                    //ev code signing audit
                    if(isEVCodeSigningAuditOver455){
                        strAuditReminderText += 'Audit Alert : Microsoft Trust Bits has Code Signing and Microsoft EV Enabled is True but EV Code Signing Audit Period End Date is Null or Over 90 days past due\n';
                    } else if(isEVCodeSigningAuditOver365){
                        strAuditReminderText += 'Audit Alert : Microsoft Trust Bits has Code Signing and Microsoft EV Enabled is True but EV Code Signing Audit Period End Date is Null or Less than 90 days past due\n';
                    }
                }
                //check parent level
                if(!isAnyAuditOver455 && isAuditOver455){
                    isAnyAuditOver455 = true;
                }
                if(!isAnyAuditOver365 && isAuditOver365){
                    isAnyAuditOver365 = true;
                }
                if((isAuditOver455 || isAuditOver365) && string.isnotblank(strAuditReminderText)){
                    rootAccountSOSet.add(rootAccountSo);
                    strAuditReminderText += '\n';
                    
                    strAuditReminderText += 'CA Owner Name: ' + rootAccountSo.Parent.Name + '\n';
                    strAuditReminderText += 'Root Certificate Name: ' + rootAccountSo.Name + '\n';
                    
                    strAuditReminderText += 'Standard Audit Period End Date (mm/dd/yyyy): ' + (rootAccountSo.Standard_Audit_Period_End_Date__c != null ? (rootAccountSo.Standard_Audit_Period_End_Date__c.month() + '/' + rootAccountSo.Standard_Audit_Period_End_Date__c.day() + '/' + rootAccountSo.Standard_Audit_Period_End_Date__c.year()) : 'null') + '\n';
                    strAuditReminderText += 'Code Signing Audit Period End Date (mm/dd/yyyy):  ' + (rootAccountSo.Code_Signing_Audit_Period_End_Date__c != null ? (rootAccountSo.Code_Signing_Audit_Period_End_Date__c.month() + '/' + rootAccountSo.Code_Signing_Audit_Period_End_Date__c.day() + '/' + rootAccountSo.Code_Signing_Audit_Period_End_Date__c.year()) : 'null') + '\n';
                    strAuditReminderText += 'BR Audit Period End Date (mm/dd/yyyy): ' + (rootAccountSo.BR_Audit_Period_End_Date__c != null ? (rootAccountSo.BR_Audit_Period_End_Date__c.month() + '/' + rootAccountSo.BR_Audit_Period_End_Date__c.day() + '/' + rootAccountSo.BR_Audit_Period_End_Date__c.year()) : 'null') + '\n';
                    strAuditReminderText += 'EV SSL Audit Period End Date (mm/dd/yyyy): ' + (rootAccountSo.EV_Audit_Period_End_Date__c != null ? (rootAccountSo.EV_Audit_Period_End_Date__c.month() + '/' + rootAccountSo.EV_Audit_Period_End_Date__c.day() + '/' + rootAccountSo.EV_Audit_Period_End_Date__c.year()) : 'null') + '\n';
                    strAuditReminderText += 'EV Code Signing Audit Period End Date (mm/dd/yyyy): ' + (rootAccountSo.EV_Code_Signing_Audit_Period_End_Date__c != null ? (rootAccountSo.EV_Code_Signing_Audit_Period_End_Date__c.month() + '/' + rootAccountSo.EV_Code_Signing_Audit_Period_End_Date__c.day() + '/' + rootAccountSo.EV_Code_Signing_Audit_Period_End_Date__c.year()) : 'null') + '\n';
                    strAuditReminderText += 'SHA-1 Fingerprint: ' + rootAccountSo.SHA_1_Fingerprint__c +'\n\n';
                    mapAuditRemForEachRoot.put(rootAccountSo.Id, strAuditReminderText);
                }
                //system.debug('rootAccountSOSet ::: '+rootAccountSOSet + ' :::: isAnyAuditOver455  ::: '+isAnyAuditOver455 );
            }
            //selecting email template - if any root has 90 days overdue then selecting that template.
            if(isAnyAuditOver455){
                templateNameStr = 'Microsoft_More_Than_90_Days_Audit_Reminder';
                subjectStr = 'Microsoft: Overdue Audit Reminder';
            } else if(isAnyAuditOver365){
                templateNameStr = 'Microsoft_Less_Than_90_Days_Audit_Reminder';
                subjectStr = 'Microsoft: Audit Reminder';
            }
            
            // create the lists which will hold the TO and CC email addresses
            List<String> toAddressesLst = new List<String>();
            List<String> ccAddressesLst = new List<String>();  
            
            // check if the email alias info is available on the parent account   
            if((accountSO.CA_Email_Alias_1__c!=null && accountSO.CA_Email_Alias_1__c.length()>0) 
                || (accountSO.CA_Email_Alias_2__c!=null && accountSO.CA_Email_Alias_2__c.length()>0))
            {            
                // system.debug('Sending email for Account ' + accountSo.Id);
                
                // if email alias info is available on the parent account then we need to send the 
                // the audit reminder email notification to these email addresses
                try {
                
                    // add email alias 1 to the list if it is not null
                    if(accountSO.CA_Email_Alias_1__c!=null && accountSO.CA_Email_Alias_1__c.length() > 0)
                    {
                        toAddressesLst.add(accountSo.CA_Email_Alias_1__c); 
                    }
                    
                    // add email alias 2 to the list if it is not null             
                    if(accountSO.CA_Email_Alias_2__c!=null && accountSO.CA_Email_Alias_2__c.length() > 0)
                    {
                        toAddressesLst.add(accountSo.CA_Email_Alias_2__c); 
                    }                      
                
                } catch(Exception ex) {
                // System.debug('Exception type caught: ' + ex.getTypeName());    
                // System.debug('Message: ' + ex.getMessage());    
                // System.debug('Cause: ' + ex.getCause());    // returns null
                // System.debug('Line number: ' + ex.getLineNumber());    
                // System.debug('Stack trace: ' + ex.getStackTraceString());    
                }
            }            
        
            // fetch the Primary POC and POC contacts from the parent account
            List<Contact> contactLst = [select id, email, Type__c from contact where account.id=:accountSO.id and (Type__c = 'Primary POC' or Type__c = 'POC')];
            // if such contacts exists
            if(contactLst!=null && contactLst.size()>0){               
                // iterate over each contact record and add Primary POC & POC email address is added to CC list                 
                for(Contact contactSO: contactLst) {      
                    //check for email is not null
                    if(contactSO.email != null) {
                        ccAddressesLst.add(contactSO.email);    
                    }
                }                                        
            }        
        
            if((toAddressesLst.size()>0 || ccAddressesLst.size()>0) && rootAccountSoSet.size() > 0 ) {
                // system.debug('Sending email to =' );
                // system.debug('rootAccountSet = ' + rootAccountSoSet);
                summaryBodyStr = sendEmail(toAddressesLst, ccAddressesLst, accountSo, subjectStr, templateNameStr, 
                                rootAccountSoSet, mapAuditRemForEachRoot, blnSendEmail);
                                
                summaryBodyStr += '____\n\n';
            }
        }
        return summaryBodyStr;
    }
    
    
    // this method sends out the email to the Primary POC and POC contacts associated with the parent account
    public static string sendEmail(List<String> toAddressesLst, List<String> ccAddressesLst, Account rootAccountSo,String subjectStr, 
        String templateNameStr, Set<Account> rootAccountSoSet, map<Id, string> mapAuditReminderForEachRoot, boolean blnSendEmail) {
        
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
                                    Root_Certificate_Name_Existing__c in: rootAccountSoSet and Case_No__r.AccountId =: rootAccountSo.Id 
                                    and Case_No__r.RecordTypeId =: strCaseRecordTypeId and Case_No__r.Status =: 'Open']);
        for(Root_Case__c objRC: lstRootCases) {
            setSubmittedRootCases.add(objRC.Root_Certificate_Name_Existing__r.Name);
        }
        
        //List<OrgWideEmailAddress> lstFromOrgWide = [select id, Address, DisplayName from OrgWideEmailAddress where DisplayName = 'CCADB Support'];
        map<string, OrgWideEmailAddress> mapOWDs = new map<string, OrgWideEmailAddress>();
         
        for(OrgWideEmailAddress orgWide : [select id, Address, DisplayName from OrgWideEmailAddress where 
                DisplayName in ('Reply-To Microsoft CA Program Manager', 'Microsoft CA Program Manager')]) {
            mapOWDs.put(orgWide.DisplayName, orgWide);
        }
        
        String bodyStr;
        
        // Set the 'From' display name and email address by using Organization Wide Emails for 'Microsoft'  
        // Special Note: DMARC policy caused emails sent by Microsoft user to fail, thus changed to CCAADB Support email alias - change done by Poonam
        //set the From address on body
        if(mapOWDs.size()  > 0 && mapOWDs.containskey('Microsoft CA Program Manager')) {
            bodyStr = 'From Address: ' + mapOWDs.get('Microsoft CA Program Manager').Address + '\n\n';
            mail.setOrgWideEmailAddressId(mapOWDs.get('Microsoft CA Program Manager').id); 
        }
        
        // set the TO addresses on email 
        if(toAddressesLst!=null && toAddressesLst.size()>0) {
            mail.setToAddresses(toAddressesLst);
        }   
        bodyStr = bodyStr + 'To Addresses: ' + toAddressesLst + '\n\n';
        
        // set the CC addresses on email
        if(ccAddressesLst!=null && ccAddressesLst.size()>0){
            mail.setCCAddresses(ccAddressesLst);
            bodyStr = bodyStr + 'CC Addresses: ' + ccAddressesLst + '\n\n';
        } 
        
        // set the BCC and ReplyTo address in email
        //commented on 28th May 18 - Use Org wide default email address instead of Microsoft CA Program Manager
        List<User> userLst = [select email,name,firstname,lastname,companyname,title,phone from user 
            where Microsoft_CA_Program_Manager__c = True order by name];
        
        /*if(userLst!=null && userLst.size()>0)
        {        
        List<String> bccAddressesLst = new List<String>();
        bccAddressesLst.add(userLst[0].email);
        mail.setBccAddresses(bccAddressesLst);          
        mail.setReplyTo(userLst[0].email);      // added by Poonam        
        // mail.setSenderDisplayName(userLst[0].name);
        } */ 
        //for(OrgWideEmailAddress orgWide : [select id, Address, DisplayName from OrgWideEmailAddress where DisplayName = 'Microsoft CA Program Manager']) {
        if(mapOWDs.containskey('Microsoft CA Program Manager')){
            OrgWideEmailAddress orgWide = mapOWDs.get('Microsoft CA Program Manager');
            List<String> bccAddressesLst = new List<String>();
            bccAddressesLst.add(orgWide.Address);
            mail.setBccAddresses(bccAddressesLst); 
            bodyStr = bodyStr + 'BCC Addresses: ' + bccAddressesLst + '\n\n';         
            mail.setReplyTo(orgWide.Address);//
        }
        //bodyStr = bodyStr + 'Reply To: ' + orgWide.Address + '\n\n';
        
        //changed on 3rd Oct 2020 - query on OWD for reply to
        if(mapOWDs.containskey('Reply-To Microsoft CA Program Manager')){
            mail.setReplyTo(mapOWDs.get('Reply-To Microsoft CA Program Manager').address);
            bodyStr = bodyStr + 'Reply To: ' + mapOWDs.get('Reply-To Microsoft CA Program Manager').address + '\n\n';
        }
        
        // set other mandatory parameters like subject, replyTo etc
        mail.setSubject(emailTemplate.subject);
        
        String rootAccountHTMLStr = '<ul>';
        String rootAccountPlainStr = '' ;
        
        boolean isFoundOpenCases = false;
        for(Account accountSo: rootAccountSoSet)
        {            
            string strAuditReminderText = mapAuditReminderForEachRoot.containskey(accountSo.Id) ? mapAuditReminderForEachRoot.get(accountSo.Id) : '';
            if(!isFoundOpenCases && setSubmittedRootCases.contains(accountSo.name)) isFoundOpenCases = true; 
            // rootAccountHTMLStr  =  rootAccountHTMLStr + '<li>' +  accountSo.name + '</li><br/>' ;     
            // rootAccountPlainStr = (rootAccountPlainStr!=null & rootAccountPlainStr.length()>0)?  rootAccountPlainStr + '- ' + accountSo.name + '\n' : '- ' + accountSo.name + '\n';
            
            rootAccountHTMLStr  =  rootAccountHTMLStr + '<li>' +  strAuditReminderText.replace('\n','<br/>') + (setSubmittedRootCases.contains(accountSo.name) ? '<br/><b>** Audit Case in the Common CA Database is under review for this root certificate.</b>' : '') + '</li><br/>' ;
            rootAccountPlainStr = (rootAccountPlainStr != null & rootAccountPlainStr.length()>0 ) 
                        ? rootAccountPlainStr + ('\n' + strAuditReminderText + (setSubmittedRootCases.contains(accountSo.name) ? '\n** Audit Case in the Common CA Database is under review for this root certificate.' : '') + '\n') 
                        : '\n' + strAuditReminderText + (setSubmittedRootCases.contains(accountSo.name) ? '\n** Audit Case in the Common CA Database is under review for this root certificate.' : '') + '\n';
        }
        //system.debug('rootAccountPlainStr ::: '+rootAccountPlainStr);
        if(rootAccountHTMLStr.length()> 3){
            rootAccountHTMLStr += '</ul>';
        }
        
        //if(isFoundOpenCases) {
        //    rootAccountHTMLStr  += '<br/>** Audit Case in the Common CA Database is under review for this root certificate.<br/><br/>';
        //    rootAccountPlainStr += '\n\n** Audit Case in the Common CA Database is under review for this root certificate.\n';
        //} 
        
        // if the HTML body is not null, provide values for all the merge fields in the template
        if(htmlBody!=null && htmlBody.length() > 0)
        {
        
            /*if(userLst!=null && userLst.size()>0)
            {
            htmlBody = htmlBody.replace('{!User.FirstName}', userLst[0].FirstName == null ? ' ' : userLst[0].FirstName);
            htmlBody = htmlBody.replace('{!User.LastName}', userLst[0].LastName == null ? ' ' : userLst[0].LastName);
            htmlBody = htmlBody.replace('{!User.Title}', userLst[0].Title   == null ? ' ' : userLst[0].Title);
            htmlBody = htmlBody.replace('{!User.CompanyName}', userLst[0].CompanyName  == null ? ' ' : userLst[0].CompanyName);         
            // htmlBody = htmlBody.replace('{!User.Phone}', userLst[0].phone  == null ? ' ' : userLst[0].phone);           
            }*/
            
            htmlBody = htmlBody.replace('{!RootCertificateList}', rootAccountHTMLStr );
            
            mail.setHtmlBody(htmlBody);
        }
        
        // get the plan text body from the template
        String plainBody = emailTemplate.Body;
        
        // if the plain text body is not null, provide values for all the merge fields in the template
        if(plainBody!=null && plainBody.length() > 0)
        {
            plainBody = plainBody.replace('{!RootCertificateList}', rootAccountPlainStr);
            
            /*if(userLst!=null && userLst.size()>0)
            {
            plainBody = plainBody.replace('{!User.FirstName}', userLst[0].FirstName == null ? ' ' : userLst[0].FirstName);
            plainBody = plainBody.replace('{!User.LastName}', userLst[0].LastName == null ? ' ' : userLst[0].LastName);
            plainBody = plainBody.replace('{!User.Title}', userLst[0].Title   == null ? ' ' : userLst[0].Title);
            plainBody = plainBody.replace('{!User.CompanyName}', userLst[0].CompanyName  == null ? ' ' : userLst[0].CompanyName);         
            // plainBody = plainBody.replace('{!User.Phone}', userLst[0].phone  == null ? ' ' : userLst[0].phone);
            }*/
            plainBody = plainBody.replace('<br/>','\n');
            plainBody = plainBody.replace('<ul>',' ');
            plainBody = plainBody.replace('</ul>',' ');
            plainBody = plainBody.replace('<li>',' ');
            plainBody = plainBody.replace('</li>',' ');     
            
            mail.setPlainTextBody(plainBody);    
        }
        
        if(blnSendEmail) {
            // send out the email
            if(!Test.IsRunningTest()){
                Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
            }
            // create a task record for the sent email so that it shows up 
            // on the related list for the corresponding root account
            
            createTask(mail.getSubject(),bodyStr + mail.getPlainTextBody(),userLst != null && userLst.size() > 0 ? userLst[0].Id : UserInfo.getUserId(),rootAccountSo.id);
        }
        string SummaryStr = 'Email Notice: '+ emailTemplate.Subject + '\n\n' + rootAccountPlainStr;
        return SummaryStr;
    }
    
    
    // this method creates the task that would be associated with the corresponding root account
    // this lets the users know that an email was sent out for the root account
    
    public static void createTask(String subject, String mailBody, String userId, String accountId){
            
        Task taskSo = new Task();
        taskSo.subject = subject;
        if(mailBody != null && mailBody.contains('<br>')){
            mailBody = mailBody.replaceAll('<br>', '\n');
        }
        taskSo.Description = mailBody; 
        taskSo.status = 'Completed';
        taskSo.OwnerId = userId; //user id        
        taskSo.WhatId = accountId; //record id
        
        insert taskSo; 
        
    }
}
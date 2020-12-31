public class MassEmailBatchHelper {

    public Account accountSo {get;set;}
    public   Map<Id,Set<String>>  toEmailAddressMap {get;set;}
    public   Map<Id,Set<String>>  ccEmailAddressMap {get;set;}
    public Integer NoofEmailsSent;
    public Integer NoofEmailsFailed;
 
    public Mass_Email__c processOwnerRecords(List<Account> accountLst, Mass_Email__c massEmailSo, Map<Id,Set<String>> toMap, Map<Id,Set<String>> ccMap) {
        try {
            NoofEmailsSent = massEmailSo.No_of_Emails_Sent__c != null ? Integer.valueof(massEmailSo.No_of_Emails_Sent__c) : 0;
            NoofEmailsFailed = massEmailSo.No_of_Emails_Failed__c != null ? Integer.valueof(massEmailSo.No_of_Emails_Failed__c) : 0;
            toEmailAddressMap = toMap;
            ccEmailAddressMap = ccMap;
            for(Account accountSo : accountLst){
                this.accountSo = accountSo;
                sendEmailForThisOwner(accountSo, massEmailSo);
            }
            //update mass email batch fields
            massEmailSo.No_of_Emails_Sent__c = NoofEmailsSent;
            massEmailSo.No_of_Emails_Failed__c = NoofEmailsFailed;
        } catch (Exception ex){
            //update mass email batch fields
            massEmailSo.Error_Message__c += ex.getMessage();
        }
        return massEmailSo;
    }
    public void sendEmailForThisOwner(Account accountSo, Mass_Email__c massEmailSo){
        // Commented by Poonam List<User> userLst = [select id, email,name,firstname,lastname,companyname,title,phone from user where CA_Program_Manager__c = true order by name];            
        // List<User> userLst = [select id, email,name,firstname,lastname,companyname,title,phone from user order by name];    
             
        // create a new instance of singleEmailMessage
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        String bodyStr = '';
        
        
        mail.setSubject(massEmailSo.Subject__c);
        Boolean isToAddressPopulated, isCCAddressPopulated;
        isToAddressPopulated = false;
        isCCAddressPopulated = false;
        
        // set the TO addresses on the email
        List<String> toEmailAddressLst = populateEmailAddress(accountSo.id, massEmailSo,'TO');
        if(toEmailAddressLst!=null && toEmailAddressLst.size() > 0) {
            mail.setToAddresses(toEmailAddressLst );
            bodyStr = bodyStr +   'To Addresses: ' + toEmailAddressLst + '\n\n';    
            isToAddressPopulated = true;
        }
        
        List<String> ccEmailAddressLst  = populateEmailAddress(accountSo.id, massEmailSo,'CC');
        
        if(ccEmailAddressLst!=null && ccEmailAddressLst.size() > 0){
            mail.setCCAddresses(ccEmailAddressLst); 
            bodyStr = bodyStr +   'CC Addresses: ' + ccEmailAddressLst + '\n\n';    
            isCCAddressPopulated = true;
        }
        
        // Set the 'from' display name and email address by using Organization Wide Emails for 'Mozilla'  
        List<User> userSoLst;
        if(massEmailSo.from__c!='Current User'){
            OrgWideEmailAddress orgWide = [select id, Address, DisplayName from OrgWideEmailAddress where DisplayName = :massEmailSo.from__c];
            mail.setOrgWideEmailAddressId(orgWide.id); 
            userSoLst = [select id, email,name,firstname,lastname,companyname,title,phone from user 
            where email = :orgWide.address and Additional_User_Record__c = false order by name];  
            
            // Additional_User_Record__c is used in the where clause as there could be multiple user records with same email id - added by Poonam 
            // system.debug('SOQL on EMAIL - Users: '+userSoLst);
        } else {
            userSoLst = [select id, email,name,firstname,lastname,companyname,title,phone from user where id = :UserInfo.getUserId() order by name];  
            //system.debug('SOQL on ID - Users: '+userSoLst);                    
        }
        // send out the email 
        if(isTOAddressPopulated || isCCAddressPopulated) {
            /*if(massEmailSo.reply_to__c!=null && massEmailSo.reply_to__c.length() > 0)
            {
            mail.setReplyTo(massEmailSo.reply_to__c);
            }
            */
            
            if(massEmailSo.reply_to__c!='Current User'){
                OrgWideEmailAddress orgWide = [select id, Address, DisplayName from OrgWideEmailAddress 
                                      where DisplayName = :massEmailSo.reply_to__c]; 
                mail.setReplyTo(orgWide.address);   
                // system.debug('not current user set reply to: '+orgWide.address); 
            } else {   
                mail.setReplyTo(UserInfo.getUserEmail());
                // system.debug('current user set reply to: '+UserInfo.getUserEmail());                                 
            }
            bodyStr = bodyStr + massEmailSo.message__c;
            mail.setPlainTextBody(massEmailSo.message__c);
            List<Messaging.SendEmailResult> Emailresults = Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
            if(Emailresults.get(0).isSuccess()){
                NoofEmailsSent++;
            } else {
                NoofEmailsFailed++;
            }
            if(userSoLst != null && userSoLst.size() > 0){
                createTask(mail.getSubject(), bodyStr,userSoLst[0].id,accountSo.id);
            } else {
                createTask(mail.getSubject(), bodyStr,UserInfo.getUserId(),accountSo.id);
            }
        } 
    }
 
    public List<String> populateEmailAddress(Id accountId , Mass_Email__c massEmailSo, String fieldIndicator) {
        List<String> toemailAddressLst = New List<String>();
        Set<String> emailSet;      
        if(fieldIndicator == 'TO'){
            emailSet = toEmailAddressMap.get(accountId);
        } else if (fieldIndicator == 'CC') {
            emailSet = ccEmailAddressMap.get(accountId);
        }
        if(emailSet!=null && emailSet.size() > 0){
            toemailAddressLst = New List<String>(emailSet);
        } 
        return toemailAddressLst;
    }  
         
        
    //this method creates the task that would be associated with the corresponding root account
    //this lets the users know that an email was sent out for the root account
    public static void createTask(String subject, String mailBody, String userId, String accountId){
        Task taskSo = new Task();
        taskSo.subject = subject;
        taskSo.Description = mailBody; 
        taskSo.status = 'Completed';
        taskSo.OwnerId = userId; //user id        
        taskSo.WhatId = accountId; //record id
        insert taskSo; 
    }
}
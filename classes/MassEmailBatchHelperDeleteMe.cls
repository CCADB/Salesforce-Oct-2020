public class MassEmailBatchHelperDeleteMe {

 public Account accountSo {get;set;}
 
 public void processOwnerRecords(List<Account> accountLst, Mass_Email__c massEmailSo) {
 
      for(Account accountSo : accountLst)
      {
        this.accountSo = accountSo;
        sendEmailForThisOwner(accountSo, massEmailSo);
       
      }
  
  }
 
  public List<String> getPOCEmailAddresses(String contactType) {

      List<Contact> contactLst = [select email from contact where type__c = :contactType and accountid = :accountSo.id];
      List<String> emailLst = New List<String>();

      if(contactLst!=null && contactLst.size() > 0)
      {
       for(Contact contactSo : contactLst)
       {
         if(contactSo.email!=null)
         {
           emailLst.add(contactSo.email);
         }
       }
      }

      return emailLst;
      
  }
   
  
  
  
  public void sendEmailForThisOwner(Account accountSo, Mass_Email__c massEmailSo){
        List<User> userLst = [select id, email,name,firstname,lastname,companyname,title,phone from user where CA_Program_Manager__c = true order by name];            
        
                // create a new instance of singleEmailMessage
                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                
                mail.setPlainTextBody(massEmailSo.Message__c);   
                
                mail.setSubject(massEmailSo.Subject__c);
                
                 // set the TO addresses on the email
                List<String> toEmailAddressLst = populateEmailAddress(massEmailSo,'TO');
                if(toEmailAddressLst!=null && toEmailAddressLst.size() > 0) 
                {
                  mail.setToAddresses(toEmailAddressLst ); 
                }
                
                List<String> ccEmailAddressLst  = populateEmailAddress(massEmailSo,'CC');
                
                if(ccEmailAddressLst!=null && ccEmailAddressLst.size() > 0)
                {
                  mail.setCCAddresses(ccEmailAddressLst); 
                }
                 
                // Set the 'from' display name and email address by using Organization Wide Emails for 'Mozilla'  
                for(OrgWideEmailAddress orgWide : [select id, Address, DisplayName from OrgWideEmailAddress where DisplayName = 'Mozilla CA Program Manager']) {
                    mail.setOrgWideEmailAddressId(orgWide.id); 
                 }
          
              // send out the email
              Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
             List<User> userSoLst = [select id, email,name,firstname,lastname,companyname,title,phone from user 
                           where CA_Program_Manager__c = true order by name];    
                           
              createTask(mail.getSubject(), mail.getPlainTextBody(),userSoLst[0].id,accountSo.id);

  
  }
 
 
 
       public List<String> populateEmailAddress(Mass_Email__c massEmailSo, String fieldIndicator) {
  
          List<String> toemailAddressLst = New List<String>();
                  
              if(fieldIndicator== 'TO' && massEmailSo.Send_To__c!=null && massEmailSo.Send_To__c.length() > 0) 
              {
                  if(massEmailSo.Send_To__c.contains(';'))
                    {
                    
                            List<String> emailSourceLst = massEmailSo.Send_To__c.split(';');
                            for(String emailSource : emailSourceLst)
                            {
                               toEmailAddressLst.addAll(getEmailAddressFromEmailSource(emailSource));
                                
                            }
                    }
                    else
                    {
                       toEmailAddressLst.addAll(getEmailAddressFromEmailSource(massEmailSo.send_to__c));
                      
                    }
                }

              if(fieldIndicator== 'CC' && massEmailSo.CC_To__c!=null && massEmailSo.CC_To__c.length() > 0) 
              {
                  if( massEmailSo.CC_To__c.contains(';'))
                    {
                    
                            List<String> emailSourceLst = massEmailSo.CC_To__c.split(';');
                            for(String emailSource : emailSourceLst)
                            {
                               toEmailAddressLst.addAll(getEmailAddressFromEmailSource(emailSource));
                                
                            }
                    }
                    else
                    {
                       toEmailAddressLst.addAll(getEmailAddressFromEmailSource(massEmailSo.CC_To__c));
                      
                    }
                }



            return   toemailAddressLst;
 
         }  
         
         public List<String> getEmailAddressFromEmailSource(String emailSource) {
          
           List<String> toEmailAddressLst = New List<String>();
             
                 if(emailSource == 'All POCs') {
                  toEmailAddressLst.addAll(getPOCEmailAddresses('POC'));            
                }
                
               if(emailSource == 'All Primary POCs') {
                  toEmailAddressLst.addAll(getPOCEmailAddresses('Primary POC'));            
                } 
                
                if(emailSource == 'CA Email Alias 1' && accountSo.CA_Email_Alias_1__c!=null) {
                    toEmailAddressLst.add(accountSo.CA_Email_Alias_1__c);
                }
               if(emailSource == 'CA Email Alias 2' && accountSo.CA_Email_Alias_2__c!=null) {
                    toEmailAddressLst.add(accountSo.CA_Email_Alias_2__c);
                }
                
                return toEmailAddressLst;
                 
         }
  
  // this method creates the task that would be associated with the corresponding root account
    // this lets the users know that an email was sent out for the root account
    public static void createTask(String subject, String mailBody, String userId, String accountId)
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
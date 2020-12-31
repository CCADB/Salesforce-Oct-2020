/***

This controller class allows users to send emails and set "From", "Reply To", "To" and "CC". 
User can send preview email and then send mail to multiple CA Owner Email Alias, Primary POCs and POCs.

User can enter filter condition in "SOQL Filter Conditions" for any record on account object. No need to
specify the record type. The program logic will determine the assocated CA Owner and Contact records.   

** IMPORTANT **
** Program assumes that org wide settings for the values listed in "From" and "Reply To" picklist is correctly set.
** When a new Root Store Operator is added, "User Eligible to Send Mass Email?" formula field must be updated.
** Validation Rules: Check_for_From_User, Check_for_Reply_To_User has all Root Store Operator
***************

1/30/2018: Send Preview Email' button only sends email to the logged in user 
6/30/2020: Commented filter condition so that we do not check for accounts's CA Owner. No need add any record type in filter.
***/

public with sharing class MassEmailController{

    String massEmailRecordId{get;set;}
    String isPreviewParam {get;set;}
    Public Boolean isPreview  {get;set;}
    Public Boolean showStartBatchButton {get;set;}
    Public Boolean showConfirmBatchButton {get;set;}
    Mass_Email__c massEmailSo {get;set;}
    Public List<DisplayUserInfoWrapper> toLst {get;set;}
    Public List<DisplayUserInfoWrapper> ccLst {get;set;}
    Public String toListPBTitle {get;set;}
    Public String ccListPBTitle {get;set;}
    Public Boolean hasErrors{get;set;}
    
    public massEmailController(Apexpages.standardcontroller controller){
         
        hasErrors = false;
        // get the parentId from the URL param
        massEmailRecordId= ApexPages.currentPage().getParameters().get('id');
        
        // get the parentId from the URL param
        isPreviewParam = ApexPages.currentPage().getParameters().get('isPreview');
        
        isPreview = isPreviewParam!=null && isPreviewParam.length() > 0 ? true : false;
        
        showStartBatchButton  = true;
        showConfirmBatchButton = false;
        toListPBTitle = 'To List';
        ccListPBTitle = 'CC List';
        
        massEmailSo = [select Id, SOQL_Filter_Conditions__c, OwnerId, Name,  Subject__c, from__c, Batch_Status__c, reply_to__c, Message__c, Send_To__c, CC_To__c, User_Eligible_To_Send_Mass_Email__c from Mass_Email__c where id =:massEmailRecordId];
        if(massEmailSo.Batch_Status__c == 'Completed'){
            showStartBatchButton   = false;
            showConfirmBatchButton = true;
        }
        // Not being used
        /* if (!massEmailSo.User_Eligible_To_Send_Mass_Email__c) {
            // showStartBatchButton  = false;
            // showConfirmBatchButton = true; 
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,'\'From\' and \'Reply To\' must be set for your organization. Please \'Go Back\' to correct the field(s).');
            ApexPages.addMessage(myMsg);
            hasErrors=true;
            showStartBatchButton  = false;
        } */  
        
        populateListForAllAccounts(massEmailSo);
    }
    
    //this older constuctor code moved to standard controller.
    /*public massEmailController() {
              
    }*/
        
    //This method is commented because no on preview we are not sending any emails.    
    /*public void massEmailHandler()
    {
    
        if(isPreview)
        {
        
            toListPBTitle = 'To List - Preview';
            ccListPBTitle = 'CC List - Preview';
            
            // Commented by Poonam List<User> userLst = [select id, email,name,firstname,lastname,companyname,title,phone from user where CA_Program_Manager__c = true order by name];            
            List<User> userLst = [select id, email,name,firstname,lastname,companyname,title,phone from user order by name]; 
            
            // create a new instance of singleEmailMessage
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            
            mail.setPlainTextBody(massEmailSo.Message__c);   
            
            mail.setSubject(massEmailSo.Subject__c);
            //   if(massEmailSo.reply_to__c!=null && massEmailSo.reply_to__c.length() > 0)
            //{
            //mail.setReplyTo(massEmailSo.reply_to__c);
            //}
            // set the TO addresses on the email
            
            List<User> userSoLst;
            
            // From must be Current user or root store operator to which he/she belongs; This is validated by validation rule
            // example Mozilla cannot choose Microsoft as From org wide address 
            if(massEmailSo.from__c!='Current User')
            {
                OrgWideEmailAddress orgWide = [select id, Address, DisplayName from OrgWideEmailAddress where DisplayName = :massEmailSo.from__c];
                mail.setOrgWideEmailAddressId(orgWide.id); 
            }
            
            if(massEmailSo.reply_to__c != 'Current User')
            {
            
                OrgWideEmailAddress orgWide;
                try 
                {
                    orgWide = [select id, Address, DisplayName from OrgWideEmailAddress where DisplayName = :massEmailSo.reply_to__c]; 
                }
                catch(Exception ex)
                {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'No entry found in Organization-Wide Email Addresses for ' + massEmailSo.reply_to__c));
                    hasErrors = true;
                    showStartBatchButton =false;
                }
                
                if(!hasErrors)
                {
                    mail.setReplyTo(orgWide.address);
                    //Code commented on 1/30/2018: In preview mode, only send email to the logged in user    
                    //mail.setToAddresses(new List<String> {orgWide.address});
                }
            }
            else
            {
                mail.setReplyTo(UserInfo.getUserEmail());      
            }
            mail.setToAddresses(new List<String> {UserInfo.getUserEmail()});
            //condition added for test class by Sunil             
            if(!hasErrors && !Test.IsRunningTest())
            {
                // send out the email
                Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
            }
        }
        populateListForAllAccounts(massEmailSo);
        if(!hasErrors && isPreview)
        {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO,'Preview email sent out.'));
        }              
    }*/
        
    // method which executes the batch job
    public void startBatch(){
        try {
            showConfirmBatchButton   = false;
            showStartBatchButton  = false;
            Map<Id,Set<String>> toEmailAddressMap = New Map<Id,Set<String>>();
            if(toLst!=null && toLst.size() > 0)
            {
                Set<String> emailSet;
                for(DisplayUserInfoWrapper diw: toLst) {
                    if(toEmailAddressMap.containsKey(diw.ownerId))
                    {
                        emailSet = toEmailAddressMap.get(diw.ownerId);
                    }
                    else
                    {
                        emailSet = New Set<String>();
                    }
                    if(diw.selected)
                        emailSet.add(diw.email);
                    toEmailAddressMap.put(diw.ownerId,emailSet);
                }
            }
            
            Map<Id,Set<String>> ccEmailAddressMap = New Map<Id,Set<String>>();
            if(ccLst!=null && ccLst.size() > 0)
            {
                Set<String> emailSet;
                for(DisplayUserInfoWrapper diw: ccLst) {
                    if(ccEmailAddressMap.containsKey(diw.ownerId))
                    {
                        emailSet = ccEmailAddressMap.get(diw.ownerId);
                    }
                    else
                    {
                        emailSet = New Set<String>();
                    }
                    if(diw.selected)
                        emailSet.add(diw.email);
                    ccEmailAddressMap.put(diw.ownerId,emailSet);
                }
            }
            Database.executeBatch(new MassEmailBatch(massEmailRecordId,toEmailAddressMap,ccEmailAddressMap),1);
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.INFO,'Mass Email Batch Initiated');
            ApexPages.addMessage(myMsg);
            
            //update mass email batch status
            massEmailSo.Batch_Status__c = 'In Progress';
            massEmailSo.Batch_Run_on__c = System.now();
            massEmailSo.No_of_Emails_Sent__c = 0;
            massEmailSo.No_of_Emails_Failed__c = 0;
            massEmailSo.Error_Message__c = '';
            update massEmailSo;
        } catch (Exception ex){
            //update mass email batch status
            massEmailSo.Batch_Status__c = 'Failed';
            massEmailSo.Batch_Run_on__c = System.now();
            massEmailSo.No_of_Emails_Sent__c = 0;
            massEmailSo.No_of_Emails_Failed__c = 0;
            massEmailSo.Error_Message__c = ex.getMessage();
            update massEmailSo;
        }
    }
          
    public void startBatchConfirmation()
    {
        showStartBatchButton  = false;
        showConfirmBatchButton = true; 
    }
         
    public void populateListForAllAccounts(Mass_Email__c massEmailSo) {
    
        Boolean fetchOwnerAccounts = false;
        String soqlStr = 'select id, name, CA_Owner_ID__c, CA_Email_Alias_1__c , CA_Email_Alias_2__c from account '  ;
        if (massEmailSo.SOQL_Filter_Conditions__c!=null && massEmailSo.SOQL_Filter_Conditions__c.length() > 0)
        {
            soqlStr = soqlStr + ' where ' + massEmailSo.SOQL_Filter_Conditions__c;
            String rootCertFilter = 'Record_Type_Name__c=RootCertificate';
            String interCertFilter = 'Record_Type_Name__c=IntermediateCertificate';
            String filterConditions = massEmailSo.SOQL_Filter_Conditions__c;
            
            filterConditions= filterConditions.trim();
            
            filterConditions= filterConditions.replaceAll('(\\s+)', '');
            filterConditions= filterConditions.replaceAll('\'', '');
            
            if( filterConditions.contains(rootCertFilter) || filterConditions.contains(interCertFilter))
            {
                fetchOwnerAccounts = true;
            }
        }
        List<Account> accountSoLst;
        try {
            accountSoLst = Database.query(soqlStr);
            system.debug('accountSoLst  ::: '+accountSoLst );
        }
        catch(Exception e)
        {
            // System.debug('The following exception has occurred: ' + e.getMessage());
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Filter condition is malformed, please make corrections to your selection. Error: ' + e.getMessage()));
            hasErrors=true;
            showStartBatchButton = false;
        }
        if(accountSoLst!=null && accountSoLst.size() > 0) //fetchOwnerAccounts && -> commented on 30th June 2020 as always we have to check accounts's CA Owner
        {
            Set<String> ownerAccountIdSet = New Set<String>();
            
            for(Account accountSo : accountSoLst)
            {
                ownerAccountIdSet.add(accountSo.ca_owner_id__c);
            }
            // system.debug('OwnerSet==' + ownerAccountIdSet);
            accountSoLst = [select id, name, CA_Owner_ID__c, CA_Email_Alias_1__c , CA_Email_Alias_2__c from account where id in :ownerAccountIdSet];
        }
        
        Map<Id,Account> accountSoMap = New Map<Id,Account>();
        if(accountSoLst!=null && accountSoLst.size() > 0)
        {
            for(Account accountSo : accountSoLst)
            {
                accountSoMap.put(accountSo.id, accountSo);
            }
            
            toLst = new List<DisplayUserInfoWrapper>();
            ccLst = new List<DisplayUserInfoWrapper>(); 
            
            this.toLst.addAll(populateToLst(massEmailSo,accountSoMap));
            this.ccLst.addAll(populateCCLst(massEmailSo,accountSoMap));
            this.toLst.sort();
            this.ccLst.sort();
        }
    }


           
    Public List<DisplayUserInfoWrapper> populateToLst(Mass_Email__c massEmailSo, Map<Id,Account> accountSoMap)
    {
        List<DisplayUserInfoWrapper> displayToLst = New List<DisplayUserInfoWrapper>();
        
        if(massEmailSo.Send_To__c!=null && massEmailSo.Send_To__c.length() > 0) 
        {
            if(massEmailSo.Send_To__c.contains(';'))
            {
                List<String> emailSourceLst = massEmailSo.Send_To__c.split(';');
                for(String emailSource : emailSourceLst)
                {
                    displayToLst.addAll(getDisplayWrapperForSource(emailSource, accountSoMap));
                }
            }
            else
            {
                displayToLst.addAll(getDisplayWrapperForSource(massEmailSo.send_to__c, accountSoMap));
            }
        }
    
        return displayToLst ;
    }
         
    Public List<DisplayUserInfoWrapper>  populateCCLst(Mass_Email__c massEmailSo, Map<Id,Account> accountSoMap)
    {
        List<DisplayUserInfoWrapper> displayCCLst = New List<DisplayUserInfoWrapper>();
        
        if(massEmailSo.CC_To__c!=null && massEmailSo.CC_To__c.length() > 0) 
        {
            if( massEmailSo.CC_To__c.contains(';'))
            {
                List<String> emailSourceLst = massEmailSo.CC_To__c.split(';');
                for(String emailSource : emailSourceLst)
                {
                    displayCCLst.addAll(getDisplayWrapperForSource(emailSource, accountSoMap));
                }
            }
            else
            {
                displayCCLst.addAll(getDisplayWrapperForSource(massEmailSo.CC_To__c, accountSoMap));
            }
        }
        return displayCCLst ;
    }
                
    public PageReference cancel() {
    
        PageReference parentRecordPage = new PageReference('/' + massEmailRecordId);
        parentRecordPage.setRedirect(true);
        return parentRecordPage;
    
    }
         
         
    public List<DisplayUserInfoWrapper> getDisplayWrapperForSource(String emailSource, Map<Id,Account> accountSoMap) {
    
        List<DisplayUserInfoWrapper> toEmailAddressLst = New List<DisplayUserInfoWrapper>();
        
        if(emailSource == 'All POCs') {
            toEmailAddressLst.addAll(getPOCEmailAddresses('POC', accountSoMap));            
        }
        
        if(emailSource == 'All Primary POCs') {
            toEmailAddressLst.addAll(getPOCEmailAddresses('Primary POC', accountSoMap));            
        } 
        
        if(emailSource == 'CA Email Alias 1' ) {
            for(Account accountSo : accountSoMap.values())
            {
                if(accountSo.CA_Email_Alias_1__c!=null && accountSo.CA_Email_Alias_1__c.length() > 0)
                { 
                    DisplayUserInfoWrapper displayWrapper = New DisplayUserInfoWrapper();
                    displayWrapper.ownerName= accountSo.name;
                    displayWrapper.email = accountSo.CA_Email_Alias_1__c;
                    displayWrapper.selected = true;
                    displayWrapper.ownerid = accountSo.id;
                    toEmailAddressLst.add(displayWrapper);
                }
            }
        }
        if(emailSource == 'CA Email Alias 2' ) {
            for(Account accountSo : accountSoMap.values())
            {
                if(accountSo.CA_Email_Alias_2__c!=null && accountSo.CA_Email_Alias_2__c.length() > 0)
                { 
                    DisplayUserInfoWrapper displayWrapper = New DisplayUserInfoWrapper();
                    displayWrapper.ownerName= accountSo.name;
                    displayWrapper.email = accountSo.CA_Email_Alias_2__c;
                    displayWrapper.ownerid = accountSo.id;
                    displayWrapper.selected = true;
                    toEmailAddressLst.add(displayWrapper);
                }
            }
        }
        return toEmailAddressLst;
    
    }
         
    public List<DisplayUserInfoWrapper> getPOCEmailAddresses(String contactType, Map<Id,Account> accountSoMap) {
        List<DisplayUserInfoWrapper> displayWrapperLst = New List<DisplayUserInfoWrapper> ();
        List<Contact> contactLst = [select Full_Name__c, email, account.name, Last_Login__c, Is_Community_User_Active__c from contact 
                where type__c = :contactType and accountid = :accountSoMap.keyset()];
        // where type__c = :contactType and accountid = :accountSoMap.keyset() and Is_Community_User_Active__c = true];
        List<String> emailLst = New List<String>();
        
        if(contactLst!=null && contactLst.size() > 0)
        {
            DisplayUserInfoWrapper displayWrapper;
            for(Contact contactSo : contactLst)
            {
                if(contactSo.email!=null && contactSo.email.length() > 0)
                {
                    displayWrapper = new DisplayUserInfoWrapper();
                    displayWrapper.fullname= contactSo.full_name__c;
                    displayWrapper.ownerName = contactSo.account.name;
                    displayWrapper.ownerid = contactSo.accountid;
                    displayWrapper.email = contactSo.email;
                    if(contactSo.Last_Login__c != null)
                    displayWrapper.LastLogin = contactSo.Last_Login__c.format('MM/dd/yyyy hh:mm a');
                    displayWrapper.IsCommunityUserActive = contactSo.Is_Community_User_Active__c ;
                    displayWrapper.selected = true;
                    displayWrapperLst.add(displayWrapper);
                    
                    emailLst.add(contactSo.email);
                }
            }
        }
        
        return displayWrapperLst;
    }
 
 
    public class DisplayUserInfoWrapper implements Comparable {
        Public String ownerName {get;set;}
        Public String fullName {get;set;}
        Public String email {get;set;}
        Public Boolean selected {get; set;}
        Public Id ownerId {get;set;}
        
        //added by Sunil
        public string LastLogin {get; set;}
        public boolean IsCommunityUserActive {get; set;}
    
    
        public Integer compareTo(Object compareTo) {
    
            DisplayUserInfoWrapper  displayWrapper = (DisplayUserInfoWrapper ) compareTo;
            Integer returnValue = 0;
            if (this.ownerName > displayWrapper.ownerName) {
                // Set return value to a positive value.
                returnValue = 1;
            } else if (this.ownerName < displayWrapper.ownerName) {
                // Set return value to a negative value.
                returnValue = -1;
            }
    
            return returnValue;
        }
    }       

}
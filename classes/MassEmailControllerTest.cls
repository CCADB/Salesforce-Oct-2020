/**

Test Case for the following Controller Extension:
MassEmailController
MassEmailBatch
MassEmailBatchHelper
MassEmailAccountFilterController

**/

@isTest 
public class MassEmailControllerTest{

    static testMethod void validateMassEmailAccountFilter() {
    
        PageReference pref = Page.MassEmailAccountFilter;
        Test.setCurrentPage(pref);
        Test.setCurrentPageReference(pref); 
        Mass_Email__c massEmailSo=    createMassEmail();
        System.currentPageReference().getParameters().put('id', massEmailSo.id);
        MassEmailAccountFilterController mafc = new MassEmailAccountFilterController();
        mafc.fetchAccounts();
        mafc.goBackToMassEmailRecord();
        ApexPages.StandardController sc = new ApexPages.StandardController(massEMailSo);
        MassEmailAccountFilterController mafc2 = new MassEmailAccountFilterController(sc);
        
        system.assertNotEquals(mafc.myComponentController,null);
    }
    
    static testMethod void validateMassEmailProgram() {
    
        PageReference pref = Page.MassEmail;
        Test.setCurrentPage(pref);
        Test.setCurrentPageReference(pref); 
        Mass_Email__c massEmailSo=    createMassEmail();
        System.currentPageReference().getParameters().put('id',massEmailSo.id );
        System.currentPageReference().getParameters().put('isPreview', 'false');
        
        Account parentAccount =  getParentAccount();
        insert parentAccount;   
        Contact primaryPOC =getParentContact(parentAccount.id,'Primary POC');
        insert primaryPOC;
        Contact poc = getParentContact(parentAccount.id,'POC');
        insert poc;
        
        MassEmailController mec = new MassEmailController(new Apexpages.standardcontroller(massEmailSo));
        //mec.massEmailHandler();
        mec.cancel();
        mec.startBatchConfirmation();
        
        mec.startBatch();
        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User']; 
        User u = new User(Alias = 'standt', Email='standarduser@testorg.com', 
                EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
                LocaleSidKey='en_US', ProfileId = p.Id, 
                TimeZoneSidKey='America/Los_Angeles', UserName= DateTime.now().getTime() +'standarduser@testorg.com');
        insert u;
        MassEmailBatchHelper.createTask('test','test',u.id,parentAccount.id);
    }
  
    static testMethod void validateMassEmailProgram2() {
  
        PageReference pref = Page.MassEmail;
        Test.setCurrentPage(pref);
        Test.setCurrentPageReference(pref); 
        Mass_Email__c massEmailSo =    createMassEmail2();
        System.currentPageReference().getParameters().put('id',massEmailSo.id );
        System.currentPageReference().getParameters().put('isPreview', 'false');
        
        Account parentAccount =  getParentAccount();
        insert parentAccount;   
        Account rootAccount =  getRootAccount();
        rootAccount.ca_owner_id__c = parentAccount.id;
        insert rootAccount;   
        
        Contact primaryPOC =getParentContact(parentAccount.id,'Primary POC');
        insert primaryPOC;
        Contact poc = getParentContact(parentAccount.id,'POC');
        insert poc;
        
        MassEmailController mec = new MassEmailController(new Apexpages.standardcontroller(massEmailSo));
        //mec.massEmailHandler();
        mec.cancel();
        mec.startBatchConfirmation();
        mec.startBatch();
        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User']; 
        User u = new User(Alias = 'standt', Email='standarduser@testorg.com', 
        EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
        LocaleSidKey='en_US', ProfileId = p.Id, 
        TimeZoneSidKey='America/Los_Angeles', UserName= DateTime.now().getTime() +'standarduser@testorg.com');
        insert u;
        MassEmailBatchHelper.createTask('test','test',u.id,parentAccount.id);
    }
   
    
    Public static Mass_Email__c createMassEmail() {
  
        Mass_Email__c massEmailSo = new Mass_Email__c();
        massEmailSo.CC_To__c = 'All POCs;CA Email Alias 2';
        // massEmailSo.From__c = 'abc@xyz.com';
        massEmailSo.from__c = 'Mozilla CA Program Manager';
        massEmailSo.message__c = 'Dear Someone,Testing custom mass emails. Regards,Mozilla';
        massEmailSo.reply_to__c = 'Mozilla CA Program Manager ';
        massEmailSo.Send_To__c = 'All Primary POCs;CA Email Alias 1';
        
        massEmailSo.Subject__c = 'Testing Mass Email';
        insert massEmailSo;
        return massEmailSo;
    }

    Public static Mass_Email__c createMassEmail2() {
        Mass_Email__c massEmailSo = new Mass_Email__c();
        massEmailSo.CC_To__c = 'All POCs;CA Email Alias 2';
        // massEmailSo.From__c = 'abc@xyz.com';
        massEmailSo.from__c = 'Mozilla CA Program Manager';
        massEmailSo.message__c = 'Dear Someone,Testing custom mass emails. Regards,Mozilla';
        massEmailSo.reply_to__c = 'Current User';
        massEmailSo.Send_To__c = 'All Primary POCs;CA Email Alias 1';
        massEmailSo.SOQL_Filter_Conditions__c = 'Record_Type_Name__c=\'Intermediate Certificate\'';
        massEmailSo.Subject__c = 'Testing Mass Email';
        insert massEmailSo;
        return massEmailSo;
    }
  
    public static Account getParentAccount()
    {
        Account parentAccount = new Account();
        parentAccount.recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('CA Owner').getRecordTypeID();
        parentAccount.name = 'ParentAccount1';
        parentAccount.type = 'Owner';
        parentAccount.phone='2128425500';
        parentAccount.website  = 'https//www.test.com';
        parentAccount.valid_From_GMT__c= date.today()+1;
        parentAccount.valid_to_GMT__c= date.today()+10;
        parentAccount.company_website__c=  'https//www.test.com';
        parentAccount.organizational_type__c=  'Or ganizational Type';
        parentAccount.geographic_focus__c=  'Geographic focus';
        parentAccount.primary_market_customer_base__c = 'Primary Market';
        parentAccount.CA_Email_Alias_1__c = 'abc@xyz.com';
        parentAccount.CA_Email_Alias_2__c = 'abc@xyz.com';
        return parentAccount;
    }
    
    
    public static Account getRootAccount()
    {
        Account parentAccount = new Account();
        parentAccount.recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Root Certificate').getRecordTypeID();
        parentAccount.name = 'ParentAccount2';
        parentAccount.type = 'Owner';
        parentAccount.phone='2128425500';
        parentAccount.website  = 'https//www.test.com';
        parentAccount.valid_From_GMT__c= date.today()+1;
        parentAccount.valid_to_GMT__c= date.today()+10;
        parentAccount.company_website__c=  'https//www.test.com';
        parentAccount.organizational_type__c=  'Organizational Type';
        parentAccount.geographic_focus__c=  'Geographic focus';
        parentAccount.primary_market_customer_base__c = 'Primary Market';
        parentAccount.CA_Email_Alias_1__c = 'abc@xyz.com';
        parentAccount.CA_Email_Alias_2__c = 'abc@xyz.com';
        return parentAccount;
    }
    public static Contact getParentContact(ID accountid, String typeStr)
    {
        Contact parentContact = new Contact();
        parentcontact.firstname = 'FirstName';
        parentcontact.accountid = accountId;
        parentcontact.lastname = 'LastName';
        parentcontact.email= 'LastName@firstname.com';
        parentcontact.phone= '456786588';
        parentcontact.type__c= typeStr;
       
        return parentContact;
    }
}
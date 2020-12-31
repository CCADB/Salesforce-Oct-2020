/*
    Description: Test class for UpdateLastLoginController
*/
@isTest
public with sharing class UpdateLastLoginControllerTest {

    static testmethod void TestLastLogin(){
        // create the parent account  - record type = Owner
        Account parentAccount = new Account();
        parentAccount.recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('CA Owner').getRecordTypeID();
        parentAccount.name = 'ParentAccount';
        parentAccount.type = 'Owner';
        parentAccount.CA_Email_Alias_1__c='EmailAlias1@Company.junk';
        parentAccount.CA_Email_Alias_2__c='EmailAlias2@Company.junk';
        parentAccount.website  = 'https//www.test.com';
        parentAccount.valid_From_GMT__c= date.today()+1;
        parentAccount.valid_to_GMT__c= date.today()+10;
        parentAccount.company_website__c=  'https//www.test.com';
        parentAccount.organizational_type__c=  'Organizational Type';
        parentAccount.geographic_focus__c=  'Geographic focus';
        parentAccount.status__c = 'Included';
        insert parentAccount;
         
        Id profile = [select id from profile Where Name ='Customer Community Plus Login User For CCADB' AND UserType = 'PowerCustomerSuccess' LIMIT 1].id;
            
        // create the contact associated with the parent account
        Contact parentContact = new Contact();
        parentcontact.firstname = 'FirstName';
        parentcontact.accountid = parentAccount.ID;
        parentcontact.lastname = 'LastName';
        parentcontact.email= 'LastName@firstname.com';
        parentcontact.phone= '456786588';
        parentcontact.type__c= 'Primary POC';
        insert parentContact;
         
        User user = new User(alias = 'test123', email='test123@noemail.com',
                    emailencodingkey='UTF-8', lastname='Testing', languagelocalekey='en_US',
                    localesidkey='en_US', profileid = profile, country='United States',IsActive =true,
                    ContactId = parentContact.Id,
                    timezonesidkey='America/Los_Angeles', username='tester@noemail.com');
        insert user;
        UpdateLastLoginController uilogin = new UpdateLastLoginController();
        UpdateLastLoginController.UpdateContacts();
        UpdateLastLoginSchedulerClass.scheduleMe('Update Last Login'+system.now());
    }
    
}
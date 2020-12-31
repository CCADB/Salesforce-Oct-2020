/*******************************************************************************************************
 Name: CAHomePageControllerTest

 Dependencies: CAHomePageController controller class, CAHomePage vf page, 
 CAHomePageControllerTest test class

 Description: This is a test class for CA's Task List (added to home page). It generates
 various reports and a summary wih record count for the CA Owner to which the logged in user is 
 associated. Detail report is only displayed when the record count is greater than 1.
 
 Root Certs with Outdated Audit Statements
 Intermediate Certs with Outdated Audit Statements
 Intermediate Certs with no audit information provided
 Intermediate Certs with no CP/CPS information provided
 Contacts who may be obsolete
 
 Instructions: Add the VF page to CA's home page
 *******************************************************************************************************
 Revision History:
 
     6/12/2019 - Created new class
 ******************************************************************************************************/
 
@isTest
public with sharing class CAHomePageControllerTest {
    
    static testmethod void TestCATaskList(){
        Account caOwnerAcc = TestUtils.getCAOwner();
        insert caOwnerAcc;
        
        Contact con = TestUtils.getContact(caOwnerAcc.id);
        con.recordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('CA Contact').getRecordTypeId();
        insert con;
        
        Account rootAccount = TestUtils.getRootCertificate(caOwnerAcc.id);
        rootAccount.Name = 'child root account 1';
        rootAccount.Standard_Audit__c = 'https://std.com';
        rootAccount.Standard_Audit_Type__c = 'WebTrust';
        rootAccount.Standard_Audit_Statement_Date__c = system.today().addDays(-400);
        rootAccount.Standard_Audit_Period_Start_Date__c = system.today().addDays(-400);
        rootAccount.Standard_Audit_Period_End_Date__c = system.today().addDays(-400);
        rootAccount.Certificate_Policy_CP__c = 'https://cp.com';
        rootAccount.Certification_Practice_Statement_CPS__c = 'https://cps.com';
        insert rootAccount;
        
        Account interCertAccount1 = TestUtils.getIntermediateCertificate(rootAccount.id);
        interCertAccount1.Name = 'child Intercert account 1';
        interCertAccount1.Standard_Audit__c = 'https://std.com';
        interCertAccount1.Standard_Audit_Type__c = 'WebTrust';
        interCertAccount1.Standard_Audit_Statement_Date__c = system.today().addDays(-400);
        interCertAccount1.Standard_Audit_Period_Start_Date__c = system.today().addDays(-400);
        interCertAccount1.Standard_Audit_Period_End_Date__c = system.today().addDays(-400);
        interCertAccount1.Standard_Audit_ALV_Found_Cert__c = 'FAIL'; 
        insert interCertAccount1;
        
        Account interCertAccount2 = TestUtils.getIntermediateCertificate(rootAccount.id);
        interCertAccount2.Name = 'child Intercert account 2';
        interCertAccount2.Audits_Same_as_Parent__c = false;
        interCertAccount2.CP_CPS_Same_as_Parent__c = false;
        insert interCertAccount2;
        
        //create community user
        User user = new User();
        user.ProfileId = [SELECT Id FROM Profile WHERE Name = 'Customer Community Plus Login User - CAs' AND UserType = 'PowerCustomerSuccess' LIMIT 1].Id;
        user.EmailEncodingKey = 'ISO-8859-1';
        user.LanguageLocaleKey = 'en_US';
        user.TimeZoneSidKey = 'America/New_York';
        user.LocaleSidKey = 'en_US';
        user.FirstName = 'first';
        user.LastName = 'last';
        user.Username = 'test@test1234098.com';   
        user.CommunityNickname = 'testUser09887123';
        user.Alias = 't1';
        user.Email = 'no@email.com';
        user.IsActive = true;
        user.ContactId = con.Id;
        insert user;
        
        System.RunAs(user) {
            CAHomePageController controller = new CAHomePageController();
        }
    }
}
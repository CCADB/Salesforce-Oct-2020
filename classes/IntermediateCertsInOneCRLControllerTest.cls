/*******************************************************************************************************
 Name: IntermediateCertsInOneCRLControllerTest

 Dependencies: IntermediateCertsInOneCRLController, IntermediateCertsInOneCRLReport vf page,
 IntermediateCertsInOneCRLReportCSV vf page, IntermediateCertsInOneCRLControllerTest

 Description: This report generates list of intermediate certs which are in OneCRL.

 Instructions: None

 *******************************************************************************************************
 Revision History:
 
     11/19/2019 - Created new

 ******************************************************************************************************/
 
@isTest 
public class IntermediateCertsInOneCRLControllerTest{

    static testMethod void validateTest() {
        Account parentAccount = new Account();
        parentAccount.recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('CA Owner').getRecordTypeID();
        parentAccount.name = 'ParentAccount';
        insert parentAccount;
        
        Account childAccount = new Account();
        childAccount.recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Intermediate Certificate').getRecordTypeID();
        childAccount.name = 'ChildAccount';
        childAccount.Status__c = 'Included';
        childAccount.OneCRL_Status__c = 'Added to OneCRL';
        childAccount.OneCRL_Bug_Number__c = '123';
        childAccount.CRL_URL_s__c = 'Test CRL URL';
        childAccount.Valid_To_GMT__c = System.Today().addYears(1);
        childAccount.Comments__c = 'Test Comments';       
        childAccount.NSS_Release_When_First_Included__c = 'Test';
        childAccount.Firefox_Release_When_First_Included__c = 'Test';
        childAccount.Mozilla_Applied_Constraints__c = 'Test';
        childAccount.Certificate_Policy_CP__c = 'Test';
        childAccount.Certification_Practice_Statement_CPS__c = 'Test';
        childAccount.Mozilla_Root_Status__c = 'Included';
        insert childAccount;

        PageReference pref = Page.IntermediateCertsInOneCRLReport;
        Test.setCurrentPage(pref);
        
        IntermediateCertsInOneCRLController pacrc = new IntermediateCertsInOneCRLController();
        pacrc.getCurrentDate();
    }

}
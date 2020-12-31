/**

Test Case for the following Controller Extension:
PublicIntermediateCertsRevokedController

**/

@isTest 
public class PublicIntermediateCertsRevokedCtlrTest{

    static testMethod void validateTest() {
        
        Account parentAccount = new Account();
        parentAccount.recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('CA Owner').getRecordTypeID();
        parentAccount.name = 'ParentAccount';
        insert parentAccount;
        
        Account childAccount = new Account();
        childAccount.recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Intermediate Certificate').getRecordTypeID();
        childAccount.name = 'ChildAccount';
        childAccount.Status__c = 'Included';
        childAccount.OneCRL_Status__c = 'Ready to Add';
        childAccount.Certificate_Issuer_Organization__c = 'Test IO';
        childAccount.Certificate_Issuer_Organizational_Unit__c = 'Test IOU';
        childAccount.Certificate_Issuer_Common_Name__c = 'Test CName';
        childAccount.Certificate_Subject_Common_Name__c = 'Test SName';
        childAccount.Certificate_Subject_Organization__c = 'Test OName';
        childAccount.OneCRL_Bug_Number__c = '123';
        childAccount.CRL_URL_s__c = 'Test URL';
        //childAccount.OCSP_URL_s__c = 'Test ';
        childAccount.Comments__c = 'Test Comment';
        childAccount.Approval_Bug__c = 'Test';
        childAccount.NSS_Release_When_First_Included__c = 'Test';
        childAccount.Firefox_Release_When_First_Included__c = 'Test';
        childAccount.Mozilla_Applied_Constraints__c = 'Test';
        childAccount.Certificate_Policy_CP__c = 'Test';
        childAccount.Certification_Practice_Statement_CPS__c = 'Test';
        childAccount.X_509_Certificate_PEM__c = 'Test';
        childAccount.Revocation_Status__c = 'Revoked';
        insert childAccount;

    
        PageReference pref = Page.PublicIntermediateCertsRevoked;
        Test.setCurrentPage(pref);
        
        PublicIntermediateCertsRevokedController pacrc = new PublicIntermediateCertsRevokedController();
        pacrc.getCurrentDate();
    }

}
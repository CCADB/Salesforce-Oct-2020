/**

Test Case for the following Controller Extension:
IncludedCACertificateReportController

**/

@isTest
public class IncludedCACertificateReportControlerTest {
  static testMethod void validateTest() {
    Account parentAccount = new Account();
    parentAccount.recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName()
      .get('CA Owner')
      .getRecordTypeID();
    parentAccount.name = 'ParentAccount';
    insert parentAccount;

    Account childAccount = new Account();
    childAccount.recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName()
      .get('Root Certificate')
      .getRecordTypeID();
    childAccount.name = 'ChildAccount';
    childAccount.Status__c = 'Included';
    childAccount.Certificate_Issuer_Organization__c = 'Test IO';
    childAccount.Certificate_Issuer_Organizational_Unit__c = 'Test IOU';
    childAccount.Approval_Bug__c = 'Test';
    childAccount.NSS_Release_When_First_Included__c = 'Test';
    childAccount.Firefox_Release_When_First_Included__c = 'Test';
    childAccount.Mozilla_Applied_Constraints__c = 'Test';
    //childAccount.Certificate_Policy_CP__c = 'Test';
    //childAccount.Certification_Practice_Statement_CPS__c = 'Test';
    childAccount.Test_Website_Expired__c = 'https://expired.com';
    childAccount.Test_Website_Revoked__c = 'https://revoked.com';
    childAccount.X_509_Certificate_PEM__c = 'Test';
    insert childAccount;

    Policy_Document_On_Certificate__c PDC = new Policy_Document_On_Certificate__c(
      Document_Link__c = 'https://CPCPS.com',
      Document_Type__c = 'CP/CPS'
    );
    insert PDC;

    PolicyDocumentAssociation_On_Certificate__c PDAC = new PolicyDocumentAssociation_On_Certificate__c(
      Policy_Document__c = PDC.Id,
      Certificate_Name__c = childAccount.Id
    );
    insert PDAC;

    Apexpages.currentpage().getParameters().put('test', 'ReportCSV');
    IncludedCACertificateReportController pacrc = new IncludedCACertificateReportController();
    pacrc.getCurrentDate();
  }
}
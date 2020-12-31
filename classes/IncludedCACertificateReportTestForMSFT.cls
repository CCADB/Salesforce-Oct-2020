/*******************************************************************************************************
 Name: IncludedCACertificateReportCtlrForMSFT

 Dependencies:  IncludedCACertificateReportCtlrForMSFT controller class, IncludedCACertificateReportTestForMSFT
 test class, IncludedCACertificateReportForMSFT vf page, IncludedCACertificateReportForMSFTCSV  vf page,
 IncludedCACertificateReportForMSFTCSVPEM  vf page

 Description: This is a test class for controller IncludedCACertificateReportCtlrForMSFT which
 generates list all root certificates included by Microsoft.
 
 Instructions: None   
 *******************************************************************************************************
 Revision History:
 
      8/16/2016 - Created new class
 ******************************************************************************************************/

@isTest 
public class IncludedCACertificateReportTestForMSFT{

    static testMethod void validateTest() {
        PageReference pref = Page.IncludedCACertificateReportForMSFTCSV;
        Test.setCurrentPage(pref);
        
        Account caOwnerAcc = TestUtils.getCAOwner();
        insert caOwnerAcc;
        
        Account childAccount = TestUtils.getRootCertificate(caOwnerAcc.id);
        childAccount.Microsoft_Status__c = 'Included';
        childAccount.Friendly_Name__c = 'Test root';
        childAccount.Certificate_Issuer_Organization__c = 'Test IO';
        childAccount.Certificate_Issuer_Organizational_Unit__c = 'Test IOU';
        childAccount.Approval_Bug__c = 'Test';
        childAccount.NSS_Release_When_First_Included__c = 'Test';
        childAccount.Firefox_Release_When_First_Included__c = 'Test';
        childAccount.Mozilla_Applied_Constraints__c = 'Test';
        childAccount.Certificate_Policy_CP__c = 'Test';
        childAccount.Certification_Practice_Statement_CPS__c = 'Test';
        childAccount.Test_Website_Expired__c = 'https://expired.com';
        childAccount.Test_Website_Revoked__c = 'https://revoked.com';
        childAccount.X_509_Certificate_PEM__c = 'Test';
        insert childAccount;
        
        IncludedCACertificateReportCtlrForMSFT certs = new IncludedCACertificateReportCtlrForMSFT();
        certs.getCurrentDate();
    }
}
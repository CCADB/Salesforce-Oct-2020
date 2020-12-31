/*******************************************************************************************************
 Name: InterCertsRevokedReportForMSFTCtrlTest

 Dependencies: InterCertsRevokedReportForMSFTCtrl, InterCertsRevokedReportForMSFTCSV vf page,
 InterCertsRevokedReportForMSFTCtrlTest

 Description: This is a test class is for InterCertsRevokedReportForMSFTCtrl class. 
 This report generates list of intermediate certs which are revoked for Microsoft.

 Instructions: None

 *******************************************************************************************************
 Revision History:
 
     11/15/2019 - Created new

 ******************************************************************************************************/
@isTest
public with sharing class InterCertsRevokedReportForMSFTCtrlTest {
    static testmethod void TestReport() {
        Account caOwnerAcc = TestUtils.getCAOwner();
        insert caOwnerAcc;
        
        //create root certs
        Account rootAccount = TestUtils.getRootCertificate(caOwnerAcc.id);
        rootAccount.Name = 'child root account 1';       
        rootAccount.Microsoft_Status__c = 'Included';
        rootAccount.SHA_1_Fingerprint__c = '0001';
        rootAccount.SHA_256_Fingerprint__c = '00256';
        insert rootAccount;
 
        //create intermediate certs
        Account intermediatecert = TestUtils.getIntermediateCertificate(rootAccount.Id);
        intermediatecert.Name = 'Test Intermediate Cert 1';
        intermediatecert.Revocation_Status__c = 'Revoked';
        intermediatecert.Root_Cert_Id__c = rootAccount.id;
        intermediatecert.SHA_256_Fingerprint__c = '256';
        intermediatecert.X_509_Certificate_PEM__c = 'ABC';
        intermediatecert.Revocation_Verification__c = 'Verified';
        insert intermediatecert;
        
        //create intermediate certs
        Account intermediatecert2 = TestUtils.getIntermediateCertificate(rootAccount.Id);
        intermediatecert2.Name = 'Test Intermediate Cert 2';
        intermediatecert2.Revocation_Status__c = 'Not Revoked';       
        intermediatecert2.Root_Cert_Id__c = rootAccount.id;
        intermediatecert2.X_509_Certificate_PEM__c = 'XYZ';
        intermediatecert2.SHA_256_Fingerprint__c = '000256';
        intermediatecert2.Revocation_Verification__c = 'Verified';
        insert intermediatecert2;
        
        Test.startTest();
        
        InterCertsRevokedReportForMSFTCtrl controller = new InterCertsRevokedReportForMSFTCtrl ();
        controller.getsfdcBaseURL();
        
        Test.stopTest();
    }
}
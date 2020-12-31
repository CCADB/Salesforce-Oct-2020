/*******************************************************************************************************
 Name: DoppelgangerReportControllerTest

 Dependencies: DoppelgangerReportController controller class, DoppelgangerReport vf page, RSHomePageControllerTest test class

 Revision History:
 
     10/9/2019 - Created new class
 ******************************************************************************************************/
 
@isTest
public with sharing class DoppelgangerReportControllerTest {
    
    static testmethod void TestDoppelgangerReport() {
        Lead lead = new Lead(LastName = 'Test Lead',Company = 'Test Company', Email = 'test@gmail.com');
        insert lead;
        
        Account acc = TestUtils.getCAOwner();
        acc.Status__c = 'Included';
        insert acc;
        
        // create a ROOT CA
        Account rootCA = TestUtils.getRootCertificate(acc.Id); 
        rootCa.X_509_Certificate_PEM__c = 'Root';
        rootCa.Status__c = 'Included';
        rootCa.Trust_Bits__c = 'Websites';
        rootCa.Subject_SPKI_SHA256__c = 'C90FBC2664485F6D3175055A45EF10D2EB6E6C7E027DF1A1D526458C42F42696';
        rootCa.Mozilla_Root_Status__c = 'Included';
        rootCa.Microsoft_Root_Status__c = 'Included';
        insert rootCa;
        
        Test.startTest(); 
        
        // create intermediate CA
        Account testAccount = TestUtils.getIntermediateCertificate(rootCa.Id);
        testAccount.X_509_Certificate_PEM__c = 'Inter Cert 1';
        testAccount.Subject_SPKI_SHA256__c = 'C90FBC2664485F6D3175055A45EF10D2EB6E6C7E027DF1A1D526458C42F42697';
        testAccount.Extended_Key_Usage__c = 'ExtKeyUsageEmailProtection,ExtKeyUsageClientAuth';
        testAccount.SHA_1_Fingerprint__c = '1234567890123456789012345678901234596352';
        testAccount.Revocation_Status__c = 'Not Revoked';
        testAccount.Valid_To_GMT__c = System.Today().addYears(1);
        testAccount.Technically_Constrained__c  = true;
        testAccount.Mozilla_Root_Status__c = 'Included';
        testAccount.Microsoft_Root_Status__c = 'Included';
        insert testAccount; 
        
        testAccount = TestUtils.getIntermediateCertificate(rootCa.Id);
        testAccount.X_509_Certificate_PEM__c = 'Inter Cert 2';
        testAccount.Subject_SPKI_SHA256__c = 'C90FBC2664485F6D3175055A45EF10D2EB6E6C7E027DF1A1D526458C42F42697';
        testAccount.Extended_Key_Usage__c = 'ExtKeyUsageEmailProtection,ExtKeyUsageClientAuth';
        testAccount.SHA_1_Fingerprint__c = '12345678901234567890123456789012345753185';
        testAccount.Revocation_Status__c = 'Not Revoked';
        testAccount.Valid_To_GMT__c = System.Today().addYears(1);
        testAccount.Mozilla_Root_Status__c = 'Included';
        testAccount.Microsoft_Root_Status__c = 'Included';
        insert testAccount; 
        
        DoppelgangerReportController controller = new DoppelgangerReportController();
        
        Test.stopTest(); 
    }
    
}
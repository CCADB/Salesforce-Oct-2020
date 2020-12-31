/*******************************************************************************************************
 Name: RSHomePageControllerMSFTTest

 Dependencies: RSHomePageControllerMSFT controller class, RSHomePageMSFT vf page, RSHomePageControllerMSFTTest test class

 Description: This is a test class for Mozilla's Root Store home page. The program generates
 various reports with record count. Detail report is only displayed when the 
 record count is greater than 1.
    
    Report sections showing the following ...
    
    1) Open Leads assigned to Microsoft
    2) Open Audit Cases assigned to Microsoft
    3) Expired Root Certificates in Microsoft’s program

 Instructions: Add the VF page to Root Store's home page
 *******************************************************************************************************
 Revision History:
 
     9/3/2019 - Created new class
 ******************************************************************************************************/
 
@isTest
public with sharing class RSHomePageControllerMSFTTest {
    
    static testmethod void TestRSHomepage() {
        Lead lead = new Lead(LastName = 'Test Lead',Company = 'Test Company', Email = 'test@gmail.com');
        insert lead;
        
        Account acc = TestUtils.getCAOwner();
        acc.Status__c = 'Included';
        insert acc;
        
        Case caseSO = TestUtils.getCase(acc.Id);
        caseSO.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('CA Audit Update Request').getRecordTypeId();
        insert caseSO;
         
        // create a ROOT CA
        Account rootCA = TestUtils.getRootCertificate(acc.Id); 
        rootCa.X_509_Certificate_PEM__c = 'Root';
        rootCa.Status__c = 'Included';
        rootCa.Trust_Bits__c = 'Websites';
        rootCa.Subject_SPKI_SHA256__c = 'C90FBC2664485F6D3175055A45EF10D2EB6E6C7E027DF1A1D526458C42F42696';
        insert rootCa;
        
        Test.startTest(); 
        
        // create intermediate CA
        Account testAccount = TestUtils.getIntermediateCertificate(rootCa.Id);
        testAccount.X_509_Certificate_PEM__c = 'Inter Cert 1';
        testAccount.Subject_SPKI_SHA256__c = 'C90FBC2664485F6D3175055A45EF10D2EB6E6C7E027DF1A1D526458C42F42697';
        testAccount.Extended_Key_Usage__c = 'ExtKeyUsageEmailProtection,ExtKeyUsageClientAuth';
        testAccount.SHA_1_Fingerprint__c = '1234567890123456789012345678901234596352';
        insert testAccount; 
        
        testAccount = TestUtils.getIntermediateCertificate(rootCa.Id);
        testAccount.X_509_Certificate_PEM__c = 'Inter Cert 3';
        testAccount.Subject_SPKI_SHA256__c = 'C90FBC2669518F6D3175055A45EF10D2EB6E6C7E027DF1A1D526458C42F42698';
        testAccount.Extended_Key_Usage__c = 'ExtKeyUsageEmailProtection,ExtKeyUsageClientAuth';
        testAccount.Revocation_Status__c = 'Revoked';
        testAccount.SHA_1_Fingerprint__c = '12345678901234567890123456789012345753185';
        testAccount.OneCRL_Status__c = '';
        testAccount.Root_Cert_Id__c = rootCa.Id;
        insert testAccount; 
        
        RSHomePageControllerMSFT controller = new RSHomePageControllerMSFT ();
        
        Test.stopTest(); 
    }
    
}
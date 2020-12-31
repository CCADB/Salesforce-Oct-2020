/*******************************************************************************************************
 Name: RSHomePageControllerTest

 Dependencies: RSHomePageController controller class, RSHomePage vf page, RSHomePageControllerTest test class

 Description: This is a test class for Mozilla's Root Store home page. 
 The Mozilla's Root Store's Task List report (added to home page). It generates
 various reports wih record count. Detail report is only displayed when the 
 record count is greater than 1.
    
    Report sections showing the following ...
    
    1) Open Leads 
    2) Open Audit Cases assigned to Mozilla which are updated by CA 
    3) Open Root Inclusion Cases which are updated by CA 
    4) Audit Data Integrity (which linked to vf page)
    5) Verify Updated Audits
    6) Verify Revoked Certst  
    7) Externally Operated Intermediate Certs missing Owner or Auditor Info
    8) Expired Root Certificates
    9) CAs Missing Email Alias 
   10) Ready to Add to OneCRL
   11) Deltas between "Mozilla EV Policy OID(s)" and "ExtendedValidation.cpp OIDs"
   12) Revoked Certs with Failed Revocation Verification
   13) Root Certs with Distrust After
   14) Unconstrained SubCAs Report
    
 Instructions: Add the VF page to Root Store's home page
 *******************************************************************************************************
 Revision History:
 
     7/8/2019 - Created new class
 ******************************************************************************************************/
 
@isTest
public with sharing class RSHomePageControllerTest {
    
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
        rootCa.ExtendedValidation_cpp_OIDs__c = '2.16.840.1.114028.10.1.1';
        rootCa.EV_Policy_OID_s__c = '2.16.840.1.114028.10.1.1';
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
        testAccount.Mozilla_Root_Status__c = 'Included';
        testAccount.Derived_Trust_Bits__c = 'Secure Email';
        testAccount.Root_Cert_Id__c = rootCa.Id;
        insert testAccount; 
        
        RSHomePageController controller = new RSHomePageController ();
        
        Test.stopTest(); 
    }
    
}
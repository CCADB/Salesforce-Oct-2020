/*******************************************************************************************************
 Name: CrossSignedRemovedRootsControllertest

 Dependencies: CrossSignedRemovedRootsController controller class, CrossSignedRemovedRootsControllerTest 
 test class, CrossSignedRemovedRootsReport vf page

 Description: This is a test class for CrossSignedRemovedRootsController which reports
 removed Root Certs followed by cross signed Intermediate Certs. Only the inter certs which are not 
 expired and their Revocation Status is not ‘Revoked’ or ‘Parent Cert Revoked’ are listed in the report.
 
 Instructions: None   
 *******************************************************************************************************
 Revision History:
 
     6/5/2018 - Created new class
 ******************************************************************************************************/
 
@isTest
public with sharing class CrossSignedRemovedRootsControllerTest {
    static testMethod void TestCrossSignedRemovedReport() {
    
        Account caOwnerAcc = TestUtils.getCAOwner();
        insert caOwnerAcc;
        
        Account rootAccount1 = TestUtils.getRootCertificate(caOwnerAcc.id);
        rootAccount1.Name = 'child root account 1';
        rootAccount1.Standard_Audit__c = 'https://std.com';
        rootAccount1.Standard_Audit_Type__c = 'WebTrust';
        rootAccount1.Standard_Audit_Statement_Date__c = system.today();
        rootAccount1.Standard_Audit_Period_Start_Date__c = system.today();
        rootAccount1.Standard_Audit_Period_End_Date__c = system.today();
        rootAccount1.Certificate_Policy_CP__c = 'https://cp.com';
        rootAccount1.Certification_Practice_Statement_CPS__c = 'https://cps.com';
        rootAccount1.Status__c = 'Removed';
        rootAccount1.Firefox_Release_When_Removed__c = 'V123';
        rootAccount1.NSS_Release_When_Removed__c = 'N123';
        rootAccount1.Subject_SPKI_SHA256__c = 'C90FBC2664485F6D3175055A45EF10D2EB6E6C7E027DF1A1D526458C42F42696';
        insert rootAccount1;
        
        Account rootAccount2 = TestUtils.getRootCertificate(caOwnerAcc.id);
        rootAccount2.Name = 'child root account 2';
        rootAccount2.Standard_Audit__c = 'https://std.com';
        rootAccount2.Standard_Audit_Type__c = 'WebTrust';
        rootAccount2.Standard_Audit_Statement_Date__c = system.today();
        rootAccount2.Standard_Audit_Period_Start_Date__c = system.today();
        rootAccount2.Standard_Audit_Period_End_Date__c = system.today();
        rootAccount2.Certificate_Policy_CP__c = 'https://cp.com';
        rootAccount2.Certification_Practice_Statement_CPS__c = 'https://cps.com';
        rootAccount2.Status__c = 'Included';
        rootAccount2.Firefox_Release_When_Removed__c = 'V123';
        rootAccount2.NSS_Release_When_Removed__c = 'N234';
        rootAccount2.Subject_SPKI_SHA256__c = 'XXXXC2664485F6D3175055A45EF10D2EB6E6C7E027DF1A1D526458C42F42696';
        insert rootAccount2;
        
        Account interCertAccount1 = TestUtils.getIntermediateCertificate(rootAccount1.id);
        interCertAccount1.Name = 'child Intercert account 1';
        interCertAccount1.Audits_Same_as_Parent__c = true;
        interCertAccount1.CP_CPS_Same_as_Parent__c = true;
        interCertAccount1.Valid_To_GMT__c = system.today().addYears(1);
        interCertAccount1.Revocation_Status__c = 'Not Revoked';
        interCertAccount1.Subject_SPKI_SHA256__c = 'C90FBC2664485F6D3175055A45EF10D2EB6E6C7E027DF1A1D526458C42F42696';
        interCertAccount1.Root_Cert_Id__c = rootAccount2.id; 
        insert interCertAccount1;
        
        CrossSignedRemovedRootsController controller = new CrossSignedRemovedRootsController();
    }
}
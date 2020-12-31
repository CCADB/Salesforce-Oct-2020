/*******************************************************************************************************
 Name: RunALVonHierarchyControllerTest

 Dependencies: RunALVonHierarchyController controller class, RunALVonHierarchy vf page, 
 RunALVonHierarchyControllerTest

 Description: This is a test class for RunALVonHierarchyController
 The controller class is created to clear the ALV fields and run ALV on hierarchy from
 a button on root cert for all intermediate certs which have Audits Same As Parent set 
 to True. "Run ALV on Hierarchy" button on root cert page allows root store operators to
 rerun ALV for the certs which are in the hierarchy. One inter cert is sent to ALV for 
 processing at a time. It calls common methods from RunALVForInterCertsBatch.
 
 There is another process that is related to ALV processing on inter certs. When a user makes 
 changes to auditor or audit fields on root or intermediate certificate records, the account 
 trigger (UpdateALVDateProcessed method) will traverse down the hierarchy to clear all of the ALV 
 fields for child (grandchild, etc) records that have "Audits Same as Parent" (includes 
 expired and revoked). There are 3 ways ALV can be rerun for these certs:
 1. A nightly scheduled batch job "ALV Batch for Inter Certs" will automatically pick these
 inter certs and rerun ALV.
 2. A system admin can initiate "ALV Batch for Inter Certs" batch process anytime from 
 "Batch Processes" custom tab.
 3. "Use this "Run ALV on Hierarchy" process from a button on the root cert.

 Instructions: 

 *******************************************************************************************************
 Revision History:
 
     10/26/2019 - Created new 

 ******************************************************************************************************/
@isTest
public with sharing class RunALVonHierarchyControllerTest {
    
    static testmethod void TestRunALV(){
        Account acc = TestUtils.getCAOwner();
        insert acc;
        
        //create a ROOT CA
        Account rootCA = TestUtils.getRootCertificate(acc.Id); 
        rootCa.X_509_Certificate_PEM__c = 'abc';
        rootCa.Status__c = 'Included';
        rootCa.Trust_Bits__c = 'Websites';
        rootCa.Subject_SPKI_SHA256__c = 'C90FBC2664485F6D3175055A45EF10D2EB6E6C7E027DF1A1D526458C42F42696';
        insert rootCa;
        
        Test.startTest(); 
        
        //create intermediate CA
        Account testAccount = TestUtils.getIntermediateCertificate(rootCa.Id);
        testAccount.X_509_Certificate_PEM__c = 'abc';
        testAccount.Subject_SPKI_SHA256__c = 'C90FBC2664485F6D3175055A45EF10D2EB6E6C7E027DF1A1D526458C42F42696';
        testAccount.Extended_Key_Usage__c = 'ExtKeyUsageEmailProtection,ExtKeyUsageClientAuth';
        testaccount.Audits_Same_as_Parent__c = true;
        insert testAccount;
        
        RunALVonHierarchyController controller = new RunALVonHierarchyController(new Apexpages.standardcontroller(rootCa));
        controller.RunALVForChildAccounts();
        
        Test.stopTest();
    }
}
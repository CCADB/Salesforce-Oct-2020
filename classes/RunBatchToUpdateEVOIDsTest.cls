/*******************************************************************************************************
 Name: RunBatchToUpdateEVOIDsTest

 Dependencies: RunBatchToUpdateEVOIDs controller class, RunEVOIDBatchSchedulerClass class, 
 RunBatchToUpdateEVOIDsTest test class
 
 Description: This is a test class for RunBatchToUpdateEVOIDs class.
 This batch is created to make callout to EVChecker tool and update 
 “ExtendedValidation.cpp OIDs” field by matching SHA-256 Fingerprint on root certificates.
 
 A scheduler class will run this batch job nightly and update the certs only when there is a 
 change. This process can be run from "Batch Processes" tab too.
 
 The tool (https://evchecker-dot-ccadb-231121.appspot.com) parses a Mozilla file 
 (https://hg.mozilla.org/mozilla-central/file/tip/security/certverifier/ExtendedValidation.cpp) and 
 returns the resuts in JSON:
 
 type EVInfo struct {
    DottedOID         string
    OIDName           string
    SHA256Fingerprint string
    Issuer            string
    Serial            string
 }
 
 This will enable CCADB to:
 - Identify which intermediate certs are enabled for EV, based on the Policy OIDs in their PEM
 - Have a data integrity report comparing EV OIDs known in CCADB versus ExtendedValidation.cpp.
 
 Instructions: Add Remote Site Setting: https://evchecker-dot-ccadb-231121.appspot.com
 
 *******************************************************************************************************
 Revision History:
 
     11/12/2019 - Created new class.

 ******************************************************************************************************/
@isTest
public with sharing class RunBatchToUpdateEVOIDsTest {
    static testMethod void TestEVOIDs() {
        Account caOwnerAcc = TestUtils.getCAOwner();
        insert caOwnerAcc;
        
        Account rootAccount = TestUtils.getRootCertificate(caOwnerAcc.id);
        rootAccount.Name = 'child root account 1';
        rootAccount.SHA_256_Fingerprint__c = '960ADF0063E96356750C2965DD0A0867DA0B9CBD6E77714AEAFB2349AB393DA3';
        rootAccount.Standard_Audit__c = 'https://std.com';
        rootAccount.Standard_Audit_Type__c = 'WebTrust';
        rootAccount.Standard_Audit_Statement_Date__c = system.today();
        rootAccount.Standard_Audit_Period_Start_Date__c = system.today();
        rootAccount.Standard_Audit_Period_End_Date__c = system.today();
        rootAccount.Certificate_Policy_CP__c = 'https://cp.com';
        rootAccount.Certification_Practice_Statement_CPS__c = 'https://cps.com';
        insert rootAccount;
        
        RunBatchToUpdateEVOIDs batch = new RunBatchToUpdateEVOIDs();
        database.executebatch(batch);
        
        RunEVOIDBatchSchedulerClass.scheduleMe('Run Batch To Populate EV OIDs' + System.now());
    }
}
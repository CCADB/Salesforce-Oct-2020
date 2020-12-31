/*******************************************************************************************************
 Name: RunBatchToUpdateDoppelgangerTest test class

 Dependencies:  RunBatchToUpdateDoppelganger controller class, RunDoppelgangerBatchSchedulerClass,
 RunBatchProcessesController, RunBatchToUpdateConstrainedDoppelganger, RunBatchToUpdateDoppelgangerTest,
 AccountMessageInlineController, AccountMessageInlinePage, 
 CommonMethods, CommonMethodsTest,
 RunBatchProcesses, RunBatchProcessesController

 Description: Test class for RunBatchToUpdateDoppelganger and RunDoppelgangerBatchSchedulerClass.
 
    Batch program was created to update 'Non-constrained Doppelganger?' flag.

    The program processes All Intermeidate Cert where 
        Subject_SPKI_SHA256 != null and
        Technically_Constrained = TRUE and
        Valid_To_GMT > TODAY and
        Revocation_Status = Not Revoked
        
    For each Intermediate cert we are checking if there is a doppelganger intermediate certs (match on Subject_SPKI_SHA256)
    then the flag is checked.
    
    AccountInline vf page displays the message to indicate existance of non constrained Doppelganger cert if the
    'Non-constrained Doppelganger?' flag is checked.
 
 Instructions: To schedule this batch use the following command from Dev Console:
  
    RunDoppelgangerBatchSchedulerClass.scheduleMe('Run Non Constrained Doppelganger Batch');
    
    Also, 'Batch Processes' tab allows user to run this process anytime from a button.

 *******************************************************************************************************
 Revision History:
 
     9/6/2019 - Created new

     
 ******************************************************************************************************/
@isTest
public with sharing class RunBatchToUpdateDoppelgangerTest {
    static testMethod void TestDoppelgangerUpdate() {
        Account caOwnerAcc = TestUtils.getCAOwner();
        insert caOwnerAcc;
        
        Account rootAccount = TestUtils.getRootCertificate(caOwnerAcc.id);
        rootAccount.Name = 'child root account 1';
        rootAccount.Standard_Audit__c = 'https://std.com';
        rootAccount.Standard_Audit_Type__c = 'WebTrust';
        rootAccount.Standard_Audit_Statement_Date__c = system.today();
        rootAccount.Standard_Audit_Period_Start_Date__c = system.today();
        rootAccount.Standard_Audit_Period_End_Date__c = system.today();
        rootAccount.Certificate_Policy_CP__c = 'https://cp.com';
        rootAccount.Certification_Practice_Statement_CPS__c = 'https://cps.com';
        insert rootAccount;
        
        Account interCertAccount1 = TestUtils.getIntermediateCertificate(rootAccount.id);
        interCertAccount1.Name = 'child Intercert account 1';
        interCertAccount1.Technically_Constrained__c = true;
        interCertAccount1.Valid_To_GMT__c = System.today().addYears(1);
        interCertAccount1.Subject_SPKI_SHA256__c = 'C90FBC2664485F6D3175055A45EF10D2EB6E6C7E027DF1A1D526458C42F42696';
        interCertAccount1.Revocation_Status__c = 'Not Revoked';
        insert interCertAccount1;
        
        Account interCertAccount2 = TestUtils.getIntermediateCertificate(rootAccount.id);
        interCertAccount2.Name = 'child Intercert account 1';
        interCertAccount2.SHA_1_Fingerprint__c = '1234567890123456789012345678901234XXX890';
        interCertAccount2.Technically_Constrained__c = false;
        interCertAccount2.Valid_To_GMT__c = System.today().addYears(1);
        interCertAccount2.Subject_SPKI_SHA256__c = 'C90FBC2664485F6D3175055A45EF10D2EB6E6C7E027DF1A1D526458C42F42696';
        interCertAccount2.Revocation_Status__c = 'Not Revoked';
        insert interCertAccount2;
        
        //Schedular class
        RunDoppelgangerBatchSchedulerClass.scheduleMe('Run Non Constrained Doppelganger Batch '+ System.now());
        
        RunBatchToUpdateDoppelganger batch = new RunBatchToUpdateDoppelganger('');
        Database.Executebatch(batch, 10);
        
        
    }
}
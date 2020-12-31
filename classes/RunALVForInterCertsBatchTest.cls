/*
    Test class for RunALVForInterCertsBatch
*/
@isTest
public with sharing class RunALVForInterCertsBatchTest {
    static testmethod void testALVInterCertbatch(){
        
        Account objnewAcc = TestUtils.getCAOwner();
        insert objnewacc;
        
        Account rootAccount = TestUtils.getRootCertificate(objnewacc.id);
        rootAccount.Status__c = 'Included';
        rootAccount.ParentId = objnewacc.Id;
        insert rootAccount;
        
        Account accountSO = TestUtils.getIntermediateCertificate(rootAccount.Id);
        accountSO.Extended_Key_Usage__c = 'ExtKeyUsageEmailProtection,ExtKeyUsageClientAuth';
        accountSO.ParentId = rootAccount.Id;
        accountSO.Subordinate_CA_Owner__c = 'Test';
        accountSO.Valid_To_GMT__c = system.today().addDays(10);
        accountSO.Subject_SPKI_SHA256__c = 'C90FBC2664485F6D3175055A45EF10D2EB6E6C7E027DF1A1D526458C42F42696';
        accountSO.Standard_Audit__c = 'https://cert.webtrust.org/SealFile?seal=1987&file=pdf';
        accountSO.Standard_Audit_Type__c = 'WebTrust';
        accountSO.Standard_Audit_Period_End_Date__c = system.today().addDays(10);
        accountSO.Standard_Audit_Period_Start_Date__c = system.today().addDays(-10);
        accountSO.Standard_Audit_Statement_Date__c = system.today().addDays(10);
        insert accountSO;
        
        RunALVForInterCertsBatch ALVBatch = new RunALVForInterCertsBatch('');
        Database.Executebatch(ALVBatch, 1);
        
        //schduled job
        RunALVForInterCertsBatchSchedulerClass.scheduleMe('Test Run ALV Batch for Intermediate Cert');
    }
    
    static testmethod void testALVInterCertbatch1(){
        
        Account objnewAcc = TestUtils.getCAOwner();
        insert objnewacc;
        
        Account rootAccount = TestUtils.getRootCertificate(objnewacc.id);
        rootAccount.Status__c = 'Included';
        rootAccount.ParentId = objnewacc.Id;
        insert rootAccount; 
        
        Account accountSO = TestUtils.getIntermediateCertificate(rootAccount.Id);
        accountSo.SHA_1_Fingerprint__c = '1234568520123456789012345678901234567890';
        accountSO.Extended_Key_Usage__c = 'ExtKeyUsageEmailProtection,ExtKeyUsageClientAuth';
        accountSO.ParentId = rootAccount.Id;
        accountSO.Subordinate_CA_Owner__c = 'Test';
        accountSO.Valid_To_GMT__c = system.today().addDays(10);
        accountSO.Subject_SPKI_SHA256__c = 'C90FBC2664485F6D3175055A45EF10D2EB6E6C7E027DF1A1D526458C42F42696';
        accountSO.EV_Audit__c = 'https://cert.webtrust.org/SealFile?seal=1987&file=pdf';
        accountSO.EV_Audit_Type__c = 'WebTrust';
        accountSO.EV_Audit_Period_End_Date__c = system.today().addDays(10);
        accountSO.EV_Audit_Period_Start_Date__c = system.today().addDays(-10);
        accountSO.EV_Audit_Statement_Date__c = system.today().addDays(10);
        accountSO.Date_ALV_Processed__c = system.today().addDays(-10);
        insert accountSO; 
        
        RunALVForInterCertsBatch ALVBatch = new RunALVForInterCertsBatch('');
        Database.Executebatch(ALVBatch, 1);
    }
    
    static testmethod void testALVInterCertbatch2(){
        
        Account objnewAcc = TestUtils.getCAOwner();
        insert objnewacc;
        
        Account rootAccount = TestUtils.getRootCertificate(objnewacc.id);
        rootAccount.Status__c = 'Included';
        rootAccount.ParentId = objnewacc.Id;
        rootAccount.Subordinate_CA_Owner__c = 'Test';
        rootAccount.Valid_To_GMT__c = system.today().addDays(10);
        rootAccount.Subject_SPKI_SHA256__c = 'C90FBC2664485F6D3175055A45EF10D2EB6E6C7E027DF1A1D526458C42F42696';
        rootAccount.EV_Audit__c = 'https://cert.webtrust.org/SealFile?seal=1987&file=pdf';
        rootAccount.EV_Audit_Type__c = 'WebTrust';
        rootAccount.EV_Audit_Period_End_Date__c = system.today().addDays(10);
        rootAccount.EV_Audit_Period_Start_Date__c = system.today().addDays(-10);
        rootAccount.EV_Audit_Statement_Date__c = system.today().addDays(10);
        insert rootAccount; 
        
        Account interCertAccount1 = TestUtils.getIntermediateCertificate(rootAccount.id);
        interCertAccount1.Extended_Key_Usage__c = 'ExtKeyUsageEmailProtection,ExtKeyUsageClientAuth';
        interCertAccount1.Name = 'child Intercert account 1';
        interCertAccount1.Audits_Same_as_Parent__c = true;
        interCertAccount1.CP_CPS_Same_as_Parent__c = true;
        interCertAccount1.CA_Owner__c = 'Test';
        interCertAccount1.Date_ALV_Processed__c = system.today().addDays(-20);
        insert interCertAccount1;
        
        RunALVForInterCertsBatch ALVBatch = new RunALVForInterCertsBatch('');
        Database.Executebatch(ALVBatch, 1);
    }
}
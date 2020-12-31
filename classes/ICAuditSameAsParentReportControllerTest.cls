/*
    Description: Test class for ICAuditSameAsParentReportController
*/
@isTest
public with sharing class ICAuditSameAsParentReportControllerTest {
    static testMethod void TestICAuditSameAsParentReport() {
        Account caOwnerAcc = TestUtils.getCAOwner();
        insert caOwnerAcc;
        
        Account rootAccount = TestUtils.getRootCertificate(caOwnerAcc.id);
        rootAccount.Name = 'child root';
        rootAccount.Standard_Audit__c = 'https://std.com';
        rootAccount.Standard_Audit_Type__c = 'WebTrust';
        rootAccount.Standard_Audit_Statement_Date__c = system.today();
        rootAccount.Standard_Audit_Period_Start_Date__c = system.today();
        rootAccount.Standard_Audit_Period_End_Date__c = system.today();
        rootAccount.Certificate_Policy_CP__c = 'https://cp.com';
        rootAccount.Certification_Practice_Statement_CPS__c = 'https://cps.com';
        rootAccount.Status__c = 'Included';
        insert rootAccount;
        
        Account interCertAccount1 = TestUtils.getIntermediateCertificate(rootAccount.id);
        interCertAccount1.Name = 'child Intercert 1';
        interCertAccount1.Audits_Same_as_Parent__c = true;
        interCertAccount1.CP_CPS_Same_as_Parent__c = true;
        interCertAccount1.Valid_To_GMT__c = system.today().addDays(10);
        interCertAccount1.Revocation_Status__c  = 'Not Revoked';
        interCertAccount1.Root_Cert_Id__c = rootAccount.Id;
        insert interCertAccount1;
        
        Account interCertAccount2 = TestUtils.getIntermediateCertificate(interCertAccount1.id);
        interCertAccount2.Name = 'child Intercert 2';
        interCertAccount2.Standard_Audit__c = 'https://std.com';
        interCertAccount2.Standard_Audit_Type__c = 'WebTrust';
        interCertAccount2.Standard_Audit_Statement_Date__c = system.today();
        interCertAccount2.Standard_Audit_Period_Start_Date__c = system.today();
        interCertAccount2.Standard_Audit_Period_End_Date__c = system.today();
        interCertAccount2.Valid_To_GMT__c = system.today().addDays(10);
        interCertAccount2.Revocation_Status__c  = 'Not Revoked';
        interCertAccount2.Root_Cert_Id__c = rootAccount.Id;
        insert interCertAccount2;
        
        ICAuditSameAsParentReportController controller = new ICAuditSameAsParentReportController();
        
        interCertAccount2.Certificate_Policy_CP__c = 'https://cp.com';
        update interCertAccount2;
        
        controller = new ICAuditSameAsParentReportController();
        
        Account interCertAccount3 = TestUtils.getIntermediateCertificate(interCertAccount2.id);
        interCertAccount3.Name = 'child Intercert 3';
        interCertAccount3.Valid_To_GMT__c = system.today().addDays(10);
        interCertAccount3.Revocation_Status__c = 'Not Revoked';
        interCertAccount3.Root_Cert_Id__c = rootAccount.Id;
        insert interCertAccount3;
        
        controller = new ICAuditSameAsParentReportController();
        
        interCertAccount3.Standard_Audit__c = 'https://std.com';
        interCertAccount3.Standard_Audit_Type__c = 'WebTrust';
        interCertAccount3.Standard_Audit_Statement_Date__c = system.today();
        interCertAccount3.Standard_Audit_Period_Start_Date__c = system.today();
        interCertAccount3.Standard_Audit_Period_End_Date__c = system.today();
        interCertAccount3.Certificate_Policy_CP__c = 'https://cp.com';
        update interCertAccount3;
        
        controller = new ICAuditSameAsParentReportController();
    }
}
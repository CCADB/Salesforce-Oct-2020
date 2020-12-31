/*******************************************************************************************************
 Name: OneCRLCertStorageReportControllerTest 

 Dependencies: OneCRLCertStorageReportController controller class, OneCRLCertStorageReport vf page, 
 OneCRLCertStorageReportControllerTest test class

 Description: This is a test class for OneCRLCertStorageReportController controller class 

******************************************************************************************************
 Revision History:
 
     12/4/2019 - Created new class
     
 ******************************************************************************************************/
@isTest
public with sharing class OneCRLCertStorageReportControllerTest {
    static testmethod void TestOneCRLCertStorageData() {
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
        interCertAccount1.Audits_Same_as_Parent__c = false;
        interCertAccount1.CP_CPS_Same_as_Parent__c = false;
        interCertAccount1.SHA_256_Fingerprint__c = 'C61E8AE4B701345DD0C06495BA0BE106757955D85D76C734ADAD116710AAB0C2';
        interCertAccount1.Certificate_Issuer_Common_Name__c = 'Test';
        insert interCertAccount1;
        
        OneCRLCertStorageReportController controller = new OneCRLCertStorageReportController();
        
        OneCRLCertStorageReportController.wrapperOneCRL wrap = new OneCRLCertStorageReportController.wrapperOneCRL ();
        wrap.serial = '5AE4653E507975C3C793E362DA6F7CB9';
        wrap.sha_256 = 'C61E8AE4B701345DD0C06495BA0BE106757955D85D76C734ADAD116710AAB0C2';
        wrap.issuer = 'CN=cPanel';
        wrap.issuercommonname = 'Trust Italia S.p.A';
        OneCRLCertStorageReportController.wrapperOneCRL comparewrap = new OneCRLCertStorageReportController.wrapperOneCRL ();
        integer i = comparewrap.compareTo(wrap);
    }
}
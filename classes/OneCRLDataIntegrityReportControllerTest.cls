/*******************************************************************************************************
  THIS REPORT IS OBSOLETED - IT HAS BEEN REPLACED BY OneCRLCertStorageReport "OneCRL Cert Storage Report"
  *******************************************************************************************************
  
 Name: OneCRLDataIntegrityReportControllerTest

 Dependencies: OneCRLDataIntegrityReport controller class, OneCRLDataIntegrityReport vf page, 
 OneCRLDataIntegrityReportControllerTest test class

 Description: This is a test class for controller class which generates a user 
 friendly report for Salesforce users. 
 The program generates a user friendly report for Salesforce users to show
 discrepancies between CCADB public report (PublicIntermediateCertsRevokedWithPEMCSV) and 
 the OneCRL Raw Data file (https://firefox.settings.services.mozilla.com/v1/buckets/blocklists/collections/certificates/records) 
 using a tool https://onecrldiff-dot-ccadb-231121.appspot.com/
 
 The tool output has JOSN format:
 type Cert struct {
    serial           string // Decimal representation
    revocationStatus string // "OneCRL Status" from the CCADB report
    issuerCN         string // Issuer Common Name
    issuerON         string // Issuer Organization Name
    fingerprint      string // "SHA-256 Fingerprint" from the CCADB report
 }
 
 Tool produces 9 different errors categories:

    "Added to OneCRL" and in OneCRL
    "Cert Expired" and in OneCRL
    "Ready to Add" and in OneCRL 
    Not in CCADB but in OneCRL 
    "Added to OneCRL" but not in OneCRL 
    "Cert Expired" and not in OneCRL
    "Ready to Add" and not in OneCRL 
    No "OneCRL Status" given in the CCADB report - Revocation Status of "Parent Cert Revoked" 
    No "OneCRL Status" given in the CCADB report - Revocation Status of "Not Revoked" or blank
    

 Instructions: Remote site setting for the tool should be active in the Salesforce org
 *******************************************************************************************************
 Revision History:
 
     6/28/2019 - Created new class
 ******************************************************************************************************/
@isTest
public with sharing class OneCRLDataIntegrityReportControllerTest {
    static testmethod void TestOneCRLData() {
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
        insert interCertAccount1;
        
        OneCRLDataIntegrityReportController controller = new OneCRLDataIntegrityReportController();
        
        OneCRLDataIntegrityReportController.wrapperOneCRL wrap = new OneCRLDataIntegrityReportController.wrapperOneCRL ();
        wrap.serial = '5AE4653E507975C3C793E362DA6F7CB9';
        wrap.revocationStatus = '';
        wrap.issuerCN = 'Trust Italia Class 2 CA - G3';
        wrap.issuerON = 'Trust Italia S.p.A';
    }
}
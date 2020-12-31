/*******************************************************************************************************
 Name: VerifyRevocationControllerTest

 Dependencies: VerifyRevocationController class, VerifyRevocationControllerTest class,
 VerifyRevocation VF page

 Description: This is a test class is created for VerifyRevocationController
 This controller class was created to verify revoked intermediate certs.
 This functionility is invoked from a button "Verify Revocation" on intermediate certs page.
 
 Revocation Status = Revoked and 
 Date of Revocation not blank and 
 Revocation Reason not blank
 CRL URL(s) or Alternate CRL not blank
 
 When above conditions are met call the tool 'https://crlverification-dot-ccadb-231121.appspot.com/'.
 If the crlverification result is ‘PASS’ and ‘OneCRL Status’ is blank, then ‘OneCRL Status’ is 
 updated to “Ready to Add”.
 Whenever crlverification result is FAIL, “Revocation Verification” to say “FAILED” and 
 update the errors that crlVerification provides regarding why it failed. 

 Instructions: To test the tool use curl -d '{"crl": "http://crl.pkioverheid.nl/DomOrganisatiePersoonLatestCRL-G3.crl","serial": "329CAB52A80A2E3F","revocationDate": "2019/06/27", "revocationReason": "(4) superseded"}' https://crlverification-dot-ccadb-231121.appspot.com/ 

 *******************************************************************************************************
 Revision History:
 
     10/26/2019 - Created new class
               
 ******************************************************************************************************/
@isTest
public with sharing class VerifyRevocationControllerTest {
    
    static testmethod void TestVerifyRevocation() {
        Account caOwnerAcc = TestUtils.getCAOwner();
        insert caOwnerAcc;
        
        //create root certs
        Account rootAccount = TestUtils.getRootCertificate(caOwnerAcc.id);
        rootAccount.Name = 'child root account 1';
        rootAccount.Standard_Audit_Period_End_Date__c = system.today().addDays(-6);
        insert rootAccount;
        
        //create intermediate certs
        Account intermediatecert = TestUtils.getIntermediateCertificate(rootAccount.Id);
        intermediatecert.Name = 'Test Intermediate Cert 1';
        intermediatecert.Revocation_Status__c = 'Not Revoked';
        insert intermediatecert;
        
        PageReference VfPage = Page.VerifyRevocation;
        Test.setCurrentPage(VfPage);

        VerifyRevocationController controller = new VerifyRevocationController(new Apexpages.standardcontroller(intermediatecert));
        controller.CallAPIToVerifyRevocation();
        
        Test.startTest();
        
        intermediatecert.Revocation_Status__c = 'Revoked';
        intermediatecert.CRL_URL_s__c = 'http://crl.camerfirma.com/chambersroot-2008.crl';
        update intermediatecert;
        controller = new VerifyRevocationController(new Apexpages.standardcontroller(intermediatecert));
        controller.CallAPIToVerifyRevocation();
                
        intermediatecert.RFC_5280_Revocation_Reason_Code__c = '(4) superseded';
        update intermediatecert;
        controller = new VerifyRevocationController(new Apexpages.standardcontroller(intermediatecert));
        controller.CallAPIToVerifyRevocation();
        
        intermediatecert.Date_of_Revocation__c = system.today();
        update intermediatecert;
        controller = new VerifyRevocationController(new Apexpages.standardcontroller(intermediatecert));
        controller.CallAPIToVerifyRevocation();
        
        intermediatecert.Revocation_Status__c = 'Revoked';
        intermediatecert.Date_of_Revocation__c = system.today().addYears(-1);
        intermediatecert.CRL_URL_s__c = '';
        intermediatecert.Alternate_CRL__c = 'http://crl.camerfirma.com/chambersroot-2008.crl';
        intermediatecert.RFC_5280_Revocation_Reason_Code__c = '(4) superseded';
        update intermediatecert;        
        controller = new VerifyRevocationController(new Apexpages.standardcontroller(intermediatecert));
        controller.CallAPIToVerifyRevocation();
        
        // intermediatecert.CRL_URL_s__c = 'https://ccadb.org';
        intermediatecert.CRL_URL_s__c = 'http://sbca.telesec.de/sbca/download/download.crl?path=CN%3DDeutsche%20Telekom%20Root%20CA%202%2COU%3DT-TeleSec%20Trust%20Center%2CO%3DDeutsche%20Telekom%20AG%2CC%3DDE%3FAuthorityRevocationList, ldap://ldap.sbca.telesec.de/CN=Deutsche%20Telekom%20Root%20CA%202,OU=T-TeleSec%20Trust%20Center,O=Deutsche%20Telekom%20AG,C=DE?AuthorityRevocationList';
        update intermediatecert;
        controller = new VerifyRevocationController(new Apexpages.standardcontroller(intermediatecert));
        controller.CallAPIToVerifyRevocation();
        
        intermediatecert.CRL_URL_s__c = '';
        intermediatecert.Alternate_CRL__c = 'http://corporate-pki1.telekom.de/cdp/Deutsche%20Telekom%20Root%20CA%202.crl, ldap://ldap-cpki1.telekom.de/cn=Deutsche%20Telekom%20Root%20CA%202,ou=T-TeleSec%20Trust%20Center,o=Deutsche%20Telekom%20AG,C=DE?authorityRevocationList';
        intermediatecert.RFC_5280_Revocation_Reason_Code__c = null;
        update intermediatecert;
        controller = new VerifyRevocationController(new Apexpages.standardcontroller(intermediatecert));
        controller.CallAPIToVerifyRevocation();
        
        intermediatecert.CRL_URL_s__c = '';
        intermediatecert.Alternate_CRL__c = '';
        update intermediatecert;
        controller = new VerifyRevocationController(new Apexpages.standardcontroller(intermediatecert));
        controller.CallAPIToVerifyRevocation();
        
        Test.stopTest();
        
        intermediatecert.Revocation_Verification__c = null;
        intermediatecert.CRL_URL_s__c = 'http://crl.camerfirma.com/chambersroot-2008.crl';
        update intermediatecert;
        RunBatchToVerifyRevocation batch = new RunBatchToVerifyRevocation('');
        database.executeBatch(batch, 1);
        
        RunVerifyRevocationSchedulerClass.scheduleMe('Run Batch Verify Revocation '+ system.now());
    }
}
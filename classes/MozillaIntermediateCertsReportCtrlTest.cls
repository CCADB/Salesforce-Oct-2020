/*******************************************************************************************************
 Name: MozillaIntermediateCertsReportCtrlTest

 Dependencies:  MozillaIntermediateCertsReportController controller class,  MozillaIntermediateCertsReportCtrlTest, 
 MozillaIntermediateCertsCSVReport vf page

 Description: This report lists non revoked intermediate certs and Derived Trust Bits contains 'Server Authentication'.
 Firefox directly uses this report to create the intermediate certificate bulk load list.

 
 Instructions:  None

 *******************************************************************************************************
 Revision History:
 
     1/15/2019 - Created new

 ******************************************************************************************************/
 
@isTest
public with sharing class MozillaIntermediateCertsReportCtrlTest {
    static testMethod void validateTest() {
        
        Account acc = TestUtils.getCAOwner();
        insert acc;
        
        Account rootacc = TestUtils.getRootCertificate(acc.Id);
        rootacc.Status__c = 'Included';
        rootacc.Trust_Bits__c = 'Websites';
        insert rootacc;
        
        Account intermediateacc = TestUtils.getIntermediateCertificate(rootacc.Id);
        intermediateacc.Revocation_Status__c = 'Not Revoked';
        intermediateacc.Valid_To_GMT__c = system.today().addDays(10);
        intermediateacc.Root_Cert_Id__c = rootacc.Id;
        intermediateacc.Subject__c = 'SSSSS';
        intermediateacc.Issuer__c = 'IIIIIII';
        intermediateacc.SHA_256_Fingerprint__c = 'AAAAAAAA';
        insert intermediateacc;
        
        MozillaIntermediateCertsReportController objReport = new MozillaIntermediateCertsReportController();
        
    }
}
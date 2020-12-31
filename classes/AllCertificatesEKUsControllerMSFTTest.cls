/*******************************************************************************************************
 Name: AllCertificatesEKUsControllerMSFTTest

 Dependencies: AllCertificatesEKUsControllerMSFT, AllCertificatesEKUsMSFTCSV VF page, 
 AllCertificatesEKUsControllerMSFTTest class

 Description: Test class for AllCertificatesEKUsController
 The report lists all root and inter certs included in Microsoft pgm. Each root cert row is 
 folloowed by it's intermediate. Root Cert record shows Microsoft EKUs and Intermediate cert record shows
 Extended Key Usage data from their respective records.
 
 Instructions:    
 *******************************************************************************************************
 Revision History:
 
       4/12/2019 - Created new
 ******************************************************************************************************/
@isTest
public with sharing class AllCertificatesEKUsControllerMSFTTest {

    static testMethod void validateTest() {
        //create the parent account  - record type = Owner
        Account parentAccount = TestUtils.getCAOwner();
        insert parentAccount;
        
        // create the child account - record type = Root
        Account rootAccount = TestUtils.getRootCertificate(parentAccount.id);
        rootAccount.CA_Owner__c = parentAccount.Name;
        rootAccount.Microsoft_EKU__c = 'Test ABC';
        rootAccount.Extended_Key_Usage__c = 'Extended Key Usage';
        rootAccount.Microsoft_Status__c = 'Included';
        insert rootAccount;
        
        // create the child account - record type = Intermediate
        Account interAccount = TestUtils.getIntermediateCertificate(rootAccount.id);
        interAccount.CA_Owner__c = parentAccount.Name;
        interAccount.Root_Cert_Id__c = rootAccount.Id;
        interAccount.Microsoft_EKU__c = 'Test ABC';
        interAccount.Extended_Key_Usage__c = 'Extended Key Usage';
        insert interAccount;
        
        PageReference pref = Page.AllCertificatesEKUsMSFTCSV;
        Test.setCurrentPage(pref);
        
        AllCertificatesEKUsControllerMSFT controller = new AllCertificatesEKUsControllerMSFT();
        
    }
}
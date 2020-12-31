/*******************************************************************************************************
 Name: ICDerivedTrustBitsListControllerTest

 Dependencies: ICDerivedTrustBitsListController controller class, ICDerivedTrustBitsList vf page, 
 ICDerivedTrustBitsListControllerTest test class

 Description: Displays all Intermediate Certs with Dervied Trust Bits. It was created for data verification
 purpose. The main logic for Derived Trust Bits is in UpdateDerivedTrustBits & GetDerivedTrustBits method in
 AccountTriggerHelper.
 
 Instructions: None
 *******************************************************************************************************
 Revision History:
 
     09/21/2020 - Created new class
     
 ******************************************************************************************************/ 

@isTest
public with sharing class ICDerivedTrustBitsListControllerTest {
    static testmethod void TestICDerivedTrustBits() {
        Account CAOwner = TestUtils.getCAOwner();
        insert CAOwner;
        
        Account rootAccount = TestUtils.getRootCertificate(CAOwner.Id);
        insert rootAccount;
        
        Account interCert = TestUtils.getIntermediateCertificate(rootAccount.Id);
        interCert.Valid_To_GMT__c = System.Today().addMonths(2);
        interCert.Mozilla_Root_Status__c = 'Included';
        insert interCert;
        
        ICDerivedTrustBitsListController controller = new ICDerivedTrustBitsListController();
        controller.getCurrentDate();
    }
}
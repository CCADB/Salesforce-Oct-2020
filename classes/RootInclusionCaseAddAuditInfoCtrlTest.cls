/*
    Description: Test class for RootInclusionCaseAddAuditInfoController
*/
/*******************************************************************************************************
 Name: RootInclusionCaseAddAuditInfoCtrlTest

 Dependencies: RootInclusionCaseAddAuditInfoController controller class, RootInclusionCaseAddAuditInfo 
 vf page, RootInclusionCaseAddAuditInfoCtrlTest class

 Description: This is a test class for RootInclusionCaseAddAuditInfoController.
 When "Copy Audit Info" button is clicked from case page, a list of related root certs are displayed,
 users can chose a root cert and copy Auditor, Audit Info and CP/CPS to Case.
 
 Instructions: None   
 *******************************************************************************************************
 Revision History:
 
     10/15/2018    Created new class
     
 ******************************************************************************************************/
@isTest
public with sharing class RootInclusionCaseAddAuditInfoCtrlTest {
    static testmethod void TestAddAuditInfo(){  
        //create the parent account  - record type = Owner
        Account parentAccount = TestUtils.getCAOwner();
        insert parentAccount;
        
        // create the contact associated with the parent account
        Contact parentContact = TestUtils.getContact(parentAccount.id);
        insert parentContact;
        
        // create the child account - record type = Root
        Account childAccount = TestUtils.getRootCertificate(parentAccount.id);
        insert childAccount;
        
        // create a case
        Case accountCaseA = TestUtils.getCase(parentAccount.id);
        accountCaseA.request_status__c  = 'Initial Request Received';         
        insert accountCaseA;
        
        RootInclusionCaseAddAuditInfoController objcontroller = new RootInclusionCaseAddAuditInfoController(new Apexpages.standardcontroller(accountCaseA));
        objcontroller.SelectDifferentRootCerts();
        objcontroller.lstWrapAllRootCerts[0].isSelected = true;
        objcontroller.ViewAuditDetails();
        
        
        objcontroller.syncAuditorNewFields();
        objcontroller.syncStandardAuditFields();
        objcontroller.syncCodeSigningAuditFields();
        Test.startTest();
        objcontroller.syncBRAuditFields();
        objcontroller.syncEVSSLAuditFields();
        objcontroller.syncEVCodeSigningAuditFields();
        objcontroller.syncCPCPSAuditFields();
        Test.stopTest();
    }
}
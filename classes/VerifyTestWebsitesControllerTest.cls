/*******************************************************************************************************
 Name: VerifyTestWebsitesControllerTest

 Dependencies: VerifyTestWebsitesController, VerifyTestWebsites vf page, VerifyTestWebsitesControllerTest,
 RootCaseTriggerHelper

 Description: This controller class is a test class for VerifyTestWebsitesController.
 VerifyTestWebsitesController apex class validates test websites (valid/expired/revoked)
 by sending HTTP request to https://ccadb-231121.appspot.com/fromCertificateDetails. The response 
 is saved on Root Cases object (Test Websites Status and Results fields).
 
 When Test Website fields are updated on root case, RootCaseTrigger launches a future callout 
 to validate the urls. Valid PEM info is required in the request body for the webservice to 
 process the request. The results are parsed and results and overall status of PASS/FAIL is 
 saved on root case record. Root Inclusion cases with status 'Request Withdrawn by CA' and 
 'Denied' are not sent for validation. "Test Website validation" buttton provides a way to view
 the root case no, root cert, status, reuslts. From this page validation process can be re-run.
 
 Instructions: Remote site setting must have https://ccadb-231121.appspot.com  
               HHTP timeout is 2 mins
 *******************************************************************************************************
 Revision History:
 
     4/25/2019 - Created new class
     11/20/2019 - Updated test class for Lint test
 ******************************************************************************************************/
@isTest
private class VerifyTestWebsitesControllerTest {
    static testmethod void testValidateTestWebsites(){
         //create the parent account  - record type = Owner
        Account parentAccount = TestUtils.getCAOwner();
        insert parentAccount;
        
        // create the child account - record type = Root
        Account childAccount = TestUtils.getRootCertificate(parentAccount.id);
        insert childAccount;
        
        // create a case
        Case accountCaseA = TestUtils.getCase(parentAccount.id);
        accountCaseA.request_status__c  = 'Initial Request Received';         
        insert accountCaseA;
        
        accountCaseA.Request_Status__c = 'Data Verified';
        update accountCaseA;
        
        // create the root case and associate it with the case
        Root_Case__c rootCaseA1 = TestUtils.getRootCase(accountCaseA.id, parentAccount.Id);
        rootCaseA1.request_status__c   = 'Initial Request Received';         
        rootCaseA1.Apply_Standard_Audit__c = true;
        rootCaseA1.Apply_BR_Audit__c = true;
        rootCaseA1.Apply_EV_Audit__c = true;         
        rootCaseA1.Case_No__c = accountCaseA.Id;
        rootCaseA1.CA_Owner_Name_Existing__c = parentAccount.Id;
        rootCaseA1.Root_Certificate_Name_Existing__c = childAccount.Id;
        rootCaseA1.RecordTypeId = Schema.SObjectType.Root_Case__c.getRecordTypeInfosByName().get('CA Audit Update Request').getRecordTypeID();
        rootCaseA1.Test_Website_Valid__c = 'https://testvalid.com';
        rootCaseA1.Test_Website_Revoked__c = 'https://testrevoked.com';
        rootCaseA1.Test_Website_Expired__c = 'https://testexpired.com';
        rootCaseA1.X_509_Certificate_PEM__c = TestUtils.strPEMInfo;
        insert rootCaseA1;
        
        Test.startTest();
        
        Apexpages.currentpage().getParameters().put('id',accountCaseA.Id);
        VerifyTestWebsitesController controller = new VerifyTestWebsitesController();
        controller.ReValidateTestWebsites();
        controller.Cancel();
        Test.stopTest();
    }
}
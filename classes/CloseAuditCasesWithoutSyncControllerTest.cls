/*
    Description: Test class for CloseAuditCasesWithoutSyncController
*/
@isTest
public with sharing class CloseAuditCasesWithoutSyncControllerTest {
    
    static testmethod void TestCloseCase(){
        // create the parent account  - record type = Owner
        Account parentAccount = TestUtils.getCAOwner();
        parentAccount.Name = 'parent root account 1';
        parentAccount.Recognized_CAA_Domains__c = 'Test 1';
        parentAccount.Problem_Reporting_Mechanism__c = 'Test 2';
        insert parentAccount;
        
        // create the child account - record type = Root
        Account childAccount = TestUtils.getRootCertificate(parentAccount.id);
        childAccount.Name = 'child root account 1';
        insert childAccount;
        
        // create the contact associated with the parent account
        Contact parentContact = TestUtils.getContact(parentAccount.id);
        parentContact.firstName = 'parent_firstname';
        parentContact.lastName = 'parent_lastname';
        insert parentContact;
        
        // create auditor
        Auditor__c auditor = new Auditor__c();
        auditor.Name = 'WebTrust';
        auditor.Auditor_Status__c = 'Confidence - High';
        auditor.Auditor_Website__c = 'http://www.google.com';
        insert auditor;
        
        // create auditor location
        Auditor_Location__c auditorlocation = new Auditor_Location__c();
        auditorlocation.Name = 'US';
        auditorlocation.Auditor__c = auditor.Id;
        auditorlocation.Auditor_Location_Status__c = 'Confidence - High';
        insert auditorlocation;
        
        // create a case
        Case accountCaseA = TestUtils.getCase(parentAccount.id);
        accountCaseA.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('CA Audit Update Request').getRecordTypeId();
        accountCaseA.request_status__c  = 'Initial Request Received'; 
        accountCaseA.Recognized_CAA_Domains__c = 'Test 3';
        accountCaseA.Problem_Reporting_Mechanism__c = 'Test 4'; 
        accountCaseA.Auditor_New__c = auditor.Id;
        accountCaseA.Auditor_Location_New__c = auditorlocation.Id; 
        // accountCaseA.Request_Status__c = 'Complete';     
        insert accountCaseA;
        
        // create the root case and associate it with the case
        Root_Case__c rootCaseA1 = TestUtils.getRootCase(accountCaseA.id, childAccount.Id);
        rootCaseA1.RecordTypeId = Schema.SObjectType.Root_Case__c.getRecordTypeInfosByName().get('CA Audit Update Request').getRecordTypeId();
        rootCaseA1.request_status__c   = 'Complete';         
        rootCaseA1.Apply_Standard_Audit__c = true;
        rootCaseA1.Apply_BR_Audit__c = true;
        rootCaseA1.Apply_EV_Audit__c = true;         
        rootCaseA1.Case_No__c = accountCaseA.Id;
        rootCaseA1.CA_Owner_Name_Existing__c = parentAccount.Id;
        rootCaseA1.Root_Certificate_Name_Existing__c = childAccount.Id;
        insert rootCaseA1;
        
        Test.startTest();
        
        CloseAuditCasesWithoutSyncController objcontroller = new CloseAuditCasesWithoutSyncController(new Apexpages.standardcontroller(accountCaseA));
        
        accountCaseA.Request_Status__c = 'Data Verified';     
        accountCaseA.Request_Status__c = 'Initial Request Received';
        accountCaseA.Status = 'Open';
        update accountCaseA;
        
        objcontroller = new CloseAuditCasesWithoutSyncController(new Apexpages.standardcontroller(accountCaseA));
        objcontroller.CloseCaseWithoutSync();
        objcontroller.ReasontoCloseCase = 'Wrongly Created Case.';
        objcontroller.CloseCaseWithoutSync();
        
        Test.stopTest();
    }
}
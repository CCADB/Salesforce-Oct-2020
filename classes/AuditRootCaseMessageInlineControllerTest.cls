/*
    Description: Test class for AuditRootCaseMessageInlineController
*/
@isTest
public with sharing class AuditRootCaseMessageInlineControllerTest {
    
    static testmethod void TestAuditRootCaseMessages(){
        //create the parent account  - record type = Owner
        Account parentAccount = SyncParentAccountFromCaseControllerTest.getParentAccount();
        parentAccount.Name = 'parent root account 1';
        insert parentAccount;
        
        // create the contact associated with the parent account
        Contact parentContact = SyncParentAccountFromCaseControllerTest.getParentContact(parentAccount.id);
        parentContact.firstName = 'parent_firstname';
        parentContact.lastName = 'parent_lastname';
        insert parentContact;
        
        // create the child account - record type = Root
        Account childAccount = SyncParentAccountFromCaseControllerTest.getChildAccount(parentAccount.id);
        childAccount.Name = 'child root account 1';
        childAccount.Standard_Audit_Period_End_Date__c = system.today().addDays(-2);
        childAccount.Code_Signing_Audit_Period_End_Date__c = system.today().addDays(-5);
        childAccount.BR_Audit_Period_End_Date__c = system.today().addDays(-3);
        childAccount.EV_Audit_Period_End_Date__c = system.today().addDays(-4);
        childAccount.EV_Code_Signing_Audit_Period_End_Date__c = system.today().addDays(-5);
        insert childAccount;
        
        // create a case
        Case accountCaseA = SyncParentAccountFromCaseControllerTest.getCase(parentAccount.id, parentContact.id);
        accountCaseA.request_status__c  = 'Initial Request Received'; 
        accountCaseA.Standard_Audit_Period_Start_Date__c = system.today().addDays(2);
        accountCaseA.Code_Signing_Audit_Period_Start_Date__c = system.today().addDays(4);
        accountCaseA.BR_Audit_Period_Start_Date__c = system.today().addDays(3);
        accountCaseA.EV_Audit_Period_Start_Date__c = system.today().addDays(4);
        accountCaseA.EV_Code_Signing_Audit_Period_Start_Date__c = system.today().addDays(5);
        insert accountCaseA;
        
        accountCaseA.Request_Status__c = 'Data Verified';
        update accountCaseA;
        
        // create the root case and associate it with the case
        Root_Case__c rootCaseA1 = SyncParentAccountFromCaseControllerTest.getRootCase(accountCaseA.id,parentAccount.Id,childAccount.Id);
        rootCaseA1.request_status__c   = 'Initial Request Received';         
        rootCaseA1.Apply_Standard_Audit__c = true;
        rootCaseA1.Apply_BR_Audit__c = true;
        rootCaseA1.Apply_EV_Audit__c = true;
        rootCaseA1.Apply_Code_Signing_Audit__c = true;         
        rootCaseA1.Case_No__c = accountCaseA.Id;
        rootCaseA1.CA_Owner_Name_Existing__c = parentAccount.Id;
        rootCaseA1.Root_Certificate_Name_Existing__c = childAccount.Id;
        rootCaseA1.RecordTypeId = Schema.SObjectType.Root_Case__c.getRecordTypeInfosByName().get('CA Audit Update Request').getRecordTypeID();
        rootCaseA1.Trust_Bits__c = 'Websites';
        rootCaseA1.Microsoft_Trust_Bits__c = 'Server Authentication';
        insert rootCaseA1;
        
        AuditRootCaseMessageInlineController auditRootCase = new AuditRootCaseMessageInlineController(new Apexpages.standardcontroller(rootCaseA1));
        
    }
    
}
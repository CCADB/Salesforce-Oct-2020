/*
* test class for PrintViewCaseController
*/
@isTest

// public with sharing class PrintViewCaseControllerTest {

public class PrintViewCaseControllerTest {
    static testmethod void testAllFieldVerified(){ 
        
        Account caOwnerAcc = TestUtils.getCAOwner();
        insert caOwnerAcc;
        
        Case caseSO = TestUtils.getCase(caOwnerAcc.Id);
        caseSO.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('CA Root Inclusion Request').getRecordTypeId();
        insert caseSO;
        
        // create the child account - record type = Root
        Account childAccount = TestUtils.getRootCertificate(caOwnerAcc.id);
        childAccount.Name = 'child root account 1';
        childAccount.Standard_Audit_Period_End_Date__c = system.today().addDays(-6);
        insert childAccount;
        
        // create the root case and associate it with the case
        Root_Case__c rootCaseA1 = TestUtils.getRootCase(caseSO.id,caOwnerAcc.Id);
        rootCaseA1.request_status__c   = 'Initial Request Received';       
        rootCaseA1.Apply_Standard_Audit__c = true;
        //rootCaseA1.EV_Audit_Type__c = 'WebTrust';
        rootCaseA1.Apply_BR_Audit__c = true;
        rootCaseA1.Apply_EV_Audit__c = true;         
        rootCaseA1.Case_No__c = caseSO.Id;
        rootCaseA1.CA_Owner_Name_Existing__c = caOwnerAcc.Id;
        rootCaseA1.Root_Certificate_Name_Existing__c = childAccount.Id;
        rootCaseA1.Application_Information_Verified__c = 'Data Verified';
        rootCaseA1.PKI_Hierarchy_Verified__c = 'Data Verified';
        rootCaseA1.Apply_Audit_Verified__c = 'Data Verified';
        rootCaseA1.Test_Website_Verified__c = 'Data Verified';
        rootCaseA1.Test_Results_Verified__c = 'Data Verified';
        rootCaseA1.Mozilla_fields_Verified__c = 'Data Verified';
        rootCaseA1.RecordTypeId = Schema.SObjectType.Root_Case__c.getRecordTypeInfosByName().get('CA Root Inclusion Request').getRecordTypeID();
        insert rootCaseA1;
        
        PrintViewCaseController objprint = new PrintViewCaseController(new apexpages.standardcontroller(caseSO));
        
    }
}
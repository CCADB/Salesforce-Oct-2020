/*
    Description: Test class for Account Hierarchy for single level
*/
@isTest
public with sharing class AccountHierarchyUptoSingleLevelTest {
    
    static testMethod void testAccountHierarchy(){
        AccountHierarchyTestData.createTestHierarchy();
        
        Account acc = new Account(Name='Test Account Name223223##');
        insert acc;
        
        AccountHierarchyUptoSingleLevel controller = new AccountHierarchyUptoSingleLevel(new apexpages.standardcontroller(acc));
        controller.BindObjectStructure();
        
        // create a ROOT CA
        Account rootCA = New Account();
        rootCA.recordTypeId= Schema.SObjectType.Account.getRecordTypeInfosByName().get('Root Certificate').getRecordTypeId(); 
        rootCa.name = 'testRoot';
        rootCa.parentId = acc.id;
        rootCa.X_509_Certificate_PEM__c = 'abc';
        insert rootCa;
        
        // create a Intermediate CA
        Account IECA = New Account();
        IECA.recordTypeId= Schema.SObjectType.Account.getRecordTypeInfosByName().get('Intermediate Certificate').getRecordTypeId(); 
        IECA.name = 'testRoot';
        IECA.parentId = rootCa.id;
        IECA.X_509_Certificate_PEM__c = 'abc';
        insert IECA;
        
        controller = new AccountHierarchyUptoSingleLevel(new apexpages.standardcontroller(rootCa));
        controller.BindObjectStructure();
    }
}
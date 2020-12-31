/*
    Test class for MigrateDataToNewRootInclusion Program
*/
@isTest
public with sharing class MigrateDataToNewRootInclusionTest {
    
    static testmethod void testMigraeDataProgram(){
        Account caOwnerAcc = TestUtils.getCAOwner();
        insert caOwnerAcc;
        
        Case caseSO = TestUtils.getCase(caOwnerAcc.Id);
        caseSO.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('CA Audit Update Request').getRecordTypeId();
        insert caseSO;
         
        Root_Case__c rootCaseA1 = TestUtils.getRootCase(caseSO.id,caOwnerAcc.Id);
        rootCaseA1.request_status__c   = 'Initial Request Received';  
        //rootCaseA1.Test_Website_URL_SSL_or_Example_Cert__c = 'http://test.com';
        insert rootCaseA1;   
        
        MigrateDataToNewRootInclusion.UpdateCasesandRootCases(new set<Id>{rootCaseA1.Id}); 
         
    }
}
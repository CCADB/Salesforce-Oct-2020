/*******************************************************************************************************
 Name: AllProblemReportingMechanismsRptCtlrTest

 Dependencies:  AllProblemReportingMechanismsReportCtlr controller class, AllProblemReportingMechanismsRptCtlrTest, 
 AllProblemReportingMechanismsReport vf pages

 Description: AllProblemReportingMechanismsReportCtlr is a controller for AllProblemReportingMechanismsReport.
 Report name used is 'All Problem Reporting Mechanism Report'. Report lists Problem Reporting Mechanisms 
 info for all ca owner and not revoked intermediate cert records included in Mozilla and Microsoft.
  
 
 Instructions:  None

 *******************************************************************************************************
 Revision History:
 
     3/3/2018 - Created new

 ******************************************************************************************************/

@isTest 
public class AllProblemReportingMechanismsRptCtlrTest{
    
    static testMethod void validateTest() {
        
        Account acc = new Account(Name='Test Account Name To Test AllProblemReportingMechanismsReportCtlr', Problem_Reporting_Mechanism__c = 'test@test.com', Status__c = 'Included');
        insert acc;
        
        // create a CA Owner
        Account CAOwner = New Account();
        CAOwner.recordTypeId= Schema.SObjectType.Account.getRecordTypeInfosByName().get('CA Owner').getRecordTypeId(); 
        CAOwner.name = 'TestCAOwner';
        CAOwner.Problem_Reporting_Mechanism__c = 'test@test.com';
        CAOwner.parentId = acc.id;
        CAOwner.Status__c = 'Included';
        insert CAOwner;
        
        
        // create a Root Certificate
        Account rootCert = New Account();
        rootCert.recordTypeId= Schema.SObjectType.Account.getRecordTypeInfosByName().get('Root Certificate').getRecordTypeId(); 
        rootCert.name = 'TestRootCertificate';
        rootCert.Problem_Reporting_Mechanism__c = 'test@test.com';
        rootCert.parentId = acc.id;
        rootCert.Status__c = 'Included';
        rootCert.X_509_Certificate_PEM__c = 'samplePEM';
        insert rootCert;
        
        
        // create a Intermediate Certificate
        Account interCert = New Account();
        interCert.recordTypeId= Schema.SObjectType.Account.getRecordTypeInfosByName().get('Intermediate Certificate').getRecordTypeId(); 
        interCert.name = 'TestIntermediateCertificate';
        interCert.Problem_Reporting_Mechanism__c = 'test@test.com';
        interCert.valid_To_GMT__c= date.today()+1;
        interCert.parentId = rootCert.id;
        interCert.Status__c = 'Provided By CA';
        interCert.X_509_Certificate_PEM__c = 'samplePEM';
        insert interCert;
        
        PageReference pref = Page.AllProblemReportingMechanismsReport;
        Test.setCurrentPage(pref);
        AllProblemReportingMechanismsReportCtlr pacrc = new AllProblemReportingMechanismsReportCtlr();
        pacrc.getCurrentDate();
    }
}
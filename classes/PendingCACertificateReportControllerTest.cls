/**

Test Case for the following Controller Extension:
PendingCACertificateReportController

**/

@isTest 
public class PendingCACertificateReportControllerTest {

    static testMethod void validateTest() {
        
        Account acc = TestUtils.getCAOwner();
        insert acc;
        
        Case objCase = TestUtils.getCase(acc.Id);
        insert objCase;
        
        Root_case__c objRC = TestUtils.getRootCase(objCase.Id, acc.Id);
        objRC.recordTypeId = Schema.SObjectType.Root_case__c.getRecordTypeInfosByName().get('CA Root Inclusion Request').getRecordTypeID();
        insert objRC;
        
        PageReference pref = Page.PendingCACertificateReportCSVFormat;
        Test.setCurrentPage(pref);
        
        PendingCACertificateReportController pacrc = new PendingCACertificateReportController();
        pacrc.getCurrentDate();
    
    }

}
/**

Test Case for the following Controller Extension:
CCAInformationReportController

**/

@isTest 
public class CAInformationReportControllerTest{

    static testMethod void validateTest() {
        Account owner = TestUtils.getCAOwner();
        owner.Status__c = 'Included';
        owner.Problem_Reporting_Mechanism__c = 'test@gmail.com';
        insert owner;
        
        PageReference pref = Page.CAInformationReport;
        Test.setCurrentPage(pref);
        CAInformationReportController pacrc = new CAInformationReportController();
        pacrc.getCurrentDate();
    }
}
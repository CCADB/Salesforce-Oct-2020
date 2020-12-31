/**

Test Case for the following Controller Extension:
ProblemReportingMechanismsReportCtlr

**/

@isTest 
public class ProblemReportingMechanismsReportCtlrTest{

    static testMethod void validateTest() {
        Account owner = TestUtils.getCAOwner();
        owner.Status__c = 'Included';
        owner.Problem_Reporting_Mechanism__c = 'test@gmail.com';
        insert owner;
 
        PageReference pref = Page.ProblemReportingMechanismsReport;
        Test.setCurrentPage(pref);
        
        ProblemReportingMechanismsReportCtlr pacrc = new ProblemReportingMechanismsReportCtlr();
        pacrc.getCurrentDate();
    }

}
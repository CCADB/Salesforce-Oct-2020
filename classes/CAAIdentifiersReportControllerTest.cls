/**

Test Case for the following Controller Extension:
CAAIdentifiersReportController

**/

@isTest 
public class CAAIdentifiersReportControllerTest{

    static testMethod void validateTest() {
        Account owner = TestUtils.getCAOwner();
        owner.Status__c = 'Included';
        owner.Recognized_CAA_Domains__c = 'test@gmail.com';
        insert owner;
 
        PageReference pref = Page.CAAIdentifiersReport;
        Test.setCurrentPage(pref);
        
        CAAIdentifiersReportController pacrc = new CAAIdentifiersReportController();
        pacrc.getCurrentDate();
    }

}
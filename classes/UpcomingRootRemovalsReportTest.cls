/**

Test Case for the following Controller Extension:
UpcomingRootRemovalsReportController

**/

@isTest 
public class UpcomingRootRemovalsReportTest{

  static testMethod void validateTest() {
  
  PageReference pref = Page.UpcomingRootRemovalsReportCSVFormat;
  Test.setCurrentPage(pref);
  
  UpcomingRootRemovalsReportController pacrc = new UpcomingRootRemovalsReportController();
  
  }

}
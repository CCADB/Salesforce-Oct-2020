/*******************************************************************************************************
 Name: AllCAAIdentifiersReportControllerTest

 Dependencies: AllCAAIdentifiersReportController controller class, AllCAAIdentifiersReportControllerTest 
 test class, AllCAAIdentifiersReportController vf page

 Description: This is a test class for AllCAAIdentifiersReportController. Report lists 
 Recognized CAA Domains info for all CA Owner and Intermediate Cert records.
 
 Instructions: None   
 *******************************************************************************************************
 Revision History:
 
     3/3/2018 - Created new class
 ******************************************************************************************************/     

@isTest 
public class AllCAAIdentifiersReportControllerTest {

    static testMethod void validateTest() {
        
        Account acc = new Account(Name='Test Account Name To Test AllCAAIdentifiersReportController',Problem_Reporting_Mechanism__c = 'test@test.com', Status__c = 'Included',Recognized_CAA_Domains__c = 'test.com');
        insert acc;
        
        PageReference pref = Page.AllCAAIdentifiersReport;
        Test.setCurrentPage(pref);
        AllCAAIdentifiersReportController pacrc = new AllCAAIdentifiersReportController();
        pacrc.getCurrentDate();
    }
}
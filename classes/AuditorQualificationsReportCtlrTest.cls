/**

Test Case for the following Controller Extension:
AuditorQualificationsReportControler

**/

@isTest 
public class AuditorQualificationsReportCtlrTest{

    static testMethod void validateTest() {
        AuditorQualificationsReportController pacrc = new AuditorQualificationsReportController();
        pacrc.getCurrentDate();
    }
}
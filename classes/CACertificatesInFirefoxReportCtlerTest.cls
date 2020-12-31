/**

Test Case for the following Controller Extension:
CACertificatesInFirefoxReportController

**/

@isTest 
public class CACertificatesInFirefoxReportCtlerTest{

  static testMethod void validateTest() {
  
  CACertificatesInFirefoxReportController pacrc = new CACertificatesInFirefoxReportController();
  pacrc.getCurrentDate();
  }

}
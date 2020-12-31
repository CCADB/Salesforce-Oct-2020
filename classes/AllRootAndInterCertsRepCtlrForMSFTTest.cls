/*******************************************************************************************************
 Name: AllRootAndInterCertsRepCtlrForMSFTTest

 Dependencies: AllRootAndInterCertsReportCtlrForMSFT controller class, 
 AllRootAndInterCertsReportCtlrForMSFT vf page, AllRootAndInterCertsRepCtlrForMSFTTest test class

 Description: This is a test class for Controller Extension AllRootAndInterCertsReportCtlrForMSFT
 It generates a report which lists all Root and Intermediate Certs in CCADB.
 
 Instructions:    
 *******************************************************************************************************
 Revision History:
 
     3/1/2017 - Created new class
 ******************************************************************************************************/
 /**

Test Case for the following Controller Extension:
    AllRootAndInterCertsReportCtlrForMSFT

**/

@isTest 
public class AllRootAndInterCertsRepCtlrForMSFTTest{

  static testMethod void validateTest() {
  
     AllRootAndInterCertsReportCtlrForMSFT pacrc = new AllRootAndInterCertsReportCtlrForMSFT();
     pacrc.getCurrentDate();
  }

}
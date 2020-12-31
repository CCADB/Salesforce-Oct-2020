/********************* THIS PRORGAM HAS BEEN REPLACE BY IncludedRootsPEMControllerTest ********************/

/*******************************************************************************************************
 Name: PEMOnlyReportControllerTest

 Dependencies: PEMOnlyReportController controller class, PEMOnlyCSV vf page, PEMOnlyReportControllerTest test class

 Description: This report generates single column report on PEM. It takes in parametrized url.
 
 .../PEMOnlyCSV?TrustBitsInclude=Websites      <= look for 'Websites' included in Mozilla Trust Bits
 .../PEMOnlyCSV?TrustBitsInclude=Email         <= look for 'Email included in Mozilla Trust Bits
      
 Instructions: None
 *******************************************************************************************************
 Revision History:
 
     10/3/2020 - Created new.
     
 ******************************************************************************************************/
@isTest
public with sharing class PEMOnlyReportControllerTest {
    static testmethod void TestReport(){
        Account accountSo = TestUtils.getCAOwner();
        insert accountSo;
        
        //create a ROOT CA
        Account rootCA = TestUtils.getRootCertificate(accountSo.Id);
        rootCA.Status__c = 'Included';
        rootCA.Trust_Bits__c = 'Websites;Email';
        insert rootCa;
        
        Apexpages.currentpage().getparameters().put('TrustBitsInclude','Websites');
        PEMOnlyReportController controller = new PEMOnlyReportController();
    }
}
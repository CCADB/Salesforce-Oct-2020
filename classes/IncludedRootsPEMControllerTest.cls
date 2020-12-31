/*******************************************************************************************************
 Name: IncludedRootsPEMControllerTest

 Dependencies: IncludedRootsPEMController controller class, IncludedRootsPEMCSV vf page, 
 IncludedRootsPEMTxt vf page, IncludedRootsPEMControllerTest test class

 Description: This report generates single column report on PEM. It takes in parametrized url.
 Two types of outputs are avilable using the following links: csv or text
 
 .../IncludedRootsPEMCSV?TrustBitsInclude=Websites      <= look for 'Websites' included in Mozilla Trust Bits
 .../IncludedRootsPEMCSV?TrustBitsInclude=Email         <= look for 'Email included in Mozilla Trust Bits
 
 .../IncludedRootsPEMTxt?TrustBitsInclude=Websites      <= look for 'Websites' included in Mozilla Trust Bits
 .../IncludedRootsPEMTxt?TrustBitsInclude=Email         <= look for 'Email included in Mozilla Trust Bits
      
 Instructions: None
 *******************************************************************************************************
 Revision History:
 
     10/5/2020 - Created new.
     
 ******************************************************************************************************/
@isTest
public with sharing class IncludedRootsPEMControllerTest {
    static testmethod void TestReport(){
        Account accountSo = TestUtils.getCAOwner();
        insert accountSo;
        
        //create a ROOT CA
        Account rootCA = TestUtils.getRootCertificate(accountSo.Id);
        rootCA.Status__c = 'Included';
        rootCA.Trust_Bits__c = 'Websites;Email';
        rootCA.X_509_Certificate_PEM__c = TestUtils.strPEMInfo;
        insert rootCa;
        
        Apexpages.currentpage().getparameters().put('TrustBitsInclude','Websites');
        IncludedRootsPEMController controller = new IncludedRootsPEMController();
    }
}
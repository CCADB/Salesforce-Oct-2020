/********************* THIS PRORGAM HAS BEEN REPLACE BY IncludedRootsPEMController ********************/

/*******************************************************************************************************
 Name: PEMOnlyReportController

 Dependencies: PEMOnlyReportController controller class, PEMOnlyCSV vf page, PEMOnlyReportControllerTest test class

 Description: This report generates single column report on PEM. It takes in parametrized url.
 
 .../PEMOnlyCSV?TrustBitsInclude=Websites      <= look for 'Websites' included in Mozilla Trust Bits
 .../PEMOnlyCSV?TrustBitsInclude=Email         <= look for 'Email included in Mozilla Trust Bits
      
 Instructions: None
 *******************************************************************************************************
 Revision History:
 
     10/3/2020 - Created new.
     
 ******************************************************************************************************/
public without sharing class PEMOnlyReportController {
    public List<Account> lstRootCertificates {get; set;}
    public PEMOnlyReportController(){
        string TrustBitsInclude = Apexpages.currentpage().getParameters().get('TrustBitsInclude');
        lstRootCertificates = new List<Account>();
        if(string.isnotblank(TrustBitsInclude)){
            string strTBI = '(\''+TrustBitsInclude+'\')';
            string Query = ' Select Id, X_509_Certificate_PEM__c from Account Where RecordType.Name = \'Root Certificate\' ';
            Query += ' AND Status__c in (\'Included\', \'Change Requested\')';
            Query += ' AND Trust_Bits__c includes '+strTBI;
            lstRootCertificates = Database.Query(Query);
        }
        
    }
}
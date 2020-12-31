/*******************************************************************************************************
 Name: IncludedRootsPEMController

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
     10/9/2020 - Add text format report and removed linefeed from middle section of PEM
     10/14/2020 - Keep linefeed in the middle section of PEM.
                  Followed the guideline given in https://tools.ietf.org/html/rfc7468
                  "Generators MUST wrap the base64-encoded lines so that each line
                   consists of exactly 64 characters except for the final line, which
                   will encode the remainder of the data (within the 64-character line
                   boundary), and they MUST NOT emit extraneous whitespace."
     
 ******************************************************************************************************/
public without sharing class IncludedRootsPEMController {
    public List<Account> lstRootCertificates {get; set;}
    public List<String> lstPEMs {get; set;}
    public IncludedRootsPEMController(){
        string TrustBitsInclude = Apexpages.currentpage().getParameters().get('TrustBitsInclude');
        lstRootCertificates = new List<Account>();
        lstPEMs = new List<string>();
        if(string.isnotblank(TrustBitsInclude)){
            string strTBI = '(\''+TrustBitsInclude+'\')';
            string Query = ' Select Id, X_509_Certificate_PEM__c from Account Where RecordType.Name = \'Root Certificate\' ';
            Query += ' AND Status__c in (\'Included\', \'Change Requested\')';
            Query += ' AND Trust_Bits__c includes '+strTBI;
            lstRootCertificates = Database.Query(Query);
            for(Account rootCert: lstRootCertificates){
                if(rootCert.X_509_Certificate_PEM__c != null) {
                    /*rootCert.X_509_Certificate_PEM__c = rootCert.X_509_Certificate_PEM__c.replace('\n','').replace('\r','').replace('\r\n','');
                    rootCert.X_509_Certificate_PEM__c = rootCert.X_509_Certificate_PEM__c.replace('-----BEGIN CERTIFICATE-----','-----BEGIN CERTIFICATE-----\n');
                    rootCert.X_509_Certificate_PEM__c = rootCert.X_509_Certificate_PEM__c.replace('-----END CERTIFICATE-----','\n-----END CERTIFICATE-----\n');*/
                    lstPEMs.add(rootCert.X_509_Certificate_PEM__c+'\n');
                }
            }
        }
        
    }
}
/*******************************************************************************************************
 Name: MozillaIntermediateCertsReportController

 Dependencies:  MozillaIntermediateCertsReportController controller class,  MozillaIntermediateCertsReportCtrlTest, 
 MozillaIntermediateCertsCSVReport vf page

 Description: This report lists non revoked intermediate certs and Derived Trust Bits contains 'Server Authentication'.
 Firefox directly uses this report to create the intermediate certificate bulk load list.
 
 Instructions:  None

 *******************************************************************************************************
 Revision History:
 
     1/15/2019 - Created new
     6/03/2020 - Added new filters OneCRL Status not equal to 'Added to OneCRL'and
                 Derived Trust Bits contains 'Server Authentication'

 ******************************************************************************************************/
 
 public class MozillaIntermediateCertsReportController {

    public List<Account> lstIntermediateCerts {get;set;}
 
    //constructor method for standard controller
    public MozillaIntermediateCertsReportController() {   
          
        List<Account> lstTempIntermediateCerts =  [SELECT Id, Name, Subject__c, Issuer__c, SHA_256_Fingerprint__c, Derived_Trust_Bits__c , X_509_Certificate_PEM__c 
                                        FROM Account
                                        WHERE Name != '<Fill in Cert Name>' 
                                        AND RecordType.Name = 'Intermediate Certificate' 
                                        AND Revocation_Status__c not in ('Revoked','Parent Cert Revoked') 
                                        AND Root_Status__c in ('Included','Change Requested') 
                                        AND Root_Cert_Id__r.Trust_Bits__c includes ('Websites')
                                        AND Valid_To_GMT__c > TODAY 
                                        AND OneCRL_Status__c != 'Added to OneCRL'
                                        // AND Derived_Trust_Bits__c in ('Server Authentication') ***** this check is happening on line #25 *****
                                        ORDER BY Name];
                                          
        lstIntermediateCerts = new List<Account>();                          
        // if we are generating a CSV file then we need to replace the double quotes in all text fields with null
        if((Test.IsRunningTest() || ApexPages.currentPage().getUrl().contains('CSV')) && lstTempIntermediateCerts !=null && lstTempIntermediateCerts.size() > 0)
        {
            for(Account acc: lstTempIntermediateCerts){
                if(acc.Derived_Trust_Bits__c != null && acc.Derived_Trust_Bits__c.contains('Server Authentication')){
                    if(acc.name !=null && acc.name.length() > 0) 
                        acc.name = acc.name.replace('"',''); 
                    if(acc.Subject__c !=null && acc.Subject__c.length() > 0) 
                        acc.Subject__c = acc.Subject__c.replace('"','');
                    if(acc.Issuer__c !=null && acc.Issuer__c.length() > 0) 
                        acc.Issuer__c = acc.Issuer__c.replace('"','');
                    if(acc.SHA_256_Fingerprint__c !=null && acc.SHA_256_Fingerprint__c.length() > 0) 
                        acc.SHA_256_Fingerprint__c = acc.SHA_256_Fingerprint__c.replace('"','').replace(':','');
                    lstIntermediateCerts.add(acc);
                }
            }
        }
    }
}
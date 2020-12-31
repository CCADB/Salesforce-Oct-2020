/*
    Description: Finds incorrect format of PEM Info in Root Certs and Intermediate Certs.
    PEM info which is a single line string is filtered and reported on VF page IncorrectFormatForPEMInfoReport
*/
public with sharing class IncorrectFormatForPEMInfoReport {
    
    transient public List<wrapperAccounts> lstWrapperAccounts {get; set;}
    
    public IncorrectFormatForPEMInfoReport(){
        
        lstWrapperAccounts = new List<wrapperAccounts>();
        
        for(Account objAcc: [select Id, CA_Owner__c,Name, SHA_256_Fingerprint__c, RecordType.Name, X_509_Certificate_PEM__c from Account  
                Where RecordType.DeveloperName in ('Root_Certificate','Intermediate_Certificate') order by CA_Owner__c, Name]){
                
            if(objAcc.X_509_Certificate_PEM__c != null && objAcc.X_509_Certificate_PEM__c  != '') {
                if(objAcc.X_509_Certificate_PEM__c.startswith('-----BEGIN CERTIFICATE-----') && objAcc.X_509_Certificate_PEM__c.endswith('-----END CERTIFICATE-----')){
                    // didn't work string strPEMInfo = objAcc.X_509_Certificate_PEM__c.removeStart('-----BEGIN CERTIFICATE-----\n');
                    string strPEMInfo = objAcc.X_509_Certificate_PEM__c.removeStart('-----BEGIN CERTIFICATE-----');
                    strPEMInfo = strPEMInfo.removeEnd('-----END CERTIFICATE-----');
                    string[] arrAllLines = strPEMInfo.split('\n');
                    
                    // if(arrAllLines.size() == 1) { production shows no records
                    // if(arrAllLines.size() < 14) { incorrect output
                    // if(arrAllLines.size() < 12) { 
                    //    lstIncorrectedPEMInfoAccounts.add(objAcc);
                    // }
                    
                    // most pem line length is 64, some have 60, 72, 75, 76 which are also valid
                    Integer linecount = 1;
                    for(string strline: arrAllLines){
                        if(string.isnotblank(strline)){
                            if(strline.trim().length() > 76){
                                lstWrapperAccounts.add(new wrapperAccounts(objAcc, strline.trim().length()));
                                break;
                            } else {
                                break;
                            }
                        }
                        linecount++;
                    }
                }
            }
        }
    }
    
    public class wrapperAccounts {
        public Account objAccount {get; set;}
        public integer PEMLength {get; set;}
        public wrapperAccounts(Account acc, Integer length){
            this.objAccount = acc;
            this.PEMLength = length;
        }
    }
}
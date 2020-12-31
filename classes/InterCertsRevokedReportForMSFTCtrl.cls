/*******************************************************************************************************
 Name: InterCertsRevokedReportForMSFTCtrl

 Dependencies: InterCertsRevokedReportForMSFTCtrl, InterCertsRevokedReportForMSFTCSV vf page,
 InterCertsRevokedReportForMSFTCtrlTest

 Description: This report generates list of intermediate certs which are revoked for Microsoft.

 Instructions: None

 *******************************************************************************************************
 Revision History:
 
     11/15/2019 - Created new

 ******************************************************************************************************/
 
 public without sharing class InterCertsRevokedReportForMSFTCtrl {
    public Transient List<Account> accountSoLst {get;set;}
    
  
    //constructor method for standard controller
    public InterCertsRevokedReportForMSFTCtrl() {  
    

                                           
        accountSoLst =  [SELECT Name, Case_Safe_ID__c, CA_Owner__c, Root_Cert_Id__r.Parent.id,
                            Subject__c, Certificate_Serial_Number__c, Alternate_CRL__c,
                            SHA_1_Fingerprint__c, SHA_256_Fingerprint__c,
                            Parent.SHA_1_Fingerprint__c, Parent.SHA_256_Fingerprint__c,
                            Root_Cert_Id__r.SHA_1_Fingerprint__c, Root_Cert_Id__r.SHA_256_Fingerprint__c,
                            Revocation_Status__c, Date_of_Revocation__c, RFC_5280_Revocation_Reason_Code__c, 
                            Revocation_Verification__c, Valid_To_GMT__c, X_509_Certificate_PEM__c
                            FROM  Account
                            WHERE Revocation_Status__c In ('Revoked','Parent Cert Revoked') 
                            AND   RecordType.Name = 'Intermediate Certificate' 
                            AND   Root_Cert_Id__r.Microsoft_Status__c in ('Included', 'Change Requested')
                            ORDER BY CA_Owner__c, Name];
                          
        // if we are generating a CSV file then we need to replace the double quotes in all text fields with null
        if(Test.IsRunningTest() || (ApexPages.currentPage().getUrl().contains('CSV') && accountSoLst !=null && accountSoLst.size() > 0)) {
            for(Account accountSo : accountSoLst){
                if(accountSo.name !=null && accountSo.name.length() > 0) 
                    accountSo.name = accountSo.name.replaceall('"','');
                if(accountSo.Subject__c !=null && accountSo.Subject__c.length() > 0) 
                    accountSo.Subject__c = accountSo.Subject__c.replaceall('"',''); 
                if(accountSo.Revocation_Verification__c !=null && accountSo.Revocation_Verification__c.length() > 0) 
                    accountSo.Revocation_Verification__c = accountSo.Revocation_Verification__c.replaceall('"','');        
                if(accountSo.X_509_Certificate_PEM__c!=null && accountSo.X_509_Certificate_PEM__c.length() > 0) 
                    accountSo.X_509_Certificate_PEM__c= accountSo.X_509_Certificate_PEM__c.replaceall('"','');  
            }
        }
    }
    
         
   String sfdcBaseURL = '';
   
   // Get the base URL to build record urls 
    public String getsfdcBaseURL() {
        
        sfdcBaseURL = URL.getSalesforceBaseUrl().toExternalForm();       
        return sfdcBaseURL;
    }
}
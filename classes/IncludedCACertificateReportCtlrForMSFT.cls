/*******************************************************************************************************
 Name: IncludedCACertificateReportCtlrForMSFT

 Dependencies:  IncludedCACertificateReportCtlrForMSFT controller class, IncludedCACertificateReportTestForMSFT
 test class, IncludedCACertificateReportForMSFT vf page, IncludedCACertificateReportForMSFTCSV  vf page,
 IncludedCACertificateReportForMSFTCSVPEM vf page, IncludedCACertificateDetailReport vf page

 Description: This is a controller class for a report to list all root certificates included by Microsoft.
 
 Instructions: None   
 *******************************************************************************************************
 Revision History:
 
      8/16/2016 - Created new class
      8/24/2019 - Added new fields for another report IncludedCACertificateDetailReport 
 ******************************************************************************************************/

public class IncludedCACertificateReportCtlrForMSFT {

 public transient List<Account> accountSoLst {get;set;}
 
  // constructor method for standard controller
    public IncludedCACertificateReportCtlrForMSFT() {   
                                         
        accountSoLst = [select Parent.Name, 
                                Name, 
                                SHA_1_Fingerprint__c, 
                                SHA_256_Fingerprint__c,                               
                                Valid_From_YYYY_MMM_DD__c,
                                Valid_To_YYYY_MMM_DD__c,
                                Public_Key_Algorithm__c,
                                Signature_Hash_Algorithm__c,
                                Microsoft_Trust_Bits__c,
                                Microsoft_Status__c,
                                X_509_Certificate_PEM__c
                            from  Account
                            where Microsoft_Status__c In ('Included','Change Requested','NotBefore','Disabled') 
                            and   RecordType.Name In ('Root Certificate')
                            order by Parent.Name, Friendly_Name__c];
     
        //if we are generating a CSV file then we need to replace the double quotes in all text fields with null
        if ((ApexPages.currentPage().getUrl().contains('CSV') && accountSoLst !=null && accountSoLst.size() > 0) || Test.isRunningTest()) {
            for(Account accountSo : accountSoLst) {
                if(accountSo.name !=null && accountSo.name.length() > 0) 
                   accountSo.name = accountSo.name.replace('"',''); 
                if(accountSo.parent.name !=null && accountSo.parent.name.length() > 0) 
                   accountSo.parent.name = accountSo.parent.name.replace('"',''); 
                if(accountSo.X_509_Certificate_PEM__c!=null && accountSo.X_509_Certificate_PEM__c.length() > 0) 
                   accountSo.X_509_Certificate_PEM__c= accountSo.X_509_Certificate_PEM__c.replace('"','');   
            } 
        }  
    } 
     
    String CurrentDate = ' ';
 
    // Get current Datetime in long date format   
    public String getCurrentDate() {
        Datetime cDT = System.now();
        CurrentDate = cDT.format('MMMM d, yyyy');
        return CurrentDate;
    }
}
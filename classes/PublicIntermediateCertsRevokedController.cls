/********************************************************************************************************************
  PublicIntermediateCertsRevokedController is a controller for PublicIntermediateCertsRevoked, PublicIntermediateCertsRevokedCSVFormat
  and PublicIntermediateCertsRevokedWithPEMCSV VF pages to list intermediate certs (Non-revoked) in hierarchy. 
  Report name used is 'All Revoked Intermediate Certs' 
  
 *********************************************************************************************************************/

public class PublicIntermediateCertsRevokedController{


    public transient List<Account> accountHierarchySoLst {get;set;}
    String revocationStatus = 'Not Revoked';
    String recordTypeName = 'Intermediate Certificate';
 
    //constructor method for standard controller
    public PublicIntermediateCertsRevokedController() { 
    
        accountHierarchySoLst = [select name, type, record_type_name__c, CA_Owner__c,
                                    Certificate_Issuer_Common_Name__c, Certificate_Issuer_Organization__c, 
                                    Certificate_Subject_Common_Name__c, Certificate_Subject_Organization__c,
                                    Certificate_Serial_Number__c, Subject_SPKI_SHA256__c,  
                                    SHA_256_Fingerprint__c,                                   
                                    Valid_From_YYYY_MMM_DD__c, Valid_To_YYYY_MMM_DD__c, 
                                    Public_Key_Algorithm__c, Signature_Hash_Algorithm__c, 
                                    RFC_5280_Revocation_Reason_Code__c, revocation_status__c, 
                                    OneCRL_Status__c, CRL_URL_s__c, Alternate_CRL__c, 
                                    Date_of_Revocation_GMT__c,
                                    X_509_Certificate_PEM__c, comments__c
                             From Account 
                             where Revocation_Status__c != :revocationStatus 
                             and   name != '<Fill in Cert Name>' 
                             and   record_type_name__c = :RecordTypeName 
                             order by CA_Owner__c];  
                             
                             
         
        // if we are generating a CSV file then we need to replace the double quotes in all text fields with null
        if((ApexPages.currentPage().getUrl().contains('CSV') && accountHierarchySoLst !=null && accountHierarchySoLst.size() > 0) || Test.IsRunningTest())
        {
            for(Account accountSo : accountHierarchySoLst)
            {
                if(accountSo.name !=null && accountSo.name.length() > 0) 
                    accountSo.name = accountSo.name.replace('"','');              
                if(accountSo.ca_owner__c!=null && accountSo.ca_owner__c.length() > 0) 
                    accountSo.ca_owner__c= accountSo.ca_owner__c.replace('"',''); 
                if(accountSo.Certificate_Issuer_Common_Name__c !=null && accountSo.Certificate_Issuer_Common_Name__c.length() > 0) 
                    accountSo.Certificate_Issuer_Common_Name__c = accountSo.Certificate_Issuer_Common_Name__c.replace('"',''); 
                if(accountSo.Certificate_Issuer_Organization__c !=null && accountSo.Certificate_Issuer_Organization__c.length() > 0) 
                    accountSo.Certificate_Issuer_Organization__c = accountSo.Certificate_Issuer_Organization__c.replace('"',''); 
                if(accountSo.Certificate_Subject_Common_Name__c !=null && accountSo.Certificate_Subject_Common_Name__c.length() > 0) 
                    accountSo.Certificate_Subject_Common_Name__c = accountSo.Certificate_Subject_Common_Name__c.replace('"','');              
                if(accountSo.Certificate_Subject_Organization__c !=null && accountSo.Certificate_Subject_Organization__c.length() > 0) 
                    accountSo.Certificate_Subject_Organization__c = accountSo.Certificate_Subject_Organization__c.replace('"',''); 
                if(accountSo.CRL_URL_s__c !=null && accountSo.CRL_URL_s__c.length() > 0) 
                    accountSo.CRL_URL_s__c= accountSo.CRL_URL_s__c.replace('"',''); 
                if(accountSo.Alternate_CRL__c !=null && accountSo.Alternate_CRL__c.length() > 0) 
                    accountSo.Alternate_CRL__c= accountSo.Alternate_CRL__c.replace('"','');  
                /*if(accountSo.OCSP_URL_s__c !=null && accountSo.OCSP_URL_s__c.length() > 0) 
                    accountSo.OCSP_URL_s__c= accountSo.OCSP_URL_s__c.replace('"','');      */                  
                if(accountSo.X_509_Certificate_PEM__c!=null && accountSo.X_509_Certificate_PEM__c.length() > 0) 
                    accountSo.X_509_Certificate_PEM__c= accountSo.X_509_Certificate_PEM__c.replace('"','');  
                if(accountSo.Comments__c !=null && accountSo.Comments__c.length() > 0) 
                    accountSo.Comments__c= accountSo.Comments__c.replace('"','');                         
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
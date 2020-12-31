/********************************************************************************************************************

  PEMDataForInterCertsReportController is a controller for PEMDataForInterCertsWithPEMCSV
  to generate report on ALL intermediate. Report also has Technically Constrained Certs.
  
  This report was specifically created for Chris to compare CCADB data in Firefox,NSS included certs and 
  new TLS Observatory tool PEM->JSON
  
 *********************************************************************************************************************/

public class PEMDataForInterCertsReportController {

 public List<Account> accountSoLst {get;set;}
 
  // constructor method for standard controller
    public PEMDataForInterCertsReportController() {   
                                          
           accountSoLst =  [select  Name,
                                    Parent.Name,
                                    CA_Owner__c,
                                    Certificate_Issuer_Common_Name__c,
                                    Certificate_Issuer_Organization__c,
                                    Certificate_Issuer_Organizational_Unit__c,
                                    Certificate_Subject_Common_Name__c, 
                                    Certificate_Subject_Organization__c, 
                                    Certificate_Subject_Organization_Unit__c,
                                    Subject__c,
                                    Valid_From_YYYY_MMM_DD__c,
                                    Valid_To_YYYY_MMM_DD__c,
                                    SHA_1_Fingerprint__c,                                   
                                    SHA_256_Fingerprint__c, 
                                    Subject_SPKI_SHA256__c, 
                                    Certificate_Serial_Number__c,                                                                                                                                 
                                    Signature_Hash_Algorithm__c,
                                    Public_Key_Algorithm__c,
                                    Certificate_Version__c,
                                    Key_Usage__c,
                                    Extended_Key_Usage__c, 
                                    CRL_URL_s__c, 
                                    Technically_Constrained__c,
                                    X_509_Certificate_PEM__c,                                   
                                    Status__c  
                                          from  Account
                                          where RecordType.Name = 'Intermediate Certificate' and                                                                                   
                                                Name != '<Fill in Cert Name>'
                                          order by CA_Owner__c, Parent.Name, Name];   
                                          
                                          /*****
                                           Root_Status__c In ('Included','Change Requested') and  
                                           Revocation_Status__c = 'Not Revoked' and   
                                           *****/
   
      // if we are generating a CSV file then we need to replace the double quotes in all text fields with null
       if((ApexPages.currentPage().getUrl().contains('CSV') && accountSoLst !=null && accountSoLst.size() > 0) || Test.IsRunningTest())
       {
          for(Account accountSo : accountSoLst)
          {
              if(accountSo.name !=null && accountSo.name.length() > 0) 
                   accountSo.name = accountSo.name.replace('"',''); 
              if(accountSo.parent.name !=null && accountSo.parent.name.length() > 0) 
                   accountSo.parent.name = accountSo.parent.name.replace('"','');  
              if(accountSo.Certificate_Issuer_Common_Name__c !=null && accountSo.Certificate_Issuer_Common_Name__c.length() > 0) 
                   accountSo.Certificate_Issuer_Common_Name__c = accountSo.Certificate_Issuer_Common_Name__c.replace('"',''); 
              if(accountSo.Certificate_Issuer_Organization__c !=null && accountSo.Certificate_Issuer_Organization__c.length() > 0) 
                   accountSo.Certificate_Issuer_Organization__c = accountSo.Certificate_Issuer_Organization__c.replace('"',''); 
              if(accountSo.Certificate_Subject_Common_Name__c !=null && accountSo.Certificate_Subject_Common_Name__c.length() > 0) 
                   accountSo.Certificate_Subject_Common_Name__c = accountSo.Certificate_Subject_Common_Name__c.replace('"','');               
              if(accountSo.Certificate_Subject_Organization__c !=null && accountSo.Certificate_Subject_Organization__c.length() > 0) 
                   accountSo.Certificate_Subject_Organization__c = accountSo.Certificate_Subject_Organization__c.replace('"','');              
              if(accountSo.Certificate_Subject_Organization_Unit__c !=null && accountSo.Certificate_Subject_Organization_Unit__c.length() > 0) 
                   accountSo.Certificate_Subject_Organization_Unit__c = accountSo.Certificate_Subject_Organization_Unit__c.replace('"','');               
              if(accountSo.Certificate_Issuer_Organizational_Unit__c !=null && accountSo.Certificate_Issuer_Organizational_Unit__c.length() > 0) 
                   accountSo.Certificate_Issuer_Organizational_Unit__c = accountSo.Certificate_Issuer_Organizational_Unit__c.replace('"','');                            
              if(accountSo.Subject__c !=null && accountSo.Subject__c.length() > 0) 
                   accountSo.Subject__c = accountSo.Subject__c.replace('"',''); 
              if(accountSo.Key_Usage__c !=null && accountSo.Key_Usage__c.length() > 0) 
                   accountSo.Key_Usage__c = accountSo.Key_Usage__c.replace('"',''); 
              if(accountSo.Extended_Key_Usage__c !=null && accountSo.Extended_Key_Usage__c.length() > 0) 
                   accountSo.Extended_Key_Usage__c = accountSo.Extended_Key_Usage__c.replace('"','');                 
              if(accountSo.SHA_1_Fingerprint__c !=null && accountSo.SHA_1_Fingerprint__c.length() > 0) 
                   accountSo.SHA_1_Fingerprint__c = accountSo.SHA_1_Fingerprint__c.replace('"',''); 
              if(accountSo.SHA_256_Fingerprint__c !=null && accountSo.SHA_256_Fingerprint__c.length() > 0) 
                   accountSo.SHA_256_Fingerprint__c = accountSo.SHA_256_Fingerprint__c.replace('"','');
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
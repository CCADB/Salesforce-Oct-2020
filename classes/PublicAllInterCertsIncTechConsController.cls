/********************************************************************************************************************

  PublicAllInterCertsIncTechConsController is a controller for PublicAllInterCertsIncTechConsControllerPEMCSV
  VF page to list intermediate certs (Non-revoked) in hierarchy. 
  Report name used is 'Public Non-Revoked Intermediate Certificates (Including Technically Constrained Certs)' 
  
  This report was specifically created for Chris to compare CCADB data and new TLS Observatory too PEM->JSON utility.
  
 *********************************************************************************************************************/

public class PublicAllInterCertsIncTechConsController {


    private List<Account> revokedAccountSoLst {get;set;}
 
    public List<Account> accountHierarchySoLst {get;set;}
    
    Public String CurrentDate = ' ';
 
    public PublicAllInterCertsIncTechConsController() {   
    
    // initialize all lists    
    accountHierarchySoLst = New List<account>();       
    revokedAccountSoLst = New List<account>();   
    
    String revocationStatus = 'Not Revoked';
    String recordTypeName = 'Intermediate Certificate';

    // query to get intermediate certs
    String queryStr = 'select ca_owner__c, parent.name, name,  type, status__c, record_type_name__c,CA_Owner_ID__c, parentid, Certificate_Issuer_Common_Name__c, Certificate_Issuer_Organization__c, Certificate_Subject_Common_Name__c, Certificate_Subject_Organization__c, Certificate_Issuer_Organizational_Unit__c, Certificate_Serial_Number__c, Subject_SPKI_SHA256__c, Key_Usage__c, SHA_1_Fingerprint__c, SHA_256_Fingerprint__c, Valid_From_YYYY_MMM_DD__c, Valid_To_YYYY_MMM_DD__c, CRL_URL_s__c, Public_Key_Algorithm__c, Signature_Hash_Algorithm__c, Certificate_Policy_CP__c, Certification_Practice_Statement_CPS__c, Standard_Audit__c, BR_Audit__c, Auditor_New__r.Name, Standard_Audit_Statement_Dt__c, CP_CPS_Same_as_Parent__c, Audits_Same_as_Parent__c,Extended_Key_Usage__c, Technically_Constrained__c, X_509_Certificate_PEM__c, comments__c From Account where lastmodifieddate!=null and Revocation_Status__c = :revocationStatus and name != \'<Fill in Cert Name>\' and record_type_name__c = :RecordTypeName  and (root_status__c= \'Included\' or root_status__c = \'Change Requested\') order by ca_owner__c,parent.name,name  ';                    
        
    // execute the soqls and get all the revoked intermediate certs and all the accounts    
    revokedAccountSoLst= Database.query(queryStr);
    
    if(revokedAccountSoLst == null || revokedAccountSoLst.size() == 0 )                
    {
         ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Warning, 'No Records found.'));
    }
    else
    {
        accountHierarchySoLst = revokedAccountSoLst;   
    }

   
      // if we are generating a CSV file then we need to replace the double quotes in all text fields with null
       if((ApexPages.currentPage().getUrl().contains('CSV') && accountHierarchySoLst !=null && accountHierarchySoLst.size() > 0) || Test.IsRunningTest())
       {
          for(Account accountSo : accountHierarchySoLst)
          {
              if(accountSo.name !=null && accountSo.name.length() > 0) 
                   accountSo.name = accountSo.name.replace('"',''); 
              if(accountSo.parent.name !=null && accountSo.parent.name.length() > 0) 
                   accountSo.parent.name = accountSo.parent.name.replace('"',''); 
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
              if(accountSo.Certificate_Issuer_Organizational_Unit__c !=null && accountSo.Certificate_Issuer_Organizational_Unit__c.length() > 0) 
                   accountSo.Certificate_Issuer_Organizational_Unit__c = accountSo.Certificate_Issuer_Organizational_Unit__c.replace('"','');                            
              if(accountSo.Key_Usage__c !=null && accountSo.Key_Usage__c.length() > 0) 
                   accountSo.Key_Usage__c = accountSo.Key_Usage__c.replace('"','');               
              if(accountSo.SHA_1_Fingerprint__c !=null && accountSo.SHA_1_Fingerprint__c.length() > 0) 
                   accountSo.SHA_1_Fingerprint__c = accountSo.SHA_1_Fingerprint__c.replace('"',''); 
              if(accountSo.SHA_256_Fingerprint__c !=null && accountSo.SHA_256_Fingerprint__c.length() > 0) 
                   accountSo.SHA_256_Fingerprint__c = accountSo.SHA_256_Fingerprint__c.replace('"','');
              if(accountSo.Extended_Key_Usage__c !=null && accountSo.Extended_Key_Usage__c.length() > 0) 
                   accountSo.Extended_Key_Usage__c = accountSo.Extended_Key_Usage__c.replace('"','');  
              if(accountSo.Certificate_Policy_CP__c !=null && accountSo.Certificate_Policy_CP__c.length() > 0) 
                   accountSo.Certificate_Policy_CP__c = accountSo.Certificate_Policy_CP__c.replace('"','');                      
              if(accountSo.Certification_Practice_Statement_CPS__c !=null && accountSo.Certification_Practice_Statement_CPS__c.length() > 0) 
                   accountSo.Certification_Practice_Statement_CPS__c = accountSo.Certification_Practice_Statement_CPS__c.replace('"','');
              if(accountSo.Standard_Audit__c !=null && accountSo.Standard_Audit__c.length() > 0) 
                   accountSo.Standard_Audit__c = accountSo.Standard_Audit__c.replace('"','');
              if(accountSo.BR_Audit__c !=null && accountSo.BR_Audit__c.length() > 0) 
                   accountSo.BR_Audit__c = accountSo.BR_Audit__c.replace('"','');       
              if(accountSo.Auditor_New__r.Name !=null && accountSo.Auditor_New__r.Name.length() > 0) 
                   accountSo.Auditor_New__r.Name = accountSo.Auditor_New__r.Name.replace('"',''); 
             /*if(accountSo.Management_Assertions_By__c !=null && accountSo.Management_Assertions_By__c.length() > 0) 
                   accountSo.Management_Assertions_By__c= accountSo.Management_Assertions_By__c.replace('"',''); */
             if(accountSo.X_509_Certificate_PEM__c!=null && accountSo.X_509_Certificate_PEM__c.length() > 0) 
                   accountSo.X_509_Certificate_PEM__c= accountSo.X_509_Certificate_PEM__c.replace('"','');  
             if(accountSo.Comments__c !=null && accountSo.Comments__c.length() > 0) 
                   accountSo.Comments__c= accountSo.Comments__c.replace('"','');               
           }
        }
    
 }
 
    
   // Get current Datetime in long date format   

    public String getCurrentDate() {

      Datetime cDT = System.now();
      CurrentDate = cDT.format('MMMM d, yyyy');

      return CurrentDate;

   }
    
 }
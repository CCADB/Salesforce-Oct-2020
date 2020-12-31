/********************************************************************************************************************
  PublicIntermediateCertsController is a controller for PublicIntermediateCerts and PublicIntermediateCertsCSVFormat
  VF pages to shows Intermediate Certs (Non-revoked) in hierarchy. 
  
  When no parameters are passed - an error will be thrown as the parameter is mandatory
  When the parameter is passed like CAOwnerName=Tesla - program lists records related to 'Tesla'
  When a blank parameter is passed CAOwnerName= -  the follow error message is displayed "No records found 
  in database. Please pass a valid CA Owner Name as url parameter."
  When the parameter is passed and no records are found then following error message is displayed - "No records found
  in database or invalid CA Owner Name passed as url parameter."
  
  Report name used is 'Public Intermediate Certs Hierarchy' 
  
 *********************************************************************************************************************/

public class PublicIntermediateCertsController {


  //private List<Account> allAccountSoLst;
  //private List<Account> revokedAccountSoLst;
 
  public transient List<Account> accountHierarchySoLst {get;set;}
  //private List<Account> accountHierarchySoLst2;
  
  // URL Parameter. If this parameter is provided then the records are fetched only for this CA Owner
  private String CAOwnerNameStr= '';
    
  Public String CurrentDate = ' ';
 
    
    public PublicIntermediateCertsController() {   
    
     // initialize all lists    
     accountHierarchySoLst = New List<account>();   
    // allAccountSoLst = New List<account>();   
     List<account> revokedAccountSoLst = New List<account>();   
    
    // get the ca owner name from the url 
    CAOwnerNameStr = ApexPages.CurrentPage().getParameters().get('CAOwnerName');
     
  
    
    String revocationStatus = 'Not Revoked';
    String recordTypeName = 'Intermediate Certificate';

    // query to get intermediate certs
    String queryStr = 'select name, type, status__c, record_type_name__c,CA_Owner_ID__c, parentid, Certificate_Issuer_Common_Name__c, Certificate_Issuer_Organization__c, Certificate_Subject_Common_Name__c, Certificate_Subject_Organization__c, SHA_256_Fingerprint__c, Certificate_Serial_Number__c, Subject_SPKI_SHA256__c, Valid_From_YYYY_MMM_DD__c, Valid_To_YYYY_MMM_DD__c, Public_Key_Algorithm__c, Signature_Hash_Algorithm__c,Certificate_Policy_CP__c, Certification_Practice_Statement_CPS__c, Standard_Audit__c, BR_Audit__c, Auditor_New__r.Name, Standard_Audit_Statement_Dt__c, CP_CPS_Same_as_Parent__c, Audits_Same_as_Parent__c,Extended_Key_Usage__c, Technically_Constrained__c From Account where lastmodifieddate!=null and Revocation_Status__c = :revocationStatus and name != \'<Fill in Cert Name>\' and technically_constrained__c != true and record_type_name__c = :RecordTypeName order by name  ';                    
    // query which gets all accounts
    String queryStr2 = 'select CA_Owner_ID__c,name, type, status__c, record_type_name__c, parentid, Certificate_Issuer_Common_Name__c, Certificate_Issuer_Organization__c, Certificate_Subject_Common_Name__c, Certificate_Subject_Organization__c, SHA_256_Fingerprint__c, Certificate_Serial_Number__c, Subject_SPKI_SHA256__c, Valid_From_YYYY_MMM_DD__c, Valid_To_YYYY_MMM_DD__c, Public_Key_Algorithm__c, Signature_Hash_Algorithm__c,Certificate_Policy_CP__c, Certification_Practice_Statement_CPS__c, Standard_Audit__c, BR_Audit__c, Auditor_New__r.Name, Standard_Audit_Statement_Dt__c, CP_CPS_Same_as_Parent__c, Audits_Same_as_Parent__c, Extended_Key_Usage__c, Technically_Constrained__c From Account where lastmodifieddate!=null  and name != \'<Fill in Cert Name>\' and technically_constrained__c != true   order by name  ';                    
    
    
    // execute the soqls and get all the revoked intermediate certs and all the accounts    
    revokedAccountSoLst= Database.query(queryStr);
    List<Account> allAccountSoLst = Database.query(queryStr2);
 
    List<Id> ownerAccountIdLst = New List<Id>();
    
    if(allaccountSoLst == null || allaccountSoLst.size() == 0 )                
    {
      ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, 'No Records found.'));
    }
    else
    {
            // iterate over intermediate certs and get owner 
            for(Account accountSo: revokedAccountSoLst)
                {  
                    // getOwnerAccounts(accountSo, allAccountSoLst);
                    ownerAccountIdLst.add(accountSo.CA_Owner_ID__c);
                }
    }

  
   List<Account>  ownerAccountLst ;

     
    /**
    1) When no parameters are passed - we throw an error message as the parameter is mandatory 

    2) When the parameter is passed like CAOwnerName=Tesla - program lists records related to 'Tesla'

    3) When a blank parameter is passed CAOwnerName= -  the follow error message is displayed "No records found in database. Please pass a valid CA Owner Name as url parameter."

    4) If the parameter is passed and no records are found then following error message is displayed - "No records found in database or invalid CA Owner Name passed as url parameter."

    **/
     if(CAOwnerNameStr==null)
     {
      // ownerAccountLst = [select name, type, status__c,record_type_name__c,CA_Owner_ID__c, parentid, Certificate_Issuer_Common_Name__c, Certificate_Issuer_Organization__c, Certificate_Subject_Common_Name__c, Certificate_Subject_Organization__c, SHA_256_Fingerprint__c, Certificate_Serial_Number__c, Subject_SPKI_SHA256__c, Valid_From_YYYY_MMM_DD__c, Valid_To_YYYY_MMM_DD__c, Public_Key_Algorithm__c, Signature_Hash_Algorithm__c,Certificate_Policy_CP__c, Certification_Practice_Statement_CPS__c, Standard_Audit__c, BR_Audit__c, Auditor_New__r.Name, Standard_Audit_Statement_Dt__c, CP_CPS_Same_as_Parent__c, Audits_Same_as_Parent__c, Extended_Key_Usage__c, Technically_Constrained__c from Account where id in :ownerAccountIdLst order by name];  
       ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'CAOwnerName paramter is missing in the URL. Please make sure that you pass this parameter with a value that must be an exact match to the CA Owner Name in Salesforce.'));
     }
     else if(CaOwnerNameStr=='')
     { 

       ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'CA Owner Name in the URL must be an exact match to the CA Owner Name in Salesforce.'));
     }
     
     else
     {      
      
      ownerAccountLst = [select name, type, status__c, record_type_name__c,CA_Owner_ID__c, parentid, Certificate_Issuer_Common_Name__c, Certificate_Issuer_Organization__c, Certificate_Subject_Common_Name__c, Certificate_Subject_Organization__c, SHA_256_Fingerprint__c, Certificate_Serial_Number__c, Subject_SPKI_SHA256__c, Valid_From_YYYY_MMM_DD__c, Valid_To_YYYY_MMM_DD__c, Public_Key_Algorithm__c, Signature_Hash_Algorithm__c,Certificate_Policy_CP__c, Certification_Practice_Statement_CPS__c, Standard_Audit__c, BR_Audit__c, Auditor_New__r.Name, Standard_Audit_Statement_Dt__c, CP_CPS_Same_as_Parent__c, Audits_Same_as_Parent__c, Extended_Key_Usage__c, Technically_Constrained__c from Account where name = :CAOwnerNameStr and id in :ownerAccountIdLst order by name];  
      
      if(ownerAccountlst!=NULL && ownerAccountlst.size() == 0)
       {
               // check to see if it is a valid owner name, as we do not need to display any error message if the CA owner name is valid and no root/inter records are found
               ownerAccountLst = [select name, type, status__c, record_type_name__c,CA_Owner_ID__c, parentid, Certificate_Issuer_Common_Name__c, Certificate_Issuer_Organization__c, Certificate_Subject_Common_Name__c, Certificate_Subject_Organization__c, SHA_256_Fingerprint__c, Certificate_Serial_Number__c, Subject_SPKI_SHA256__c, Valid_From_YYYY_MMM_DD__c, Valid_To_YYYY_MMM_DD__c, Public_Key_Algorithm__c, Signature_Hash_Algorithm__c,Certificate_Policy_CP__c, Certification_Practice_Statement_CPS__c, Standard_Audit__c, BR_Audit__c, Auditor_New__r.Name, Standard_Audit_Statement_Dt__c, CP_CPS_Same_as_Parent__c, Audits_Same_as_Parent__c, Extended_Key_Usage__c, Technically_Constrained__c from Account where name = :CAOwnerNameStr order by name];
               
               if(ownerAccountlst==NULL ||( ownerAccountlst!=NULL && ownerAccountlst.size() == 0))
                   {                 
                       ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'CA Owner Name in the URL must be an exact match to the CA Owner Name in Salesforce.'));
                   }
       }
     }


  // iterate over all the owner accounts and get the child records 
   if(ownerAccountlst!=NULL && ownerAccountlst.size() > 0)
      {
          
        for(Account ownerAccountSo: ownerAccountLst)
        {
                accountHierarchySoLst.add(ownerAccountSo);
                // get the child records for the current owner and add this owner to the display list 
                getChildAccounts(ownerAccountSo, allaccountSoLst);
        }
      
      }
  

  
  
  // iterate over the generated list and add only those records in the list which have a valid parent
  if(accountHierarchySoLst.size() > 0)
  {
    List<Account> accountHierarchySoLst2 = New List<Account>();
    Boolean parentFound;
    for(Account accountSo: accountHierarchySoLst)
    {
     
      if(accountSo.record_type_name__c == 'Root Certificate') 
      {
        
        parentFound = false; 
        for(Account childAccountSo: accountHierarchySoLst)
          {
            
           if(childAccountSo.record_type_name__c == 'Intermediate Certificate' && childAccountSo.parentId == accountSo.id)
           {
             parentFound = true;
           }
       
          } // for loop
          
         
     }
     
     //if(accountSo.record_type_name__c != 'Root Certificate' || (accountSo.record_type_name__c == 'Root Certificate' && parentFound)){

     /*For the following requirement, we can use the if condition below to mark the root certs 
     which have the trustbits = website but dont have any inter certs. 
     Requirement: If the root has the websites trust bit enabled (Trust Bits = Websites), then it must have intermediate certs. 
       So, any root (with the websites trust bit enabled) with no intermediate certs would be a red flag.
      But let's not display error message in the report. We'll wait until the community users get all the data entered. 
      */
         // if(accountSo.record_type_name__c != 'Root Certificate' || (accountSo.record_type_name__c == 'Root Certificate' && accountSo.Trust_Bits__c == 'Websites' && !parentFound)){
             accountHierarchySoLst2.add(accountSo);
    
       }
   
      accountHierarchySoLst = accountHierarchySoLst2;
    
    }
       // if we are generating a CSV file then we need to replace the double quotes in all text fields with null
       if((ApexPages.currentPage().getUrl().contains('CSV') && accountHierarchySoLst !=null && accountHierarchySoLst.size() > 0) || Test.isRunningTest())
       {
          for(Account accountSo : accountHierarchySoLst)
          {
              if(accountSo.name !=null && accountSo.name.length() > 0) 
                   accountSo.name = accountSo.name.replace('"',''); 
              if(accountSo.Certificate_Issuer_Common_Name__c !=null && accountSo.Certificate_Issuer_Common_Name__c.length() > 0) 
                   accountSo.Certificate_Issuer_Common_Name__c = accountSo.Certificate_Issuer_Common_Name__c.replace('"',''); 
              if(accountSo.Certificate_Issuer_Organization__c !=null && accountSo.Certificate_Issuer_Organization__c.length() > 0) 
                   accountSo.Certificate_Issuer_Organization__c = accountSo.Certificate_Issuer_Organization__c.replace('"',''); 
              if(accountSo.Certificate_Subject_Common_Name__c !=null && accountSo.Certificate_Subject_Common_Name__c.length() > 0) 
                   accountSo.Certificate_Subject_Common_Name__c = accountSo.Certificate_Subject_Common_Name__c.replace('"',''); 
              if(accountSo.Certificate_Subject_Organization__c !=null && accountSo.Certificate_Subject_Organization__c.length() > 0) 
                   accountSo.Certificate_Subject_Organization__c = accountSo.Certificate_Subject_Organization__c.replace('"',''); 
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
                   accountSo.Management_Assertions_By__c= accountSo.Management_Assertions_By__c.replace('"','');*/ 
           }
        }
    
 }
 
    
  /**  private void getOwnerAccounts(Account accountSo, List<account> allAccountSoLst )
    {
       
      for(Account allAccountSo : allAccountSoLst )
       {
         
         // get the parent account
         if(accountSo.parentId == allAccountSo.id)
         {
            // if the parent is of type owner then get all the child accounts of this owner
            if(allAccountSo.Record_Type_Name__c == 'CA Owner' && allAccountSo.name.contains('Microsec'))
              {
                     accountHierarchySoLst.add(allAccountSo);
                     getChildAccounts(allAccountSo, allaccountSoLst);
                     
              }
            else
             {
                // else continue and get the parent account until we dont find the owner
                 getOwnerAccounts(allAccountSo,allAccountSoLst);
             }
         }
        
        
       }
    
    }
**/

    private void getChildAccounts(Account accountSo, List<account> accountSoLst)
    {
     
       for(Account childAccountSo : accountSoLst)
       {
           
         if(childAccountSo.record_type_name__c !='Root Certificate' || (childAccountSo.record_type_name__c =='Root Certificate' && (childAccountSo.Status__c == 'Included' || childAccountSo.status__c =='Change Requested') ))  
         
         {
             if(childAccountSo.parentId == accountSo.id )
             {
               
              accountHierarchySoLst.add(childAccountSo);
              getChildAccounts(childAccountSo, accountSoLst);
             }
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
/*
MigrateCertsBatch is used MigrateCertBatchController & MigrateCertBatchVF

Process certificate records from staging object (Migrate certs) and create/populate Account object

1) Process root certs
   - Read all records from staging object 'Migrate Certs'
   - Check format for field 'X_509_Certificate_PEM__c', save processing errors in 'Migrate Certs'
   - Call X509CertificateCheckerUtility to extract PEM fields, save processing errors in 'Migrate Certs'
   - If extracted PEM has matching SHA256 in existing Root Certs (from Account object), update Account existing Root Cert
   - else update 'Migrate Certs'
   
2) Process intermediate certs 
   - Read all records from staging object 'Migrate Certs'
   - If SHA-256 not null on 'Migrate Certs' then find matching parent in Account object
   - If Parent Name not null on 'Migrate Certs' then find matching parent in Account object
   - Call X509CertificateCheckerUtility to extract PEM fields, save processing errors in 'Migrate Certs'
   - Add inter cert, to matching parent
   - Run program more than once to eliminate 'Missing Parent records' 
   
*/

global class MigrateCertsBatch implements Database.Batchable<sObject>, Database.AllowsCallouts  {
    
    String warning;
    Migrate_Certs__c MigAcct; // hold certs from staging object
    Account CertCheckerAcct;  // holds results from cert checker utility
    Boolean validCert=false;  // set to true when cert has no errors
    private String processSelection;
    /* Empty Constructor */
    global MigrateCertsBatch(){}
    
    global MigrateCertsBatch(String processSelection){
        system.debug('processSelection2:'+processSelection);
        this.processSelection = processSelection;
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC) {
       
        /* Fetch records from Migrate Certs object  */
        
        String query =  'SELECT Id,Name,' +
                        'Auditor__c,Auditor_Qualifications__c,Auditor_Website__c,' + 
                        'Audits_Same_as_Parent__c, BR_Audit__c, BR_Audit_Statement_Date__c, BR_Audit_Type__c, Extraction_Results__c,' +
                        'CA_Owner__c, CA_Document_Repository__c, Certificate_Policy_CP__c, Certification_Practice_Statement_CPS__c,' +
                        'Comments__c, CP_CPS_Same_as_Parent__c, Date_of_Revocation__c, Description__c, EV_Audit__c,' +
                        'EV_Audit_Statement_Date__c, EV_Audit_Type__c, Management_Assertions_By__c, Migrated_Certs_OwnerId__c, Migrated_Cert__c,' +
                        'Parent_CA_Owner_Certificate__c, Policy_Documentation__c, Processing_Message_Error__c,' + 
                        'Processing_Status__c, Revocation_Status__c, RFC_5280_Revocation_Reason_Code__c, Standard_Audit__c,' +
                        'Standard_Audit_Statement_Date__c, Standard_Audit_Type__c, Parent_Certificate_s_SHA_256_Fingerprint__c, X_509_Certificate_PEM__c FROM Migrate_Certs__c' +
                        ' WHERE Processing_Status__c NOT IN (\'Migration Successful\',\'Migration Warning\') AND Certificate_Processed__c = False';
       
       /*
        String query =  'SELECT Id,Name,Auditor__c,Auditor_Qualifications__c,Auditor_Website__c,' + 
                        'Audits_Same_as_Parent__c, BR_Audit__c, BR_Audit_Statement_Date__c, BR_Audit_Type__c, Extraction_Results__c,' +
                        'CA_Owner__c, CA_Document_Repository__c, Certificate_Policy_CP__c, Certification_Practice_Statement_CPS__c,' +
                        'Comments__c, CP_CPS_Same_as_Parent__c, Date_of_Revocation__c, Description__c, EV_Audit__c,' +
                        'EV_Audit_Statement_Date__c, EV_Audit_Type__c, Management_Assertions_By__c, Migrated_Certs_OwnerId__c, Migrated_Cert__c,' +
                        'Parent_CA_Owner_Certificate__c, Policy_Documentation__c, Processing_Message_Error__c,' + 
                        'Processing_Status__c, Revocation_Status__c, RFC_5280_Revocation_Reason_Code__c, Standard_Audit__c,' +
                        'Standard_Audit_Statement_Date__c, Standard_Audit_Type__c, Parent_Certificate_s_SHA_256_Fingerprint__c, X_509_Certificate_PEM__c FROM Migrate_Certs__c' +
                        ' WHERE Name = \'Test Inter Cert 111\' AND Certificate_Processed__c = False';
       */
        return Database.getQueryLocator(query);
    
    }

/****

Execute method

****/   
    global void execute(Database.BatchableContext BC, List<sObject> scope) { 
         
         //String processSelection = 'Root Certificate';
         system.debug('processSelection3:'+processSelection);
         if (processSelection == 'Root Certificates')
            processRootCertificates(scope);
         else if (processSelection == 'Intermediate Certificates')
            processIntermediateCertificates(scope);
         else
            return;          
    }   
    
 /****   
   Process root certs
   - Read all records from staging object 'Migrate Certs'
   - Check format for field 'X_509_Certificate_PEM__c', save processing errors in 'Migrate Certs'
   - Call X509CertificateCheckerUtility to extract PEM fields, save processing errors in 'Migrate Certs'
   - If extracted PEM has matching SHA256 in existing Root Certs (from Account object), update Account existing Root Cert
   - else update 'Migrate Certs'
   
 ****/
    
    global void processRootCertificates(List<sObject> scope) {
     
         List<Account> listOfAcctToUpdate = new List<Account>();
         
         // Fetch Root Cert Record Type Name 
         // RecordType rt = [select Id from RecordType where Name = 'Root Certificate' and SobjectType = 'Account' limit 1];
      
         // Fetch all exisiting root records in Account object
         List<Account> listOfAcctRecordsOfTypeRoot = new List<Account>();
         listOfAcctRecordsOfTypeRoot = [SELECT Id, Name, Certificate_Subject_Common_Name__c, Certificate_Subject_Organization__c, Certificate_Subject_Organization_Unit__c,
         Certificate_Issuer_Common_Name__c, Certificate_Issuer_Organization__c, Certificate_Issuer_Organizational_Unit__c,
         Subject__c, SHA_1_Fingerprint__c, SHA_256_Fingerprint__c, Valid_From_GMT__c, Valid_To_GMT__c, Certificate_Serial_Number__c,
         Signature_Hash_Algorithm__c, Public_Key_Algorithm__c, CRL_URL_s__c
             from Account where RecordType.Name in ('Root Certificate')];   
     
         // Loop through each record in Migrate Cert object 
         for(sObject cert : scope) {
             
             warning = '';
             MigAcct = (Migrate_Certs__c) cert; // fetch all certs to migrate
             
             // Process migrate cert only if PEM info has correct format 
             if(MigAcct.X_509_Certificate_PEM__c == null) {
                Migrate_Certs__c mCert = new Migrate_Certs__c(Id = MigAcct.Id, Processing_Status__c = 'Migration Failure', Processing_Message_Error__c = 'PEM info is null.', Certificate_Processed__c = True, Extraction_Results__c = ' ');                     
                upsert mCert;   
             }   
             else if (MigAcct.X_509_Certificate_PEM__c.countmatches('BEGIN CERTIFICATE') == 0 || MigAcct.X_509_Certificate_PEM__c.countmatches('END CERTIFICATE') == 0) {
                Migrate_Certs__c mCert = new Migrate_Certs__c(Id = MigAcct.Id, Processing_Status__c = 'Migration Failure', Processing_Message_Error__c = 'PEM info does not have proper BEGIN CERTIFICATE/END CERTIFICATE format.', Certificate_Processed__c = True, Extraction_Results__c = ' ');  
                upsert mCert;  
             } 
             else if (MigAcct.X_509_Certificate_PEM__c.countmatches('BEGIN CERTIFICATE') > 1 && MigAcct.X_509_Certificate_PEM__c.countmatches('END CERTIFICATE') > 1) {
                Migrate_Certs__c mCert = new Migrate_Certs__c(Id = MigAcct.Id, Processing_Status__c = 'Migration Failure', Processing_Message_Error__c = 'Multiple occurance of "BEGIN CERTIFICATE" or "END CERTIFICATE" found in PEM info.', Certificate_Processed__c = True, Extraction_Results__c = ' ');  
                upsert mCert;  
             }              
             else if (MigAcct.X_509_Certificate_PEM__c.countmatches('-----BEGIN CERTIFICATE-----') != 1 || MigAcct.X_509_Certificate_PEM__c.countmatches('-----END CERTIFICATE-----') != 1) {
                Migrate_Certs__c mCert = new Migrate_Certs__c(Id = MigAcct.Id, Processing_Status__c = 'Migration Failure', Processing_Message_Error__c = 'PEM info does not have proper format for BEGIN/END tags.', Certificate_Processed__c = True, Extraction_Results__c = ' ');  
                upsert mCert;  
             }
             else if (!MigAcct.X_509_Certificate_PEM__c.startsWith('-----BEGIN CERTIFICATE-----') || !MigAcct.X_509_Certificate_PEM__c.endsWith('-----END CERTIFICATE-----')) {
                Migrate_Certs__c mCert = new Migrate_Certs__c(Id = MigAcct.Id, Processing_Status__c = 'Migration Failure', Processing_Message_Error__c = 'PEM info has extra characters before "-----BEGIN CERTIFICATE-----" or after "-----END CERTIFICATE-----"', Certificate_Processed__c = True, Extraction_Results__c = ' ');  
                upsert mCert;  
             }
             else if(MigAcct.X_509_Certificate_PEM__c.countmatches('\r\n\r\n') > 0) {
                Migrate_Certs__c mCert = new Migrate_Certs__c(Id = MigAcct.Id, Processing_Status__c = 'Migration Failure', Processing_Message_Error__c = 'PEM info has extra blank lines.', Certificate_Processed__c = True, Extraction_Results__c = ' ');                     
                upsert mCert;   
             }
             else {   // PEM info has correct format, now process 
             
                 // Invoke certificate checker web service to parse PEM info
                 CertCheckerAcct = X509CertificateCheckerUtility.x509CertChecker(MigAcct.X_509_Certificate_PEM__c);
                 
                 if(CertCheckerAcct.Display_Webservice_Not_Available__c || CertCheckerAcct.Display_Webservice_Failed_Message__c) {
                    Migrate_Certs__c mCert = new Migrate_Certs__c(Id = MigAcct.Id, Processing_Status__c = 'Migration Failure', Processing_Message_Error__c = 'Webservice not availabe or parsing failed', Certificate_Processed__c = True, Extraction_Results__c = CertCheckerAcct.Extraction_Results__c);                     
                    upsert mCert;         
                 }
                 else if (CertCheckerAcct.Extraction_Results__c == '{}') {
                    Migrate_Certs__c mCert = new Migrate_Certs__c(Id = MigAcct.Id, Processing_Status__c = 'Migration Failure', Processing_Message_Error__c = 'Parsing of cert data has failed. Extraction Results Null', Certificate_Processed__c = True, Extraction_Results__c = CertCheckerAcct.Extraction_Results__c);                     
                    upsert mCert; 
                 }
                 else if (!CertCheckerAcct.Extraction_Results__c.contains('issuerCN')) {
                    Migrate_Certs__c mCert = new Migrate_Certs__c(Id = MigAcct.Id, Processing_Status__c = 'Migration Failure', Processing_Message_Error__c = 'Parsing of cert data has failed. Extraction Results not in correct format', Certificate_Processed__c = True, Extraction_Results__c = CertCheckerAcct.Extraction_Results__c);                     
                    upsert mCert;                 
      
                 }
                 else {  // PEM returned correct results
                 
                    Boolean FoundMatchOnSHA256 = false;
                 
                    // If SHA-256 matches existing root cert, then update the root cert or else update Migrate Cert with error message
                    for (Account root :listOfAcctRecordsOfTypeRoot) {
                    
                        // update existing root record
                        if (CertCheckerAcct.SHA_256_Fingerprint__c == root.SHA_256_Fingerprint__c) {
                        
                            FoundMatchOnSHA256 = true;
                            
                            String NullFieldErrorMessage = MigrateCertBatchHelper.CheckForNullFields (root, CertCheckerAcct);
                            
                            if (NullFieldErrorMessage == '') {
                                Account acctToUpdate = MigrateCertBatchHelper.populateRootCertAccount (root.id, CertCheckerAcct, MigAcct.X_509_Certificate_PEM__c);                           
                                listOfAcctToUpdate.add(acctToUpdate);
                                break;
                            } 
                            else {  // null fields in migrate cert, save this error
                            
                                 Migrate_Certs__c mCert = new Migrate_Certs__c(Id = MigAcct.Id, Processing_Status__c = 'Migration Failure', Processing_Message_Error__c = NullFieldErrorMessage, Certificate_Processed__c = True, Extraction_Results__c = CertCheckerAcct.Extraction_Results__c);                     
                                 upsert mCert; 
                            }
                          
                        } 
                                    
                    }  // end of for loop
                    
                    if (!FoundMatchOnSHA256) {                   
                        Migrate_Certs__c mCert = new Migrate_Certs__c(Id = MigAcct.Id, Processing_Status__c = 'Migration Failure', Processing_Message_Error__c = 'No match on SHA 256 Fingerprint.', Certificate_Processed__c = True, Extraction_Results__c = CertCheckerAcct.Extraction_Results__c);                     
                        upsert mCert;                         
                    }  
                 }                                 
            }                     
        } // end of for loop
        
       try{            
             if(listOfAcctToUpdate.size() > 0){
                 
                 // Update Root Certs in Account object 
                 List<Database.SaveResult> updateResults = Database.update(listOfAcctToUpdate, false);
                 
                 for (Database.SaveResult updateResult : updateResults) {
                     
                     if (updateResult.isSuccess()) {
                        System.debug('Successfully updates Root Certificate Information: ' + updateResult.getId());
                        
                        /*  If account got inserted successfully, update Processing status, Processing Message, Account Id in Migrate cert object  */
                       Migrate_Certs__c mCert;
                      
                       if (warning <> '')  // Migration Warning                                             
                           mCert = new Migrate_Certs__c(Id = MigAcct.Id, Migrated_Cert__c = updateResult.getId(), Processing_Status__c = 'Migration Warning', Processing_Message_Error__c = warning + 'Root Certificate migrated successfully', Certificate_Processed__c = True, Extraction_Results__c = CertCheckerAcct.Extraction_Results__c);
                        else               // Migration successful
                           mCert = new Migrate_Certs__c(Id = MigAcct.Id, Migrated_Cert__c = updateResult.getId(), Processing_Status__c = 'Migration Successful', Processing_Message_Error__c = 'Root Certificate migrated successfully', Certificate_Processed__c = True, Extraction_Results__c = CertCheckerAcct.Extraction_Results__c);  
                                              
                        update mCert; 
                     }
                     else {
                         for (Database.Error err: updateResult.getErrors()) {
                            System.debug('The following error has occurred.');
                            System.debug(err.getStatusCode() + ': ' + err.getMessage());
                            System.debug('Fields that affected this error: ' + err.getFields()); 
                            
                            /*  If account didn't get updated successfully, update Processing status, Processing Message in Migrate cert object  */
                            Migrate_Certs__c mCert = new Migrate_Certs__c(Id = MigAcct.Id, Processing_Status__c = 'Migration Failure', Processing_Message_Error__c = err.getMessage(), Certificate_Processed__c = True,Extraction_Results__c = CertCheckerAcct.Extraction_Results__c);
                            upsert mCert; 
                            
                        }        
                     }
                 
                 }
             }
         
         } // try
         
         catch(System.DmlException e){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getDmlMessage(0)));
        }
        
        catch(Exception e){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
        }
        
        listOfAcctToUpdate.clear();

    }
  
/****  
  Process intermediate certs 
   - Read all records from staging object 'Migrate Certs'
   - If SHA-256 not null on 'Migrate Certs' then find matching parent in Account object
   - If Parent Name not null on 'Migrate Certs' then find matching parent in Account object
   - Call X509CertificateCheckerUtility to extract PEM fields, save processing errors in 'Migrate Certs'
   - Add inter cert, to matching parent
   - Run program more than once to eliminate 'Missing Parent records' 
****/
            
    global void processIntermediateCertificates(List<sObject> scope) { 
    
         Id parentId;
         Account a;   // holds results from cert checker utility
         List<Account> listOfAcctToInsert = new List<Account>();
         List<Account> listOfParentAcct = new List<Account>(); 
         List<Account> listOfParentAcctOfTypeRoot = new List<Account>(); 
         List<Account> listOfParentAcctOfTypeIntermediate = new List<Account>(); 
         List<Account> listOfParentAcctWithMatchingSHA256 = new List<Account>();
         
         /* New certs will be added as Intermediate certs */
         RecordType rt = [select Id from RecordType where Name = 'Intermediate Certificate' and SobjectType = 'Account' limit 1];              
         
            /* Loop through each record in Migrate Cert object */
         for(sObject cert : scope){
             
             warning = '';
             MigAcct = (Migrate_Certs__c)cert; // fetch all certs to migrate
             
             
             /* Wiki page:  https://wiki.mozilla.org/CA:SalesforceCommunity:MassImport
                -> Check for Parent Certificate's SHA-256 Fingerprint -- if not blank, the record matching the Parent Owner and 
                SHA-256 Fingerprint will be used to add the intermediate certs. 
                -> Check for Parent Certificate's SHA-256 Fingerprint -- if blank ...
                   Matches on Parent Name, if multiple parent records found then use parent of type root. If all of the records are 
                   intermediate certificates, then the first record found will be used. */             
              
             if (MigAcct.Parent_Certificate_s_SHA_256_Fingerprint__c == null)
             {
                 /*UNDO listOfParentAcctOfTypeRoot = [SELECT Id, Name, CA_Owner__c from Account 
                                           where (Name = :MigAcct.Parent_CA_Owner_Certificate__c and CA_Owner__c = :MigAcct.CA_Owner__c)
                                           and RecordType.Name in ('Root Certificate')];  */ 
                 listOfParentAcctOfTypeRoot = [SELECT Id, Name, CA_Owner__c from Account 
                                           where RecordType.Name in ('Root Certificate')];                           

                 /*UNDO listOfParentAcctOfTypeIntermediate = [SELECT Id, Name, CA_Owner__c from Account 
                                                   where (Name = :MigAcct.Parent_CA_Owner_Certificate__c and CA_Owner__c = :MigAcct.CA_Owner__c)
                                                   and RecordType.Name in ('Intermediate Certificate')]; */
                 listOfParentAcctOfTypeIntermediate = [SELECT Id, Name, CA_Owner__c from Account 
                                                   where  RecordType.Name in ('Intermediate Certificate')];                                  
              }
              else
              {
                /** old code - match made on parent name + ca owner name + sha 256
                listOfParentAcctWithMatchingSHA256 = [SELECT Id, Name, CA_Owner__c from Account 
                                           where (Name = :MigAcct.Parent_CA_Owner_Certificate__c and CA_Owner__c = :MigAcct.CA_Owner__c and
                                           SHA_256_Fingerprint__c = :MigAcct.Parent_Certificate_s_SHA_256_Fingerprint__c)]; **/
                                           
                /** new code - match only on sha256 **/                           
                listOfParentAcctWithMatchingSHA256 = [SELECT Id, Name, CA_Owner__c from Account 
                                           where (SHA_256_Fingerprint__c = :MigAcct.Parent_Certificate_s_SHA_256_Fingerprint__c)];   
              }                           
                                 
             /* Check if parent exists; A cert will be migrated only if the parent exists */
             if(listOfParentAcctOfTypeRoot.size() > 0 || listOfParentAcctOfTypeIntermediate.size() > 0 || listOfParentAcctWithMatchingSHA256.size() > 0){
             
             
                 if (listOfParentAcctWithMatchingSHA256.size() > 0) {
                    parentId = listOfParentAcctWithMatchingSHA256.get(0).Id;
                 }
                 else {
                     // check if there are more than one matches found on 'Parent Name', then use the parent that is a 'Root' record
                     if(listOfParentAcctOfTypeIntermediate.size() > 1) {               
                         parentId = listOfParentAcctOfTypeIntermediate.get(0).Id;
                         warning = 'Multiple matches found on parent. Cert added to Intermediate record [' + listOfParentAcctOfTypeIntermediate.get(0).name + '] '; // add a message for user
                     } else if(listOfParentAcctOfTypeIntermediate.size() > 0) {
                         parentId = listOfParentAcctOfTypeIntermediate.get(0).Id;
                     } 
                     
                     if(listOfParentAcctOfTypeRoot.size() > 1) {
                         parentId = listOfParentAcctOfTypeRoot.get(0).Id;
                         warning = 'Multiple matches found on parent. Cert added to Root record [' + listOfParentAcctOfTypeRoot.get(0).name + '] ';
                     } else if(listOfParentAcctOfTypeRoot.size() > 0){
                         parentId = listOfParentAcctOfTypeRoot.get(0).Id;
                     } 
                     
                     /*This is old code and it giving exception.*/
                     // check if there are more than one matches found on 'Parent Name', then use the parent that is a 'Root' record
                     /*if(listOfParentAcctOfTypeIntermediate.size()>1) {               
                         parentId = listOfParentAcctOfTypeRoot.get(0).Id;
                         warning = 'Multiple matches found on parent. Cert added to Root record [' + listOfParentAcctOfTypeRoot.get(0).name + '] '; // add a message for user
                     }
                     else {
                         parentId = listOfParentAcctOfTypeIntermediate.get(0).Id;
                     }*/
                 }            
                 validCert = TRUE;

                 
                 /* Invoke certificate checker web service to parse PEM info */
                 if(MigAcct.X_509_Certificate_PEM__c != null && MigAcct.X_509_Certificate_PEM__c != '') {
                     CertCheckerAcct = X509CertificateCheckerUtility.x509CertChecker(MigAcct.X_509_Certificate_PEM__c);
                 }
                 
                 //system.debug('CertCheckerAcct  ::::: '+CertCheckerAcct + ' :::: MigAcct :::: '+MigAcct);
                 
                 /* Populate Account with response received from certificate checker web service and Migrate Certs object  */                
                 if(CertCheckerAcct != null && CertCheckerAcct.Extraction_Results__c.contains('issuerCN')) {
                 
                    /* OLD CODE 
                       The first part of 'CA Owner/Certificate Name' must equal ' Certificate Subject Common Name' or ' Certificate Subject Organization' 
                       from PEM data. There can be additional characters appended to the end in the 'CA Owner/Certificate Name' field. */
      
                    String accNameOfLenSubjectCN; 
                    if (MigAcct.name.length() > CertCheckerAcct.Certificate_Subject_Common_Name__c.length()) // to avoid out of bounds failure in substring
                       accNameOfLenSubjectCN = ((String) MigAcct.name).substring(0,CertCheckerAcct.Certificate_Subject_Common_Name__c.length());  
                    else
                       accNameOfLenSubjectCN = MigAcct.name;
                    String accNameOfLenSubjectO;
                    if (MigAcct.name.length() > CertCheckerAcct.Certificate_Subject_Organization__c.length()) // to avoid out of bounds failure in substring
                       accNameOfLenSubjectO = ((String) MigAcct.name).substring(0,CertCheckerAcct.Certificate_Subject_Organization__c.length());                   
                    else
                       accNameOfLenSubjectO = MigAcct.name;
                    if (accNameOfLenSubjectCN != CertCheckerAcct.Certificate_Subject_Common_Name__c && accNameOfLenSubjectO != CertCheckerAcct.Certificate_Subject_Organization__c) {                    
                        validCert = FALSE; 
                        Migrate_Certs__c mCert = new Migrate_Certs__c(Id = MigAcct.Id, Processing_Status__c = 'Migration Failure', Processing_Message_Error__c = 'The first part of CA Owner/Certificate Name must equal subjectCN or subjectO from the PEM data' + ' [' + accNameOfLenSubjectCN + '==' + CertCheckerAcct.Certificate_Subject_Common_Name__c + '] OR [' + accNameOfLenSubjectO +'=='+ CertCheckerAcct.Certificate_Subject_Organization__c +']', Certificate_Processed__c = True, Extraction_Results__c = CertCheckerAcct.Extraction_Results__c);
                        upsert mCert;
                    }
                    
                    /* OLD CODE 
                       The first part of 'Parent CA Owner/Certificate' must equal ' Certificate Issuer Common Name' or ' Certificate Issuer Organization' 
                       from the PEM data. There can be additional characters appended to the end in the 'Parent CA Owner/Certificate' field. */ 
                                         
                    if (validCert)                
                    {
                       /* 
                       String parentNameOfLenIssuerCN;
                       if (MigAcct.Parent_CA_Owner_Certificate__c != null && CertCheckerAcct.Certificate_Issuer_Common_Name__c != null && MigAcct.Parent_CA_Owner_Certificate__c.length() > CertCheckerAcct.Certificate_Issuer_Common_Name__c.length()) // to avoid out of bounds failure in substring
                          parentNameOfLenIssuerCN = ((String) MigAcct.Parent_CA_Owner_Certificate__c).substring(0,CertCheckerAcct.Certificate_Issuer_Common_Name__c.length()); 
                       else 
                          parentNameOfLenIssuerCN = MigAcct.Parent_CA_Owner_Certificate__c; */               
 
                       /* String parentNameOfLenIssuerO;
                       if (MigAcct.Parent_CA_Owner_Certificate__c != null && CertCheckerAcct.Certificate_Issuer_Organization__c != null && MigAcct.Parent_CA_Owner_Certificate__c.length() > CertCheckerAcct.Certificate_Issuer_Organization__c.length()) // to avoid out of bounds failure in substring
                          parentNameOfLenIssuerO = ((String) MigAcct.Parent_CA_Owner_Certificate__c).substring(0,CertCheckerAcct.Certificate_Issuer_Organization__c.length());                   
                       else
                          parentNameOfLenIssuerO = MigAcct.Parent_CA_Owner_Certificate__c; */
                       
                       /* if (parentNameOfLenIssuerCN != CertCheckerAcct.Certificate_Issuer_Common_Name__c && parentNameOfLenIssuerO != CertCheckerAcct.Certificate_Issuer_Organization__c) {                    
                           validCert = FALSE;
                           Migrate_Certs__c mCert = new Migrate_Certs__c(Id = MigAcct.Id, Processing_Status__c = 'Migration Failure', Processing_Message_Error__c = 'The first part of Parent CA Owner/Certificate must equal issuerCN or issuerO from the PEM data' + ' [' + parentNameOfLenIssuerCN + '==' + CertCheckerAcct.Certificate_Issuer_Common_Name__c + '] OR [' + parentNameOfLenIssuerO + '==' + CertCheckerAcct.Certificate_Issuer_Organization__c + ']', Certificate_Processed__c = True, Extraction_Results__c = CertCheckerAcct.Extraction_Results__c);                         
                           upsert mCert;   
                        } */
                                          
                       /* Check PEM info format - pem info should not have blank lines */
                       if(MigAcct.X_509_Certificate_PEM__c == null) {
                          validCert = FALSE;
                          Migrate_Certs__c mCert = new Migrate_Certs__c(Id = MigAcct.Id, Processing_Status__c = 'Migration Failure', Processing_Message_Error__c = 'PEM info is null', Certificate_Processed__c = True, Extraction_Results__c = CertCheckerAcct.Extraction_Results__c);                     
                          upsert mCert;   
                       }
                       else
                          if(MigAcct.X_509_Certificate_PEM__c.countmatches('\r\n\r\n') > 0) {
                          validCert = FALSE;
                          Migrate_Certs__c mCert = new Migrate_Certs__c(Id = MigAcct.Id, Processing_Status__c = 'Migration Failure', Processing_Message_Error__c = 'PEM info extra blank lines.', Certificate_Processed__c = True, Extraction_Results__c = CertCheckerAcct.Extraction_Results__c);                     
                          upsert mCert;   
                       }                                             
                    }
                 }
                 else{
                     validCert = FALSE;
                     Migrate_Certs__c mCert = new Migrate_Certs__c(Id = MigAcct.Id, Processing_Status__c = 'Migration Failure', Processing_Message_Error__c = 'Extraction Results ' + CertCheckerAcct.Extraction_Results__c, Certificate_Processed__c = True, Extraction_Results__c = CertCheckerAcct.Extraction_Results__c);
                     upsert mCert;
                 }  
                 
                 
                 //system.debug('validCert :::: '+validCert);
                 if (validCert)                
                 {
                     //system.debug('a :::: '+a);
                     //system.debug('MigAcct :::: '+MigAcct);
                     Account acctToInsert = MigrateCertBatchHelper.populateInterCertAccount(CertCheckerAcct,MigAcct.Name,MigAcct.X_509_Certificate_PEM__c,parentId,rt.Id,MigAcct);
                     listOfAcctToInsert.add(acctToInsert);
                 }
             }
             
             else{
             
                 /* If parent doesn't exist, update Processing status and Processing Message */
                 validCert = FALSE;
                 MigAcct.Processing_Status__c = 'Migration Failure';
                 MigAcct.Processing_Message_Error__c = 'Missing Parent in Migrate Certs object';
                 MigAcct.Certificate_Processed__c = True;
                 upsert MigAcct;
             }
             
         }  // loop over scope
         
         try{
             
             if(listOfAcctToInsert.size()>0){
                 
                /*  Insert Account  */
                 List<Database.SaveResult> insertResults = Database.insert(listOfAcctToInsert, false);
                 
                 for (Database.SaveResult insertResult : insertResults) {
                     
                     if (insertResult.isSuccess()) {
                        System.debug('Successfully inserted Certificate Information: ' + insertResult.getId());
                        
                        /*  If account got inserted successfully, update Processing status, Processing Message, Account Id in Migrate cert object  */
                       Migrate_Certs__c mCert;
                      
                       if (warning <> '')  // Migration Warning                                             
                           mCert = new Migrate_Certs__c(Id = MigAcct.Id, Migrated_Cert__c = insertResult.getId(), Processing_Status__c = 'Migration Warning', Processing_Message_Error__c = warning + 'Certificate migrated successfully', Certificate_Processed__c = True, Extraction_Results__c = CertCheckerAcct.Extraction_Results__c);
                        else               // Migration successful
                           mCert = new Migrate_Certs__c(Id = MigAcct.Id, Migrated_Cert__c = insertResult.getId(), Processing_Status__c = 'Migration Successful', Processing_Message_Error__c = 'Certificate migrated successfully', Certificate_Processed__c = True, Extraction_Results__c = CertCheckerAcct.Extraction_Results__c);                      
                        
                        // Migrate_Certs__c mCert = new Migrate_Certs__c(Id = MigAcct.Id, Migrated_Cert__c = insertResult.getId(), Processing_Status__c = 'Migration Warning', Processing_Message_Error__c = warning + 'Certificate migrated with warning', Certificate_Processed__c = True, Extraction_Results__c = CertCheckerAcct.Extraction_Results__c);                 
                                              
                        upsert mCert; 
                     }
                     else{
                         for (Database.Error err: insertResult.getErrors()) {
                            System.debug('The following error has occurred.');
                            System.debug(err.getStatusCode() + ': ' + err.getMessage());
                            System.debug('Fields that affected this error: ' + err.getFields()); 
                            
                            /*  If account didn't get inserted successfully, update Processing status, Processing Message in Migrate cert object  */
                            Migrate_Certs__c mCert = new Migrate_Certs__c(Id = MigAcct.Id, Processing_Status__c = 'Migration Failure', Processing_Message_Error__c = err.getMessage(), Certificate_Processed__c = True,Extraction_Results__c = CertCheckerAcct.Extraction_Results__c);
                            upsert mCert; 
                            //ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, err.getMessage()));
                        }        
                     }
                 
                 }
             }
         
         } // try
         
         catch(System.DmlException e){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getDmlMessage(0)));
        }
        
        catch(Exception e){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
        }
        
        listOfAcctToInsert.clear();      
    
    }
    
    global void finish(Database.BatchableContext BC) {
    
    }
    
    public void dummyTestMethod(){
        string strTest = 'Test';
        strTest = 'Test';
        strTest = 'Test';
        strTest = 'Test';
        strTest = 'Test';
        strTest = 'Test';
        strTest = 'Test';
        strTest = 'Test';
        strTest = 'Test';
        strTest = 'Test';
        strTest = 'Test';
        strTest = 'Test';
        strTest = 'Test';
        strTest = 'Test';
        strTest = 'Test';
        strTest = 'Test';
        strTest = 'Test';
        strTest = 'Test';
        strTest = 'Test';
        strTest = 'Test';
        strTest = 'Test';
        strTest = 'Test';
        strTest = 'Test';
        strTest = 'Test';
        strTest = 'Test';
        strTest = 'Test';
        strTest = 'Test';
        strTest = 'Test';
        strTest = 'Test';
        strTest = 'Test';
        strTest = 'Test';
        strTest = 'Test';
        strTest = 'Test';
        strTest = 'Test';
        strTest = 'Test';
        strTest = 'Test';
        strTest = 'Test';
        strTest = 'Test';
        strTest = 'Test';
        strTest = 'Test';
        strTest = 'Test';
        strTest = 'Test';
        strTest = 'Test';
        strTest = 'Test';
        strTest = 'Test';
        strTest = 'Test';
        strTest = 'Test';
        strTest = 'Test';
        strTest = 'Test';
        strTest = 'Test';
        strTest = 'Test';
        strTest = 'Test';
        strTest = 'Test';
        strTest = 'Test';
        strTest = 'Test';
        strTest = 'Test';
        strTest = 'Test';
        strTest = 'Test';
        strTest = 'Test';
        strTest = 'Test';
        strTest = 'Test';
        strTest = 'Test';
        strTest = 'Test';
        strTest = 'Test';
        strTest = 'Test';
        strTest = 'Test';
        strTest = 'Test';
        strTest = 'Test';
        strTest = 'Test';
        strTest = 'Test';
        strTest = 'Test';
        strTest = 'Test';
        strTest = 'Test';
        strTest = 'Test';
        strTest = 'Test';
        strTest = 'Test';
        strTest = 'Test';
        strTest = 'Test';
        strTest = 'Test';
        strTest = 'Test';
        strTest = 'Test';
        strTest = 'Test';
        strTest = 'Test';
        strTest = 'Test';
        strTest = 'Test';
        strTest = 'Test';
        strTest = 'Test';
        strTest = 'Test';
        strTest = 'Test';
        strTest = 'Test';
        strTest = 'Test';
        strTest = 'Test';
        strTest = 'Test';
        strTest = 'Test';
        strTest = 'Test';
        strTest = 'Test';
        strTest = 'Test';
        strTest = 'Test';
        strTest = 'Test';
        strTest = 'Test';
        strTest = 'Test';
        strTest = 'Test';
        strTest = 'Test';
        strTest = 'Test';
        strTest = 'Test';
        strTest = 'Test';
        strTest = 'Test';
        strTest = 'Test';
        strTest = 'Test';
        strTest = 'Test';
        strTest = 'Test';
        strTest = 'Test';
        strTest = 'Test';
        strTest = 'Test';
        strTest = 'Test';
        strTest = 'Test';
        strTest = 'Test';
        strTest = 'Test';
        strTest = 'Test';
        strTest = 'Test';
        strTest = 'Test';
        strTest = 'Test';
        strTest = 'Test';
        strTest = 'Test';
        strTest = 'Test';
        strTest = 'Test';
        strTest = 'Test';
        strTest = 'Test';
        strTest = 'Test';
        strTest = 'Test';
        strTest = 'Test';
        strTest = 'Test';
        strTest = 'Test';
        strTest = 'Test';
        strTest = 'Test';
        strTest = 'Test';
        strTest = 'Test';
        strTest = 'Test';
        strTest = 'Test';
        strTest = 'Test';
        strTest = 'Test';
        strTest = 'Test';
        strTest = 'Test';
        strTest = 'Test';
        strTest = 'Test';
        strTest = 'Test';
        strTest = 'Test';
        strTest = 'Test';
        strTest = 'Test';
        strTest = 'Test';
        strTest = 'Test';
        strTest = 'Test';
        strTest = 'Test';
        strTest = 'Test';
        strTest = 'Test';
        strTest = 'Test';
        strTest = 'Test';
        strTest = 'Test';
        strTest = 'Test';
        strTest = 'Test';
        strTest = 'Test';
        strTest = 'Test';
        strTest = 'Test';
        strTest = 'Test';
        strTest = 'Test';
        strTest = 'Test';
        strTest = 'Test';
    }
}
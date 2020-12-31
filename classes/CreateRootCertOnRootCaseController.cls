// Controller class for the CreateRootCertOnRootCase VF page. 
// This page is invoked when the user clicks on the "Add/Update PEM Info" button
// from the root case of type "CA Owner/Root Inclusion Request".
// The page would prompt the user to enter the PEM info
// if the PEM info is provided, the cert checker webservice is invoked and update 
// root case record with the response details
// The 'Clone' button also uses this controller (currently unused)

global with sharing class CreateRootCertOnRootCaseController{

 // var which holds the PEM info entered by the user
 public String pemInfoStr {get;set;}
 
 // extraction results returned after processing pem info
 public String extractionResultsStr {get;set;}
 
 // the reference of the record from which the button was clicked
 public Root_Case__c currentRootCaseRecordSo {get;set;}
 
 // the record id from which the create root cert button was clicked
 public Id currentRootCaseIdFromURL {get;set;}
 
 // X509CertificateCheckerUtility returns parsed certifcate info as Account type 
 public Account parsedCertificateSO;//changed visibility to Public for test class
 
 // current root case
 private Root_Case__c RootCaseRecordSo;
 
 public Boolean showBackButton {get;set;}
 
 public Boolean isUpdatePEMInfoFlow {get;set;}
 
 // flag used to enable/disable update button
 public Boolean isCertCheckSuccessful {get;set;}
 
 //property used to enable/disable update button
 public Boolean disableUpdateButton{get;set;}
 
 // constructor
 public CreateRootCertOnRootCaseController(ApexPages.StandardController stdController) {
   
   // get the current root case record id from the URL param
   currentRootCaseIdFromURL= ApexPages.currentPage().getParameters().get('id');
   
   showBackButton = false;
   this.disableUpdateButton = false;
   
   this.currentRootCaseRecordSo = (Root_Case__c)stdController.getRecord();
   
   RootCaseRecordSo = [select name, case_no__c, case_no__r.accountid, recordTypeId, 
                              Root_Certificate_Name__c, CA_Owner_Name_Existing__c, Root_Certificate_Name_Existing__c,
                              SHA_1_Fingerprint__c, Extraction_Results__c,     
                              Valid_To__c, EV_Tested__c, 
                              Trust_Bits__c, Valid_From__c, 
                              Test_Website_Revoked__c, Test_Website_Expired__c, 
                              EV_Policy_OID_s__c, Revocation_Tested__c, 
                              SSL_Validation_Type__c, 
                              Test_Website_Lint_Test__c, 
                              CA_Browser_Forum_Lint_Test__c, 
                              Mozilla_Applied_Constraints__c,  
                              Root_Certificate_Download_URL__c, NSS_Release_When_First_Included__c,
                              Firefox_Release_When_First_Included__c,
                              Comments__c                                                    
                        from Root_Case__c
                        where id =:currentRootCaseRecordSo.id limit 1];
                                             
   
   String isUpdatePEMInfoFlowParam = ApexPages.currentPage().getParameters().get('updatePEMInfo');
   
   if(isUpdatePEMInfoFlowParam!=null && isUpdatePEMInfoFlowParam.length() > 0 && isUpdatePEMInfoFlowParam.equals('true'))
   {
      isUpdatePEMInfoFlow = true;
   }
   else
   {
      isUpdatePEMInfoFlow = false;   
   }

 } 


 public PageReference updateRootCert() {
     
        Root_Case__c rootCaseSO = new Root_Case__c(Id = currentRootCaseIdFromURL);
        
        // if certChecker returns '<Fill in Cert Name>' then keep the current account name
        if (rootCaseSO.Root_Certificate_Name__c == '<Fill in Cert Name>') { 
           rootCaseSO.Root_Certificate_Name__c = RootCaseRecordSo.Root_Certificate_Name__c; 
        } 
                      
        rootCaseSO.X_509_Certificate_PEM__c = pemInfoStr;
               
        try{
         
          // header info  
          rootCaseSO.Root_Certificate_Name__c = parsedCertificateSO.name;
          rootCaseSO.CA_Owner_Name_Existing__c = RootCaseRecordSo.case_no__r.accountid;
                                             
          // Issuer Info
          rootCaseSO.Certificate_Issuer_Common_Name__c = parsedCertificateSO.Certificate_Issuer_Common_Name__c;
          rootCaseSO.OU_From_Issuer_Field__c = parsedCertificateSO.Certificate_Issuer_Organizational_Unit__c;
          rootCaseSO.O_From_Issuer_Field__c = parsedCertificateSO.Certificate_Issuer_Organization__c;
          rootCaseSO.Issuer__c = parsedCertificateSO.Issuer__c;
          
          // Subject Info
          rootCaseSO.Certificate_Subject_Common_Name__c = parsedCertificateSO.Certificate_Subject_Common_Name__c;              
          rootCaseSO.OU_From_Subject_Field__c = parsedCertificateSO.Certificate_Subject_Organization_Unit__c;
          rootCaseSO.O_From_Subject_Field__c = parsedCertificateSO.Certificate_Subject_Organization__c;
          rootCaseSO.Subject__c = parsedCertificateSO.Subject__c;
        
          // Fingerprint Info      
          rootCaseSO.SHA_1_Fingerprint__c = parsedCertificateSO.SHA_1_Fingerprint__c;
          rootCaseSO.SHA_256_Fingerprint__c = parsedCertificateSO.SHA_256_Fingerprint__c;
          rootCaseSO.SPKI_SHA256__c = parsedCertificateSO.SPKI_SHA256__c;
          rootCaseSO.Subject_SPKI_SHA256__c = parsedCertificateSO.Subject_SPKI_SHA256__c;
        
          // Valid From and To Dates
          rootCaseSO.Valid_From__c = parsedCertificateSO.Valid_From_GMT__c;
          rootCaseSO.Valid_To__c = parsedCertificateSO.Valid_To_GMT__c;
         
          // Common fields              
          rootCaseSO.Public_Key_Algorithm__c = parsedCertificateSO.Public_Key_Algorithm__c ;            
          rootCaseSO.Signature_Hash_Algorithm__c = parsedCertificateSO.Signature_Hash_Algorithm__c;
          rootCaseSO.Certificate_Serial_Number__c = parsedCertificateSO.Certificate_Serial_Number__c; 
          //rootCaseSO.Certificate_Fingerprint__c = parsedCertificateSO.Certificate_ID__c;
          //rootCaseSO.Certificate_Version__c = parsedCertificateSO.Certificate_Version__c;
          // rootCaseSO.Basic_Constraints__c = parsedCertificateSO.Basic_Constraints__c;
          rootCaseSO.Key_Usage__c = parsedCertificateSO.Key_Usage__c ;
          rootCaseSO.Extended_Key_Usage__c = parsedCertificateSO.Extended_Key_Usage__c;        
          
          
          // CRL returned by certChecker returns only the portion of the url ending in '.crl' 
          // Do not populate these fields by cert checker response
          //rootCaseSO.CRL_URL_s__c = parsedCertificateSO.CRL_URL_s__c;
          //rootCaseSO.OCSP_URL_s__c = parsedCertificateSO.OCSP_URL_s__c;

          // Checking for technical constrained flag - additional condition to check for null and converted to lower case and then compare with 'yes'
          rootCaseSO.Technically_Constrained__c = parsedCertificateSO.Technically_Constrained__c;
                          
          // Extraction results
          rootCaseSO.Extraction_Results__c = parsedCertificateSO.Extraction_Results__c;
                   
          // Find if Root Certificate exists in Account object by matching PEM info
          List<Account> lstAccounts;
          lstAccounts = [SELECT id, parentid, type, X_509_Certificate_PEM__c                                   
                         FROM Account 
                         WHERE ParentId = :rootCaseSO.CA_Owner_Name_Existing__c AND type = 'Root'];       
           
          rootCaseSO.Root_Certificate_Name_Existing__c = null; 
          for(Account acc : lstAccounts){
              if(acc.X_509_Certificate_PEM__c != null){
                    // remove carriage return and newline characters before comparing PEM info
                    String str1 = acc.X_509_Certificate_PEM__c.replaceall('\r','');
                    str1 = str1.replaceall('\n','');
                    String str2 = rootCaseSo.X_509_Certificate_PEM__c.replaceall('\r','');
                    str2 = str2.replaceall('\n','');
                    if (str1 == str2) {                    
                       rootCaseSO.Root_Certificate_Name_Existing__c = acc.id; // found match on PEM info
                       break;
                    }
                }
            }
                                     
          update rootCaseSO;          
       
        }catch(Exception ex){
            this.disableUpdateButton = true;
            
            String errorMessage;
            /*if (ex.getDmlType(0) == StatusCode.DUPLICATES_DETECTED) {
               errorMessage = 'Update Failed. Update would result in a duplicate Root Certificate. Please use the existing record ' + rootCaseSO.name; 
               ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, errorMessage));    
            }*/
            // else if (ex.getDmlType(0) == StatusCode.FIELD_CUSTOM_VALIDATION_EXCEPTION) {
            //   System.debug('Validation Rule::::'+ ex.getMessage());
            //   errorMessage = 'This PEM data has produced the same \'Extraction Results\' as earlier, so no updates are necessary. Hit \'Cancel\' to return. <br/>';
            //   ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, errorMessage)); 
            // }
            //else {
            errorMessage = 'Error processing!! Please contact your administrator.<br/>' + ex.getMessage();
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, errorMessage)); 
            //}
                   
            // ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, errorMessage));
            showBackButton=true;
            return null;
        }    
     
        PageReference rootCertRecordEditModePage = new PageReference('/' + rootCaseSO.id);
        rootCertRecordEditModePage.setRedirect(true);
        return rootCertRecordEditModePage;
    }


  // method executed on the click on validate pem info
  // this method invokes the rest api and validates the pem info 
  // provided by the user and shows the corresponding success/error message on the page
  
  public PageReference submit() {
  
   try {
       
      if(CommonMethods.validatePEMInfo(pemInfoStr)){
      
          // invoke the cert checker webservice and get the response
          // NOTE: Cert checker utiltiy returns Account type 
          parsedCertificateSO = PEMParserController.parsePEM(pemInfoStr);
               
          // set extractionResultsStr with the value returned by the utility; used by VF page
          extractionResultsStr = parsedCertificateSO.Extraction_Results__c;    
    
          //show the error message if the webservice was not available
          if(parsedCertificateSO.Display_Webservice_Not_Available__c)
          {      
             ApexPages.Message apexMessage = new ApexPages.Message(ApexPages.Severity.Error, 'The webservice for parsing cert data is unavailable at the current moment. Please try again later.');
             ApexPages.addMessage(apexMessage);
             return null;
          }
          
          // show the error message if there were errors parsing the pem info
          if(parsedCertificateSO.Display_Webservice_Failed_Message__c)
          {      
             ApexPages.Message apexMessage = new ApexPages.Message(ApexPages.Severity.Error, 'Parsing of cert data has failed with errors. Please provide correct PEM format for the Root cert.');
             ApexPages.addMessage(apexMessage);
             return null;
          }
          
          // show the error message if the extraction results do not have fields
          if(parsedCertificateSO.Extraction_Results__c == '{}')
          {      
             ApexPages.Message apexMessage = new ApexPages.Message(ApexPages.Severity.Error, 'Parsing of cert data has failed. Please provide correct PEM format for the Root cert.' + ' Extraction Results: ' + parsedCertificateSO.Extraction_Results__c);
             ApexPages.addMessage(apexMessage);
             return null;
          }
          
          // show the error message if the extraction results does not look right
          //this is condition commented because of new tls observatory change.
          /*if(!parsedCertificateSO.Extraction_Results__c.contains('issuerCN'))
          {      
             ApexPages.Message apexMessage = new ApexPages.Message(ApexPages.Severity.Error, 'Parsing of cert data has failed. Please provide correct PEM format for the Root cert.' + ' Extraction Results: ' + parsedCertificateSO.Extraction_Results__c);
             ApexPages.addMessage(apexMessage);
             return null;
          }*/
          /******** 
          // SHA-1 fingerprint of this record must match the value extracted by X509CertificateCheckerUtility
          if((!String.isBlank(RootCaseRecordSo.SHA_1_Fingerprint__c)) && RootCaseRecordSo.SHA_1_Fingerprint__c <> parsedCertificateSO.SHA_1_Fingerprint__c){
              this.isCertCheckSuccessful = true;
              this.disableUpdateButton = true;
              String errorMessage = '<br/>Extracted SHA-1 Fingerprint (shown below) does not match the value in the certificate record. Hit \'Cancel\' to return.<br/>' + '<br/>Certificate Name: ' + parsedCertificateSO.Name + '<br/>Certificate Issuer Common Name: ' + parsedCertificateSO.Certificate_Issuer_Common_Name__c + '<br/>SHA-1 Fingerprint: ' + parsedCertificateSO.SHA_1_Fingerprint__c;
              ApexPages.Message apexMessage = new ApexPages.Message(ApexPages.Severity.WARNING, errorMessage);
              ApexPages.addMessage(apexMessage);
              return null;
          } 
          *********/
          
          // show success message if there were no errors
          ApexPages.addMessage(
          new ApexPages.Message(ApexPages.Severity.Confirm,'Cert Check is successful. Please proceed by clicking on the \'Update Root Case\' button.'));
          
          // set the boolean flag to show/hide buttons accordingly     
          isCertCheckSuccessful=true;
    
          return null; 
      }
    }
   catch (Exception ex) {
     // throw exception messages
     ApexPages.addMessages(ex);

   }
   
  return null;  

 }
 
  //clone the root cert record on root case object and clear all the pem info field and verified fields
 public PageReference cloneRootCase() {
 
  Root_Case__c cloneRootCaseSO = new Root_Case__c();
 
  cloneRootCaseSo.Root_Certificate_Name__c = '<Fill in Cert Name>'; 
  cloneRootCaseSo.case_no__c = RootCaseRecordSo.case_no__c; 
  cloneRootCaseSo.recordTypeId = RootCaseRecordSo.recordTypeId;  
  cloneRootCaseSo.CA_Owner_Name_Existing__c = RootCaseRecordSo.CA_Owner_Name_Existing__c;  
  cloneRootCaseSo.Root_Certificate_Name_Existing__c = RootCaseRecordSo.Root_Certificate_Name_Existing__c;
  //cloneRootCaseSo.CP__c = RootCaseRecordSo.CP__c; 
  //cloneRootCaseSo.CP_Doc_Language__c = RootCaseRecordSo.CP_Doc_Language__c;
  //cloneRootCaseSo.CPS__c = RootCaseRecordSo.CPS__c;
  //cloneRootCaseSo.CPS_Doc_Language__c = RootCaseRecordSo.CPS_Doc_Language__c;
  //cloneRootCaseSo.CRL_URL_s__c = RootCaseRecordSo.CRL_URL_s__c; 
  //cloneRootCaseSo.BR_Audit__c = RootCaseRecordSo.BR_Audit__c; 
  //cloneRootCaseSo.EV_Audit__c = RootCaseRecordSo.EV_Audit__c; 
  //cloneRootCaseSo.OCSP_URL_s__c = RootCaseRecordSo.OCSP_URL_s__c;  
  cloneRootCaseSo.EV_Tested__c = RootCaseRecordSo.EV_Tested__c; 
  cloneRootCaseSo.Trust_Bits__c = RootCaseRecordSo.Trust_Bits__c;  
  //cloneRootCaseSo.Auditor_Name__c = RootCaseRecordSo.Auditor_Name__c; 
  //cloneRootCaseSo.CA_Hierarchy__c = RootCaseRecordSo.CA_Hierarchy__c; 
  //cloneRootCaseSo.Test_Website_URL_SSL_or_Example_Cert__c = RootCaseRecordSo.Test_Website_URL_SSL_or_Example_Cert__c; 
  cloneRootCaseSo.Test_Website_Revoked__c = RootCaseRecordSo.Test_Website_Revoked__c; 
  cloneRootCaseSo.Test_Website_Expired__c = RootCaseRecordSo.Test_Website_Expired__c; 
  //cloneRootCaseSo.BR_Audit_Type__c = RootCaseRecordSo.BR_Audit_Type__c; 
  //cloneRootCaseSo.Cross_Signing__c = RootCaseRecordSo.Cross_Signing__c; 
  //cloneRootCaseSo.EV_Audit_Type__c = RootCaseRecordSo.EV_Audit_Type__c; 
  //cloneRootCaseSo.Standard_Audit__c = RootCaseRecordSo.Standard_Audit__c; 
  //cloneRootCaseSo.Auditor_Website__c = RootCaseRecordSo.Auditor_Website__c; 
  cloneRootCaseSo.EV_Policy_OID_s__c = RootCaseRecordSo.EV_Policy_OID_s__c; 
  //cloneRootCaseSo.Network_Security__c = RootCaseRecordSo.Network_Security__c; 
  cloneRootCaseSo.Revocation_Tested__c = RootCaseRecordSo.Revocation_Tested__c; 
  //cloneRootCaseSo.Certificate_Summary__c = RootCaseRecordSo.Certificate_Summary__c; 
  cloneRootCaseSo.SSL_Validation_Type__c = RootCaseRecordSo.SSL_Validation_Type__c; 
  //cloneRootCaseSo.Standard_Audit_Type__c = RootCaseRecordSo.Standard_Audit_Type__c; 
  //cloneRootCaseSo.Policy_Documentation__c = RootCaseRecordSo.Policy_Documentation__c; 
  //cloneRootCaseSo.Auditor_Qualifications__c = RootCaseRecordSo.Auditor_Qualifications__c; 
  //cloneRootCaseSo.CA_Document_Repository__c = RootCaseRecordSo.CA_Document_Repository__c; 
  //cloneRootCaseSo.Signing_Key_Parameters__c = RootCaseRecordSo.Signing_Key_Parameters__c;
  cloneRootCaseSo.Test_Website_Lint_Test__c = RootCaseRecordSo.Test_Website_Lint_Test__c; 
  //cloneRootCaseSo.BR_Audit_Statement_Date__c = RootCaseRecordSo.BR_Audit_Statement_Date__c; 
  //cloneRootCaseSo.BR_Commitment_to_Comply__c = RootCaseRecordSo.BR_Commitment_to_Comply__c; 
  //cloneRootCaseSo.EV_Audit_Statement_Date__c = RootCaseRecordSo.EV_Audit_Statement_Date__c; 
  //cloneRootCaseSo.Root_Stores_Included_In__c = RootCaseRecordSo.Root_Stores_Included_In__c; 
  //cloneRootCaseSo.SSL_Verification_Procedures__c = RootCaseRecordSo.SSL_Verification_Procedures__c;
  //cloneRootCaseSo.Other_Relevant_Documents__c = RootCaseRecordSo.Other_Relevant_Documents__c; 
  cloneRootCaseSo.CA_Browser_Forum_Lint_Test__c = RootCaseRecordSo.CA_Browser_Forum_Lint_Test__c; 
  //cloneRootCaseSo.Externally_Operated_SubCAs__c = RootCaseRecordSo.Externally_Operated_SubCAs__c; 
  //cloneRootCaseSo.Organization_Verification_Procedures__c = RootCaseRecordSo.Organization_Verification_Procedures__c; 
  //cloneRootCaseSo.Technical_Constraint_on_3rd_party_Issuer__c = RootCaseRecordSo.Technical_Constraint_on_3rd_party_Issuer__c; 
  cloneRootCaseSo.Mozilla_Applied_Constraints__c = RootCaseRecordSo.Mozilla_Applied_Constraints__c; 
  //cloneRootCaseSo.Multi_Factor_Authentication__c = RootCaseRecordSo.Multi_Factor_Authentication__c;
  //cloneRootCaseSo.SSL_Verification_Procedures__c = RootCaseRecordSo.SSL_Verification_Procedures__c; 
  //cloneRootCaseSo.EV_SSL_Verification_Procedures__c = RootCaseRecordSo.EV_SSL_Verification_Procedures__c;  
  //cloneRootCaseSo.Standard_Audit_Statement_Date__c = RootCaseRecordSo.Standard_Audit_Statement_Date__c; 
  //cloneRootCaseSo.Code_Signing_Subscriber_Verification_Pro__c = RootCaseRecordSo.Code_Signing_Subscriber_Verification_Pro__c;
  //cloneRootCaseSo.Email_Address_Verification_Procedures__c = RootCaseRecordSo.Email_Address_Verification_Procedures__c;
  cloneRootCaseSo.Root_Certificate_Download_URL__c = RootCaseRecordSo.Root_Certificate_Download_URL__c; 
  cloneRootCaseSo.NSS_Release_When_First_Included__c = RootCaseRecordSo.NSS_Release_When_First_Included__c;
  cloneRootCaseSo.Firefox_Release_When_First_Included__c = RootCaseRecordSo.Firefox_Release_When_First_Included__c;
  //cloneRootCaseSo.Publicly_Disclosed_and_Audited_subCAs__c = RootCaseRecordSo.Publicly_Disclosed_and_Audited_subCAs__c;
  cloneRootCaseSo.Comments__c = RootCaseRecordSo.Comments__c;

  // do copy PEM fields and comments
  // cloneRootCaseSo.Certificate_Issuer_Common_Name__c = null;
  // cloneRootCaseSo.OU_From_Issuer_Field__c = null;
  // cloneRootCaseSo.O_From_Issuer_Field__c = null;
  // cloneRootCaseSo.Subject__c = null;  
  // cloneRootCaseSo.SHA_1_Fingerprint__c =  null;
  // cloneRootCaseSo.SHA_256_Fingerprint__c = null;
  // cloneRootCaseSo.Valid_From__c =  null;
  // cloneRootCaseSo.Valid_To__c =  null;  
  // cloneRootCaseSo.Certificate_Serial_Number__c = null;
  // cloneRootCaseSo.Certificate_Version__c = null;
  // cloneRootCaseSo.Certificate_Fingerprint__c = null;
  // cloneRootCaseSo.Public_Key_Algorithm__c = null;
  // cloneRootCaseSo.Certificate_Signature_Algorithm__c = null; 
  // cloneRootCaseSo.Signature_Hash_Algorithm__c = null;
  // cloneRootCaseSo.Extraction_Results__c = null;  
  // cloneRootCaseSo.X_509_Certificate_PEM__c  =  null;
  // cloneRootCaseSo.Valid_From__c = null;
  // cloneRootCaseSo.Valid_To__c = null;
  // cloneRootCaseSo.Comment_By Mozilla_on_Root_Case__c = null;
  

        try{
            insert cloneRootCaseSo;
        }catch(DmlException ex){
            String errorMessage = 'Error in creating cloned root case. Please use the existing record ' + RootCaseRecordSo.name;
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, errorMessage));
            showBackButton=true;
            return null;
        }
        
        
    // PageReference parentRecordPage= isPortalUser == true ? new PageReference('/CACommunity/' + RootCaseRecordSo.id): new PageReference('/' + tempRootCaseSo.id);
    PageReference parentRecordPage= new PageReference('/' + cloneRootCaseSo.id);
    parentRecordPage.setRedirect(true);
    return parentRecordPage;
   
        
 
 }
 
 

/**** 
 // when the user does not provide any pem info 
 // simply create the root cert record and set the name and parentid
 public PageReference skip() {
   
   Account parsedCertificateSO = new Account();
   parsedCertificateSO.parentId = currentRootCaseIdFromURL;
   parsedCertificateSO.name = [select id, name from account where id = :currentRootCaseIdFromURL limit 1].name;
   parsedCertificateSO.recordTypeId= Schema.SObjectType.Account.getRecordTypeInfosByName().get('CA Owner/Root Inclusion Request').getRecordTypeId();
 
    try{
            insert parsedCertificateSO;
       } catch(DmlException ex){
            String errorMessage = ex.getDmlType(0) == StatusCode.DUPLICATES_DETECTED ? 'You are trying to create a duplicate Root Certificate. Please use the existing record ' + parsedCertificateSO.name : '';
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, errorMessage));
            showBackButton=true;
            return null;
       }

     PageReference rootCertRecordEditModePage= new PageReference('/' + parsedCertificateSO.id+'/e');
     rootCertRecordEditModePage.setRedirect(true);
     return rootCertRecordEditModePage;
 
 }  *****/

 // user wants to abort the operation, redirect them to the record
 // from which they landed on this page
 public PageReference cancel() {
   
   Account parsedCertificateSO = new Account();
   
  
   // PageReference parentRecordPage = isPortalUser == true ? new PageReference('/CACommunity/' + currentRootCaseIdFromURL) : new PageReference('/' + currentRootCaseIdFromURL);
   PageReference parentRecordPage = new PageReference('/' + currentRootCaseIdFromURL);
   parentRecordPage.setRedirect(true);
   return parentRecordPage;
 
 }
 
    // function used by javascript to re-render the buttons on the user acceptance of the technical constrained flag - this will toggle the button to enable/disable.
    public void showUpdateButton(){
        
        this.disableUpdateButton = !this.disableUpdateButton;
    }
 
}
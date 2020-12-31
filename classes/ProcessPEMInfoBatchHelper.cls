// This is the helper class for the ProcessPEMInfoBatch class. It 
// processes the PEM info and updates the PEM fields on the record. 
// *** Important *** Validation rule 'Check_PEM_Derived_Fields' must be deactivated
// before starting the batch job.

public class ProcessPEMInfoBatchHelper {

// this method processes each intermediate cert and populates the record id of that root on the inter cert record.
// if the intermediate cert record already has the root cert id populated then it is updated only if the new root cert id 
// is different than the root cert id on the record.

 public static Integer processInterCerts(List<Account> accountSolst) {

    List<Account> toBeUpdatedCertsLst = New List<Account>();
    Account tempCertSO;
        Boolean isCertCheckSuccessful;
    DateTime currentDT = DateTime.now();
    String formattedDt = currentDT.format('MM-dd-yyyy hh:mm:ss');
   try{
    // iterate over each intermediate cert and invoke the cert checker webservice and get the response
    for(Account accountSo: accountSoLst){
    
        isCertCheckSuccessful = true;
        accountSo.ProcessPEMInfoBatch_Message__c = '';
            
        if(accountSo.X_509_Certificate_PEM__c != null ) {
        
          tempCertSO = X509CertificateCheckerUtility.x509CertChecker(accountSo.X_509_Certificate_PEM__c);     
          
          if(tempCertSO.Display_Webservice_Not_Available__c || tempCertSO.Display_Webservice_Failed_Message__c) {      
          system.debug('Webservice not available');
          system.debug('accountid='+accountSo.id);
             accountSo.ProcessPEMInfoBatch_Message__c += 'Error: The webservice for parsing cert data is unavailable at the current moment. Please try again later.';
             isCertCheckSuccessful = false;
          }
     
          if(tempCertSO.Extraction_Results__c == '{}')  {      
            accountSo.ProcessPEMInfoBatch_Message__c += 'Error: Parsing of cert data gave no results. Please provided correct PEM format for the certificate.';
            isCertCheckSuccessful = false;
          }
          
          if(!tempCertSO.Extraction_Results__c.contains('issuerCN')) {      
            accountSo.ProcessPEMInfoBatch_Message__c += 'Error: Extraction results does not look right. Please provided correct PEM format for the certificate.';
            isCertCheckSuccessful = false;
          }
      
          if (isCertCheckSuccessful) {
            accountSo.ProcessPEMInfoBatch_Message__c += 'Message: PEM Info parsing completed successful.';
          } 
          
          accountSo.ProcessPEMInfoBatch_Message__c += ' [' + formattedDt + ']';  
          
          accountSo.Name = tempCertSO.Name; 
          accountSo.Extraction_Results__c = tempCertSO.Extraction_Results__c ;
          accountSo.Display_Warning_or_Message__c = tempCertSO.Display_Warning_or_Message__c;
          accountSo.Display_Webservice_Not_Available__c = tempCertSO.Display_Webservice_Not_Available__c;
          accountSo.Display_Webservice_Failed_Message__c = tempCertSO.Display_Webservice_Failed_Message__c;
          accountSo.Certificate_Issuer_Common_Name__c = tempCertSO.Certificate_Issuer_Common_Name__c;
          accountSo.Certificate_Issuer_Organizational_Unit__c = tempCertSO.Certificate_Issuer_Organizational_Unit__c;
          accountSo.Certificate_Issuer_Organization__c = tempCertSO.Certificate_Issuer_Organization__c;
          accountSo.Certificate_Subject_Common_Name__c = tempCertSO.Certificate_Subject_Common_Name__c;
          accountSo.Certificate_Subject_Organization_Unit__c = tempCertSO.Certificate_Subject_Organization_Unit__c;
          accountSo.Certificate_Subject_Organization__c = tempCertSO.Certificate_Subject_Organization__c;
          //accountSo.Certificate_ID__c = tempCertSO.Certificate_ID__c;
          accountSo.Certificate_Serial_Number__c = tempCertSO.Certificate_Serial_Number__c;
          accountSo.SHA_1_Fingerprint__c = tempCertSO.SHA_1_Fingerprint__c;
          accountSo.SHA_256_Fingerprint__c= tempCertSO.SHA_256_Fingerprint__c;
          //accountSo.Certificate_ID__c= tempCertSO.Certificate_ID__c;
          accountSo.Valid_From_GMT__c = tempCertSO.Valid_From_GMT__c;
          accountSo.Valid_To_GMT__c = tempCertSO.Valid_To_GMT__c;
          accountSo.Certificate_Serial_Number__c = tempCertSO.Certificate_Serial_Number__c; 
          accountSo.Signature_Hash_Algorithm__c = tempCertSO.Signature_Hash_Algorithm__c;
          //accountSo.Basic_Constraints__c = tempCertSO.Basic_Constraints__c;
          accountSo.Public_Key_Algorithm__c = tempCertSO.Public_Key_Algorithm__c;
          accountSo.Key_Usage__c = tempCertSO.Key_Usage__c;
          accountSo.Extended_Key_Usage__c = tempCertSO.Extended_Key_Usage__c;
          //accountSo.OCSP_URL_s__c = tempCertSO.OCSP_URL_s__c;
          accountSo.CRL_URL_s__c = tempCertSO.CRL_URL_s__c;
          accountSo.Technically_Constrained__c = tempCertSO.Technically_Constrained__c;    
  
          
          toBeUpdatedCertsLst.add(accountSO);
    
          system.debug('##### toBeUpdatedCertsLst Size='+toBeUpdatedCertsLst.size());
       
      }  
    }
    }
    catch (Exception ex)
    {
     System.debug('linenumer ' + ex.getLineNumber());    
     System.debug('linenumer ' + ex.getMessage());    
     System.debug('linenumer ' + ex.getStackTraceString());    
     
    
    }
    
    // now bulk update records from current batch
    try {
          if(toBeUpdatedCertsLst.size() > 0) {
             update toBeUpdatedCertsLst; 
             system.debug('##### Total number of certs updated from current batch ='+toBeUpdatedCertsLst.size());
          } 
    } catch(Exception e) {
    
        System.debug('An unexpected error has occurred during bulk update: ' + e.getMessage());    
    }
     
    return toBeUpdatedCertsLst.size();
  }

}
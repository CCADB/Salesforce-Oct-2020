/*
MigrateCertBatchHelper used by MigrateCertsBatch

Populate account from Certificate checker web service and Migrate Certs object

*/

public class MigrateCertBatchHelper{

    /**
    @Method : Populates data in existing certificate record with data provided by CertificateChecker utility and Migrate Certs object
    **/
     public static Account populateInterCertAccount(Account acct, String certName, String pemInfo, Id parentId, Id recTypeId, Migrate_Certs__c migCert){
         Account acctToUpdate = new Account();
         acctToUpdate.Name = certName;
         acctToUpdate.ParentId = parentId;
         acctToUpdate.RecordTypeId = recTypeId;
         acctToUpdate.Extraction_Results__c = acct.Extraction_Results__c ;
         acctToUpdate.Display_Warning_or_Message__c = acct.Display_Warning_or_Message__c;
         acctToUpdate.Display_Webservice_Not_Available__c = acct.Display_Webservice_Not_Available__c;
         acctToUpdate.Display_Webservice_Failed_Message__c = acct.Display_Webservice_Failed_Message__c;
         acctToUpdate.Certificate_Issuer_Common_Name__c = acct.Certificate_Issuer_Common_Name__c;
         acctToUpdate.Certificate_Issuer_Organizational_Unit__c = acct.Certificate_Issuer_Organizational_Unit__c;
         acctToUpdate.Certificate_Issuer_Organization__c = acct.Certificate_Issuer_Organization__c;
         acctToUpdate.Certificate_Subject_Common_Name__c = acct.Certificate_Subject_Common_Name__c;
         acctToUpdate.Certificate_Subject_Organization_Unit__c = acct.Certificate_Subject_Organization_Unit__c;
         acctToUpdate.Certificate_Subject_Organization__c = acct.Certificate_Subject_Organization__c;
         acctToUpdate.SHA_1_Fingerprint__c = acct.SHA_1_Fingerprint__c;
         acctToUpdate.SHA_256_Fingerprint__c= acct.SHA_256_Fingerprint__c;
         //acctToUpdate.Certificate_ID__c= acct.Certificate_ID__c;
         acctToUpdate.Valid_From_GMT__c = acct.Valid_From_GMT__c;
         acctToUpdate.Valid_To_GMT__c = acct.Valid_To_GMT__c;
         // to be deleted acctToUpdate.Signing_Key_Parameters__c = acct.Signing_Key_Parameters__c;
         // to be deleted  acctToUpdate.Signature_Algorithm__c = acct.Signature_Algorithm__c; 
         acctToUpdate.Signature_Hash_Algorithm__c = acct.Signature_Hash_Algorithm__c;
         acctToUpdate.Certificate_Serial_Number__c = acct.Certificate_Serial_Number__c;                        
         //acctToUpdate.Basic_Constraints__c = acct.Basic_Constraints__c;
         acctToUpdate.Public_Key_Algorithm__c = acct.Public_Key_Algorithm__c;
         acctToUpdate.Key_Usage__c = acct.Key_Usage__c;
         acctToUpdate.Extended_Key_Usage__c = acct.Extended_Key_Usage__c;
         //acctToUpdate.OCSP_URL_s__c = acct.OCSP_URL_s__c;
         acctToUpdate.CRL_URL_s__c = acct.CRL_URL_s__c;
         acctToUpdate.Technically_Constrained__c = acct.Technically_Constrained__c;        
         
         acctToUpdate.Status__c = 'Provided by CA';
         
         if(acct.Revocation_Status__c == 'None'){
             acctToUpdate.Revocation_Status__c = 'Not Revoked';
         }
         else{
             acctToUpdate.Revocation_Status__c = migCert.Revocation_Status__c;
         }
                 
        acctToUpdate.Date_of_Revocation__c = migCert.Date_of_Revocation__c ;        
        acctToUpdate.RFC_5280_Revocation_Reason_Code__c = migCert.RFC_5280_Revocation_Reason_Code__c;
        acctToUpdate.Audits_Same_as_Parent__c = migCert.Audits_Same_as_Parent__c;
        acctToUpdate.Standard_Audit__c = migCert.Standard_Audit__c;
        acctToUpdate.Standard_Audit_Type__c = migCert.Standard_Audit_Type__c;
        acctToUpdate.Standard_Audit_Statement_Date__c = migCert.Standard_Audit_Statement_Date__c;
        acctToUpdate.BR_Audit__c = migCert.BR_Audit__c;
        acctToUpdate.BR_Audit_Type__c = migCert.BR_Audit_Type__c;
        acctToUpdate.BR_Audit_Statement_Date__c = migCert.BR_Audit_Statement_Date__c; 
        acctToUpdate.Auditor__c = migCert.Auditor__c;
        acctToUpdate.Auditor_Website__c = migCert.Auditor_Website__c;
        acctToUpdate.Auditor_Qualifications__c = migCert.Auditor_Qualifications__c;
        //acctToUpdate.Management_Assertions_By__c = migCert.Management_Assertions_By__c;
        acctToUpdate.EV_Audit__c = migCert.EV_Audit__c;
        acctToUpdate.EV_Audit_Type__c = migCert.EV_Audit_Type__c;
        acctToUpdate.EV_Audit_Statement_Date__c = migCert.EV_Audit_Statement_Date__c; 
        acctToUpdate.CP_CPS_Same_as_Parent__c = migCert.CP_CPS_Same_as_Parent__c; 
        acctToUpdate.Policy_Documentation__c = migCert.Policy_Documentation__c;
        acctToUpdate.CA_Document_Repository__c = migCert.CA_Document_Repository__c;
        acctToUpdate.Certificate_Policy_CP__c = migCert.Certificate_Policy_CP__c;
        acctToUpdate.Certification_Practice_Statement_CPS__c = migCert.Certification_Practice_Statement_CPS__c;
        acctToUpdate.Description = migCert.Description__c;
        acctToUpdate.Comments__c = migCert.Comments__c;
        acctToUpdate.X_509_Certificate_PEM__c = pemInfo;
        acctToUpdate.Display_PEM_Info_Warning_Message__c = False;
        if (migCert.Migrated_Certs_OwnerId__c != null)
            acctToUpdate.OwnerId = migCert.Migrated_Certs_OwnerId__c;
         
        return acctToUpdate;
     
     }
     
     public static Account populateRootCertAccount(Id recordId, Account pemInfo, String pemString){
     
         Account acctToUpdate = new Account();      
         
         acctToUpdate.id = recordId;
         acctToUpdate.Certificate_Issuer_Common_Name__c = pemInfo.Certificate_Issuer_Common_Name__c;
         acctToUpdate.Certificate_Issuer_Organizational_Unit__c = pemInfo.Certificate_Issuer_Organizational_Unit__c;
         acctToUpdate.Certificate_Issuer_Organization__c = pemInfo.Certificate_Issuer_Organization__c;
         acctToUpdate.Certificate_Subject_Common_Name__c = pemInfo.Certificate_Subject_Common_Name__c;
         acctToUpdate.Certificate_Subject_Organization_Unit__c = pemInfo.Certificate_Subject_Organization_Unit__c;
         acctToUpdate.Certificate_Subject_Organization__c = pemInfo.Certificate_Subject_Organization__c;
         acctToUpdate.Subject__c = pemInfo.Subject__c; 
         acctToUpdate.SHA_1_Fingerprint__c = pemInfo.SHA_1_Fingerprint__c;
         acctToUpdate.SHA_256_Fingerprint__c= pemInfo.SHA_256_Fingerprint__c;
         //acctToUpdate.Certificate_ID__c= pemInfo.Certificate_ID__c;
         acctToUpdate.Valid_From_GMT__c = pemInfo.Valid_From_GMT__c;
         acctToUpdate.Valid_To_GMT__c = pemInfo.Valid_To_GMT__c;
         // to be deleted acctToUpdate.Signing_Key_Parameters__c = pemInfo.Signing_Key_Parameters__c;         
         // to be deleted acctToUpdate.Signature_Algorithm__c = pemInfo.Signature_Algorithm__c; 
         acctToUpdate.Certificate_Serial_Number__c = pemInfo.Certificate_Serial_Number__c;
         acctToUpdate.Signature_Hash_Algorithm__c = pemInfo.Signature_Hash_Algorithm__c;
         //acctToUpdate.Basic_Constraints__c = pemInfo.Basic_Constraints__c;
         acctToUpdate.Public_Key_Algorithm__c = pemInfo.Public_Key_Algorithm__c;
         acctToUpdate.Key_Usage__c = pemInfo.Key_Usage__c;
         acctToUpdate.Extended_Key_Usage__c = pemInfo.Extended_Key_Usage__c;
         //acctToUpdate.OCSP_URL_s__c = pemInfo.OCSP_URL_s__c;
         acctToUpdate.CRL_URL_s__c = pemInfo.CRL_URL_s__c;
         acctToUpdate.Technically_Constrained__c = pemInfo.Technically_Constrained__c;      
         acctToUpdate.X_509_Certificate_PEM__c = pemString;
         acctToUpdate.Extraction_Results__c = pemInfo.Extraction_Results__c ;
         acctToUpdate.Display_PEM_Info_Warning_Message__c = False;
         acctToUpdate.Display_Warning_or_Message__c = pemInfo.Display_Warning_or_Message__c;
         acctToUpdate.Display_Webservice_Not_Available__c = pemInfo.Display_Webservice_Not_Available__c;
         acctToUpdate.Display_Webservice_Failed_Message__c = pemInfo.Display_Webservice_Failed_Message__c;
      
         return acctToUpdate;
     }
     
     public static String CheckForNullFields (Account ExistingRoot, Account MigrateRoot){
     
         String NullFieldErrorMessage = '';
       
         if (ExistingRoot.Name != null &&
             MigrateRoot.Name == null) {
             NullFieldErrorMessage += 'Certificate Name ';
         }
         
         if (ExistingRoot.Certificate_Subject_Common_Name__c != null &&
             MigrateRoot.Certificate_Subject_Common_Name__c == null) {
             NullFieldErrorMessage += 'Certificate Subject Common Name ';
         }
         
         if (ExistingRoot.Certificate_Subject_Organization__c != null &&
             MigrateRoot.Certificate_Subject_Organization__c == null) {
             NullFieldErrorMessage += 'Certificate Subject Organization ';
         }
         
         if (ExistingRoot.Certificate_Subject_Organization_Unit__c != null &&
             MigrateRoot.Certificate_Subject_Organization_Unit__c == null) {
             NullFieldErrorMessage += 'Certificate Subject Organization Unit ';
         }
         
         if (ExistingRoot.Certificate_Issuer_Common_Name__c != null &&
             MigrateRoot.Certificate_Issuer_Common_Name__c == null) {
             NullFieldErrorMessage += 'Certificate Issuer Common Name ';
         }
         
         if (ExistingRoot.Certificate_Issuer_Organization__c != null &&
             MigrateRoot.Certificate_Issuer_Organization__c == null) {
             NullFieldErrorMessage += 'Certificate Issuer Organization ';
         }
         
         if (ExistingRoot.Certificate_Issuer_Organizational_Unit__c != null &&
             MigrateRoot.Certificate_Issuer_Organizational_Unit__c == null) {
             NullFieldErrorMessage += 'Certificate Issuer Organizational Unit ';
         }
         
         if (ExistingRoot.Subject__c != null &&
             MigrateRoot.Subject__c == null) {
             NullFieldErrorMessage += 'Subject ';
         }
         
         if (ExistingRoot.SHA_1_Fingerprint__c != null &&
             MigrateRoot.SHA_1_Fingerprint__c == null) {
             NullFieldErrorMessage += 'SHA-1 Fingerprint ';
         }
         
         if (ExistingRoot.SHA_256_Fingerprint__c != null &&
             MigrateRoot.SHA_256_Fingerprint__c == null) {
             NullFieldErrorMessage += 'SHA-56 Fingerprint ';
         }
         
         /*if (ExistingRoot.Certificate_ID__c != null &&
             MigrateRoot.Certificate_ID__c == null) {
             NullFieldErrorMessage += 'Certificate ID ';
         }*/
         
         if (ExistingRoot.Valid_From_GMT__c != null &&
             MigrateRoot.Valid_From_GMT__c == null) {
             NullFieldErrorMessage += 'Valid From GMT ';
         }
         
         if (ExistingRoot.Valid_To_GMT__c != null &&
             MigrateRoot.Valid_To_GMT__c == null) {
             NullFieldErrorMessage += 'Valid To GMT ';
         }
         
         if (ExistingRoot.Certificate_Serial_Number__c != null &&
             MigrateRoot.Certificate_Serial_Number__c == null) {
             NullFieldErrorMessage += 'Certificate Serial Number ';
         }
         
         if (ExistingRoot.Signature_Hash_Algorithm__c != null &&
             MigrateRoot.Signature_Hash_Algorithm__c == null) {
             NullFieldErrorMessage += 'Signature Hash Algorithm ';
         }
         
         /*if (ExistingRoot.Basic_Constraints__c != null &&
             MigrateRoot.Basic_Constraints__c == null) {
             NullFieldErrorMessage += 'Basic Constraints ';
         }*/
         
         if (ExistingRoot.Public_Key_Algorithm__c != null &&
             MigrateRoot.Public_Key_Algorithm__c == null) {
             NullFieldErrorMessage += 'Public Key Algorithm ';
         }
         
         /*if (ExistingRoot.OCSP_URL_s__c != null &&
             MigrateRoot.OCSP_URL_s__c == null) {
             NullFieldErrorMessage += 'OCSP URL(s) ';
         }*/
         
         if (ExistingRoot.CRL_URL_s__c != null &&
             MigrateRoot.CRL_URL_s__c == null) {
             NullFieldErrorMessage += 'CRL URL(s) ';
         }
         
       
         if (NullFieldErrorMessage != '')
             NullFieldErrorMessage = 'Exisiting root has data but the migrating cert has following field(s) null: ' + NullFieldErrorMessage;
              
         return NullFieldErrorMessage;
     }
}
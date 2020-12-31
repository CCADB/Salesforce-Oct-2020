/*
    Description: Common Test methods
*/
@isTest
public with sharing class TestUtils {
    
    static testmethod void TestAllMethods(){
        Account acc = getCAOwner();
        insert acc;
        
        getContact(acc.Id);
        
        getRootCertificate(acc.Id);
        
        Auditor__c auditor = getAuditor();
        insert auditor;
        
        getAuditorLocation(auditor.Id);
        
        Case objCase = getCase(acc.Id);
        insert objCase;
        
        getRootCase(objCase.Id, acc.Id);
        
        string strPEM = strPEMInfo;
    }
    
    public static Account getCAOwner() {
        Account parentAccount = new Account();
        parentAccount.recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('CA Owner').getRecordTypeID();
        parentAccount.name = 'ParentAccount'+System.now();
        parentAccount.type = 'Owner';
        parentAccount.phone='2128425500';
        parentAccount.website  = 'https//www.test.com';
        parentAccount.valid_From_GMT__c= date.today()+1;
        parentAccount.valid_to_GMT__c= date.today()+10;
        parentAccount.company_website__c=  'https//www.test.com';
        parentAccount.organizational_type__c=  'Organizational Type';
        parentAccount.geographic_focus__c=  'Geographic focus';
        parentAccount.primary_market_customer_base__c = 'Primary Market';
        return parentAccount;
    }

    public static Contact getContact(ID accountid){
        Contact parentContact = new Contact();
        parentcontact.firstname = 'FirstName'+System.now();
        parentcontact.accountid = accountId;
        parentcontact.lastname = 'LastName';
        parentcontact.email= 'LastName@firstname.com';
        parentcontact.phone= '456786588';
        parentcontact.type__c= 'Primary POC';
        
        return parentContact;
    }

    public static Account getRootCertificate(ID parentAccountId){
        Account childAccount = new Account();
        childAccount.recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Root Certificate').getRecordTypeID();
        childAccount.name = 'RootAccount'+System.now();
        childAccount.phone='2128425500';
        childAccount.website  = 'https//www.test.com';
        childAccount.valid_From_GMT__c= date.today()+1;
        childAccount.valid_to_GMT__c= date.today()+10;
        childAccount.company_website__c=  'https//www.test.com';
        childAccount.SHA_1_Fingerprint__c= '1234567890123456789012345678901234567890';
        childAccount.parentid = parentAccountId;
        return childAccount;
    }
    
    public static Account getIntermediateCertificate(ID parentAccountId){
        Account childAccount = new Account();
        childAccount.recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Intermediate Certificate').getRecordTypeID();
        childAccount.name = 'Intermediate Account'+System.now();
        childAccount.phone='2128425500';
        childAccount.website  = 'https//www.test.com';
        childAccount.valid_From_GMT__c= date.today()+1;
        childAccount.valid_to_GMT__c= date.today()+10;
        childAccount.company_website__c=  'https//www.test.com';
        childAccount.SHA_1_Fingerprint__c= '1234567890123456789012345678901234567890';
        childAccount.parentid = parentAccountId;
        return childAccount;
    }
    
    public static Auditor__c getAuditor(){
        Auditor__c auditor = new Auditor__c();
        auditor.Name = 'WebTrust';
        auditor.Auditor_Status__c = 'Confidence - High';
        auditor.Auditor_Website__c = 'http://www.google.com';
        return auditor;
    }
    public static Auditor_Location__c getAuditorLocation(Id auditorId){
        Auditor_Location__c auditorlocation = new Auditor_Location__c();
        auditorlocation.Name = 'US';
        auditorlocation.Auditor__c = auditorId;
        auditorlocation.Auditor_Location_Status__c = 'Confidence - High';
        return auditorlocation;
    }
    
    public static Case getCase(ID accountId) {
        Case caseSO = new Case(AccountId = accountId); 
        caseSO.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('CA Audit Update Request').getRecordTypeId();
        caseSO.subject = 'test audit request case';
        caseSO.Status = 'Open';
        caseSO.EV_Audit_Type__c = 'WebTrust';
        caseSO.Standard_Audit_Statement_Link__c = 'http://www.google.com/mozilla.stdAudit-external.com';
        caseSO.Standard_Audit_Type__c = 'WebTrust';
        caseSO.Standard_Audit_Statement_Date__c = system.today();
        caseSO.Standard_Audit_Period_Start_Date__c = system.today().addDays(-3);
        caseSO.Standard_Audit_Period_End_Date__c = system.today().addDays(-2);
        caseSO.Standard_Audit_Verified__c = 'Not Verified';
        caseSO.Standard_Audit_Authenticity_Confirmed__c = True;
        
        caseSO.Code_Signing_Audit_Statement_Link__c = 'http://www.google.com/mozilla.stdAudit-external.com';
        caseSO.Code_Signing_Audit_Type__c = 'WebTrust';
        caseSO.Code_Signing_Audit_Statement_Date__c = system.today();
        caseSO.Code_Signing_Audit_Period_Start_Date__c = system.today().addDays(-3);
        caseSO.Code_Signing_Audit_Period_End_Date__c = system.today().addDays(-2);
        caseSO.Code_Signing_Audit_Verified__c = 'Not Verified';
        caseSO.Code_Signing_Audit_Authenticity_Confirm__c = True;
        
        caseSO.BR_Audit_Statement_Link__c = 'http://www.google.com/mozilla.brAudit-external.com';
        caseSO.BR_Audit_Type__c = 'WebTrust';
        caseSO.BR_Audit_Statement_Date__c = system.today();
        caseSO.BR_Audit_Period_Start_Date__c = system.today().addDays(-3);
        caseSO.BR_Audit_Period_End_Date__c = system.today().addDays(-2);
        caseSO.BR_Audit_Statement_Link_Verified__c = 'Not Verified';
        caseSO.BR_Audit_Authenticity_Confirmed__c = True;
        
        caseSO.EV_Audit_Statement_Link__c = 'http://www.google.com/mozilla.evAudit-external.com';
        caseSO.EV_Audit_Type__c = 'Webtrust';
        caseSO.EV_Audit_Statement_Date__c = system.today();
        caseSO.EV_Audit_Period_Start_Date__c = system.today().addDays(-3);
        caseSO.EV_Audit_Period_End_Date__c = system.today().addDays(-2);
        caseSO.EV_Audit_Statement_Link_Verified__c  = 'Not Verified';
        caseSO.EV_Code_Signing_Audit_Auth_Confirmed__c = True;
        
        caseSO.EV_Code_Signing_Audit_Statement_Link__c = 'http://www.google.com/mozilla.evAudit-external.com';
        caseSO.EV_Code_Signing_Audit_Type__c = 'Webtrust';
        caseSO.EV_Code_Signing_Audit_Statement_Date__c = system.today();
        caseSO.EV_Code_Signing_Audit_Period_Start_Date__c = system.today().addDays(-3);
        caseSO.EV_Code_Signing_Audit_Period_End_Date__c = system.today().addDays(-2);
        caseSO.EV_Code_Signing_Verified__c  = 'Not Verified';
        caseSO.EV_SSL_Audit_Authenticity_Confirmed__c = True;
        
        caseSO.Certification_Practice_Statement_Link__c = 'http://www.google.com/mozilla.cpsAudit-external.com';
        
        caseSO.Certificate_Policy_Link__c = 'http://www.google.com/mozilla.cpAudit-external.com';
        caseSO.CP_CPS_Last_Updated_Date__c = system.today().addDays(-1);
        caseSO.CP_CPS_Links_Verified__c = 'Not Verified';
        caseSO.CA_Document_Repository__c = 'Test document repository';
        return caseSO; 
 
    }
   
    public static Root_Case__c getRootCase(ID caseID, Id caOwnerId) {
        Root_Case__c rootCaseSO = new Root_Case__c ();
        rootCaseSO.root_certificate_name__c = 'ChildAccount';
        rootCaseSO.case_no__c = caseID;
        rootCaseSO.CA_Owner_Name_Existing__c = caOwnerId;
        rootCaseSO.Apply_Standard_Audit__c = true;
        rootCaseSO.Apply_BR_Audit__c = true;
        rootCaseSO.Apply_EV_Audit__c = true;
        rootCaseSO.Apply_EV_Code_Signing_Audit__c = true;
        rootCaseSO.Apply_Code_Signing_Audit__c = true;
        
        rootCaseSO.valid_from__c = date.today()+1;
        rootCaseSO.valid_to__c = date.today()+10;
        rootCaseSO.SHA_1_Fingerprint__c = '12:34:56:78:90:12:34:56:78:90:12:34:56:78:90:12:34:56:78:90';
        rootCaseSO.trust_bits__c = 'Websites';
        //rootCaseSO.BR_Audit__c = 'www.company.com/brauditdocument.html';
        rootCaseSO.EV_Policy_OID_s__c = 'Not EV';
        //rootCaseSO.EV_Audit__c = 'www.company.com/evauditdocument.html';
        rootCaseSO.NSS_Release_When_First_Included__c = 'NSS 1.0';
        rootCaseSO.Firefox_Release_When_First_Included__c = 'Firefox 1.0';             
                         
        /*rootCaseSO.O_From_Issuer_Field_Verified__c = 'Verified';  
        rootCaseSO.OU_From_Issuer_Field_Verified__c = 'Verified';   
        rootCaseSO.Certificate_Summary_Verified__c = 'Not Applicable';  
        rootCaseSO.Root_Certificate_Download_URL_Verified__c = 'Verified';  
        rootCaseSO.SHA_1_Fingerprint_Verified__c = 'Verified';  
        rootCaseSO.SHA_256_Fingerprint_Verified__c = 'Verified';   
        rootCaseSO.Valid_From_Verified__c = 'Verified';  
        rootCaseSO.Valid_To_Verified__c = 'Not Applicable';  
        rootCaseSO.Certificate_Version_Verified__c = 'Verified';  
        rootCaseSO.Cert_Signature_Algorithm_Verified__c = 'Verified';   
        rootCaseSO.Signing_Key_Parameters_Verified__c = 'Not Applicable';   
        rootCaseSO.TestWebsiteURLSSLorExCert_Verified__c = 'Verified';         
        rootCaseSO.CRL_URL_Verified__c = 'Verified';  
        rootCaseSO.OCSP_URL_Verified__c = 'Verified';  
        rootCaseSO.Revocation_Tested_Verified__c = 'Verified'; 
        rootCaseSO.CA_Browser_Forum_Lint_Test_Verified__c = 'Verified'; 
        rootCaseSO.Test_Website_Lint_Test_Verified__c = 'Verified';  
        rootCaseSO.Trust_Bits_Verified__c = 'Verified';  
        rootCaseSO.SSL_Validation_Type_Verified__c = 'Not Applicable';  
        rootCaseSO.EV_Policy_OID_s_Verified__c = 'Verified';  
        rootCaseSO.EV_Tested_Verified__c = 'Verified';  
        rootCaseSO.Root_Stores_Included_In_Verified__c = 'Verified';  
        rootCaseSO.Mozilla_Applied_Constraints_Verified__c = 'Verified';  
        rootCaseSO.CA_Hierarchy_Verified__c = 'Verified';  
        rootCaseSO.Externally_Operated_SubCAs_Verified__c = 'Verified';*/  
        rootCaseSO.Cross_Signing_Verified__c = 'Verified';  
        /*rootCaseSO.Tech_Cons_on_3rd_party_Iss_Verified__c = 'Verified'; 
        rootCaseSO.Policy_Documentation_Verified__c = 'Verified';  
        rootCaseSO.CA_Document_Repository_Verified__c = 'Verified'; 
        rootCaseSO.CP_Verified__c = 'Verified' ; 
        rootCaseSO.CPS_Verified__c = 'Verified';  
        rootCaseSO.Other_Relevant_Documents_Verified__c = 'Verified';  
        rootCaseSO.Auditor_Name_Verified__c = 'Verified'; 
        rootCaseSO.Auditor_Website_Verified__c = 'Verified';  
        rootCaseSO.Auditor_Qualifications_Verified__c = 'Verified'; 
        rootCaseSO.Auditor_New_Verified__c = 'Verified';
        rootCaseSO.Auditor_Location_New_Verified__c = 'Verified';
        rootCaseSO.Management_Assertions_By_Verified__c = 'Verified';
        rootCaseSO.Standard_Audit__c = 'http://standardaudit.com'; 
        rootCaseSO.Standard_Audit_Verified__c = 'Verified'; 
        rootCaseSO.Standard_Audit_Type_Verified__c = 'Verified';   
        rootCaseSO.Standard_Audit_Statement_Dt_Verified__c = 'Verified'; 
        rootCaseSO.Standard_Audit_Period_Dates_Verified__c = 'Verified';   
        rootCaseSO.BR_Audit__c = 'http://braudit.com';
        rootCaseSO.BR_Audit_Verified__c = 'Verified';  
        rootCaseSO.BR_Audit_Type_Verified__c = 'Verified';  
        rootCaseSO.BR_Audit_Statement_Date_Verified__c = 'Not Applicable'; 
        rootCaseSO.BR_Audit_Period_Dates_Verified__c = 'Verified'; 
        rootCaseSO.EV_Audit__c = 'http://EVaudit.com';
        rootCaseSO.EV_Audit_Verified__c = 'Verified';              
        rootCaseSO.EV_Audit_Type_Verified__c = 'Verified';              
        rootCaseSO.EV_Audit_Statement_Date_Verified__c = 'Not Applicable';  
        rootCaseSO.EV_SSL_Audit_Period_Dates_Verified__c = 'Verified';             
        rootCaseSO.BR_Commitment_to_Comply_Verified__c = 'Verified';  
        rootCaseSO.BR_Self_Assessment_Verified__c = 'Not Applicable';                         
        rootCaseSO.SSL_Verification_Procedures_Verified__c = 'Verified';               
        rootCaseSO.EV_SSL_Verification_Proc_Verified__c = 'Verified';               
        rootCaseSO.Org_Verification_Procedure_Verified__c = 'Verified';              
        rootCaseSO.Email_Addr_Verification_Proc_Verified__c = 'Not Applicable';               
        rootCaseSO.Code_Signing_Subs_Verif_Proc_Verified__c = 'Verified';               
        rootCaseSO.Multi_Factor_Authentication_Verified__c = 'Verified';               
        rootCaseSO.Network_Security_Verified__c = 'Verified';               
        rootCaseSO.Publ_Discl_Audited_subCAs_Verified__c = 'Not Applicable';*/
        rootCaseSO.Comments_by_Mozilla_on_Root_Case__c = 'Comments on Root';
        return rootCaseSO ;
    } 
    
    public static string strPEMInfo = '-----BEGIN CERTIFICATE-----' +
     'MIIGTDCCBTSgAwIBAgIBDDANBgkqhkiG9w0BAQUFADB/MQswCQYDVQQGEwJFVTEn' +
     'MCUGA1UEChMeQUMgQ2FtZXJmaXJtYSBTQSBDSUYgQTgyNzQzMjg3MSMwIQYDVQQL' +
     'ExpodHRwOi8vd3d3LmNoYW1iZXJzaWduLm9yZzEiMCAGA1UEAxMZQ2hhbWJlcnMg' +
     'b2YgQ29tbWVyY2UgUm9vdDAeFw0wOTAxMjAxMDIwMTlaFw0xOTAxMTgxMDIwMTla' +
     'MIHtMQswCQYDVQQGEwJFUzEiMCAGCSqGSIb3DQEJARYTaW5mb0BjYW1lcmZpcm1h' +
     'LmNvbTFDMEEGA1UEBxM6TWFkcmlkIChzZWUgY3VycmVudCBhZGRyZXNzIGF0IHd3' +
     'dy5jYW1lcmZpcm1hLmNvbS9hZGRyZXNzKTESMBAGA1UEBRMJQTgyNzQzMjg3MSIw' +
     'IAYDVQQLExlodHRwOi8vd3d3LmNhbWVyZmlybWEuY29tMRkwFwYDVQQKExBBQyBD' +
     'YW1lcmZpcm1hIFNBMSIwIAYDVQQDExlBQyBDYW1lcmZpcm1hIENvZGVzaWduIHYy' +
     'MIIBIDANBgkqhkiG9w0BAQEFAAOCAQ0AMIIBCAKCAQEAyNwx4WbAIQBcJThZtBE6' +
     'N9ccwdpjuZ0GyJxkPWmjNRaCDSkobnmbUt5LKshzKIX/wovAjFcn71XNa4NY6DPg' +
     'XHteg5Ff62AsMIbudu/cdsAVUSRJF/+lgVbBQOtxS8qMesNPKoD/cL24z3esDqhR' +
     '1AxtJ2WhdfTmI0SK6EHbGMHJzMrxsvJ7x5sOxU7yHDF3heF5apJRsyAA/hU1kpju' +
     'uUAgmkDhQSod6H+fLyUC2uu+0Ka93C2h6CB5IppZkOJ42E9jtmJgOI9ZOnxMV2Hv' +
     'vrNb1SY8i36DPHGmPCEhGjCn2ezuDCoeQP1LLc22Iea05104BxusEBkOjVES7npq' +
     'lwIBA6OCAmQwggJgMBIGA1UdEwEB/wQIMAYBAf8CAQIwbgYDVR0fBGcwZTAwoC6g' +
     'LIYqaHR0cDovL2NybC5jYW1lcmZpcm1hLmNvbS9jaGFtYmVyc3Jvb3QuY3JsMDGg' +
     'L6AthitodHRwOi8vY3JsMS5jYW1lcmZpcm1hLmNvbS9jaGFtYmVyc3Jvb3QuY3Js' +
     'MB0GA1UdDgQWBBRpGpRyoNGW/z1WKtj+K0cYFZ2w7jCBqwYDVR0jBIGjMIGggBTj' +
     'lPWxTenboSlbV4tNdgZ24dGiiqGBhKSBgTB/MQswCQYDVQQGEwJFVTEnMCUGA1UE' +
     'ChMeQUMgQ2FtZXJmaXJtYSBTQSBDSUYgQTgyNzQzMjg3MSMwIQYDVQQLExpodHRw' +
     'Oi8vd3d3LmNoYW1iZXJzaWduLm9yZzEiMCAGA1UEAxMZQ2hhbWJlcnMgb2YgQ29t' +
     'bWVyY2UgUm9vdIIBADB1BggrBgEFBQcBAQRpMGcwPQYIKwYBBQUHMAKGMWh0dHA6' +
     'Ly93d3cuY2FtZXJmaXJtYS5jb20vY2VydHMvUk9PVC1DSEFNQkVSUy5jcnQwJgYI' +
     'KwYBBQUHMAGGGmh0dHA6Ly9vY3NwLmNhbWVyZmlybWEuY29tMA4GA1UdDwEB/wQE' +
     'AwIBBjAeBgNVHREEFzAVgRNpbmZvQGNhbWVyZmlybWEuY29tMCcGA1UdEgQgMB6B' +
     'HGNoYW1iZXJzcm9vdEBjaGFtYmVyc2lnbi5vcmcwPQYDVR0gBDYwNDAyBgRVHSAA' +
     'MCowKAYIKwYBBQUHAgEWHGh0dHA6Ly9wb2xpY3kuY2FtZXJmaXJtYS5jb20wDQYJ' +
     'KoZIhvcNAQEFBQADggEBADOSqMcVWLnxmZPaWwZlwhnChTwoICkDCiZMrwGEcRHD' +
     'y+XpcOm9LwjHABoEe1RKSefF+KrpGAmYNLy6TpfWvJCemqw0KBpzwKFo8eKjc4pH' +
     'p/RHa+Oq5i0F090drej2IoLpQwzHEpd9Haj0KxSS/e6AZR7FbBykeajt1L8TwptJ' +
     'BJMrEhY6Ov0bsupZweMTbSGVhZDYn3Wau482XnZ1jHvrjA93lTcCpNZoqUxRnLME' +
     '0qeI+b49MKOBILCU3JsVqWd6+eilbeJnqI6B7plxn1K/8ZN68fnlVULGniLe4uG7' +
     '+gzqD4AmWxSyk0FzyggVxtTKx6S/u3BxY9Y/GoPEsf0=' +
     '-----END CERTIFICATE-----';
}
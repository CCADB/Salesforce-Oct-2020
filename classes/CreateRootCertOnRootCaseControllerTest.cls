@isTest
public class CreateRootCertOnRootCaseControllerTest{
    
    static String PEMinfo;
    
    @testsetup
    static void testSetupMethod(){
        // create the parent account  - record type = Owner
         Account parentAccount = getParentAccount();
         parentAccount.Name = 'parent root account 1';
         insert parentAccount;
         
         // create the contact associated with the parent account
         Contact parentContact = getParentContact(parentAccount.id);
         parentContact.firstName = 'parent_firstname';
         parentContact.lastName = 'parent_lastname';
         insert parentContact;
         
         // create the child account - record type = Root
         Account childAccount = getChildAccount(parentAccount.id);
         childAccount.Name = 'child root account 1';
         insert childAccount;
         
         // create a case
         Case accountCaseA = getCase(parentAccount.id, parentContact.id);
         accountCaseA.request_status__c  = 'Initial Request Received';         
         insert accountCaseA;
         accountCaseA.Request_Status__c = 'Data Verified';
         update accountCaseA;
         
         // create the root case and associate it with the case
         Root_Case__c rootCaseA1 = getRootCase(accountCaseA.id,parentAccount.Id,childAccount.Id);
         rootCaseA1.request_status__c   = 'Initial Request Received';         
         rootCaseA1.Apply_Standard_Audit__c = true;
         rootCaseA1.Apply_BR_Audit__c = true;
         rootCaseA1.Apply_EV_Audit__c = true;         
         rootCaseA1.Case_No__c = accountCaseA.Id;
         rootCaseA1.CA_Owner_Name_Existing__c = parentAccount.Id;
         rootCaseA1.Root_Certificate_Name_Existing__c = childAccount.Id;
         rootCaseA1.RecordTypeId = Schema.SObjectType.Root_Case__c.getRecordTypeInfosByName().get('CA Owner/Root Inclusion Request').getRecordTypeID();
         insert rootCaseA1;
    }
    
    static testmethod void test1(){
        
        
        PEMinfo = '-----BEGIN CERTIFICATE-----' +
               'MIID2jCCAsKgAwIBAgIDAjpWMA0GCSqGSIb3DQEBBQUAMEIxCzAJBgNVBAYTAlVT' +
               'MRYwFAYDVQQKEw1HZW9UcnVzdCBJbmMuMRswGQYDVQQDExJHZW9UcnVzdCBHbG9i' +
               'YWwgQ0EwHhcNMTAwNzIyMTUwNTQyWhcNMTcwNzIxMTUwNTQyWjB3MQswCQYDVQQG' +
               'EwJVUzETMBEGA1UEChMKQWV0bmEgSW5jLjEoMCYGA1UECxMfR2VvUm9vdCBDZXJ0' +
               'aWZpY2F0aW9uIEF1dGhvcml0eTEpMCcGA1UEAxMgQWV0bmEgSW5jLiBDZXJ0aWZp' +
               'Y2F0ZSBBdXRob3JpdHkwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQCQ' +
               'tON+e/RhUkbAcFUsFadmEhsZfoHvYN1fDoExp8EK6d6Ry0Yq1zpc8cFj+hT16G9F' +
               'dEERryVrT/0YINaiilnvGRxdgg7YOsxTU1/1ZGm1KGevfJ/pkVXAcBSqK9ncoRUC' +
               'Y5Xuyda2AXrICbC1Yx2fiyKyQ4HI+G9h5NUTnjgUN6kXuTYV1idYQWYXYfiUVPV4' +
               '3tkgh5nvuCF6AcGpjhgd2aHDrfhong/WihhqqojEh/Lq71qtniVtT18V/1Cnp0hO' +
               'R5JyBQDod2bikP0qIQS2UGk0lsJu7mFruqQKc7/geodCD29jX7QD9jXWvrHauYWQ' +
               'COOuVI8Vfsevh83RGJJ5AgMBAAGjgaMwgaAwHwYDVR0jBBgwFoAUwHqYaI2J+6sF' +
               'ZAwRfap9ZbjKzE4wHQYDVR0OBBYEFL7DxXHIoI1iXT0RMidDMWONKCnBMBIGA1Ud' +
               'EwEB/wQIMAYBAf8CAQAwDgYDVR0PAQH/BAQDAgEGMDoGA1UdHwQzMDEwL6AtoCuG' +
               'KWh0dHA6Ly9jcmwuZ2VvdHJ1c3QuY29tL2NybHMvZ3RnbG9iYWwuY3JsMA0GCSqG' +
               'SIb3DQEBBQUAA4IBAQA+PQPSNwgCyo3k7QnSAoZo2FrxAw5wZy2G7BFaby72m7rm' +
               'gX9QbA7RSwpL8zMv8oSoHSsMZKDcCskxAoRVa7wisjTpsgBmaVRjS5w+jDjizQG5' +
               'Sl5c7cdt+3vB6uegE4bIekPXu4nr7iSqmXIIq7x5qHKwS5F8MGMaiZtaidn66j9y' +
               '2VrM7XyAjt5hEJkXAeiMjRZXJ67SQO2K7CXK8BCakEFrznkorMEsJJaF2KagyeP5' +
               '6It8mIE+TDAcmUVYFCiRXXbLAhr1h30mGaog6P3qMZLWh1K8F/30ltoN10igQ35y' +
               'Bx4GG+Ub/zMhkrtTClipcItkEwu7fHEdZN6/wQKh' +
               '-----END CERTIFICATE-----';
               
        PageReference pref = Page.UpdatePemInfoOnRootCase;
        Test.setCurrentPage(pref);
         
        Root_Case__c rootCaseSO = [select name, case_no__c, case_no__r.accountid, recordTypeId, 
                                  Root_Certificate_Name__c, SHA_1_Fingerprint__c, Extraction_Results__c                            
                                  from Root_Case__c where id != null limit 1];
                                  
        Map<String, HttpCalloutMock> endpoint2TestResp = new Map<String,HttpCalloutMock>();
        
        string strResponse = '{"id":25095119,"serialNumber":"0C","version":3,"signatureAlgorithm":"SHA1WithRSA","issuer":{"id":23,"c":["EU"],"o":["AC Camerfirma SA CIF A82743287"],"ou":["http://www.chambersign.org"],"cn":"Chambers of Commerce Root"},"validity":{"notBefore":"2009-01-20T10:20:19Z","notAfter":"2019-01-18T10:20:19Z"},"subject":{"c":["ES"],"o":["AC Camerfirma SA"],"ou":["http://www.camerfirma.com"],"cn":"AC Camerfirma Codesign v2"},"key":{"alg":"RSA","size":2048,"exponent":3},"x509v3Extensions":{"authorityKeyId":"45T1sU3p26EpW1eLTXYGduHRooo=","subjectKeyId":"aRqUcqDRlv89VirY/itHGBWdsO4=","keyUsage":["Certificate Sign","CRL Sign"],"extendedKeyUsage":[],"extendedKeyUsageOID":[],"subjectAlternativeName":[],"crlDistributionPoint":["http://crl.camerfirma.com/chambersroot.crl","http://crl1.camerfirma.com/chambersroot.crl"],"policyIdentifiers":["2.5.29.32.0"],"isTechnicallyConstrained":false},"x509v3BasicConstraints":"Critical","ca":true,"validationInfo":{"Android":{},"Apple":{"isValid":true},"Microsoft":{},"Mozilla":{},"Ubuntu":{}},"firstSeenTimestamp":"2017-06-27T21:26:31.524236Z","lastSeenTimestamp":"2017-06-27T21:26:31.524236Z","hashes":{"sha1":"7240558E1CE4A0C77D4072625596D6749AF9D797","sha256":"9BC4F171FF9AA224F00C799E80490E31010E3475A08FE64DC9A9C4192EB0C0B1","spki-sha256":"0CE5D2685B4A973997E1C75A229DA5814281F09C9F90A9E882337A3A90837FD3","subject-spki-sha256":"BD1B46C7C5253FE92B574FEADF9F555E6E093FA44D652BA8F56549F382B0FBAA","pin-sha256":"DOXSaFtKlzmX4cdaIp2lgUKB8JyfkKnogjN6OpCDf9M="},"ciscoUmbrellaRank":2147483647,"mozillaPolicyV2_5":{"IsTechnicallyConstrained":false}}';
        
        //set mock response
        SingleRequestMock mockrequest = new SingleRequestMock(201, 'Complete', strResponse, null);
        endpoint2TestResp.put('https://tls-observatory.services.mozilla.com/api/v1/certificate', mockrequest);

        MockHttpResponseGenerator multiMockGen = new MockHttpResponseGenerator(endpoint2TestResp);
        
        Test.setMock(HttpCalloutMock.class, multiMockGen);
        
        Test.startTest();
                                  
        ApexPages.CurrentPage().getParameters().put('id', rootCaseSO.Id);
        ApexPages.StandardController standardcontroller = new ApexPages.StandardController(rootCaseSO);
        CreateRootCertOnRootCaseController obj = new CreateRootCertOnRootCaseController(standardcontroller);
        
        ApexPages.CurrentPage().getParameters().put('updatePEMInfo', 'true');
        obj = new CreateRootCertOnRootCaseController(standardcontroller);
        obj.pemInfoStr = null;//condition:1 - null PEM info
        obj.submit();
        
        obj.pemInfoStr = PEMinfo + PEMinfo + PEMinfo + PEMinfo + PEMinfo + PEMinfo + PEMinfo+ PEMinfo + PEMinfo;//condition:2 - PEM info more than 10k chars
        obj.submit();
        
        obj.pemInfoStr = 'ABC -- PEM -- XYZ';//condition:3 - PEM not started with 'BEGIN CERTIFICATE'
        obj.submit();
        
        obj.pemInfoStr = '-----BEGIN CERTIFICATE-----'+ 
        '2VrM7XyAjt5hEJkXAeiMjRZXJ67SQO2K7CXK8BCakEFrznkorMEsJJaF2KagyeP5' +
        '-----BEGIN CERTIFICATE-----';//condition:4 - PEM not started with 'BEGIN CERTIFICATE'
        obj.submit();
        
        obj.pemInfoStr = '--BEGIN CERTIFICATE-- XYZ --END CERTIFICATE--';//condition:3 - PEM not started with 'BEGIN CERTIFICATE'
        obj.submit();
        
        obj.pemInfoStr = 'ABC -----BEGIN CERTIFICATE----- AND -----END CERTIFICATE-----';//condition:3 - PEM not started with 'BEGIN CERTIFICATE'
        obj.submit();
        
        obj.pemInfoStr = '-----BEGIN CERTIFICATE-----                       '+
        +'                                                                \n'+
        +'                                                                \n'+
        +'-----END CERTIFICATE-----';//condition:3 - PEM not started with 'BEGIN CERTIFICATE'
        obj.submit();
        
        obj.pemInfoStr = PEMinfo;
        //obj.parsedCertificateSO.Display_Webservice_Not_Available__c = true;
        obj.submit();
        
        obj.updateRootCert();
        obj.showUpdateButton();
        obj.cancel();
        obj.cloneRootCase();
        
        Test.stopTest();
    }
    
    public static Account getParentAccount() {
        
        Account parentAccount = new Account();
        parentAccount.recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('CA Owner').getRecordTypeID();
        parentAccount.name = 'ParentAccount';
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

    public static Contact getParentContact(ID accountid) {
        
        Contact parentContact = new Contact();
        parentcontact.firstname = 'FirstName';
        parentcontact.accountid = accountId;
        parentcontact.lastname = 'LastName';
        parentcontact.email= 'LastName@firstname.com';
        parentcontact.phone= '456786588';
        parentcontact.type__c= 'Primary POC';
        
        return parentContact;
    }

   public static Account getChildAccount(ID parentAccountId) {
        
        Account childAccount = new Account();
        childAccount.recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Root Certificate').getRecordTypeID();
        childAccount.name = 'ChildAccount';
        childAccount.type = 'Root';
        childAccount.phone='2128425500';
        childAccount.website  = 'https//www.test.com';
        childAccount.valid_From_GMT__c= date.today()+1;
        childAccount.valid_to_GMT__c= date.today()+10;
        childAccount.company_website__c=  'https//www.test.com';
        childAccount.SHA_1_Fingerprint__c= '12:34:56:78:90:12:34:56:78:90:12:34:56:78:90:12:34:56:78:90';
        childAccount.parentid = parentAccountId;
        
        return childAccount;
    }
   public static Case getCase(ID accountId, Id contactID) {
        
        Case caseDetailsSO = new CAse();
        caseDetailsSO.contactid = contactId;
        caseDetailsSO.accountid=accountId;
        caseDetailsSO.subject='test';
        caseDetailsSO.request_status__c = 'Initial Request Received';
        caseDetailsSO.new_contact_name__c='test user';
        caseDetailsSO.new_contact_type__c='Primary POC';
        caseDetailsSO.new_contact_email__c = 'test@test.com' ;
        caseDetailsSO.new_contact_phone__c = '23456789';
        caseDetailsSO.new_contact_department__c = 'CA Program Dept';
        caseDetailsSO.new_contact_title__c = 'CA Program Manager';
        caseDetailsSO.company_website__c = 'https://www.test1233.com';
        caseDetailsSO.organizational_type__c = 'Organizational Type';
        caseDetailsSO.geographic_focus__c= 'Geographic focus';
        //caseDetailsSO.Company_Website_Verified__c = 'Verified';              
        //caseDetailsSO.Organizational_Type_Verified__c = 'Not Applicable';              
        //caseDetailsSO.Organizational_Type_Others_Verified__c = 'Verified';               
        //caseDetailsSO.Geographic_Focus_Verified__c = 'Not Applicable'; 
        //caseDetailsSO.Primary_Market_Customer_Base_Verified__c = 'Verified';              
        //caseDetailsSO.Impact_to_Mozilla_Users_Verified__c = 'Verified';               
        //caseDetailsSO.CA_s_Reponse_to_Recom_Prac_Verified__c = 'Not Applicable';               
        //caseDetailsSO.CA_s_Response_to_Prob_Prac_Verified__c = 'Verified'; 
              
        return caseDetailsSO ;
    }
    
   public static Root_Case__c getRootCase(ID caseID, Id caOwnerId, Id rootAccountId){
         
         Root_Case__c rootCaseSO = TestUtils.getRootCase(CaseID, rootAccountId);
         /*rootCaseSO.root_certificate_name__c = 'ChildAccount';
         rootCaseSO.case_no__c = caseID;
         rootCaseSO.CA_Owner_Name_Existing__c = caOwnerId;
         rootCaseSO.Root_Certificate_Name_Existing__c = rootAccountId;
         rootCaseSO.Apply_Standard_Audit__c = true;
         rootCaseSO.Apply_BR_Audit__c = true;
         rootCaseSO.Apply_EV_Audit__c = true;
         
         rootCaseSO.valid_from__c = date.today()+1;
         rootCaseSO.valid_to__c = date.today()+10;
         rootCaseSO.SHA_1_Fingerprint__c = '12:34:56:78:90:12:34:56:78:90:12:34:56:78:90:12:34:56:78:90';
         rootCaseSO.trust_bits__c = 'Websites';
         rootCaseSO.BR_Audit__c = 'www.company.com/brauditdocument.html';
         rootCaseSO.EV_Policy_OID_s__c = 'Not EV';
         rootCaseSO.EV_Audit__c = 'www.company.com/evauditdocument.html';
         rootCaseSO.NSS_Release_When_First_Included__c = 'NSS 1.0';
         rootCaseSO.Firefox_Release_When_First_Included__c = 'Firefox 1.0';             
                             
         RootCaseSO.O_From_Issuer_Field_Verified__c = 'Verified';  
         RootCaseSO.OU_From_Issuer_Field_Verified__c = 'Verified';   
         RootCaseSO.Certificate_Summary_Verified__c = 'Not Applicable';  
         RootCaseSO.Root_Certificate_Download_URL_Verified__c = 'Verified';  
         RootCaseSO.SHA_1_Fingerprint_Verified__c = 'Verified';  
         RootCaseSO.SHA_256_Fingerprint_Verified__c = 'Verified';   
         RootCaseSO.Valid_From_Verified__c = 'Verified';  
         RootCaseSO.Valid_To_Verified__c = 'Not Applicable';  
         RootCaseSO.Certificate_Version_Verified__c = 'Verified';  
         RootCaseSO.Cert_Signature_Algorithm_Verified__c = 'Verified';   
         RootCaseSO.Signing_Key_Parameters_Verified__c = 'Not Applicable';   
         RootCaseSO.TestWebsiteURLSSLorExCert_Verified__c = 'Verified';         
         RootCaseSO.CRL_URL_Verified__c = 'Verified';  
         RootCaseSO.OCSP_URL_Verified__c = 'Verified';  
         RootCaseSO.Revocation_Tested_Verified__c = 'Verified'; 
         RootCaseSO.CA_Browser_Forum_Lint_Test_Verified__c = 'Verified'; 
         RootCaseSO.Test_Website_Lint_Test_Verified__c = 'Verified';  
         RootCaseSO.Trust_Bits_Verified__c = 'Verified';  
         RootCaseSO.SSL_Validation_Type_Verified__c = 'Not Applicable';  
         RootCaseSO.EV_Policy_OID_s_Verified__c = 'Verified';  
         RootCaseSO.EV_Tested_Verified__c = 'Verified';  
         RootCaseSO.Root_Stores_Included_In_Verified__c = 'Verified';  
         RootCaseSO.Mozilla_Applied_Constraints_Verified__c = 'Verified';  
         RootCaseSO.CA_Hierarchy_Verified__c = 'Verified';  
         RootCaseSO.Externally_Operated_SubCAs_Verified__c = 'Verified';  
         RootCaseSO.Cross_Signing_Verified__c = 'Verified';  
         RootCaseSO.Tech_Cons_on_3rd_party_Iss_Verified__c = 'Verified'; 
         RootCaseSO.Policy_Documentation_Verified__c = 'Verified';  
         RootCaseSO.CA_Document_Repository_Verified__c = 'Verified'; 
         RootCaseSO.CP_Verified__c = 'Verified' ; 
         RootCaseSO.CPS_Verified__c = 'Verified';  
         RootCaseSO.Other_Relevant_Documents_Verified__c = 'Verified';  
         RootCaseSO.Auditor_Name_Verified__c = 'Verified'; 
         RootCaseSO.Auditor_Website_Verified__c = 'Verified';  
         RootCaseSO.Auditor_Qualifications_Verified__c = 'Verified';  
         RootCaseSO.Standard_Audit_Verified__c = 'Verified'; 
         RootCaseSO.Standard_Audit_Type_Verified__c = 'Verified';   
         RootCaseSO.Standard_Audit_Statement_Dt_Verified__c = 'Verified';  
         RootCaseSO.BR_Audit_Verified__c = 'Verified';  
         RootCaseSO.BR_Audit_Type_Verified__c = 'Verified';  
         RootCaseSO.BR_Audit_Statement_Date_Verified__c = 'Not Applicable';  
         RootCaseSO.EV_Audit_Verified__c = 'Verified';              
         RootCaseSO.EV_Audit_Type_Verified__c = 'Verified';              
         RootCaseSO.EV_Audit_Statement_Date_Verified__c = 'Not Applicable';               
         RootCaseSO.BR_Commitment_to_Comply_Verified__c = 'Verified';               
         RootCaseSO.SSL_Verification_Procedures_Verified__c = 'Verified';               
         RootCaseSO.EV_SSL_Verification_Proc_Verified__c = 'Verified';               
         RootCaseSO.Org_Verification_Procedure_Verified__c = 'Verified';              
         RootCaseSO.Email_Addr_Verification_Proc_Verified__c = 'Not Applicable';               
         RootCaseSO.Code_Signing_Subs_Verif_Proc_Verified__c = 'Verified';               
         RootCaseSO.Multi_Factor_Authentication_Verified__c = 'Verified';               
         RootCaseSO.Network_Security_Verified__c = 'Verified';               
         RootCaseSO.Publ_Discl_Audited_subCAs_Verified__c = 'Not Applicable';
         RootCaseSO.Comments_by_Mozilla_on_Root_Case__c = 'Comments on Root';*/
        

        return rootCaseSO ;
    }
}
/**
Test Case for the following Controller Extension:
PEMDataForRootCertsReportController

**/

@isTest 
public class PEMDataForRootCertsReportControllerTest{

    @TestSetup
    static void setupTestData(){
        
        Id intermediateCertId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Intermediate Certificate').getRecordTypeId();
        Id rootCertId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Root Certificate').getRecordTypeId();
        Id caOwnerCertId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('CA Owner').getRecordTypeId();
        
        Account caOwnerAccount = new Account(
        Name = 'AC Camerfirma, S.A.',
        Type = 'Owner',
        RecordTypeId = caOwnerCertId,
        BillingState = 'CA',
        CA_Email_Alias_1__c = 'gestion_soporte@camerfirma.com.junk',
        Company_Website__c = 'http://www.camerfirma.com',
        Geographic_Focus__c = 'Spain',
        Organizational_Type__c = 'Public Corporation',
        Status__c = 'Included',
        Primary_Market_Customer_Base__c = 'Camerfirma S.A. is a commercial CA issuing certificates for companies primarily in Spain. Camerfirma is the digital certification authority for Chambers of Commerce in Spain.',
        Do_NOT_Send_Audit_Reminder__c = false,
        Status_In_Text__c = 'Included',
        Geographic_Focus_255_char__c = 'Spain',
        CA_Owner__c = 'AC Camerfirma, S.A.',
        Display_PEM_Info_Warning_Message__c = false,
        Display_Warning_or_Message__c = false,
        Display_Webservice_Failed_Message__c = false,
        Display_Webservice_Not_Available__c = false,
        Audits_Same_as_Parent__c = false,
        CP_CPS_Same_as_Parent__c = false,
        Technically_Constrained__c = false,
        Microsoft_Contract_Type__c = 'Commercial',
        Microsoft_Status__c = 'Included',
        Microsoft_EV_Enabled__c = false,
        Microsoft_Do_NOT_Send_Audit_Reminder__c = false,
        Standard_Audit_Update_Status__c = 'Not Processed',
        BR_Audit_Update_Status__c = 'Not Processed',
        EV_Audit_Update_Status__c = 'Not Processed',
        Microsoft_Status_In_Text__c = 'Included',
        EV_Code_Signing_Audit_Update_Status__c = 'Not Processed',
        Recognized_CAA_Domains__c = 'camerfirma.com',
        Problem_Reporting_Mechanism__c = 'AC Camerirma offers an email address to provide this information. operaciones@camerfirma.com; gestion_soporte@camerfirma.com',
        Instructions__c = 'CAs cannot directly modify data for their CA Owner records, because the data must first be verified by a root store operator. Follow the instructions here: http://ccadb.org/cas/updates to create an Audit Case and corresponding Audit Root Cases to provide your annual updates to audit, CP/CPS, and test website URLs. At that time you can also update the CAA Domains and Problem Reporting Mechanism. If you need to update this data more frequently, contact your root store operator.');
        
        insert caOwnerAccount;
        
        Account rootAccount = new Account(
        Name = 'Chambers of Commerce Root - 2008',
        Type = 'Root',
        RecordTypeId = rootCertId,
        ParentId = caOwnerAccount.Id,
        BillingState = 'California',
        Approval_Bug__c = 'https://bugzilla.mozilla.org/show_bug.cgi?id=406968',
        Standard_Audit_Type__c = 'WebTrust',
        Auditor__c = 'Auren',
        BR_Audit_Statement_Date__c = Date.newInstance(2016,08,05),
        BR_Audit_Type__c = 'WebTrust',
        //BR_Audit__c = 'https://bugzilla.mozilla.org/attachment.cgi?id=8800807',
        CRL_URL_s__c = '(not present)',
        Certificate_Issuer_Organization__c = 'AC Camerfirma S.A.',
        Certificate_Policy_CP__c = 'http://policy.camerfirma.com/',
        Certification_Practice_Statement_CPS__c = 'http://docs.camerfirma.com/publico/DocumentosWeb/politicas/CPS_V_3_2_5_eng-GB-signed.pdf',
        Comments_by_Mozilla_on_Root__c = 'Chambers of Commerce Root - 2008 will be fully migrated to Chambers of Commerce Root - 2016 by 2020.',
        EV_Audit_Statement_Date__c = Date.newInstance(2016,08,05),
        EV_Audit_Type__c = 'WebTrust',
        //EV_Audit__c = 'https://bugzilla.mozilla.org/attachment.cgi?id=8800811',
        EV_Policy_OID_s__c = '1.3.6.1.4.1.17326.10.14.2.1.2',
        Firefox_Release_When_First_Included__c = 'Firefox 4.0',
        NSS_Release_When_First_Included__c = 'NSS 3.12.9',
        //OCSP_URL_s__c = '(not present)',
        //Publicly_Disclosed_and_Audited_subCAs__c = 'http://www.camerfirma.com/area-de-usuario/jerarquia-politicas-y-practicas-de-certificacion-2/',
        SHA_1_Fingerprint__c = '786A74AC76AB147F9C6A3050BA9EA87EFE9ACE3C',
        SHA_256_Fingerprint__c = '063E4AFAC491DFD332F3089B8542E94617D893D7FE944E10A7937EE29D9693C0',
        //Signature_Algorithm__c = 'SHA-1',
        //Signing_Key_Parameters__c = '4096',
        Standard_Audit_Statement_Date__c = Date.newInstance(2016,06,17),
        //Standard_Audit__c = 'https://bug986854.bmoattachments.org/attachment.cgi?id=8775118',
        Status__c = 'Included',
        Trust_Bits__c = 'Websites;Email',
        //URL_to_Test_Website_or_Example_Cert__c = 'https://www.camerfirma.com',
        Valid_From_GMT__c = Date.newInstance(2008,08,01),
        Valid_To_GMT__c = Date.newInstance(2038,07,31),
        //Root_Stores_Included_In__c = 'Mozilla',
        Auditor_Qualifications__c = 'http://www.webtrust.org/licensed-webtrust-practitioners-international/item64419.aspx',
        Auditor_Website__c = 'http://www.auren.com/',
        Do_NOT_Send_Audit_Reminder__c = false,
        Status_In_Text__c = 'Included',
        //Basic_Constraints__c = 'cA: true, pathLenConstraint: 12',
        CA_Owner__c = 'AC Camerfirma, S.A.',
        Certificate_Issuer_Common_Name__c = 'Chambers of Commerce Root - 2008',
        Certificate_Serial_Number__c = '00a3da427ea4b1aeda',
        Certificate_Subject_Common_Name__c = 'Chambers of Commerce Root - 2008',
        Certificate_Subject_Organization__c = 'AC Camerfirma S.A.',
        Display_PEM_Info_Warning_Message__c = false,
        Display_Warning_or_Message__c = false,
        Display_Webservice_Failed_Message__c = false,
        Display_Webservice_Not_Available__c = false,
        Extended_Key_Usage__c = '(not present)',
        Extraction_Results__c = '',
        Key_Usage__c = 'keyCertSign, cRLSign',
        X_509_Certificate_PEM__c = '-----BEGIN CERTIFICATE-----MIIHTzCCBTegAwIBAgIJAKPaQn6ksa7aMA0GCSqGSIb3DQEBBQUAMIGuMQswCQYD-----END CERTIFICATE-----',
        Audits_Same_as_Parent__c = false,
        CP_CPS_Same_as_Parent__c = false,
        Certificate_Policy_CP_255_char__c = 'http://policy.camerfirma.com/',
        Certification_Practice_Stat_CPS_255_char__c = 'http://docs.camerfirma.com/publico/DocumentosWeb/politicas/CPS_V_3_2_5_eng-GB-signed.pdf',
        Technically_Constrained__c = false,
        Signature_Hash_Algorithm__c = 'sha1WithRSAEncryption',
        Public_Key_Algorithm__c = 'RSA 4096 bits',
        Microsoft_Status__c = 'Included',
        Microsoft_Trust_Bits__c = 'Server Authentication;Client Authentication;Code Signing;Encrypting File System;IP Security Tunnel Termination;IP Security User;Secure Email;Time Stamping',
        Microsoft_EV_Policy_OID_s__c = 'Policy = 1.3.6.1.4.1.17326.10.14.2.1.2, "", 1.3.6.1.4.1.311.60.1.1, "Root Program Flags", 0xc0',
        Microsoft_EKU__c = 'EKU = 1.3.6.1.4.1.311.10.3.4, "Encrypting File System"EKU = 1.3.6.1.5.5.7.3.1, "Server Authentication"EKU = 1.3.6.1.5.5.7.3.2, "Client Authentication"EKU = 1.3.6.1.5.5.7.3.3, "Code Signing"EKU = 1.3.6.1.5.5.7.3.4, "Secure Email"EKU = 1.3.6.1.5.5.7.3.6, "I',
        Microsoft_EV_Enabled__c = true,
        Microsoft_Country_of_Origin__c = 'European Union',
        Subject__c = 'CN=Chambers of Commerce Root - 2008, OU=null, O=AC Camerfirma S.A., C=EU',
        Signature_Hash__c = '2e32bf12551a50a4f43c45178f6b8f03022ccf15',
        Mozilla_Verified_Audit_Date__c = Date.newInstance(2016,06,17),
        Microsoft_Verified_Audit_Date__c = Date.newInstance(2015,06,17),
        Friendly_Name__c = 'Chambers of Commerce Root - 2008',
        Microsoft_Do_NOT_Send_Audit_Reminder__c = false,
        Subject_SPKI_SHA256__c = '849AD3279D9B805A288339468C417744AC1CE2758A6E283A446685384D5D6CD2',
        Standard_Audit_Statement_Internal_Link__c = 'https://ccadb--Mozilla.cs91.my.salesforce.com/servlet/servlet.FileDownload?file=00P2F000000y6AAUAY',
        BR_Audit_Statement_Internal_Link__c = 'https://ccadb--Mozilla.cs91.my.salesforce.com/servlet/servlet.FileDownload?file=00P2F000000y69fUAA',
        EV_Audit_Statement_Internal_Link__c = 'https://ccadb--Mozilla.cs91.my.salesforce.com/servlet/servlet.FileDownload?file=00P2F000000y69eUAA',
        Standard_Audit_Update_Status__c = 'Successful',
        BR_Audit_Update_Status__c = 'Successful',
        EV_Audit_Update_Status__c = 'Successful',
        Test_Website_Valid__c = 'https://www.camerfirma.com',
        Microsoft_Status_In_Text__c = 'Included',
        EV_Code_Signing_Audit_Update_Status__c = 'Not Processed',
        Instructions__c = 'CAs cannot directly modify data for their root certificate records, because the data must first be verified by a root store operator. Follow the instructions here: http://ccadb.org/cas/updates to create an Audit Case and corresponding Audit Root Cases to provide your annual updates to audit, CP/CPS, and test website URLs.',
        Certificate_Subject_Organization_Unit__c = 'Testing',
        Certificate_Issuer_Organizational_Unit__c = 'Testing');
        
        insert rootAccount;
        

        Account account = new Account(
        Name = 'Chambers of Commerce Root - 2008',
        Type = 'Intermediate Certificate',
        RecordTypeId = intermediateCertId,
        ParentId = rootAccount.Id,
        CRL_URL_s__c = '(not present)',
        Certificate_Issuer_Organization__c = 'AC Camerfirma S.A.',
        //OCSP_URL_s__c = '(not present)',
        SHA_1_Fingerprint__c = 'CD03B4683048E364B8E9F7EDD94C78747C3951CA',
        SHA_256_Fingerprint__c = '3666F8049140FDC0A65E809B281A3BE3B10DAFEEFD76B9DDC272A93E83CA5B99',
        Status__c = 'Provided by CA',
        Valid_From_GMT__c = Date.newInstance(2011,12,07),
        Valid_To_GMT__c = Date.newInstance(2038,07,31),
        //Root_Stores_Included_In__c = 'Mozilla',
        Do_NOT_Send_Audit_Reminder__c = false,
        Status_In_Text__c = 'Provided by CA',
        //Basic_Constraints__c = 'cA: true, pathLenConstraint: 12',
        CA_Owner__c = 'AC Camerfirma, S.A.',
        Certificate_Issuer_Common_Name__c = 'Chambers of Commerce Root - 2008',
        Certificate_Serial_Number__c = '00d9083fbba967ca1a',
        Certificate_Subject_Common_Name__c = 'Chambers of Commerce Root - 2008',
        Certificate_Subject_Organization__c = 'AC Camerfirma S.A.',
        Display_PEM_Info_Warning_Message__c = false,
        Display_Warning_or_Message__c = false,
        Display_Webservice_Failed_Message__c = false,
        Display_Webservice_Not_Available__c = false,
        Extended_Key_Usage__c = '(not present)',
        Extraction_Results__c = '',
        Key_Usage__c = 'keyCertSign, cRLSign',
        Revocation_Status__c = 'Not Revoked',
        X_509_Certificate_PEM__c = '-----BEGIN CERTIFICATE-----MIIHTzCCBTegAwIBAgIJANkIP7upZ8oaMA0GCSqGSIb3DQEBCwUAMIGuMQswCQYD-----END CERTIFICATE-----',
        Audits_Same_as_Parent__c = true,
        CP_CPS_Same_as_Parent__c = true,
        Technically_Constrained__c = false,
        Root_Cert_Id__c = rootAccount.Id,
        Signature_Hash_Algorithm__c = 'sha256WithRSAEncryption',
        Public_Key_Algorithm__c = 'RSA 4096 bits',
        Microsoft_EV_Enabled__c = false,
        Subject__c = 'CN=Chambers of Commerce Root - 2008, OU=null, O=AC Camerfirma S.A., C=EU',
        Microsoft_Do_NOT_Send_Audit_Reminder__c = false,
        Subject_SPKI_SHA256__c = '849AD3279D9B805A288339468C417744AC1CE2758A6E283A446685384D5D6CD2',
        Standard_Audit_Update_Status__c = 'Not Processed',
        BR_Audit_Update_Status__c = 'Not Processed',
        EV_Audit_Update_Status__c = 'Not Processed',
        Certificate_Version__c = '3',
        EV_Code_Signing_Audit_Update_Status__c = 'Not Processed',
        Certificate_Subject_Organization_Unit__c = 'Testing',
        Certificate_Issuer_Organizational_Unit__c = 'Testing');
        
        insert account;
    }
    
    
    static testMethod void validateTest() {
        
        PageReference pref = Page.PEMDataForRootCertsWithPEMCSV ;
        Test.setCurrentPage(pref);
        
        Test.startTest();
        
        PEMDataForRootCertsReportController pacrc = new PEMDataForRootCertsReportController();
        pacrc.getCurrentDate();
        
        Test.stopTest();
    }

}
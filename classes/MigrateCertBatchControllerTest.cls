/**************************************************************************************

Test Case for the following Controller Extensions:

MigrateCertBatchController
MigrateCertBatchUpdateCert
MigrateCertsBatch
MigrateCertBatchVF

**/

@isTest(SeeAllData = false)
public class MigrateCertBatchControllerTest {

    static string PEMinfo =  '-----BEGIN CERTIFICATE----- ' +

'MIIFRTCCBC2gAwIBAgIDCZBkMA0GCSqGSIb3DQEBCwUAMFAxCzAJBgNVBAYTAkRF' +

'MRUwEwYDVQQKDAxELVRydXN0IEdtYkgxKjAoBgNVBAMMIUQtVFJVU1QgUm9vdCBD' +

'bGFzcyAzIENBIDIgRVYgMjAwOTAeFw0wOTExMTIxMjUyNDNaFw0yOTExMDUwODUw' +

'NDZaME8xCzAJBgNVBAYTAkRFMRUwEwYDVQQKDAxELVRydXN0IEdtYkgxKTAnBgNV' +

'BAMMIEQtVFJVU1QgU1NMIENsYXNzIDMgQ0EgMSBFViAyMDA5MIIBIjANBgkqhkiG' +

'9w0BAQEFAAOCAQ8AMIIBCgKCAQEAygp+ZziakFyPq80fk1QIT9UCcPy0R3UIyq56' +

'hXA6lhgfs1l9R9wRM9/DIVX2olb0gHCXdpnHRm+jwzeL3dHJO8Im5Om/c24ZfSVE' +

'zBcgKxS5X7X5e7oCYb9tozd9xs04WqYd5kWrvCJsSQf5gtv5gAeJt+QiU7dtXs3A' +

'YDflWv4g9eEaDExxM0VQmceEAo5qc7I7dk5ry356G14zQmr29cxie6YS0kH+7qn5' +

'g+c21M01sENle0tBPxIfkv+nV95Ih3JkpHSPm/wgFKfCtwRtG+5VehUoMEpgfi0X' +

'fmVkag558aQpaaeQCtYZnXuq6g1D1LAcjIqMpOP4wNRp1ldLzQIDAQABo4ICJzCC' +

'AiMwHwYDVR0jBBgwFoAU05SKTGITKhkuzK9yin0215oc3GcwRwYIKwYBBQUHAQEE' +

'OzA5MDcGCCsGAQUFBzABhitodHRwOi8vcm9vdC1jMy1jYTItZXYtMjAwOS5vY3Nw' +

'LmQtdHJ1c3QubmV0MF8GA1UdIARYMFYwVAYEVR0gADBMMEoGCCsGAQUFBwIBFj5o' +

'dHRwOi8vd3d3LmQtdHJ1c3QubmV0L2ludGVybmV0L2ZpbGVzL0QtVFJVU1RfUm9v' +

'dF9QS0lfQ1BTLnBkZjAzBgNVHREELDAqgRBpbmZvQGQtdHJ1c3QubmV0hhZodHRw' +

'Oi8vd3d3LmQtdHJ1c3QubmV0MIHdBgNVHR8EgdUwgdIwgYeggYSggYGGf2xkYXA6' +

'Ly9kaXJlY3RvcnkuZC10cnVzdC5uZXQvQ049RC1UUlVTVCUyMFJvb3QlMjBDbGFz' +

'cyUyMDMlMjBDQSUyMDIlMjBFViUyMDIwMDksTz1ELVRydXN0JTIwR21iSCxDPURF' +

'P2NlcnRpZmljYXRlcmV2b2NhdGlvbmxpc3QwRqBEoEKGQGh0dHA6Ly93d3cuZC10' +

'cnVzdC5uZXQvY3JsL2QtdHJ1c3Rfcm9vdF9jbGFzc18zX2NhXzJfZXZfMjAwOS5j' +

'cmwwHQYDVR0OBBYEFKztpZ16orZD8RiKJWpsscyo8lrUMA4GA1UdDwEB/wQEAwIB' +

'BjASBgNVHRMBAf8ECDAGAQH/AgEAMA0GCSqGSIb3DQEBCwUAA4IBAQA6I3sGyvb4' +

'MdTyEZFBBWBN/5Kx1SVkkPsll8DvgosJiuuK4I7mD6FFKDjKgogr407EoDSS2t1+' +

'pSmQCb0rNXoJT3YIlpZGqPYU2rcwrelabJQZWAfoRnbkDx2aqofhp5u45dyQpM2t' +

'R93/oA36iuHYc9Ewq8CaLGolrpT138RD7i4nN7sZFuFH0IseNz0+EZm88NHi9WeJ' +

'UyshWFKBKARi+589Y4P/G2XnbckxFKUxa7uEroZcMwvKBy469K0Au0zVTxs1zNtf' +

'Ol3QkNgPwzOPeHhOnpzcenyPgNEm+HQ0FPTnB4HeKBqTeLpkM7h4gq5MZ2TPmfuX' +
                'KDz3AHrWLLdH' +
                '-----END CERTIFICATE-----';

    static void CreateRecords(){
        Account ownerAccount2 = new Account();
        ownerAccount2.recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('CA Owner').getRecordTypeID();
        ownerAccount2.name = 'D-TRUST';
        ownerAccount2.type = 'Owner';
        ownerAccount2.CA_Email_Alias_1__c='EmailAlias1@Company.junk';
        ownerAccount2.CA_Email_Alias_2__c='EmailAlias2@Company.junk';
        ownerAccount2.website  = 'https//www.test.com';
        ownerAccount2.valid_From_GMT__c= date.today()+1;
        ownerAccount2.valid_to_GMT__c= date.today()+10;
        ownerAccount2.company_website__c=  'https//www.test.com';
        ownerAccount2.organizational_type__c=  'Organizational Type';
        ownerAccount2.geographic_focus__c=  'Geographic focus';
        ownerAccount2.status__c = 'Included';
        insert ownerAccount2;

        Account rootAccount = new Account();
        rootAccount.recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Root Certificate').getRecordTypeID();
        rootAccount.name = 'Sample Issuer CN';
        rootAccount.parentid = ownerAccount2.Id;
        rootAccount.type = 'Root';
        rootAccount.valid_From_GMT__c = date.today()+1;
        rootAccount.valid_to_GMT__c = date.today()+10;
        rootAccount.SHA_1_fingerprint__c= '96:C9:1B:0B:95:B4:10:98:42:FA:D0:D8:22:79:FE:60:FA:B9:16:83';
        rootAccount.SHA_256_fingerprint__c = '51:84:7C:8C:BD:2E:9C:72:C9:1E:29:2D:2C:E2:47:D7:DE:1D:3F:D2:70:54:7A:22:EF:7D:61:0F:38:B9:84:2C';
        rootAccount.Trust_Bits__c = 'Email';
        rootAccount.Standard_Audit__c = 'http://www.google.com/StandardAudit.pdf';
        rootAccount.Standard_Audit_Type__c = 'WebTrust';
        rootAccount.Standard_Audit_Statement_Date__c = system.today();
        rootAccount.Standard_Audit_Period_Start_Date__c = system.today().addDays(-3);
        rootAccount.Standard_Audit_Period_End_Date__c = system.today().addDays(-2);
        rootAccount.BR_Audit__c = 'http://www.google.com/BRAudit.pdf';
        rootAccount.BR_Audit_Type__c = 'WebTrust';
        rootAccount.BR_Audit_Statement_Date__c = system.today();
        rootAccount.BR_Audit_Period_Start_Date__c = system.today().addDays(-3);
        rootAccount.BR_Audit_Period_End_Date__c = system.today().addDays(-2);
        rootAccount.EV_Audit__c = 'http://www.google.com/EVAudit.pdf';
        rootAccount.EV_Audit_Type__c = 'Webtrust';
        rootAccount.EV_Audit_Statement_Date__c = system.today();
        rootAccount.EV_Audit_Period_Start_Date__c = system.today().addDays(-3);
        rootAccount.EV_Audit_Period_End_Date__c = system.today().addDays(-2);
        rootAccount.ev_policy_oid_s__c = '';
        rootAccount.status__c = 'Included';
        insert rootAccount;


        rootAccount = new Account();
        rootAccount.recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Root Certificate').getRecordTypeID();
        rootAccount.name = 'Sample Issuer CN 1';
        rootAccount.parentid = ownerAccount2.Id;
        rootAccount.type = 'Root';
        rootAccount.valid_From_GMT__c= date.today()+1;
        rootAccount.valid_to_GMT__c= date.today()+10;
        rootAccount.SHA_1_fingerprint__c= 'CE:6A:64:A3:09:E4:2F:BB:D9:85:1C:45:3E:64:09:EA:E8:7D:60:F1';
        rootAccount.SHA_256_fingerprint__c = '51:84:7C:8C:BD:2E:9A:72:C9:1E:29:2D:2A:E2:47:D7:DE:1E:3F:D2:70:54:7A:20:EF:7D:61:0F:38:B8:84:2C';
        rootAccount.Trust_Bits__c = 'Email;Websites';
        rootAccount.Standard_Audit__c = 'http://www.google.com/StandardAudit.pdf';
        rootAccount.Standard_Audit_Type__c = 'WebTrust';
        rootAccount.Standard_Audit_Statement_Date__c = system.today();
        rootAccount.Standard_Audit_Period_Start_Date__c = system.today().addDays(-3);
        rootAccount.Standard_Audit_Period_End_Date__c = system.today().addDays(-2);
        rootAccount.BR_Audit__c = 'http://www.google.com/BRAudit.pdf';
        rootAccount.BR_Audit_Type__c = 'WebTrust';
        rootAccount.BR_Audit_Statement_Date__c = system.today();
        rootAccount.BR_Audit_Period_Start_Date__c = system.today().addDays(-3);
        rootAccount.BR_Audit_Period_End_Date__c = system.today().addDays(-2);
        rootAccount.EV_Audit__c = 'http://www.google.com/EVAudit.pdf';
        rootAccount.EV_Audit_Type__c = 'Webtrust';
        rootAccount.EV_Audit_Statement_Date__c = system.today();
        rootAccount.EV_Audit_Period_Start_Date__c = system.today().addDays(-3);
        rootAccount.EV_Audit_Period_End_Date__c = system.today().addDays(-2);
        rootAccount.ev_policy_oid_s__c = '';
        rootAccount.status__c = 'Included';
        insert rootAccount;

        rootAccount = new Account();
        rootAccount.recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Root Certificate').getRecordTypeID();
        rootAccount.name = 'Sample Issuer CN 2';
        rootAccount.parentid = ownerAccount2.Id;
        rootAccount.type = 'Root';
        rootAccount.valid_From_GMT__c= date.today()+1;
        rootAccount.valid_to_GMT__c= date.today()+10;
        rootAccount.SHA_1_fingerprint__c= '12:34:56:78:90:12:34:56:78:90:12:34:56:78:90:12:34:56:78:90';
        rootAccount.SHA_256_fingerprint__c = '84:84:7C:8C:BD:2E:9C:52:C9:1E:29:2D:2C:E2:47:D7:DE:1R:3F:D2:70:54:7A:44:EF:7D:61:0F:84:B9:84:2C';
        rootAccount.Trust_Bits__c = 'Email;Websites';
        rootAccount.Standard_Audit__c = 'http://www.google.com/StandardAudit.pdf';
        rootAccount.Standard_Audit_Type__c = 'WebTrust';
        rootAccount.Standard_Audit_Statement_Date__c = system.today();
        rootAccount.Standard_Audit_Period_Start_Date__c = system.today().addDays(-3);
        rootAccount.Standard_Audit_Period_End_Date__c = system.today().addDays(-2);
        rootAccount.BR_Audit__c = 'http://www.google.com/BRAudit.pdf';
        rootAccount.BR_Audit_Type__c = 'WebTrust';
        rootAccount.BR_Audit_Statement_Date__c = system.today();
        rootAccount.BR_Audit_Period_Start_Date__c = system.today().addDays(-3);
        rootAccount.BR_Audit_Period_End_Date__c = system.today().addDays(-2);
        rootAccount.EV_Audit__c = 'http://www.google.com/EVAudit.pdf';
        rootAccount.EV_Audit_Type__c = 'Webtrust';
        rootAccount.EV_Audit_Statement_Date__c = system.today();
        rootAccount.EV_Audit_Period_Start_Date__c = system.today().addDays(-3);
        rootAccount.EV_Audit_Period_End_Date__c = system.today().addDays(-2);
        rootAccount.ev_policy_oid_s__c = 'Some data';
        rootAccount.status__c = 'Included';
        insert rootAccount;

        Migrate_Certs__c migrateCert = new Migrate_Certs__c();
        migrateCert.name = 'Sample Subject CN';
        migrateCert.CA_Owner__c = 'D-TRUST';
        migrateCert.Parent_CA_Owner_Certificate__c = 'Sample Issuer CN';
        migrateCert.Processing_Status__c = 'Not Processed';
        migrateCert.Revocation_Status__c = 'Not Revoked';
        migrateCert.Standard_Audit__c = 'http://www.google.com/StandardAudit.pdf';
        migrateCert.Standard_Audit_Statement_Date__c = date.today();
        migrateCert.Standard_Audit_Type__c = 'WebTrust';
        migrateCert.BR_Audit__c = 'http://www.google.com/BRAudit.pdf';
        migrateCert.BR_Audit_Statement_Date__c = date.today();
        migrateCert.BR_Audit_Type__c = 'WebTrust';
        migrateCert.EV_Audit__c = 'http://www.google.com/EVAudit.pdf';
        migrateCert.EV_Audit_Statement_Date__c = date.today();
        migrateCert.EV_Audit_Type__c = 'Webtrust';
        migrateCert.Certificate_Policy_CP__c = 'cp.pdf';
        migrateCert.Certification_Practice_Statement_CPS__c = 'cps.pdf';
        migrateCert.X_509_Certificate_PEM__c = PEMInfo;
        insert migrateCert;

        migrateCert = new Migrate_Certs__c();
        migrateCert.name = 'Sample Subject CN';
        migrateCert.CA_Owner__c = 'D-TRUST';
        migrateCert.Parent_CA_Owner_Certificate__c = 'Sample Issuer CN 1';
        migrateCert.Processing_Status__c = 'Not Processed';
        migrateCert.Revocation_Status__c = 'Not Revoked';
        migrateCert.Certificate_Processed__c = true;
        migrateCert.Standard_Audit__c = 'http://www.google.com/StandardAudit.pdf';
        migrateCert.Standard_Audit_Statement_Date__c = date.today();
        migrateCert.Standard_Audit_Type__c = 'WebTrust';
        migrateCert.BR_Audit__c = 'http://www.google.com/BRAudit.pdf';
        migrateCert.BR_Audit_Statement_Date__c = date.today();
        migrateCert.BR_Audit_Type__c = 'WebTrust';
        migrateCert.EV_Audit__c = 'http://www.google.com/EVAudit.pdf';
        migrateCert.EV_Audit_Statement_Date__c = date.today();
        migrateCert.EV_Audit_Type__c = 'Webtrust';
        migrateCert.Certificate_Policy_CP__c = 'cp.pdf';
        migrateCert.Certification_Practice_Statement_CPS__c = 'cps.pdf';
        migrateCert.X_509_Certificate_PEM__c = PEMInfo;
        insert migrateCert;

        migrateCert = new Migrate_Certs__c();
        migrateCert.name = 'Sample Subject CN Test 1';
        migrateCert.CA_Owner__c = 'D-TRUST';
        migrateCert.Parent_CA_Owner_Certificate__c = 'Sample Issuer CN 2';
        migrateCert.Processing_Status__c = 'Not Processed';
        migrateCert.Revocation_Status__c = 'Not Revoked';
        migrateCert.Certificate_Processed__c = true;
        migrateCert.Standard_Audit__c = 'http://www.google.com/StandardAudit.pdf';
        migrateCert.Standard_Audit_Statement_Date__c = date.today();
        migrateCert.Standard_Audit_Type__c = 'WebTrust';
        migrateCert.BR_Audit__c = 'http://www.google.com/BRAudit.pdf';
        migrateCert.BR_Audit_Statement_Date__c = date.today();
        migrateCert.BR_Audit_Type__c = 'WebTrust';
        migrateCert.EV_Audit__c = 'http://www.google.com/EVAudit.pdf';
        migrateCert.EV_Audit_Statement_Date__c = date.today();
        migrateCert.EV_Audit_Type__c = 'Webtrust';
        migrateCert.Certificate_Policy_CP__c = 'cp.pdf';
        migrateCert.Certification_Practice_Statement_CPS__c = 'cps.pdf';
        insert migrateCert;

        migrateCert = new Migrate_Certs__c();
        migrateCert.name = 'Sample Subject CN Test 1';
        migrateCert.CA_Owner__c = 'D-TRUST';
        migrateCert.Parent_CA_Owner_Certificate__c = 'Sample Issuer CN 1';
        migrateCert.Parent_Certificate_s_SHA_1_Fingerprint__c = '22:45';
        migrateCert.Processing_Status__c = 'Not Processed';
        migrateCert.Revocation_Status__c = 'Not Revoked';
        migrateCert.Certificate_Processed__c = true;
        migrateCert.Standard_Audit__c = 'http://www.google.com/StandardAudit.pdf';
        migrateCert.Standard_Audit_Statement_Date__c = date.today();
        migrateCert.Standard_Audit_Type__c = 'WebTrust';
        migrateCert.BR_Audit__c = 'http://www.google.com/BRAudit.pdf';
        migrateCert.BR_Audit_Statement_Date__c = date.today();
        migrateCert.BR_Audit_Type__c = 'WebTrust';
        migrateCert.EV_Audit__c = 'http://www.google.com/EVAudit.pdf';
        migrateCert.EV_Audit_Statement_Date__c = date.today();
        migrateCert.EV_Audit_Type__c = 'Webtrust';
        migrateCert.Certificate_Policy_CP__c = 'cp.pdf';
        migrateCert.Certification_Practice_Statement_CPS__c = 'cps.pdf';
        migrateCert.X_509_Certificate_PEM__c = null;
        insert migrateCert;
    }

    static testmethod void myTestControllerMethods(){
        CreateRecords();
        MigrateCertBatchController batchController = new MigrateCertBatchController();
        batchController.setprocessSelection('Root Certificates');
        System.assertEquals('Root Certificates', batchController.getprocessSelection());
        batchController.prepareCerts();
        batchController.getItems();
    }

    static testMethod void myTestControllerMethods1() {
        // *************************** START PROCESS ***********************************

        MigrateCertBatchController batchController = new MigrateCertBatchController();
        batchController.setprocessSelection('Intermediate Certificates');
        batchController.prepareCerts();
        Test.startTest();

        try{
        batchController.startBatch();
        }catch(Exception e){}


        // End the test
        Test.stopTest();

        // ***************************** END PROCESS ***********************************

    }



    static testMethod void myTestControllerMethod2() {
        // *************************** START PROCESS ***********************************
        CreateRecords();
        MigrateCertsBatch obj = new MigrateCertsBatch('Root Certificates');
        Database.executeBatch(obj,1);
        // ***************************** END PROCESS ***********************************

    }

    static testMethod void myTestControllerMethod3() {
        // *************************** START PROCESS ***********************************
        CreateRecords();
        MigrateCertsBatch objbatch = new MigrateCertsBatch();
        MigrateCertsBatch obj = new MigrateCertsBatch('Intermediate Certificates');
        obj.dummyTestMethod();
        Database.executeBatch(obj,1);
        // ***************************** END PROCESS ***********************************

    }

    static testMethod void myTestControllerMethods4() {
        MigrateCertsBatch objbatch = new MigrateCertsBatch();
        MigrateCertsBatch obj = new MigrateCertsBatch('Test');
        Database.executeBatch(obj,1);
    }

    static testmethod void myTestCheckForNullFields(){
        Account rootAccount = new Account();
        rootAccount.name = 'Sample Issuer CN';
        rootAccount.Certificate_Subject_Common_Name__c = 'ABC';
        rootAccount.Certificate_Subject_Organization__c = 'XYZ';
        rootAccount.Certificate_Subject_Organization_Unit__c = 'TRE';
        rootAccount.valid_From_GMT__c= date.today()+1;
        rootAccount.valid_to_GMT__c= date.today()+10;
        rootAccount.Certificate_Issuer_Common_Name__c = 'ERT';
        rootAccount.Certificate_Issuer_Organization__c = 'Email';
        rootAccount.Certificate_Issuer_Organizational_Unit__c = 'http://www.google.com/StandardAudit.pdf';
        rootAccount.Subject__c = 'SADSAD';
        rootAccount.SHA_1_Fingerprint__c = 'WebTrust';
        rootAccount.SHA_256_Fingerprint__c = 'http://www.google.com/BRAudit.pdf';
        //rootAccount.Certificate_ID__c = 'Test ID';
        rootAccount.Certificate_Serial_Number__c = 'Test';
        rootAccount.Signature_Hash_Algorithm__c = 'http://www.google.com/EVAudit.pdf';
        //rootAccount.Basic_Constraints__c = 'Basic';
        rootAccount.Public_Key_Algorithm__c = '';
        //rootAccount.OCSP_URL_s__c = '';
        rootAccount.CRL_URL_s__c = 'Included';

        Account objacc = new Account();

        MigrateCertBatchHelper.CheckForNullFields(rootAccount, objacc);

    }

}
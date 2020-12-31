/*******************************************************************************************************
 Name: CompareCertDataTest

 Dependencies:  CompareCertData controller class, CompareCertDataTest, CompareCertData vf page

 Description: This is a test class for CompareCertData controller. The controller classs generates a report 
 by comparing the CCADB and certdata.txt.
 
 Instructions:  

 *******************************************************************************************************
 Revision History:
 
      1/22/2018 - Created new

 ******************************************************************************************************/
 
@isTest
public with sharing class CompareCertDataTest {
    
    @testsetup
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
        rootAccount.SHA_1_fingerprint__c= '96C91B0B95B4109842FAD0D82279FE60FAB91683';
        rootAccount.Trust_Bits__c = 'Email';
        rootAccount.Standard_Audit__c = 'http://www.google.com/StandardAudit.pdf';
        rootAccount.Standard_Audit_Statement_Date__c = date.today(); 
        rootAccount.Standard_Audit_Type__c = 'WebTrust';
        rootAccount.Standard_Audit_Period_Start_Date__c = date.today();
        rootAccount.Standard_Audit_Period_End_Date__c = date.today();
        rootAccount.BR_Audit__c = 'http://www.google.com/BRAudit.pdf';
        rootAccount.BR_Audit_Statement_Date__c = date.today();
        rootAccount.BR_Audit_Period_Start_Date__c = date.today();
        rootAccount.BR_Audit_Period_End_Date__c = date.today();
        rootAccount.BR_Audit_Type__c = 'WebTrust';
        rootAccount.EV_Audit__c = 'http://www.google.com/EVAudit.pdf';
        rootAccount.EV_Audit_Statement_Date__c = date.today();
        rootAccount.EV_Audit_Period_Start_Date__c = date.today();
        rootAccount.EV_Audit_Period_End_Date__c = date.today();
        rootAccount.EV_Audit_Type__c = 'WebTrust';
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
        rootAccount.SHA_1_fingerprint__c= 'CE6A64A309E42FBBD9851C453E6409EAE87D60F1';
        rootAccount.SHA_256_Fingerprint__c = 'CA42DD41745FD0B81EB902362CF9D8BF719DA1BD1B1EFC946F5B4C99F42C1B9E';
        rootAccount.Trust_Bits__c = 'Email;Websites';
        rootAccount.Standard_Audit__c = 'http://www.google.com/StandardAudit.pdf';
        rootAccount.Standard_Audit_Statement_Date__c = date.today();
        rootAccount.Standard_Audit_Type__c = 'WebTrust';
        rootAccount.Standard_Audit_Period_Start_Date__c = date.today();
        rootAccount.Standard_Audit_Period_End_Date__c = date.today();
        rootAccount.BR_Audit__c = 'http://www.google.com/BRAudit.pdf';
        rootAccount.BR_Audit_Statement_Date__c = date.today(); 
        rootAccount.BR_Audit_Period_Start_Date__c = date.today();
        rootAccount.BR_Audit_Period_End_Date__c = date.today();
        rootAccount.BR_Audit_Type__c = 'WebTrust';
        rootAccount.EV_Audit__c = 'http://www.google.com/EVAudit.pdf';
        rootAccount.EV_Audit_Statement_Date__c = date.today();
        rootAccount.EV_Audit_Period_Start_Date__c = date.today();
        rootAccount.EV_Audit_Period_End_Date__c = date.today();
        rootAccount.EV_Audit_Type__c = 'WebTrust';
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
        rootAccount.SHA_1_fingerprint__c= '1234567890123456789012345678901234567890';
        rootAccount.Certificate_Serial_Number__c = '40000000001154b5ac394';
        rootAccount.SHA_256_Fingerprint__c = 'CBB5AF185E942A2402F9EACBC0ED5BB876EEA3C1223623D00447E4F3BA554B65';
        rootAccount.Certificate_Issuer_Common_Name__c = 'GlobalSign Root CA';
        rootAccount.Trust_Bits__c = 'Email;Websites';
        rootAccount.Standard_Audit__c = 'http://www.google.com/StandardAudit.pdf';
        rootAccount.Standard_Audit_Statement_Date__c = date.today();
        rootAccount.Standard_Audit_Type__c = 'WebTrust';
        rootAccount.Standard_Audit_Period_Start_Date__c = date.today();
        rootAccount.Standard_Audit_Period_End_Date__c = date.today();
        rootAccount.BR_Audit__c = 'http://www.google.com/BRAudit.pdf';
        rootAccount.BR_Audit_Statement_Date__c = date.today();
        rootAccount.BR_Audit_Period_Start_Date__c = date.today();
        rootAccount.BR_Audit_Period_End_Date__c = date.today();
        rootAccount.BR_Audit_Type__c = 'WebTrust';
        rootAccount.EV_Audit__c = 'http://www.google.com/EVAudit.pdf';
        rootAccount.EV_Audit_Statement_Date__c = date.today(); 
        rootAccount.EV_Audit_Period_Start_Date__c = date.today();
        rootAccount.EV_Audit_Period_End_Date__c = date.today();
        rootAccount.EV_Audit_Type__c = 'Webtrust';
        rootAccount.ev_policy_oid_s__c = 'Some data';
        rootAccount.status__c = 'Included';
        insert rootAccount;
    }
    
    static testmethod void TestCompareReport(){
        string ResponseData = '';
        ResponseData = '[{"PEM":"","sha256":"CB:B5:AF:18:5E:94:2A:24:02:F9:EA:CB:C0:ED:5B:B8:76:EE:A3:C1:22:36:23:D0:04:47:E4:F3:BA:55:4B:65","serialNumber":"40000000001154b5ac394","issuer":"O=GlobalSign nv-sa/OU=Root CA/CN=GlobalSign Root CA","trustWeb":true,"trustEmail":true},{"PEM":"","sha256":"CA:42:DD:41:74:5F:D0:B8:1E:B9:02:36:2C:F9:D8:BF:71:9D:A1:BD:1B:1E:FC:94:6F:5B:4C:99:F4:2C:1B:9E","serialNumber":"400000000010f8626e60d","issuer":"O=GlobalSign/OU=GlobalSign Root CA - R2/CN=GlobalSign","trustWeb":true,"trustEmail":true}';
        ResponseData += ',{"PEM":"","sha256":"73:C1:76:43:4F:1B:C6:D5:AD:F4:5B:0E:76:E7:27:28:7C:8D:E5:76:16:C1:E6:E6:14:1A:2B:2C:BC:7D:8E:4C","serialNumber":"456b5054","issuer":"O=Entrust, Inc./OU=(c) 2006 Entrust, Inc./CN=Entrust Root Certification Authority","trustWeb":true,"trustEmail":true}]';
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new ApiCalloutMock(responseData));
        CompareCertData objcomparereport = new CompareCertData();
        Test.stoptest();
    }
    
    public class ApiCalloutMock implements HttpCalloutMock {
        private String data;
        public ApiCalloutMock(String data) {
            this.data = data;
        }
        public HTTPResponse respond(HTTPRequest request) {
            HttpResponse response = new HttpResponse();
            response.setBody(data);
            return response;
        }        
    }
}
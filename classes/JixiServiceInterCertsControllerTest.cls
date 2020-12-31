/*******************************************************************************************************
 Name: JixiServiceInterCertsControllerTest

 Dependencies:  JixiServiceInterCertsController controller class, 
 JixiServiceInterCertsControllerTest test class, JixiServiceInterCerts vf page

 Description: This is a test class. Audit Letter Validation for Intermediate Certs or Jixi service 
 allows root store managers and CAs to validate audit docuemnts. It is invoked from a button "Audit 
 Letter Validation" from Intermediate Cert record. A self signed certificate is required to 
 authenticate and establish the connection. 
 
 1. Prepare a request from Intermediate cert and related root cert record. Method Name: prepareRequest
 2. Do a Callout. Method Name: doCallout
 3. Perform Post Callout Activities. Method Name: postCallActions
 
 If the "Audit Same As Parent" is checked, ALV processing will not be allowed to run. Only one intermediate
 cert data is send in the https request to process.
 
 Instructions: The  ALV webservice was initially created for Case/RootCase records and the JSON definition
 has not been modify for intermediate certs. That is why the this prorgam is referencing Case/RootCase  
 attributes. 
 *******************************************************************************************************
 Revision History:
 
      5/2/2019 - Created new class
 ******************************************************************************************************/
    
    
@isTest
public class JixiServiceInterCertsControllerTest {
    static testmethod void testJixiServiceInterCertsController(){
        
        Account objnewAcc = new Account();
        objnewAcc.Name = 'Test CA Owner';
        insert objnewacc;
        
        Account rootAccount = getChildAccount();
        rootAccount.Status__c = 'Included';
        rootAccount.ParentId = objnewacc.Id;
        rootAccount.Standard_Audit__c = 'https://cert.webtrust.org/SealFile?seal=1987&file=pdf';
        rootAccount.BR_Audit__c = 'https://cert.webtrust.org/SealFile?seal=1988&file=pdf';
        rootAccount.BR_Audit_Type__c = 'WebTrust';
        rootAccount.EV_Audit__c = 'https://cert.webtrust.org/SealFile?seal=1989&file=pdf';
        rootAccount.EV_Code_Signing_Audit__c = 'https://cert.webtrust.org/SealFile?seal=1990&file=pdf';
        rootAccount.Code_Signing_Audit_Type__c = 'WebTrust';
        rootAccount.EV_Code_Signing_Audit_Type__c = 'WebTrust';
        rootAccount.EV_Audit_Type__c = 'WebTrust';
        rootAccount.Standard_Audit_Type__c = 'WebTrust';
        
        rootAccount.BR_Audit_Period_Start_Date__c = system.today().addDays(-10);
        rootAccount.BR_Audit_Period_End_Date__c = system.today().addDays(10);
        rootAccount.BR_Audit_Statement_Date__c = system.today().addDays(10);
        
        rootAccount.Code_Signing_Audit_Period_End_Date__c = system.today().addDays(10);
        rootAccount.Code_Signing_Audit_Period_Start_Date__c  = system.today().addDays(-10);
        rootAccount.Code_Signing_Audit_Statement_Date__c = system.today().addDays(10);
        
        rootAccount.EV_Code_Signing_Audit_Period_End_Date__c = system.today().addDays(10);
        rootAccount.EV_Code_Signing_Audit_Period_Start_Date__c = system.today().addDays(-10);
        rootAccount.EV_Code_Signing_Audit_Statement_Date__c =  system.today().addDays(10);
        
        rootAccount.EV_Audit_Period_End_Date__c = system.today().addDays(10);
        rootAccount.EV_Audit_Period_Start_Date__c = system.today().addDays(-10);
        rootAccount.EV_Audit_Statement_Date__c = system.today().addDays(10);
        
        rootAccount.Standard_Audit_Period_End_Date__c = system.today().addDays(10);
        rootAccount.Standard_Audit_Period_Start_Date__c = system.today().addDays(-10);
        rootAccount.Standard_Audit_Statement_Date__c = system.today().addDays(10); 
        
        insert rootAccount;
        
        Account accountSO = getInterCertAccount();
        accountSO.Extended_Key_Usage__c = 'ExtKeyUsageEmailProtection,ExtKeyUsageClientAuth';
        accountSO.ParentId = rootAccount.Id;
        accountSO.Subject_SPKI_SHA256__c = 'C90FBC2664485F6D3175055A45EF10D2EB6E6C7E027DF1A1D526458C42F42696';
        accountSO.Revocation_Status__c = 'Not Revoked';
        insert accountSO;   
        
        Jixi_Integration_Tokens__c token = new Jixi_Integration_Tokens__c();
        token.name = 'Jixi Service Tokens';
        token.Client_Certification_Name__c = 'SelfSignedCertForJixi';
        token.HTTP_Method__c = 'POST';
        token.Service_Endpoint__c = 'https://ccadbwebapiservice.azurewebsites.net/api/CAs';
        token.Timeout__c = 10000;
        insert token;
        
        QueueHttpMock mock = new QueueHttpMock();
        HttpResponse res1 = new HttpResponse();
        res1.setStatusCode(200);
        res1.setBody('{"CaseRecordID":"'+accountSO.Id+'","StandardAudit":{"AutoReviewStatus":false,"AutoReviewResults":'+
        '"PDFLetterDownloaded=Pass; AllThumbprintsListed=Fail; Auditor=Fail; CAOwner=Pass; Cleaned=Fail; DateVerified=Pass;'+
        ' AuditPeriodStart=Pass; AuditPeriodEnd=Pass; StatementDate=Pass;"},"BRAudit":{"AutoReviewStatus":false,"AutoReviewResults":'+
        '"PDFLetterDownloaded=Pass; AllThumbprintsListed=Fail; Auditor=Fail; CAOwner=Pass; Cleaned=Fail; DateVerified=Pass; '+
        'AuditPeriodStart=Pass; AuditPeriodEnd=Pass; StatementDate=Pass;"},"EVSSLAudit":{"AutoReviewStatus":false,"AutoReviewResults":'+
        '"PDFLetterDownloaded=Pass; AllThumbprintsListed=Fail; Auditor=Fail; CAOwner=Pass; Cleaned=Fail; DateVerified=Pass; '+
        'AuditPeriodStart=Pass; AuditPeriodEnd=Pass; StatementDate=Pass;"},"EVCodeSigningAudit":{"AutoReviewStatus":true,"AutoReviewResults"'+
        ':"PDFLetterDownloaded=Pass; AllThumbprintsListed=Fail; Auditor=Fail;"},"RootCases":[{"RootCaseRecordID":"'+accountSO.Id+'","RootCaseNumber":"'+accountSO.CA_Owner_Certificate_No__c+'","Name":"'+accountSO.Name+'"'+
        ',"SHA1Thumbprint":"'+accountSO.SHA_1_Fingerprint__c+'","SHA256Thumbprint":"'+accountSO.SHA_256_Fingerprint__c+'","AutoReviewStatus":false,"AutoReviewResults":"'+
        'EKUReconciliation=Pass; ServerAuthentication=Fail; ClientAuthentication=Fail; CodeSigning=Fail; SecureEmail=Fail;'+
        ' TimeStamping=Fail; CodeSigningEV=Fail;"}]}');
       
        HttpResponse res2 = new HttpResponse();
        res2.setStatusCode(404);
        res2.setBody('{foo:bar}');
        
        mock.addResponse(res1);
        mock.addResponse(res2);
        Test.setMock(HttpCalloutMock.class, mock);
        
        Test.startTest();
        
        PageReference pref = Page.JixiServiceInterCerts;
        Test.setCurrentPage(pref);
        ApexPages.currentPage().getParameters().put('id', 'asdf');
        
        ApexPages.standardController stdCon = new ApexPages.standardController(accountSO);
        
        JixiServiceInterCertsController jixi = new JixiServiceInterCertsController(stdCon);
        
        jixi.prepareRequest();
        jixi.doCallout();
        jixi.postCallActions();
        
        jixi.doCallout();
        jixi.postCallActions();
        
        jixi.downloadLog();
        jixi.UpdateDeriveTrustBits();
        
        Test.stopTest();
        
        //when audit same as parent
        Account interCertAccount1 = TestUtils.getIntermediateCertificate(rootAccount.id);
        interCertAccount1.Extended_Key_Usage__c = 'ExtKeyUsageEmailProtection,ExtKeyUsageClientAuth';
        interCertAccount1.Name = 'child Intercert 1';
        interCertAccount1.Audits_Same_as_Parent__c = true;
        insert interCertAccount1;
        
        jixi = new JixiServiceInterCertsController(new ApexPages.standardController(interCertAccount1));
        
        jixi.prepareRequest();
        jixi.doCallout();
        
    }
    static testmethod void TestReponseClass() {
       string Response = '{"CaseRecordID":"asdsad","StandardAudit":{"AutoReviewStatus":false,"AutoReviewResults":'+
        '"PDFLetterDownloaded=Pass; AllThumbprintsListed=Fail; Auditor=Fail; CAOwner=Pass; Cleaned=Fail; DateVerified=Pass;'+
        ' AuditPeriodStart=Pass; AuditPeriodEnd=Pass; StatementDate=Pass;"},"BRAudit":{"AutoReviewStatus":false,"AutoReviewResults":'+
        '"PDFLetterDownloaded=Pass; AllThumbprintsListed=Fail; Auditor=Fail; CAOwner=Pass; Cleaned=Fail; DateVerified=Pass; '+
        'AuditPeriodStart=Pass; AuditPeriodEnd=Pass; StatementDate=Pass;"},"EVSSLAudit":{"AutoReviewStatus":false,"AutoReviewResults":'+
        '"PDFLetterDownloaded=Pass; AllThumbprintsListed=Fail; Auditor=Fail; CAOwner=Pass; Cleaned=Fail; DateVerified=Pass; '+
        'AuditPeriodStart=Pass; AuditPeriodEnd=Pass; StatementDate=Pass;"},"EVCodeSigningAudit":{"AutoReviewStatus":true,"AutoReviewResults"'+
        ':"PDFLetterDownloaded=Pass; AllThumbprintsListed=Fail; Auditor=Fail;"},"RootCases":[{"RootCaseRecordID":"asdad","RootCaseNumber":"asdsad","Name":"adsads"'+
        ',"SHA1Thumbprint":"asdsd","SHA256Thumbprint":"asdasd","AutoReviewStatus":false,"AutoReviewResults":"'+
        'EKUReconciliation=Pass; ServerAuthentication=Fail; ClientAuthentication=Fail; CodeSigning=Fail; SecureEmail=Fail;'+
        ' TimeStamping=Fail; CodeSigningEV=Fail;"}],"ErrorLogAndActions":[{"ErrorLog":"asdad","RecommendedAction":"asdsad"}]}';
        
        JixiServiceTokens.JixiServiceResponse result = JixiServiceTokens.parse(Response);
        
        for(JixiServiceTokens.RootCasesResult rootCaseResult : result.RootCases){
            string testCase1 = rootCaseResult.RootCaseRecordID;
            string testCase2 = rootCaseResult.RootCaseNumber;
            string testCase3 = rootCaseResult.Name;
            string testCase4 = rootCaseResult.SHA1Thumbprint;
            string testCase5 = rootCaseResult.SHA256Thumbprint;
        }
        for(JixiServiceTokens.ErrorLogAndActions logResult : result.ErrorLogAndActions){
            string testCase1 = logResult.ErrorLog;
            string testCase2 = logResult.RecommendedAction;
        }
        
    }
    public static Account getInterCertAccount(){ 
        
        Account parentAccount = new Account();
        parentAccount.recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Intermediate Certificate').getRecordTypeID();
        parentAccount.name = 'ParentAccount';
        parentAccount.type = 'Intermediate Certificate';
        parentAccount.status__c= 'Included';
        parentAccount.Revocation_Status__c = 'Included';
        parentAccount.phone='2128425500';
        parentAccount.website  = 'https//www.test.com';
        parentAccount.CA_Owner__c  = 'ParentAccount(ltd)';
        parentAccount.Subordinate_CA_Owner__c  = 'Subordinate CA Owner';
        parentAccount.valid_From_GMT__c= date.today()+1;
        parentAccount.valid_to_GMT__c= date.today()+10;
        parentAccount.company_website__c=  'https//www.test.com';
        parentAccount.organizational_type__c=  'Organizational Type';
        parentAccount.geographic_focus__c=  'Geographic focus';
        parentAccount.primary_market_customer_base__c = 'Primary Market';
        parentAccount.Standard_Audit__c = 'http://www.google.com/mozilla.stdAudit-external.com';
        parentAccount.Standard_Audit_Type__c='WebTrust';
        
        parentAccount.EV_Audit__c = 'http://www.google.com/mozilla.evAudit-external.com';
        parentAccount.EV_Code_Signing_Audit__c = 'http://www.google.com/mozilla.evAudit-external.com';  
        parentAccount.EV_Code_Signing_Audit_Type__c = 'WebTrust';
        parentAccount.EV_Audit_Type__c = 'WebTrust';
        
        parentAccount.SHA_1_Fingerprint__c = 'CABD2A79A1076A31F21D253635CB039D4329A5E8';
        parentAccount.SHA_256_Fingerprint__c = '96BCEC06264976F37460779ACF28C5A7CFE8A3C0AAE11A8FFCEE05C0BDDF08C6';     
       
        parentAccount.BR_Audit__c = 'http://www.google.com/mozilla.brAudit-external.com';
        parentAccount.BR_Audit_Type__c = 'WebTrust';
        parentAccount.BR_Audit_Period_Start_Date__c = system.today().addDays(-10);
        parentAccount.BR_Audit_Period_End_Date__c = system.today().addDays(10);
        parentAccount.BR_Audit_Statement_Date__c = system.today().addDays(10);
        
        parentAccount.Code_Signing_Audit__c='';
        parentAccount.Code_Signing_Audit_Type__c = 'WebTrust';
        parentAccount.Code_Signing_Audit_Period_End_Date__c = system.today().addDays(10);
        parentAccount.Code_Signing_Audit_Period_Start_Date__c  = system.today().addDays(-10);
        parentAccount.Code_Signing_Audit_Statement_Date__c = system.today().addDays(10);
        
        parentAccount.EV_Code_Signing_Audit_Period_End_Date__c = system.today().addDays(10);
        parentAccount.EV_Code_Signing_Audit_Period_Start_Date__c = system.today().addDays(-10);
        parentAccount.EV_Code_Signing_Audit_Statement_Date__c =  system.today().addDays(10);
        
        parentAccount.EV_Audit_Period_End_Date__c = system.today().addDays(10);
        parentAccount.EV_Audit_Period_Start_Date__c = system.today().addDays(-10);
        parentAccount.EV_Audit_Statement_Date__c = system.today().addDays(10);
        
        parentAccount.Standard_Audit_Period_End_Date__c = system.today().addDays(10);
        parentAccount.Standard_Audit_Period_Start_Date__c = system.today().addDays(-10);
        parentAccount.Standard_Audit_Statement_Date__c = system.today().addDays(10);
        return parentAccount;
    }
     public static Account getChildAccount() {
        
        Account parentAccount = new Account();
        parentAccount.recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Root Certificate').getRecordTypeID();
        parentAccount.name = 'ChildAccount';
        parentAccount.type = 'Owner';
        parentAccount.phone='2128425500';
        parentAccount.website  = 'https//www.test.com';
        parentAccount.valid_From_GMT__c= date.today()+1;
        parentAccount.valid_to_GMT__c= date.today()+10;
        parentAccount.company_website__c=  'https//www.test.com';
        parentAccount.organizational_type__c=  'Organizational Type';
        parentAccount.geographic_focus__c=  'Geographic focus';
        parentAccount.primary_market_customer_base__c = 'Primary Market';
        parentAccount.SHA_1_Fingerprint__c = 'CABD2A79A1076A31F21D253635CB039D4329A5E8';
        parentAccount.SHA_256_Fingerprint__c = '96BCEC06264976F37460779ACF28C5A7CFE8A3C0AAE11A8FFCEE05C0BDDF08C6';
        parentAccount.Subject_SPKI_SHA256__c = '96BCEC06264976F37460779ACF28C5A7CFE8A3C0AAE11A8FFCEE05C0BDDF08C6';
        parentAccount.trust_bits__c = 'Websites';
        // rootCaseSO.BR_Audit__c = 'www.company.com/brauditdocument.html';
        parentAccount.EV_Policy_OID_s__c = 'Not EV';
        // rootCaseSO.EV_Audit__c = 'www.company.com/evauditdocument.html';
        parentAccount.NSS_Release_When_First_Included__c = 'NSS 1.0';
        parentAccount.Firefox_Release_When_First_Included__c = 'Firefox 1.0';              
        
        return parentAccount;
    }

}
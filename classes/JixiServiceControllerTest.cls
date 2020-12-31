@isTest
public class JixiServiceControllerTest{
    
    static testmethod void testJixiServiceController(){
        
        Account caOwnerAcc = getCAOwnerAccount();
        insert caOwnerAcc;
        
        Account rootAccount = getChildAccount();
        rootAccount.ParentId = caOwnerAcc.Id;
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

        
        Case caseSO = getCase(caOwnerAcc.Id);
        insert caseSO;
        
        // create the root case and associate it with the case
        Root_Case__c rootCaseA1 = getRootCase(caseSO.id,rootAccount.Id);
        rootCaseA1.request_status__c   = 'Initial Request Received';         
        rootCaseA1.Apply_Standard_Audit__c = true;
        //rootCaseA1.EV_Audit_Type__c = 'WebTrust';
        rootCaseA1.Apply_BR_Audit__c = true;
        rootCaseA1.Apply_EV_Audit__c = true;         
        rootCaseA1.Case_No__c = caseSO.Id;
        rootCaseA1.CA_Owner_Name_Existing__c = caOwnerAcc.Id;
        // rootCaseA1.RecordTypeId = Schema.SObjectType.Root_Case__c.getRecordTypeInfosByName().get('CA Owner/Root Inclusion Request').getRecordTypeID();
        rootCaseA1.RecordTypeId = Schema.SObjectType.Root_Case__c.getRecordTypeInfosByName().get('CA Audit Update Request').getRecordTypeID();
        insert rootCaseA1;
        
        Jixi_Integration_Tokens__c token = new Jixi_Integration_Tokens__c();
        token.name = 'Jixi Service Tokens';
        token.Client_Certification_Name__c = 'SelfSignedCertForJixi';
        token.HTTP_Method__c = 'POST';
        token.Service_Endpoint__c = 'https://ccadbwebapiservice.azurewebsites.net/api/CAs';
        token.Timeout__c = 10000;
        insert token;
        
        Test.startTest();
        
        PageReference pref = Page.JixiService;
        Test.setCurrentPage(pref);
        ApexPages.currentPage().getParameters().put('id', 'asdf');
        
        QueueHttpMock mock = new QueueHttpMock();
        HttpResponse res1 = new HttpResponse();
        res1.setStatusCode(200);
        res1.setBody('{"CaseRecordID":"'+caseSO.Id+'","StandardAudit":{"AutoReviewStatus":false,"AutoReviewResults":'+
        '"PDFLetterDownloaded=Pass; AllThumbprintsListed=Fail; Auditor=Fail; CAOwner=Pass; Cleaned=Fail; DateVerified=Pass;'+
        ' AuditPeriodStart=Pass; AuditPeriodEnd=Pass; StatementDate=Pass;"},"BRAudit":{"AutoReviewStatus":false,"AutoReviewResults":'+
        '"PDFLetterDownloaded=Pass; AllThumbprintsListed=Fail; Auditor=Fail; CAOwner=Pass; Cleaned=Fail; DateVerified=Pass; '+
        'AuditPeriodStart=Pass; AuditPeriodEnd=Pass; StatementDate=Pass;"},"EVSSLAudit":{"AutoReviewStatus":false,"AutoReviewResults":'+
        '"PDFLetterDownloaded=Pass; AllThumbprintsListed=Fail; Auditor=Fail; CAOwner=Pass; Cleaned=Fail; DateVerified=Pass; '+
        'AuditPeriodStart=Pass; AuditPeriodEnd=Pass; StatementDate=Pass;"},"EVCodeSigningAudit":{"AutoReviewStatus":true,"AutoReviewResults"'+
        ':"PDFLetterDownloaded=Pass; AllThumbprintsListed=Fail; Auditor=Fail;"},"RootCases":[{"RootCaseRecordID":"'+rootCaseA1.Id+'","RootCaseNumber":"'+rootCaseA1.Name+'","Name":"'+rootCaseA1.Name+'"'+
        ',"SHA1Thumbprint":"'+rootCaseA1.SHA_1_Fingerprint__c+'","SHA256Thumbprint":"'+rootCaseA1.SHA_256_Fingerprint__c+'","AutoReviewStatus":false,"AutoReviewResults":"'+
        'EKUReconciliation=Pass; ServerAuthentication=Fail; ClientAuthentication=Fail; CodeSigning=Fail; SecureEmail=Fail;'+
        ' TimeStamping=Fail; CodeSigningEV=Fail;"}]}');
        
        HttpResponse res2 = new HttpResponse();
        res2.setStatusCode(404);
        res2.setBody('{foo:bar}');
        
        mock.addResponse(res1);
        mock.addResponse(res2);
        Test.setMock(HttpCalloutMock.class, mock);
       
        ApexPages.standardController stdCon = new ApexPages.standardController(caseSO);
        
        JixiServiceController jixi = new JixiServiceController(stdCon);
        jixi.prepareRequest();
        jixi.doCallout();
        jixi.postCallActions();
        
        jixi.doCallout();
        jixi.postCallActions();
        
        jixi.downloadLog();
        
        Test.stopTest();
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
    
    public static Account getCAOwnerAccount(){ 
        
        Account parentAccount = new Account();
        parentAccount.recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('CA Owner').getRecordTypeID();
        parentAccount.name = 'ParentAccount';
        parentAccount.type = 'Owner';
        parentAccount.status__c= 'Included';
        parentAccount.Revocation_Status__c = 'Included';
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
        return parentAccount;
    }

    
    public static Case getCase(Id accountId){ 
        
        Case caseSO = new Case(AccountId = accountId); 
        caseSO.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('CA Audit Update Request').getRecordTypeId();
        caseSO.subject = 'test audit request case';
        caseSO.Status = 'Open';
              
        caseSO.Standard_Audit_Statement_Link__c = 'http://www.google.com/mozilla.stdAudit-external.com';
        caseSO.Standard_Audit_Type__c = 'WebTrust';
        caseSO.Standard_Audit_Verified__c = 'Not Verified';
        caseSO.Standard_Audit_Statement_Date__c = System.today();
        caseSO.Standard_Audit_Period_Start_Date__c = System.today().addDays(-2);
        caseSO.Standard_Audit_Period_End_Date__c = System.today().addDays(-1);
        
        caseSO.BR_Audit_Statement_Link__c = 'http://www.google.com/mozilla.brAudit-external.com';
        caseSO.BR_Audit_Type__c = 'WebTrust';
        caseSO.BR_Audit_Statement_Link_Verified__c = 'Not Verified';
        caseSO.BR_Audit_Statement_Date__c = System.today();
        caseSO.BR_Audit_Period_Start_Date__c = System.today().addDays(-2);
        caseSO.BR_Audit_Period_End_Date__c = System.today().addDays(-1);
                
        caseSO.EV_Audit_Statement_Link__c = 'http://www.google.com/mozilla.evAudit-external.com';
        caseSO.EV_Audit_Type__c = 'Webtrust';
        caseSO.EV_Audit_Statement_Link_Verified__c  = 'Not Verified';
        caseSO.EV_Audit_Statement_Date__c = System.today();
        caseSO.EV_Audit_Period_Start_Date__c = System.today().addDays(-2);
        caseSO.EV_Audit_Period_End_Date__c = System.today().addDays(-1);
               
        caseSO.EV_Code_Signing_Audit_Statement_Link__c = 'http://www.google.com/mozilla.evAudit-external.com';
        caseSO.EV_Code_Signing_Audit_Type__c = 'Webtrust';
        caseSO.EV_Code_Signing_Verified__c = 'Not Verified';
        caseSO.EV_Code_Signing_Audit_Statement_Date__c = System.today();
        caseSO.EV_Code_Signing_Audit_Period_Start_Date__c = System.today().addDays(-2);
        caseSO.EV_Code_Signing_Audit_Period_End_Date__c = System.today().addDays(-1);
             
        caseSO.Certification_Practice_Statement_Link__c = 'http://www.google.com/mozilla.cpsAudit-external.com';       
        caseSO.Certificate_Policy_Link__c = 'http://www.google.com/mozilla.cpAudit-external.com';
        caseSO.CP_CPS_Links_Verified__c = 'Not Verified';
 
   
        return caseSO; 
    } 
    
    public static Root_Case__c getRootCase(ID caseID, Id rootAccountId){
         Root_Case__c rootCaseSO = TestUtils.getRootCase(caseID, rootAccountId);
         /*Root_Case__c rootCaseSO = new Root_Case__c ();
         rootCaseSO.root_certificate_name__c = 'ChildAccount';
         rootCaseSO.case_no__c = caseID;
         //rootCaseSO.CA_Owner_Name_Existing__c = caOwnerId;
         rootCaseSO.Root_Certificate_Name_Existing__c = rootAccountId;
         rootCaseSO.Apply_Standard_Audit__c = true;
         rootCaseSO.Apply_BR_Audit__c = true;
         rootCaseSO.Apply_EV_Audit__c = true;
         
         rootCaseSO.valid_from__c = date.today()+1;
         rootCaseSO.valid_to__c = date.today()+10;
         rootCaseSO.SHA_1_Fingerprint__c = '1234567890123456789012345678901234567890';
         rootCaseSO.SHA_256_Fingerprint__c = '7431E5F4C3C1CE4690774F0B61E05440883BA9A01ED00BA6ABD7806ED3B118CF';
         rootCaseSO.trust_bits__c = 'Websites';
         // rootCaseSO.BR_Audit__c = 'www.company.com/brauditdocument.html';
         rootCaseSO.EV_Policy_OID_s__c = 'Not EV';
         // rootCaseSO.EV_Audit__c = 'www.company.com/evauditdocument.html';
         rootCaseSO.NSS_Release_When_First_Included__c = 'NSS 1.0';
         rootCaseSO.Firefox_Release_When_First_Included__c = 'Firefox 1.0';             
                             
         //RootCaseSO.O_From_Issuer_Field_Verified__c = 'Verified';  
         //RootCaseSO.OU_From_Issuer_Field_Verified__c = 'Verified';   
         //RootCaseSO.Certificate_Summary_Verified__c = 'Not Applicable';  
         //RootCaseSO.Root_Certificate_Download_URL_Verified__c = 'Verified';  
         //RootCaseSO.SHA_1_Fingerprint_Verified__c = 'Verified';  
         //RootCaseSO.SHA_256_Fingerprint_Verified__c = 'Verified';   
         //RootCaseSO.Valid_From_Verified__c = 'Verified';  
         //RootCaseSO.Valid_To_Verified__c = 'Not Applicable';  
         //RootCaseSO.Certificate_Version_Verified__c = 'Verified';  
         //RootCaseSO.Cert_Signature_Algorithm_Verified__c = 'Verified';   
         //RootCaseSO.Signing_Key_Parameters_Verified__c = 'Not Applicable';   
         //RootCaseSO.TestWebsiteURLSSLorExCert_Verified__c = 'Verified';         
         //RootCaseSO.CRL_URL_Verified__c = 'Verified';  
         //RootCaseSO.OCSP_URL_Verified__c = 'Verified';  
         //RootCaseSO.Revocation_Tested_Verified__c = 'Verified'; 
         //RootCaseSO.CA_Browser_Forum_Lint_Test_Verified__c = 'Verified'; 
         //RootCaseSO.Test_Website_Lint_Test_Verified__c = 'Verified';  
         //RootCaseSO.Trust_Bits_Verified__c = 'Verified';  
         //RootCaseSO.SSL_Validation_Type_Verified__c = 'Not Applicable';  
         //RootCaseSO.EV_Policy_OID_s_Verified__c = 'Verified';  
         //RootCaseSO.EV_Tested_Verified__c = 'Verified';  
         //RootCaseSO.Root_Stores_Included_In_Verified__c = 'Verified';  
         //RootCaseSO.Mozilla_Applied_Constraints_Verified__c = 'Verified';  
         //RootCaseSO.CA_Hierarchy_Verified__c = 'Verified';  
         //RootCaseSO.Externally_Operated_SubCAs_Verified__c = 'Verified';  
         RootCaseSO.Cross_Signing_Verified__c = 'Verified';  
         //RootCaseSO.Tech_Cons_on_3rd_party_Iss_Verified__c = 'Verified'; 
         //RootCaseSO.Policy_Documentation_Verified__c = 'Verified';  
         //RootCaseSO.CA_Document_Repository_Verified__c = 'Verified'; 
         //RootCaseSO.CP_Verified__c = 'Verified' ; 
         //RootCaseSO.CPS_Verified__c = 'Verified';  
         //RootCaseSO.Other_Relevant_Documents_Verified__c = 'Verified';  
         //RootCaseSO.Auditor_Name_Verified__c = 'Verified'; 
         //RootCaseSO.Auditor_Website_Verified__c = 'Verified';  
         //RootCaseSO.Auditor_Qualifications_Verified__c = 'Verified';  
         //RootCaseSO.Standard_Audit_Verified__c = 'Verified'; 
         //RootCaseSO.Standard_Audit_Type_Verified__c = 'Verified';   
         //RootCaseSO.Standard_Audit_Statement_Dt_Verified__c = 'Verified';  
         //RootCaseSO.BR_Audit_Verified__c = 'Verified';  
         //RootCaseSO.BR_Audit_Type_Verified__c = 'Verified';  
         //RootCaseSO.BR_Audit_Statement_Date_Verified__c = 'Not Applicable';  
         //RootCaseSO.EV_Audit_Verified__c = 'Verified';              
         //RootCaseSO.EV_Audit_Type_Verified__c = 'Verified';              
         //RootCaseSO.EV_Audit_Statement_Date_Verified__c = 'Not Applicable';               
         //RootCaseSO.BR_Commitment_to_Comply_Verified__c = 'Verified';   
         //RootCaseSO.BR_Self_Assessment_Verified__c = 'Not Applicable';            
         //RootCaseSO.SSL_Verification_Procedures_Verified__c = 'Verified';               
         //RootCaseSO.EV_SSL_Verification_Proc_Verified__c = 'Verified';               
         //RootCaseSO.Org_Verification_Procedure_Verified__c = 'Verified';              
         //RootCaseSO.Email_Addr_Verification_Proc_Verified__c = 'Not Applicable';               
         //RootCaseSO.Code_Signing_Subs_Verif_Proc_Verified__c = 'Verified';               
         //RootCaseSO.Multi_Factor_Authentication_Verified__c = 'Verified';               
         //RootCaseSO.Network_Security_Verified__c = 'Verified';               
         //RootCaseSO.Publ_Discl_Audited_subCAs_Verified__c = 'Not Applicable';
         RootCaseSO.Comments_by_Mozilla_on_Root_Case__c = 'Comments on Root';*/
         return rootCaseSO;
    }
}
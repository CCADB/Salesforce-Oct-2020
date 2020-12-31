/*******************************************************************************************************
 Name: VerifyTestWebsitesController

 Dependencies: VerifyTestWebsitesController, VerifyTestWebsites vf page, VerifyTestWebsitesControllerTest,
 RootCaseTriggerHelper

 Description: This apex class validates test websites (valid/expired/revoked) by sending 
 HTTP request to https://ccadb-231121.appspot.com/fromCertificateDetails. The response 
 is saved on Root Cases object (Test Websites Status and Results fields).
 
 When Test Website fields are updated on root case, RootCaseTrigger launches a future callout 
 to validate the urls. Valid PEM info is required in the request body for the webservice to 
 process the request. The results are parsed and results and overall status of PASS/FAIL is 
 saved on root case record. Root Inclusion cases with status 'Request Withdrawn by CA' and 
 'Denied' are not sent for validation. "Test Website validation" buttton provides a way to view
 the root case no, root cert, status, reuslts. From this page validation process can be re-run.
 
 Instructions: Remote site setting must have https://ccadb-231121.appspot.com  
               HHTP timeout is 2 mins
 *******************************************************************************************************
 Revision History:
 
     4/25/2019 - Created new class
     11/20/2019 - Updated class to add Lint Test Verification. 
 ******************************************************************************************************/

public with sharing class VerifyTestWebsitesController {

    public List<WrapperRootCases> lstWrapperRootCases {get; set;}
    public boolean isAnyError {get; set;}
    public Id recordId;
    public boolean isRootInclusionCase {get; set;}
    set<id> setofRCIds = new set<Id>(); 
    
    public VerifyTestWebsitesController (){
        recordId = Apexpages.currentpage().getParameters().get('id');
        isAnyError = false;
        isRootInclusionCase = false;
        if(recordId != null) {
            BindRootCases();
        } else {
            isAnyError = true;
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error,'Record Id not found.'));
        }
    }
    
    public void BindRootCases(){
        List<Root_Case__c> lstRootCases = new List<Root_Case__c>([select Id, Name,Root_Certificate_Name__c,
                    Case_No__c, Case_No__r.RecordType.Name,
                    Test_Website_Valid__c,Test_Website_Valid_Status__c,Test_Website_Valid_Results__c,
                    Test_Website_Revoked__c,Test_Website_Revoked_Status__c,Test_Website_Revoked_Results__c,
                    Test_Website_Expired__c,Test_Website_Expired_Status__c,Test_Website_Expired_Results__c,
                    Lint_Test_Status__c, Lint_Test_Results__c
                    from Root_Case__c Where (Case_No__c =: recordId OR Id =: recordId) 
                    AND Request_Status__c not in ('Request Withdrawn by CA','Denied') Order by Name]);
        lstWrapperRootCases = new List<WrapperRootCases>();
        
        for(Root_Case__c rc: lstRootCases){
            if(!isRootInclusionCase && rc.Case_No__r.RecordType.Name == 'CA Root Inclusion Request'){
                isRootInclusionCase = true;
            }
            setofRCIds.add(rc.Id);
            WrapperRootCases wrc = new WrapperRootCases();
            wrc.rootcase = rc;
            List<TestWebSiteResults> lstWResults = new List<TestWebSiteResults>();
            if(string.isnotblank(rc.Test_Website_Valid__c)){
                TestWebSiteResults twresults = new TestWebSiteResults('Valid - ' + rc.Test_Website_Valid__c, rc.Test_Website_Valid_Status__c, rc.Test_Website_Valid_Results__c);
                lstWResults.add(twresults);
                //lint test verification.
                TestWebSiteResults twresultsLint = new TestWebSiteResults('Lint Test - ' + rc.Test_Website_Valid__c, rc.Lint_Test_Status__c, rc.Lint_Test_Results__c);
                lstWResults.add(twresultsLint);
            }
            if(string.isnotblank(rc.Test_Website_Revoked__c)){
                TestWebSiteResults twresults = new TestWebSiteResults('Revoked - ' + rc.Test_Website_Revoked__c, rc.Test_Website_Revoked_Status__c, 
                                        rc.Test_Website_Revoked_Results__c);
                lstWResults.add(twresults);
            }
            if(string.isnotblank(rc.Test_Website_Expired__c)){
                TestWebSiteResults twresults = new TestWebSiteResults('Expired - ' + rc.Test_Website_Expired__c, rc.Test_Website_Expired_Status__c, 
                                        rc.Test_Website_Expired_Results__c);
                lstWResults.add(twresults);
            }
            wrc.lstWebSiteResults = lstWResults;
            lstWrapperRootCases.add(wrc);
        }
    }
    
    public void ReValidateTestWebsites(){
        try {
            if(setofRCIds.size() > 0) {
                system.debug('setofRCIds ::: '+setofRCIds);
                ValidateTestWebsites(setofRCIds);
                BindRootCases();
            }
        } catch (Exception ex) {
            Apexpages.addMessages(ex);
        }
    }
    
    public PageReference Cancel(){
        PageReference pg = new PageReference('/'+recordId);
        return pg;
    }
    
    /*
        Wrapper class to display Test websites results.
    */
    public class WrapperRootCases {
        public Root_Case__c rootcase {get; set;}
        public List<TestWebSiteResults> lstWebSiteResults {get; set;}
        public WrapperRootCases(){
            rootcase = new Root_Case__c();
            lstWebSiteResults = new List<TestWebSiteResults>();
        }
    }
    
    public class TestWebSiteResults {
        public string TestWebsite{get; set;}
        public string TestWebsiteStatus{get; set;}
        public string TestWebsiteResults{get; set;}
        public TestWebSiteResults(string TB, string TWS, string TWR){
            this.TestWebsite = TB;
            this.TestWebsiteStatus = TWS;
            this.TestWebsiteResults = TWR;
        }
    }
    
    //future call which is used in root case trigger helper class
    @future(callout=true)
    public static void ValidateTestWebsitesFromTrigger(set<ID> setOfRootCaseIds){
        ValidateTestWebsites(setOfRootCaseIds);
    }
    
    //make html call to validate test website.
    public static void ValidateTestWebsites(set<ID> setOfRootCaseIds){
        HttpRequest req = new HttpRequest();
        HTTPResponse res;
        try {
            req.setEndpoint('https://ccadb-231121.appspot.com/fromCertificateDetails');
            List<Root_Case__c> lstRootCases = new List<Root_Case__c>([select Id, Name,Root_Certificate_Name__c, X_509_Certificate_PEM__c, 
                        Test_Website_Valid__c,Test_Website_Revoked__c,Test_Website_Expired__c, Lint_Test_Status__c, Lint_Test_Results__c
                        from Root_Case__c Where Id in: setOfRootCaseIds AND Request_Status__c not in ('Request Withdrawn by CA','Denied')]);
            string RequestBody = CreateRequestBody(lstRootCases);
            if(string.isnotblank(RequestBody)){
                req.setBody(RequestBody);
                //system.debug('RequestBody ::: ' + RequestBody);
                req.setMethod('POST');
                req.setTimeOut(120000);
                req.setHeader('Content-Type','application/json');
                //req.setHeader('Content-Length', string.valueof(RequestBody.length()));
                if(!Test.isRunningTest()){
                    Http http = new Http();
                    res = http.send(req);
                }
                if((res != null && res.getStatusCode() == 200) || Test.isRunningTest()){
                    string strTestJsonBody = '[{"SubjectURL":"","RecordID":"a0056000001lodGAAQ","Opinion":{"Result":"FAIL","Errors":[]},"Expectation":"revoked","Error":"","Chain":{"Root":{"OCSP":null,"Fingerprint":"","Expiration":{"Status":"","Error":""},"CrtSh":"","CRL":null,"CommonName":""},"Leaf":{"OCSP":null,"Fingerprint":"","Expiration":{"Status":"","Error":""},"CrtSh":"","CRL":null,"CommonName":""},"Intermediates":null}},{"SubjectURL":"","RecordID":"a0056000001lodGAAQ","Opinion":{"Result":"FAIL","Errors":[]},"Expectation":"expired","Error":"","Chain":{"Root":{"OCSP":null,"Fingerprint":"","Expiration":{"Status":"","Error":""},"CrtSh":"","CRL":null,"CommonName":""},"Leaf":{"OCSP":null,"Fingerprint":"","Expiration":{"Status":"","Error":""},"CrtSh":"","CRL":null,"CommonName":""},"Intermediates":null}},{"SubjectURL":"","RecordID":"a0056000001lodGAAQ","Opinion":{"Result":"FAIL","Errors":[]},"Expectation":"valid","Error":"","Chain":{"Root":{"OCSP":null,"Fingerprint":"","Expiration":{"Status":"","Error":""},"CrtSh":"","CRL":null,"CommonName":""},"Leaf":{"OCSP":null,"Fingerprint":"","Expiration":{"Status":"","Error":""},"CrtSh":"","CRL":null,"CommonName":""},"Intermediates":null}}]';
                    string strJsonBody = Test.isRunningTest() ? strTestJsonBody : res.getBody();
                    //system.debug(strJsonBody);
                    List<parseTestWebsiteResults> lstTestWebsitesResults = (List<parseTestWebsiteResults>)System.JSON.deserialize(strJsonBody, List<parseTestWebsiteResults>.class);
                    //system.debug('lstTestWebsitesResults ::: '+lstTestWebsitesResults);
                    
                    map<string, List<parseTestWebsiteResults>> mapRootCaseWiseResults = new map<string,List<parseTestWebsiteResults>>();
                    
                    for(parseTestWebsiteResults result: lstTestWebsitesResults){
                        if(mapRootCaseWiseResults.containskey(result.RecordID)){
                            mapRootCaseWiseResults.get(result.RecordID).add(result);
                        } else {
                            mapRootCaseWiseResults.put(result.RecordID, new List<parseTestWebsiteResults>{result});
                        }
                    }
                    
                    
                    //Lint Test Verification for each root certification
                    map<Id, map<string, string>> mapOfRootCaseLintTestResults = new map<Id, map<string, string>>();
                    for(Root_Case__c rc: lstRootCases){
                        if(string.isnotblank(rc.Test_Website_Valid__c)){
                            map<string, string> mapResponse = ValidateLintTestWebsites(rc.Test_Website_Valid__c);
                            if(mapResponse != null && mapResponse.size() > 0) {
                                mapOfRootCaseLintTestResults.put(rc.Id, mapResponse);
                            }
                        }
                    }
                    
                    // update Status & Results on Root Cases
                    // Expectation in response JSON has valid/revoked/expired
                    // Opinion in response JSON has Pass/Fail status
                    List<Root_Case__c> lstRootCasesToUpdate = new List<Root_Case__c>();
                    for(string key: mapRootCaseWiseResults.keyset()){
                        if(mapRootCaseWiseResults.get(key).size() > 0){
                            Root_Case__c rootcase = new Root_Case__c(Id = key);
                            for(parseTestWebsiteResults parseresult: mapRootCaseWiseResults.get(key)){
                                if(parseresult.Expectation != null && parseresult.Expectation == 'valid'){
                                    if(parseresult.Opinion.Result != null) {
                                        rootcase.Test_Website_Valid_Status__c = parseresult.Opinion.Result;
                                    }
                                    rootcase.Test_Website_Valid_Results__c = JSON.serialize(parseresult);
                                } else if(parseresult.Expectation != null && parseresult.Expectation == 'revoked'){
                                    if(parseresult.Opinion.Result != null) {
                                        rootcase.Test_Website_Revoked_Status__c = parseresult.Opinion.Result;
                                    }
                                    rootcase.Test_Website_Revoked_Results__c = JSON.serialize(parseresult);
                                } else if(parseresult.Expectation != null && parseresult.Expectation == 'expired'){
                                    if(parseresult.Opinion.Result != null) {
                                        rootcase.Test_Website_Expired_Status__c = parseresult.Opinion.Result;
                                    }
                                    rootcase.Test_Website_Expired_Results__c = JSON.serialize(parseresult);
                                }
                            }
                            if(mapOfRootCaseLintTestResults.containskey(key)){
                                map<string, string> mapLintTestResult = mapOfRootCaseLintTestResults.get(key);
                                for(string lkey: mapLintTestResult.keyset()){
                                    rootcase.Lint_Test_Status__c = lkey; 
                                    rootcase.Lint_Test_Results__c = mapLintTestResult.get(lkey);
                                }
                            }
                            //rootcase.Extract_Test_Website_Results__c = JSON.serialize(mapRootCaseWiseResults.get(key));
                            lstRootCasesToUpdate.add(rootcase);
                        }
                    }
                    if(lstRootCasesToUpdate.size() > 0) {
                        update lstRootCasesToUpdate;
                    }
                }
            }
        } catch(Exception ex){
            return;
        }
    }
    
    //This method is doing call out for Lint Test Websites.
    public static map<string, string> ValidateLintTestWebsites(string TestValidWebsite){
        map<string, string> mapValidResults = new map<string, string>();
        HttpRequest req = new HttpRequest();
        HTTPResponse res;
        try {
            req.setEndpoint('https://ccadb-231121.appspot.com/lintFromSubject?subject='+TestValidWebsite);
            //req.setBody(RequestBody);
            //system.debug('RequestBody ::: ' + RequestBody);
            req.setMethod('POST');
            req.setTimeOut(120000);
            req.setHeader('Content-Type','application/json');
            req.setHeader('Content-Length', '0');
            if(!Test.isRunningTest()){
                Http http = new Http();
                res = http.send(req);
            }
            if((res != null && res.getStatusCode() == 200) || Test.isRunningTest()){
                string strTestJsonBody = '{"Opinion":{"Result":"FAIL","Errors":[]}}';
                string strJsonBody = Test.isRunningTest() ? strTestJsonBody : res.getBody();
                strJsonBody = strJsonBody.replaceall('\n','');
                Map<String, Object> m = (Map<String, Object>) JSON.deserializeUntyped(strJsonBody);
                Map<String, Object> m2 = (Map<String, Object>)m.get('Opinion');
                string result = '';
                if(m2.containskey('Result')){
                    result = string.valueof(m2.get('Result'));
                }
                mapValidResults.put(result, strJsonBody);
            }
        } catch (Exception ex){
            return null;
        }
        return mapValidResults;
    }
    
    //creating request body for to verify test websites.
    public static string CreateRequestBody(List<Root_Case__c> lstRootCases){
        string strRequest = '';
        if(lstRootCases.size() > 0) {
            string strRootCases = '';
            //Integer count = 0;
            for(Root_Case__c rootcase: lstRootCases){
                //if(count == 1) break; //added for testing
                if(rootcase.X_509_Certificate_PEM__c != null && rootcase.X_509_Certificate_PEM__c.length() > 0
                    && (string.isnotblank(rootcase.Test_Website_Valid__c) || string.isnotblank(rootcase.Test_Website_Revoked__c) ||
                        string.isnotblank(rootcase.Test_Website_Expired__c))) {
                    strRootCases += '{"RecordID":"'+rootcase.Id+'",';
                    strRootCases += '"Name":"'+rootcase.Root_Certificate_Name__c+'",';
                    string strPEM = rootcase.X_509_Certificate_PEM__c.normalizeSpace();
                    //system.debug('strPEM Contains: ' + strPEM.containsWhitespace());
                    //system.debug('strPEM  :: '+strPEM );
                    strRootCases += '"PEM":"'+strPEM +'",';
                    if(string.isnotblank(rootcase.Test_Website_Valid__c)){
                        strRootCases += '"TestWebsiteValid":"'+rootcase.Test_Website_Valid__c+'"';
                    }
                    if(string.isnotblank(rootcase.Test_Website_Revoked__c)){
                        strRootCases += ',"TestWebsiteRevoked":"'+rootcase.Test_Website_Revoked__c+'"';
                    }
                    if(string.isnotblank(rootcase.Test_Website_Expired__c)){
                        strRootCases += ',"TestWebsiteExpired":"'+rootcase.Test_Website_Expired__c+'"';
                    }
                    strRootCases += '},';
                    //count++;
                }
            }
            if(strRootCases.length() > 0) {
                strRootCases = strRootCases.substring(0, strRootCases.length() - 1);
            }
            strRequest = '{ "CertificateDetails":['+ strRootCases +'] }';
        }
        return strRequest;
    }
    /*
        Class created to parse response.
    */
    public class parseTestWebsiteResults {
        public String SubjectURL; 
        public String RecordID;
        public String Expectation; 
        public cls_Chain Chain;
        public cls_Opinion Opinion;
        public String Error;
    }
    class cls_Chain {
        public cls_Leaf Leaf;
        public List<cls_Intermediates> Intermediates;
        public cls_Root Root;
    }
    class cls_Leaf {
        public String Fingerprint;
        public String CrtSh; 
        public String CommonName;
        public List<cls_OCSP> OCSP;
        public List<cls_CRL> CRL;
        public cls_Expiration Expiration;
    }
    class cls_OCSP {
        public string Error;
        public string Responder;
        public string Status;
    }
    class cls_CRL {
        public string Error;
        public string Endpoint;
        public string Status;
    }
    class cls_Expiration {
        public String Error;
        public String Status; 
    }
    class cls_Intermediates {
        public String Fingerprint;
        public String CrtSh;
        public String CommonName; 
        public List<cls_OCSP> OCSP;
        public List<cls_CRL> CRL;
        public cls_Expiration Expiration;
    }
    class cls_Root {
        public String Fingerprint;
        public String CrtSh; 
        public String CommonName;
        public List<cls_OCSP> OCSP;
        public List<cls_CRL> CRL;
        public cls_Expiration Expiration;
    }
    class cls_Opinion {
        public String Result; 
        public List<cls_Errors> Errors;
    }
    class cls_Errors {
        public String Raw; 
        public String Interpretation; 
        public String Advise;
    } 
}
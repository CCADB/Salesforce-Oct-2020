/*******************************************************************************************************
 Name: JixiServiceController

 Dependencies:  JixiServiceController controller class, 
 JixiServiceControllerTest test class, JixiService vf page

 Description: Audit Letter Validation or Jixi service allows root store managers to validate 
 audit docuemnts. It is invoked from a button "Audit Letter Validation" on Audit Case page. 
 A self signed certificate is required to authenticate and establish the connection. 
 
 1. Prepare a request from Case and Root Case records. Method Name: prepareRequest
 2. Do a Callout. Method Name: doCallout
 3. Perform Post Callout Activities. Method Name: postCallActions
 
 Instructions: None

 *******************************************************************************************************
 Revision History:

 02/15/1019  Changed parameter in prepareRequest() from EVCodeSigningApplied to EVCodeSigningAuditApplied
 06/20/2019  Changed in Microsoft Trust bits, do union of Mozilla and Microsoft and passed to ALV
 06/21/2019  Changes Mozilla Trust Bits "Email" to "Secure Email"
 10/01/2019  Replaced "Cleaned" with "AuditLocation"
 07/17/2020  Success Log added, Check line 398 on which text seperating success log
***************************************************************************************************/

public class JixiServiceController{
    
    public Case caseSO {get; private set;}
    public String request{get; private set;}
    public String response{get; private set;}
    public Boolean hasErrors{get; private set;}
    public String statusText {get; set;}
    public List<Root_Case__c> lstRootCases{get; private set;}
    public List<JixiServiceTokens.ErrorLogAndActions> lstErrorLog {get; private set;}
    public List<JixiServiceTokens.ErrorLogAndActions> lstSuccessLog {get; private set;}
    
    private Map<Integer, String> mapHttpStatusCodes;
    
    public JixiServiceController(ApexPages.StandardController stdCon){
        
        this.caseSO = getCaseRecord(stdCon.getId());
                       
        this.hasErrors = false;
        this.statusText = 'Invoking ALV Sevice...  <br/>';
        this.lstErrorLog = new List<JixiServiceTokens.ErrorLogAndActions>();
        this.lstSuccessLog = new List<JixiServiceTokens.ErrorLogAndActions>();
        
        this.lstRootCases = new List<Root_Case__c>();
        this.lstRootCases = this.caseSO.Root_Cases__r;
        this.hasErrors = this.lstRootCases.isEmpty();
        mapHttpStatusCodes = new Map<Integer, String>();  
        mapHttpStatusCodes.put(204, 'Error Code: 204 - The server successfully processed the request and is not returning any content.');            
        mapHttpStatusCodes.put(400, 'Error Code: 400 - Bad Request');
        mapHttpStatusCodes.put(401, 'Error Code: 401 - Unauthorized Request. Authentication failed.');
        mapHttpStatusCodes.put(403, 'Error Code: 403 - Forbidden, Request is valid but Server refused action.');
        mapHttpStatusCodes.put(404, 'Error Code: 404 - The requested resource could not be found but may be available in the future.');
        mapHttpStatusCodes.put(408, 'Error Code: 408 - The server timed out waiting for the request.'); 
        mapHttpStatusCodes.put(500, 'Error Code: 500 - Internal Server Error. Unexpected condition was encountered.');
        mapHttpStatusCodes.put(501, 'Error Code: 501 - Not Implemented. The server either does not recognize the request method, or it lacks the ability to fulfill the request.');
        mapHttpStatusCodes.put(503, 'Error Code: 503 - Service Unavailable. The server is currently unavailable.');
    }
    
    /*
    * get Case Record
    */
    private Case getCaseRecord(Id caseId){
       
       return [SELECT Id, CaseNumber, Account.Name, Auditor_New__r.Name, Auditor_New__r.Alternate_Auditor_Name_s__c,
       Standard_Audit_Type__c, Standard_Audit_Statement_Date__c,     
       Standard_Audit_Period_Start_Date__c,Standard_Audit_Period_End_Date__c,
       Standard_Audit_Statement_Link__c, Standard_Audit_Verified__c,
       Code_Signing_Audit_Type__c, Code_Signing_Audit_Statement_Date__c, 
       Code_Signing_Audit_Period_Start_Date__c, Code_Signing_Audit_Period_End_Date__c, 
       Code_Signing_Audit_Statement_Link__c, Code_Signing_Audit_Verified__c,
       BR_Audit_Type__c,BR_Audit_Statement_Date__c,
       BR_Audit_Period_Start_Date__c,BR_Audit_Period_End_Date__c,
       BR_Audit_Statement_Link__c, BR_Audit_Statement_Link_Verified__c,
       EV_Audit_Type__c, EV_Audit_Statement_Date__c,
       EV_Audit_Period_Start_Date__c, EV_Audit_Period_End_Date__c,
       EV_Audit_Statement_Link__c, EV_Audit_Statement_Link_Verified__c,
       EV_Code_Signing_Audit_Type__c, EV_Code_Signing_Audit_Statement_Date__c,
       EV_Code_Signing_Audit_Period_Start_Date__c, EV_Code_Signing_Audit_Period_End_Date__c,
       EV_Code_Signing_Audit_Statement_Link__c, EV_Code_Signing_Verified__c,
       Standard_Audit_Auto_Review_Status__c, Standard_Audit_Auto_Review_Results__c, 
       BR_Audit_Auto_Review_Status__c, BR_Audit_Auto_Review_Results__c, 
       Code_Signing_Audit_ALV_Status__c, Code_Signing_Audit_ALV_Results__c,
       EV_SSL_Audit_Auto_Review_Status__c, EV_SSL_Audit_Auto_Review_Results__c, 
       EV_Code_Signing_Audit_AutoReviewStatus__c, EV_Code_Signing_Audit_AutoReviewResults__c,        
             (SELECT Id, Name, Included_Certificate_Name__c, Root_Certificate_Name_Existing__c, 
       SHA_1_Fingerprint__c, SHA_256_Fingerprint__c, 
       Apply_Standard_Audit__c, Apply_Code_Signing_Audit__c, Apply_BR_Audit__c, Apply_EV_Audit__c, Apply_EV_Code_Signing_Audit__c,
       Microsoft_Trust_Bits__c, Trust_Bits__c, Microsoft_EV_Enabled__c, Auto_Review_Status__c, Auto_Review_Results__c
       FROM Root_Cases__r) 
       FROM Case
       WHERE Id = :caseId];
    }
    
    /*
    * prepareRequest - prepare request JSON at the begining of page load.
    */
    public void prepareRequest(){
        
        try{
        //pass concatinated Audior name and Alternate Auditor names
        String auditor = caseSO.Auditor_New__r.Name;
        auditor += (caseSO.Auditor_New__r.Alternate_Auditor_Name_s__c != null ?  (';' + caseSO.Auditor_New__r.Alternate_Auditor_Name_s__c) : '');
        //Code added by Sunil - Use JSON Generator to generate request in proper sequence.
        JSONGenerator gen = JSON.createGenerator(true);
        
        //start main object
        gen.writeStartObject();
        
        gen.writeStringField('CaseRecordID', caseSO.Id);
        gen.writeStringField('CaseNumber', caseSO.CaseNumber);
        gen.writeStringField('CAOwnerName', caseSO.Account.Name);
        gen.writeStringField('Auditor', auditor);
        
        //start StandardAudit
        gen.writeFieldName('StandardAudit');
        gen.writeStartObject();
        
        gen.writeStringField('AuditType', caseSO.Standard_Audit_Type__c != null ? caseSO.Standard_Audit_Type__c : '');
        gen.writeStringField('StatementDate', caseSO.Standard_Audit_Statement_Date__c != null ? String.valueOf(caseSO.Standard_Audit_Statement_Date__c) : '');
        gen.writeStringField('AuditPeriodStart', caseSO.Standard_Audit_Period_Start_Date__c != null ? String.valueOf(caseSO.Standard_Audit_Period_Start_Date__c) : '');
        gen.writeStringField('AuditPeriodEnd', caseSO.Standard_Audit_Period_End_Date__c != null ? String.valueOf(caseSO.Standard_Audit_Period_End_Date__c) : '');
        gen.writeStringField('Link', caseSO.Standard_Audit_Statement_Link__c != null ? caseSO.Standard_Audit_Statement_Link__c : '');
        
        //end StandardAudit
        gen.writeEndObject();
        
        //start code signing audit
        gen.writeFieldName('CodeSigningAudit');
        gen.writeStartObject();
        
        gen.writeStringField('AuditType', caseSO.Code_Signing_Audit_Type__c != null ? caseSO.Code_Signing_Audit_Type__c : '');
        gen.writeStringField('StatementDate', caseSO.Code_Signing_Audit_Statement_Date__c != null ? String.valueOf(caseSO.Code_Signing_Audit_Statement_Date__c) : '');
        gen.writeStringField('AuditPeriodStart', caseSO.Code_Signing_Audit_Period_Start_Date__c != null ? String.valueOf(caseSO.Code_Signing_Audit_Period_Start_Date__c) : '');
        gen.writeStringField('AuditPeriodEnd', caseSO.Code_Signing_Audit_Period_End_Date__c != null ? String.valueOf(caseSO.Code_Signing_Audit_Period_End_Date__c) : '');
        gen.writeStringField('Link', caseSO.Code_Signing_Audit_Statement_Link__c != null ? caseSO.Code_Signing_Audit_Statement_Link__c : '');
        
        gen.writeEndObject();
        //end code signing audit
        
        //start BRAudit
        gen.writeFieldName('BRAudit');
        gen.writeStartObject();
        
        gen.writeStringField('AuditType', caseSO.BR_Audit_Type__c != null ? caseSO.BR_Audit_Type__c : '');
        gen.writeStringField('StatementDate', caseSO.BR_Audit_Statement_Date__c != null ? String.valueOf(caseSO.BR_Audit_Statement_Date__c) : '');
        gen.writeStringField('AuditPeriodStart', caseSO.BR_Audit_Period_Start_Date__c != null ? String.valueOf(caseSO.BR_Audit_Period_Start_Date__c) : '');
        gen.writeStringField('AuditPeriodEnd', caseSO.BR_Audit_Period_End_Date__c != null ? String.valueOf(caseSO.BR_Audit_Period_End_Date__c) : '');
        gen.writeStringField('Link', caseSO.BR_Audit_Statement_Link__c != null ? caseSO.BR_Audit_Statement_Link__c : '');
        
        //end BRAudit
        gen.writeEndObject();
        
        //start EVSSL
        gen.writeFieldName('EVSSLAudit');
        gen.writeStartObject();
        
        gen.writeStringField('AuditType', caseSO.EV_Audit_Type__c != null ? caseSO.EV_Audit_Type__c : '');
        gen.writeStringField('StatementDate', caseSO.EV_Audit_Statement_Date__c != null ? String.valueOf(caseSO.EV_Audit_Statement_Date__c) : '');
        gen.writeStringField('AuditPeriodStart', caseSO.EV_Audit_Period_Start_Date__c != null ? String.valueOf(caseSO.EV_Audit_Period_Start_Date__c) : '');
        gen.writeStringField('AuditPeriodEnd', caseSO.EV_Audit_Period_End_Date__c != null ? String.valueOf(caseSO.EV_Audit_Period_End_Date__c) : '');
        gen.writeStringField('Link', caseSO.EV_Audit_Statement_Link__c != null ? caseSO.EV_Audit_Statement_Link__c : '');
        
        //end EVSSL
        gen.writeEndObject();
        
        //start EVCodeSigning
        gen.writeFieldName('EVCodeSigningAudit');
        gen.writeStartObject();
        
        gen.writeStringField('AuditType', caseSO.EV_Code_Signing_Audit_Type__c != null ? caseSO.EV_Code_Signing_Audit_Type__c : '');
        gen.writeStringField('StatementDate', caseSO.EV_Code_Signing_Audit_Statement_Date__c != null ? String.valueOf(caseSO.EV_Code_Signing_Audit_Statement_Date__c) : '');
        gen.writeStringField('AuditPeriodStart', caseSO.EV_Code_Signing_Audit_Period_Start_Date__c != null ? String.valueOf(caseSO.EV_Code_Signing_Audit_Period_Start_Date__c) : '');
        gen.writeStringField('AuditPeriodEnd', caseSO.EV_Code_Signing_Audit_Period_End_Date__c != null ? String.valueOf(caseSO.EV_Code_Signing_Audit_Period_End_Date__c) : '');
        gen.writeStringField('Link', caseSO.EV_Code_Signing_Audit_Statement_Link__c != null ? caseSO.EV_Code_Signing_Audit_Statement_Link__c : '');
        
        //end EVCodeSigning
        gen.writeEndObject();

        //start rootcases
        gen.writeFieldName('RootCases');
        gen.writeStartArray();
        for(Root_Case__c rootCase : caseSO.Root_Cases__r){
            //start object
            gen.writeStartObject();

            gen.writeStringField('RootCaseRecordID', rootCase.Id);
            gen.writeStringField('RootCaseNumber', rootCase.Name);
            gen.writeStringField('Name', rootCase.Included_Certificate_Name__c != null ? rootCase.Included_Certificate_Name__c : '');
            gen.writeStringField('SHA1Thumbprint', rootCase.SHA_1_Fingerprint__c != null ? rootCase.SHA_1_Fingerprint__c : '');
            gen.writeStringField('SHA256Thumbprint', rootCase.SHA_256_Fingerprint__c != null ? rootCase.SHA_256_Fingerprint__c : '');
            
            //combined Trust bits of Mozilla and Microsoft.
            string strMicrosoftTrustBits = '';
            set<string> setOfTrustBits = new set<string>();
            if(rootCase.Microsoft_Trust_Bits__c != null && string.isnotblank(rootCase.Microsoft_Trust_Bits__c)){
                setOfTrustBits.addall(rootCase.Microsoft_Trust_Bits__c.split(';'));
            }
            if(rootCase.Trust_Bits__c != null && string.isnotblank(rootCase.Trust_Bits__c)) {
                for(string str: rootCase.Trust_Bits__c.split(';')){
                    if(string.isnotblank(str)) {
                        if(str.trim() == 'Websites') {
                            setOfTrustBits.add('Server Authentication');
                        } else if(str.trim() == 'Email') {
                            setOfTrustBits.add('Secure Email');
                        }
                    }
                }
            }
            if(setOfTrustBits.size() > 0){
                List<string> lstTrustBits = new List<string>();
                lstTrustBits.addall(setOfTrustBits);
                strMicrosoftTrustBits = string.join(lstTrustBits,';');
            }
            gen.writeStringField('MicrosoftTrustBits', strMicrosoftTrustBits);
            
            gen.writeStringField('MicrosoftEVEnabled', String.valueOf(rootCase.Microsoft_EV_Enabled__c));
            gen.writeStringField('StandardAuditApplied', String.valueOf(rootCase.Apply_Standard_Audit__c));
            gen.writeStringField('CodeSigningAuditApplied', String.valueOf(rootCase.Apply_Code_Signing_Audit__c));
            gen.writeStringField('BRAuditApplied', String.valueOf(rootCase.Apply_BR_Audit__c));
            gen.writeStringField('EVSSLAuditApplied', String.valueOf(rootCase.Apply_EV_Audit__c));
            gen.writeStringField('EVCodeSigningAuditApplied', String.valueOf(rootCase.Apply_EV_Code_Signing_Audit__c));
            //end object
            gen.writeEndObject();
        }
        //end rootcases
        gen.writeEndArray();
        //gen.writeObjectField('RootCases', lstCertificates);
        
        //end main object
        gen.writeEndObject();
        
        this.request = gen.getAsString();
        
        System.debug('Request'+this.request);
        
        }catch(Exception exp){
            
            this.hasErrors = true;
            this.response = exp.getMessage() + ' Please contact your administrator.';
            // System.debug(exp.getStackTraceString());
            // System.debug(exp.getLineNumber());
            
        }
        this.statusText += 'Sending HTTPS request to ALV Sevice...  <br/>';
    }
    
    /*
    * doCallout - do an actual callout to Jixi server
      TODO: Create a custom setting and put all integration variables there.
    */
    public void doCallout(){
        
        if(!this.hasErrors){
            
            try{
                                
                Jixi_Integration_Tokens__c tokens = Jixi_Integration_Tokens__c.getInstance('Jixi Service Tokens');
                //system.debug(tokens);
                
                HttpRequest hReq = new HttpRequest();
                hReq.setHeader('Content-Type', 'application/json');
                hReq.setEndpoint(tokens.Service_Endpoint__c);//don't forget to set remote site setting for this endpoint.
                hReq.setMethod(tokens.HTTP_Method__c);
                hReq.setBody(this.request);
                hReq.setTimeout(Integer.valueOf(tokens.Timeout__c));
                hReq.setClientCertificateName(tokens.Client_Certification_Name__c);
                
                Http http = new Http();
                System.debug('H Request Body'+hReq.getBody());
                HttpResponse hRes = http.send(hReq);
                
                System.debug(hRes.getHeaderKeys());
                System.debug(hRes.getHeader('Location')); //if response code 201 CREATED then Jixi is returning "https://ccadbwebapiservice.azurewebsites.net/api/CAs/50063000004KUgE" in location
                System.debug(hRes.getBody());
                                
                //200 OK, 201 CREATED, 202 ACCEPTED
                if(hRes != null && (hRes.getStatusCode() == 200 || hRes.getStatusCode() == 201 || hRes.getStatusCode() == 202)){
                    this.response = hRes.getBody();
                    // System.debug(this.response);
       
                }else{
                    System.debug(hRes);
                    this.hasErrors = true;
                    this.response = mapHttpStatusCodes.containsKey(hRes.getStatusCode()) ? mapHttpStatusCodes.get(hRes.getStatusCode()) +
                     ' Please contact your administrator.' : 'Unexpected Error Occurred. Please contact your administrator.' + this.response;
                }
            }catch(Exception exp){
                System.debug(exp.getMessage());
                System.debug(exp.getStackTraceString());
                System.debug(exp.getLineNumber());
                this.hasErrors = true;
                this.response = exp.getMessage() + ' Please contact your administrator.';               
            }
        }
        
        this.statusText += 'Parsing Response and updating Case & Root Case records...  <br/>'; //'Sending HTTPS POST to Jixi Sevice';
    }
    
    /*
    * postCallActions - Get the response string, parse and update case & root case records
    */
    public PageReference postCallActions(){
        
        //this.hasErrors = true;
        pageReference pref = null;
        if(this.hasErrors){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, this.response));
            return pref;
        }

        try{
            
            //if no errors so far then parse the response
            JixiServiceTokens.JixiServiceResponse result = JixiServiceTokens.parse(this.response);
            // System.debug(result);
            
            //update case record
            Case caseSO = new Case(Id = result.CaseRecordID);
            
            //update Standard audit
            if(this.caseSO.Standard_Audit_Statement_Link__c != null){
                caseSO.Standard_Audit_Auto_Review_Status__c = result.StandardAudit.AutoReviewStatus;
                caseSO.Standard_Audit_Auto_Review_Results__c = result.StandardAudit.AutoReviewResults;
            } else {
                caseSO.Standard_Audit_Auto_Review_Status__c = '';
                caseSO.Standard_Audit_Auto_Review_Results__c = '';           
            }
            
            // update Standard Audit Deviation each time ALV is run            
            if(this.caseSO.Standard_Audit_Verified__c != 'Data Verified' && caseSO.Standard_Audit_Auto_Review_Results__c != null && caseSO.Standard_Audit_Auto_Review_Results__c.contains('AuditLocation=Fail')){
                    caseSO.Standard_Deviation__c = true;                     
            }
            
            //update Code Signing audit
            if(this.caseSO.Code_Signing_Audit_Statement_Link__c != null){
                caseSO.Code_Signing_Audit_ALV_Status__c = result.CodeSigningAudit.AutoReviewStatus;
                caseSO.Code_Signing_Audit_ALV_Results__c = result.CodeSigningAudit.AutoReviewResults;
            } else {
                caseSO.Code_Signing_Audit_ALV_Status__c = '';
                caseSO.Code_Signing_Audit_ALV_Results__c  = '';           
            }
            
            // update Code Signing Audit Deviation each time ALV is run            
            if(this.caseSO.Code_Signing_Audit_Verified__c != 'Data Verified' && caseSO.Code_Signing_Audit_ALV_Results__c != null && caseSO.Code_Signing_Audit_ALV_Results__c.contains('AuditLocation=Fail')){
                    caseSO.Code_Signing_Deviation__c = true;                     
            }            
            
            //update BR audit        
            if(this.caseSO.BR_Audit_Statement_Link__c != null){
                caseSO.BR_Audit_Auto_Review_Status__c = result.BRAudit.AutoReviewStatus;
                caseSO.BR_Audit_Auto_Review_Results__c = result.BRAudit.AutoReviewResults;
            } else {
                caseSO.BR_Audit_Auto_Review_Status__c = '';
                caseSO.BR_Audit_Auto_Review_Results__c = '';
            }
            
            // update BR Audit Deviation each time ALV is run            
            if(this.caseSO.BR_Audit_Statement_Link_Verified__c != 'Data Verified' && caseSO.BR_Audit_Auto_Review_Results__c != null && caseSO.BR_Audit_Auto_Review_Results__c.contains('AuditLocation=Fail')){
                    caseSO.BR_Deviation__c = true;                     
            }              
                        
            //update EV SSL audit
            if(this.caseSO.EV_Audit_Statement_Link__c != null){
                caseSO.EV_SSL_Audit_Auto_Review_Status__c = result.EVSSLAudit.AutoReviewStatus;
                caseSO.EV_SSL_Audit_Auto_Review_Results__c = result.EVSSLAudit.AutoReviewResults;
            } else {
                caseSO.EV_SSL_Audit_Auto_Review_Status__c = '';
                caseSO.EV_SSL_Audit_Auto_Review_Results__c = '';
            }
            
            // update EV SSL Audit Deviation each time ALV is run            
            if(this.caseSO.EV_Audit_Statement_Link_Verified__c != 'Data Verified' && caseSO.EV_SSL_Audit_Auto_Review_Results__c != null && caseSO.EV_SSL_Audit_Auto_Review_Results__c.contains('AuditLocation=Fail')){
                    caseSO.EV_SSL_Deviation__c = true;                     
            }            
            
            //update EV Code Signing
            if(this.caseSO.EV_Code_Signing_Audit_Statement_Link__c != null){
                caseSO.EV_Code_Signing_Audit_AutoReviewStatus__c = result.EVCodeSigningAudit.AutoReviewStatus;
                caseSO.EV_Code_Signing_Audit_AutoReviewResults__c = result.EVCodeSigningAudit.AutoReviewResults;
            } else {
                caseSO.EV_Code_Signing_Audit_AutoReviewStatus__c = '';
                caseSO.EV_Code_Signing_Audit_AutoReviewResults__c = '';
            }
            
            // update EV Code Signing Audit Deviation each time ALV is run            
            if(this.caseSO.EV_Code_Signing_Verified__c != 'Data Verified' && caseSO.EV_Code_Signing_Audit_AutoReviewResults__c != null && caseSO.EV_Code_Signing_Audit_AutoReviewResults__c.contains('AuditLocation=Fail')){
                caseSO.EV_Code_Signing_Deviation__c = true;                     
            }            
            
            
            string strSuccessLogText = 'Succeed to validate EKU';
            List<JixiServiceTokens.ErrorLogAndActions> lstLogs = result.ErrorLogAndActions != null ? result.ErrorLogAndActions : new List<JixiServiceTokens.ErrorLogAndActions>();
            for(JixiServiceTokens.ErrorLogAndActions log: lstLogs){ 
                if(log.ErrorLog.contains(strSuccessLogText)){
                    this.lstSuccessLog.add(log); 
                } else {
                    this.lstErrorLog.add(log); 
                }
            }
            
            //update root cases
            List<Root_Case__c> lstRootCases = new List<Root_Case__c>();
            for(JixiServiceTokens.RootCasesResult rootCaseResult : result.RootCases){
                
                Root_Case__c rootCase = new Root_Case__c(Id = rootCaseResult.RootCaseRecordID);
                rootCase.Auto_Review_Status__c = String.valueOf(rootCaseResult.AutoReviewStatus);
                rootCase.Auto_Review_Results__c = rootCaseResult.AutoReviewResults;
                lstRootCases.add(rootCase);
            }
            
            update caseSO;
            
            if(lstRootCases.size() > 0){
                update lstRootCases;
            }
            
            pref = new PageReference('/'+caseSO.Id); //stdCon.view();
            
        }catch(Exception exp){
            System.debug(exp.getMessage());
            System.debug(exp.getStackTraceString());
            System.debug(exp.getLineNumber());
            this.hasErrors = true;
            this.response = this.response +'\n***** ERROR ****: '+exp.getMessage();
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, this.response));
        }
        
        this.caseSO = getCaseRecord(this.caseSO.Id);
                        
        this.lstRootCases = new List<Root_Case__c>();
        
        this.lstRootCases = this.caseSO.Root_Cases__r;
                       
        return null; //change it to 'pref' then it won't wait on the screen and directly go to Case record detail page
    }
    
    public PageReference downloadLog(){
        
        PageReference pref = Page.JixiServiceErrorReport;
        pref.getParameters().put('id', this.caseSO.Id);
        pref.setRedirect(false);
        
        return pref;
    }
    
    /* Code mey be used later to send http request Asynchronously 
    @future(Callout=true)
    public static void callAPI(){
        Jixi_Integration_Tokens__c tokens = Jixi_Integration_Tokens__c.getInstance('Jixi Service Tokens');
        //system.debug(tokens);
        
        HttpRequest hReq = new HttpRequest();
        hReq.setHeader('Content-Type', 'application/json');
        hReq.setEndpoint(tokens.Service_Endpoint__c);//don't forget to set remote site setting for this endpoint.
        hReq.setMethod(tokens.HTTP_Method__c);
        string strBody = '{'+
                                 '"CaseRecordID" : "500e000000ESaPXAA1",'+
                                 '"CaseNumber" : "10000338",'+
                                 '"CAOwnerName" : "DigiCert",'+
                                 '"Auditor" : "null",'+
                                 '"StandardAudit" : {'+
                                    '"AuditType" : "WebTrust",'+
                                    '"StatementDate" : "2019-01-29",'+
                                    '"AuditPeriodStart" : "2017-11-01",'+
                                    '"AuditPeriodEnd" : "2018-10-31",'+
                                    '"Link" : "https://content.digicert.com/wp-content/uploads/2019/01/DigiCert-Symantec-WTCA-Indp-Acct-Opinion-and-Mgmt-Assertion-Oct-2018-FINAL.pdf"'+
                                 '}'+
                                 '"RootCases" : [ {'+
                                 '"RootCaseRecordID" : "a00e000000AmZZ1AAN",'+
                                 '"RootCaseNumber" : "R00000744",'+
                                 '"Name" : "VeriSign Class 3 Public Primary Certification Authority - G3",'+
                                 '"SHA1Thumbprint" : "132D0D45534B6997CDB2D5C339E25576609B5CC6",'+
                                 '"SHA256Thumbprint" : "EB04CF5EB1F39AFA762F2BB120F296CBA520C1B97DB1589565B81CB9A17B7244",'+
                                 '"MicrosoftTrustBits" : "Server Authentication;Client Authentication;Code Signing;Secure Email",'+
                                 '"MicrosoftEVEnabled" : "false",'+
                                 '"StandardAuditApplied" : "false",'+
                                 '"CodeSigningAuditApplied" : "true",'+
                                 '"BRAuditApplied" : "true",'+
                                 '"EVSSLAuditApplied" : "true",'+
                                 '"EVCodeSigningAuditApplied" : "true"'+
                                 '} ]' +
                                 '}';
        hReq.setBody(strBody);
        hReq.setTimeout(Integer.valueOf(tokens.Timeout__c));
        hReq.setClientCertificateName(tokens.Client_Certification_Name__c);
        
        Http http = new Http();
        
        HttpResponse hRes = http.send(hReq);
        
        System.debug(hRes.getHeaderKeys());
        System.debug(hRes.getHeader('Location')); //if response code 201 CREATED then Jixi is returning "https://ccadbwebapiservice.azurewebsites.net/api/CAs/50063000004KUgE" in location
        System.debug(hRes.getBody());
    }*/
}
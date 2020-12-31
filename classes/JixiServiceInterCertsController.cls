/*******************************************************************************************************
 Name: JixiServiceInterCertsController

 Dependencies:  JixiServiceInterCertsController controller class, 
 JixiServiceInterCertsControllerTest test class, JixiServiceInterCerts vf page

 Description: Audit Letter Validation for Intermediate Certs or Jixi service allows root store managers 
 and CAs to validate audit docuemnts. It is invoked from a button "Audit Letter Validation" from 
 Intermediate Cert record and slso from nightly batch program. 
 
 ==== High Level Implementation Details ====

 There is a "Derived Trust Bits" field in the "Certificate Data [Fields
 NOT editable; extracted from PEM]" section. Very high level logic: If
 the cert has EKU in it, then that will be used. Otherwise see which root
 store it's parent root cert is in. If in both Mozilla and Microsoft then
 create union of the trust bits that the parent/root cert is trusted for.

 When "Derived Trust Bits" contains 'Server Authentication', then ALV is
 run on the BR audit. Currently, for intermediate certs, we are only
 processing the standard and BR audit statements.

 When "Audits Same as Parent" is checked, CCADB will look up the parent
 chain until audit statements are found, and run ALV using those audit
 statements. When "Audits Same as Parent" is not checked, then CCADB will
 just pass the audit statements in the intermediate cert record into ALV.
 
 The "Standard Audit ALV Found Cert" and "BR Audit ALV Found Cert" are
 set according to the ALV result AllThumbprintsListed, which looks for
 the cert's SHA-256 fingerprint in the corresponding audit statement.
 
 ==== TechinicalImplementation Details ====
 
 A self signed certificate is required to authenticate and establish the connection. Only one intermediate 
 cert data is send in the https request to process.
 
 1. Prepare a request from Intermediate cert and related root cert record. Method Name: prepareRequest
 2. Do a Callout. Method Name: doCallout
 3. Perform Post Callout Activities. Method Name: postCallActions
 
 ====
 
 First 'Derived Trust Bits' field is repopulated by (AccountTriggerHelper.getDerivedTrustBits) before calling
 ALV webservice.
 ====
 
 Display error when following conditions are not met or skip record when batch processing:
 
 Revokation Status <> Not Revoked
 Valid To > Today
 Subordinate CA Owner <> blank when "Audit Same As Parent" is false 
 ====
 
 If "Audit Same As Parent" is True  
       Use Audit and Auditor information from parent 
       Use that parent intermediate cert’s “Subordinate CA Owner” field for the CAOwnerName 
       to pass into ALV. If the parent is Root Cert then use CA Owner Name.
  else
      Use Subordinate CA Owner, Audit and Auditor information from the current intermediate cert.
 ==== 
 If Derived Trust Bits is empty "Client Authentication" is passed to ALV, so that standard audit gets checked.

 When Derived Trust Bits are not blank then check if Server Authentication or Secure Email or 
 Client Authentication is present (regardless of “Audits Same as Parent” true or false).
      - If one or more are found then pass those Derived trust Bits
      - If these values not found, then pass only "Client Authentication"
 
 ====
 When “Audits Same as Parent” is true, only use the following trust bits (when they are in the Derived Trus Bits list).
 Server Authentication
 Secure Email
 Client Authentication
 
 For example, if Derived Trust Bits on inter cert =
     Client Authentication;Code Signing;Time Stamping
 Then only send "Client Authentication" to ALV.

 For example, if Derived Trust Bits on inter cert =
     Server Authentication, Client Authentication;Code Signing;Time Stamping
 Then only send "Server Authentication" and "Client Authentication" to ALV.
 
 When “Audits Same as Parent” is true, pass parent Standard audits to ALV.
 When “Audits Same as Parent” is false, pass current Standard audits to ALV.

 Code Signing audits are not passed, send blank audits and Apply Code Signing = False to ALV

 When Derived Trust Bits contains “Server Authentication" send the BR Audit and 
 Apply BR Audit = True (even when BR Audit is blank). Use the parent's BR audit 
 when “Audits Same as Parent” is true, and use the current BR audit when 
 “Audits Same as Parent” is false.
 When Derived Trust Bits does not contain “Server Authentication" then
 Apply BR Audit = False is passed into ALV, and do not pass in a BR audit (even if one is found).
 "BR Audit ALV Status" gets set to blank, even if a BR audit was provided.

 EV SSL audits are not passed, send blank audits and Apply EV SSL = False to ALV

 EV Code Signing audits are not passed, send blank audits and Apply EV Code Signing = False to ALV
 
 ===
 
 These fields should get populated when ALV is run, based on the ALV results...
 If AllThumbprintsListed=Fail set the "Found Cert" field to FAIL
 If AllThumbprintsListed=Pass set the "Found Cert" field to PASS
 If no ALV results, set the "Found Cert" field to empty
 ===
  
 "MicrosoftEVEnabled" is always passed as "False"
 ==
 
 When "Audits Same as Parent" is true, 'AuditLocation=Fail; ' and 'AuditLocation=Pass;'
 are replaced by blank in ALV Results and not counted in ALV Status. This is because 
 intermediate certs should not get penalized for the root certs audit statements 
 not being in an authorized location.
 ===
 
 ALV-rerun is needed when any of the Audit Statement Dates > ALV Process Date.
 
 AccountTrigger.UpdateALVDateProcessed() method clears the ALV fields when Auditor and Audit fields are updated.
 
 A nightly batch job (RunALVForInterCertsBatch) also uses this controller.

 Instructions: The  ALV webservice was initially created for Case/RootCase records and the JSON definition
 has not been modify for intermediate certs. That is why the this prorgam is referencing Case/RootCase  
 attributes. 

 
 *******************************************************************************************************
 Revision History:
 
      5/2/2019 - Created new class
      5/10/2019 - Replacing Microsoft Trust Bits with Derived Trust Bits
      6/3/2019  - Updated controller to allow run ALV for intermediatecerts where Audit same as parent is checked.
      6/7/2019  - Updated class to read auditor infomration from parent when audit same as parent is checked. 
                  Also copied CA Owner to Subordinate CA Owner.
      6/21/2019 - Uncommented EVCodeSigning (althought it is not being used on inter certs) to make the HTTP
                  request identical to Case ALV request; Added "Audit Same As Parent" condition for Apply fields
      6/23/2019 - We are passing Blank EV Code Signing Audit as we are not using for Intermediate certs and the reason is added to make consitant same as case ALV.
      7/29/2019 - Added validation to check if valid from date is greater than any audit period end date the show error.
      9/22/2019 - Changed logic for passing derived trust bits when Audit same as parent is checked.
      10/1/2019 - BR logic was updated
      9/21/2020 - As Derived Trust bits logic has changed, Updated codes to manage that.
 ******************************************************************************************************/


public class JixiServiceInterCertsController{
    
    public Account accountSO {get; private set;}
    public Account parentaccountSO {get; private set;}
    public String request{get; private set;}
    public String response{get; private set;}
    public Boolean hasErrors{get; private set;}
    public Boolean IsNewCertificate {get; private set;}
    public string TrustBits {get; set;}
    public string CAOwnerName {get; set;}
    public String statusText {get; set;}
    public List<JixiServiceTokens.ErrorLogAndActions> lstErrorLog {get; private set;}
    
    private Map<Integer, String> mapHttpStatusCodes;
    
    public JixiServiceInterCertsController(ApexPages.StandardController stdCon){
        
        this.accountSO = getInterCertsRecord(stdCon.getId());
        IsNewCertificate = false;
        this.response = '';
        this.hasErrors = false;
        //remove validation when account is Audit same as parent.
        //this.hasErrors = this.accountSO.Audits_Same_as_Parent__c;
        
        //Cert must be Not revoked
        if(this.accountSO.Revocation_Status__c != 'Not Revoked'){
            this.hasErrors = true;
        }
        
        //Valid To Must be greater than today
        if(this.accountSO.Valid_To_GMT__c < System.Today()){
            this.hasErrors = true;
        }
        
        //if Subordinate CA owner is blank then shows error
        if(!this.hasErrors && !this.accountSO.Audits_Same_as_Parent__c && string.isblank(this.accountSO.Subordinate_CA_Owner__c)){
            this.hasErrors = true;
        }
        
        //re calculate derived trust bits before calling ALV
        map<Id,Account> mapAllAccounts = new map<Id, Account>([select Id, ParentId, RecordType.Name, Derived_Trust_Bits__c,
                        Trust_Bits__c,Microsoft_Trust_Bits__c,Status__c,Microsoft_Status__c, Subject_SPKI_SHA256__c
                        from Account Where RecordType.Name != 'CA Owner']);
        
        set<string> setOfSubjectSPKI = new set<string>();
        if(this.accountSO.Subject_SPKI_SHA256__c != null) {
            setOfSubjectSPKI.add(this.accountSO.Subject_SPKI_SHA256__c);
        }
        if(this.accountSO.ParentId != null && this.accountSO.Parent.Subject_SPKI_SHA256__c != null) {
            setOfSubjectSPKI.add(this.accountSO.Parent.Subject_SPKI_SHA256__c);
        }
        map<string, List<Account>> mapAllRootsWithSameSPKI = new map<string, List<Account>>();
        if(setOfSubjectSPKI.size() > 0){
            Date todaydt = system.today();
            //querying on root certificate to get same Subject + SPKI.
            List<Account> lstRootAccs = new List<Account>([Select Id, ParentId, RecordType.Name, Derived_Trust_Bits__c,
                            Trust_Bits__c,Microsoft_Trust_Bits__c,Status__c,Microsoft_Status__c,Subject_SPKI_SHA256__c 
                            from Account Where //RecordType.Name = 'Root Certificate' and 
                            (Status__c in ('Not Yet Included','Included','Change Requested') or Microsoft_Status__c in ('Included','Change Requested')
                            OR Valid_To_GMT__c >=: todaydt)
                            and Subject_SPKI_SHA256__c =: setOfSubjectSPKI]);
            for(Account objRoot: lstRootAccs){
                if(mapAllRootsWithSameSPKI.containskey(objRoot.Subject_SPKI_SHA256__c)){
                    mapAllRootsWithSameSPKI.get(objRoot.Subject_SPKI_SHA256__c).add(objRoot);
                } else {
                    mapAllRootsWithSameSPKI.put(objRoot.Subject_SPKI_SHA256__c, new List<Account>{objRoot});
                }
            }
        }
        
        this.accountSo.Derived_Trust_Bits__c = '';
        string strDerivedTrustBits = AccountTriggerHelper.getDerivedTrustBits(this.accountSo, mapAllAccounts, mapAllRootsWithSameSPKI);
        if(strDerivedTrustBits != null && string.isnotblank(strDerivedTrustBits)){
            this.accountSo.Derived_Trust_Bits__c = strDerivedTrustBits;
        }
        //set default derived trust bits if it isblank
        if(this.accountSo.Derived_Trust_Bits__c == null || string.isblank(this.accountSo.Derived_Trust_Bits__c)){
            this.accountSo.Derived_Trust_Bits__c = 'Client Authentication';
        }
        
        //find parent account when Intermediate cert is same as parent.
        parentaccountSO = new Account();
        if(this.accountSO.Audits_Same_as_Parent__c) {
            boolean isFound = false;
            Id accParentId = accountSO.ParentId;
            Account objParentAccount;
            while(!isFound){
                objParentAccount = GetParentAccount(accParentId);
                if(objParentAccount != null && !objParentAccount.Audits_Same_as_Parent__c) {
                    isFound = true;
                } else if(objParentAccount == null) {
                    isFound = true;
                }
                if(objParentAccount != null) accParentId = objParentAccount.ParentId;
            }
            parentaccountSO = objParentAccount;
        }
        
        //check if valid from date is greater than audit period end date the show error.
        if(!this.hasErrors && !this.accountSO.Audits_Same_as_Parent__c  && 
                (this.accountSO.Valid_From_GMT__c > this.accountSO.Standard_Audit_Period_End_Date__c ||
                this.accountSO.Valid_From_GMT__c > this.accountSO.Code_Signing_Audit_Period_End_Date__c ||
                this.accountSO.Valid_From_GMT__c > this.accountSO.BR_Audit_Period_End_Date__c ||
                this.accountSO.Valid_From_GMT__c > this.accountSO.EV_Audit_Period_End_Date__c ||
                this.accountSO.Valid_From_GMT__c > this.accountSO.EV_Code_Signing_Audit_Period_End_Date__c)){
            this.hasErrors = true;
            IsNewCertificate = true;
        } else if(!this.hasErrors && this.accountSO.Audits_Same_as_Parent__c  && 
                (this.accountSO.Valid_From_GMT__c > this.parentaccountSO.Standard_Audit_Period_End_Date__c ||
                this.accountSO.Valid_From_GMT__c > this.parentaccountSO.Code_Signing_Audit_Period_End_Date__c ||
                this.accountSO.Valid_From_GMT__c > this.parentaccountSO.BR_Audit_Period_End_Date__c ||
                this.accountSO.Valid_From_GMT__c > this.parentaccountSO.EV_Audit_Period_End_Date__c ||
                this.accountSO.Valid_From_GMT__c > this.parentaccountSO.EV_Code_Signing_Audit_Period_End_Date__c)){
            this.hasErrors = true;
            IsNewCertificate = true;
        }
        
        this.statusText = 'Invoking ALV Sevice...  <br/>';
        this.lstErrorLog = new List<JixiServiceTokens.ErrorLogAndActions>();
        
        
        
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
    
    public void UpdateDeriveTrustBits(){
        try {
            if(this.accountSo.Derived_Trust_Bits__c != null && string.isnotblank(this.accountSo.Derived_Trust_Bits__c)){
                Account objAcc = new Account(Id = this.accountSo.Id);
                objAcc.Derived_Trust_Bits__c = this.accountSo.Derived_Trust_Bits__c;
                update objAcc;
            }
        } catch (Exception e){
            //don't display message when its running from batch.
            if(ApexPages.currentpage() != null){
                apexpages.addMessages(e);
            }
        }
    }
    
    /*
    * get Intermediate cert Record
    */
    private Account getInterCertsRecord(Id accId){
       
       return [SELECT Id, CA_Owner_Certificate_No__c, Name, CA_Owner__c, Subordinate_CA_Owner__c, 
               Auditor_New__r.Name, Auditor_New__r.Alternate_Auditor_Name_s__c,
               SHA_1_Fingerprint__c, SHA_256_Fingerprint__c, ParentId,Valid_To_GMT__c,
               Audits_Same_as_Parent__c,Subject_SPKI_SHA256__c,Parent.Subject_SPKI_SHA256__c,Extended_Key_Usage__c,Valid_From_GMT__c,
               Standard_Audit__c, Standard_Audit_Type__c, Standard_Audit_Statement_Date__c,     
               Standard_Audit_Period_Start_Date__c,Standard_Audit_Period_End_Date__c,               
               Code_Signing_Audit__c, Code_Signing_Audit_Type__c, Code_Signing_Audit_Statement_Date__c, 
               Code_Signing_Audit_Period_Start_Date__c, Code_Signing_Audit_Period_End_Date__c, 
               BR_Audit__c, BR_Audit_Type__c,BR_Audit_Statement_Date__c,
               BR_Audit_Period_Start_Date__c,BR_Audit_Period_End_Date__c,
               EV_Audit__c, EV_Audit_Type__c, EV_Audit_Statement_Date__c,
               EV_Audit_Period_Start_Date__c, EV_Audit_Period_End_Date__c,
               EV_Code_Signing_Audit__c, EV_Code_Signing_Audit_Type__c, EV_Code_Signing_Audit_Statement_Date__c,
               EV_Code_Signing_Audit_Period_Start_Date__c, EV_Code_Signing_Audit_Period_End_Date__c,
               Standard_Audit_ALV_Status__c, Standard_Audit_ALV_Results__c, 
               BR_Audit_ALV_Status__c, BR_Audit_ALV_Results__c, Revocation_Status__c ,
               Code_Signing_Audit_ALV_Status__c, Code_Signing_Audit_ALV_Results__c,
               EV_SSL_Audit_ALV_Status__c, EV_SSL_Audit_ALV_Results__c,Derived_Trust_Bits__c,
               Root_Cert_Id__c,Root_Cert_Id__r.Microsoft_Trust_Bits__c,Root_Cert_Id__r.Microsoft_EV_Enabled__c
               FROM Account
               WHERE Id = :accId];
    }
    
    /*
    * prepareRequest - prepare request JSON at the begining of page load.
    */
    public void prepareRequest(){
        try{
            //pass concatinated Audior name and Alternate Auditor names
            String auditor = '';
            //copy CA Owner Name when 
            if(this.accountSO.Audits_Same_as_Parent__c){
                auditor = parentaccountSO.Auditor_New__r.Name;
                auditor += (parentaccountSO.Auditor_New__r.Alternate_Auditor_Name_s__c != null ?  (';' + parentaccountSO.Auditor_New__r.Alternate_Auditor_Name_s__c) : '');
            } else {
                auditor = accountSO.Auditor_New__r.Name;
                auditor += (accountSO.Auditor_New__r.Alternate_Auditor_Name_s__c != null ?  (';' + accountSO.Auditor_New__r.Alternate_Auditor_Name_s__c) : '');
            }
            //Code added by Sunil - Use JSON Generator to generate request in proper sequence.
            JSONGenerator gen = JSON.createGenerator(true);
            
            //start main object
            gen.writeStartObject();
            
            gen.writeStringField('CaseRecordID', accountSO.Id);
            gen.writeStringField('CaseNumber', accountSO.CA_Owner_Certificate_No__c);
            // gen.writeStringField('CAOwnerName', accountSO.CA_Owner__c); 
            
            //copy CA Owner Name from parent when Audit same as parent else it from current cert
            CAOwnerName = this.accountSO.Subordinate_CA_Owner__c;
            if(this.accountSO.Audits_Same_as_Parent__c && parentaccountSO.RecordType.Name == 'Intermediate Certificate'){
                CAOwnerName = parentaccountSO.Subordinate_CA_Owner__c;
            } else if(this.accountSO.Audits_Same_as_Parent__c && parentaccountSO.RecordType.Name == 'Root Certificate'){
                CAOwnerName = parentaccountSO.CA_Owner__c;
            }
            
            gen.writeStringField('CAOwnerName', string.isnotblank(CAOwnerName) ? CAOwnerName : ''); // for inter certs use subordinate CA Owner Name instead of CA Owner
            gen.writeStringField('Auditor', auditor);
            
            //start StandardAudit
            gen.writeFieldName('StandardAudit');
            gen.writeStartObject();
            
            if(this.accountSO.Audits_Same_as_Parent__c) {
                gen.writeStringField('AuditType', parentaccountSO.Standard_Audit_Type__c != null ? parentaccountSO.Standard_Audit_Type__c : '');
                gen.writeStringField('StatementDate', parentaccountSO.Standard_Audit_Statement_Date__c != null ? String.valueOf(parentaccountSO.Standard_Audit_Statement_Date__c) : '');
                gen.writeStringField('AuditPeriodStart', parentaccountSO.Standard_Audit_Period_Start_Date__c != null ? String.valueOf(parentaccountSO.Standard_Audit_Period_Start_Date__c) : '');
                gen.writeStringField('AuditPeriodEnd', parentaccountSO.Standard_Audit_Period_End_Date__c != null ? String.valueOf(parentaccountSO.Standard_Audit_Period_End_Date__c) : '');
                gen.writeStringField('Link', parentaccountSO.Standard_Audit__c != null ? parentaccountSO.Standard_Audit__c : '');
                
            } else {
                gen.writeStringField('AuditType', accountSO.Standard_Audit_Type__c != null ? accountSO.Standard_Audit_Type__c : '');
                gen.writeStringField('StatementDate', accountSO.Standard_Audit_Statement_Date__c != null ? String.valueOf(accountSO.Standard_Audit_Statement_Date__c) : '');
                gen.writeStringField('AuditPeriodStart', accountSO.Standard_Audit_Period_Start_Date__c != null ? String.valueOf(accountSO.Standard_Audit_Period_Start_Date__c) : '');
                gen.writeStringField('AuditPeriodEnd', accountSO.Standard_Audit_Period_End_Date__c != null ? String.valueOf(accountSO.Standard_Audit_Period_End_Date__c) : '');
                gen.writeStringField('Link', accountSO.Standard_Audit__c != null ? accountSO.Standard_Audit__c : '');
            }
            
            //end StandardAudit
            gen.writeEndObject();
            
            //start code signing audit
            gen.writeFieldName('CodeSigningAudit');
            gen.writeStartObject();
            
            gen.writeStringField('AuditType', '');
            gen.writeStringField('StatementDate', '');
            gen.writeStringField('AuditPeriodStart', '');
            gen.writeStringField('AuditPeriodEnd', '');
            gen.writeStringField('Link', '');
            
            /*if(this.accountSO.Audits_Same_as_Parent__c) {
                gen.writeStringField('AuditType', parentaccountSO.Code_Signing_Audit_Type__c != null ? parentaccountSO.Code_Signing_Audit_Type__c : '');
                gen.writeStringField('StatementDate', parentaccountSO.Code_Signing_Audit_Statement_Date__c != null ? String.valueOf(parentaccountSO.Code_Signing_Audit_Statement_Date__c) : '');
                gen.writeStringField('AuditPeriodStart', parentaccountSO.Code_Signing_Audit_Period_Start_Date__c != null ? String.valueOf(parentaccountSO.Code_Signing_Audit_Period_Start_Date__c) : '');
                gen.writeStringField('AuditPeriodEnd', parentaccountSO.Code_Signing_Audit_Period_End_Date__c != null ? String.valueOf(parentaccountSO.Code_Signing_Audit_Period_End_Date__c) : '');
                gen.writeStringField('Link', parentaccountSO.Code_Signing_Audit__c != null ? parentaccountSO.Code_Signing_Audit__c : '');
            } else {
                gen.writeStringField('AuditType', accountSO.Code_Signing_Audit_Type__c != null ? accountSO.Code_Signing_Audit_Type__c : '');
                gen.writeStringField('StatementDate', accountSO.Code_Signing_Audit_Statement_Date__c != null ? String.valueOf(accountSO.Code_Signing_Audit_Statement_Date__c) : '');
                gen.writeStringField('AuditPeriodStart', accountSO.Code_Signing_Audit_Period_Start_Date__c != null ? String.valueOf(accountSO.Code_Signing_Audit_Period_Start_Date__c) : '');
                gen.writeStringField('AuditPeriodEnd', accountSO.Code_Signing_Audit_Period_End_Date__c != null ? String.valueOf(accountSO.Code_Signing_Audit_Period_End_Date__c) : '');
                gen.writeStringField('Link', accountSO.Code_Signing_Audit__c != null ? accountSO.Code_Signing_Audit__c : '');
            }*/
            gen.writeEndObject();
            //end code signing audit
            
            //start BRAudit
            gen.writeFieldName('BRAudit');
            gen.writeStartObject();
            
            if(this.accountSO.Audits_Same_as_Parent__c){
                gen.writeStringField('AuditType', parentaccountSO.BR_Audit_Type__c != null && accountSO.Derived_Trust_Bits__c.contains('Server Authentication') ? parentaccountSO.BR_Audit_Type__c : '');
                gen.writeStringField('StatementDate', parentaccountSO.BR_Audit_Statement_Date__c != null  && accountSO.Derived_Trust_Bits__c.contains('Server Authentication') ? String.valueOf(parentaccountSO.BR_Audit_Statement_Date__c) : '');
                gen.writeStringField('AuditPeriodStart', parentaccountSO.BR_Audit_Period_Start_Date__c != null  && accountSO.Derived_Trust_Bits__c.contains('Server Authentication') ? String.valueOf(parentaccountSO.BR_Audit_Period_Start_Date__c) : '');
                gen.writeStringField('AuditPeriodEnd', parentaccountSO.BR_Audit_Period_End_Date__c != null  && accountSO.Derived_Trust_Bits__c.contains('Server Authentication') ? String.valueOf(parentaccountSO.BR_Audit_Period_End_Date__c) : '');
                gen.writeStringField('Link', parentaccountSO.BR_Audit__c != null  && accountSO.Derived_Trust_Bits__c.contains('Server Authentication') ? parentaccountSO.BR_Audit__c : '');
            } else {
                gen.writeStringField('AuditType', accountSO.BR_Audit_Type__c != null && accountSO.Derived_Trust_Bits__c.contains('Server Authentication') ? accountSO.BR_Audit_Type__c : '');
                gen.writeStringField('StatementDate', accountSO.BR_Audit_Statement_Date__c != null && accountSO.Derived_Trust_Bits__c.contains('Server Authentication') ? String.valueOf(accountSO.BR_Audit_Statement_Date__c) : '');
                gen.writeStringField('AuditPeriodStart', accountSO.BR_Audit_Period_Start_Date__c != null && accountSO.Derived_Trust_Bits__c.contains('Server Authentication') ? String.valueOf(accountSO.BR_Audit_Period_Start_Date__c) : '');
                gen.writeStringField('AuditPeriodEnd', accountSO.BR_Audit_Period_End_Date__c != null && accountSO.Derived_Trust_Bits__c.contains('Server Authentication') ? String.valueOf(accountSO.BR_Audit_Period_End_Date__c) : '');
                gen.writeStringField('Link', accountSO.BR_Audit__c != null && accountSO.Derived_Trust_Bits__c.contains('Server Authentication') ? accountSO.BR_Audit__c : '');
            }
            
            //end BRAudit
            gen.writeEndObject();
            
            //start EVSSL
            gen.writeFieldName('EVSSLAudit');
            gen.writeStartObject();
            //pass blank EV SSL Audit
            gen.writeStringField('AuditType', '');
            gen.writeStringField('StatementDate', '');
            gen.writeStringField('AuditPeriodStart', '');
            gen.writeStringField('AuditPeriodEnd', '');
            gen.writeStringField('Link', '');
            /*if(this.accountSO.Audits_Same_as_Parent__c){
                gen.writeStringField('AuditType', parentaccountSO.EV_Audit_Type__c != null ? parentaccountSO.EV_Audit_Type__c : '');
                gen.writeStringField('StatementDate', parentaccountSO.EV_Audit_Statement_Date__c != null ? String.valueOf(parentaccountSO.EV_Audit_Statement_Date__c) : '');
                gen.writeStringField('AuditPeriodStart', parentaccountSO.EV_Audit_Period_Start_Date__c != null ? String.valueOf(parentaccountSO.EV_Audit_Period_Start_Date__c) : '');
                gen.writeStringField('AuditPeriodEnd', parentaccountSO.EV_Audit_Period_End_Date__c != null ? String.valueOf(parentaccountSO.EV_Audit_Period_End_Date__c) : '');
                gen.writeStringField('Link', parentaccountSO.EV_Audit__c != null ? parentaccountSO.EV_Audit__c : '');
                
            } else {
                gen.writeStringField('AuditType', accountSO.EV_Audit_Type__c != null ? accountSO.EV_Audit_Type__c : '');
                gen.writeStringField('StatementDate', accountSO.EV_Audit_Statement_Date__c != null ? String.valueOf(accountSO.EV_Audit_Statement_Date__c) : '');
                gen.writeStringField('AuditPeriodStart', accountSO.EV_Audit_Period_Start_Date__c != null ? String.valueOf(accountSO.EV_Audit_Period_Start_Date__c) : '');
                gen.writeStringField('AuditPeriodEnd', accountSO.EV_Audit_Period_End_Date__c != null ? String.valueOf(accountSO.EV_Audit_Period_End_Date__c) : '');
                gen.writeStringField('Link', accountSO.EV_Audit__c != null ? accountSO.EV_Audit__c : '');
            }*/
            
            //end EVSSL
            gen.writeEndObject();
            
            //start EVCodeSigning
            //We are passing Blank EV Code Signing Audit as we are not using for Intermediate certs and the reason is added to make consitant same as case ALV.
            gen.writeFieldName('EVCodeSigningAudit');
            gen.writeStartObject();
            
            gen.writeStringField('AuditType', '');
            gen.writeStringField('StatementDate', '');
            gen.writeStringField('AuditPeriodStart', '');
            gen.writeStringField('AuditPeriodEnd', '');
            gen.writeStringField('Link', '');
            
            //end EVCodeSigning
            gen.writeEndObject();
    
            //start rootcases
            gen.writeFieldName('RootCases');
            gen.writeStartArray();
                //start object
                gen.writeStartObject();
    
                gen.writeStringField('RootCaseRecordID', accountSO.Id);
                gen.writeStringField('RootCaseNumber', accountSO.CA_Owner_Certificate_No__c);
                gen.writeStringField('Name', accountSO.Name != null ? accountSO.Name : '');
                gen.writeStringField('SHA1Thumbprint', accountSO.SHA_1_Fingerprint__c != null ? accountSO.SHA_1_Fingerprint__c : '');
                gen.writeStringField('SHA256Thumbprint', accountSO.SHA_256_Fingerprint__c != null ? accountSO.SHA_256_Fingerprint__c : '');
                
                //Trust Bits
                TrustBits = accountSO.Derived_Trust_Bits__c;
                set<string> setofValidTrustBits = new set<string>{'Server Authentication','Secure Email','Client Authentication'};
                string[] arrTrustBits = TrustBits.split(';');
                List<string> lstNewTrustBits = new List<string>();
                for(string str: arrTrustBits){
                    if(string.isnotblank(str) && setofValidTrustBits.contains(str.trim())){
                        lstNewTrustBits.add(str);     
                    }
                }
                if(lstNewTrustBits.size() > 0){
                    TrustBits = string.join(lstNewTrustBits,';');
                } else {
                    TrustBits = 'Client Authentication';
                }
                
                gen.writeStringField('MicrosoftTrustBits', TrustBits);
                //(accountSO.Root_Cert_Id__c != null && accountSO.Root_Cert_Id__r.Microsoft_Trust_Bits__c != null ? accountSO.Root_Cert_Id__r.Microsoft_Trust_Bits__c : '')
                
                //Microsoft EV Enabled.
                /*if(this.accountSO.Audits_Same_as_Parent__c) {
                    gen.writeStringField('MicrosoftEVEnabled', string.valueof(parentaccountSO.EV_Audit__c != null ? true : false));
                } else {
                    gen.writeStringField('MicrosoftEVEnabled', string.valueof(accountSO.EV_Audit__c != null ? true : false));
                }*/
                gen.writeStringField('MicrosoftEVEnabled', 'false');
                
                if(this.accountSO.Audits_Same_as_Parent__c){
                   gen.writeStringField('StandardAuditApplied', (string.isnotblank(parentaccountSO.Standard_Audit__c) ? 'true' : 'false'));
                   gen.writeStringField('CodeSigningAuditApplied', 'false');
                   gen.writeStringField('BRAuditApplied', (accountSO.Derived_Trust_Bits__c.contains('Server Authentication') ? 'true' : 'false'));
                   gen.writeStringField('EVSSLAuditApplied', 'false');
                   //gen.writeStringField('EVSSLAuditApplied', (string.isnotblank(parentaccountSO.EV_Audit__c) ? 'true' : 'false'));    
                   gen.writeStringField('EVCodeSigningAuditApplied', 'false');
                }
                else {
                   gen.writeStringField('StandardAuditApplied', (string.isnotblank(accountSO.Standard_Audit__c) ? 'true' : 'false'));
                   gen.writeStringField('CodeSigningAuditApplied', 'false');
                   gen.writeStringField('BRAuditApplied', (accountSO.Derived_Trust_Bits__c.contains('Server Authentication') ? 'true' : 'false'));
                   gen.writeStringField('EVSSLAuditApplied', 'false');
                   gen.writeStringField('EVCodeSigningAuditApplied', 'false');
                }
                
                // end object
                gen.writeEndObject();
            
            //end rootcases
            gen.writeEndArray();
            //gen.writeObjectField('RootCases', lstCertificates);
            
            //end main object
            gen.writeEndObject();
            
            this.request = gen.getAsString();
            
            // System.debug('Request'+this.request);
            
        } catch(Exception exp){
            this.hasErrors = true;
            this.response = exp.getMessage() + ' Please contact your administrator.';
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
                // System.debug(tokens);
                
                HttpRequest hReq = new HttpRequest();
                hReq.setHeader('Content-Type', 'application/json');
                hReq.setEndpoint(tokens.Service_Endpoint__c);//don't forget to set remote site setting for this endpoint.
                hReq.setMethod(tokens.HTTP_Method__c);
                hReq.setBody(this.request);
                hReq.setTimeout(Integer.valueOf(tokens.Timeout__c));
                hReq.setClientCertificateName(tokens.Client_Certification_Name__c);
                
                Http http = new Http();
                // System.debug('H Request Body'+hReq.getBody());
                HttpResponse hRes = http.send(hReq);
                
                // System.debug(hRes.getHeaderKeys());
                // System.debug(hRes.getHeader('Location')); //if response code 201 CREATED then Jixi is returning "https://ccadbwebapiservice.azurewebsites.net/api/CAs/50063000004KUgE" in location
                // System.debug(hRes.getBody());
                                
                //200 OK, 201 CREATED, 202 ACCEPTED
                if(hRes != null && (hRes.getStatusCode() == 200 || hRes.getStatusCode() == 201 || hRes.getStatusCode() == 202)){
                    this.response = hRes.getBody();
                    // System.debug(this.response);
       
                }else{
                    // System.debug(hRes);
                    this.hasErrors = true;
                    this.response = mapHttpStatusCodes.containsKey(hRes.getStatusCode()) ? mapHttpStatusCodes.get(hRes.getStatusCode()) +
                     ' Please contact your administrator.' : 'Unexpected Error Occurred. Please contact your administrator.' + this.response;
                }
            }catch(Exception exp){
                // System.debug(exp.getMessage());
                // System.debug(exp.getStackTraceString());
                // System.debug(exp.getLineNumber());
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
            //don't display message when its running from batch.
            if(ApexPages.currentpage() != null){
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, this.response));
                return pref;
            }
        }

        try{
            
            //if no errors so far then parse the response
            JixiServiceTokens.JixiServiceResponse result = JixiServiceTokens.parse(this.response);
            // System.debug(result);
            
            //update account record
            Account accountSO = new Account(Id = result.CaseRecordID);
            if(this.accountSo.Derived_Trust_Bits__c != null) {
                accountSO.Derived_Trust_Bits__c = this.accountSo.Derived_Trust_Bits__c;
            }
            //update Standard audit
            if(this.accountSO.Standard_Audit__c != null || (this.accountSO.Audits_Same_as_Parent__c && parentaccountSO.Standard_Audit__c != null)){
                string ALVResult = result.StandardAudit.AutoReviewResults;
                if(this.accountSO.Audits_Same_as_Parent__c && string.isnotblank(result.StandardAudit.AutoReviewResults)){
                    if(ALVResult.contains('AuditLocation=Fail; ') || ALVResult.contains('AuditLocation=Pass; ')){
                        ALVResult = ALVResult.replace('AuditLocation=Fail; ','').replace('AuditLocation=Pass; ','');
                    }
                    accountSO.Standard_Audit_ALV_Results__c = ALVResult;
                    accountSO.Standard_Audit_ALV_Status__c = ALVResult.contains('Fail') ? 'FAIL' : 'PASS';
                } else {
                    accountSO.Standard_Audit_ALV_Results__c = result.StandardAudit.AutoReviewResults;
                    accountSO.Standard_Audit_ALV_Status__c = result.StandardAudit.AutoReviewStatus;
                }
                accountSO.Standard_Audit_ALV_Found_Cert__c = '';
                if(ALVResult.contains('AllThumbprintsListed=Fail')){
                    accountSO.Standard_Audit_ALV_Found_Cert__c = 'FAIL';
                } else if(ALVResult.contains('AllThumbprintsListed=Pass')){
                    accountSO.Standard_Audit_ALV_Found_Cert__c = 'PASS';
                }
            } else {
                accountSO.Standard_Audit_ALV_Status__c = '';
                accountSO.Standard_Audit_ALV_Results__c = '';  
                accountSO.Standard_Audit_ALV_Found_Cert__c = '';         
            }
            
            // update Standard Audit Deviation each time ALV is run
            //this.accountSO.Standard_Audit_Verified__c != 'Data Verified' &&  
            /*if(accountSO.Standard_Audit_ALV_Results__c != null && accountSO.Standard_Audit_ALV_Results__c.contains('AuditLocation=Fail')){
                accountSO.Standard_Deviation__c = true;                     
            }*/
            
            //update Code Signing audit
            /*if(this.accountSO.Code_Signing_Audit__c != null || (this.accountSO.Audits_Same_as_Parent__c && parentaccountSO.Code_Signing_Audit__c != null)){
                if(this.accountSO.Audits_Same_as_Parent__c && string.isnotblank(result.CodeSigningAudit.AutoReviewResults)){
                    string ALVResult = result.CodeSigningAudit.AutoReviewResults;
                    if(ALVResult.contains('AuditLocation=Fail; ') || ALVResult.contains('AuditLocation=Pass; ')){
                        ALVResult = ALVResult.replace('AuditLocation=Fail; ','').replace('AuditLocation=Pass; ','');
                    }
                    accountSO.Code_Signing_Audit_ALV_Results__c = ALVResult;
                    accountSO.Code_Signing_Audit_ALV_Status__c = ALVResult.contains('Fail') ? 'FAIL' : 'PASS';
                } else {
                    accountSO.Code_Signing_Audit_ALV_Status__c = result.CodeSigningAudit.AutoReviewStatus;
                    accountSO.Code_Signing_Audit_ALV_Results__c = result.CodeSigningAudit.AutoReviewResults;
                }
            } else {*/
            //update blank status as we are not passing Audit.
            accountSO.Code_Signing_Audit_ALV_Status__c = '';
            accountSO.Code_Signing_Audit_ALV_Results__c  = '';           
            //}
            
            // update Code Signing Audit Deviation each time ALV is run
            //this.accountSO.Code_Signing_Audit_Verified__c != 'Data Verified' &&   
            /*if(accountSO.Code_Signing_Audit_ALV_Results__c != null && accountSO.Code_Signing_Audit_ALV_Results__c.contains('AuditLocation=Fail')){
                accountSO.Code_Signing_Deviation__c = true;                     
            } */           
            
            //update BR audit        
            if(accountSO.Derived_Trust_Bits__c.contains('Server Authentication')){
                //(this.accountSO.BR_Audit__c != null || (this.accountSO.Audits_Same_as_Parent__c && parentaccountSO.BR_Audit__c != null)) && 
                string ALVResult = result.BRAudit.AutoReviewResults;
                if(this.accountSO.Audits_Same_as_Parent__c && string.isnotblank(result.BRAudit.AutoReviewResults)){
                    if(ALVResult.contains('AuditLocation=Fail; ') || ALVResult.contains('AuditLocation=Pass; ')){
                        ALVResult = ALVResult.replace('AuditLocation=Fail; ','').replace('AuditLocation=Pass; ','');
                    }
                    accountSO.BR_Audit_ALV_Results__c = ALVResult;
                    accountSO.BR_Audit_ALV_Status__c = ALVResult.contains('Fail') ? 'FAIL' : 'PASS';
                } else {
                    accountSO.BR_Audit_ALV_Status__c = result.BRAudit.AutoReviewStatus;
                    accountSO.BR_Audit_ALV_Results__c = result.BRAudit.AutoReviewResults;
                }
                accountSO.BR_Audit_ALV_Found_Cert__c = '';
                if(ALVResult.contains('AllThumbprintsListed=Fail')){
                    accountSO.BR_Audit_ALV_Found_Cert__c = 'FAIL';
                } else if(ALVResult.contains('AllThumbprintsListed=Pass')){
                    accountSO.BR_Audit_ALV_Found_Cert__c = 'PASS';
                }
            } else {
                accountSO.BR_Audit_ALV_Status__c = '';
                accountSO.BR_Audit_ALV_Results__c = '';
                accountSO.BR_Audit_ALV_Found_Cert__c = '';
            }
            
            // update BR Audit Deviation each time ALV is run
            //this.accountSO.BR_Audit_Statement_Link_Verified__c != 'Data Verified' &&       
            /*if(accountSO.BR_Audit_ALV_Results__c != null && accountSO.BR_Audit_ALV_Results__c.contains('AuditLocation=Fail')){
                accountSO.BR_Deviation__c = true;                     
            } */             
                        
            //update EV SSL audit
            /*if(this.accountSO.EV_Audit__c != null || (this.accountSO.Audits_Same_as_Parent__c && parentaccountSO.EV_Audit__c != null)){
                if(this.accountSO.Audits_Same_as_Parent__c && string.isnotblank(result.EVSSLAudit.AutoReviewResults)){
                    string ALVResult = result.EVSSLAudit.AutoReviewResults;
                    if(ALVResult.contains('AuditLocation=Fail; ') || ALVResult.contains('AuditLocation=Pass; ')){
                        ALVResult = ALVResult.replace('AuditLocation=Fail; ','').replace('AuditLocation=Pass; ','');
                    }
                    accountSO.EV_SSL_Audit_ALV_Results__c = ALVResult;
                    accountSO.EV_SSL_Audit_ALV_Status__c = ALVResult.contains('Fail') ? 'FAIL' : 'PASS';
                } else {
                    accountSO.EV_SSL_Audit_ALV_Status__c = result.EVSSLAudit.AutoReviewStatus;
                    accountSO.EV_SSL_Audit_ALV_Results__c = result.EVSSLAudit.AutoReviewResults;
                }
            } else {*/
            //update blank status as we are not passing Audit.
            accountSO.EV_SSL_Audit_ALV_Status__c = '';
            accountSO.EV_SSL_Audit_ALV_Results__c = '';
            //}
            
            // update EV SSL Audit Deviation each time ALV is run
            //this.accountSO.EV_Audit_Statement_Link_Verified__c != 'Data Verified' &&        
            /*if(accountSO.EV_SSL_Audit_ALV_Results__c != null && accountSO.EV_SSL_Audit_ALV_Results__c.contains('AuditLocation=Fail')){
                accountSO.EV_SSL_Deviation__c = true;                     
            }  */          
            
            // update EV Code Signing
            /*if(this.accountSO.EV_Code_Signing_Audit_Statement_Link__c != null|| (this.accountSO.Audits_Same_as_Parent__c && parentaccountSO.EV_Code_Signing_Audit_Statement_Link__c != null)){
                accountSO.EV_Code_Signing_Audit_AutoReviewStatus__c = result.EVCodeSigningAudit.AutoReviewStatus;
                accountSO.EV_Code_Signing_Audit_AutoReviewResults__c = result.EVCodeSigningAudit.AutoReviewResults;
            } else {
                accountSO.EV_Code_Signing_Audit_AutoReviewStatus__c = '';
                accountSO.EV_Code_Signing_Audit_AutoReviewResults__c = '';
            }
            
            // update EV Code Signing Audit Deviation each time ALV is run            
            if(this.accountSO.EV_Code_Signing_Verified__c != 'Data Verified' && accountSO.EV_Code_Signing_Audit_AutoReviewResults__c != null && accountSO.EV_Code_Signing_Audit_AutoReviewResults__c.contains('AuditLocation=Fail')){
                    accountSO.EV_Code_Signing_Deviation__c = true;                     
            } */           
                        
            
            this.lstErrorLog = result.ErrorLogAndActions != null ? result.ErrorLogAndActions : new List<JixiServiceTokens.ErrorLogAndActions>();
            
            // update root cases
            // List<Root_Case__c> lstRootCases = new List<Root_Case__c>();
            for(JixiServiceTokens.RootCasesResult rootCaseResult : result.RootCases){
                accountSO.ALV_Status__c = String.valueOf(rootCaseResult.AutoReviewStatus != null && rootCaseResult.AutoReviewStatus ? 'PASS' : 'FAIL');
                accountSO.ALV_Results__c = rootCaseResult.AutoReviewResults;
            }
            accountSO.Date_ALV_Processed__c = system.today();
            update accountSO;
            
            /*if(lstRootCases.size() > 0){
                update lstRootCases;
            }*/
            
            pref = new PageReference('/'+accountSO.Id); //stdCon.view();
            
        }catch(Exception exp){
            // System.debug(exp.getMessage());
            // System.debug(exp.getStackTraceString());
            // System.debug(exp.getLineNumber());
            this.hasErrors = true;
            this.response = this.response +'\n***** ERROR ****: '+exp.getMessage();
            //don't display message when its running from batch.
            if(ApexPages.currentpage() != null){
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, this.response));
            }
        }
        
        this.accountSO = getInterCertsRecord(this.accountSO.Id);
                        
        //this.lstRootCases = new List<Root_Case__c>();
        
        //this.lstRootCases = this.accountSO.Root_Cases__r;
                       
        return null; //change it to 'pref' then it won't wait on the screen and directly go to Case record detail page
    }
    
    public PageReference downloadLog(){
        
        PageReference pref = Page.JixiServiceErrorReportInterCerts;
        pref.getParameters().put('id', this.accountSO.Id);
        pref.setRedirect(false);
        
        return pref;
    }
    
    public Account GetParentAccount(string accId){
        List<Account> lstAcc = new List<Account>([select Id, ParentId, RecordType.Name,CA_Owner__c,
                        Standard_Audit__c, Standard_Audit_Type__c, Standard_Audit_Statement_Date__c,     
                        Standard_Audit_Period_Start_Date__c,Standard_Audit_Period_End_Date__c,               
                        Code_Signing_Audit__c, Code_Signing_Audit_Type__c, Code_Signing_Audit_Statement_Date__c, 
                        Code_Signing_Audit_Period_Start_Date__c, Code_Signing_Audit_Period_End_Date__c, 
                        BR_Audit__c, BR_Audit_Type__c,BR_Audit_Statement_Date__c,Auditor_New__r.Name, Auditor_New__r.Alternate_Auditor_Name_s__c,
                        BR_Audit_Period_Start_Date__c,BR_Audit_Period_End_Date__c,
                        EV_Audit__c, EV_Audit_Type__c, EV_Audit_Statement_Date__c,
                        EV_Audit_Period_Start_Date__c, EV_Audit_Period_End_Date__c,
                        EV_Code_Signing_Audit__c, EV_Code_Signing_Audit_Type__c, EV_Code_Signing_Audit_Statement_Date__c,
                        EV_Code_Signing_Audit_Period_Start_Date__c, EV_Code_Signing_Audit_Period_End_Date__c,
                        Standard_Audit_ALV_Status__c, Standard_Audit_ALV_Results__c, 
                        BR_Audit_ALV_Status__c, BR_Audit_ALV_Results__c, 
                        Code_Signing_Audit_ALV_Status__c, Code_Signing_Audit_ALV_Results__c,
                        EV_SSL_Audit_ALV_Status__c, EV_SSL_Audit_ALV_Results__c,Derived_Trust_Bits__c,
                        Audits_Same_as_Parent__c, CP_CPS_Same_as_Parent__c, Revocation_Status__c, Subordinate_CA_Owner__c
                        from Account Where Id =: accId]);
        if(lstAcc.size() > 0){
            return lstAcc[0];
        }
        return null;
    }
    
    /* Code mey be used later to send http request Asynchronously 
    @future(Callout=true)
    public static void callAPI(){
        Jixi_Integration_Tokens__c tokens = Jixi_Integration_Tokens__c.getInstance('Jixi Service Tokens');
        // System.debug(tokens);
        
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
        
        // System.debug(hRes.getHeaderKeys());
        // System.debug(hRes.getHeader('Location')); //if response code 201 CREATED then Jixi is returning "https://ccadbwebapiservice.azurewebsites.net/api/CAs/50063000004KUgE" in location
        // System.debug(hRes.getBody());
    }*/
}
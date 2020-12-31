/*******************************************************************************************************
 Name: AddUpdateRootCasesController

 Dependencies: AddUpdateRootCasesController controller class, AddUpdateRootCases vf page, 
 AddUpdateRootCasesControllerTest test class

 Description: This class is created for Root Inclusion type of Cases. User can update and add new root case.
    
 Root Certificates get created on 'Apply Changes' button is selected. Do not allow users to add from standard
 related list. 
 
 New root certs can be added by a providing PEM info. If a CA (community user) adds a new root cert, the
 record owner of this record is transferred to an internal user.
 
 Instructions: None
 *******************************************************************************************************
 Revision History:
 
     10/1/2020 - Made class as without sharing. When CAs add new root cert, the record owner has to be 
                 transferred to an internal user. The method to transfer CA Owner is in AccountTriggerHelper.
     
 ******************************************************************************************************/

public without sharing class AddUpdateRootCasesController {
    
    Id caseOwnerId;
    public Case objCase;
    public boolean isCaseCompleted {get; set;}
    
    //var which holds pem info entered by user
    public string strPEMInfo {get; set;}
    
    //var which holds extract result
    public string strextractionResults {get; set;}
    
    //for which case you want to add root case
    public string CaseId {get; set;}
    
    // flag used to enable/disable update button
    public Boolean isCertCheckSuccessful {get;set;}
    
    //flag used to disable update button
    public boolean disableCreateButton {get; set;}
    
    //holds PEM info extraction result in account object
    public Account parsedCertificateSO;
    
    public boolean blnAddPEMInfoOpened {get; set;}
    public List<WrapperRootCases> lstWrapAllRootCases{get; set;}
    
    public AddUpdateRootCasesController(Apexpages.standardcontroller controller) {
        caseOwnerId = controller.getId();
        isCaseCompleted = false;
        LoadRootCases();
        strPEMInfo = '';
        strextractionResults = '';
        disableCreateButton = false;
        isCertCheckSuccessful = false;
        CaseId = controller.getId();
        blnAddPEMInfoOpened = false;
    }
    
    public void LoadRootCases(){
        lstWrapAllRootCases = new List<WrapperRootCases>();
        List<Case> lstCases = new List<Case>([select Id,AccountId,CaseNumber,Account.Name,Request_Status__c,
                    RecordType.Name from Case Where Id =: caseOwnerId]);
        
        if(lstCases.size() > 0) {
            objCase = lstCases[0];
            
            //get record type id for root cases
            string RCAuditUpdateRTId = ''; 
            string CaseRecordTypeName = objCase.RecordType.Name;
            if(Schema.SObjectType.Root_Case__c.getRecordTypeInfosByName().get(CaseRecordTypeName) != null){
                RCAuditUpdateRTId = Schema.SObjectType.Root_Case__c.getRecordTypeInfosByName().get(CaseRecordTypeName).getRecordTypeId();
            }
            
            if(objCase.Request_Status__c == 'Complete') {
                isCaseCompleted = true;
            }
            map<Id,Root_Case__c> mapExistingRootCases = new map<Id,Root_Case__c>();
            
            //fill map to find existing root cases.
            for(Root_Case__c rc: [Select Id,Name, Root_Certificate_Name_Existing__c, Request_Status__c,
                                         Apply_Standard_Audit__c, Apply_Code_Signing_Audit__c,Root_Certificate_Name__c ,
                                         Root_Certificate_Name_Existing__r.Name,Is_New__c,
                                         Apply_BR_Audit__c, Apply_EV_Audit__c, Apply_EV_Code_Signing_Audit__c,
                                         Mozilla_Status__c, Microsoft_Status__c, SHA_256_Fingerprint__c, Certificate_Serial_Number__c,
                                         Issuer__c, Subject__c, Certificate_Issuer_Common_Name__c, OU_From_Issuer_Field__c, O_From_Issuer_Field__c , 
                                         Certificate_Subject_Common_Name__c, OU_From_Subject_Field__c , O_From_Subject_Field__c , SHA_1_Fingerprint__c, 
                                         SPKI_SHA256__c, Subject_SPKI_SHA256__c, Valid_From__c, Valid_To__c, Public_Key_Algorithm__c, Signature_Hash_Algorithm__c, 
                                         Key_Usage__c, Extended_Key_Usage__c, Technically_Constrained__c, 
                                         Extraction_Results__c, X_509_Certificate_PEM__c  
                                  from   Root_Case__c Where Case_No__c =: objCase.Id Order by Is_New__c, Root_Certificate_Name_Existing__c]){
                if(rc.Root_Certificate_Name_Existing__c != null) {
                    mapExistingRootCases.put(rc.Root_Certificate_Name_Existing__c,rc);
                } else {
                    boolean isReadOnly  = false;
                    if(rc.Request_Status__c != 'Initial Request Received') {
                        isReadOnly = true;
                    }
                    lstWrapAllRootCases.add(new WrapperRootCases(false,isReadOnly ,rc,new Account()));
                }
            }
            
            //loop on all root certificates. 
            for(Account objAccount: [select Id, Name, Status__c, Microsoft_Status__c,
                            Test_Website_Valid__c, Test_Website_Revoked__c,Test_Website_Expired__c, 
                            Issuer__c, Subject__c, Certificate_Issuer_Common_Name__c, Certificate_Issuer_Organizational_Unit__c,
                            Certificate_Issuer_Organization__c, Certificate_Subject_Common_Name__c, 
                            Certificate_Subject_Organization_Unit__c, Certificate_Subject_Organization__c, 
                            SHA_1_Fingerprint__c, SHA_256_Fingerprint__c, SPKI_SHA256__c, Subject_SPKI_SHA256__c, 
                            Valid_From_GMT__c, Valid_To_GMT__c, Public_Key_Algorithm__c, Signature_Hash_Algorithm__c, 
                            Certificate_Serial_Number__c, Certificate_Version__c, Key_Usage__c, Extended_Key_Usage__c, 
                            CRL_URL_s__c, Technically_Constrained__c, Trust_Bits__c, Microsoft_Trust_Bits__c,
                            Extraction_Results__c, X_509_Certificate_PEM__c from 
                            Account Where RecordType.Name = 'Root Certificate' and ParentId =: objCase.AccountId 
                            
                            // (Status__c in ('Included','Change Requested') 
                            // or Microsoft_Status__c In ('Included','Change Requested') 
                            
                            And Valid_To_GMT__c >= Today
                            And (Status__c IN ('Not Yet Included','Included','Change Requested') 
                            OR  Microsoft_Status__c IN ('Not Included','Included','Change Requested','Pending','Not Before')        
                            OR Id in: mapExistingRootCases.keyset()) Order By Name]){
                            
                            
                Root_Case__c objRC = new Root_Case__c();
                //boolean isDisable = false;
                boolean isReadOnly = false;
                boolean isSelected = false;
                objRC.Case_No__c = objCase.Id;
                objRC.Root_Certificate_Name__c = objAccount.Name;
                //if existing root case found, disable select option and copy values from existing root cases
                if(mapExistingRootCases.containskey(objAccount.Id)) {
                    objRC = mapExistingRootCases.get(objAccount.Id);
                    if(objRC.Request_Status__c != 'Initial Request Received') {
                        isReadOnly = true;
                    }
                    isSelected = true;
                } else {
                    //for new root certificates
                    objRC.CA_Owner_Name_Existing__c = objCase.AccountId;
                    if(string.isnotblank(RCAuditUpdateRTId)){
                        objRC.RecordTypeId = RCAuditUpdateRTId;
                    }
                    objRC.Root_Certificate_Name_Existing__c = objAccount.Id;
                    // objRC.Apply_Standard_Audit__c = true; do not set default
                }
                lstWrapAllRootCases.add(new WrapperRootCases(isSelected ,isReadOnly ,objRC,objAccount));
                lstWrapAllRootCases.sort();
            }
        }
    }
    
    //method is used to upsert root cases based on selected root certificates
    public PageReference NextToRootCase(){
        blnAddPEMInfoOpened = false;
        List<Root_Case__c> lstRootCasesToUpsert = new List<Root_Case__c>();
        List<Root_Case__c> lstRootCasesToDelete = new List<Root_Case__c>();
        
        for(WrapperRootCases objWrap: lstWrapAllRootCases){
            if(objWrap.objRootCase.Apply_Standard_Audit__c || objWrap.objRootCase.Apply_Code_Signing_Audit__c || objWrap.objRootCase.Apply_BR_Audit__c ||
                objWrap.objRootCase.Apply_EV_Audit__c || objWrap.objRootCase.Apply_EV_Code_Signing_Audit__c || objWrap.objRootCase.Is_New__c){
                if(objWrap.objRootCase.Id == null && objWrap.objAccount.Id != null) {
                    objWrap.objRootCase.SHA_256_Fingerprint__c = objWrap.objAccount.SHA_256_Fingerprint__c;
                    objWrap.objRootCase.Test_Website_Valid__c = objWrap.objAccount.Test_Website_Valid__c;
                    objWrap.objRootCase.Test_Website_Revoked__c = objWrap.objAccount.Test_Website_Revoked__c;
                    objWrap.objRootCase.Test_Website_Expired__c = objWrap.objAccount.Test_Website_Expired__c;
                    
                    //copy audit fields only for root inclusion type of cases
                    if(objCase.RecordType.Name == 'CA Root Inclusion Request'){
                        // Issuer Info
                        objWrap.objRootCase.Certificate_Issuer_Common_Name__c = objWrap.objAccount.Certificate_Issuer_Common_Name__c;
                        objWrap.objRootCase.OU_From_Issuer_Field__c = objWrap.objAccount.Certificate_Issuer_Organizational_Unit__c;
                        objWrap.objRootCase.O_From_Issuer_Field__c = objWrap.objAccount.Certificate_Issuer_Organization__c;
                        objWrap.objRootCase.Issuer__c = objWrap.objAccount.Issuer__c;
                        
                        // Subject Info
                        objWrap.objRootCase.Certificate_Subject_Common_Name__c = objWrap.objAccount.Certificate_Subject_Common_Name__c;              
                        objWrap.objRootCase.OU_From_Subject_Field__c = objWrap.objAccount.Certificate_Subject_Organization_Unit__c;
                        objWrap.objRootCase.O_From_Subject_Field__c = objWrap.objAccount.Certificate_Subject_Organization__c;
                        objWrap.objRootCase.Subject__c = objWrap.objAccount.Subject__c;
                        
                        // Fingerprint Info      
                        objWrap.objRootCase.SHA_1_Fingerprint__c = objWrap.objAccount.SHA_1_Fingerprint__c;
                        objWrap.objRootCase.SHA_256_Fingerprint__c = objWrap.objAccount.SHA_256_Fingerprint__c;
                        objWrap.objRootCase.SPKI_SHA256__c = objWrap.objAccount.SPKI_SHA256__c;
                        objWrap.objRootCase.Subject_SPKI_SHA256__c = objWrap.objAccount.Subject_SPKI_SHA256__c;
                        
                        // Valid From and To Dates
                        objWrap.objRootCase.Valid_From__c = objWrap.objAccount.Valid_From_GMT__c;
                        objWrap.objRootCase.Valid_To__c = objWrap.objAccount.Valid_To_GMT__c;
                        
                        // Common fields              
                        objWrap.objRootCase.Public_Key_Algorithm__c = objWrap.objAccount.Public_Key_Algorithm__c ;            
                        objWrap.objRootCase.Signature_Hash_Algorithm__c = objWrap.objAccount.Signature_Hash_Algorithm__c;
                        objWrap.objRootCase.Certificate_Serial_Number__c = objWrap.objAccount.Certificate_Serial_Number__c; 
                        //objWrap.objRootCase.Certificate_Fingerprint__c = objWrap.objAccount.Certificate_ID__c;
                        //objWrap.objRootCase.Certificate_Version__c = objWrap.objAccount.Certificate_Version__c;
                        objWrap.objRootCase.Key_Usage__c = objWrap.objAccount.Key_Usage__c ;
                        objWrap.objRootCase.Extended_Key_Usage__c = objWrap.objAccount.Extended_Key_Usage__c; 
                        objWrap.objRootCase.Trust_Bits__c = objWrap.objAccount.Trust_Bits__c;    
                        objWrap.objRootCase.Microsoft_Trust_Bits__c = objWrap.objAccount.Microsoft_Trust_Bits__c;  // needed by ALV       
                        
                        //crl urls
                        //objWrap.objRootCase.CRL_URL_s__c = objWrap.objAccount.CRL_URL_s__c;
                        
                        // Checking for technical constrained flag - additional condition to check for null and converted to lower case and then compare with 'yes'
                        objWrap.objRootCase.Technically_Constrained__c = objWrap.objAccount.Technically_Constrained__c;
                        
                        // Extraction results
                        objWrap.objRootCase.Extraction_Results__c = objWrap.objAccount.Extraction_Results__c;
                        objWrap.objRootCase.X_509_Certificate_PEM__c = objWrap.objAccount.X_509_Certificate_PEM__c;
                    }
                }
                lstRootCasesToUpsert.add(objWrap.objRootCase);
            } else if(objWrap.objRootCase.Root_Certificate_Name_Existing__c != null && objWrap.objRootCase.Id != null) {
                lstRootCasesToDelete.add(objWrap.objRootCase);
            }
        }
        try {
            if(lstRootCasesToDelete.size() > 0){
                delete lstRootCasesToDelete;  // delete root case if all Apply fields are unchecked
            }
            if(lstRootCasesToUpsert.size() > 0) {
                upsert lstRootCasesToUpsert; // update or insert root case if any Apply field has changed
                
                if(objCase.RecordType.Name == 'CA Root Inclusion Request'){
                    set<string> setOfSha256 = new set<string>();
                    set<string> setOfSerialNumber = new set<string>();
                    for(Root_Case__c objRC: lstRootCasesToUpsert){
                        if(objRC.Root_Certificate_Name_Existing__c == null) {
                            setOfSha256.add(objRC.SHA_256_Fingerprint__c);
                            setOfSerialNumber.add(objRC.Certificate_Serial_Number__c);
                        }
                    }
                    
                    if(setOfSha256.size() > 0 && setOfSerialNumber.size() > 0){
                        map<string, Account> mapExistAccounts = new map<string, Account>();
                        for(Account objAcc: [select Id,SHA_256_Fingerprint__c,Certificate_Serial_Number__c from Account Where ParentId =: objCase.AccountId and 
                            SHA_256_Fingerprint__c in: setOfSha256 and Certificate_Serial_Number__c in: setOfSerialNumber]){
                            mapExistAccounts.put(objAcc.SHA_256_Fingerprint__c+'#'+objAcc.Certificate_Serial_Number__c, objAcc);
                        }
                        map<string, Account> mapNewRootAccounts = new map<string, Account>();
                        for(Root_Case__c objRC: lstRootCasesToUpsert){
                            if(objRC.Root_Certificate_Name_Existing__c == null) {
                                string strKey = objRC.SHA_256_Fingerprint__c+'#'+objRC.Certificate_Serial_Number__c;
                                if(!mapExistAccounts.containskey(strKey)){
                                    Account objAcc = new Account();
                                    
                                    objAcc.ParentId = objCase.AccountId;
                                    
                                    //objAcc.Type = 'Root';
                                    objAcc.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Root Certificate').getRecordTypeID();
                                    //Commented to pick default request status
                                    /*objAcc.Status__c = 'Provided by CA';
                                    objAcc.Microsoft_Status__c = 'Provided by CA';
                                    objAcc.Cisco_Status__c = 'Provided by CA';*/
                                    
                                    objAcc.Name = objRC.Root_Certificate_Name__c;
                                    
                                    // Issuer Info
                                    objAcc.Certificate_Issuer_Common_Name__c = objRC.Certificate_Issuer_Common_Name__c;
                                    objAcc.Certificate_Issuer_Organizational_Unit__c = objRC.OU_From_Issuer_Field__c;
                                    objAcc.Certificate_Issuer_Organization__c = objRC.O_From_Issuer_Field__c;
                                    objAcc.Issuer__c = objRC.Issuer__c;
                                    
                                    // Subject Info
                                    objAcc.Certificate_Subject_Common_Name__c = objRC.Certificate_Subject_Common_Name__c;              
                                    objAcc.Certificate_Subject_Organization_Unit__c = objRC.OU_From_Subject_Field__c;
                                    objAcc.Certificate_Subject_Organization__c = objRC.O_From_Subject_Field__c;
                                    objAcc.Subject__c = objRC.Subject__c;
                                    
                                    // Fingerprint Info      
                                    objAcc.SHA_1_Fingerprint__c = objRC.SHA_1_Fingerprint__c;
                                    objAcc.SHA_256_Fingerprint__c = objRC.SHA_256_Fingerprint__c;
                                    objAcc.SPKI_SHA256__c = objRC.SPKI_SHA256__c;
                                    objAcc.Subject_SPKI_SHA256__c = objRC.Subject_SPKI_SHA256__c;
                                    
                                    // Valid From and To Dates
                                    objAcc.Valid_From_GMT__c = objRC.Valid_From__c;
                                    objAcc.Valid_To_GMT__c = objRC.Valid_To__c;
                                    
                                    // Common fields              
                                    objAcc.Public_Key_Algorithm__c = objRC.Public_Key_Algorithm__c ;            
                                    objAcc.Signature_Hash_Algorithm__c = objRC.Signature_Hash_Algorithm__c;
                                    objAcc.Certificate_Serial_Number__c = objRC.Certificate_Serial_Number__c; 
                                    //objAcc.Certificate_ID__c = objRC.Certificate_Fingerprint__c;
                                    //objAcc.Certificate_Version__c = objRC.Certificate_Version__c;
                                    objAcc.Key_Usage__c = objRC.Key_Usage__c ;
                                    objAcc.Extended_Key_Usage__c = objRC.Extended_Key_Usage__c;        
                                    
                                    //crl urls
                                    //objAcc.CRL_URL_s__c = objRC.CRL_URL_s__c;
                                    
                                    // Checking for technical constrained flag - additional condition to check for null and converted to lower case and then compare with 'yes'
                                    objAcc.Technically_Constrained__c = objRC.Technically_Constrained__c;
                                    
                                    // Extraction results
                                    objAcc.Extraction_Results__c = objRC.Extraction_Results__c;
                                    objAcc.X_509_Certificate_PEM__c = objRC.X_509_Certificate_PEM__c;
                                    mapNewRootAccounts.put(strKey, objAcc);
                                }
                            }
                        }
                        if(mapNewRootAccounts.size() > 0){
                            insert mapNewRootAccounts.values();
                            List<Root_Case__c> lstRootCasesToUpdate = new List<Root_Case__c>();
                            for(Root_Case__c objRC: lstRootCasesToUpsert){
                                if(objRC.Root_Certificate_Name_Existing__c == null) {
                                    string strKey = objRC.SHA_256_Fingerprint__c+'#'+objRC.Certificate_Serial_Number__c;
                                    if(mapExistAccounts.containskey(strKey)){
                                        objRC.Root_Certificate_Name_Existing__c = mapExistAccounts.get(strKey).Id;
                                        lstRootCasesToUpdate.add(objRC);
                                    } else if(mapNewRootAccounts.containskey(strKey)){
                                        objRC.Root_Certificate_Name_Existing__c = mapNewRootAccounts.get(strKey).Id;
                                        lstRootCasesToUpdate.add(objRC);
                                    }
                                }
                            }
                            
                            if(lstRootCasesToUpdate.size() > 0) {
                                update lstRootCasesToUpdate;
                            }
                        }
                    }
                }
                
                //ApexPages.AddMessage( new ApexPages.Message( ApexPages.Severity.CONFIRM, 'Root Cases created Successfully.'));
            } else {
                ApexPages.AddMessage( new ApexPages.Message( ApexPages.Severity.Warning, 'Please select at least one root certificate to create Root case.'));
                return null;
            }
            
            LoadRootCases();
        } catch (Exception ex){
            Apexpages.addMessages(ex);
            return null;
        }
        
        PageReference pg = new Pagereference('/'+objCase.Id);
        pg.setReDirect(true);
        return pg;
    }
    
    public void ValidatePEMInfo(){
    
        disableCreateButton = false;  // added by Poonam on 11/7/2018
        try {
            if(CommonMethods.validatePEMInfo(strPEMInfo)) {
            
                // invoke the cert checker webservice and get the response
                // NOTE: Cert checker utiltiy returns Account type 
                parsedCertificateSO = PEMParserController.parsePEM(strPEMInfo);
                
                // set strextractionResults with the value returned by the utility; used by VF page
                strextractionResults = parsedCertificateSO.Extraction_Results__c;    
                
                //show the error message if the webservice was not available
                if(parsedCertificateSO.Display_Webservice_Not_Available__c)
                {      
                    ApexPages.Message apexMessage = new ApexPages.Message(ApexPages.Severity.Error, 'The webservice for parsing cert data is unavailable at the current moment. Please try again later.');
                    ApexPages.addMessage(apexMessage);
                    return;
                }
                
                // show the error message if there were errors parsing the pem info
                if(parsedCertificateSO.Display_Webservice_Failed_Message__c)
                {      
                    ApexPages.Message apexMessage = new ApexPages.Message(ApexPages.Severity.Error, 'Parsing of cert data has failed with errors. Please provide correct PEM format for the Root cert.');
                    ApexPages.addMessage(apexMessage);
                    return;
                }
                
                // show the error message if the extraction results do not have fields
                if(parsedCertificateSO.Extraction_Results__c == '{}')
                {      
                    ApexPages.Message apexMessage = new ApexPages.Message(ApexPages.Severity.Error, 'Parsing of cert data has failed. Please provide correct PEM format for the Root cert.' + ' Extraction Results: ' + parsedCertificateSO.Extraction_Results__c);
                    ApexPages.addMessage(apexMessage);
                    return;
                }
                
                // show the error message if the extraction results does not look right
                /*if(!parsedCertificateSO.Extraction_Results__c.contains('issuerCN'))
                {      
                    ApexPages.Message apexMessage = new ApexPages.Message(ApexPages.Severity.Error, 'Parsing of cert data has failed. Please provide correct PEM format for the Root cert.' + ' Extraction Results: ' + parsedCertificateSO.Extraction_Results__c);
                    ApexPages.addMessage(apexMessage);
                    return;
                }*/
                
                if(parsedCertificateSO.Subject__c != parsedCertificateSO.Issuer__c){
                    // show warning when subject and issuer is not matching
                    string strWarning = 'You are about to create a Root Case for an intermediate certificate. ';
                    strWarning += 'Under normal circumstances, you should add your intermediate certificates to the CCADB using a different process, ';
                    strWarning += 'as described here: https://www.ccadb.org/cas/intermediates.';
                    strWarning += '\nYou can still create root case by clicking on the \'Create Root Case\' button.';
                    ApexPages.addMessage(
                    new ApexPages.Message(ApexPages.Severity.Warning,strWarning));
                } else {
                    // show success message if there were no errors
                    ApexPages.addMessage(
                    new ApexPages.Message(ApexPages.Severity.Confirm,'Cert Check is successful. Please proceed by clicking on the \'Create Root Case\' button.'));
                }    
                // set the boolean flag to show/hide buttons accordingly     
                isCertCheckSuccessful=true; 
            }
        }
        catch (Exception ex) {
            // throw exception messages
            ApexPages.addMessages(ex);
        
        }
    }
    
    //visible text to enter pem info
    public void AddPEMInfo(){
        blnAddPEMInfoOpened = true;
        strPEMInfo = '';
        strextractionResults = '';
        isCertCheckSuccessful = false;
    }
    
    //hide text to enter pem info
    public void CancelPEMInfo(){
        blnAddPEMInfoOpened = false;
        //system.debug('blnAddPEMInfoOpened  :::: '+blnAddPEMInfoOpened );
    }
    
    public PageReference CreateRootCert(){
        disableCreateButton = false;
        
        string strInclusionRecordTypeId = Schema.SObjectType.Root_Case__c.getRecordTypeInfosByName().get('CA Root Inclusion Request').getRecordTypeId();
        
        Root_Case__c rootCaseSO = new Root_Case__c(Case_No__c = CaseId, RecordTypeId = strInclusionRecordTypeId);
        
        rootCaseSO.X_509_Certificate_PEM__c = strPEMInfo;
        
        boolean isRootExist = false;
        if(parsedCertificateSO.SHA_256_Fingerprint__c.contains(':')) parsedCertificateSO.SHA_256_Fingerprint__c = parsedCertificateSO.SHA_256_Fingerprint__c.replace(':',''); 
        
        List<Root_Case__c> lstRootCases = new List<Root_Case__c>([select Id from Root_Case__c Where 
                SHA_256_Fingerprint__c =: parsedCertificateSO.SHA_256_Fingerprint__c and Case_No__c =: CaseId]);
        if(lstRootCases.size() > 0){
            isRootExist = true;
        }
        
        if(isRootExist){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Root case with this PEM already exists. Please select from above list.')); 
            //blnAddPEMInfoOpened = false;
            disableCreateButton = true;
            return null;
        }
        Savepoint sp = Database.setSavepoint();
        try {
            List<Case> lstCases = new List<Case>([select Id, AccountId from Case Where Id =: CaseId]); 
             
            // header info  
            rootCaseSO.Root_Certificate_Name__c = parsedCertificateSO.name;
            if(lstCases.size() > 0) {
                rootCaseSO.CA_Owner_Name_Existing__c = lstCases[0].AccountId;
            }
            
            // Issuer Info
            rootCaseSO.Certificate_Issuer_Common_Name__c = parsedCertificateSO.Certificate_Issuer_Common_Name__c;
            rootCaseSO.OU_From_Issuer_Field__c = parsedCertificateSO.Certificate_Issuer_Organizational_Unit__c;
            rootCaseSO.O_From_Issuer_Field__c = parsedCertificateSO.Certificate_Issuer_Organization__c;
            rootCaseSO.Issuer__c = parsedCertificateSO.Issuer__c;
            
            // Subject Info
            rootCaseSO.Certificate_Subject_Common_Name__c = parsedCertificateSO.Certificate_Subject_Common_Name__c;              
            rootCaseSO.OU_From_Subject_Field__c = parsedCertificateSO.Certificate_Subject_Organization_Unit__c;
            rootCaseSO.O_From_Subject_Field__c = parsedCertificateSO.Certificate_Subject_Organization__c;
            rootCaseSO.Subject__c = parsedCertificateSO.Subject__c;
            
            // Fingerprint Info      
            rootCaseSO.SHA_1_Fingerprint__c = parsedCertificateSO.SHA_1_Fingerprint__c;
            rootCaseSO.SHA_256_Fingerprint__c = parsedCertificateSO.SHA_256_Fingerprint__c;
            rootCaseSO.SPKI_SHA256__c = parsedCertificateSO.SPKI_SHA256__c;
            rootCaseSO.Subject_SPKI_SHA256__c = parsedCertificateSO.Subject_SPKI_SHA256__c;
            
            // Valid From and To Dates
            rootCaseSO.Valid_From__c = parsedCertificateSO.Valid_From_GMT__c;
            rootCaseSO.Valid_To__c = parsedCertificateSO.Valid_To_GMT__c;
            
            // Common fields              
            rootCaseSO.Public_Key_Algorithm__c = parsedCertificateSO.Public_Key_Algorithm__c ;            
            rootCaseSO.Signature_Hash_Algorithm__c = parsedCertificateSO.Signature_Hash_Algorithm__c;
            rootCaseSO.Certificate_Serial_Number__c = parsedCertificateSO.Certificate_Serial_Number__c; 
            //rootCaseSO.Certificate_Fingerprint__c = parsedCertificateSO.Certificate_ID__c;
            //rootCaseSO.Certificate_Version__c = parsedCertificateSO.Certificate_Version__c;
            // rootCaseSO.Basic_Constraints__c = parsedCertificateSO.Basic_Constraints__c;
            rootCaseSO.Key_Usage__c = parsedCertificateSO.Key_Usage__c ;
            rootCaseSO.Extended_Key_Usage__c = parsedCertificateSO.Extended_Key_Usage__c;        
            
            //crl urls
            //rootCaseSO.CRL_URL_s__c = parsedCertificateSO.CRL_URL_s__c;
            //rootCaseSO.OCSP_URL_s__c = parsedCertificateSO.OCSP_URL_s__c;
            
            // Checking for technical constrained flag - additional condition to check for null and converted to lower case and then compare with 'yes'
            rootCaseSO.Technically_Constrained__c = parsedCertificateSO.Technically_Constrained__c;
            
            // Extraction results
            rootCaseSO.Extraction_Results__c = parsedCertificateSO.Extraction_Results__c;
            
            //by default standard audit is checked
            //rootCaseSO.Apply_Standard_Audit__c = true;
            
            
            rootCaseSO.Is_New__c = true;
            insert rootCaseSO; 
            
            //checking for root certificate
            List<Account> lstAccount = new List<Account>([select Id from Account Where ParentId =: lstCases[0].AccountId and 
                        SHA_256_Fingerprint__c =: parsedCertificateSO.SHA_256_Fingerprint__c 
                        and Certificate_Serial_Number__c =: parsedCertificateSO.Certificate_Serial_Number__c]);
            if(lstAccount.size() == 0){
                //Record type.
                parsedCertificateSO.X_509_Certificate_PEM__c = strPEMInfo;
                parsedCertificateSO.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Root Certificate').getRecordTypeID();
                parsedCertificateSO.ParentId = lstCases[0].AccountId;
                //commented to pick default status
                /*parsedCertificateSO.Status__c = 'Provided by CA';
                parsedCertificateSO.Microsoft_Status__c = 'Provided by CA';
                parsedCertificateSO.Cisco_Status__c = 'Provided by CA';*/
                insert parsedCertificateSO;
                
                rootCaseSO.Root_Certificate_Name_Existing__c = parsedCertificateSO.Id;
                update rootCaseSO;
            }
              
            ApexPages.AddMessage( new ApexPages.Message( ApexPages.Severity.CONFIRM, 'Root Case created successfully. Please check for the newly added root cert in the list, indicate which audit statements it is included in, then click on the "Apply Changes" button. To add another Root Cert,use "Add PEM Info" button again.'));
            LoadRootCases();
            blnAddPEMInfoOpened = false;
        }catch(Exception ex){
            Database.rollback(sp);
            String errorMessage;
            if (ex.getDmlType(0) == StatusCode.DUPLICATES_DETECTED) {
               errorMessage = 'Update Failed. Update would result in a duplicate Root Certificate. Please use the existing record ' + rootCaseSO.name; 
               ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, errorMessage));    
            } else {
               errorMessage = 'Error processing!! Please contact your administrator. ' + ex.getMessage();
               ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, errorMessage)); 
            }     
            disableCreateButton = true;
            return null;
        }    
     
        PageReference pg = new PageReference('/' + rootCaseSO.id);
        pg.setRedirect(true);
        return null;
    }
    
    //wrapper class for displaying root certificates 
    public class WrapperRootCases implements Comparable {
        public boolean isSelected {get; set;} // For Action column NOT BEING USED 
        //public boolean isDisabled {get; set;}
        public boolean isReadOnly {get; set;}  // depends on Request Status
        public Root_Case__c objRootCase {get; set;} // for Root Case fields
        public Account objAccount {get; set;}  // for account fields like SHA-1 etc
        public WrapperRootCases(boolean isSel, boolean isRead, Root_Case__c objRC, Account objAcc){
            this.isSelected = isSel;
            this.isReadOnly = isRead;
            this.objRootCase = objRC;
            this.objAccount = objAcc;
        }   
        
        public Integer compareTo(Object objToCompare) {
            WrapperRootCases wrap = (WrapperRootCases)objToCompare;
            if(wrap.objRootCase != null && wrap.objRootCase.Is_New__c){
                return 1;
            } else {
                return 0;
            }
        }  
    }
    
    
}
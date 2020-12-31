/*******************************************************************************************************
 Name: SyncRootAccountFromInclusionCaseCtrl

 Dependencies: SyncParentAccountFromInclusionCaseCtrl controller class, SyncParentAccountFromInclusionCase 
 vf page, SyncParentAccountFromIncluCaseCtrlTest, SyncRootAccountFromInclusionCaseCtrl, 
 SyncRootAccountFromInclusionCase vf page, SyncRootAccountFromInclusionCaseCtrlTest

 Description: This is the controller class for the SyncRootAccountFromInclusionCase VF page. The user gets 
 redirected to this page after fields displayed on the SyncParentAccountFromInclusionCase VF Page are 
 synced (or may not be) with the parent account.
 
 When the "Sync MozillaRootInclusionInfo" button is clicked from any from Case page for Record Type 
 'CA Root Inclusion Request' type "Case", the user is first redirected to SyncParentAccountFromInclusionCase VF page. 
 
 Here the user has options to update two sets of records CA Owner record and Root Certificate record: 
 1. Update the displayed fields from the Case record to the Parent Account (or the CA Owner).     
    AND
 2. Update and iterate through the Root Case records which are associated with this Case and
    allow user to update assiciated Root Certificate record on Account.
        
 Sync can be done for CA Owner, Auditor, Audit, Test Websites fields when data is "Data Verified"
 and Case Status is at any stage.
  
 Mozilla fields can only be synced when Case.Request Status is 'Complete' or 'Included or Pending EV'.
 
 Parent Account (CA Owner) Status is set to 'Included' only if all related Cases are 'Complete' or 'Included, Pending EV'
     
 Instructions: None   
 *******************************************************************************************************
 Revision History:
 
     10/15/2018    Created new class
     6/11/2019     Removed condition to check request status of root cases. Allow to sync root case on any stage.
     6/19/2019     Updated program to reate cseparate sections for auditor, audit, cp/cps fields and 
                   allow users to copy individual sections
     8/26/2020     Commented CP/CPS fields, this data now resides in Policy Doc objects na they are synced separately              
 ******************************************************************************************************/

global with sharing class SyncRootAccountFromInclusionCaseCtrl {

    // flag for exception handling
    Public Boolean hasError{get; set;}  
    
    // the root account object whose name is same as the root case name.
    public Account rootAccountSO;
    public Root_Case__c rootCaseSO;
    public Case caseSO {get; set;}
    
    //this variable holds the count of total number of root cases. this is displayed on the page
    Integer totalRootCaseCount;
    
    //this variable holds the sequence number of the current account ex: 2 of 4 
    Integer currentRecordCount;
    
    private List<Root_Case__c> lstRootCases;
    
    private Map<Id, Root_Case__c> mapRootCases = new Map<Id, Root_Case__c>();
    
    private Map<string, Account> mapRootAccounts = new Map<string, Account>();
    
    //check if root cases are found or not
    public boolean isRootCasesFound {get; set;}
    
    Boolean rootAccountExists;
    
    public Boolean isRecordUpdated {get; private set;}
    public Boolean isUpdateCancelled {get; private set;}
    public boolean isCPACanadaURLDoesntMatch {get; set;}
    public string strCPACanadaURLDoesntMatch {get; set;}
    String caseId;
    
    public Boolean showAuditorNewConfirmation {get;set;}
    public Boolean showStandardAuditConfirmation {get;set;}
    public Boolean showCodeSigningAuditConfirmation {get;set;}
    public Boolean showBRAuditConfirmation {get;set;}
    public Boolean showEVSSLAuditConfirmation {get;set;}
    public Boolean showEVCodeSigningAuditConfirmation {get;set;}
    public Boolean showAllOtherConfirmation {get;set;}
    public Boolean showTestWebsitesConfirmation {get;set;}
    public Boolean showCPCPSAuditConfirmation {get; set;}
    
    //constructor method for standard controller    
    public SyncRootAccountFromInclusionCaseCtrl(ApexPages.StandardController stdController) {
         
        // get the record id on which the button was clicked
        caseId = stdController.getId();
         
        Set<String> accountIds = new Set<String>();
        Set<string> rootSha256FingerPrints = new set<string>();
        
        this.lstRootCases = new List<Root_Case__c>();
        this.currentRecordCount = 0;
        this.isRecordUpdated = false;
        this.isUpdateCancelled = false;
        this.isCPACanadaURLDoesntMatch = false;
        strCPACanadaURLDoesntMatch = '';
        this.hasError = false;
        isRootCasesFound = false;
        
        this.showTestWebsitesConfirmation = false;
        this.showAuditorNewConfirmation = false;
        this.showStandardAuditConfirmation = false;
        this.showCodeSigningAuditConfirmation = false;
        this.showBRAuditConfirmation = false;
        this.showEVSSLAuditConfirmation = false;
        this.showEVCodeSigningAuditConfirmation = false;
        this.showAllOtherConfirmation = false;
        this.showCPCPSAuditConfirmation = false;
        
        //get case details
        List<Case> lstCaseSO = new List<Case>([select Id, Auditor_New__c,Auditor_New__r.Name, Auditor_Location_New__c,Auditor_Location_New__r.Name, Standard_Audit_Statement_Link__c,Standard_Audit_Type__c,
                Standard_Audit_Statement_Date__c,Standard_Audit_Period_Start_Date__c,Standard_Audit_Period_End_Date__c,
                BR_Audit_Statement_Link__c,BR_Audit_Type__c,BR_Audit_Statement_Date__c,BR_Audit_Period_Start_Date__c,BR_Audit_Period_End_Date__c,
                Code_Signing_Audit_Statement_Link__c,Code_Signing_Audit_Type__c,Code_Signing_Audit_Period_Start_Date__c,Code_Signing_Audit_Period_End_Date__c,
                Code_Signing_Audit_Statement_Date__c,EV_Audit_Statement_Link__c,EV_Audit_Type__c,EV_Audit_Statement_Date__c,EV_Audit_Period_Start_Date__c,
                EV_Audit_Period_End_Date__c,EV_Code_Signing_Audit_Statement_Link__c,EV_Code_Signing_Audit_Type__c,EV_Code_Signing_Audit_Statement_Date__c,
                EV_Code_Signing_Audit_Period_Start_Date__c,EV_Code_Signing_Audit_Period_End_Date__c,Policy_Documentation__c,
                CA_Document_Repository__c,Certificate_Policy_Link__c,Certification_Practice_Statement_Link__c,CP_CPS_Last_Updated_Date__c,
                Auditor_Verified__c,Standard_Audit_Verified__c,Code_Signing_Audit_Verified__c,BR_Audit_Statement_Link_Verified__c,
                EV_Audit_Statement_Link_Verified__c,EV_Code_Signing_Verified__c,CP_CPS_Links_Verified__c,Request_Status__c 
                from Case Where Id =: caseId]);
        if(lstCaseSO.size() > 0){
            caseSO = lstCaseSO[0];
            set<string> setofAuditUrls = new set<string>();
            if(caseSO.Standard_Audit_Statement_Link__c != null && (caseSO.Standard_Audit_Statement_Link__c.startswith('https://www.cpacanada.ca') ||
                caseSO.Standard_Audit_Statement_Link__c.startswith('https://cert.webtrust.org'))){
                setofAuditUrls.add(caseSO.Standard_Audit_Statement_Link__c);
            }
            if(caseSO.Code_Signing_Audit_Statement_Link__c != null && (caseSO.Code_Signing_Audit_Statement_Link__c.startswith('https://www.cpacanada.ca') || 
                caseSO.Code_Signing_Audit_Statement_Link__c.startswith('https://cert.webtrust.org'))){
                setofAuditUrls.add(caseSO.Code_Signing_Audit_Statement_Link__c);
            }
            if(caseSO.BR_Audit_Statement_Link__c != null && (caseSO.BR_Audit_Statement_Link__c.startswith('https://www.cpacanada.ca') ||
                caseSO.BR_Audit_Statement_Link__c.startswith('https://cert.webtrust.org'))){
                setofAuditUrls.add(caseSO.BR_Audit_Statement_Link__c);
            }
            if(caseSO.EV_Audit_Statement_Link__c != null && (caseSO.EV_Audit_Statement_Link__c.startswith('https://www.cpacanada.ca') ||
                caseSO.EV_Audit_Statement_Link__c.startswith('https://cert.webtrust.org'))){
                setofAuditUrls.add(caseSO.EV_Audit_Statement_Link__c);
            }
            if(caseSO.EV_Code_Signing_Audit_Statement_Link__c != null && (caseSO.EV_Code_Signing_Audit_Statement_Link__c.startswith('https://www.cpacanada.ca') ||
                caseSO.EV_Code_Signing_Audit_Statement_Link__c.startswith('https://cert.webtrust.org'))){
                setofAuditUrls.add(caseSO.EV_Code_Signing_Audit_Statement_Link__c);
            }
            
            if(setofAuditUrls.size() > 0){
                map<string, Id> mapCPACanadaFiles = new map<string, Id>();
                for(CPACanada_File__c file: [select Id,Name,Report_URL__c from CPACanada_File__c Where Report_URL__c != null and Report_URL__c in: setofAuditUrls]){
                    mapCPACanadaFiles.put(file.Report_URL__c.tolowercase(), file.Id);
                }
                if(caseSO.Standard_Audit_Statement_Link__c != null && (caseSO.Standard_Audit_Statement_Link__c.startswith('https://www.cpacanada.ca') ||
                    caseSO.Standard_Audit_Statement_Link__c.startswith('https://cert.webtrust.org')) && 
                    !mapCPACanadaFiles.containskey(caseSO.Standard_Audit_Statement_Link__c.tolowercase())){
                    strCPACanadaURLDoesntMatch += 'Standard Audit Report URL does not match Seal ID in CPA Canada object. Re-enter the Seal ID URL, which will re-map to the new report URL.' + '<br/>';
                    isCPACanadaURLDoesntMatch = true;
                }
                if(caseSO.Code_Signing_Audit_Statement_Link__c != null && (caseSO.Code_Signing_Audit_Statement_Link__c.startswith('https://www.cpacanada.ca') ||
                    caseSO.Code_Signing_Audit_Statement_Link__c.startswith('https://cert.webtrust.org')) &&
                    !mapCPACanadaFiles.containskey(caseSO.Code_Signing_Audit_Statement_Link__c.tolowercase())){
                    isCPACanadaURLDoesntMatch = true;
                    strCPACanadaURLDoesntMatch += 'Code Signing Audit Report URL does not match Seal ID in CPA Canada object. Re-enter the Seal ID URL, which will re-map to the new report URL.' + '<br/>';
                }
                if(caseSO.BR_Audit_Statement_Link__c != null && (caseSO.BR_Audit_Statement_Link__c.startswith('https://www.cpacanada.ca') ||
                    caseSO.BR_Audit_Statement_Link__c.startswith('https://cert.webtrust.org')) &&
                    !mapCPACanadaFiles.containskey(caseSO.BR_Audit_Statement_Link__c.tolowercase())){
                    isCPACanadaURLDoesntMatch = true;
                    strCPACanadaURLDoesntMatch += 'BR Audit Report URL does not match Seal ID in CPA Canada object. Re-enter the Seal ID URL, which will re-map to the new report URL.' + '<br/>';
                }
                if(caseSO.EV_Audit_Statement_Link__c != null && (caseSO.EV_Audit_Statement_Link__c.startswith('https://www.cpacanada.ca') ||
                    caseSO.EV_Audit_Statement_Link__c.startswith('https://cert.webtrust.org')) &&
                    !mapCPACanadaFiles.containskey(caseSO.EV_Audit_Statement_Link__c.tolowercase())){
                    isCPACanadaURLDoesntMatch = true;
                    strCPACanadaURLDoesntMatch += 'EV SSL Audit Report URL does not match Seal ID in CPA Canada object. Re-enter the Seal ID URL, which will re-map to the new report URL.' + '<br/>';
                }
                if(caseSO.EV_Code_Signing_Audit_Statement_Link__c != null && (caseSO.EV_Code_Signing_Audit_Statement_Link__c.startswith('https://www.cpacanada.ca') ||
                    caseSO.EV_Code_Signing_Audit_Statement_Link__c.startswith('https://cert.webtrust.org')) &&
                    !mapCPACanadaFiles.containskey(caseSO.EV_Code_Signing_Audit_Statement_Link__c.tolowercase())){
                    isCPACanadaURLDoesntMatch = true;
                    strCPACanadaURLDoesntMatch += 'EV Code Signing Audit Report URL does not match Seal ID in CPA Canada object. Re-enter the Seal ID URL, which will re-map to the new report URL.' + '<br/>';
                }
            } 
        }
        
        for(Root_Case__c rootCase : [select name, case_no__c, case_no__r.accountid, case_no__r.Link_to_Bugzilla_Bug__c, 
                Root_Certificate_Name__c, Certificate_Issuer_Common_Name__c, O_From_Issuer_Field__c, OU_From_Issuer_Field__c, 
                SHA_1_Fingerprint__c, SHA_256_Fingerprint__c, 
                valid_from__c, valid_to__c, Certificate_Serial_Number__c, 
                Subject__c, Signature_Hash_Algorithm__c, Public_Key_Algorithm__c, 
                Apply_Standard_Audit__c,Apply_Code_Signing_Audit__c,Apply_BR_Audit__c,Apply_EV_Code_Signing_Audit__c,
                Test_Website_Expired__c, Test_Website_Revoked__c, Test_Website_Valid__c, Apply_EV_Audit__c,
                Trust_Bits__c, EV_Policy_OID_s__c, Mozilla_Applied_Constraints__c, 
                Issuer__c,OU_From_Subject_Field__c,O_From_Subject_Field__c,
                Subject_SPKI_SHA256__c,SPKI_SHA256__c, Is_New__c,Certificate_Subject_Common_Name__c,
                NSS_Release_When_First_Included__c, Firefox_Release_When_First_Included__c , 
                X_509_Certificate_PEM__c, Extraction_Results__c, Request_Status__c, Test_Website_Verified__c
                FROM Root_Case__c where Case_No__c = :caseId ]){
            //AND Request_Status__c in ('Included, Pending EV','Complete')
            mapRootCases.put(rootCase.Id, rootCase);
            accountIds.add(rootCase.Case_no__r.AccountId);
            rootSha256FingerPrints.add(rootCase.SHA_256_Fingerprint__c);
            isRootCasesFound = true;
        }
        
        lstRootCases.addAll(mapRootCases.values());
        this.totalRootCaseCount = lstRootCases.size();
        for(Account objAcc: [SELECT Id, Name, Parentid, Type, CA_Owner_Id__c, Certificate_Issuer_Common_Name__c, Certificate_Issuer_Organization__c, 
                                   Certificate_Issuer_Organizational_Unit__c, Approval_Bug__c, 
                                   SHA_1_Fingerprint__c, SHA_256_Fingerprint__c, Certificate_Version__c,
                                   Valid_from_GMT__c, Valid_to_GMT__c, Certificate_Serial_Number__c, Subject__c,
                                   Signature_Hash_Algorithm__c, Public_Key_Algorithm__c,
                                   Test_Website_Expired__c, Test_Website_Revoked__c, Test_Website_Valid__c,
                                   CRL_URL_s__c,Issuer__c,Certificate_Subject_Organization__c ,Certificate_Subject_Organization_Unit__c ,
                                   Subject_SPKI_SHA256__c,SPKI_SHA256__c,Certificate_Subject_Common_Name__c,
                                   Trust_Bits__c, EV_Policy_OID_s__c, Mozilla_Applied_Constraints__c,
                                   Standard_Audit__c, Standard_Audit_Type__c, Standard_Audit_Statement_Date__c,
                                   Standard_Audit_Period_Start_Date__c, Standard_Audit_Period_End_Date__c,
                                   Code_Signing_Audit__c, Code_Signing_Audit_Type__c, Code_Signing_Audit_Statement_Date__c, 
                                   Code_Signing_Audit_Period_Start_Date__c, Code_Signing_Audit_Period_End_Date__c,
                                   BR_Audit__c, BR_Audit_Type__c, BR_Audit_Statement_Date__c, 
                                   BR_Audit_Period_Start_Date__c, BR_Audit_Period_End_Date__c,
                                   EV_Audit__c, EV_Audit_Type__c, EV_Audit_Statement_Date__c,
                                   EV_Audit_Period_Start_Date__c, EV_Audit_Period_End_Date__c,
                                   EV_Code_Signing_Audit__c, EV_Code_Signing_Audit_Type__c,EV_Code_Signing_Audit_Statement_Date__c,
                                   EV_Code_Signing_Audit_Period_Start_Date__c,EV_Code_Signing_Audit_Period_End_Date__c,
                                   CP_CPS_Last_Updated_Date__c,
                                   Auditor_New__c, Auditor_New__r.Name, Auditor_Location_New__c, Auditor_Location_New__r.Name,     
                                   Policy_Documentation__c, CA_Document_Repository__c, Certificate_Policy_CP__c, 
                                   Certification_Practice_Statement_CPS__c, 
                                   NSS_Release_When_First_Included__c, Firefox_Release_When_First_Included__c,
                                   X_509_Certificate_PEM__c                                   
                                   FROM Account WHERE ParentId IN :accountIds AND Type = 'Root' AND Name <> '<Fill in Cert Name>' AND
                                   SHA_256_Fingerprint__c in: rootSha256FingerPrints]){
            mapRootAccounts.put(objAcc.SHA_256_Fingerprint__c, objAcc);
        }
        getRecordsForComparison();
        
    }//end of constructor
    
    private void getRecordsForComparison(){
        
        this.rootAccountSO = null;
        this.isRecordUpdated = false;
        this.isUpdateCancelled = false;
        this.hasError = false;
        
        this.showTestWebsitesConfirmation = false;
        this.showAuditorNewConfirmation = false;
        this.showStandardAuditConfirmation = false;
        this.showCodeSigningAuditConfirmation = false;
        this.showBRAuditConfirmation = false;
        this.showEVSSLAuditConfirmation = false;
        this.showEVCodeSigningAuditConfirmation = false;
        this.showAllOtherConfirmation = false;
        this.showCPCPSAuditConfirmation = false;
        
        if(!lstRootCases.isEmpty() && this.currentRecordCount < this.totalRootCaseCount){
            this.rootCaseSO = lstRootCases[this.currentRecordCount];
            
            if(mapRootAccounts.containskey(this.rootCaseSO.SHA_256_Fingerprint__c)){
                this.rootAccountSO = mapRootAccounts.get(this.rootCaseSO.SHA_256_Fingerprint__c);
                rootAccountExists  = true;
            }
            
            if(this.rootAccountSO == null){
                this.rootAccountSO = createNewAccountSoInstance(this.rootCaseSO.Root_Certificate_Name__c, this.rootCaseSO.Case_No__r.AccountId);
                rootAccountExists = false;
            }
        }
    }
    
    // this method is invoked when the root case contains the account name which does not exists
    // in that case we need to create a new root account
    public Account createNewAccountSoInstance(String accName, String acParentId){
        Account rootAccountSo = new Account(Name = accName, ParentId = acParentId);
        rootAccountSo.RecordTypeID = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Root Certificate').getRecordTypeID();
        return rootAccountSo;
    }
    
    //when root case is newly created copy PEM information
    public Account copyPEMInfo(Account rootAcc, Root_Case__c rootcase){
        //we are not copying this information as we are already copying while creating certificate.
        /*if(rootcase.Is_New__c) {
            //sync subject fields
            rootAcc.Subject__c = rootcase.Subject__c; 
            rootAcc.Certificate_Subject_Common_Name__c = rootcase.Certificate_Subject_Common_Name__c;
            rootAcc.Certificate_Subject_Organization_Unit__c = rootcase.OU_From_Subject_Field__c;
            rootAcc.Certificate_Subject_Organization__c = rootcase.O_From_Subject_Field__c;
            
            //sync issuer fields
            rootAcc.Issuer__c = rootcase.Issuer__c;
            rootAcc.Certificate_Issuer_Common_Name__c = rootcase.Certificate_Issuer_Common_Name__c;
            rootAcc.Certificate_Issuer_Organization__c = rootcase.O_From_Issuer_Field__c;
            rootAcc.Certificate_Issuer_Organizational_Unit__c = rootcase.OU_From_Issuer_Field__c;
            
            //Certificate Data from root cases section
            rootAcc.valid_from_GMT__c= rootcase.valid_from__c;
            rootAcc.valid_to_GMT__c= rootcase.valid_to__c; 
            rootAcc.Certificate_Serial_Number__c= rootcase.Certificate_Serial_Number__c; 
            rootAcc.SHA_1_Fingerprint__c= rootcase.SHA_1_Fingerprint__c;
            rootAcc.Signature_Hash_Algorithm__c= rootcase.Signature_Hash_Algorithm__c; 
            rootAcc.Public_Key_Algorithm__c= rootcase.Public_Key_Algorithm__c;        
            rootAcc.SPKI_SHA256__c  = rootcase.SPKI_SHA256__c ;
            rootAcc.Subject_SPKI_SHA256__c = rootcase.Subject_SPKI_SHA256__c ;
            rootAcc.Root_Certificate_Download_URL__c = rootcase.Root_Certificate_Download_URL__c;
        }
        //rootAcc.Certificate_ID__c = rootcase.Certificate_Fingerprint__c;
        //pem information
        rootAcc.X_509_Certificate_PEM__c = rootcase.X_509_Certificate_PEM__c;
        rootAcc.Extraction_Results__c = rootcase.Extraction_Results__c;*/
        
        //last sync update info
        rootAcc.Last_Sync_Case_No__c = rootcase.Name;
        rootAcc.Last_Sync_Date_Time__c = System.now();
        //if root case status is included EV pending or completed then update status to included.
        if(rootcase.Request_Status__c == 'Included, Pending EV' || rootcase.Request_Status__c == 'Complete') {
            rootAcc.Status__c = 'Included'; 
        }
        return rootAcc;
    }
    
    
    // update the case to auditor information
    public void syncAuditorNewFields() {
        if(this.rootAccountSo != null && this.caseSO != null) {
            //audit infomration
            this.rootAccountSo.Auditor_New__c = this.caseSO.Auditor_New__c;
            this.rootAccountSo.Auditor_Location_New__c = this.caseSO.Auditor_Location_New__c;
            //sync common info
            this.rootAccountSo = copyPEMInfo(this.rootAccountSo, this.rootCaseSO); 
            this.showAuditorNewConfirmation = true;
            try {
                upsert this.rootAccountSo;
                //re-query and get udpated values
                this.rootAccountSo = [SELECT Id, Name, Parentid, Type, Certificate_Issuer_Common_Name__c, Certificate_Issuer_Organization__c, 
                                   Certificate_Issuer_Organizational_Unit__c, Approval_Bug__c, 
                                   SHA_1_Fingerprint__c, SHA_256_Fingerprint__c, Certificate_Version__c,
                                   Valid_from_GMT__c, Valid_to_GMT__c, Certificate_Serial_Number__c, Subject__c,
                                   Signature_Hash_Algorithm__c, Public_Key_Algorithm__c,
                                   Test_Website_Expired__c, Test_Website_Revoked__c, Test_Website_Valid__c,
                                   CRL_URL_s__c,Issuer__c,Certificate_Subject_Organization__c ,Certificate_Subject_Organization_Unit__c ,
                                   Subject_SPKI_SHA256__c,SPKI_SHA256__c,Certificate_Subject_Common_Name__c,
                                   Trust_Bits__c, EV_Policy_OID_s__c, Mozilla_Applied_Constraints__c,
                                   Standard_Audit__c, Standard_Audit_Type__c, Standard_Audit_Statement_Date__c,
                                   Standard_Audit_Period_Start_Date__c, Standard_Audit_Period_End_Date__c,
                                   Code_Signing_Audit__c, Code_Signing_Audit_Type__c, Code_Signing_Audit_Statement_Date__c, 
                                   Code_Signing_Audit_Period_Start_Date__c, Code_Signing_Audit_Period_End_Date__c,
                                   BR_Audit__c, BR_Audit_Type__c, BR_Audit_Statement_Date__c,
                                   BR_Audit_Period_Start_Date__c, BR_Audit_Period_End_Date__c,
                                   EV_Audit__c, EV_Audit_Type__c, EV_Audit_Statement_Date__c,
                                   EV_Audit_Period_Start_Date__c, EV_Audit_Period_End_Date__c, 
                                   EV_Code_Signing_Audit__c, EV_Code_Signing_Audit_Type__c,EV_Code_Signing_Audit_Statement_Date__c,
                                   EV_Code_Signing_Audit_Period_Start_Date__c,EV_Code_Signing_Audit_Period_End_Date__c,
                                   Auditor_New__c, Auditor_New__r.Name, Auditor_Location_New__c, Auditor_Location_New__r.Name,     
                                   Policy_Documentation__c, CA_Document_Repository__c, Certificate_Policy_CP__c, 
                                   Certification_Practice_Statement_CPS__c, CP_CPS_Last_Updated_Date__c,
                                   NSS_Release_When_First_Included__c, Firefox_Release_When_First_Included__c,
                                   X_509_Certificate_PEM__c                                   
                                   FROM Account
                                   WHERE Id = :rootAccountSo.Id];
            } catch (Exception ex) {
                this.hasError = true;
                ApexPages.addMessages(ex);
            }
        }
    }
    
    // update the case to standard audit fields
    public void syncStandardAuditFields() {
        //standard audit
        if(this.rootCaseSO.Apply_Standard_Audit__c) {
            if(this.caseSO.Standard_Audit_Statement_Link__c != null && this.caseSO.Standard_Audit_Statement_Link__c.startswith('http')) {
                this.rootAccountSo.Standard_Audit__c = this.caseSO.Standard_Audit_Statement_Link__c; 
                this.rootAccountSo.Standard_Audit_Type__c = this.caseSO.Standard_Audit_Type__c; 
                this.rootAccountSo.Standard_Audit_Statement_Date__c = this.caseSO.Standard_Audit_Statement_Date__c;
                this.rootAccountSo.Standard_Audit_Period_Start_Date__c = this.caseSO.Standard_Audit_Period_Start_Date__c;
                this.rootAccountSo.Standard_Audit_Period_End_Date__c = this.caseSO.Standard_Audit_Period_End_Date__c;
                //sync common info
                this.rootAccountSo = copyPEMInfo(this.rootAccountSo, this.rootCaseSO);
                this.showStandardAuditConfirmation = true;
                try {
                    upsert this.rootAccountSo;
                } catch (Exception ex) {
                    this.hasError = true;
                    ApexPages.addMessages(ex);
                }
            }
        }
    }
    
    // update the case to code signing audit fields
    public void syncCodeSigningAuditFields() {
        //code signing audit
        if(this.rootCaseSO.Apply_Code_Signing_Audit__c) {
            if(this.caseSO.Code_Signing_Audit_Statement_Link__c != null && this.caseSO.Code_Signing_Audit_Statement_Link__c.startswith('http')) {
                this.rootAccountSo.Code_Signing_Audit__c = this.caseSO.Code_Signing_Audit_Statement_Link__c; 
                this.rootAccountSo.Code_Signing_Audit_Type__c= this.caseSO.Code_Signing_Audit_Type__c;
                this.rootAccountSo.Code_Signing_Audit_Statement_Date__c= this.caseSO.Code_Signing_Audit_Statement_Date__c;
                this.rootAccountSo.Code_Signing_Audit_Period_Start_Date__c = this.caseSO.Code_Signing_Audit_Period_Start_Date__c;
                this.rootAccountSo.Code_Signing_Audit_Period_End_Date__c = this.caseSO.Code_Signing_Audit_Period_End_Date__c;
                //sync common info
                this.rootAccountSo = copyPEMInfo(this.rootAccountSo, this.rootCaseSO); 
                this.showCodeSigningAuditConfirmation = true;
                try {
                    upsert this.rootAccountSo;
                } catch (Exception ex) {
                    this.hasError = true;
                    ApexPages.addMessages(ex);
                }
            }
        }
    }
    
    // update the case to BR audit fields
    public void syncBRAuditFields() {
        //br audit
        if(this.rootCaseSO.Apply_BR_Audit__c) {
            if(this.caseSO.BR_Audit_Statement_Link__c != null && this.caseSO.BR_Audit_Statement_Link__c.startswith('http')) {
                this.rootAccountSo.BR_Audit__c= this.caseSO.BR_Audit_Statement_Link__c; 
                this.rootAccountSo.BR_Audit_Type__c= this.caseSO.BR_Audit_Type__c; 
                this.rootAccountSo.BR_Audit_Statement_Date__c= this.caseSO.BR_Audit_Statement_Date__c; 
                this.rootAccountSo.BR_Audit_Period_Start_Date__c = this.caseSO.BR_Audit_Period_Start_Date__c;
                this.rootAccountSo.BR_Audit_Period_End_Date__c = this.caseSO.BR_Audit_Period_End_Date__c;
                //sync common info
                this.rootAccountSo = copyPEMInfo(this.rootAccountSo, this.rootCaseSO); 
                this.showBRAuditConfirmation = true;
                try {
                    upsert this.rootAccountSo;
                } catch (Exception ex) {
                    this.hasError = true;
                    ApexPages.addMessages(ex);
                }
            }
        }
    }
    
    // update the case to EV SSL audits fields
    public void syncEVSSLAuditFields() {
        //ev ssl audit
        if(this.rootCaseSO.Apply_EV_Audit__c) {
            if(this.caseSO.EV_Audit_Statement_Link__c != null && this.caseSO.EV_Audit_Statement_Link__c.startswith('http')) {
                this.rootAccountSo.EV_Audit__c= this.caseSO.EV_Audit_Statement_Link__c;
                this.rootAccountSo.EV_Audit_Type__c= this.caseSO.EV_Audit_Type__c;
                this.rootAccountSo.EV_Audit_Statement_Date__c= this.caseSO.EV_Audit_Statement_Date__c;
                this.rootAccountSo.EV_Audit_Period_Start_Date__c = this.caseSO.EV_Audit_Period_Start_Date__c;
                this.rootAccountSo.EV_Audit_Period_End_Date__c = this.caseSO.EV_Audit_Period_End_Date__c;
                //sync common info
                this.rootAccountSo = copyPEMInfo(this.rootAccountSo, this.rootCaseSO);
                this.showEVSSLAuditConfirmation = true;
                try {
                    upsert this.rootAccountSo;
                } catch (Exception ex) {
                    this.hasError = true;
                    ApexPages.addMessages(ex);
                }
            }
        }
    }
    
    // update the case to EV Code Signing audits fields
    public void syncEVCodeSigningAuditFields() {
        //ev code signing audit
        if(this.rootCaseSO.Apply_EV_Code_Signing_Audit__c) {
            if(this.caseSO.EV_Code_Signing_Audit_Statement_Link__c != null && this.caseSO.EV_Code_Signing_Audit_Statement_Link__c.startswith('http')) {
                this.rootAccountSo.EV_Code_Signing_Audit__c= this.caseSO.EV_Code_Signing_Audit_Statement_Link__c; 
                this.rootAccountSo.EV_Code_Signing_Audit_Type__c= this.caseSO.EV_Code_Signing_Audit_Type__c;
                this.rootAccountSo.EV_Code_Signing_Audit_Statement_Date__c= this.caseSO.EV_Code_Signing_Audit_Statement_Date__c;
                this.rootAccountSo.EV_Code_Signing_Audit_Period_Start_Date__c = this.caseSO.EV_Code_Signing_Audit_Period_Start_Date__c;
                this.rootAccountSo.EV_Code_Signing_Audit_Period_End_Date__c = this.caseSO.EV_Code_Signing_Audit_Period_End_Date__c;
                //sync common info
                this.rootAccountSo = copyPEMInfo(this.rootAccountSo, this.rootCaseSO);
                try {
                    upsert this.rootAccountSo;
                } catch (Exception ex) {
                    this.hasError = true;
                    ApexPages.addMessages(ex);
                }
            }
        }
    }
    
    // update case to CP/CPS audit fields
    public void syncCPCPSAuditFields(){
        if(this.rootAccountSo != null && this.caseSO != null) {
            //cp/cps fields - fields moved to Poicy Doc objects
            // this.rootAccountSo.CA_Document_Repository__c = this.caseSO.CA_Document_Repository__c;
            // this.rootAccountSo.Certificate_Policy_CP__c = this.caseSO.Certificate_Policy_Link__c;
            // this.rootAccountSo.Certification_Practice_Statement_CPS__c = this.caseSO.Certification_Practice_Statement_Link__c;
            // this.rootAccountSo.CP_CPS_Last_Updated_Date__c = this.caseSO.CP_CPS_Last_Updated_Date__c;
            // this.rootAccountSo.Policy_Documentation__c= this.caseSO.Policy_Documentation__c;
            
            //sync common info
            this.rootAccountSo = copyPEMInfo(this.rootAccountSo, this.rootCaseSO);
            
            this.showCPCPSAuditConfirmation = true;
            try {
                upsert this.rootAccountSo;
            } catch (Exception ex) {
                this.hasError = true;
                ApexPages.addMessages(ex);
            }
        }
    }
    
    //sync test websites section
    public void syncTestWebsitesFields(){
        if(this.rootAccountSo != null && this.caseSO != null) {
            //sync test websites
            // copy test website only if null or url   
            if(this.rootCaseSO.Test_Website_Valid__c == null || 
                (this.rootCaseSO.Test_Website_Valid__c != null && 
                (this.rootCaseSO.Test_Website_Valid__c.startsWithIgnoreCase('https://')))) {
                this.rootAccountSo.Test_Website_Valid__c = this.rootCaseSO.Test_Website_Valid__c; 
            } 
            if(this.rootCaseSO.Test_Website_Revoked__c == null || 
                (this.rootCaseSO.Test_Website_Revoked__c != null && 
                (this.rootCaseSO.Test_Website_Revoked__c.startsWithIgnoreCase('https://')))) {
                this.rootAccountSo.Test_Website_Revoked__c = this.rootCaseSO.Test_Website_Revoked__c; 
            } 
            if(this.rootCaseSO.Test_Website_Expired__c == null || 
                (this.rootCaseSO.Test_Website_Expired__c != null && 
                (this.rootCaseSO.Test_Website_Expired__c.startsWithIgnoreCase('https://')))) {
                this.rootAccountSo.Test_Website_Expired__c = this.rootCaseSO.Test_Website_Expired__c; 
            }
            
            this.rootAccountSo = copyPEMInfo(this.rootAccountSo, this.rootCaseSO);
            this.showTestWebsitesConfirmation = true;
            try {
                upsert this.rootAccountSo;
            } catch (Exception ex) {
                this.hasError = true;
                ApexPages.addMessages(ex);
            }
        }
    }
    
    // update the all other fields
    public void syncAllOtherFields() {
        if(this.rootAccountSo != null && this.caseSO != null) {
            //mozilla section fields
            this.rootAccountSo.Approval_Bug__c = this.rootCaseSO.case_no__r.Link_to_Bugzilla_Bug__c;
            this.rootAccountSo.Trust_Bits__c= this.rootCaseSO.Trust_Bits__c; 
            this.rootAccountSo.EV_Policy_OID_s__c= this.rootCaseSO.EV_Policy_OID_s__c; 
            this.rootAccountSo.Mozilla_Applied_Constraints__c= this.rootCaseSO.Mozilla_Applied_Constraints__c; 
            this.rootAccountSo.NSS_Release_When_First_Included__c = this.rootCaseSO.NSS_Release_When_First_Included__c;
            this.rootAccountSo.Firefox_Release_When_First_Included__c = this.rootCaseSO.Firefox_Release_When_First_Included__c;
            
            //sync common info
            this.rootAccountSo = copyPEMInfo(this.rootAccountSo, this.rootCaseSO);
            
            this.showAllOtherConfirmation = true;
            try {
                upsert this.rootAccountSo;
            } catch (Exception ex) {
                this.hasError = true;
                ApexPages.addMessages(ex);
            }
        }
    }
  
    // update the root cert in account and redirect the user to the same page but this time append a flag which indicates that the 
    // record was updated. This flag will be used by the VF page to determine if the acknowledgement message needs to be displayed    
    /*public PageReference syncAccount(){
         
         this.rootAccountSo.type= 'Root';
         
         
         this.rootAccountSo.SHA_256_Fingerprint__c= this.rootCaseSO.SHA_256_Fingerprint__c;  
         
         //audit infomration
         this.rootAccountSo.Auditor_New__c= this.caseSO.Auditor_New__c;
         this.rootAccountSo.Auditor_Location_New__c= this.caseSO.Auditor_Location_New__c;
         
         this.rootAccountSo.Management_Assertions_By__c = this.caseSO.Management_Assertions_By__c;
         
         //standard audit
         if(this.rootCaseSO.Apply_Standard_Audit__c) {
             if(this.caseSO.Standard_Audit_Statement_Link__c != null && this.caseSO.Standard_Audit_Statement_Link__c.startswith('http')) {
                 this.rootAccountSo.Standard_Audit__c= this.caseSO.Standard_Audit_Statement_Link__c; 
                 this.rootAccountSo.Standard_Audit_Type__c= this.caseSO.Standard_Audit_Type__c; 
                 this.rootAccountSo.Standard_Audit_Statement_Date__c= this.caseSO.Standard_Audit_Statement_Date__c;
                 this.rootAccountSo.Standard_Audit_Period_Start_Date__c = this.caseSO.Standard_Audit_Period_Start_Date__c;
                 this.rootAccountSo.Standard_Audit_Period_End_Date__c = this.caseSO.Standard_Audit_Period_End_Date__c;
             }
         } 
         
         //code signing audit
         if(this.rootCaseSO.Apply_Code_Signing_Audit__c) {
             if(this.caseSO.Code_Signing_Audit_Statement_Link__c != null && this.caseSO.Code_Signing_Audit_Statement_Link__c.startswith('http')) {
                 this.rootAccountSo.Code_Signing_Audit__c = this.caseSO.Code_Signing_Audit_Statement_Link__c; 
                 this.rootAccountSo.Code_Signing_Audit_Type__c= this.caseSO.Code_Signing_Audit_Type__c;
                 this.rootAccountSo.Code_Signing_Audit_Statement_Date__c= this.caseSO.Code_Signing_Audit_Statement_Date__c;
                 this.rootAccountSo.Code_Signing_Audit_Period_Start_Date__c = this.caseSO.Code_Signing_Audit_Period_Start_Date__c;
                 this.rootAccountSo.Code_Signing_Audit_Period_End_Date__c = this.caseSO.Code_Signing_Audit_Period_End_Date__c;
             }
         }
         
         //br audit
         if(this.rootCaseSO.Apply_BR_Audit__c) {
             if(this.caseSO.BR_Audit_Statement_Link__c != null && this.caseSO.BR_Audit_Statement_Link__c.startswith('http')) {
                 this.rootAccountSo.BR_Audit__c= this.caseSO.BR_Audit_Statement_Link__c; 
                 this.rootAccountSo.BR_Audit_Type__c= this.caseSO.BR_Audit_Type__c; 
                 this.rootAccountSo.BR_Audit_Statement_Date__c= this.caseSO.BR_Audit_Statement_Date__c; 
                 this.rootAccountSo.BR_Audit_Period_Start_Date__c = this.caseSO.BR_Audit_Period_Start_Date__c;
                 this.rootAccountSo.BR_Audit_Period_End_Date__c = this.caseSO.BR_Audit_Period_End_Date__c;
             }
         }
         
         //ev ssl audit
         if(this.rootCaseSO.Apply_EV_Audit__c) {
             if(this.caseSO.EV_Audit_Statement_Link__c != null && this.caseSO.EV_Audit_Statement_Link__c.startswith('http')) {
                 this.rootAccountSo.EV_Audit__c= this.caseSO.EV_Audit_Statement_Link__c;
                 this.rootAccountSo.EV_Audit_Type__c= this.caseSO.EV_Audit_Type__c;
                 this.rootAccountSo.EV_Audit_Statement_Date__c= this.caseSO.EV_Audit_Statement_Date__c;
                 this.rootAccountSo.EV_Audit_Period_Start_Date__c = this.caseSO.EV_Audit_Period_Start_Date__c;
                 this.rootAccountSo.EV_Audit_Period_End_Date__c = this.caseSO.EV_Audit_Period_End_Date__c;
             }
         }
         
         //ev code signing audit
         if(this.rootCaseSO.Apply_EV_Code_Signing_Audit__c) {
             if(this.caseSO.EV_Code_Signing_Audit_Statement_Link__c != null && this.caseSO.EV_Code_Signing_Audit_Statement_Link__c.startswith('http')) {
                 this.rootAccountSo.EV_Code_Signing_Audit__c= this.caseSO.EV_Code_Signing_Audit_Statement_Link__c; 
                 this.rootAccountSo.EV_Code_Signing_Audit_Type__c= this.caseSO.EV_Code_Signing_Audit_Type__c;
                 this.rootAccountSo.EV_Code_Signing_Audit_Statement_Date__c= this.caseSO.EV_Code_Signing_Audit_Statement_Date__c;
                 this.rootAccountSo.EV_Code_Signing_Audit_Period_Start_Date__c = this.caseSO.EV_Code_Signing_Audit_Period_Start_Date__c;
                 this.rootAccountSo.EV_Code_Signing_Audit_Period_End_Date__c = this.caseSO.EV_Code_Signing_Audit_Period_End_Date__c;
             }
         }
         
         //cp/cps fields
         // this section is no longer needed since this data now resides in policy doc object and they are synced separately
         // this.rootAccountSo.CA_Document_Repository__c = this.caseSO.CA_Document_Repository__c;
         // this.rootAccountSo.Certificate_Policy_CP__c = this.caseSO.Certificate_Policy_Link__c;
         // this.rootAccountSo.Certification_Practice_Statement_CPS__c = this.caseSO.Certification_Practice_Statement_Link__c;
         // this.rootAccountSo.CP_CPS_Last_Updated_Date__c = this.caseSO.CP_CPS_Last_Updated_Date__c;
         // this.rootAccountSo.Policy_Documentation__c= this.caseSO.Policy_Documentation__c;
         
         // copy test website only if null or url   
         if(this.rootCaseSO.Test_Website_Valid__c == null || 
           (this.rootCaseSO.Test_Website_Valid__c != null && 
           (this.rootCaseSO.Test_Website_Valid__c.startsWithIgnoreCase('https://')))) {
             this.rootAccountSo.Test_Website_Valid__c = this.rootCaseSO.Test_Website_Valid__c; 
         } 
         if(this.rootCaseSO.Test_Website_Revoked__c == null || 
           (this.rootCaseSO.Test_Website_Revoked__c != null && 
           (this.rootCaseSO.Test_Website_Revoked__c.startsWithIgnoreCase('https://')))) {
             this.rootAccountSo.Test_Website_Revoked__c = this.rootCaseSO.Test_Website_Revoked__c; 
         } 
         if(this.rootCaseSO.Test_Website_Expired__c == null || 
           (this.rootCaseSO.Test_Website_Expired__c != null && 
           (this.rootCaseSO.Test_Website_Expired__c.startsWithIgnoreCase('https://')))) {
             this.rootAccountSo.Test_Website_Expired__c = this.rootCaseSO.Test_Website_Expired__c; 
         }
         
         //mozilla section fields
         this.rootAccountSo.Approval_Bug__c = this.rootCaseSO.case_no__r.Link_to_Bugzilla_Bug__c;
         this.rootAccountSo.Trust_Bits__c= this.rootCaseSO.Trust_Bits__c; 
         this.rootAccountSo.EV_Policy_OID_s__c= this.rootCaseSO.EV_Policy_OID_s__c; 
         this.rootAccountSo.Mozilla_Applied_Constraints__c= this.rootCaseSO.Mozilla_Applied_Constraints__c; 
         this.rootAccountSo.NSS_Release_When_First_Included__c = this.rootCaseSO.NSS_Release_When_First_Included__c;
         this.rootAccountSo.Firefox_Release_When_First_Included__c = this.rootCaseSO.Firefox_Release_When_First_Included__c;
         
         this.rootAccountSo.Certificate_ID__c = this.rootCaseSO.Certificate_Fingerprint__c;
         //pem information
         this.rootAccountSo.X_509_Certificate_PEM__c = this.rootCaseSO.X_509_Certificate_PEM__c;
         this.rootAccountSo.Extraction_Results__c = this.rootCaseSO.Extraction_Results__c;
         
         //last sync update info
         this.rootAccountSo.Last_Sync_Case_No__c = this.rootCaseSO.Name;
         this.rootAccountSo.Last_Sync_Date_Time__c = System.now();
         this.rootAccountSo.Status__c = 'Included'; 
         
        try{
            upsert rootAccountSo; 
            
            //update mozilla status on ca owner if status is not 'Included'
            if(rootAccountSo.ParentId != null){
                List<Account> lstCAOwner = new List<Account>([select Id,Status__c from Account Where Id =: rootAccountSo.ParentId and Status__c != 'Included']);
                if(lstCAOwner.size() > 0) {
                    Account objAcc = new Account(Id = rootAccountSo.ParentId, Status__c = 'Included');
                    update objAcc;
                }
            }
            
            //re-query and get udpated values
            rootAccountSo = [SELECT Id, Name, Parentid, Type, Certificate_Issuer_Common_Name__c, Certificate_Issuer_Organization__c, 
                                   Certificate_Issuer_Organizational_Unit__c, Approval_Bug__c, Root_Certificate_Download_URL__c, 
                                   SHA_1_Fingerprint__c, SHA_256_Fingerprint__c, Certificate_ID__c, Certificate_Version__c,
                                   Valid_from_GMT__c, Valid_to_GMT__c, Certificate_Serial_Number__c, Subject__c,
                                   Signature_Hash_Algorithm__c, Public_Key_Algorithm__c,
                                   Test_Website_Expired__c, Test_Website_Revoked__c, Test_Website_Valid__c,
                                   CRL_URL_s__c,Issuer__c,Certificate_Subject_Organization__c ,Certificate_Subject_Organization_Unit__c ,
                                   Subject_SPKI_SHA256__c,SPKI_SHA256__c,Certificate_Subject_Common_Name__c,
                                   Trust_Bits__c, EV_Policy_OID_s__c, Mozilla_Applied_Constraints__c,
                                   Standard_Audit__c, Standard_Audit_Type__c, Standard_Audit_Statement_Date__c,
                                   Standard_Audit_Period_Start_Date__c, Standard_Audit_Period_End_Date__c,
                                   Code_Signing_Audit__c, Code_Signing_Audit_Type__c, Code_Signing_Audit_Statement_Date__c, 
                                   Code_Signing_Audit_Period_Start_Date__c, Code_Signing_Audit_Period_End_Date__c,
                                   BR_Audit__c, BR_Audit_Type__c, BR_Audit_Statement_Date__c,
                                   BR_Audit_Period_Start_Date__c, BR_Audit_Period_End_Date__c,
                                   EV_Audit__c, EV_Audit_Type__c, EV_Audit_Statement_Date__c,
                                   EV_Audit_Period_Start_Date__c, EV_Audit_Period_End_Date__c, 
                                   EV_Code_Signing_Audit__c, EV_Code_Signing_Audit_Type__c,EV_Code_Signing_Audit_Statement_Date__c,
                                   EV_Code_Signing_Audit_Period_Start_Date__c,EV_Code_Signing_Audit_Period_End_Date__c,
                                   Management_Assertions_By__c,
                                   Auditor_New__c, Auditor_New__r.Name, Auditor_Location_New__c, Auditor_Location_New__r.Name,     
                                   Policy_Documentation__c, CA_Document_Repository__c, Certificate_Policy_CP__c, 
                                   Certification_Practice_Statement_CPS__c, CP_CPS_Last_Updated_Date__c,
                                   NSS_Release_When_First_Included__c, Firefox_Release_When_First_Included__c,
                                   Root_Stores_Included_In__c, X_509_Certificate_PEM__c                                   
                                   FROM Account
                                   WHERE Id = :rootAccountSo.Id
                                   AND Type = 'Root'
                                   AND Name <> '<Fill in Cert Name>'];
                               
            // Lastly, update the hidden fields and set Sync execution date/time on Root Case record
            this.rootCaseSO.CA_Owner_Name_Existing__c = rootAccountSo.parentid;  
            this.rootCaseSO.Root_Certificate_Name_Existing__c = rootAccountSo.id;
            this.rootCaseSO.Last_Sync_Date_Time__c = System.now();
        
            try { 
                update rootCaseSO;  
                  
            } catch(Exception ex) {
            
               isRecordUpdated= false;
               this.hasError = true;
               ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
               return null;
            }   
           
        } catch(Exception ex) {
           
            isRecordUpdated= false;
            this.hasError = true;
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
            return null;  
        }

        // ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM, 'Record Updated Successfully'));
        this.isRecordUpdated= true; 
        this.isUpdateCancelled = false;   
        return null;
    } */
   
   // before redirecting the user to syncContact page check if there are more root cases to be reviewed
   // if there are more root cases then present the next root case to the user
   public PageReference redirectToSyncContact(){
        PageReference rootCaseSoPageRef = new PageReference('/apex/SyncContactFromCase?id='+caseId);
        return rootCaseSoPageRef;
    }
     
   // when the user does not want to create/update root account, redirect to same page with a flag that indicates that 
   // the user cancelled the operation. this flag is used by the VF page to display the corresponding acknowledgement message.
   // also the user is redirect to the next root case
   
   public PageReference next(){
       
       this.isRecordUpdated = false;
       this.isUpdateCancelled = false;
       this.hasError = false;
       return cancelSyncAccount();
   }
   
   public PageReference cancelSyncAccount(){
        this.currentRecordCount++;
        //this.isUpdateCancelled = true;
        //this.isRecordUpdated = false;
        if(this.currentRecordCount == this.totalRootCaseCount){
            return redirectToRootCase();
        }
        getRecordsForComparison();
        return null;
    }
    
  // eventually take the user back the root case record
   public PageReference redirectToRootCase() {
         
         PageReference rootCaseSoPageRef = new PageReference('/' +this.caseSO.id);
         rootCaseSoPageRef.setRedirect(true);
         return rootCaseSoPageRef;        
    }
    
   
   public Root_Case__c getRootCase()  { return this.rootCaseSO;  }
    
   public Account getParentAccount()     { return this.rootAccountSo;  }
  
   public Integer getTotalRootCaseCount() {   return this.totalRootCaseCount;  }
   
   public Integer getCurrentRecordCount()  {   return this.currentRecordCount+1;  }

   public Boolean getRootAccountExists() { return this.rootAccountExists;  }
 
}
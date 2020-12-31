/*********************************************************************************************************************
This is the controller class for the SyncAuditUpdateOnRootFromCase VF page.
When the "Sync AuditUpdateInfo" button is clicked from any Root Certificate  
the user is redirected to  SyncAuditUpdateOnRootFromCase VF page. 

Commented on 6th May 2020 as CP/CPS documentation moved in different object

*********************************************************************************************************************/
public with sharing class SyncAuditUpdateOnRootFromCaseController{

    // object that holds all the details which are fetched using SOQL
    public Case caseDetailsSo {get; set;}
    // object to hold Root Case 
    public Root_Case__c rootCaseSO {get; set;}
    // object to hold root certificate from Account object
    public Account rootAccountSO {get; set;}  
    // object that holds all the details which are fetched using SOQL
    private List<Root_Case__c> lstRootCases;
    
    // boolean flag to check if policy docs have been synced
    public Boolean isPolicyDocSynced{get; set;}
    
    // flag that indicates whether the record was updated. 
    // the next actions that a user could perform are presented on the screen based on the value of this flag
    public Boolean isRecordUpdated{get; set;}
   
    // flag that indicates whether the user rejected to update the parent account
    // the next actions that a user could perform are presented on the screen based on the value of this flag
    public Boolean isUpdateCancelled{get; set;}
    
    // boolean flag to check whether the request status is complete or not
    // if the flag is set as true then we do not allow the user to proceed
    // with the sync process, instead we display a message to the user.
    public Boolean isRequestStatusDataVerified {get; private set;}
    
    //boolean flag added to check error
    public Boolean isErrorFound {get; private set;}
    
    //Navigation variables
    Public Integer totalRootCases {get; set;}
    Public Integer currentIndex {get; set;}
    
    //Show message when data is not verified
    public Boolean isDataVerified{get; private set;}
    
    //Show CA Owner field Sync section
    public Boolean isCWOwnerSync{get; private set;}
    
    //show CPACanada error if report url has changed.
    public boolean isCPACanadaURLDoesntMatch {get; set;}
    public string strCPACanadaURLDoesntMatch {get; set;}
    
    private Id caseId;
    
    // constructor method
    public SyncAuditUpdateOnRootFromCaseController(ApexPages.StandardController stdController){
        caseId = stdController.getId();
        isErrorFound = false;
        isCWOwnerSync = true;
        isCPACanadaURLDoesntMatch = false;
        strCPACanadaURLDoesntMatch = '';
        isPolicyDocSynced = true;
        BindRootCases();
    }
    
    //bind all root cases
    public void BindRootCases(){
        // get the record id on which the button was clicked
        this.lstRootCases = new List<Root_Case__c>();
        
        // query all the details for this record
        this.caseDetailsSo = [SELECT AccountId, CaseNumber, 
                             Standard_Audit_Statement_Link__c, Standard_Audit_Type__c, Standard_Audit_Statement_date__c, 
                             Standard_Audit_Period_Start_Date__c, Standard_Audit_Period_End_Date__c, Standard_Deviation__c,
                             Code_Signing_Audit_Statement_Link__c, Code_Signing_Audit_Type__c, Code_Signing_Audit_Statement_date__c, 
                             Code_Signing_Audit_Period_Start_Date__c, Code_Signing_Audit_Period_End_Date__c, Code_Signing_Deviation__c,
                             BR_Audit_Statement_Link__c, BR_Audit_Type__c, BR_Audit_Statement_date__c, 
                             BR_Audit_Period_Start_Date__c, BR_Audit_Period_End_Date__c, BR_Deviation__c,
                             EV_Audit_Statement_Link__c, EV_Audit_Type__c, EV_Audit_Statement_date__c, 
                             EV_Audit_Period_Start_Date__c, EV_Audit_Period_End_Date__c, EV_SSL_Deviation__c,
                             EV_Code_Signing_Audit_Statement_Link__c, EV_Code_Signing_Audit_Type__c, EV_Code_Signing_Audit_Statement_date__c, 
                             EV_Code_Signing_Audit_Period_Start_Date__c, EV_Code_Signing_Audit_Period_End_Date__c, EV_Code_Signing_Deviation__c,
                             Auditor_New__c, Auditor_New__r.Name, Auditor_Location_New__c, Auditor_Location_New__r.Name,                            
                             CA_Document_Repository__c, Policy_Documentation__c, 
                             Certificate_Policy_Link__c, Certification_Practice_Statement_Link__c, CP_CPS_Last_Updated_Date__c, 
                             Request_Status__c,Recognized_CAA_Domains__c, Account.Recognized_CAA_Domains__c,
                             Problem_Reporting_Mechanism__c, Account.Problem_Reporting_Mechanism__c,
                             Count_of_Policy_Docs_not_synced__c                                                                         
                             FROM Case WHERE Id = :caseId LIMIT 1];
                             
        // All policy docs must be synced 'Document Verified' = 'Complete' before starting sync audit info        
        if(this.caseDetailsSo.Count_of_Policy_Docs_not_synced__c > 0) {
            isPolicyDocSynced = false;
            return;
        }                       
                             
        set<string> setofAuditUrls = new set<string>();
        if(caseDetailsSo.Standard_Audit_Statement_Link__c != null && (caseDetailsSo.Standard_Audit_Statement_Link__c.startswith('https://www.cpacanada.ca') ||
            caseDetailsSo.Standard_Audit_Statement_Link__c.startswith('https://cert.webtrust.org'))){
            setofAuditUrls.add(caseDetailsSo.Standard_Audit_Statement_Link__c);
        }
        if(caseDetailsSo.Code_Signing_Audit_Statement_Link__c != null && (caseDetailsSo.Code_Signing_Audit_Statement_Link__c.startswith('https://www.cpacanada.ca') || 
            caseDetailsSo.Code_Signing_Audit_Statement_Link__c.startswith('https://cert.webtrust.org'))){
            setofAuditUrls.add(caseDetailsSo.Code_Signing_Audit_Statement_Link__c);
        }
        if(caseDetailsSo.BR_Audit_Statement_Link__c != null && (caseDetailsSo.BR_Audit_Statement_Link__c.startswith('https://www.cpacanada.ca') ||
            caseDetailsSo.BR_Audit_Statement_Link__c.startswith('https://cert.webtrust.org'))){
            setofAuditUrls.add(caseDetailsSo.BR_Audit_Statement_Link__c);
        }
        if(caseDetailsSo.EV_Audit_Statement_Link__c != null && (caseDetailsSo.EV_Audit_Statement_Link__c.startswith('https://www.cpacanada.ca') ||
            caseDetailsSo.EV_Audit_Statement_Link__c.startswith('https://cert.webtrust.org'))){
            setofAuditUrls.add(caseDetailsSo.EV_Audit_Statement_Link__c);
        }
        if(caseDetailsSo.EV_Code_Signing_Audit_Statement_Link__c != null && (caseDetailsSo.EV_Code_Signing_Audit_Statement_Link__c.startswith('https://www.cpacanada.ca') ||
            caseDetailsSo.EV_Code_Signing_Audit_Statement_Link__c.startswith('https://cert.webtrust.org'))){
            setofAuditUrls.add(caseDetailsSo.EV_Code_Signing_Audit_Statement_Link__c);
        }
        
        if(setofAuditUrls.size() > 0){
            map<string, Id> mapCPACanadaFiles = new map<string, Id>();
            for(CPACanada_File__c file: [select Id,Name,Report_URL__c from CPACanada_File__c Where Report_URL__c != null and Report_URL__c in: setofAuditUrls]){
                mapCPACanadaFiles.put(file.Report_URL__c.tolowercase(), file.Id);
            }
            if(caseDetailsSo.Standard_Audit_Statement_Link__c != null && (caseDetailsSo.Standard_Audit_Statement_Link__c.startswith('https://www.cpacanada.ca') ||
                caseDetailsSo.Standard_Audit_Statement_Link__c.startswith('https://cert.webtrust.org')) && 
                !mapCPACanadaFiles.containskey(caseDetailsSo.Standard_Audit_Statement_Link__c.tolowercase())){
                strCPACanadaURLDoesntMatch += 'Standard Audit Report URL does not match Seal ID in CPA Canada object. Re-enter the Seal ID URL, which will re-map to the new report URL.' + '<br/>';
                isCPACanadaURLDoesntMatch = true;
            }
            if(caseDetailsSo.Code_Signing_Audit_Statement_Link__c != null && (caseDetailsSo.Code_Signing_Audit_Statement_Link__c.startswith('https://www.cpacanada.ca') ||
                caseDetailsSo.Code_Signing_Audit_Statement_Link__c.startswith('https://cert.webtrust.org')) &&
                !mapCPACanadaFiles.containskey(caseDetailsSo.Code_Signing_Audit_Statement_Link__c.tolowercase())){
                isCPACanadaURLDoesntMatch = true;
                strCPACanadaURLDoesntMatch += 'Code Signing Audit Report URL does not match Seal ID in CPA Canada object. Re-enter the Seal ID URL, which will re-map to the new report URL.' + '<br/>';
            }
            if(caseDetailsSo.BR_Audit_Statement_Link__c != null && (caseDetailsSo.BR_Audit_Statement_Link__c.startswith('https://www.cpacanada.ca') ||
                caseDetailsSo.BR_Audit_Statement_Link__c.startswith('https://cert.webtrust.org')) &&
                !mapCPACanadaFiles.containskey(caseDetailsSo.BR_Audit_Statement_Link__c.tolowercase())){
                isCPACanadaURLDoesntMatch = true;
                strCPACanadaURLDoesntMatch += 'BR Audit Report URL does not match Seal ID in CPA Canada object. Re-enter the Seal ID URL, which will re-map to the new report URL.' + '<br/>';
            }
            if(caseDetailsSo.EV_Audit_Statement_Link__c != null && (caseDetailsSo.EV_Audit_Statement_Link__c.startswith('https://www.cpacanada.ca') ||
                caseDetailsSo.EV_Audit_Statement_Link__c.startswith('https://cert.webtrust.org')) &&
                !mapCPACanadaFiles.containskey(caseDetailsSo.EV_Audit_Statement_Link__c.tolowercase())){
                isCPACanadaURLDoesntMatch = true;
                strCPACanadaURLDoesntMatch += 'EV SSL Audit Report URL does not match Seal ID in CPA Canada object. Re-enter the Seal ID URL, which will re-map to the new report URL.' + '<br/>';
            }
            if(caseDetailsSo.EV_Code_Signing_Audit_Statement_Link__c != null && (caseDetailsSo.EV_Code_Signing_Audit_Statement_Link__c.startswith('https://www.cpacanada.ca') ||
                caseDetailsSo.EV_Code_Signing_Audit_Statement_Link__c.startswith('https://cert.webtrust.org')) &&
                !mapCPACanadaFiles.containskey(caseDetailsSo.EV_Code_Signing_Audit_Statement_Link__c.tolowercase())){
                isCPACanadaURLDoesntMatch = true;
                strCPACanadaURLDoesntMatch += 'EV Code Signing Audit Report URL does not match Seal ID in CPA Canada object. Re-enter the Seal ID URL, which will re-map to the new report URL.' + '<br/>';
            }
        } 
                             
        // deprecated fields Auditor__c, Auditor_Website__c, Auditor_Qualifications__c, 
        
        //check if CAA Domains or Reporting Mech is doesn't match with CA Owner
        if((string.isBlank(caseDetailsSo.Recognized_CAA_Domains__c) && caseDetailsSo.Problem_Reporting_Mechanism__c == caseDetailsSo.Account.Problem_Reporting_Mechanism__c) ||
            (string.isBlank(caseDetailsSo.Problem_Reporting_Mechanism__c) && caseDetailsSo.Recognized_CAA_Domains__c == caseDetailsSo.Account.Recognized_CAA_Domains__c) ||     
            (caseDetailsSo.Recognized_CAA_Domains__c == caseDetailsSo.Account.Recognized_CAA_Domains__c && caseDetailsSo.Problem_Reporting_Mechanism__c == caseDetailsSo.Account.Problem_Reporting_Mechanism__c) ||
            (string.isBlank(caseDetailsSo.Recognized_CAA_Domains__c) && string.isBlank(caseDetailsSo.Problem_Reporting_Mechanism__c))){
            isCWOwnerSync = false;
        }
        
        //Auditor (New) fields must be filled before starting mass update process 
            
        if(string.isBlank(this.caseDetailsSo.Auditor_New__c) || string.isBlank(this.caseDetailsSo.Auditor_Location_New__c)){
            isRequestStatusDataVerified = false;
            return;
            //isErrorFound = true;
            //display message 'Fill in Auditor and Auditor Location fields before proceeding with sync process.';
        }  
                  
        this.isRequestStatusDataVerified = this.caseDetailsSo.Request_Status__c == 'Data Verified' || this.caseDetailsSo.Request_Status__c == 'Verification by Root Store' || this.caseDetailsSo.Request_Status__c == 'Complete'  ? true : false;
        this.isUpdateCancelled = false;
        this.isRecordUpdated = false;
        
        this.lstRootCases =  [SELECT Name, case_no__c, case_no__r.accountid, case_no__r.Account.Name,
                              CA_Owner_Name_Existing__r.Name, Root_Certificate_Name_Existing__r.Name,
                              SHA_256_Fingerprint__c,
                              Test_Website_Valid__c, Test_Website_Expired__c, Test_Website_Revoked__c, Request_Status__c,
                              Apply_Standard_Audit__c, Apply_Code_Signing_Audit__c, Apply_BR_Audit__c, Apply_EV_Audit__c, Apply_EV_Code_Signing_Audit__c,
                              Root_Certificate_Name_Existing__c,
                              Root_Certificate_Name_Existing__r.SHA_256_Fingerprint__c, 
                              Root_Certificate_Name_Existing__r.Auditor_New__c, 
                              Root_Certificate_Name_Existing__r.Auditor_New__r.Name, 
                              Root_Certificate_Name_Existing__r.Auditor_Location_New__c,
                              Root_Certificate_Name_Existing__r.Auditor_Location_New__r.Name,
                              Root_Certificate_Name_Existing__r.Policy_Documentation__c,
                              Root_Certificate_Name_Existing__r.CA_Document_Repository__c,
                              Root_Certificate_Name_Existing__r.Certificate_Policy_CP__c,
                              Root_Certificate_Name_Existing__r.Certification_Practice_Statement_CPS__c,
                              Root_Certificate_Name_Existing__r.CP_CPS_Last_Updated_Date__c,
                              Root_Certificate_Name_Existing__r.Test_Website_Valid__c,
                              Root_Certificate_Name_Existing__r.Test_Website_Expired__c,
                              Root_Certificate_Name_Existing__r.Test_Website_Revoked__c,
                              Root_Certificate_Name_Existing__r.Standard_Audit__c,
                              Root_Certificate_Name_Existing__r.Standard_Audit_Type__c,
                              Root_Certificate_Name_Existing__r.Standard_Audit_Statement_Date__c,
                              Root_Certificate_Name_Existing__r.Standard_Audit_Period_Start_Date__c,
                              Root_Certificate_Name_Existing__r.Standard_Audit_Period_End_Date__c,
                              Root_Certificate_Name_Existing__r.Standard_Deviation__c,
                              Root_Certificate_Name_Existing__r.Code_Signing_Audit__c,
                              Root_Certificate_Name_Existing__r.Code_Signing_Audit_Type__c,
                              Root_Certificate_Name_Existing__r.Code_Signing_Audit_Statement_Date__c,
                              Root_Certificate_Name_Existing__r.Code_Signing_Audit_Period_Start_Date__c,
                              Root_Certificate_Name_Existing__r.Code_Signing_Audit_Period_End_Date__c,
                              Root_Certificate_Name_Existing__r.Code_Signing_Deviation__c,
                              Root_Certificate_Name_Existing__r.BR_Audit__c,
                              Root_Certificate_Name_Existing__r.BR_Audit_Type__c,
                              Root_Certificate_Name_Existing__r.BR_Audit_Statement_Date__c,
                              Root_Certificate_Name_Existing__r.BR_Audit_Period_Start_Date__c,
                              Root_Certificate_Name_Existing__r.BR_Audit_Period_End_Date__c,
                              Root_Certificate_Name_Existing__r.BR_Deviation__c,
                              Root_Certificate_Name_Existing__r.EV_Audit__c,
                              Root_Certificate_Name_Existing__r.EV_Audit_Type__c,
                              Root_Certificate_Name_Existing__r.EV_Audit_Statement_Date__c,
                              Root_Certificate_Name_Existing__r.EV_Audit_Period_Start_Date__c,
                              Root_Certificate_Name_Existing__r.EV_Audit_Period_End_Date__c, 
                              Root_Certificate_Name_Existing__r.EV_SSL_Deviation__c,                           
                              Root_Certificate_Name_Existing__r.EV_Code_Signing_Audit__c,
                              Root_Certificate_Name_Existing__r.EV_Code_Signing_Audit_Type__c,
                              Root_Certificate_Name_Existing__r.EV_Code_Signing_Audit_Statement_Date__c,
                              Root_Certificate_Name_Existing__r.EV_Code_Signing_Audit_Period_Start_Date__c,
                              Root_Certificate_Name_Existing__r.EV_Code_Signing_Audit_Period_End_Date__c,
                              Root_Certificate_Name_Existing__r.EV_Code_Signing_Deviation__c  
                              FROM Root_Case__c 
                              WHERE Case_No__c = :this.caseDetailsSo.Id AND Request_Status__c <> 'Complete'
                              ORDER BY NAME];
                              
                              // fields deprecated
                              // Root_Certificate_Name_Existing__r.Auditor__c,
                              // Root_Certificate_Name_Existing__r.Auditor_Website__c,
                              // Root_Certificate_Name_Existing__r.Auditor_Qualifications__c,
        
        this.totalRootCases =  this.lstRootCases.size();
        if(!isErrorFound) {
            this.currentIndex = 0;
        }
        // System.debug('this.lstRootCases.size(): '+this.lstRootCases.size());          
        if(this.lstRootCases.size() > 0){
            // System.debug('this.lstRootCases.size(): '+this.lstRootCases.size());
            this.rootCaseSO = this.lstRootCases[this.currentIndex];
            this.isDataVerified = this.rootCaseSO.Request_Status__c == 'Data Verified' ? true : false;
            this.rootAccountSO = (Account)this.rootCaseSO.getSObject('Root_Certificate_Name_Existing__r'); 
        }
    }
   
   Public Boolean getIsMoreRootCasesAvailable(){
       //System.debug('IsMoreRootCasesAvailable: '+this.currentIndex);
       return this.currentIndex < this.totalRootCases;
       
   }
   
   //Sync CA Owner Fields
   public void SyncCAOwner(){
       try {
           isErrorFound = false;
           Account objCAOwner = new Account();
           objCAOwner.Id = caseDetailsSo.AccountId;
           if(string.isnotBlank(caseDetailsSo.Recognized_CAA_Domains__c)) {
               objCAOwner.Recognized_CAA_Domains__c = caseDetailsSo.Recognized_CAA_Domains__c;
           }
           if(string.isnotBlank(caseDetailsSo.Problem_Reporting_Mechanism__c)) {
               objCAOwner.Problem_Reporting_Mechanism__c = caseDetailsSo.Problem_Reporting_Mechanism__c;
           }
           this.isRecordUpdated = true;
           update objCAOwner;
           //requery
           this.caseDetailsSo = [SELECT AccountId, CaseNumber, 
                             Standard_Audit_Statement_Link__c, Standard_Audit_Type__c, Standard_Audit_Statement_date__c, 
                             Standard_Audit_Period_Start_Date__c, Standard_Audit_Period_End_Date__c, Standard_Deviation__c,
                             Code_Signing_Audit_Statement_Link__c, Code_Signing_Audit_Type__c, Code_Signing_Audit_Statement_date__c, 
                             Code_Signing_Audit_Period_Start_Date__c, Code_Signing_Audit_Period_End_Date__c, Code_Signing_Deviation__c,
                             BR_Audit_Statement_Link__c, BR_Audit_Type__c, BR_Audit_Statement_date__c, 
                             BR_Audit_Period_Start_Date__c, BR_Audit_Period_End_Date__c, BR_Deviation__c,
                             EV_Audit_Statement_Link__c, EV_Audit_Type__c, EV_Audit_Statement_date__c, 
                             EV_Audit_Period_Start_Date__c, EV_Audit_Period_End_Date__c, EV_SSL_Deviation__c,
                             EV_Code_Signing_Audit_Statement_Link__c, EV_Code_Signing_Audit_Type__c, EV_Code_Signing_Audit_Statement_date__c, 
                             EV_Code_Signing_Audit_Period_Start_Date__c, EV_Code_Signing_Audit_Period_End_Date__c, EV_Code_Signing_Deviation__c,
                             Auditor_New__c, Auditor_New__r.Name, Auditor_Location_New__c, Auditor_Location_New__r.Name,                              
                             CA_Document_Repository__c, Policy_Documentation__c, 
                             Certificate_Policy_Link__c, Certification_Practice_Statement_Link__c, CP_CPS_Last_Updated_Date__c, 
                             Request_Status__c,Recognized_CAA_Domains__c, Account.Recognized_CAA_Domains__c,
                             Problem_Reporting_Mechanism__c, Account.Problem_Reporting_Mechanism__c                                                                          
                             FROM Case WHERE Id = :caseId LIMIT 1];
                             
                             // deprecated fields - Auditor__c, Auditor_Website__c, Auditor_Qualifications__c,
       } catch(Exception ex) {
           isErrorFound = true;
       }
       //isCWOwnerSync = false;
   }
   
   public void nexttoRootCase(){
       this.isRecordUpdated = false;
       isCWOwnerSync = false;
   }
   
   public void cancelSyncCAOwner(){
       isCWOwnerSync = false;
   }
   
   Public PageReference next(){
       
       this.currentIndex++;
       isErrorFound = false;
       if(getIsMoreRootCasesAvailable()){
           this.rootCaseSO = this.lstRootCases[this.currentIndex];
           this.isDataVerified = this.rootCaseSO.Request_Status__c == 'Data Verified' ? true : false;
           this.rootAccountSO = (Account)this.rootCaseSO.getSObject('Root_Certificate_Name_Existing__r');
           this.isUpdateCancelled = false;
           this.isRecordUpdated = false;
       }else{
           this.isDataVerified = false;
       }
       
       return null;
   }
    // when the user hits cancel redirect to the same page with the status in URL so that an acknowledgement message is shown to the user.
   public PageReference cancelSyncAccount() {
         this.isUpdateCancelled = true;
         //this.currentIndex++;
         return null;        
         
    }
    
   Public PageReference goBack(){
       
       return new PageReference('/'+this.caseDetailsSo.Id);
   }
  
  // update the root certificate on account object and redirect the user to the same page but this time append a flag which indicates that the 
  // record was updated. This flag will be used by the VF page to determine if the acknoledgement message needs to be displayed    

   public PageReference syncAccount()
   {
         Savepoint sp = Database.setSavepoint();
         isErrorFound = false;
         //if "Apply Standard Audit" for Root Case is true then update following standard audit fields 
         if (this.rootCaseSO.Apply_Standard_Audit__c) {
             this.rootAccountSo.Standard_Audit__c = this.caseDetailsSo.Standard_Audit_Statement_Link__c; 
             this.rootAccountSo.Standard_Audit_Type__c = this.caseDetailsSo.Standard_Audit_Type__c; 
             this.rootAccountSo.Standard_Audit_Statement_Date__c = this.CaseDetailsSo.Standard_Audit_Statement_Date__c; 
             this.rootAccountSo.Standard_Audit_Period_Start_Date__c = this.CaseDetailsSo.Standard_Audit_Period_Start_Date__c; 
             this.rootAccountSo.Standard_Audit_Period_End_Date__c = this.CaseDetailsSo.Standard_Audit_Period_End_Date__c; 
             this.rootAccountSo.Standard_Deviation__c = this.CaseDetailsSo.Standard_Deviation__c;
         }
         
         //if "Apply Code Signing Audit" for Root Case is true then update following code signing audit fields 
         if (this.rootCaseSO.Apply_Code_Signing_Audit__c) {
             this.rootAccountSo.Code_Signing_Audit__c = this.caseDetailsSo.Code_Signing_Audit_Statement_Link__c; 
             this.rootAccountSo.Code_Signing_Audit_Type__c = this.caseDetailsSo.Code_Signing_Audit_Type__c; 
             this.rootAccountSo.Code_Signing_Audit_Statement_Date__c = this.CaseDetailsSo.Code_Signing_Audit_Statement_Date__c; 
             this.rootAccountSo.Code_Signing_Audit_Period_Start_Date__c = this.CaseDetailsSo.Code_Signing_Audit_Period_Start_Date__c; 
             this.rootAccountSo.Code_Signing_Audit_Period_End_Date__c = this.CaseDetailsSo.Code_Signing_Audit_Period_End_Date__c; 
             this.rootAccountSo.Code_Signing_Deviation__c = this.CaseDetailsSo.Code_Signing_Deviation__c;
         }
         
         // if "Apply BR Audit" for Root Case is true then update following BR audit fields
         if (this.rootCaseSO.Apply_BR_Audit__c) {
             this.rootAccountSo.BR_Audit__c = this.caseDetailsSo.BR_Audit_Statement_Link__c; 
             this.rootAccountSo.BR_Audit_Type__c = this.caseDetailsSo.BR_Audit_Type__c; 
             this.rootAccountSo.BR_Audit_Statement_Date__c = this.CaseDetailsSo.BR_Audit_Statement_Date__c; 
             this.rootAccountSo.BR_Audit_Period_Start_Date__c = this.CaseDetailsSo.BR_Audit_Period_Start_Date__c; 
             this.rootAccountSo.BR_Audit_Period_End_Date__c = this.CaseDetailsSo.BR_Audit_Period_End_Date__c; 
             this.rootAccountSo.BR_Deviation__c = this.CaseDetailsSo.BR_Deviation__c;
         }
         
         // if "Apply EV Audit" for Root Case is true then update following EV audit fields 
         if (this.rootCaseSO.Apply_EV_Audit__c) {  // EV SSL fields
             this.rootAccountSo.EV_Audit__c = this.caseDetailsSo.EV_Audit_Statement_Link__c; 
             this.rootAccountSo.EV_Audit_Type__c = this.caseDetailsSo.EV_Audit_Type__c; 
             this.rootAccountSo.EV_Audit_Statement_Date__c = this.CaseDetailsSo.EV_Audit_Statement_Date__c; 
             this.rootAccountSo.EV_Audit_Period_Start_Date__c = this.CaseDetailsSo.EV_Audit_Period_Start_Date__c; 
             this.rootAccountSo.EV_Audit_Period_End_Date__c = this.CaseDetailsSo.EV_Audit_Period_End_Date__c; 
             this.rootAccountSo.EV_SSL_Deviation__c = this.CaseDetailsSo.EV_SSL_Deviation__c;
         
         }
         
        // if "Apply EV Code Signing Audit" for Root Case is true then update following EV audit fields 
         if (this.rootCaseSO.Apply_EV_Code_Signing_Audit__c) {        
             this.rootAccountSo.EV_Code_Signing_Audit__c = this.caseDetailsSo.EV_Code_Signing_Audit_Statement_Link__c; 
             this.rootAccountSo.EV_Code_Signing_Audit_Type__c = this.caseDetailsSo.EV_Code_Signing_Audit_Type__c; 
             this.rootAccountSo.EV_Code_Signing_Audit_Statement_Date__c = this.CaseDetailsSo.EV_Code_Signing_Audit_Statement_Date__c; 
             this.rootAccountSo.EV_Code_Signing_Audit_Period_Start_Date__c = this.CaseDetailsSo.EV_Code_Signing_Audit_Period_Start_Date__c; 
             this.rootAccountSo.EV_Code_Signing_Audit_Period_End_Date__c = this.CaseDetailsSo.EV_Code_Signing_Audit_Period_End_Date__c;             
             this.rootAccountSo.EV_Code_Signing_Deviation__c = this.CaseDetailsSo.EV_Code_Signing_Deviation__c;
         }
         
                         
         // update auditor fields
         this.rootAccountSo.Auditor_New__c = this.caseDetailsSo.Auditor_New__c;
         this.rootAccountSo.Auditor_Location_New__c = this.caseDetailsSo.Auditor_Location_New__c;
         // this.rootAccountSo.Auditor__c = this.caseDetailsSo.Auditor__c;
         // this.rootAccountSo.Auditor_Website__c = this.caseDetailsSo.Auditor_Website__c;
         // this.rootAccountSo.Auditor_Qualifications__c = this.caseDetailsSo.Auditor_Qualifications__c;
         //this.rootAccountSo.Management_Assertions_By__c = this.caseDetailsSo.Management_Assertions_By__c;
         
         // update cp/cps fields
         //Commented on 6th May 2020 as CP/CPS documentation moved in different object
         /*this.rootAccountSo.CA_Document_Repository__c = this.caseDetailsSo.CA_Document_Repository__c;
         this.rootAccountSo.Policy_Documentation__c = this.caseDetailsSo.Policy_Documentation__c;         
         this.rootAccountSo.Certificate_Policy_CP__c = this.caseDetailsSo.Certificate_Policy_Link__c;
         this.rootAccountSo.Certification_Practice_Statement_CPS__c = this.caseDetailsSo.Certification_Practice_Statement_Link__c;
         this.rootAccountSo.CP_CPS_Last_Updated_Date__c = this.caseDetailsSo.CP_CPS_Last_Updated_Date__c;  */      
    
         // copy test website only if null or url   
         if(this.rootCaseSo.Test_Website_Valid__c == null || 
           (this.rootCaseSo.Test_Website_Valid__c != null && 
           (this.rootCaseSo.Test_Website_Valid__c.startsWithIgnoreCase('https://')))) {           
               this.rootAccountSo.Test_Website_Valid__c = this.rootCaseSo.Test_Website_Valid__c; 
         }
         if(this.rootCaseSo.Test_Website_Expired__c == null || 
           (this.rootCaseSo.Test_Website_Expired__c != null && 
           (this.rootCaseSo.Test_Website_Expired__c.startsWithIgnoreCase('https://')))) {      
               this.rootAccountSo.Test_Website_Expired__c = this.rootCaseSo.Test_Website_Expired__c; 
         }
         if(this.rootCaseSo.Test_Website_Revoked__c == null || 
           (this.rootCaseSo.Test_Website_Revoked__c != null && 
           (this.rootCaseSo.Test_Website_Revoked__c.startsWithIgnoreCase('https://')))) {      
              this.rootAccountSo.Test_Website_Revoked__c = this.rootCaseSo.Test_Website_Revoked__c; 
         } 

         // leave the time stamp on the source and target records
         this.rootAccountSo.Last_Sync_Case_No__c = this.caseDetailsSO.CaseNumber;
         this.rootAccountSo.Last_Sync_Date_Time__c = System.now();
         
         
         try{
             update rootAccountSo;
             this.rootAccountSo = [select Id, ParentId, Name, Friendly_Name__c, Type,
                                    SHA_256_Fingerprint__c, SHA_256__c,
                                    Trust_bits__c, Microsoft_Trust_Bits__c,
                                    Revocation_Status__c, Date_of_Revocation__c, RFC_5280_Revocation_Reason_Code__c,
                                    Audits_Same_as_Parent__c, Standard_Audit__c, 
                                    Standard_Audit_Type__c, Standard_Audit_Statement_Date__c, 
                                    Standard_Audit_Period_Start_Date__c, Standard_Audit_Period_End_Date__c, Standard_Deviation__c,
                                    Code_Signing_Audit__c, Code_Signing_Audit_Type__c, Code_Signing_Audit_Statement_Date__c, 
                                    Code_Signing_Audit_Period_Start_Date__c, Code_Signing_Audit_Period_End_Date__c, Code_Signing_Deviation__c,
                                    BR_Audit__c, BR_Audit_Type__c, BR_Audit_Statement_Date__c, 
                                    BR_Audit_Period_Start_Date__c, BR_Audit_Period_End_Date__c, BR_Deviation__c,
                                    EV_Audit__c, EV_Audit_Type__c, EV_Audit_Statement_Date__c, 
                                    EV_Audit_Period_Start_Date__c, EV_Audit_Period_End_Date__c, EV_SSL_Deviation__c,
                                    EV_Code_Signing_Audit__c, EV_Code_Signing_Audit_Type__c, EV_Code_Signing_Audit_Statement_Date__c,
                                    EV_Code_Signing_Audit_Period_Start_Date__c, EV_Code_Signing_Audit_Period_End_Date__c, EV_Code_Signing_Deviation__c,
                                    Auditor_New__c, Auditor_New__r.Name, Auditor_Location_New__c, Auditor_Location_New__r.Name,                            
                                    CP_CPS_Same_as_Parent__c, Policy_Documentation__c, CA_Document_Repository__c,                                   
                                    Certificate_Policy_CP__c, Certification_Practice_Statement_CPS__c, CP_CPS_Last_Updated_Date__c,                               
                                    Mozilla_Verified_Audit_Date__c, Microsoft_Verified_Audit_Date__c,
                                    EV_Policy_OID_s__c, Microsoft_EV_Enabled__c,Test_Website_Valid__c,
                                    Do_NOT_Send_Audit_Reminder__c, Microsoft_Do_NOT_Send_Audit_Reminder__c,
                                    Status__c, Microsoft_Status__c , Removal_Bug_No_or_Date__c,Test_Website_Expired__c,Test_Website_Revoked__c
                                    from Account
                                    where Id =: rootAccountSo.Id];
                                    
                                    // deprecated fields - Auditor__c, Auditor_Website__c, Auditor_Qualifications__c,
            
             isRecordUpdated= true;
            
            
            // Lastly, set Request Status & Sync execution date/time on Root Case record
            this.rootCaseSo.Last_Sync_Date_Time__c = System.now();
            this.rootCaseSo.Request_Status__c ='Complete' ; 
            update rootCaseSo;          
         }
         /*Changed by Sunil on 30 Jan 2017 - Changeed DMLException to Exception*/
         catch(Exception exp){
             isErrorFound = true;
             Database.rollback(sp);
             BindRootCases();
             ApexPages.addMessages(exp);
         }
          
         return null;
    }    
  
    
}
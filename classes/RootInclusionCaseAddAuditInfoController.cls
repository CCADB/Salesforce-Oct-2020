/*******************************************************************************************************
 Name: RootInclusionCaseAddAuditInfoController

 Dependencies: RootInclusionCaseAddAuditInfoController controller class, RootInclusionCaseAddAuditInfo 
 vf page, RootInclusionCaseAddAuditInfoCtrlTest class

 Description: This class is created for Cases with record type "CA Root Inclusion".
 When "Copy Audit Info" button is clicked from case page, a list of related root certs are displayed,
 users can chose a root cert and copy Auditor, Audit Info and CP/CPS to Case.
 
 Instructions: None   
 *******************************************************************************************************
 Revision History:
 
     10/15/2018    Created new class
     6/13/2019     Updated program to reate cseparate sections for auditor, audit, cp/cps fields and 
                   allow users to copy individual sections
     4/27/2020     Updated code to show error message if update fail
 ******************************************************************************************************/
 
public with sharing class RootInclusionCaseAddAuditInfoController {
    Id caseOwnerId;
    public Case objCase {get; set;}
    public boolean isCaseCompleted {get; set;}
    public boolean isRecordMoreThan1000 {get; set;}
    
    public List<WrapperRootCerts> lstWrapAllRootCerts {get; set;}
    public Account objSelectedRootCerts {get; set;}
    
    public boolean isShowSelectedRootCert {get; set;}
    
    public Boolean showAuditorNewConfirmation{get;set;}
    public Boolean showStandardAuditConfirmation{get;set;}
    public Boolean showCodeSigningAuditConfirmation{get;set;}
    public Boolean showBRAuditConfirmation{get;set;}
    public Boolean showEVSSLAuditConfirmation{get;set;}
    public Boolean showEVCodeSigningAuditConfirmation{get;set;}
    public Boolean showCPCPSAuditConfirmation{get;set;}
    
    public RootInclusionCaseAddAuditInfoController(Apexpages.standardcontroller controller) {
        caseOwnerId = controller.getId();
        isCaseCompleted = false;
        isRecordMoreThan1000 = false;
        isShowSelectedRootCert = false;
        lstWrapAllRootCerts = new List<WrapperRootCerts>();
        List<Case> lstCases = new List<Case>([select Id,AccountId,CaseNumber,Account.Name,
            Request_Status__c,Auditor_New__c,Auditor_New__r.Name,Auditor_Location_New__c,
            Auditor_Location_New__r.Name, Standard_Audit_Statement_Link__c,Standard_Audit_Type__c,
            Standard_Audit_Statement_Date__c,Standard_Audit_Period_Start_Date__c,Standard_Audit_Period_End_Date__c,
            Code_Signing_Audit_Statement_Link__c, Code_Signing_Audit_Type__c,Code_Signing_Audit_Period_Start_Date__c,
            Code_Signing_Audit_Period_End_Date__c, Code_Signing_Audit_Statement_Date__c,BR_Audit_Statement_Link__c,BR_Audit_Statement_Date__c,
            BR_Audit_Type__c,BR_Audit_Period_Start_Date__c,BR_Audit_Period_End_Date__c,EV_Audit_Statement_Link__c ,EV_Audit_Statement_Date__c,
            EV_Audit_Type__c,EV_Audit_Period_Start_Date__c,EV_Audit_Period_End_Date__c,EV_Code_Signing_Audit_Statement_Link__c ,
            EV_Code_Signing_Audit_Statement_Date__c,EV_Code_Signing_Audit_Type__c,EV_Code_Signing_Audit_Period_Start_Date__c,
            EV_Code_Signing_Audit_Period_End_Date__c,Policy_Documentation__c,Certificate_Policy_Link__c,CA_Document_Repository__c,
            Certification_Practice_Statement_Link__c,CP_CPS_Last_Updated_Date__c
            from Case Where Id =: caseOwnerId]);
        
        
        this.showAuditorNewConfirmation = false;
        this.showStandardAuditConfirmation = false;
        this.showCodeSigningAuditConfirmation = false;
        this.showBRAuditConfirmation = false;
        this.showEVSSLAuditConfirmation = false;
        this.showEVCodeSigningAuditConfirmation = false;
        this.showCPCPSAuditConfirmation = false;
        
        if(lstCases.size() > 0) {
            objCase = lstCases[0];
            if(objCase.Request_Status__c == 'Complete') {
                isCaseCompleted = true;
            }
            Integer count = 0;
            //loop on all root certificates. 
            for(Account objAccount: [select Id, Name, Status__c, Microsoft_Status__c, SHA_256_Fingerprint__c,Valid_From_GMT__c,Valid_To_GMT__c,
                                Auditor_New__c,Auditor_New__r.Name,Auditor_Location_New__c,Auditor_Location_New__r.Name,
                                Standard_Audit__c,Standard_Audit_Statement_Date__c,Standard_Audit_Type__c,
                                Standard_Audit_Period_Start_Date__c,Standard_Audit_Period_End_Date__c,Code_Signing_Audit__c,
                                Code_Signing_Audit_Type__c,Code_Signing_Audit_Period_Start_Date__c,Code_Signing_Audit_Period_End_Date__c,
                                Code_Signing_Audit_Statement_Date__c,BR_Audit__c,BR_Audit_Statement_Date__c,
                                BR_Audit_Type__c,BR_Audit_Period_Start_Date__c,BR_Audit_Period_End_Date__c,EV_Audit__c ,EV_Audit_Statement_Date__c,
                                EV_Audit_Type__c,EV_Audit_Period_Start_Date__c,EV_Audit_Period_End_Date__c,EV_Code_Signing_Audit__c,
                                EV_Code_Signing_Audit_Statement_Date__c,EV_Code_Signing_Audit_Type__c,EV_Code_Signing_Audit_Period_Start_Date__c,
                                EV_Code_Signing_Audit_Period_End_Date__c,Policy_Documentation__c,Certificate_Policy_CP__c,CA_Document_Repository__c,
                                Certification_Practice_Statement_CPS__c,CP_CPS_Last_Updated_Date__c,Auditor_Website_New__c,Auditor_Qualifications_New__c
                                from Account Where RecordType.Name = 'Root Certificate' 
                                and Name != '<Fill in Cert Name>'
                                and ParentId =: objCase.AccountId Order By Name Limit 1000]){
                lstWrapAllRootCerts.add(new WrapperRootCerts(false,objAccount));
                count++;
            }
            if(count == 1000){
                isRecordMoreThan1000 = true;
            }
        }
    }
    
    public void RefreshCaseDetails(){
        List<Case> lstCases = new List<Case>([select Id,AccountId,CaseNumber,Account.Name,
            Request_Status__c,Auditor_New__c,Auditor_New__r.Name,Auditor_Location_New__c,
            Auditor_Location_New__r.Name, Standard_Audit_Statement_Link__c,Standard_Audit_Type__c,
            Standard_Audit_Statement_Date__c,Standard_Audit_Period_Start_Date__c,Standard_Audit_Period_End_Date__c,
            Code_Signing_Audit_Statement_Link__c, Code_Signing_Audit_Type__c,Code_Signing_Audit_Period_Start_Date__c,
            Code_Signing_Audit_Period_End_Date__c, Code_Signing_Audit_Statement_Date__c,BR_Audit_Statement_Link__c,BR_Audit_Statement_Date__c,
            BR_Audit_Type__c,BR_Audit_Period_Start_Date__c,BR_Audit_Period_End_Date__c,EV_Audit_Statement_Link__c ,EV_Audit_Statement_Date__c,
            EV_Audit_Type__c,EV_Audit_Period_Start_Date__c,EV_Audit_Period_End_Date__c,EV_Code_Signing_Audit_Statement_Link__c ,
            EV_Code_Signing_Audit_Statement_Date__c,EV_Code_Signing_Audit_Type__c,EV_Code_Signing_Audit_Period_Start_Date__c,
            EV_Code_Signing_Audit_Period_End_Date__c,Policy_Documentation__c,Certificate_Policy_Link__c,CA_Document_Repository__c,
            Certification_Practice_Statement_Link__c,CP_CPS_Last_Updated_Date__c
            from Case Where Id =: objCase.Id]);
        if(lstCases.size() > 0){
            objCase = lstCases[0];
        }
    }
    
    public void SelectDifferentRootCerts(){
        isShowSelectedRootCert = false;
    }
    
    //method is used to update case based on selected root certificates
    public void ViewAuditDetails(){
        objSelectedRootCerts = new Account();
        Integer count = 0;
        
        for(WrapperRootCerts objWrap: lstWrapAllRootCerts){
            if(objWrap.isSelected){
                objSelectedRootCerts = objWrap.objAccount;
                count++;
            }
        }
        if(count == 0) {
            ApexPages.AddMessage( new ApexPages.Message( ApexPages.Severity.Error, 'Choose the root certificate whose Audit/CP/CPS information you wish to copy.'));
            return;
        } else if(count > 1) {
            ApexPages.AddMessage( new ApexPages.Message( ApexPages.Severity.Error, 'Please select only one root certificate to copy Information to case.'));
            return;
        }
        isShowSelectedRootCert = true;
    }
    
    // update the case to auditor information
    public void syncAuditorNewFields() {
        if(objSelectedRootCerts != null && objSelectedRootCerts.Id != null) {
            objCase.Auditor_New__c = objSelectedRootCerts.Auditor_New__c;
            objCase.Auditor_Location_New__c = objSelectedRootCerts.Auditor_Location_New__c;
            try {
                update objCase;
                this.showAuditorNewConfirmation = true;
            } catch (Exception ex) {
                //this.hasError = true;
                ApexPages.getMessages().clear();
                ApexPages.addMessages(ex);
            }
        }
        RefreshCaseDetails();
    }
    
    // update the case to standard audit fields
    public void syncStandardAuditFields() {
        if(objSelectedRootCerts != null && objSelectedRootCerts.Id != null) {
            objCase.Standard_Audit_Statement_Link__c = objSelectedRootCerts.Standard_Audit__c;
            objCase.Standard_Audit_Statement_Date__c = objSelectedRootCerts.Standard_Audit_Statement_Date__c;
            objCase.Standard_Audit_Type__c = objSelectedRootCerts.Standard_Audit_Type__c;
            objCase.Standard_Audit_Period_Start_Date__c = objSelectedRootCerts.Standard_Audit_Period_Start_Date__c;
            objCase.Standard_Audit_Period_End_Date__c = objSelectedRootCerts.Standard_Audit_Period_End_Date__c;
            
            try {
                update objCase;
                this.showStandardAuditConfirmation = true;
            } catch (Exception ex) {
                //this.hasError = true;
                ApexPages.getMessages().clear();
                ApexPages.addMessages(ex);
            }
            RefreshCaseDetails();
        }
    }
    
    // update the case to code signing audit fields
    public void syncCodeSigningAuditFields() {
        if(objSelectedRootCerts != null && objSelectedRootCerts.Id != null) {
            objCase.Code_Signing_Audit_Statement_Link__c = objSelectedRootCerts.Code_Signing_Audit__c;
            objCase.Code_Signing_Audit_Statement_Date__c = objSelectedRootCerts.Code_Signing_Audit_Statement_Date__c;
            objCase.Code_Signing_Audit_Type__c = objSelectedRootCerts.Code_Signing_Audit_Type__c;
            objCase.Code_Signing_Audit_Period_Start_Date__c = objSelectedRootCerts.Code_Signing_Audit_Period_Start_Date__c;
            objCase.Code_Signing_Audit_Period_End_Date__c = objSelectedRootCerts.Code_Signing_Audit_Period_End_Date__c;
            
            try {
                update objCase;
                this.showCodeSigningAuditConfirmation = true;
            } catch (Exception ex) {
                //this.hasError = true;
                ApexPages.getMessages().clear();
                ApexPages.addMessages(ex);
            }
            RefreshCaseDetails();
        }
    }
    
    // update the case to BR audit fields
    public void syncBRAuditFields() {
        if(objSelectedRootCerts != null && objSelectedRootCerts.Id != null) {
            objCase.BR_Audit_Statement_Link__c = objSelectedRootCerts.BR_Audit__c;
            objCase.BR_Audit_Statement_Date__c = objSelectedRootCerts.BR_Audit_Statement_Date__c;
            objCase.BR_Audit_Type__c = objSelectedRootCerts.BR_Audit_Type__c;
            objCase.BR_Audit_Period_Start_Date__c = objSelectedRootCerts.BR_Audit_Period_Start_Date__c;
            objCase.BR_Audit_Period_End_Date__c = objSelectedRootCerts.BR_Audit_Period_End_Date__c;
            
            try {
                update objCase;
                this.showBRAuditConfirmation = true;
            } catch (Exception ex) {
                //this.hasError = true;
                ApexPages.getMessages().clear();
                ApexPages.addMessages(ex);
            }
            RefreshCaseDetails();
        }
    }
    
    // update the case to EV SSL audits fields
    public void syncEVSSLAuditFields() {
        if(objSelectedRootCerts != null && objSelectedRootCerts.Id != null) {
            objCase.EV_Audit_Statement_Link__c = objSelectedRootCerts.EV_Audit__c;
            objCase.EV_Audit_Statement_Date__c = objSelectedRootCerts.EV_Audit_Statement_Date__c;
            objCase.EV_Audit_Type__c = objSelectedRootCerts.EV_Audit_Type__c;
            objCase.EV_Audit_Period_Start_Date__c = objSelectedRootCerts.EV_Audit_Period_Start_Date__c;
            objCase.EV_Audit_Period_End_Date__c = objSelectedRootCerts.EV_Audit_Period_End_Date__c;
            
            try {
                update objCase;
                this.showEVSSLAuditConfirmation = true;
            } catch (Exception ex) {
                //this.hasError = true;
                ApexPages.getMessages().clear();
                ApexPages.addMessages(ex);
            }
            RefreshCaseDetails();
        }
    }
    
    // update the case to EV Code Signing audits fields
    public void syncEVCodeSigningAuditFields() {
        if(objSelectedRootCerts != null && objSelectedRootCerts.Id != null) {
            objCase.EV_Code_Signing_Audit_Statement_Link__c = objSelectedRootCerts.EV_Code_Signing_Audit__c;
            objCase.EV_Code_Signing_Audit_Statement_Date__c = objSelectedRootCerts.EV_Code_Signing_Audit_Statement_Date__c;
            objCase.EV_Code_Signing_Audit_Type__c = objSelectedRootCerts.EV_Code_Signing_Audit_Type__c;
            objCase.EV_Code_Signing_Audit_Period_Start_Date__c = objSelectedRootCerts.EV_Code_Signing_Audit_Period_Start_Date__c;
            objCase.EV_Code_Signing_Audit_Period_End_Date__c = objSelectedRootCerts.EV_Code_Signing_Audit_Period_End_Date__c;
            
            try {
                update objCase;
                this.showEVCodeSigningAuditConfirmation = true;
            } catch (Exception ex) {
                //this.hasError = true;
                ApexPages.getMessages().clear();
                ApexPages.addMessages(ex);
            }
            RefreshCaseDetails();
        }
    }
    
    // update the case to CP/CPS audits fields
    public void syncCPCPSAuditFields() {
        if(objSelectedRootCerts != null && objSelectedRootCerts.Id != null) {
            objCase.Policy_Documentation__c = objSelectedRootCerts.Policy_Documentation__c;
            objCase.Certificate_Policy_Link__c = objSelectedRootCerts.Certificate_Policy_CP__c;
            objCase.CA_Document_Repository__c = objSelectedRootCerts.CA_Document_Repository__c;
            objCase.Certification_Practice_Statement_Link__c = objSelectedRootCerts.Certification_Practice_Statement_CPS__c;
            objCase.CP_CPS_Last_Updated_Date__c = objSelectedRootCerts.CP_CPS_Last_Updated_Date__c;
            
            try {
                update objCase;
                this.showCPCPSAuditConfirmation = true;
            } catch (Exception ex) {
                //this.hasError = true;
                ApexPages.getMessages().clear();
                ApexPages.addMessages(ex);
            }
            RefreshCaseDetails();
        }
    }
    
    /*public PageReference UpdateCaseInfo(){
        try {
            if(objSelectedRootCerts != null && objSelectedRootCerts.Id != null) {
                objCase.Auditor_New__c = objSelectedRootCerts.Auditor_New__c;
                objCase.Auditor_Location_New__c = objSelectedRootCerts.Auditor_Location_New__c;
                objCase.Management_Assertions_By__c = objSelectedRootCerts.Management_Assertions_By__c;
                objCase.Standard_Audit_Statement_Link__c = objSelectedRootCerts.Standard_Audit__c;
                objCase.Standard_Audit_Statement_Date__c = objSelectedRootCerts.Standard_Audit_Statement_Date__c;
                objCase.Standard_Audit_Type__c = objSelectedRootCerts.Standard_Audit_Type__c;
                objCase.Standard_Audit_Period_Start_Date__c = objSelectedRootCerts.Standard_Audit_Period_Start_Date__c;
                objCase.Standard_Audit_Period_End_Date__c = objSelectedRootCerts.Standard_Audit_Period_End_Date__c;
                
                objCase.Code_Signing_Audit_Statement_Link__c = objSelectedRootCerts.Code_Signing_Audit__c;
                objCase.Code_Signing_Audit_Statement_Date__c = objSelectedRootCerts.Code_Signing_Audit_Statement_Date__c;
                objCase.Code_Signing_Audit_Type__c = objSelectedRootCerts.Code_Signing_Audit_Type__c;
                objCase.Code_Signing_Audit_Period_Start_Date__c = objSelectedRootCerts.Code_Signing_Audit_Period_Start_Date__c;
                objCase.Code_Signing_Audit_Period_End_Date__c = objSelectedRootCerts.Code_Signing_Audit_Period_End_Date__c;
                
                objCase.BR_Audit_Statement_Link__c = objSelectedRootCerts.BR_Audit__c;
                objCase.BR_Audit_Statement_Date__c = objSelectedRootCerts.BR_Audit_Statement_Date__c;
                objCase.BR_Audit_Type__c = objSelectedRootCerts.BR_Audit_Type__c;
                objCase.BR_Audit_Period_Start_Date__c = objSelectedRootCerts.BR_Audit_Period_Start_Date__c;
                objCase.BR_Audit_Period_End_Date__c = objSelectedRootCerts.BR_Audit_Period_End_Date__c;
                objCase.EV_Audit_Statement_Link__c = objSelectedRootCerts.EV_Audit__c;
                objCase.EV_Audit_Statement_Date__c = objSelectedRootCerts.EV_Audit_Statement_Date__c;
                objCase.EV_Audit_Type__c = objSelectedRootCerts.EV_Audit_Type__c;
                objCase.EV_Audit_Period_Start_Date__c = objSelectedRootCerts.EV_Audit_Period_Start_Date__c;
                objCase.EV_Audit_Period_End_Date__c = objSelectedRootCerts.EV_Audit_Period_End_Date__c;
                objCase.EV_Code_Signing_Audit_Statement_Link__c = objSelectedRootCerts.EV_Code_Signing_Audit__c;
                objCase.EV_Code_Signing_Audit_Statement_Date__c = objSelectedRootCerts.EV_Code_Signing_Audit_Statement_Date__c;
                objCase.EV_Code_Signing_Audit_Type__c = objSelectedRootCerts.EV_Code_Signing_Audit_Type__c;
                objCase.EV_Code_Signing_Audit_Period_Start_Date__c = objSelectedRootCerts.EV_Code_Signing_Audit_Period_Start_Date__c;
                objCase.EV_Code_Signing_Audit_Period_End_Date__c = objSelectedRootCerts.EV_Code_Signing_Audit_Period_End_Date__c;
                objCase.Policy_Documentation__c = objSelectedRootCerts.Policy_Documentation__c;
                objCase.Certificate_Policy_Link__c = objSelectedRootCerts.Certificate_Policy_CP__c;
                objCase.CA_Document_Repository__c = objSelectedRootCerts.CA_Document_Repository__c;
                objCase.Certification_Practice_Statement_Link__c = objSelectedRootCerts.Certification_Practice_Statement_CPS__c;
                objCase.CP_CPS_Last_Updated_Date__c = objSelectedRootCerts.CP_CPS_Last_Updated_Date__c;
                update objCase;
                ApexPages.AddMessage( new ApexPages.Message( ApexPages.Severity.CONFIRM, 'Case updated Successfully.'));
            }
        } catch (Exception ex){
            Apexpages.addMessages(ex);
            return null;
        }
        
        PageReference pg = new Pagereference('/'+objCase.Id);
        pg.setReDirect(true);
        return pg;
    }*/
    
    //wrapper class for displaying root certificates 
    public class WrapperRootCerts {
        public boolean isSelected {get; set;} 
        public Account objAccount {get; set;}
        public WrapperRootCerts(boolean isSel, Account objAcc){
            this.isSelected = isSel;
            this.objAccount = objAcc;
        }        
    }
}
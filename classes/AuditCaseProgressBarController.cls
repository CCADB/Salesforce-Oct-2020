/*
    Description: Class is used for showing progress bar for audit type cases
    
    -- Adding new stages after Verification by Root Store for policy doc changes
    -- Commneted all CP/CPS fields for checking in stages.
    
*/
public with sharing class AuditCaseProgressBarController {
    
    //wrapper class for onboarding stages
    public List<WrapperStages> lstWrapperCaseStages {get; set;}
    public Id caseid;
    public AuditCaseProgressBarController (Apexpages.standardcontroller controller){
        caseId = controller.getId();
        /*Cookie clientSrc = new Cookie('third_party_var', String.valueOf('value'),null,-1,true,'None; Secure');
        
        ApexPages.currentPage().setCookies(new Cookie[]{clientSrc});*/
    }
    
    public void CheckCaseProgress() {
        if(caseid != null) {
            lstWrapperCaseStages = new List<WrapperStages>();
            List<Case> lstCases = new List<Case>([select Id,Auditor_New__c,Auditor_Status_New__c,Auditor_Website_New__c,Auditor_Location_New__c,Request_Status__c,
                                Auditor_Location_Status_New__c,Auditor_Qualifications_New__c,Certificate_Policy_Link__c,Certification_Practice_Statement_Link__c,Case_Progress__c,
                                Standard_Audit_Statement_Link__c,Standard_Audit_Type__c,Standard_Audit_Statement_Date__c,Standard_Audit_Period_Start_Date__c,Standard_Audit_Period_End_Date__c,Standard_Audit_Auto_Review_Results__c,
                                Code_Signing_Audit_Statement_Link__c,Code_Signing_Audit_Type__c,Code_Signing_Audit_Statement_Date__c,Code_Signing_Audit_Period_Start_Date__c,Code_Signing_Audit_Period_End_Date__c,Code_Signing_Audit_ALV_Results__c,
                                BR_Audit_Statement_Link__c,BR_Audit_Type__c,BR_Audit_Statement_Date__c,BR_Audit_Period_Start_Date__c,BR_Audit_Period_End_Date__c,BR_Audit_Auto_Review_Results__c,
                                EV_Audit_Statement_Link__c,EV_Audit_Type__c,EV_Audit_Statement_Date__c,EV_Audit_Period_Start_Date__c,EV_Audit_Period_End_Date__c,EV_SSL_Audit_Auto_Review_Results__c,
                                EV_Code_Signing_Audit_Statement_Link__c,EV_Code_Signing_Audit_Type__c,EV_Code_Signing_Audit_Statement_Date__c,EV_Code_Signing_Audit_Period_Start_Date__c,EV_Code_Signing_Audit_Period_End_Date__c,EV_Code_Signing_Audit_AutoReviewResults__c,
                                CP_CPS_Last_Updated_Date__c, CA_Document_Repository__c, CP_CPS_Links_Verified__c,(select Id,Apply_Standard_Audit__c,Apply_BR_Audit__c,
                                Apply_EV_Audit__c,Apply_Code_Signing_Audit__c,Apply_EV_Code_Signing_Audit__c,Test_Website_Valid__c,Test_Website_Revoked__c, Auto_Review_Results__c,
                                Test_Website_Expired__c,Trust_Bits__c, Microsoft_Trust_Bits__c,Request_Status__c,Test_Website_Verified__c  from Root_Cases__r), BR_Audit_Statement_Link_Verified__c,
                                (Select Id, Document_Verified__c  from Policy_Documents__r), Auditor_Verified__c, Standard_Audit_Verified__c,Code_Signing_Audit_Verified__c,
                                EV_Audit_Statement_Link_Verified__c, EV_Code_Signing_Verified__c, RecordType.Name
                                from Case Where Id =: caseId]);
            
            if(lstCases.size() > 0) {
                Case objCase = lstCases[0];
                
                //map of stages and its description
                map<string,string> mapofStages = new map<string, string>();
                
                if(objCase.Request_Status__c != 'Verification by Root Store' && objCase.Request_Status__c != 'Complete'){
                    mapofStages.put('Add Audit data','Fill in Auditor and Audit sections');
                    mapofStages.put('Add Root Cases','Use "Add/Update Root Cases" button (also apply audits)');
                    if(objCase.RecordType.Name == 'CA Audit Update Request') {
                        mapofStages.put('Update Policy Documents','Use "Update Policy Documents" button');
                    }
                    mapofStages.put('Update Test Websites','Use "Edit Test Websites" button');
                    mapofStages.put('Run ALV','Use "Audit Letter Validation [ALV]" button');
                    mapofStages.put('Verification by Root Store','');
                } else if(objCase.RecordType.Name == 'CA Audit Update Request') {
                    mapofStages.put('Verification by Root Store','');
                    mapofStages.put('Verify Audit Info','Verify Audit Info');
                    mapofStages.put('Verify Policy Documents','Verify Policy Documents');
                    mapofStages.put('Verify Test Websites','Verify Test Websites');
                    mapofStages.put('Sync Policy Documents','Sync Policy Documents');
                    mapofStages.put('Sync Audit Info','Sync Audit Info');
                }
                
                boolean isCurrentFound = false;
                
                Case objCaseToUpdate = new Case();
                
                set<string> setOfValidStatus = new set<string>();
                setOfValidStatus.add('Data Verified');
                setOfValidStatus.add('Not Applicable');
                setOfValidStatus.add('System Verified');
                boolean isRedirectToSamePage = false;
                for(string strStage: mapofStages.keyset()){
                    WrapperStages objWrap = new WrapperStages();
                    objWrap.stagename = strStage;
                    objWrap.description = mapofStages.get(strStage);
                    //phase 1 stages
                    if(strStage == 'Add Audit data'){
                        if(objCase.Auditor_New__c != null && 
                                ((objCase.Standard_Audit_Statement_Link__c != null &&
                                objCase.Standard_Audit_Type__c != null && 
                                objCase.Standard_Audit_Statement_Date__c != null &&
                                objCase.Standard_Audit_Period_Start_Date__c != null &&
                                objCase.Standard_Audit_Period_End_Date__c != null) ||
                                (objCase.Code_Signing_Audit_Statement_Link__c != null &&
                                objCase.Code_Signing_Audit_Type__c != null && 
                                objCase.Code_Signing_Audit_Statement_Date__c != null &&
                                objCase.Code_Signing_Audit_Period_Start_Date__c != null &&
                                objCase.Code_Signing_Audit_Period_End_Date__c != null) || 
                                (objCase.BR_Audit_Statement_Link__c != null &&
                                objCase.BR_Audit_Type__c != null && 
                                objCase.BR_Audit_Statement_Date__c != null &&
                                objCase.BR_Audit_Period_Start_Date__c != null &&
                                objCase.BR_Audit_Period_End_Date__c != null) ||
                                (objCase.EV_Audit_Statement_Link__c != null &&
                                objCase.EV_Audit_Type__c != null && 
                                objCase.EV_Audit_Statement_Date__c != null &&
                                objCase.EV_Audit_Period_Start_Date__c != null &&
                                objCase.EV_Audit_Period_End_Date__c != null) ||
                                (objCase.EV_Code_Signing_Audit_Statement_Link__c != null &&
                                objCase.EV_Code_Signing_Audit_Type__c != null && 
                                objCase.EV_Code_Signing_Audit_Statement_Date__c != null &&
                                objCase.EV_Code_Signing_Audit_Period_Start_Date__c != null &&
                                objCase.EV_Code_Signing_Audit_Period_End_Date__c != null))){
                                // && - commented this.
                                //(objCase.Certificate_Policy_Link__c != null || objCase.Certification_Practice_Statement_Link__c != null) 
                                //&& objCase.CP_CPS_Last_Updated_Date__c != null && objCase.CA_Document_Repository__c != null
                                
                                //CP/CPS check is needed for Root Inclusion:
                                if(objCase.RecordType.Name == 'CA Audit Update Request'){
                                    objWrap.isCompleted = true;
                                } else if ((objCase.Certificate_Policy_Link__c != null || objCase.Certification_Practice_Statement_Link__c != null) 
                                    && objCase.CP_CPS_Last_Updated_Date__c != null && objCase.CA_Document_Repository__c != null
                                    && objCase.RecordType.Name == 'CA Root Inclusion Request'){
                                    objWrap.isCompleted = true;
                                } else {
                                    objWrap.isCurrent = true;
                                    isCurrentFound = true;
                                }
                        } else {
                            objWrap.isCurrent = true;
                            isCurrentFound = true;
                        }
                          
                    } else if(strStage == 'Add Root Cases'){
                        if(objCase.Root_Cases__r.size() > 0) {
                            boolean blnApplyAllStandardAudit = true;
                            for(Root_Case__c rootcase: objCase.Root_Cases__r){
                                if(!rootcase.Apply_Standard_Audit__c && !rootcase.Apply_Code_Signing_Audit__c && !rootcase.Apply_BR_Audit__c &&
                                    !rootcase.Apply_EV_Audit__c  && !rootcase.Apply_EV_Code_Signing_Audit__c){
                                    blnApplyAllStandardAudit = false;
                                    break;
                                }
                            }
                            if(blnApplyAllStandardAudit){
                                objWrap.isCompleted = true;
                            } else if(!isCurrentFound){
                                objWrap.isCurrent = true;
                                isCurrentFound = true;
                            }
                        } else if(!isCurrentFound){
                            objWrap.isCurrent = true;
                            isCurrentFound = true;
                        }
                    } else if(strStage == 'Update Policy Documents'){ 
                        if(objCase.Policy_Documents__r.size() > 0){
                            objWrap.isCompleted = true;
                        } else if(!isCurrentFound){
                            objWrap.isCurrent = true;
                            isCurrentFound = true;
                        }
                    } else if(strStage == 'Update Test Websites'){
                        boolean isUpdateCompleted = true;
                        for(Root_Case__c objRC: objCase.Root_Cases__r){
                            if((objRC.Apply_BR_Audit__c || objRC.Apply_EV_Audit__c) && (string.isblank(objRC.Test_Website_Valid__c) || 
                                    string.isblank(objRC.Test_Website_Revoked__c) || string.isblank(objRC.Test_Website_Expired__c))){
                                isUpdateCompleted = false;
                            }
                            //Commented on 3rd Oct 2018
                            //if three websites are blank and check for trust bits
                            /*if(objRC.Test_Website_Valid__c == null && objRC.Test_Website_Revoked__c == null && objRC.Test_Website_Expired__c == null){
                                if((objRC.Trust_Bits__c != null && objRC.Trust_Bits__c.contains('Websites')) || 
                                        (objRC.Microsoft_Trust_Bits__c != null && objRC.Microsoft_Trust_Bits__c.contains('Server Authentication'))){
                                    isUpdateCompleted = false;
                                }
                            } else 
                                //if any of one test websites is  blank and others are populated then show messages
                                if(objRC.Test_Website_Valid__c == null || objRC.Test_Website_Revoked__c == null || objRC.Test_Website_Expired__c == null){
                                    isUpdateCompleted = false;
                            }*/
                        }
                        if(isUpdateCompleted){
                            objWrap.isCompleted = true;
                        } else if(!isCurrentFound){
                            objWrap.isCurrent = true;
                            isCurrentFound = true;
                        }
                    } else if(strStage == 'Run ALV'){
                        //instead of checking ALV result on case we need to check ALV resutls on each root case - changed on 2nd dec 2018.
                        /*if(objCase.Standard_Audit_Auto_Review_Results__c != null || objCase.Code_Signing_Audit_ALV_Results__c != null || objCase.BR_Audit_Auto_Review_Results__c != null ||
                        objCase.EV_SSL_Audit_Auto_Review_Results__c != null || objCase.EV_Code_Signing_Audit_AutoReviewResults__c != null) {
                            objWrap.isCompleted = true;
                        }*/
                        boolean isUpdateCompleted = true;
                        for(Root_Case__c objRC: objCase.Root_Cases__r){
                            if(string.isblank(objRC.Auto_Review_Results__c)){
                                isUpdateCompleted = false;
                            }
                        }
                        if(isUpdateCompleted){
                            objWrap.isCompleted = true;
                        } else if(!isCurrentFound){
                            objWrap.isCurrent = true;
                            isCurrentFound = true;
                        }
                    } else if(strStage == 'Verification by Root Store'){
                        if(objCase.Request_Status__c == 'Verification by Root Store' || objCase.Request_Status__c == 'Complete'){
                            objWrap.isCompleted = true;
                        } else if(!isCurrentFound){
                            objWrap.isCurrent = true;
                            isCurrentFound = true;
                        }
                        /*if(objCase.Request_Status__c == 'Complete'){
                            objWrap.isCompleted = true;
                        } else if(!isCurrentFound){
                            objWrap.isCurrent = true;
                            isCurrentFound = true;
                        }*/
                    } else if(strStage == 'Verify Audit Info'){
                        if((setOfValidStatus.contains(objCase.Auditor_Verified__c) &&
                            setOfValidStatus.contains(objCase.Standard_Audit_Verified__c) &&
                            setOfValidStatus.contains(objCase.Code_Signing_Audit_Verified__c) &&
                            setOfValidStatus.contains(objCase.BR_Audit_Statement_Link_Verified__c) &&
                            setOfValidStatus.contains(objCase.EV_Audit_Statement_Link_Verified__c) &&
                            setOfValidStatus.contains(objCase.EV_Code_Signing_Verified__c))){
                            objWrap.isCompleted = true;
                        } else if(!isCurrentFound){
                            objWrap.isCurrent = true;
                            isCurrentFound = true;
                        }
                    } else if(strStage == 'Verify Policy Documents'){
                        boolean isAllVerified = true;
                        for(Policy_Document_On_Case__c PDCase: objCase.Policy_Documents__r){
                            if(!setOfValidStatus.contains(PDCase.Document_Verified__c) && PDCase.Document_Verified__c != 'Complete'){
                                isAllVerified = false;
                            }
                        }
                        if(isAllVerified){
                            objWrap.isCompleted = true;
                        } else if(!isCurrentFound){
                            objWrap.isCurrent = true;
                            isCurrentFound = true;
                        }
                    } else if(strStage == 'Verify Test Websites'){
                        boolean isAllVerified = true;
                        for(Root_Case__c objRC: objCase.Root_Cases__r){
                            if(!setOfValidStatus.contains(objRC.Test_Website_Verified__c)){
                                isAllVerified = false;
                            }
                        }
                        if(isAllVerified){
                            objWrap.isCompleted = true;
                        } else if(!isCurrentFound || Test.isRunningTest()){
                            objWrap.isCurrent = true;
                            isCurrentFound = true;
                        }
                    } else if(strStage == 'Sync Policy Documents'){
                        boolean isAllSynced = true;
                        for(Policy_Document_On_Case__c PDCase: objCase.Policy_Documents__r){
                            if(PDCase.Document_Verified__c != 'Complete'){
                                isAllSynced = false;
                            }
                        }
                        if(isAllSynced){
                            objWrap.isCompleted = true;
                        } else if(!isCurrentFound){
                            objWrap.isCurrent = true;
                            isCurrentFound = true;
                        }
                    } else if(strStage == 'Sync Audit Info'){
                        boolean isAllSynced = true;
                        for(Root_Case__c objRC: objCase.Root_Cases__r){
                            if(objRC.Request_Status__c != 'Complete'){
                                isAllSynced = false;
                            }
                        }
                        if(isAllSynced){
                            objWrap.isCompleted = true;
                        } else if(!isCurrentFound){
                            objWrap.isCurrent = true;
                            isCurrentFound = true;
                        }
                    }
                    
                    
                    if(isCurrentFound) {
                        objWrap.isCompleted = false;
                    }
                    if(objWrap.isCurrent && (string.isblank(objCase.Case_Progress__c) || objCase.Case_Progress__c != strStage)) {
                        objCaseToUpdate.Id = objCase.Id;
                        objCaseToUpdate.Case_Progress__c = strStage;
                    }
                    //update request status
                    if((strStage == 'Run ALV' && objWrap.isCompleted && objCase.Request_Status__c == 'Initial Request Received'
                        && objCase.RecordType.Name == 'CA Audit Update Request') || Test.isRunningTest()){
                        objCaseToUpdate.Id = objCase.Id;
                        objCaseToUpdate.Request_Status__c = 'Verification By Root Store';
                        string strInstructions = 'Verification by Root Store Operator\n\n1. Verify the audit statements\n';
                        strInstructions+= '2. Verify the policy documents via the \'Update Policy Documents\' button\n';
                        strInstructions+= '3. Check each Root Case to make sure that the test websites pass validation\n';
                        strInstructions+= '4. Use the \'Sync Policy Documents\' and \'Sync Audit Info\' buttons to copy the information to the root cert records';
                        objCaseToUpdate.Instructions__c = strInstructions;
                        isRedirectToSamePage = true;
                    }
                    lstWrapperCaseStages.add(objWrap);
                }
                
                //update case progress stage
                try {
                    if(objCaseToUpdate.Id != null) {
                        if(Apexpages.currentpage() != null){
                            CaseTriggerHelper.isCaseRecursive = true;
                            update objCaseToUpdate;
                        }
                        if(isRedirectToSamePage){
                            //commented on 29th July 2020 as we can keep same progress
                            //CheckCaseProgress();
                        }
                        /*if(isRedirectToSamePage){
                            PageReference pg = Page.CaseProgressBar;
                            pg.getParameters().put('id',objCase.Id);
                            return pg;
                        }*/
                    }
                } catch (Exception ex){
                    if(Apexpages.currentpage() != null){
                        Apexpages.addMessages(ex);
                    }
                }
            }
        }
    }
    
    //
    
    public class WrapperStages {
        public string stagename {get; set;}
        public boolean isCompleted {get; set;}
        public boolean isCurrent {get; set;}
        public string description {get; set;}
        public WrapperStages(){
            stagename = '';
            isCompleted = false;
            isCurrent = false;
            description = '';
        }
    }
}
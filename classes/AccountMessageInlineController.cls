/*******************************************************************************************************
 Name: AccountMessageInlineController

 Dependencies:  AccountMessageInlineController controller class, AccountMessageInlinePage VF page,
 AccountMessageInlineControllerTest

 Description: Controller class is for Inline Account page. This is specifically to check
 
     Audit urls, Audit Same As Parent, CP/CPS urls, CP/CPS Same As Parent fields.
    
    -> only the non blank urls (audit/cp/cps) are ckecked 
    -> When CP and CPS Link is blank and 'CP/CPS Same As Parent' is not True then it display error message.
    -> When CP or CPS link is populated and Parent Cert's 'CP/CPS Same As Parent' is not True then check if they have same CP and CPS. 
       If they match then display message to check CP/CPS Same As Parent checkbox.
    -> When CP or CPS link is populated and Parent Cert's 'CP/CPS Same As Parent' is True then we are checking parent's Parent and compare CP and CPS. 
       If match then display message to check CP/CPS Same As Parent checkbox.
    
    Same logic is used for Audits (Std, Code Sign, BR, EV SSL only)

 Instructions: None
    
 *******************************************************************************************************
 Revision History:
 
    2/2/2019 Check for 'Audit Same as Parent'
    3/5/2019 Updated code to check only populated CP or CPS or all audit urls. We are not comparing blank 
             audit urls.
    4/15/19  Updated code to check CPACanada report url is changed or not. 
    6/3/19   Updated code to check "Date ALV Processed" with Audit Statement dates. If it audit same as 
             parent then comparing parent audit dates with "Date ALV Processed".    
    9/5/19   Updated code to add warning for 'Non-constrained Doppelganger'. 
  
 ******************************************************************************************************/
 
public with sharing class AccountMessageInlineController {
    
    public string strAuditSameAsParent {get; set;}
    public string strCPCPSSameAsParent {get; set;}
    public boolean isStandardAuditReportURLNotFound {get; set;}
    public boolean isBRAuditReportURLNotFound {get; set;}
    public boolean isCodeSigningAuditReportURLNotFound {get; set;}
    public boolean isEVSSLAuditReportURLNotFound {get; set;}
    public boolean isEVCodeSigningAuditReportURLNotFound {get; set;}
    public string strALVProcessed {get; set;}
    public string strWarningTechnicalConstrained {get; set;}

    
    public AccountMessageInlineController(Apexpages.standardcontroller controller){
        strAuditSameAsParent = '';
        strCPCPSSameAsParent = '';
        strWarningTechnicalConstrained = '';
        strALVProcessed = '';
        isStandardAuditReportURLNotFound = false;
        isBRAuditReportURLNotFound = false;
        isCodeSigningAuditReportURLNotFound = false;
        isEVSSLAuditReportURLNotFound = false;
        isEVCodeSigningAuditReportURLNotFound = false;
        
        Id accId = controller.getId();
        
        List<Account> lstAcc = new List<Account>([select Id, ParentId, RecordType.Name,Valid_From_GMT__c,
                        Certificate_Policy_CP__c, Certification_Practice_Statement_CPS__c,Subject_SPKI_SHA256__c,
                        Parent.Certificate_Policy_CP__c, Parent.Certification_Practice_Statement_CPS__c,Technically_Constrained__c ,
                        Standard_Audit__c, Parent.Standard_Audit__c, Code_Signing_Audit__c, Parent.Code_Signing_Audit__c,
                        BR_Audit__c, Parent.BR_Audit__c, EV_Audit__c, Parent.EV_Audit__c,Date_ALV_Processed__c, 
                        Audits_Same_as_Parent__c, Parent.Audits_Same_as_Parent__c,Code_Signing_Audit_Statement_Date__c,
                        EV_Audit_Statement_Date__c,Standard_Audit_Statement_Date__c,BR_Audit_Statement_Date__c,
                        CP_CPS_Same_as_Parent__c, Parent.CP_CPS_Same_as_Parent__c,EV_Code_Signing_Audit__c,
                        Standard_Audit_Period_End_Date__c,BR_Audit_Period_End_Date__c,EV_Audit_Period_End_Date__c,
                        EV_Code_Signing_Audit_Period_End_Date__c,Code_Signing_Audit_Period_End_Date__c,
                        Parent.Standard_Audit_Period_End_Date__c,Parent.BR_Audit_Period_End_Date__c,Parent.EV_Audit_Period_End_Date__c,
                        Parent.EV_Code_Signing_Audit_Period_End_Date__c,Parent.Code_Signing_Audit_Period_End_Date__c,Revocation_Status__c
                        from Account Where Id =: accId]);
        if(lstAcc.size() > 0){
            Account objAcc = lstAcc[0];
            
            //check for CPA Canada URL has changed or not.
            set<string> setofAuditUrls = new set<string>();
            if(objAcc.Standard_Audit__c != null && objAcc.Standard_Audit__c.startswith('https://www.cpacanada.ca')){
                setofAuditUrls.add(objAcc.Standard_Audit__c);
            }
            if(objAcc.Code_Signing_Audit__c != null && objAcc.Code_Signing_Audit__c.startswith('https://www.cpacanada.ca')){
                setofAuditUrls.add(objAcc.Code_Signing_Audit__c);
            }
            if(objAcc.BR_Audit__c != null && objAcc.BR_Audit__c.startswith('https://www.cpacanada.ca')){
                setofAuditUrls.add(objAcc.BR_Audit__c);
            }
            if(objAcc.EV_Audit__c != null && objAcc.EV_Audit__c.startswith('https://www.cpacanada.ca')){
                setofAuditUrls.add(objAcc.EV_Audit__c);
            }
            if(objAcc.EV_Code_Signing_Audit__c != null && objAcc.EV_Code_Signing_Audit__c.startswith('https://www.cpacanada.ca')){
                setofAuditUrls.add(objAcc.EV_Code_Signing_Audit__c);
            }
            
            if(setofAuditUrls.size() > 0){
                map<string, Id> mapCPACanadaFiles = new map<string, Id>();
                for(CPACanada_File__c file: [select Id,Name,Report_URL__c from CPACanada_File__c Where Report_URL__c != null and Report_URL__c in: setofAuditUrls]){
                    mapCPACanadaFiles.put(file.Report_URL__c.tolowercase(), file.Id);
                }
                if(objAcc.Standard_Audit__c != null && objAcc.Standard_Audit__c.startswith('https://www.cpacanada.ca') &&
                    !mapCPACanadaFiles.containskey(objAcc.Standard_Audit__c.tolowercase())){
                    isStandardAuditReportURLNotFound = true;
                }
                if(objAcc.Code_Signing_Audit__c != null && objAcc.Code_Signing_Audit__c.startswith('https://www.cpacanada.ca') &&
                    !mapCPACanadaFiles.containskey(objAcc.Code_Signing_Audit__c.tolowercase())){
                    isCodeSigningAuditReportURLNotFound = true;
                }
                if(objAcc.BR_Audit__c != null && objAcc.BR_Audit__c.startswith('https://www.cpacanada.ca') &&
                    !mapCPACanadaFiles.containskey(objAcc.BR_Audit__c.tolowercase())){
                    isBRAuditReportURLNotFound = true;
                }
                if(objAcc.EV_Audit__c != null && objAcc.EV_Audit__c.startswith('https://www.cpacanada.ca') &&
                    !mapCPACanadaFiles.containskey(objAcc.EV_Audit__c.tolowercase())){
                    isEVSSLAuditReportURLNotFound = true;
                }
                if(objAcc.EV_Code_Signing_Audit__c != null && objAcc.EV_Code_Signing_Audit__c.startswith('https://www.cpacanada.ca') &&
                    !mapCPACanadaFiles.containskey(objAcc.EV_Code_Signing_Audit__c.tolowercase())){
                    isEVCodeSigningAuditReportURLNotFound = true;
                }
                
            }
            //check only for intermediate certs
            if(objAcc.RecordType.Name == 'Intermediate Certificate') {
                //check for 'Non-constrained Doppelganger'
                if(objAcc.Subject_SPKI_SHA256__c != null && objAcc.Technically_Constrained__c){
                    List<Account> lstSameSubjectSPKI = CommonMethods.getSameSubjectSPKIInterCerts(objAcc.Subject_SPKI_SHA256__c);
                    if(lstSameSubjectSPKI.size() > 0){
                        strWarningTechnicalConstrained += 'This cert is technically-constrained, but there are certs with the same Subject+SPKI that are not technically-constrained.';
                    }
                }
                
                //check if audit statement url is not blank and Date ALV Processed is blank or older than statement dates
                //check if cert is not revoked
                if(objAcc.Revocation_Status__c == 'Not Revoked'){
                    if((string.isnotblank(objAcc.Standard_Audit__c) || string.isnotblank(objAcc.BR_Audit__c) || 
                        string.isnotblank(objAcc.Code_Signing_Audit__c) || string.isnotblank(objAcc.EV_Audit__c)) && objAcc.Date_ALV_Processed__c == null){
                        strALVProcessed = 'Re-run Audit Letter Validation (ALV).';
                    } else {
                        if(objAcc.Audits_Same_as_Parent__c){
                            boolean isFound = false;
                            Id accParentId = objAcc.ParentId;
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
                            if(objAcc.Date_ALV_Processed__c != null && ((objParentAccount.Standard_Audit_Statement_Date__c != null && objAcc.Date_ALV_Processed__c < objParentAccount.Standard_Audit_Statement_Date__c) || 
                                (objParentAccount.BR_Audit_Statement_Date__c != null && objAcc.Date_ALV_Processed__c < objParentAccount.BR_Audit_Statement_Date__c) ||
                                (objParentAccount.Code_Signing_Audit_Statement_Date__c != null && objAcc.Date_ALV_Processed__c < objParentAccount.Code_Signing_Audit_Statement_Date__c) ||
                                (objParentAccount.EV_Audit_Statement_Date__c != null && objAcc.Date_ALV_Processed__c < objParentAccount.EV_Audit_Statement_Date__c))){
                                    strALVProcessed = 'Re-run Audit Letter Validation (ALV).'; 
                            }
                            if((objAcc.Valid_From_GMT__c > objParentAccount.Standard_Audit_Period_End_Date__c ||
                                objAcc.Valid_From_GMT__c > objParentAccount.Code_Signing_Audit_Period_End_Date__c ||
                                objAcc.Valid_From_GMT__c > objParentAccount.BR_Audit_Period_End_Date__c ||
                                objAcc.Valid_From_GMT__c > objParentAccount.EV_Audit_Period_End_Date__c ||
                                objAcc.Valid_From_GMT__c > objParentAccount.EV_Code_Signing_Audit_Period_End_Date__c)){
                                   //strALVProcessed = 'Re-run Audit Letter Validation (ALV).'; 
                                   strALVProcessed = 'This certificate was created after the audit period of the current audit statement, so please make sure to include it in the CA\'s next periodic audit statement.';
                            } 
                        } 
                        if(objAcc.Date_ALV_Processed__c != null && 
                                ((objAcc.Standard_Audit_Statement_Date__c != null && objAcc.Date_ALV_Processed__c < objAcc.Standard_Audit_Statement_Date__c) || 
                                (objAcc.BR_Audit_Statement_Date__c != null && objAcc.Date_ALV_Processed__c < objAcc.BR_Audit_Statement_Date__c) ||
                                (objAcc.Code_Signing_Audit_Statement_Date__c != null && objAcc.Date_ALV_Processed__c < objAcc.Code_Signing_Audit_Statement_Date__c) ||
                                (objAcc.EV_Audit_Statement_Date__c != null && objAcc.Date_ALV_Processed__c < objAcc.EV_Audit_Statement_Date__c))){
                                    strALVProcessed = 'Re-run Audit Letter Validation (ALV).'; 
                        }
                        if(!objAcc.Audits_Same_as_Parent__c && (objAcc.Valid_From_GMT__c > objAcc.Standard_Audit_Period_End_Date__c ||
                            objAcc.Valid_From_GMT__c > objAcc.Code_Signing_Audit_Period_End_Date__c ||
                            objAcc.Valid_From_GMT__c > objAcc.BR_Audit_Period_End_Date__c ||
                            objAcc.Valid_From_GMT__c > objAcc.EV_Audit_Period_End_Date__c ||
                            objAcc.Valid_From_GMT__c > objAcc.EV_Code_Signing_Audit_Period_End_Date__c)){
                               //strALVProcessed = 'Re-run Audit Letter Validation (ALV).';
                               strALVProcessed = 'This certificate was created after the audit period of the current audit statement, so please make sure to include it in the CA\'s next periodic audit statement.';   
                        }          
                    }
                }
                
                //if cp/cps are blank then it should check cp/cps same as parent
                if(string.isblank(objAcc.Certificate_Policy_CP__c) && string.isblank(objAcc.Certification_Practice_Statement_CPS__c) && !objAcc.CP_CPS_Same_as_Parent__c){
                    strCPCPSSameAsParent = 'Please fill in Policies and Practices Information section or mark the checkbox "CP/CPS Same as Parent"';
                }
                //check if cp/cps are same as parent and parent cert cp/cps is not same as parent
                if((string.isnotblank(objAcc.Certificate_Policy_CP__c) || string.isnotblank(objAcc.Certification_Practice_Statement_CPS__c)) && 
                    !objAcc.CP_CPS_Same_as_Parent__c && !objAcc.Parent.CP_CPS_Same_as_Parent__c && (string.isblank(objAcc.Certificate_Policy_CP__c) || 
                    (string.isnotblank(objAcc.Certificate_Policy_CP__c) && objAcc.Certificate_Policy_CP__c == objAcc.Parent.Certificate_Policy_CP__c)) &&
                    (string.isblank(objAcc.Certification_Practice_Statement_CPS__c) || (string.isnotblank(objAcc.Certification_Practice_Statement_CPS__c) && 
                    objAcc.Certification_Practice_Statement_CPS__c == objAcc.Parent.Certification_Practice_Statement_CPS__c))){
                    strCPCPSSameAsParent = 'Policies and Practices Information fields are same as parent. Please clear the fields and check "CP/CPS Same as Parent".';
                }
                
                //check if cp/cps are populate and parent intermediate is also same as parent
                if((string.isnotblank(objAcc.Certificate_Policy_CP__c) || string.isnotblank(objAcc.Certification_Practice_Statement_CPS__c)) 
                    && !objAcc.CP_CPS_Same_as_Parent__c && objAcc.Parent.CP_CPS_Same_as_Parent__c){
                    boolean isFound = false;
                    Id accParentId = objAcc.ParentId;
                    while(!isFound){
                        Account objParentAccount = GetParentAccount(accParentId);
                        if(objParentAccount != null && (objParentAccount.RecordType.Name == 'Root Certificate' || !objParentAccount.CP_CPS_Same_as_Parent__c)) {
                            isFound = true;
                            if((string.isblank(objAcc.Certificate_Policy_CP__c) || 
                                (string.isnotblank(objAcc.Certificate_Policy_CP__c) && objAcc.Certificate_Policy_CP__c == objParentAccount.Certificate_Policy_CP__c)) &&
                                (string.isblank(objAcc.Certification_Practice_Statement_CPS__c) || (string.isnotblank(objAcc.Certification_Practice_Statement_CPS__c) && 
                                objAcc.Certification_Practice_Statement_CPS__c == objParentAccount.Certification_Practice_Statement_CPS__c))){
                                strCPCPSSameAsParent = 'Policies and Practices Information fields are same as parent. Please clear the fields and check "CP/CPS Same as Parent".';
                            }  
                        } else if(objParentAccount == null) {
                            isFound = true;
                        }
                        if(objParentAccount != null) accParentId = objParentAccount.ParentId;
                    }
                }
                
                //if audits are blank then check Audit Same as Parent
                if(string.isblank(objAcc.Standard_Audit__c) && string.isblank(objAcc.Code_Signing_Audit__c) && string.isblank(objAcc.BR_Audit__c) &&
                    string.isblank(objAcc.EV_Audit__c) && !objAcc.Audits_Same_as_Parent__c){
                    strAuditSameAsParent = 'Please fill in Audit Information section or mark the checkbox "Audits Same as Parent"';    
                }
                //check if audits are same as parent and parent intermediate is not same as parent
                if((string.isnotblank(objAcc.Standard_Audit__c) || string.isnotblank(objAcc.Code_Signing_Audit__c) || 
                    string.isnotblank(objAcc.BR_Audit__c) || string.isnotblank(objAcc.EV_Audit__c)) && !objAcc.Audits_Same_as_Parent__c &&
                    !objAcc.Parent.Audits_Same_as_Parent__c && 
                    (string.isblank(objAcc.Standard_Audit__c) || (string.isnotblank(objAcc.Standard_Audit__c) && objAcc.Standard_Audit__c == objAcc.Parent.Standard_Audit__c)) &&
                    (string.isblank(objAcc.Code_Signing_Audit__c) || (string.isnotblank(objAcc.Code_Signing_Audit__c) && objAcc.Code_Signing_Audit__c == objAcc.Parent.Code_Signing_Audit__c)) &&
                    (string.isblank(objAcc.BR_Audit__c) || (string.isnotblank(objAcc.BR_Audit__c) && objAcc.BR_Audit__c == objAcc.Parent.BR_Audit__c)) &&
                    (string.isblank(objAcc.EV_Audit__c) || (string.isnotblank(objAcc.EV_Audit__c) && objAcc.EV_Audit__c == objAcc.Parent.EV_Audit__c))){
                    strAuditSameAsParent = 'All provided Audits are same as parent. Please clear the Audit fields and check "Audits Same as Parent".';
                }
                
                //check if audits are populated and parent intermediate is also same as parent
                if((string.isnotblank(objAcc.Standard_Audit__c) || string.isnotblank(objAcc.Code_Signing_Audit__c) || string.isnotblank(objAcc.BR_Audit__c) || 
                    string.isnotblank(objAcc.EV_Audit__c)) && !objAcc.Audits_Same_as_Parent__c && objAcc.Parent.Audits_Same_as_Parent__c){
                    boolean isFound = false;
                    Id accParentId = objAcc.ParentId;
                    while(!isFound){
                        Account objParentAccount = GetParentAccount(accParentId);
                        if(objParentAccount != null && (objParentAccount.RecordType.Name == 'Root Certificate' || !objParentAccount.Audits_Same_as_Parent__c)) {
                            isFound = true;
                            if((string.isblank(objAcc.Standard_Audit__c) || (string.isnotblank(objAcc.Standard_Audit__c) && objAcc.Standard_Audit__c == objParentAccount.Standard_Audit__c)) &&
                                (string.isblank(objAcc.Code_Signing_Audit__c) || (string.isnotblank(objAcc.Code_Signing_Audit__c) && objAcc.Code_Signing_Audit__c == objParentAccount.Code_Signing_Audit__c)) &&
                                (string.isblank(objAcc.BR_Audit__c) || (string.isnotblank(objAcc.BR_Audit__c) && objAcc.BR_Audit__c == objParentAccount.BR_Audit__c)) &&
                                (string.isblank(objAcc.EV_Audit__c) || (string.isnotblank(objAcc.EV_Audit__c) && objAcc.EV_Audit__c == objParentAccount.EV_Audit__c))){
                                strAuditSameAsParent = 'All provided Audits are same as parent. Please clear the Audit fields and check "Audits Same as Parent".';
                            }
                        } else if(objParentAccount == null) {
                            isFound = true;
                        }
                        if(objParentAccount != null) accParentId = objParentAccount.ParentId;
                    }
                }
            }
        }
    }
    
    public Account GetParentAccount(string accId){
        List<Account> lstAcc = new List<Account>([select Id, ParentId, RecordType.Name,
                        Certificate_Policy_CP__c, Certification_Practice_Statement_CPS__c,
                        Parent.Certificate_Policy_CP__c, Parent.Certification_Practice_Statement_CPS__c,
                        Standard_Audit__c, Parent.Standard_Audit__c, Code_Signing_Audit__c, Parent.Code_Signing_Audit__c,
                        BR_Audit__c, Parent.BR_Audit__c, EV_Audit__c, Parent.EV_Audit__c,Date_ALV_Processed__c, 
                        Audits_Same_as_Parent__c, Parent.Audits_Same_as_Parent__c,Code_Signing_Audit_Statement_Date__c,
                        EV_Audit_Statement_Date__c,Standard_Audit_Statement_Date__c,BR_Audit_Statement_Date__c,
                        CP_CPS_Same_as_Parent__c, Parent.CP_CPS_Same_as_Parent__c,EV_Code_Signing_Audit__c,
                        Standard_Audit_Period_End_Date__c,BR_Audit_Period_End_Date__c,EV_Audit_Period_End_Date__c,
                        EV_Code_Signing_Audit_Period_End_Date__c,Code_Signing_Audit_Period_End_Date__c,
                        Parent.Standard_Audit_Period_End_Date__c,Parent.BR_Audit_Period_End_Date__c,Parent.EV_Audit_Period_End_Date__c,
                        Parent.EV_Code_Signing_Audit_Period_End_Date__c,Parent.Code_Signing_Audit_Period_End_Date__c
                        from Account Where Id =: accId]);
        if(lstAcc.size() > 0){
            return lstAcc[0];
        }
        return null;
    }
}
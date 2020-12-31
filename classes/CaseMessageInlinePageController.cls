/*
    Description: Controller for CaseMessageInlinePage
*/
public with sharing class CaseMessageInlinePageController {
    
    public boolean isStandardAuditReportURLNotFound {get; set;}
    public boolean isBRAuditReportURLNotFound {get; set;}
    public boolean isCodeSigningAuditReportURLNotFound {get; set;}
    public boolean isEVSSLAuditReportURLNotFound {get; set;}
    public boolean isEVCodeSigningAuditReportURLNotFound {get; set;}
    
    public CaseMessageInlinePageController (Apexpages.standardcontroller controller){
        Cookie clientSrc = new Cookie('third_party_var', String.valueOf('value'),null,-1,true,'None; Secure');
        
        ApexPages.currentPage().setCookies(new Cookie[]{clientSrc});
        isStandardAuditReportURLNotFound = false;
        isBRAuditReportURLNotFound = false;
        isCodeSigningAuditReportURLNotFound = false;
        isEVSSLAuditReportURLNotFound = false;
        isEVCodeSigningAuditReportURLNotFound = false;
        
        Id caseid = controller.getId();
        
        if(caseid != null) {
            set<string> setofAuditUrls = new set<string>();
            List<Case> lstCases = new List<Case>([select Id,Standard_Audit_Statement_Link__c,Code_Signing_Audit_Statement_Link__c,
                    BR_Audit_Statement_Link__c,EV_Audit_Statement_Link__c,EV_Code_Signing_Audit_Statement_Link__c from Case Where Id =: caseid]);
            if(lstCases.size() > 0){
                Case objCase = lstCases[0];
                if(objCase.Standard_Audit_Statement_Link__c != null && objCase.Standard_Audit_Statement_Link__c.startswith('https://www.cpacanada.ca')){
                    setofAuditUrls.add(objCase.Standard_Audit_Statement_Link__c);
                }
                if(objCase.Code_Signing_Audit_Statement_Link__c != null && objCase.Code_Signing_Audit_Statement_Link__c.startswith('https://www.cpacanada.ca')){
                    setofAuditUrls.add(objCase.Code_Signing_Audit_Statement_Link__c);
                }
                if(objCase.BR_Audit_Statement_Link__c != null && objCase.BR_Audit_Statement_Link__c.startswith('https://www.cpacanada.ca')){
                    setofAuditUrls.add(objCase.BR_Audit_Statement_Link__c);
                }
                if(objCase.EV_Audit_Statement_Link__c != null && objCase.EV_Audit_Statement_Link__c.startswith('https://www.cpacanada.ca')){
                    setofAuditUrls.add(objCase.EV_Audit_Statement_Link__c);
                }
                if(objCase.EV_Code_Signing_Audit_Statement_Link__c != null && objCase.EV_Code_Signing_Audit_Statement_Link__c.startswith('https://www.cpacanada.ca')){
                    setofAuditUrls.add(objCase.EV_Code_Signing_Audit_Statement_Link__c);
                }
                
                if(setofAuditUrls.size() > 0){
                    map<string, Id> mapCPACanadaFiles = new map<string, Id>();
                    for(CPACanada_File__c file: [select Id,Name,Report_URL__c from CPACanada_File__c Where Report_URL__c != null and Report_URL__c in: setofAuditUrls]){
                        mapCPACanadaFiles.put(file.Report_URL__c.tolowercase(), file.Id);
                    }
                    if(objCase.Standard_Audit_Statement_Link__c != null && objCase.Standard_Audit_Statement_Link__c.startswith('https://www.cpacanada.ca') &&
                        !mapCPACanadaFiles.containskey(objCase.Standard_Audit_Statement_Link__c.tolowercase())){
                        isStandardAuditReportURLNotFound = true;
                    }
                    if(objCase.Code_Signing_Audit_Statement_Link__c != null && objCase.Code_Signing_Audit_Statement_Link__c.startswith('https://www.cpacanada.ca') &&
                        !mapCPACanadaFiles.containskey(objCase.Code_Signing_Audit_Statement_Link__c.tolowercase())){
                        isCodeSigningAuditReportURLNotFound = true;
                    }
                    if(objCase.BR_Audit_Statement_Link__c != null && objCase.BR_Audit_Statement_Link__c.startswith('https://www.cpacanada.ca') &&
                        !mapCPACanadaFiles.containskey(objCase.BR_Audit_Statement_Link__c.tolowercase())){
                        isBRAuditReportURLNotFound = true;
                    }
                    if(objCase.EV_Audit_Statement_Link__c != null && objCase.EV_Audit_Statement_Link__c.startswith('https://www.cpacanada.ca') &&
                        !mapCPACanadaFiles.containskey(objCase.EV_Audit_Statement_Link__c.tolowercase())){
                        isEVSSLAuditReportURLNotFound = true;
                    }
                    if(objCase.EV_Code_Signing_Audit_Statement_Link__c != null && objCase.EV_Code_Signing_Audit_Statement_Link__c.startswith('https://www.cpacanada.ca') &&
                        !mapCPACanadaFiles.containskey(objCase.EV_Code_Signing_Audit_Statement_Link__c.tolowercase())){
                        isEVCodeSigningAuditReportURLNotFound = true;
                    }
                    
                }
            }
        }
    }
    
}
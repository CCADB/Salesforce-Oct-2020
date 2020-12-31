/*
    Description: AuditRootCaseMessageInlinePage Controller to display inline messages
    
    Display Audit Gap messages and Test websites releated messages.
*/
public with sharing class AuditRootCaseMessageInlineController {
    
    //boolean is used to render audit gap message
    public boolean isAuditGapMessage {get;set;}
    //var is used to display audit message
    public string strAuditGapMessage {get; set;}
    //boolean is used to render if all audits are empty
    public boolean isAllAuditEmpty {get;set;}
    //boolean is used to render if one or more websites are blank
    public boolean isIfOneOrMoreWebsites {get;set;}
    //boolean is used to render if no websites added and trust bits are populated
    public boolean isIfNoWebsites {get;set;}
    
    public AuditRootCaseMessageInlineController (Apexpages.standardcontroller controller){
        isAuditGapMessage = false;
        isAllAuditEmpty = false;
        isIfOneOrMoreWebsites = false;
        isIfNoWebsites = false;
        strAuditGapMessage = '';
        //query on root case
        List<Root_Case__c> lstRootCases = new List<Root_Case__c>([select Id,Name,Root_Certificate_Name_Existing__c, 
            Case_No__c,Case_No__r.Standard_Audit_Period_Start_Date__c, Root_Certificate_Name_Existing__r.Standard_Audit_Period_End_Date__c,
            Case_No__r.Code_Signing_Audit_Period_Start_Date__c, Root_Certificate_Name_Existing__r.Code_Signing_Audit_Period_End_Date__c,
            Case_No__r.BR_Audit_Period_Start_Date__c, Root_Certificate_Name_Existing__r.BR_Audit_Period_End_Date__c,
            Case_No__r.EV_Audit_Period_Start_Date__c, Root_Certificate_Name_Existing__r.EV_Audit_Period_End_Date__c,
            Case_No__r.EV_Code_Signing_Audit_Period_Start_Date__c, Root_Certificate_Name_Existing__r.EV_Code_Signing_Audit_Period_End_Date__c,
            Apply_Standard_Audit__c,Apply_BR_Audit__c,Apply_EV_Audit__c,Apply_EV_Code_Signing_Audit__c,Apply_Code_Signing_Audit__c,
            Test_Website_Valid__c,Test_Website_Revoked__c,Test_Website_Expired__c,Microsoft_Trust_Bits__c,Trust_Bits__c
            from Root_Case__c Where Id =: controller.getId()]);
        
        if(lstRootCases.size() > 0){
            Root_Case__c objRC = lstRootCases[0];
            //checking audit gaps
            if(objRC.Root_Certificate_Name_Existing__c != null){
                strAuditGapMessage = 'Forbidden gap between previous Audit Period End Date and new Audit Period Start Date for ';
                boolean blnAddComma = false;
                //checking for standard audit gaps
                if(objRC.Case_No__r.Standard_Audit_Period_Start_Date__c != null && objRC.Root_Certificate_Name_Existing__r.Standard_Audit_Period_End_Date__c != null &&
                    objRC.Root_Certificate_Name_Existing__r.Standard_Audit_Period_End_Date__c.DaysBetween(objRC.Case_No__r.Standard_Audit_Period_Start_Date__c) > 2){
                    isAuditGapMessage = true;
                    strAuditGapMessage += 'Standard Audit';
                    blnAddComma = true;
                }
                
                //checking for code signing audit gap
                if(objRC.Case_No__r.Code_Signing_Audit_Period_Start_Date__c != null && objRC.Root_Certificate_Name_Existing__r.Code_Signing_Audit_Period_End_Date__c != null &&
                    objRC.Root_Certificate_Name_Existing__r.Code_Signing_Audit_Period_End_Date__c.DaysBetween(objRC.Case_No__r.Code_Signing_Audit_Period_Start_Date__c) > 2){
                    isAuditGapMessage = true;
                    if(blnAddComma){
                        strAuditGapMessage += ', ';
                    }
                    strAuditGapMessage += 'Code Signing Audit';
                    blnAddComma = true;
                }
                
                //checking for br audit gap
                if(objRC.Case_No__r.BR_Audit_Period_Start_Date__c != null && objRC.Root_Certificate_Name_Existing__r.BR_Audit_Period_End_Date__c != null &&
                    objRC.Root_Certificate_Name_Existing__r.BR_Audit_Period_End_Date__c.DaysBetween(objRC.Case_No__r.BR_Audit_Period_Start_Date__c) > 2){
                    isAuditGapMessage = true;
                    if(blnAddComma){
                        strAuditGapMessage += ', ';
                    }
                    strAuditGapMessage += 'BR Audit';
                    blnAddComma = true;
                }
                //checking for ev ssl gap
                if(objRC.Case_No__r.EV_Audit_Period_Start_Date__c != null && objRC.Root_Certificate_Name_Existing__r.EV_Audit_Period_End_Date__c != null &&
                    objRC.Root_Certificate_Name_Existing__r.EV_Audit_Period_End_Date__c.DaysBetween(objRC.Case_No__r.EV_Audit_Period_Start_Date__c) > 2){
                    isAuditGapMessage = true;
                    if(blnAddComma){
                        strAuditGapMessage += ', ';
                    }
                    strAuditGapMessage += 'EV SSL Audit';
                    blnAddComma = true;
                }
                //checking for ev code signing gap
                if(objRC.Case_No__r.EV_Code_Signing_Audit_Period_Start_Date__c != null && objRC.Root_Certificate_Name_Existing__r.EV_Code_Signing_Audit_Period_End_Date__c != null &&
                    objRC.Root_Certificate_Name_Existing__r.Standard_Audit_Period_End_Date__c.DaysBetween(objRC.Case_No__r.Standard_Audit_Period_Start_Date__c) > 2){
                    isAuditGapMessage = true;
                    if(blnAddComma){
                        strAuditGapMessage += ', ';
                    }
                    strAuditGapMessage += 'EV Code Signing Audit';
                }
            }
            
            //if all audits are blank/false
            if(objRC.Apply_Standard_Audit__c == false && objRC.Apply_Code_Signing_Audit__c == false && objRC.Apply_BR_Audit__c == false && 
                    objRC.Apply_EV_Audit__c == false && objRC.Apply_EV_Code_Signing_Audit__c == false){
                isAllAuditEmpty = true;
            }
            
            //check test websites only when BR and EV SSL Audit apply
            if((objRC.Apply_BR_Audit__c || objRC.Apply_EV_Audit__c) && (string.isblank(objRC.Test_Website_Valid__c) || 
                    string.isblank(objRC.Test_Website_Revoked__c) || string.isblank(objRC.Test_Website_Expired__c))){
                isIfNoWebsites = true;
            }
            
            //commented on 3rd Oct 2018
            /*//if three websites are blank and check for trust bits
            if(objRC.Test_Website_Valid__c == null && objRC.Test_Website_Revoked__c == null && objRC.Test_Website_Expired__c == null){
                if((objRC.Trust_Bits__c != null && objRC.Trust_Bits__c.contains('Websites')) || 
                        (objRC.Microsoft_Trust_Bits__c != null && objRC.Microsoft_Trust_Bits__c.contains('Server Authentication'))){
                    isIfNoWebsites = true;
                }
            } else 
            //if any of one test websites is  blank and others are populated then show messages
            if(objRC.Test_Website_Valid__c == null || objRC.Test_Website_Revoked__c == null || objRC.Test_Website_Expired__c == null){
                isIfOneOrMoreWebsites = true;
            }*/
        }
    }
}
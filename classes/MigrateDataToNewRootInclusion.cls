/*
    Description: Class is created for Migrating data of Cases and Root Case of Record Type
    'CA Owner/Root Inclusion  Request' to new type
    
    Mapping rules for data migration are below ...

    Old Verified Fields to new:
    None => Not Verified
    Verified => Data Verified
    Not Applicable => Not Applicable 
    All others => Not Verified
    
    Old Mozilla Request Status to new: 
    Need Information from CA => Information Verification In Process
    Ready for Public Discussion => In Detail CP/CPS Review
*/
public with sharing class MigrateDataToNewRootInclusion {
    
    /*
        Run from Developer console.
        
        //RUN FOR ALL CA OWNER ROOT INCLUSION TPYE CASES
        set<Id> setOfRootCaseIds = new set<Id>();
        for(Root_Case__c objRC: [select Id from Root_Case__c Where RecordType.DeveloperName = 'CA_Owner_Root_Inclusion_Request']){
            setOfRootCaseIds.add(objRC.Id);
        }
        MigrateDataToNewRootInclusion.UpdateCasesandRootCases(setOfRootCaseIds);
        
        //RUN FOR SPECIFIC CASE
        set<Id> setOfRootCaseIds = new set<Id>();
        for(Root_Case__c objRC: [select Id from Root_Case__c Where Case_No__c = '50029000008Dvzs']){
            setOfRootCaseIds.add(objRC.Id);
        }
        MigrateDataToNewRootInclusion.UpdateCasesandRootCases(setOfRootCaseIds);
    */
    
    //passed Root case id as parameter
    public static void UpdateCasesandRootCases(set<Id> setOfRootCaseIds){
        /*try {
            Id RCInclusionRecordTypeID;
            Id CaseInclusionRecordTypeID;
            if(Schema.SObjectType.Root_Case__c.getRecordTypeInfosByName().get('CA Root Inclusion Request') != null){
                RCInclusionRecordTypeID = Schema.SObjectType.Root_Case__c.getRecordTypeInfosByName().get('CA Root Inclusion Request').getRecordTypeID();
            }
            if(Schema.SObjectType.Case.getRecordTypeInfosByName().get('CA Root Inclusion Request') != null){
                CaseInclusionRecordTypeID = Schema.SObjectType.Case.getRecordTypeInfosByName().get('CA Root Inclusion Request').getRecordTypeID();
            }
            if(setOfRootCaseIds.size() > 0){
                List<Root_Case__c> lstRootCasesToUpdate = new List<Root_Case__c>();
                map<Id,Case> mapCasesToUpdate = new map<Id,Case>();
                for(Root_Case__c objRC: [select Id,Name,CA_Hierarchy__c,Description_of_PKI_Hierarchy__c,
                        Certificate_Summary__c,Role__c,Case_No__c,Standard_Audit__c,BR_Audit__c,EV_Audit__c,
                        Apply_Standard_Audit__c,Apply_BR_Audit__c,Apply_EV_Audit__c,Test_Website_Valid__c,
                        Test_Website_URL_SSL_or_Example_Cert__c,Case_No__r.Request_Status__c,Request_Status__c,
                        CP__c,CPS__c, CP_Verified__c,CPS_Verified__c,
                        CA_Document_Repository__c,Other_Relevant_Documents__c,Policy_Documentation__c,
                        Standard_Audit_Type__c,Standard_Audit_Statement_Date__c,
                        Standard_Audit_Period_Start_Date__c,Standard_Audit_Period_End_Date__c,Standard_Audit_Verified__c,
                        BR_Self_Assessment__c,EV_Audit_Type__c,EV_Audit_Statement_Date__c,EV_SSL_Audit_Period_Start_Date__c,
                        EV_SSL_Audit_Period_End_Date__c,EV_Audit_Verified__c,Certificate_Summary_Verified__c,Application_Information_Verified__c,
                        TestWebsiteURLSSLorExCert_Verified__c,Test_Website_Verified__c,Revocation_Tested_Verified__c, CA_Browser_Forum_Lint_Test_Verified__c, 
                        Test_Website_Lint_Test_Verified__c, EV_Tested_Verified__c, CA_Hierarchy_Verified__c, Externally_Operated_SubCAs_Verified__c, Cross_Signing_Verified__c, Tech_Cons_on_3rd_party_Iss_Verified__c, 
                        Trust_Bits_Verified__c, SSL_Validation_Type_Verified__c, EV_Policy_OID_s_Verified__c, Mozilla_Applied_Constraints_Verified__c, 
                        Technical_Constraint_on_3rd_party_Issuer__c, Constraints_on_External_SubCAs_RAs__c
                        //,Case_No__r.Impact_to_Mozilla_Users_Verified__c,Management_Assertions_By__c
                        //,Case_No__r.Company_Website_Verified__c,Case_No__r.CA_s_Reponse_to_Recom_Prac_Verified__c,Case_No__r.CA_s_Response_to_Prob_Prac_Verified__c
                        from Root_Case__c Where Id in: setOfRootCaseIds]){
                        
                    //===================RootCases==============================
                    
                    //change record type
                    objRC.RecordTypeId = RCInclusionRecordTypeID;
                    //default
                    objRC.Root_Stores_Applying_To__c = 'Mozilla';
                    //copy certificate summary to role
                    objRC.Role__c = objRC.Certificate_Summary__c;
                    
                    //if standard audit is not blank then apply standard audit set as true
                    if(objRC.Standard_Audit__c != null && objRC.Standard_Audit__c.startswith('http')){
                        objRC.Apply_Standard_Audit__c = true;
                    }
                    //if br audit is not blank then apply br audit set as true
                    if(objRC.BR_Audit__c != null && objRC.BR_Audit__c.startswith('http')){
                        objRC.Apply_BR_Audit__c = true;
                    }
                    //if ev ssl audit is not blank then apply ev ssl audit set as true
                    if(objRC.EV_Audit__c != null && objRC.EV_Audit__c.startswith('http')){
                        objRC.Apply_EV_Audit__c = true;
                    }
                    //Test Website Valid is empty then copy the url from this field (only the url)
                    if(objRC.Test_Website_Valid__c == null && objRC.Test_Website_URL_SSL_or_Example_Cert__c != null && 
                            objRC.Test_Website_URL_SSL_or_Example_Cert__c.startswith('http')){
                        objRC.Test_Website_Valid__c = objRC.Test_Website_URL_SSL_or_Example_Cert__c;
                    }
                    
                    //copy ca hierarchy descrption to pki heirarchy
                    objRC.Description_of_PKI_Hierarchy__c = 'DUE TO SYSTEM UPGRADE ON OCT 15, 2018 - Hierarchy checkboxes not checked. \n\n ' + objRC.CA_Hierarchy__c; 
                    
                    //application verified
                    objRC.Application_Information_Verified__c = getStatus(objRC.Certificate_Summary_Verified__c);
                    
                    set<string> setOfRequestStatusToVerified = new set<string>();
                    setOfRequestStatusToVerified.add('In Detailed CP/CPS Review');
                    setOfRequestStatusToVerified.add('In Public Discussion');
                    setOfRequestStatusToVerified.add('Approved, Pending Inclusion');
                    setOfRequestStatusToVerified.add('Approved, Pending Inclusion and EV');
                    setOfRequestStatusToVerified.add('Included, Pending EV');
                    setOfRequestStatusToVerified.add('Complete');
                    //apply audit verified
                    if(setOfRequestStatusToVerified.contains(objRC.Request_Status__c)){
                        objRC.Apply_Audit_Verified__c = 'Data Verified';
                    } else {
                        objRC.Apply_Audit_Verified__c = 'Not Verified';
                    }
                    
                    //set request status
                    objRC.Request_Status__c = getRequestStatus(objRC.Request_Status__c);
                    
                    //copy test websites verified
                    objRC.Test_Website_Verified__c = getStatus(objRC.TestWebsiteURLSSLorExCert_Verified__c);
                    
                    set<string> setOfVerifiedStatus = new set<string>{'Verified','Not Applicable'};
                    
                    //test results verified.
                    if(setOfVerifiedStatus.contains(objRC.Revocation_Tested_Verified__c) && setOfVerifiedStatus.contains(objRC.CA_Browser_Forum_Lint_Test_Verified__c) &&
                        setOfVerifiedStatus.contains(objRC.Test_Website_Lint_Test_Verified__c) && setOfVerifiedStatus.contains(objRC.EV_Tested_Verified__c)){
                        objRC.Test_Results_Verified__c = 'Data Verified';
                    } else {
                        objRC.Test_Results_Verified__c = 'Not Verified';
                    }
                    
                    //pki verified
                    if(setOfVerifiedStatus.contains(objRC.CA_Hierarchy_Verified__c) && setOfVerifiedStatus.contains(objRC.Externally_Operated_SubCAs_Verified__c) &&
                        setOfVerifiedStatus.contains(objRC.Cross_Signing_Verified__c) && setOfVerifiedStatus.contains(objRC.Tech_Cons_on_3rd_party_Iss_Verified__c)){
                        objRC.PKI_Hierarchy_Verified__c = 'Data Verified';
                    } else {
                        objRC.PKI_Hierarchy_Verified__c = 'Not Verified';
                    }
                    
                    //mozilla fields verified
                    if(setOfVerifiedStatus.contains(objRC.Trust_Bits_Verified__c) && setOfVerifiedStatus.contains(objRC.SSL_Validation_Type_Verified__c) &&
                        setOfVerifiedStatus.contains(objRC.EV_Policy_OID_s_Verified__c) && setOfVerifiedStatus.contains(objRC.Mozilla_Applied_Constraints_Verified__c)){
                        objRC.Mozilla_Fields_Verified__c = 'Data Verified';
                    } else {
                        objRC.Mozilla_Fields_Verified__c = 'Not Verified';
                    }
                    
                    //copy value 3rd party issuer
                    objRC.Constraints_on_External_SubCAs_RAs__c = objRC.Technical_Constraint_on_3rd_party_Issuer__c;
                    
                    //set microsoft status
                    objRC.Microsoft_Request_Status__c = 'Not Applicable';

                    lstRootCasesToUpdate.add(objRC);
                    
                    //====================Cases============================
                    Case objCase = new Case();
                    
                    if(mapCasesToUpdate.containskey(objRC.Case_No__c)){
                        objCase = mapCasesToUpdate.get(objRC.Case_No__c);
                    } else {
                        objCase.Id = objRC.Case_No__c; 
                        objCase.Request_Status__c = objRC.Case_No__r.Request_Status__c;
                    }
                    //Mozilla Status field, Microsoft Status and Microsoft Contract Type field to populate. 
                    
                    objCase.RecordTypeId = CaseInclusionRecordTypeID;
                    
                    //objCase.CA_Owner_Information_Verified__c = getStatus(objRC.Case_No__r.Impact_to_Mozilla_Users_Verified__c);
                    
                    //objCase.Company_Website_Verified__c = getStatus(objRC.Case_No__r.Company_Website_Verified__c);
                    
                    //copy auditor and auditor location field to case
                    if(objRC.Auditor_New__c != null){
                        objCase.Auditor_New__c = objRC.Auditor_New__c;
                    }
                    if(objRC.Auditor_Location_New__c != null){
                        objCase.Auditor_Location_New__c = objRC.Auditor_Location_New__c;
                    }
                    //copy auditor veritifed field
                    
                    if((!mapCasesToUpdate.containskey(objRC.Case_No__c) || mapCasesToUpdate.get(objRC.Case_No__c).Auditor_Verified__c == null) && objRC.Auditor_New_Verified__c != null) {
                        objCase.Auditor_Verified__c = getStatus(objRC.Auditor_New_Verified__c);
                    }
                    
                    //standard audit
                    if(objRC.Standard_Audit__c != null && objRC.Standard_Audit__c.startswith('http')){
                        objCase.Standard_Audit_Statement_Link__c = objRC.Standard_Audit__c;
                        objCase.Standard_Audit_Type__c = objRC.Standard_Audit_Type__c;
                        objCase.Standard_Audit_Statement_Date__c = objRC.Standard_Audit_Statement_Date__c;
                        objCase.Standard_Audit_Period_Start_Date__c = objRC.Standard_Audit_Period_Start_Date__c;
                        objCase.Standard_Audit_Period_End_Date__c = objRC.Standard_Audit_Period_End_Date__c;
                        //if((!mapCasesToUpdate.containskey(objRC.Case_No__c) || mapCasesToUpdate.get(objRC.Case_No__c).Standard_Audit_Verified__c == null) && objRC.Standard_Audit_Verified__c != null) {
                        objCase.Standard_Audit_Verified__c = getStatus(objRC.Standard_Audit_Verified__c);
                        if(objCase.Standard_Audit_Verified__c == 'Data Verified'){
                            objCase.Standard_Audit_Authenticity_Confirmed__c = true;
                        }
                        //}
                    }
                    
                    //Mangegemtn assertation
                    if(objRC.Management_Assertions_By__c != null) {
                        objCase.Management_Assertions_By__c = objRC.Management_Assertions_By__c;
                    }
                    
                    //br audit
                    if(objRC.BR_Audit__c != null && objRC.BR_Audit__c.startswith('http')){
                        objCase.BR_Audit_Statement_Link__c = objRC.BR_Audit__c;
                        objCase.BR_Audit_Type__c = objRC.BR_Audit_Type__c;
                        objCase.BR_Audit_Statement_Date__c = objRC.BR_Audit_Statement_Date__c;
                        objCase.BR_Audit_Period_Start_Date__c = objRC.BR_Audit_Period_Start_Date__c;
                        objCase.BR_Audit_Period_End_Date__c = objRC.BR_Audit_Period_End_Date__c;
                        //if((!mapCasesToUpdate.containskey(objRC.Case_No__c) || mapCasesToUpdate.get(objRC.Case_No__c).BR_Audit_Statement_Link_Verified__c == null) && objRC.BR_Audit_Verified__c != null) {
                        //objCase.BR_Audit_Statement_Link_Verified__c = getStatus(objRC.BR_Audit_Verified__c);
                        if(objCase.BR_Audit_Statement_Link_Verified__c == 'Data Verified'){
                            objCase.BR_Audit_Authenticity_Confirmed__c = true;
                        }
                        //}
                    }
                    
                    //EV SSL audit
                    if(objRC.EV_Audit__c != null && objRC.EV_Audit__c.startswith('http')){
                        objCase.EV_Audit_Statement_Link__c = objRC.EV_Audit__c;
                        objCase.EV_Audit_Type__c = objRC.EV_Audit_Type__c;
                        objCase.EV_Audit_Statement_Date__c = objRC.EV_Audit_Statement_Date__c;
                        objCase.EV_Audit_Period_Start_Date__c = objRC.EV_SSL_Audit_Period_Start_Date__c;
                        objCase.EV_Audit_Period_End_Date__c = objRC.EV_SSL_Audit_Period_End_Date__c;
                        //if((!mapCasesToUpdate.containskey(objRC.Case_No__c) || mapCasesToUpdate.get(objRC.Case_No__c).EV_Audit_Statement_Link_Verified__c == null) && objRC.EV_Audit_Verified__c != null) {
                        objCase.EV_Audit_Statement_Link_Verified__c = getStatus(objRC.EV_Audit_Verified__c);
                        if(objCase.EV_Audit_Statement_Link_Verified__c == 'Data Verified'){
                            objCase.EV_SSL_Audit_Authenticity_Confirmed__c = true;
                        }
                        //}
                    }
                    
                    //code signing audit
                    objCase.Code_Signing_Audit_Verified__c = 'Not Applicable';
                    //ev code signing audit
                    objCase.EV_Code_Signing_Verified__c = 'Not Applicable';
                    
                    //copy first non empty root case CP to case CP
                    if((!mapCasesToUpdate.containskey(objRC.Case_No__c) || mapCasesToUpdate.get(objRC.Case_No__c).Certificate_Policy_Link__c == null) && objRC.CP__c != null){
                        objCase.Certificate_Policy_Link__c = objRC.CP__c;
                    }
                    //Copy first non empty root case CPS to case CPS
                    if((!mapCasesToUpdate.containskey(objRC.Case_No__c) || mapCasesToUpdate.get(objRC.Case_No__c).Certification_Practice_Statement_Link__c == null) && objRC.CPS__c != null){
                        objCase.Certification_Practice_Statement_Link__c = objRC.CPS__c;
                    }
                    //copy first non empty root case to case
                    if((!mapCasesToUpdate.containskey(objRC.Case_No__c) || mapCasesToUpdate.get(objRC.Case_No__c).CA_Document_Repository__c == null) && objRC.CA_Document_Repository__c != null){
                        objCase.CA_Document_Repository__c = objRC.CA_Document_Repository__c;
                    }
                    if((!mapCasesToUpdate.containskey(objRC.Case_No__c) || mapCasesToUpdate.get(objRC.Case_No__c).Other_Relevant_Documents__c == null) && objRC.Other_Relevant_Documents__c != null){
                        objCase.Other_Relevant_Documents__c = objRC.Other_Relevant_Documents__c;
                    }
                    if((!mapCasesToUpdate.containskey(objRC.Case_No__c) || mapCasesToUpdate.get(objRC.Case_No__c).Policy_Documentation__c == null) && objRC.Policy_Documentation__c != null){
                        objCase.Policy_Documentation__c = objRC.Policy_Documentation__c;
                    }
                    //cp/cps verified
                    objCase.CP_CPS_Links_Verified__c = getStatus(objRC.CPS_Verified__c);
                    
                    //BR Self assesment
                    objCase.BR_Self_Assessment__c = objRC.BR_Self_Assessment__c;
                    
                    //verified fields
                    //URL and TExt area fields. getting String too long error.
                    //objCase.Required_Practices__c = objRC.Case_No__r.CAs_Response_to_Required_Practices__c;
                    //objCase.Required_Practices_Verified__c = getStatus(objRC.Case_No__r.CA_s_Reponse_to_Recom_Prac_Verified__c);
                    
                    //objCase.Forbidden_Practices__c = objRC.Case_No__r.CAs_Reponse_to_Forbidden_Practices__c;
                    //objCase.Forbidden_Practices_Verified__c = getStatus(objRC.Case_No__r.CA_s_Response_to_Prob_Prac_Verified__c);
                    
                    //if(objRC.CPS_Doc_Language__c != null) {
                    //    objCase.CPS_Doc_Language__c = objRC.CPS_Doc_Language__c;
                    //}
                    
                    //set request status
                    objCase.Request_Status__c = getRequestStatus(objCase.Request_Status__c);
                    
                    //set microsoft status
                    objCase.Microsoft_Request_Status__c = 'Not Applicable';
                    
                    mapCasesToUpdate.put(objCase.Id, objCase);
                }
                if(lstRootCasesToUpdate.size() >0){
                    update lstRootCasesToUpdate;
                }
                if(mapCasesToUpdate.size() >0){
                    update mapCasesToUpdate.values();
                }
            }
        } catch (Exception ex){
            system.debug(ex);
        }*/
    }
    
    /*public static string getStatus(string verifiedtype){
        string returnNew  = '';
        if(verifiedtype == 'None'){
            returnNew = 'Not Verified';
        } else if(verifiedtype == 'Verified'){
            returnNew = 'Data Verified';
        } else if(verifiedtype == 'Not Applicable'){
            returnNew = 'Not Applicable';
        } else {
            returnNew = 'Not Verified';
        }
        return returnNew;
    }
    
    public static string getRequestStatus(string requeststatus){
        string strReqStatus = '';
        if(requeststatus == 'Need Information from CA') {
            strReqStatus = 'Information Verification In Process';
        } else if(requeststatus == 'Ready for Public Discussion'){
            strReqStatus = 'In Detail CP/CPS Review';
        } else {
            strReqStatus = requeststatus;
        }
        return strReqStatus;
    }*/
}
/*
    Description: Controller is created to check data integrity of audit file archives. 
    The pgm looks for ...
                 
        1) Discrepancies between audit info for Root/Intermediate records and File Archive records
        2) Missing Root/Inter certs entries in File Archive object
        
    Users can pass an URL parameter to filter records ...
    
        Type=All or Type=    *all records are shown
        Type=Mozilla         *filter on CA Owner's Mozilla Status = 'Included','Change Requested'; Root Cert's Mozilla Status = 'Included','Change Requested'; And Inter Certs that chain up these Root Rert records
        Type=Microsoft       *filter on CA Owner's Microsoft Status equals 'Included' or 'Change Requested'; Root Cert's Microsoft Status = 'Included','Change Requested'; And Inter Certs that chain up these Root Rert records
        
    The controller feeds the VF page to show four sections
                 
        Root Certs - Inconsistent Audit Dates
        Root Certs - Missing Audit Archives
        Intermediate Certs - Inconsistent Audit Dates
        Intermediate Certs - Missing Audit Archives
        
    NOTE: PROGRAM DOES NOT CHECK FOR FILE ARCHIVE ASSOCIATION REOCRDS.

    Create Date: 3/21/2018
    Updates    :
    04/06/2018        Update audit data integrity to filter records based on URL parameter. 
                      When Type=Mozilla then display root/inter certs which belongs to CA Owner's with Mozilla Status is Included or Change Requested.
                      When Type=Microsoft then display root/inter certs which belongs to CA Owner's with Microsoft Status is Included or Change Requested.
                      When Type= or Type=All showing all root/inter certs.
    04/11/2018        Update the report to only show root certs with Mozilla status of Included or Change Requested.
                      When Type=Mozilla then show only root certs with mozilla status of Included or Change Requested and for intermediate certs Root Cert Id's  mozilla status is included or change requested.
                      When Type=Microsoft then show only root certs with microsoft status of Included or Change Requested and for intermediate certs Root Cert Id's  microsoft status is included or change requested.
                      When Type= or Type=All showing all root/inter certs.
    09/27/2018        Updated code to add for Code Signing audit.
    03/07/2019        For Mozilla type report, have condition to exclude intermediate certs with Revocation Status equals “Not Revoked”.
    03/10/2019        For Mozilla type report, correct 'exclude' to 'include' not revoked inter certs
    04/24/2019        Exclude expired intermediate certs ('Valid To' is in the past)
    08/13/2019        Added Comments field for Account.
    08/04/2020        Added "Comments" to "Mozilla - Intermediate Certs - Inconsistent Audit Dates" section
*/

public with sharing class AuditDataIntegrityReportController {
    
    //list that has audit integrity report - Inter certs
    public transient List<WrapperAccounts> lstInconsistentInterCerts {get; set;}
    //list that has file archives for Inter certs
    public transient List<WrapperInnerAccount> lstMissingAuditArchivesInterCerts {get; set;}
    //list that has audit integrity report - root certs
    public transient List<WrapperAccounts> lstInconsistentRootCerts {get; set;}
    //list that has file archives for Root certs
    public transient List<WrapperInnerAccount> lstMissingAuditArchivesRootCerts {get; set;}
    
    public string reportType {get; set;}
    
    //controller
    public AuditDataIntegrityReportController(){
        lstInconsistentInterCerts = new List<WrapperAccounts>();
        lstInconsistentRootCerts = new List<WrapperAccounts>();
        lstMissingAuditArchivesInterCerts = new List<WrapperInnerAccount>();
        lstMissingAuditArchivesRootCerts = new List<WrapperInnerAccount>();
        
        reportType = 'All';
        if(Apexpages.currentPage().getParameters().get('type') != null){
            reportType = string.valueof(Apexpages.currentPage().getParameters().get('type'));
        }
        String CAOwnerRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('CA Owner').getRecordTypeId();
        String rootCertRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Root Certificate').getRecordTypeId();
        String intermediateCertRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Intermediate Certificate').getRecordTypeId();
        
        //query all CA Owner and fill maps
        map<Id,Account> mapAllCAOWners = new map<Id,Account>([Select Id,Name,Status__c,Microsoft_Status__c
                         from Account Where RecordTypeId =: CAOwnerRecordTypeId]);
        
        //query all root and inter certs and fill map (key as audit url and value as account)
        map<string, List<Account>> mapAuditURLWiseAccounts = new map<string, List<Account>>();
        for(Account objAcc: [SELECT Id, Name, ParentId, RecordTypeId, Valid_To_GMT__c, 
                            Standard_Audit__c, Standard_Audit_Statement_Date__c, Standard_Audit_Period_Start_Date__c, Standard_Audit_Period_End_Date__c,
                            Code_Signing_Audit__c, Code_Signing_Audit_Statement_Date__c, Code_Signing_Audit_Period_Start_Date__c, Code_Signing_Audit_Period_End_Date__c,
                            BR_Audit__c, BR_Audit_Statement_Date__c,BR_Audit_Period_Start_Date__c,BR_Audit_Period_End_Date__c,EV_Audit__c ,EV_Audit_Statement_Date__c,CA_Owner_ID__c,Status__c ,
                            EV_Audit_Period_Start_Date__c,EV_Audit_Period_End_Date__c,EV_Code_Signing_Audit__c,EV_Code_Signing_Audit_Statement_Date__c,EV_Code_Signing_Audit_Period_Start_Date__c,
                            Root_Cert_Id__c,Root_Cert_Id__r.Status__c,Root_Cert_Id__r.Microsoft_Status__c,Microsoft_Status__c,CA_Owner__c,Revocation_Status__c ,
                            EV_Code_Signing_Audit_Period_End_Date__c, Comments__c
                            FROM Account 
                            WHERE (RecordTypeId =: rootCertRecordTypeId or RecordTypeId =: intermediateCertRecordTypeId)]){
            set<string> setofAuditURLs = new set<string>();
            if(mapAllCAOWners.containskey(objAcc.CA_Owner_ID__c)){
                boolean isValidAcc = false;
                if(string.isnotblank(reportType)){
                    if(reportType.tolowercase() == 'mozilla') {
                        if(mapAllCAOWners.get(objAcc.CA_Owner_ID__c).Status__c != null && (mapAllCAOWners.get(objAcc.CA_Owner_ID__c).Status__c == 'Included' || 
                                mapAllCAOWners.get(objAcc.CA_Owner_ID__c).Status__c == 'Change Requested')){
                            if(objAcc.RecordTypeId == rootCertRecordTypeId && (objAcc.Status__c == 'Included' || objAcc.Status__c == 'Change Requested')){
                                isValidAcc = true;
                            } else if(objAcc.RecordTypeId == intermediateCertRecordTypeId && (objAcc.Root_Cert_Id__c != null && 
                                            (objAcc.Root_Cert_Id__r.Status__c == 'Included' || objAcc.Root_Cert_Id__r.Status__c == 'Change Requested')) 
                                            && objAcc.Revocation_Status__c == 'Not Revoked' && objAcc.Valid_To_GMT__c >= System.Today()){
                                isValidAcc = true;
                            }
                        } 
                    } else if(reportType.tolowercase() == 'microsoft') {
                        if(mapAllCAOWners.get(objAcc.CA_Owner_ID__c).Microsoft_Status__c != null && (mapAllCAOWners.get(objAcc.CA_Owner_ID__c).Microsoft_Status__c == 'Included' || 
                                mapAllCAOWners.get(objAcc.CA_Owner_ID__c).Microsoft_Status__c == 'Change Requested')){
                            if(objAcc.RecordTypeId == rootCertRecordTypeId && (objAcc.Microsoft_Status__c == 'Included' || objAcc.Microsoft_Status__c == 'Change Requested')){
                                isValidAcc = true;
                            } else if(objAcc.RecordTypeId == intermediateCertRecordTypeId && (objAcc.Root_Cert_Id__c != null && 
                                            (objAcc.Root_Cert_Id__r.Microsoft_Status__c == 'Included' || objAcc.Root_Cert_Id__r.Microsoft_Status__c == 'Change Requested')
                                            && objAcc.Valid_To_GMT__c >= System.Today())){
                                isValidAcc = true;
                            }
                        } 
                    } else {
                        isValidAcc = true;
                    } 
                } else {
                    isValidAcc = true;
                }
                
                if(isValidAcc) {
                    if(objAcc.Standard_Audit__c != null) {
                        setofAuditURLs.add(objAcc.Standard_Audit__c);
                    }
                    if(objAcc.Code_Signing_Audit__c != null) {
                        setofAuditURLs.add(objAcc.Code_Signing_Audit__c);
                    }
                    if(objAcc.BR_Audit__c != null) {
                        setofAuditURLs.add(objAcc.BR_Audit__c);
                    }
                    if(objAcc.EV_Audit__c != null) {
                        setofAuditURLs.add(objAcc.EV_Audit__c);
                    }
                    if(objAcc.EV_Code_Signing_Audit__c != null) {
                        setofAuditURLs.add(objAcc.EV_Code_Signing_Audit__c);
                    }
                    if(setofAuditURLs.size() > 0){
                        for(string strURL: setofAuditURLs){
                            string strKey = strURL + '#' + objAcc.CA_Owner_ID__c;
                            if(mapAuditURLWiseAccounts.containskey(strKey)){
                                mapAuditURLWiseAccounts.get(strKey).add(objAcc);
                            } else {
                                mapAuditURLWiseAccounts.put(strKey, new List<Account>{objAcc});
                            }
                        }
                    }
                }
            }
        }
        
        //query all file archive records and fill file archive map (key as external link and value as file archive)
        map<string, File_Archive__c> mapAuditURLWiseFileArchive = new map<string, File_Archive__c>();
        for(File_Archive__c objFA: [SELECT Id,Name,Auditor__c,Auditor_Location__c,Audit_Statement_Date__c,
                                    CA_Owner__c,Document_Type__c,External_Link__c,Internal_Link__c,
                                    Period_End_Date__c,Period_Start_Date__c 
                                    FROM File_Archive__c]){
            if(objFA.External_Link__c != null){
                mapAuditURLWiseFileArchive.put(objFA.External_Link__c+'#'+objFA.CA_Owner__c, objFA);
            }
        }
        
        //fill list of missing archives for root and inter certs
        if(mapAuditURLWiseAccounts.size() > 0){
            for(string strAuditKey: mapAuditURLWiseAccounts.keyset()){
                if(!mapAuditURLWiseFileArchive.containskey(strAuditKey)){
                    for(Account objAcc: mapAuditURLWiseAccounts.get(strAuditKey)){
                        string strAuditURL = strAuditKey.split('#')[0];
                        WrapperInnerAccount objInnerWrapAcc = new WrapperInnerAccount();
                        objInnerWrapAcc.objAccount = objAcc;
                        List<WrapperAccountAuditDetail> lstWrapperAccountAuditDetail = new List<WrapperAccountAuditDetail>(); 
                        boolean isMatch = true;
                        if(objAcc.Standard_Audit__c == strAuditURL){
                            isMatch = false;
                            WrapperAccountAuditDetail objWrapAudit = new WrapperAccountAuditDetail();
                            objWrapAudit.AuditType = 'Standard Audit';
                            objWrapAudit.AuditURL = strAuditURL;
                            objWrapAudit.StatementDate = objAcc.Standard_Audit_Statement_Date__c;
                            objWrapAudit.PeriodStartDate = objAcc.Standard_Audit_Period_Start_Date__c;
                            objWrapAudit.PeriodEndDate = objAcc.Standard_Audit_Period_End_Date__c;
                            lstWrapperAccountAuditDetail.add(objWrapAudit);
                        }
                        if(objAcc.Code_Signing_Audit__c == strAuditURL){
                            isMatch = false;
                            WrapperAccountAuditDetail objWrapAudit = new WrapperAccountAuditDetail();
                            objWrapAudit.AuditType = 'Code Signing Audit';
                            objWrapAudit.AuditURL = strAuditURL;
                            objWrapAudit.StatementDate = objAcc.Code_Signing_Audit_Statement_Date__c;
                            objWrapAudit.PeriodStartDate = objAcc.Code_Signing_Audit_Period_Start_Date__c;
                            objWrapAudit.PeriodEndDate = objAcc.Code_Signing_Audit_Period_End_Date__c;
                            lstWrapperAccountAuditDetail.add(objWrapAudit);
                        }
                        if(objAcc.BR_Audit__c == strAuditURL){
                            isMatch = false;
                            WrapperAccountAuditDetail objWrapAudit = new WrapperAccountAuditDetail();
                            objWrapAudit.AuditType = 'BR Audit';
                            objWrapAudit.AuditURL = strAuditURL;
                            objWrapAudit.StatementDate = objAcc.BR_Audit_Statement_Date__c ;
                            objWrapAudit.PeriodStartDate = objAcc.BR_Audit_Period_Start_Date__c;
                            objWrapAudit.PeriodEndDate = objAcc.BR_Audit_Period_End_Date__c;
                            lstWrapperAccountAuditDetail.add(objWrapAudit);
                        }
                        if(objAcc.EV_Audit__c == strAuditURL){
                            isMatch = false;
                            WrapperAccountAuditDetail objWrapAudit = new WrapperAccountAuditDetail();
                            objWrapAudit.AuditType = 'EV SSL Audit';
                            objWrapAudit.AuditURL = strAuditURL;
                            objWrapAudit.StatementDate = objAcc.EV_Audit_Statement_Date__c;
                            objWrapAudit.PeriodStartDate = objAcc.EV_Audit_Period_Start_Date__c;
                            objWrapAudit.PeriodEndDate = objAcc.EV_Audit_Period_End_Date__c;
                            lstWrapperAccountAuditDetail.add(objWrapAudit);
                        }
                        if(objAcc.EV_Code_Signing_Audit__c == strAuditURL){
                            isMatch = false;
                            WrapperAccountAuditDetail objWrapAudit = new WrapperAccountAuditDetail();
                            objWrapAudit.AuditType = 'EV Code Signing Audit';
                            objWrapAudit.AuditURL = strAuditURL;
                            objWrapAudit.StatementDate = objAcc.EV_Code_Signing_Audit_Statement_Date__c ;
                            objWrapAudit.PeriodStartDate = objAcc.EV_Code_Signing_Audit_Period_Start_Date__c;
                            objWrapAudit.PeriodEndDate = objAcc.EV_Code_Signing_Audit_Period_End_Date__c;
                            lstWrapperAccountAuditDetail.add(objWrapAudit);
                        }
                        if(!isMatch){
                            objInnerWrapAcc.lstWrapperAuditDetail = lstWrapperAccountAuditDetail;
                            if(objAcc.RecordTypeId == intermediateCertRecordTypeId){
                                lstMissingAuditArchivesInterCerts.add(objInnerWrapAcc);
                            } else if(objAcc.RecordTypeId == rootCertRecordTypeId){
                                lstMissingAuditArchivesRootCerts.add(objInnerWrapAcc);
                            }
                        }
                    }
                }
            }
        }
        
        //create list of audit data integrity report
        if(mapAuditURLWiseFileArchive.size() > 0){
            for(string strAuditKey: mapAuditURLWiseFileArchive.keyset()){
                if(mapAuditURLWiseAccounts.containskey(strAuditKey)){
                    string strAuditURL = strAuditKey.split('#')[0];
                    WrapperAccounts objWrapAcc = new WrapperAccounts();
                    objWrapAcc.AuditURL = strAuditURL;
                    File_Archive__c objFA = mapAuditURLWiseFileArchive.get(strAuditKey);
                    objWrapAcc.objFileArchive = objFA;
                    List<WrapperInnerAccount> lstInnerInterCertsWrapper = new List<WrapperInnerAccount>();
                    List<WrapperInnerAccount> lstInnerRootWrapper = new List<WrapperInnerAccount>();
                    for(Account objAcc: mapAuditURLWiseAccounts.get(strAuditKey)){
                        WrapperInnerAccount objInnerWrapAcc = new WrapperInnerAccount();
                        objInnerWrapAcc.objAccount = objAcc;
                        List<WrapperAccountAuditDetail> lstWrapperAccountAuditDetail = new List<WrapperAccountAuditDetail>(); 
                        boolean isMatch = true;
                        if(objAcc.Standard_Audit__c == strAuditURL){
                            if(objFA.Audit_Statement_Date__c != objAcc.Standard_Audit_Statement_Date__c || 
                                    objFA.Period_Start_Date__c != objAcc.Standard_Audit_Period_Start_Date__c || 
                                    objFA.Period_End_Date__c != objAcc.Standard_Audit_Period_End_Date__c){
                                isMatch = false;
                                WrapperAccountAuditDetail objWrapAudit = new WrapperAccountAuditDetail();
                                objWrapAudit.AuditType = 'Standard Audit';
                                objWrapAudit.AuditURL = strAuditURL;
                                objWrapAudit.StatementDate = objAcc.Standard_Audit_Statement_Date__c;
                                objWrapAudit.PeriodStartDate = objAcc.Standard_Audit_Period_Start_Date__c;
                                objWrapAudit.PeriodEndDate = objAcc.Standard_Audit_Period_End_Date__c;
                                if(objFA.Audit_Statement_Date__c != objAcc.Standard_Audit_Statement_Date__c){
                                    objWrapAudit.isDiffStatementDate = true;
                                }
                                if(objFA.Period_Start_Date__c != objAcc.Standard_Audit_Period_Start_Date__c){
                                    objWrapAudit.isDiffPeriodStartDate = true;
                                }
                                if(objFA.Period_End_Date__c != objAcc.Standard_Audit_Period_End_Date__c){
                                    objWrapAudit.isDiffPeriodEndDate = true;
                                }
                                lstWrapperAccountAuditDetail.add(objWrapAudit);
                            }
                        }
                        
                        if(objAcc.Code_Signing_Audit__c == strAuditURL){
                            if(objFA.Audit_Statement_Date__c != objAcc.Code_Signing_Audit_Statement_Date__c || 
                                    objFA.Period_Start_Date__c != objAcc.Code_Signing_Audit_Period_Start_Date__c || 
                                    objFA.Period_End_Date__c != objAcc.Code_Signing_Audit_Period_End_Date__c){
                                isMatch = false;
                                WrapperAccountAuditDetail objWrapAudit = new WrapperAccountAuditDetail();
                                objWrapAudit.AuditType = 'Code Signing Audit';
                                objWrapAudit.AuditURL = strAuditURL;
                                objWrapAudit.StatementDate = objAcc.Code_Signing_Audit_Statement_Date__c;
                                objWrapAudit.PeriodStartDate = objAcc.Code_Signing_Audit_Period_Start_Date__c;
                                objWrapAudit.PeriodEndDate = objAcc.Code_Signing_Audit_Period_End_Date__c;
                                if(objFA.Audit_Statement_Date__c != objAcc.Code_Signing_Audit_Statement_Date__c){
                                    objWrapAudit.isDiffStatementDate = true;
                                }
                                if(objFA.Period_Start_Date__c != objAcc.Code_Signing_Audit_Period_Start_Date__c){
                                    objWrapAudit.isDiffPeriodStartDate = true;
                                }
                                if(objFA.Period_End_Date__c != objAcc.Code_Signing_Audit_Period_End_Date__c){
                                    objWrapAudit.isDiffPeriodEndDate = true;
                                }
                                lstWrapperAccountAuditDetail.add(objWrapAudit);
                            }
                        }
                        
                        if(objAcc.BR_Audit__c == strAuditURL){
                            if(objFA.Audit_Statement_Date__c != objAcc.BR_Audit_Statement_Date__c || 
                                    objFA.Period_Start_Date__c != objAcc.BR_Audit_Period_Start_Date__c || 
                                    objFA.Period_End_Date__c != objAcc.BR_Audit_Period_End_Date__c ){
                                isMatch = false;
                                WrapperAccountAuditDetail objWrapAudit = new WrapperAccountAuditDetail();
                                objWrapAudit.AuditType = 'BR Audit';
                                objWrapAudit.AuditURL = strAuditURL;
                                objWrapAudit.StatementDate = objAcc.BR_Audit_Statement_Date__c ;
                                objWrapAudit.PeriodStartDate = objAcc.BR_Audit_Period_Start_Date__c;
                                objWrapAudit.PeriodEndDate = objAcc.BR_Audit_Period_End_Date__c;
                                if(objFA.Audit_Statement_Date__c != objAcc.BR_Audit_Statement_Date__c){
                                    objWrapAudit.isDiffStatementDate = true;
                                }
                                if(objFA.Period_Start_Date__c != objAcc.BR_Audit_Period_Start_Date__c){
                                    objWrapAudit.isDiffPeriodStartDate = true;
                                }
                                if(objFA.Period_End_Date__c != objAcc.BR_Audit_Period_End_Date__c){
                                    objWrapAudit.isDiffPeriodEndDate = true;
                                }
                                lstWrapperAccountAuditDetail.add(objWrapAudit);
                            }
                        }
                        if(objAcc.EV_Audit__c == strAuditURL){
                            if(objFA.Audit_Statement_Date__c != objAcc.EV_Audit_Statement_Date__c || 
                                    objFA.Period_Start_Date__c != objAcc.EV_Audit_Period_Start_Date__c || 
                                    objFA.Period_End_Date__c != objAcc.EV_Audit_Period_End_Date__c){
                                isMatch = false;
                                WrapperAccountAuditDetail objWrapAudit = new WrapperAccountAuditDetail();
                                objWrapAudit.AuditType = 'EV SSL Audit';
                                objWrapAudit.AuditURL = strAuditURL;
                                objWrapAudit.StatementDate = objAcc.EV_Audit_Statement_Date__c;
                                objWrapAudit.PeriodStartDate = objAcc.EV_Audit_Period_Start_Date__c;
                                objWrapAudit.PeriodEndDate = objAcc.EV_Audit_Period_End_Date__c;
                                if(objFA.Audit_Statement_Date__c != objAcc.EV_Audit_Statement_Date__c){
                                    objWrapAudit.isDiffStatementDate = true;
                                }
                                if(objFA.Period_Start_Date__c != objAcc.EV_Audit_Period_Start_Date__c){
                                    objWrapAudit.isDiffPeriodStartDate = true;
                                }
                                if(objFA.Period_End_Date__c != objAcc.EV_Audit_Period_End_Date__c){
                                    objWrapAudit.isDiffPeriodEndDate = true;
                                }
                                lstWrapperAccountAuditDetail.add(objWrapAudit);
                            }
                        }
                        if(objAcc.EV_Code_Signing_Audit__c == strAuditURL){
                            if(objFA.Audit_Statement_Date__c != objAcc.EV_Code_Signing_Audit_Statement_Date__c || 
                                    objFA.Period_Start_Date__c != objAcc.EV_Code_Signing_Audit_Period_Start_Date__c || 
                                    objFA.Period_End_Date__c != objAcc.EV_Code_Signing_Audit_Period_End_Date__c){
                                isMatch = false;
                                WrapperAccountAuditDetail objWrapAudit = new WrapperAccountAuditDetail();
                                objWrapAudit.AuditType = 'EV Code Signing Audit';
                                objWrapAudit.AuditURL = strAuditURL;
                                objWrapAudit.StatementDate = objAcc.EV_Code_Signing_Audit_Statement_Date__c ;
                                objWrapAudit.PeriodStartDate = objAcc.EV_Code_Signing_Audit_Period_Start_Date__c;
                                objWrapAudit.PeriodEndDate = objAcc.EV_Code_Signing_Audit_Period_End_Date__c;
                                if(objFA.Audit_Statement_Date__c != objAcc.EV_Code_Signing_Audit_Statement_Date__c){
                                    objWrapAudit.isDiffStatementDate = true;
                                }
                                if(objFA.Period_Start_Date__c != objAcc.EV_Code_Signing_Audit_Period_Start_Date__c ){
                                    objWrapAudit.isDiffPeriodStartDate = true;
                                }
                                if(objFA.Period_End_Date__c != objAcc.EV_Code_Signing_Audit_Period_End_Date__c){
                                    objWrapAudit.isDiffPeriodEndDate = true;
                                }
                                lstWrapperAccountAuditDetail.add(objWrapAudit);
                            }
                        }
                        if(!isMatch){
                            objInnerWrapAcc.lstWrapperAuditDetail = lstWrapperAccountAuditDetail;
                            if(objAcc.RecordTypeId == intermediateCertRecordTypeId){
                                lstInnerInterCertsWrapper.add(objInnerWrapAcc);
                            } else if(objAcc.RecordTypeId == rootCertRecordTypeId){
                                lstInnerRootWrapper.add(objInnerWrapAcc);
                            }
                        }
                        
                    }
                    if(lstInnerInterCertsWrapper.size() > 0){
                        objWrapAcc.lstWrapperAccount = lstInnerInterCertsWrapper;
                        lstInconsistentInterCerts.add(objWrapAcc);
                    }
                    if(lstInnerRootWrapper.size() > 0){
                        objWrapAcc.lstWrapperAccount = lstInnerRootWrapper;
                        lstInconsistentRootCerts.add(objWrapAcc);
                    }
                }
            }
        }
    }
    /*
        Wrapper classes
    */
    public class WrapperAccounts {
        public string AuditURL {get; set;}
        public File_Archive__c objFileArchive {get; set;}
        public List<WrapperInnerAccount> lstWrapperAccount {get; set;}
    }
    
    public class WrapperInnerAccount {
        public Account objAccount {get; set;}
        public List<WrapperAccountAuditDetail> lstWrapperAuditDetail {get; set;}
    }
    
    public class WrapperAccountAuditDetail {
        public boolean isDiffStatementDate {get; set;}
        public boolean isDiffPeriodStartDate {get; set;}
        public boolean isDiffPeriodEndDate {get; set;}
        public string AuditURL {get; set;}
        public string AuditType {get; set;}
        public Date StatementDate {get; set;}
        public Date PeriodStartDate {get; set;}
        public Date PeriodEndDate {get; set;}
    }
}
/*******************************************************************************************************
 Name: AllCertificateRecordsReportController

 Dependencies: AllCertificateRecordsReportController, AllCertificateRecordsCSVFormat, 
 AllCertificateRecordsReportCtlrTest
 
 Description: This report generates list of all root and intermediate certs.

 Instructions: None

 *******************************************************************************************************
 Revision History:
 
     06/24/2017 - Created new
     11/20/2019 - Added Subordinate CA Owner field to the report
     05/26/2020 - Changed for CP/CPS fields and display links for Policy documents
     08/12/2020 - Updated code to user latest last update date for Policy documents
 ******************************************************************************************************/
 
public class AllCertificateRecordsReportController{

    public List<wrapperAccount> lstWrapperAccountSO {get; set;}  
    
    // constructor method for standard controller
    public AllCertificateRecordsReportController() {   
            lstWrapperAccountSO = new List<wrapperAccount>();              
            List<Account> accountSoLst =  [SELECT  
                                    CA_Owner__c,
                                    Id,
                                    Name,
                                    ParentId,
                                    Parent.Name,
                                    Parent.SHA_256_Fingerprint__c,
                                    RecordType.Name,
                                    Subordinate_CA_Owner__c,
                                    Revocation_Status__c,
                                    SHA_256_Fingerprint__c, 
                                    Audits_Same_as_Parent__c,
                                    Auditor_New__r.Name,
                                    Standard_Audit__c,
                                    Standard_Audit_Type__c, 
                                    Standard_Audit_Statement_Date__c,
                                    Standard_Audit_Period_Start_Date__c, 
                                    Standard_Audit_Period_End_Date__c,
                                    BR_Audit__c,
                                    BR_Audit_Type__c, 
                                    BR_Audit_Statement_Date__c,
                                    BR_Audit_Period_Start_Date__c, 
                                    BR_Audit_Period_End_Date__c, 
                                    EV_Audit__c,
                                    EV_Audit_Type__c, 
                                    EV_Audit_Statement_Date__c,
                                    EV_Audit_Period_Start_Date__c, 
                                    EV_Audit_Period_End_Date__c, 
                                    EV_Code_Signing_Audit__c,
                                    EV_Code_Signing_Audit_Type__c, 
                                    EV_Code_Signing_Audit_Statement_Date__c,
                                    EV_Code_Signing_Audit_Period_Start_Date__c, 
                                    EV_Code_Signing_Audit_Period_End_Date__c, 
                                    CP_CPS_Same_as_Parent__c,
                                    CP_CPS_Last_Updated_Date__c,
                                    Certificate_Policy_CP__c,
                                    Certification_Practice_Statement_CPS__c,
                                    Test_Website_Valid__c,
                                    Test_Website_Expired__c,
                                    Test_Website_Revoked__c,
                                    Technically_Constrained__c,
                                    Status__c,
                                    Microsoft_Status__c,
                                    (Select Id, Document_Link__c, Document_Type__c, Document_Last_Update_Date__c from Policy_Document_Associations_OnCert__r Where Is_Deleted__c = false
                                     Order by Document_Last_Update_Date__c desc) 
                                    FROM Account
                                    WHERE Name != '<Fill in Cert Name>' 
                                    AND RecordType.Name In ('Root Certificate','Intermediate Certificate')
                                    ORDER BY CA_Owner__c ASC, RecordType.Name DESC, Name ASC]; 
                                      
                                    
        // if we are generating a CSV file then we need to replace the double quotes in all text fields with null
        //ApexPages.currentPage().getUrl() != null && ApexPages.currentPage().getUrl().contains('CSV') - condition removed because no need - Sunil
        if((Test.isRunningTest() || (ApexPages.currentPage().getUrl() != null && ApexPages.currentPage().getUrl().contains('CSV'))) && accountSoLst !=null && accountSoLst.size() > 0)
        {
            for(Account accountSo : accountSoLst) {
                wrapperAccount objWrap = new wrapperAccount();
                if(accountSo.CA_Owner__c !=null && accountSo.CA_Owner__c.length() > 0) 
                    accountSo.CA_Owner__c = accountSo.CA_Owner__c.replace('"',''); 
                if(accountSo.Name !=null && accountSo.Name.length() > 0) 
                    accountSo.Name = accountSo.Name.replace('"',''); 
                if(accountSo.Subordinate_CA_Owner__c !=null && accountSo.Subordinate_CA_Owner__c.length() > 0) 
                    accountSo.Subordinate_CA_Owner__c = accountSo.Subordinate_CA_Owner__c.replace('"','');          
                if(accountSo.Auditor_New__r.Name !=null && accountSo.Auditor_New__r.Name.length() > 0) 
                    accountSo.Auditor_New__r.Name = accountSo.Auditor_New__r.Name.replace('"','');      
                /*if(accountSo.Certificate_Policy_CP__c !=null && accountSo.Certificate_Policy_CP__c.length() > 0) 
                    accountSo.Certificate_Policy_CP__c = accountSo.Certificate_Policy_CP__c.replace('"',''); 
                if(accountSo.Certification_Practice_Statement_CPS__c !=null && accountSo.Certification_Practice_Statement_CPS__c.length() > 0) 
                    accountSo.Certification_Practice_Statement_CPS__c = accountSo.Certification_Practice_Statement_CPS__c.replace('"',''); */
                
                string dateformat = 'yyyy.MM.dd';
                
                objWrap.objaccountSO = accountSo;
                if (accountSO.CP_CPS_Last_Updated_Date__c !=null) {
                   objWrap.accCPCPSLastUpdateddate = DateTime.NewInstance(accountSO.CP_CPS_Last_Updated_Date__c.year(),
                        accountSO.CP_CPS_Last_Updated_Date__c.month(), accountSO.CP_CPS_Last_Updated_Date__c.day()).format(dateformat);
                }
                string strCP = '';
                string strCPS = '';
                Date CPCPSDate;
                for(PolicyDocumentAssociation_On_Certificate__c PDAC: accountSo.Policy_Document_Associations_OnCert__r){
                    if(PDAC.Document_Type__c != null){
                        if(PDAC.Document_Type__c == 'CP'){
                            if(string.isnotblank(strCP)) strCP += '; ';
                            strCP += PDAC.Document_Link__c;
                        }
                        if(PDAC.Document_Type__c == 'CPS' || PDAC.Document_Type__c == 'CP/CPS'){
                            if(string.isnotblank(strCPS)) strCPS += '; ';
                            strCPS += PDAC.Document_Link__c;
                        }
                    }
                    if(CPCPSDate == null || PDAC.Document_Last_Update_Date__c  > CPCPSDate){
                        CPCPSDate = PDAC.Document_Last_Update_Date__c;
                    }
                } 
                
                objWrap.CP = strCP;
                objWrap.CPS = strCPS;
                if(CPCPSDate != null) {
                    objWrap.CPCPSLastUpdateddate = DateTime.NewInstance(CPCPSDate .year(),
                        CPCPSDate.month(), CPCPSDate.day()).format(dateformat);
                }
                if(accountSo.Standard_Audit_Statement_Date__c != null) {
                    objWrap.SAdate = DateTime.NewInstance(accountSo.Standard_Audit_Statement_Date__c.year(),
                        accountSo.Standard_Audit_Statement_Date__c.month(),accountSo.Standard_Audit_Statement_Date__c.day()).format(dateformat);
                }
                if(accountSo.Standard_Audit_Period_Start_Date__c != null) {
                    objWrap.SAstartdate = DateTime.NewInstance(accountSo.Standard_Audit_Period_Start_Date__c.year(),
                        accountSo.Standard_Audit_Period_Start_Date__c.month(),accountSo.Standard_Audit_Period_Start_Date__c.day()).format(dateformat);
                }
                if(accountSo.Standard_Audit_Period_End_Date__c != null) { 
                    objWrap.SAenddate = DateTime.NewInstance(accountSo.Standard_Audit_Period_End_Date__c.year(),
                        accountSo.Standard_Audit_Period_End_Date__c.month(),accountSo.Standard_Audit_Period_End_Date__c.day()).format(dateformat);
                }
                if(accountSo.BR_Audit_Statement_Date__c != null) {
                    objWrap.BRdate = DateTime.NewInstance(accountSo.BR_Audit_Statement_Date__c.year(),
                        accountSo.BR_Audit_Statement_Date__c.month(),accountSo.BR_Audit_Statement_Date__c.day()).format(dateformat);
                }    
                if(accountSo.BR_Audit_Period_Start_Date__c != null) {
                    objWrap.BRstartdate = DateTime.NewInstance(accountSo.BR_Audit_Period_Start_Date__c.year(),
                        accountSo.BR_Audit_Period_Start_Date__c.month(),accountSo.BR_Audit_Period_Start_Date__c.day()).format(dateformat);
                }
                if(accountSo.BR_Audit_Period_End_Date__c != null) {
                    objWrap.BRenddate = DateTime.NewInstance(accountSo.BR_Audit_Period_End_Date__c.year(),
                        accountSo.BR_Audit_Period_End_Date__c.month(), accountSo.BR_Audit_Period_End_Date__c.day()).format(dateformat);
                }    
                if(accountSo.EV_Audit_Statement_Date__c != null) {
                    objWrap.EVdate = DateTime.NewInstance(accountSo.EV_Audit_Statement_Date__c.year(),
                        accountSo.EV_Audit_Statement_Date__c.month(),accountSo.EV_Audit_Statement_Date__c.day()).format(dateformat);
                } 
                if(accountSo.EV_Audit_Period_Start_Date__c != null) {
                    objWrap.EVSSLstartdate = DateTime.NewInstance(accountSo.EV_Audit_Period_Start_Date__c.year(),
                        accountSo.EV_Audit_Period_Start_Date__c.month(), accountSo.EV_Audit_Period_Start_Date__c.day()).format(dateformat);
                }
                if(accountSo.EV_Audit_Period_End_Date__c != null) {
                    objWrap.EVSSLenddate = DateTime.NewInstance(accountSo.EV_Audit_Period_End_Date__c.year(),
                        accountSo.EV_Audit_Period_End_Date__c.month(),accountSo.EV_Audit_Period_End_Date__c.day()).format(dateformat);
                }
                if(accountSo.EV_Code_Signing_Audit_Statement_Date__c != null) {
                    objWrap.EVCodedate = DateTime.NewInstance(accountSo.EV_Code_Signing_Audit_Statement_Date__c.year(),
                        accountSo.EV_Code_Signing_Audit_Statement_Date__c.month(),accountSo.EV_Code_Signing_Audit_Statement_Date__c.day()).format(dateformat);
                } 
                if(accountSo.EV_Code_Signing_Audit_Period_Start_Date__c != null) {
                    objWrap.EVCodestartdate = DateTime.NewInstance(accountSo.EV_Code_Signing_Audit_Period_Start_Date__c.year(),
                        accountSo.EV_Code_Signing_Audit_Period_Start_Date__c.month(),accountSo.EV_Code_Signing_Audit_Period_Start_Date__c.day()).format(dateformat);
                }
                if(accountSo.EV_Code_Signing_Audit_Period_End_Date__c != null) {
                    objWrap.EVCodeenddate = DateTime.NewInstance(accountSo.EV_Code_Signing_Audit_Period_End_Date__c.year(),
                        accountSo.EV_Code_Signing_Audit_Period_End_Date__c.month(), accountSo.EV_Code_Signing_Audit_Period_End_Date__c.day()).format(dateformat);
                }
                /*if(accountSo.CP_CPS_Last_Updated_Date__c != null) {
                    objWrap.CPCPSLastUpdateddate = DateTime.NewInstance(accountSo.CP_CPS_Last_Updated_Date__c.year(),
                        accountSo.CP_CPS_Last_Updated_Date__c.month(), accountSo.CP_CPS_Last_Updated_Date__c.day()).format(dateformat);
                }*/
                    
                lstWrapperAccountSO.add(objWrap);
            } 
        }                                       
    }
  
     
    String CurrentDate = ' ';
 
    // Get current Datetime in long date format   

    public String getCurrentDate() {
        Datetime cDT = System.now();
        CurrentDate = cDT.format('MMMM d, yyyy');        
        return CurrentDate;        
    } 
    
    public class wrapperAccount {
    
        public string accCPCPSLastUpdateddate {get;set;}
    
        public Account objaccountSO {get; set;}
        public string CP {get; set;}
        public string CPS {get; set;}
        public string SAdate {get;set;}
        public string SAstartdate {get;set;}
        public string SAenddate {get;set;}
        public string BRdate {get;set;}
        public string BRstartdate {get;set;}
        public string BRenddate {get;set;}
        public string EVdate {get;set;}
        public string EVSSLstartdate {get;set;}
        public string EVSSLenddate {get;set;}
        public string EVCodedate {get;set;}
        public string EVCodestartdate {get;set;}
        public string EVCodeenddate {get;set;}
        public string CPCPSLastUpdateddate {get;set;}
        
        public wrapperAccount(){
            objaccountSO = new Account();
            SAdate = '';
            SAstartdate = '';
            SAenddate = '';
            BRdate = '';
            BRstartdate = '';
            BRenddate = '';
            EVdate = '';
            EVSSLstartdate = '';
            EVSSLenddate = '';
            EVCodedate = '';
            EVCodestartdate = '';
            EVCodeenddate = '';
            CPCPSLastUpdateddate = '';
            accCPCPSLastUpdateddate = '';
        }
    }    
}
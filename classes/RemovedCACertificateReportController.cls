/********************************************************************************************************************
  RemovedCACertificateReportController is a controller for RemovedCACertificateReport, RemovedCACertificateReportCSVFormat
  and RemovedCACertificateReportPEMCSV VF pages to lists Mozilla'd removed root certs. 
  Report name used is 'Mozilla Removed CA Certificate List' 
  
  8/12/2020 - Updated code changed consider CP links when document type is CP and CPS for CPS and CP/CPS for policy documents.
 *********************************************************************************************************************/

public class RemovedCACertificateReportController{

    public transient List<wrapAccounts> lstwrapAccounts {get; set;}
 
    //constructor method for standard controller
    public RemovedCACertificateReportController() {   
        lstwrapAccounts = new List<wrapAccounts>();           
        List<Account> accountSoLst =  [select  Parent.Name,
                            Certificate_Issuer_Organization__c,
                            Certificate_Issuer_Organizational_Unit__c,
                            Name,
                            SHA_256_Fingerprint__c, 
                            Certificate_Serial_Number__c, 
                            Valid_From_GMT__c, 
                            Valid_To_GMT__c,       
                            Subject_SPKI_SHA256__c,                                                                  
                            Public_Key_Algorithm__c,
                            Signature_Hash_Algorithm__c,
                            Trust_Bits__c,
                            EV_Policy_OID_s__c, 
                            Removal_Bug_No_or_Date__c,
                            Approval_Bug__c,
                            NSS_Release_When_First_Included__c,
                            Firefox_Release_When_First_Included__c,
                            NSS_Release_When_Removed__c,
                            Firefox_Release_When_Removed__c,
                            Mozilla_Applied_Constraints__c, 
                            Parent.Company_Website__c,
                            Parent.Geographic_Focus__c,
                            //Certificate_Policy_CP__c,
                            //Certification_Practice_Statement_CPS__c,
                            Standard_Audit__c,
                            BR_Audit__c, 
                            EV_Audit__c,
                            Auditor__c,
                            Standard_Audit_Type__c,
                            X_509_Certificate_PEM__c,
                            Comments__c,
                            (Select Id, Document_Link__c, Document_Type__c from Policy_Document_Associations_OnCert__r Where Is_Deleted__c = false
                                Order by Document_Last_Update_Date__c desc)  
                            from  Account
                            where Status__c In ('Removed') and RecordType.Name In ('Root Certificate')
                            order by Parent.Name, Name];
     
        //if we are generating a CSV file then we need to replace the double quotes in all text fields with null
        if(Test.isRunningTest() || (accountSoLst !=null && accountSoLst.size() > 0)){
            for(Account accountSo : accountSoLst){
                if(Test.isRunningTest() || ApexPages.currentPage().getUrl().contains('CSV')) { // additional Test.isRunningTest() for test class to work
                    if(accountSo.Parent.Name !=null && accountSo.Parent.Name.length() > 0) 
                        accountSo.Parent.Name = accountSo.Parent.Name.replace('"',''); 
                    if(accountSo.name !=null && accountSo.name.length() > 0) 
                        accountSo.name = accountSo.name.replace('"',''); 
                    if(accountSo.Certificate_Issuer_Organization__c !=null && accountSo.Certificate_Issuer_Organization__c.length() > 0) 
                        accountSo.Certificate_Issuer_Organization__c = accountSo.Certificate_Issuer_Organization__c.replace('"','');                                        
                    if(accountSo.Certificate_Issuer_Organizational_Unit__c !=null && accountSo.Certificate_Issuer_Organizational_Unit__c.length() > 0) 
                        accountSo.Certificate_Issuer_Organizational_Unit__c = accountSo.Certificate_Issuer_Organizational_Unit__c.replace('"','');  
                    if(accountSo.SHA_256_Fingerprint__c !=null && accountSo.SHA_256_Fingerprint__c.length() > 0) 
                        accountSo.SHA_256_Fingerprint__c = accountSo.SHA_256_Fingerprint__c.replace('"','');                  
                    if(accountSo.EV_Policy_OID_s__c !=null && accountSo.EV_Policy_OID_s__c.length() > 0) 
                        accountSo.EV_Policy_OID_s__c = accountSo.EV_Policy_OID_s__c.replace('"','');                   
                    if(accountSo.Removal_Bug_No_or_Date__c !=null && accountSo.Removal_Bug_No_or_Date__c.length() > 0) 
                        accountSo.Removal_Bug_No_or_Date__c = accountSo.Removal_Bug_No_or_Date__c.replace('"','');                       
                    if(accountSo.Approval_Bug__c !=null && accountSo.Approval_Bug__c.length() > 0) 
                        accountSo.Approval_Bug__c = accountSo.Approval_Bug__c.replace('"','');                                                      
                    if(accountSo.NSS_Release_When_First_Included__c !=null && accountSo.NSS_Release_When_First_Included__c.length() > 0) 
                        accountSo.NSS_Release_When_First_Included__c = accountSo.NSS_Release_When_First_Included__c.replace('"','');
                    if(accountSo.Firefox_Release_When_First_Included__c !=null && accountSo.Firefox_Release_When_First_Included__c.length() > 0) 
                        accountSo.Firefox_Release_When_First_Included__c = accountSo.Firefox_Release_When_First_Included__c.replace('"','');
                    if(accountSo.NSS_Release_When_Removed__c !=null && accountSo.NSS_Release_When_Removed__c.length() > 0) 
                        accountSo.NSS_Release_When_Removed__c = accountSo.NSS_Release_When_Removed__c.replace('"','');
                    if(accountSo.Firefox_Release_When_Removed__c !=null && accountSo.Firefox_Release_When_Removed__c.length() > 0) 
                        accountSo.Firefox_Release_When_Removed__c = accountSo.Firefox_Release_When_Removed__c.replace('"','');                    
                    /*if(accountSo.URL_to_Test_Website_or_Example_Cert__c !=null && accountSo.URL_to_Test_Website_or_Example_Cert__c.length() > 0) 
                    accountSo.URL_to_Test_Website_or_Example_Cert__c = accountSo.URL_to_Test_Website_or_Example_Cert__c.replace('"','');   */                
                    if(accountSo.Mozilla_Applied_Constraints__c !=null && accountSo.Mozilla_Applied_Constraints__c.length() > 0) 
                        accountSo.Mozilla_Applied_Constraints__c = accountSo.Mozilla_Applied_Constraints__c.replace('"','');                   
                    if(accountSo.Parent.Company_Website__c !=null && accountSo.Parent.Company_Website__c.length() > 0) 
                        accountSo.Parent.Company_Website__c = accountSo.Parent.Company_Website__c.replace('"','');
                    if(accountSo.Parent.Geographic_Focus__c !=null && accountSo.Parent.Geographic_Focus__c.length() > 0) 
                        accountSo.Parent.Geographic_Focus__c = accountSo.Parent.Geographic_Focus__c.replace('"','');                    
                    /*if(accountSo.Certificate_Policy_CP__c !=null && accountSo.Certificate_Policy_CP__c.length() > 0) 
                        accountSo.Certificate_Policy_CP__c = accountSo.Certificate_Policy_CP__c.replace('"','');                      
                    if(accountSo.Certification_Practice_Statement_CPS__c !=null && accountSo.Certification_Practice_Statement_CPS__c.length() > 0) 
                        accountSo.Certification_Practice_Statement_CPS__c = accountSo.Certification_Practice_Statement_CPS__c.replace('"','');  */                  
                    if(accountSo.Standard_Audit__c !=null && accountSo.Standard_Audit__c.length() > 0) 
                        accountSo.Standard_Audit__c = accountSo.Standard_Audit__c.replace('"','');
                    if(accountSo.BR_Audit__c !=null && accountSo.BR_Audit__c.length() > 0) 
                        accountSo.BR_Audit__c = accountSo.BR_Audit__c.replace('"','');
                    if(accountSo.EV_Audit__c !=null && accountSo.EV_Audit__c.length() > 0) 
                        accountSo.EV_Audit__c = accountSo.EV_Audit__c.replace('"','');                  
                    if(accountSo.Auditor__c !=null && accountSo.Auditor__c.length() > 0) 
                        accountSo.Auditor__c = accountSo.Auditor__c.replace('"',''); 
                    if(accountSo.Comments__c !=null && accountSo.Comments__c.length() > 0) 
                        accountSo.Comments__c = accountSo.Comments__c.replace('"',''); 
                }      
                //fill wrapper
                wrapAccounts wrapAcc = new wrapAccounts();
                string strCP = '';
                string strCPS = '';
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
                }  
                wrapAcc.objAccount = accountSo;
                wrapAcc.CP = strCP;
                wrapAcc.CPS = strCPS;
                lstwrapAccounts.add(wrapAcc);  
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
    
    public class wrapAccounts {
        public string CP {get; set;}
        public string CPS {get; set;}
        public Account objAccount {get; set;}
        public wrapAccounts(){
            CP = '';
            CPS = '';
            objAccount = new Account();
        }
    }
}
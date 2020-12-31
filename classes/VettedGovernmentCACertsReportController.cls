/*******************************************************************************************************
 Name: VettedGovernmentCACertsReportController

 Dependencies:  VettedGovernmentCACertsReportController controller class, VettedGovernmentCACertsReportCtrlTest, 
 VettedGovernmentCACertsReport, VettedGovernmentCACertsCSV, VettedGovernmentCACertsReportInternal vf pages

 Description: This report lists root certificates for which 'Vetted Government CA' is checked.
 
 Instructions:  None

 *******************************************************************************************************
 Revision History:
 
     7/9/2020 - Created new

 ******************************************************************************************************/
 
public without sharing class VettedGovernmentCACertsReportController {

    public transient List<wrapAccounts> lstwrapAccounts {get; set;}
 
    //constructor method for standard controller
    public VettedGovernmentCACertsReportController() {  
        lstwrapAccounts = new List<wrapAccounts>();
        List<Account> accountSoLst = [SELECT Name, 
                                             ParentId, 
                                             Parent.Name, 
                                             Parent.Company_Website__c, 
                                             Parent.Geographic_Focus__c,
                                             Valid_To_GMT__c,
                                             SHA_256_Fingerprint__c,
                                             Standard_Audit__c,
                                             Certificate_Policy_CP__c ,
                                             X_509_Certificate_PEM__c,
                                             Standard_Audit_Period_End_Date__c,
                                             Status__c, Microsoft_Status__c
                                             /*(Select Id, 
                                                    Document_Link__c, 
                                                    Document_Type__c 
                                            FROM Policy_Document_Associations_OnCert__r 
                                            WHERE Is_Deleted__c = false
                                            ORDER BY Document_Last_Update_Date__c desc)*/
                                      FROM Account
                                      WHERE RecordType.Name In ('Root Certificate')
                                      AND Vetted_Government_CA__c = True
                                      AND Valid_To_GMT__c >= Today
                                      ORDER BY Parent.Name, Name];
                                      
                                      /* Status__c In ('Included','Change Requested') */
                                      
       // if we are generating a CSV file then we need to replace the double quotes in all text fields with null
       if(Test.IsRunningTest() || (accountSoLst != null && accountSoLst.size() > 0)){
            for(Account accountSo : accountSoLst){
                if(ApexPages.currentPage().getUrl() != null && ApexPages.currentPage().getUrl().contains('CSV')){ 
                    if(accountSo.name !=null && accountSo.name.length() > 0) 
                        accountSo.name = accountSo.name.replace('"',''); 
                    if(accountSo.parent.name !=null && accountSo.parent.name.length() > 0) 
                        accountSo.parent.name = accountSo.parent.name.replace('"','');  
                    if(accountSo.X_509_Certificate_PEM__c!=null && accountSo.X_509_Certificate_PEM__c.length() > 0) 
                        accountSo.X_509_Certificate_PEM__c= accountSo.X_509_Certificate_PEM__c.replace('"','');
                }
                //fill wrapper
                wrapAccounts wrapAcc = new wrapAccounts();
                string strCP = accountSo.Certificate_Policy_CP__c;
                string strCPS = '';
                /*for(PolicyDocumentAssociation_On_Certificate__c PDAC: accountSo.Policy_Document_Associations_OnCert__r){
                    if(PDAC.Document_Type__c != null){
                        if(PDAC.Document_Type__c == 'CP' || PDAC.Document_Type__c == 'CP/CPS'){
                            if(string.isnotblank(strCP)) strCP += '; ';
                            strCP += PDAC.Document_Link__c;
                        }
                        if(PDAC.Document_Type__c == 'CPS' || PDAC.Document_Type__c == 'CP/CPS'){
                            if(string.isnotblank(strCPS)) strCPS += '; ';
                            strCPS += PDAC.Document_Link__c;
                        }
                    }
                } */ 
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
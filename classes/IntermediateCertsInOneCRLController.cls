/*******************************************************************************************************
 Name: IntermediateCertsInOneCRLController

 Dependencies: IntermediateCertsInOneCRLController, IntermediateCertsInOneCRLReport vf page,
 IntermediateCertsInOneCRLReportCSV vf page, IntermediateCertsInOneCRLControllerTest

 Description: This report generates list of intermediate certs which are in OneCRL.

 Instructions: None

 *******************************************************************************************************
 Revision History:
 
     11/19/2019 - Created new

 ******************************************************************************************************/
 
public class IntermediateCertsInOneCRLController{

    public transient List<Account> accountSoLst {get;set;}
    public List<wrapperAccount> lstWrapperAccountSO {get; set;} 
 
    //constructor method for standard controller
    public IntermediateCertsInOneCRLController() { 
    
        lstWrapperAccountSO = new List<wrapperAccount>();   
    
        accountSoLst = [SELECT Name, CA_Owner__c, Parent.Name, Record_Type_Name__c, 
                                        Certificate_Serial_Number__c, SHA_256_Fingerprint__c, 
                                        RFC_5280_Revocation_Reason_Code__c,
                                        Revocation_Status__c, Date_of_Revocation__c,
                                        Valid_To_GMT__c, Valid_To_YYYY_MMM_DD__c, CRL_URL_s__c, Alternate_CRL__c, 
                                        OneCRL_Bug_Number__c, Comments__c 
                                 FROM Account 
                                 WHERE Name != '<Fill in Cert Name>'
                                 AND   Record_Type_Name__c = 'Intermediate Certificate'
                                 AND   OneCRL_Status__c = 'Added to OneCRL'
                                 ORDER BY CA_Owner__c];  
                             
                             
         
        // if we are generating a CSV file then we need to replace the double quotes in all text fields with null
        // if((ApexPages.currentPage().getUrl().contains('CSV') && accountSoLst !=null && accountSoLst.size() > 0) || Test.IsRunningTest())
         if((Test.isRunningTest() || (ApexPages.currentPage().getUrl() != null && ApexPages.currentPage().getUrl().contains('CSV'))) && accountSoLst !=null && accountSoLst.size() > 0)       
         {
            for(Account accountSo : accountSoLst)
            {
                wrapperAccount objWrap = new wrapperAccount();
                
                if(accountSo.Name !=null && accountSo.Name.length() > 0) 
                    accountSo.Name = accountSo.Name.replace('"','');  
                if(accountSo.Parent.Name !=null && accountSo.Parent.Name.length() > 0) 
                    accountSo.Parent.Name = accountSo.Parent.Name.replace('"','');                  
                if(accountSo.CA_Owner__c!=null && accountSo.CA_Owner__c.length() > 0) 
                    accountSo.CA_Owner__c= accountSo.CA_Owner__c.replace('"',''); 
                if(accountSo.CRL_URL_s__c !=null && accountSo.CRL_URL_s__c.length() > 0) 
                    accountSo.CRL_URL_s__c= accountSo.CRL_URL_s__c.replace('"',''); 
                if(accountSo.Alternate_CRL__c !=null && accountSo.Alternate_CRL__c.length() > 0) 
                    accountSo.Alternate_CRL__c= accountSo.Alternate_CRL__c.replace('"','');                                                
                if(accountSo.Comments__c !=null && accountSo.Comments__c.length() > 0) 
                    accountSo.Comments__c= accountSo.Comments__c.replace('"','');  
                    
                // convert date fields for CSV file    
                objWrap.objaccountSO = accountSo;
                string dateformat ='MM/dd/yyyy';
                
                if(accountSo.Valid_To_GMT__c != null) {
                    objWrap.VTGMTdate = DateTime.NewInstance(accountSo.Valid_To_GMT__c.year(),
                                                          accountSo.Valid_To_GMT__c.month(),
                                                          accountSo.Valid_To_GMT__c.day()).format(dateformat);
                }
                
                if(accountSo.Date_of_Revocation__c != null) {
                    objWrap.DRdate = DateTime.NewInstance(accountSo.Date_of_Revocation__c.year(),
                                                          accountSo.Date_of_Revocation__c.month(),
                                                          accountSo.Date_of_Revocation__c.day()).format(dateformat);                                                                                  
                 }
                 
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
    
        public Account objaccountSO {get; set;}        
        public string DRdate {get;set;} 
        public string VTGMTdate {get;set;}      
        
        public wrapperAccount(){
            objaccountSO = new Account();
            DRdate = '';
            VTGMTdate = '';
        } 
    }          
}
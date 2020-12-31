/********************************************************************************************************************
  PublicInterCertsWithOutdatedAuditStCtlr is a controller for PublicInterCertsWithOutdatedAuditSt VF pages 
  to list intermediate certs ...
  
  Filtered By:
        CA Owner/Certificate Record Type equals Intermediate Certificate
        AND <Root Cert that it chains up to is in Mozilla's root store>
        AND Revocation Status not equal to Revoked,Parent Cert Revoked
        AND Valid To (GMT) greater than TODAY  <i.e. cert is not expired>
        AND Standard Audit Statement Date less than (TODAY - 1 year) <i.e. audits due>
        Sort by Standard Audit Statement Date, with oldest on top

  Report name used is 'Intermediate Certs With Outdated Audit Statements' 
  
  *** Revision History ***
  Create Date: 7/13/2018
  Update Date:
 *********************************************************************************************************************/

public class PublicInterCertsWithOutdatedAuditStCtlr{

    public transient List<Account> accountSoLst {get;set;}
 
    // constructor method for standard controller
    public PublicInterCertsWithOutdatedAuditStCtlr() { 
    
        accountSoLst = [SELECT Name, 
                           CA_Owner__c,
                           Standard_Audit__c,
                           Standard_Audit_Statement_Date__c,
                           Standard_Audit_Period_Start_Date__c,
                           Standard_Audit_Period_End_Date__c, 
                           BR_Audit__c,
                           BR_Audit_Statement_Date__c,
                           EV_Audit__c,
                           EV_Audit_Statement_Date__c                                                                    
                               FROM Account 
                               WHERE Name != '<Fill in Cert Name>'
                               AND Record_Type_Name__c = 'Intermediate Certificate'
                               AND Revocation_Status__c NOT IN ('Revoked', 'Parent Cert Revoked')
                               AND Valid_To_GMT__c > TODAY   
                               AND Standard_Audit_Statement_Date__c < LAST_N_DAYS:365
                               AND Root_Status__c IN  ('Included','Change Requested')                     
                                      ORDER BY Standard_Audit_Statement_Date__c];  
                                                 
         
         // if we are generating a CSV file then we need to replace the double quotes in all text fields with null
         /**  if((ApexPages.currentPage().getUrl().contains('CSV') && accountSoLst !=null && accountSoLst.size() > 0) || Test.IsRunningTest())
           {
              for(Account accountSo : accountSoLst)
              {
                  if(accountSo.Name !=null && accountSo.Name.length() > 0) 
                       accountSo.Name = accountSo.Name.replace('"','');              
                  if(accountSo.CA_Owner__c!=null && accountSo.CA_Owner__c.length() > 0) 
                       accountSo.CA_Owner__c= accountSo.CA_Owner__c.replace('"','');                                     
              }
          }  **/                  
    }
     
    String CurrentDate = ' ';
    
    // Get current Datetime in long date format   
    public String getCurrentDate() {
        Datetime cDT = System.now();
        CurrentDate = cDT.format('MMMM d, yyyy');
        return CurrentDate;
    }
}
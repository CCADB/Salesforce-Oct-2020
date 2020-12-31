/********************************************************************************************************************

  ProblemReportingMechanismsReportCtlr is a controller for ProblemReportingMechanismsReport VF pages. 
  Report name used is 'Mozilla Problem Reporting Mechanism Report'. Report lists Problem Reporting Mechanisms 
  info for all ca owner, root certs and intermediate cert records
  
 *********************************************************************************************************************/

public class ProblemReportingMechanismsReportCtlr{

    public transient List<Account> accountSoLst {get;set;}

    // constructor method for standard controller
    public ProblemReportingMechanismsReportCtlr() {   
                    
        List<Account> accSoLst =  [select Name,
                            Parent.Name,
                            Problem_Reporting_Mechanism__c                    
                            from  Account
                            where Status__c In ('Included','Change Requested','Provided by CA','Verified')
                            and   RecordType.Name In ('CA Owner','Root Certificate','Intermediate Certificate')
                            and   Name != '<Fill in Cert Name>'
                            order by Name]; 
       
       // filter records with non blank 'Problem_Reporting_Mechanism__c', which is long text field   
       accountSoLst = new List<Account>();          
       for(Account a : accSoLst)
       {
           if (a.Problem_Reporting_Mechanism__c != null && a.Problem_Reporting_Mechanism__c.length() > 0) {
               accountSoLst.add(a);
           }
       }                  
       
       // email obfuscation                      
       PreventEmailSpoofing(accountSoLst);                     
     
     
       // if we are generating a CSV file then we need to replace the double quotes in all text fields with null
       if((ApexPages.currentPage().getUrl().contains('CSV') && accountSoLst !=null && accountSoLst.size() > 0) || Test.IsRunningTest())
       {
          for(Account accountSo : accountSoLst)
          {
              if(accountSo.name !=null && accountSo.name.length() > 0) 
                   accountSo.name = accountSo.name.replace('"','');  
              if(accountSo.parent.name !=null && accountSo.parent.name.length() > 0) 
                   accountSo.parent.name = accountSo.parent.name.replace('"','');                                    
              if(accountSo.Problem_Reporting_Mechanism__c !=null && accountSo.Problem_Reporting_Mechanism__c.length() > 0) 
                   accountSo.Problem_Reporting_Mechanism__c= accountSo.Problem_Reporting_Mechanism__c.replace('"','');                         
          }
       } 
   } 
 
    // Find email and replace @ with [at] and . with [dot]
    public static void PreventEmailSpoofing(List<Account> lstAccounts) {
        Pattern emailPattern = Pattern.compile('([a-zA-Z0-9_\\-\\.]+)@(((\\[a-z]{1,3}\\.[a-z]{1,3}\\.[a-z]{1,3}\\.)|(([a-zA-Z0-9\\-]+\\.)+))([a-zA-Z]{2,4}|[0-9]{1,3}))');
        
        for(Account objAcc: lstAccounts){
            if(objAcc.Problem_Reporting_Mechanism__c != null){
               
                Matcher emailMatcher = emailPattern.matcher(objAcc.Problem_Reporting_Mechanism__c);
                
                while (emailMatcher.find()) {  // loop until no more emails to transform 
                
                    string emailmatch = emailMatcher.group();
                    string newemailmatch = emailmatch.replace('@','[at]').replace('.','[dot]');
                    string emailString = objAcc.Problem_Reporting_Mechanism__c;
                    objAcc.Problem_Reporting_Mechanism__c = emailString.replace(emailmatch,newemailmatch);
                }               
                
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
}
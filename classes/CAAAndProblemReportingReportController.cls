/********************************************************************************************************************
  THIS CONTROLLER CLASS IS NOT IN USE. IT HAS BEEN REPLACED BY CAInformationReportController
  CAAAndProblemReportingReportController is a controller for CAAAndProblemReportingReport VF pages to list CA Owners. 
  Report name used is 'Mozilla CAA Domains & Problem Reporting Mechanism'. 
  
 *********************************************************************************************************************/

public class CAAAndProblemReportingReportController{

public List<Account> accountSoLst {get;set;}
 
    // constructor method for standard controller
    public CAAAndProblemReportingReportController() {   
                                                                  
           accountSoLst =  [select  Name,
                                    Organizational_Type__c,
                                    Geographic_Focus__c,
                                    Primary_Market_Customer_Base__c,
                                    Company_Website__c,
                                    Recognized_CAA_Domains__c,
                                    Problem_Reporting_Mechanism__c                    
                             from  Account
                             where Status__c In ('Included','Change Requested') and RecordType.Name In ('CA Owner')
                             order by Name];  
                            
          PreventEmailSpoofing(accountSoLst);                     
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
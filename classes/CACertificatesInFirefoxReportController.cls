/********************************************************************************************************************

  CACertificatesInFirefoxReportController is a controller for CACertificatesInFirefoxReport
   VF pages to list root certificates. Report name used is
  'CA Certificates In Firefox'. 
  
*********************************************************************************************************************/

public class CACertificatesInFirefoxReportController{

    public transient List<Account> accountSoLst {get;set;}
 
    //constructor method for standard controller
    public CACertificatesInFirefoxReportController() {   
        accountSoLst =  [select  Parent.Name,                                   
                                    Name,                                   
                                    Valid_To_YYYY_MMM_DD__c,                                  
                                    Trust_Bits__c,                                    
                                    Firefox_Release_When_First_Included__c,                                   
                                    Parent.Company_Website__c,
                                    Parent.Geographic_Focus__c,                                   
                                    Comments__c  
                                    from  Account
                                    where Status__c In ('Included','Change Requested') 
                                    and RecordType.Name In ('Root Certificate')
                                    and Trust_Bits__c Includes ('Websites')
                                    order by Parent.Name, Name];
    }
  
     
    String CurrentDate = ' ';
 
    // Get current Datetime in long date format   
    public String getCurrentDate() {
        Datetime cDT = System.now();
        CurrentDate = cDT.format('MMMM d, yyyy');
        return CurrentDate;
    }
}
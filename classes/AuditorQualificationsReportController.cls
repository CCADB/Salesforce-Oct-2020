/********************************************************************************************************************

  AuditorQualificationsReportController is a controller for AuditorQualificationsReport VF pages to list all 
  Auditors and Auditor Locations. Report name used is'Auditor Qualifications Report'. 
  
 *********************************************************************************************************************/

public class AuditorQualificationsReportController{

    public transient List<Auditor_Location__c> auditorAndLocationSoLst {get;set;}
    
    // constructor method for standard controller
    public AuditorQualificationsReportController() {   
    
        auditorAndLocationSoLst =  [SELECT Auditor__r.Name, 
                                    Auditor__r.Auditor_Website__c,
                                    Auditor_Location__c.Name, 
                                    Auditor_Location__c.Auditor_Qualifications__c,
                                    Auditor_Location__c.Comments__c
                                    FROM Auditor_Location__c
                                    ORDER BY Auditor__r.Name, Name];   
    }
    
    String CurrentDate = ' ';
    // Get current Datetime in long date format   
    public String getCurrentDate() {
    
        Datetime cDT = System.now();
        CurrentDate = cDT.format('MMMM d, yyyy');
        return CurrentDate;
    }
}
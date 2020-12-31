/*
    Description: Controller is created to display Summary audit reminder report
*/
public with sharing class AuditReminderSummaryOnlyController {
    
    public AuditReminderSummaryOnlyController (){}
    
    // var which holds the exception message
    public String errorText {get;set;}
 
    //method which executes the batch job
    public void startBatch(){
        errorText = ' ';
        // Pass send summary email as true. As we need to send only summary email to Mozilla CA Program Manager (from org wide settings)
        Database.executeBatch(new AuditReminderBatch(true, false),1);
    }
    
    // method which executes the batch job
    public void startBatchToUpdateAuditAlert(){
        errorText = ' ';
        //pass both as false.
        Database.executeBatch(new AuditReminderBatch(false, false),1);
    }
}
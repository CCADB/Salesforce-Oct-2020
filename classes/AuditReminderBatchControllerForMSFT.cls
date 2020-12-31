/*
    this is the controller class for the RunAuditReminderBatcForMSFTh VF page. 
    
    Controller is used in RunAuditReminderSummaryMSFT VF page and run batch only to send summary email.
*/
public class AuditReminderBatchControllerForMSFT{

    // var which holds the exception message
    public String errorText {get;set;}
    
    // method which executes the batch job
    public void startBatch(){
        errorText = ' ';
        Database.executeBatch(new AuditReminderBatchForMSFT(true),1);
    }
    
    // method which executes the batch job for summary email
    public void startSummaryBatch(){
        errorText = ' ';
        Database.executeBatch(new AuditReminderBatchForMSFT(false),1);
    }
}
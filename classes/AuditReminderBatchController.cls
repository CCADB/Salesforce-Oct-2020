// this is the controller class for the RunAuditReminderBatch VF page. 
public class AuditReminderBatchController{

    // var which holds the exception message
    public String errorText {get;set;}
    
    // method which executes the batch job
    public void startBatch(){
        errorText = ' ';
        //pass Send Email to CA and Summary as true to it will send emails to CA and also sends summary email.
        Database.executeBatch(new AuditReminderBatch(false, true),1);
    }
    
    // method which executes the batch job
    public void startBatchToUpdateAuditAlert(){
        errorText = ' ';
        //pass both as false.
        Database.executeBatch(new AuditReminderBatch(false, false),1);
    }
}
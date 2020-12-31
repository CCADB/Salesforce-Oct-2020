/*
    Controller is created for VF page to run Audit Reminder for Out dates Intermediate Certs.
*/
public with sharing class AuditReminderICWithOutdatedAuditStCtrl {

    public String errorText { get; set; }

    public PageReference startBatch() {
        errorText = ' ';
        Id batchId = Database.executeBatch(new AuditReminderICWithOutdatedAuditStBatch(true), 1);
        System.debug('batchId: '+batchId);
        return null;
    }
    
    //method which executes the batch job to update audit alert
    public void startBatchToUpdateAuditAlert(){
        errorText = ' ';
        //pass both as false.
        Id batchId = Database.executeBatch(new AuditReminderICWithOutdatedAuditStBatch(false), 1);
    }

}
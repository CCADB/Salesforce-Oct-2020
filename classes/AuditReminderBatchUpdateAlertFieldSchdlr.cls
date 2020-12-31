/*******************************************************************************************************
 Name: AuditReminderBatchUpdateAlertFieldSchdlr
 
 Dependencies: AuditReminderBatch class, AuditReminderBatchHelper class, AuditReminderMailWrapper class,
 RunAuditReminderBatch VF page, RunAuditReminderSummaryOnly VF page,
 
 Description: This schedular class is run daily to update 'Mozilla Audit Alert' field on all root 
 certificate records. It calls the common logic in audit reminder batch program to dertermine which
 root are about to expire, expired or in danger of being removed. When 'AuditReminderBatch' is called, 
 pass 'false' for both parameters (SendSummaryEmailOnly, SendEmailToCAAndSummary) so that summary email 
 and alert emails are not sent out.
 
 By updating 'Mozilla Audit Alert', it makes it easy for users to use the field in standard reports. 
 
 Instructions: To schedule this Apex class use the developer console and run 
 AuditReminderBatchUpdateAlertFieldSchdlr.scheduleMe('Mozilla: Audit Reminder Batch Update Alert Field');
   
 *******************************************************************************************************
 Revision History:
 
     2/27/2019 - Created new class
 ******************************************************************************************************/


global class AuditReminderBatchUpdateAlertFieldSchdlr implements Schedulable{
 
   public static String sched = '0 0 4 * * ? *';  // every day 4 AM.
  
   global static String scheduleMe(String jobNameStr) {
        AuditReminderBatchUpdateAlertFieldSchdlr SC = new AuditReminderBatchUpdateAlertFieldSchdlr(); 
        return System.schedule(jobNameStr, sched, SC);
    }

    global void execute(SchedulableContext sc) {
        //we don't need to send any emails so both flag are false.
        AuditReminderBatch b1 = new AuditReminderBatch(false, false);  // 'false' is for summary emails and alert emails
        ID batchprocessid = Database.executeBatch(b1,1);           
    }
}
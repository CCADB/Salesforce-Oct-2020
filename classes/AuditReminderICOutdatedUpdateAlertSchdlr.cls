/*******************************************************************************************************
 Name: AuditReminderICOutdatedUpdateAlertSchdlr 
 
 Dependencies: AuditReminderICWithOutdatedAuditStBatch class, AuditReminderICWithOutdatedAuditStHelper class, 
 AuditReminderMailWrapper class,AuditReminderICWithOutdatedAuditStCtrl class, RunAuditReminderICWithOutdatedAuditSt VF page
 
 Description: This schedular class is run daily to update 'Mozilla Audit Alert' field on all intermediate
 certificate records. It calls the common logic in audit reminder batch program to dertermine which
 intermediate are outdated. When 'AuditReminderICWithOutdatedAuditStBatch' is called, 
 pass 'false' for (SendEmailToCAAndSummary) so that summary email 
 and alert emails are not sent out.
 
 By updating 'Mozilla Audit Alert', it makes it easy for users to use the field in standard reports. 
 
 Instructions: To schedule this Apex class use the developer console and run 
 AuditReminderICOutdatedUpdateAlertSchdlr.scheduleMe('Mozilla: Audit Reminder Batch Update Alert Field For Intermediate Certs Daily');
   
 *******************************************************************************************************
 Revision History:
 
     2/28/2019 - Created new class
 ******************************************************************************************************/
global class AuditReminderICOutdatedUpdateAlertSchdlr implements Schedulable{
   
   public static String sched = '0 0 5 * * ? *';  // every day 5 AM.
   
   global static String scheduleMe(String jobNameStr) {
        AuditReminderICOutdatedUpdateAlertSchdlr SC = new AuditReminderICOutdatedUpdateAlertSchdlr(); 
        return System.schedule(jobNameStr, sched, SC);
    }

    global void execute(SchedulableContext sc) {
        AuditReminderICWithOutdatedAuditStBatch b1 = new AuditReminderICWithOutdatedAuditStBatch(false);
        ID batchprocessid = Database.executeBatch(b1,10);           
    }
}
global class AuditReminderICWithOutdatedAuditStSchd implements Schedulable{
 
   // To schedule this Apex class use the developer console and run AuditReminderICWithOutdatedAuditStSchd.scheduleMe('Mozilla: Run Audit Reminder For OutDated Inter Certs Batch on First Tuesday of Every Month');
   // To test from Developer Console, run following statemnts ...
   //     AuditReminderICWithOutdatedAuditStBatch b1 = new AuditReminderICWithOutdatedAuditStBatch();
   //     ID batchprocessid = Database.executeBatch(b1,10);   

   public static String sched = '0 0 7 ? * 3#1';       // every first Tuesday at 7AM
   
   global static String scheduleMe(String jobNameStr) {
        AuditReminderICWithOutdatedAuditStSchd SC = new AuditReminderICWithOutdatedAuditStSchd(); 
        return System.schedule(jobNameStr, sched, SC);
    }

    global void execute(SchedulableContext sc) {
        AuditReminderICWithOutdatedAuditStBatch b1 = new AuditReminderICWithOutdatedAuditStBatch(true);
        ID batchprocessid = Database.executeBatch(b1,10);           
    }
}
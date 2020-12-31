global class AuditReminderForICAuditCPCPSBScheduler implements Schedulable{
 
   // To schedule this Apex class use the developer console and run AuditReminderForICAuditCPCPSBScheduler.scheduleMe('Mozilla: Run Audit Reminder For Inter Certs Batch on 1st Sunday of Every Month');
   
   public static String sched = '0 0 7 ? * SUN#1';       // every first Sunday at 7AM
   
   global static String scheduleMe(String jobNameStr) {
        AuditReminderForICAuditCPCPSBScheduler SC = new AuditReminderForICAuditCPCPSBScheduler(); 
        return System.schedule(jobNameStr, sched, SC);
    }

    global void execute(SchedulableContext sc) {

        AuditReminderForICAuditCPCPSBatch b1 = new AuditReminderForICAuditCPCPSBatch();
        ID batchprocessid = Database.executeBatch(b1,10);           
    }
}
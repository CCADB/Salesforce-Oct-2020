global class AuditReminderForICAuditCPCPSBScheduler1 implements Schedulable{
 
   // To schedule this Apex class use the developer console and run AuditReminderForICAuditCPCPSBScheduler1.scheduleMe('Mozilla: Run Audit Reminder For Inter Certs Batch on 3st Sunday of Every Month');
   
   public static String sched = '0 0 7 ? * SUN#3';       // every third Sunday at 7AM
   
   global static String scheduleMe(String jobNameStr) {
        AuditReminderForICAuditCPCPSBScheduler1 SC = new AuditReminderForICAuditCPCPSBScheduler1(); 
        return System.schedule(jobNameStr, sched, SC);
    }

    global void execute(SchedulableContext sc) {

        AuditReminderForICAuditCPCPSBatch b1 = new AuditReminderForICAuditCPCPSBatch();
        ID batchprocessid = Database.executeBatch(b1,10);           
    }
}
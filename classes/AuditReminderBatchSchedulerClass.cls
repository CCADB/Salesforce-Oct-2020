global class AuditReminderBatchSchedulerClass implements Schedulable{
 
   // To schedule this Apex class use the developer console and run AuditReminderBatchSchedulerClass.scheduleMe('Mozilla: Audit Reminder Batch');
   
   public static String sched = '0 0 12 ? * TUE#3';  // 3rd Tuesday of Every month
  
   global static String scheduleMe(String jobNameStr) {
        AuditReminderBatchSchedulerClass  SC = new AuditReminderBatchSchedulerClass(); 
        return System.schedule(jobNameStr, sched, SC);
    }

    global void execute(SchedulableContext sc) {
        //pass Send Email to CA and Summary as true to it will send emails to CA and also sends summary email.
        AuditReminderBatch b1 = new AuditReminderBatch(false, true);
        ID batchprocessid = Database.executeBatch(b1,1);           
    }
}
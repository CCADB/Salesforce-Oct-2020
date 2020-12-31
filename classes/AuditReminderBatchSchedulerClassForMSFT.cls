global class AuditReminderBatchSchedulerClassForMSFT implements Schedulable{
   
   // To schedule this Apex class use the developer console and run AuditReminderBatchSchedulerClassForMSFT.scheduleMe('Microsoft: Audit Reminder Batch');
   
   public static String sched = '0 0 12 ? * MON#4';  // 4th Monday of Every month
  
   global static String scheduleMe(String jobNameStr) {
        AuditReminderBatchSchedulerClassForMSFT  SC = new AuditReminderBatchSchedulerClassForMSFT(); 
        return System.schedule(jobNameStr, sched, SC);
    }

    global void execute(SchedulableContext sc) {

        AuditReminderBatchForMSFT b1 = new AuditReminderBatchForMSFT(true);
        ID batchprocessid = Database.executeBatch(b1,10);           
    }
}
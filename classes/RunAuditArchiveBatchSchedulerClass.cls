global class RunAuditArchiveBatchSchedulerClass implements Schedulable{
   
   // To schedule this Apex class use the developer console and run RunAuditArchiveBatchSchedulerClass.scheduleMe('Run Audit Archive Batch');
   
   public static String sched = '0 0 6 ? * SUN';  // every Sunday at 6AM
   
   global static String scheduleMe(String jobNameStr) {
        RunAuditArchiveBatchSchedulerClass  SC = new RunAuditArchiveBatchSchedulerClass(); 
        return System.schedule(jobNameStr, sched, SC);
    }

    global void execute(SchedulableContext sc) {

        RunAuditArchiveBatch b1 = new RunAuditArchiveBatch();
        ID batchprocessid = Database.executeBatch(b1,1);           
    }
}
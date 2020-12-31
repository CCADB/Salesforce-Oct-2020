/*
    Description: Created Schedular class to Run ALV for Intermediate certs.
    // To schedule this Apex class use the developer console and run RunALVForInterCertsBatchSchedulerClass.scheduleMe('Run ALV for Inter Certs Batch');
*/
global with sharing class RunALVForInterCertsBatchSchedulerClass implements Schedulable {
    
    public static String sched = '0 30 1 ? * *';  // every day at 1:30AM
   
    global static String scheduleMe(String jobNameStr) {
        RunALVForInterCertsBatchSchedulerClass SC = new RunALVForInterCertsBatchSchedulerClass(); 
        return System.schedule(jobNameStr, sched, SC);
    }

    global void execute(SchedulableContext sc) {
        RunALVForInterCertsBatch b1 = new RunALVForInterCertsBatch('');
        ID batchprocessid = Database.executeBatch(b1,1);           
    }
}
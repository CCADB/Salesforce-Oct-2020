/*
    Description: Schedular class for updating Revocation Verification
    
     *****To schedule this Apex class use the developer console and run ***
    RunVerifyRevocationSchedulerClass.scheduleMe('Run Batch To Verify Revocation - Daily 5:30AM');
*/
global class RunVerifyRevocationSchedulerClass implements Schedulable, Database.AllowsCallouts{
   
    public static String sched = '0 30 5 ? * *';  // everyday at 5:30 AM 
   
    global static String scheduleMe(String jobNameStr) {
        RunVerifyRevocationSchedulerClass SC = new RunVerifyRevocationSchedulerClass(); 
        return System.schedule(jobNameStr, sched, SC);
    }

    global void execute(SchedulableContext sc) {
        RunBatchToVerifyRevocation batch = new RunBatchToVerifyRevocation('');
        Database.executeBatch(batch,1);
    }
    
}
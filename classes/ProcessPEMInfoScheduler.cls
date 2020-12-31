global class ProcessPEMInfoScheduler implements Schedulable{

    public static String sched = '0 0 * * * ?';  //Run every hour
    
    // To schedule this Apex class use the developer console and run ProcessPEMInfoScheduler.scheduleMe('ProcessPEMInfoBatch');
  
   global static String scheduleMe(String jobNameStr) {
        ProcessPEMInfoScheduler SC = new ProcessPEMInfoScheduler (); 
        return System.schedule(jobNameStr, sched, SC);
    }

    global void execute(SchedulableContext sc) {

        ProcessPEMInfoBatch b1 = new ProcessPEMInfoBatch();
        ID batchprocessid = Database.executeBatch(b1,50);           
    }
}
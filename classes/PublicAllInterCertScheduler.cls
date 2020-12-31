global class PublicAllInterCertScheduler implements Schedulable{

    public static String sched = '0 0 * * * ?';  //Run every hour
    
    // To schedule this Apex class use the developer console and run PublicAllInterCertScheduler.scheduleMe('PublicAllInterCertsBatch');
  
   global static String scheduleMe(String jobNameStr) {
        PublicAllInterCertScheduler SC = new PublicAllInterCertScheduler (); 
        return System.schedule(jobNameStr, sched, SC);
    }

    global void execute(SchedulableContext sc) {

        PublicAllIntermediateCertsBatch b1 = new PublicAllIntermediateCertsBatch();
        ID batchprocessid = Database.executeBatch(b1,1);           
    }
}
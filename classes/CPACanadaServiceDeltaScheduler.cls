/*******************************************************************************************************
 Name: CPACanadaServiceDeltaScheduler

 Dependencies: CPACanadaServiceController, CPACanadaServiceDeltaBatch, 
 CPACanadaServiceAllScheduler, CPACanadaServiceDeltaScheduler, CPACanadaServiceControllerTest

 Description: Scheduler class for get Delta CPACAnada Files
 
 Class is created for call API to get CPA Canada report file urls and update in Salesforce.
  
 Instructions:  
 
    RUN CODE FROM CONSOLE
    //It calls batch for delta, if count doesn't match then auto runs job and sync all files.
    CPACanadaServiceDeltaScheduler.scheduleMe('CPACanada Sync Delta Files - Daily 1PM');
  
    
 *******************************************************************************************************
 Revision History:
 
     2/19/2019 - Created new class
     4/19/2019 - Updated class to scheduled on every 1 PM. Removed schedule to run on 1 AM.
     
 ******************************************************************************************************/
 
global class CPACanadaServiceDeltaScheduler implements Schedulable{
 
   public static String sched1 = '0 0 13 ? * *'; //Everyday 1 PM
  
   global static String scheduleMe(String jobNameStr) {
        CPACanadaServiceDeltaScheduler SC = new CPACanadaServiceDeltaScheduler(); 
        return System.schedule(jobNameStr, sched1, SC);
    }

    global void execute(SchedulableContext sc) {
        //CPACanadaServiceController.getDeltaCPACanadaFiles(); 
        CPACanadaServiceDeltaBatch batch = new CPACanadaServiceDeltaBatch();
        Database.executebatch(batch, 1);
    }
}
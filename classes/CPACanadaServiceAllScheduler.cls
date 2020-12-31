/*******************************************************************************************************
 Name: CPACanadaServiceAllScheduler

 Dependencies: CPACanadaServiceController, CPACanadaServiceDeltaBatch, 
 CPACanadaServiceAllScheduler, CPACanadaServiceDeltaScheduler, CPACanadaServiceControllerTest

 Description: Scheduler class for get All CPACAnada Files
 
 Class is created for call API to get CPA Canada report file urls and update in Salesforce.
  
 Instructions:  
 
    RUN CODE FROM CONSOLE
    CPACanadaServiceAllScheduler.scheduleMe('CPACanada Sync All Files - Daily 1 AM');
  
    
 *******************************************************************************************************
 Revision History:
 
     2/19/2019 - Created new class
     4/19/2019 - Updated class to scheduled on every 1 AM. Removed schedule to run on every sunday 6 AM.
     
 ******************************************************************************************************/
 
 
global class CPACanadaServiceAllScheduler implements Schedulable{
 
   public static String sched = '0 0 1 ? * *'; //Everyday 1 AM
  
   global static String scheduleMe(String jobNameStr) {
        CPACanadaServiceAllScheduler SC = new CPACanadaServiceAllScheduler(); 
        return System.schedule(jobNameStr, sched, SC);
    }

    global void execute(SchedulableContext sc) {
        CPACanadaServiceController.getAllCPACanadaFiles(); 
    }
}
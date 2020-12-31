/*******************************************************************************************************
 Name: RunDoppelgangerBatchSchedulerClass

 Dependencies:  RunBatchToUpdateDoppelganger controller class, RunDoppelgangerBatchSchedulerClass,
 RunBatchProcessesController, RunBatchToUpdateConstrainedDoppelganger, RunBatchToUpdateDoppelgangerTest,
 AccountMessageInlineController, AccountMessageInlinePage, 
 CommonMethods, CommonMethodsTest,
 RunBatchProcesses, RunBatchProcessesController

 Description: Schedular class is created To run batch job to update Non Constrained Doppelganger
 
 
    Batch program was created to update 'Non-constrained Doppelganger?' flag.

    The program processes All Intermeidate Cert where 
        Subject_SPKI_SHA256 != null and
        Technically_Constrained = TRUE and
        Valid_To_GMT > TODAY and
        Revocation_Status = Not Revoked
        
    For each Intermediate cert we are checking if there is a doppelganger intermediate certs (match on Subject_SPKI_SHA256)
    then the flag is checked.
    
    AccountInline vf page displays the message to indicate existance of non constrained Doppelganger cert if the
    'Non-constrained Doppelganger?' flag is checked.
 
 Instructions: To schedule this batch use the following command from Dev Console:
  
    RunDoppelgangerBatchSchedulerClass.scheduleMe('Run Non Constrained Doppelganger Batch');
    
    Also, 'Batch Processes' tab allows user to run this process anytime from a button.

 *******************************************************************************************************
 Revision History:
 
     9/6/2019 - Created new

     
 ******************************************************************************************************/
global class RunDoppelgangerBatchSchedulerClass implements Schedulable{
   
   public static String sched = '0 0 1 ? * *'; // Everyday 1 AM
   
   global static String scheduleMe(String jobNameStr) {
        RunDoppelgangerBatchSchedulerClass SC = new RunDoppelgangerBatchSchedulerClass(); 
        return System.schedule(jobNameStr, sched, SC);
    }

    global void execute(SchedulableContext sc) {
        RunBatchToUpdateDoppelganger b1 = new RunBatchToUpdateDoppelganger('');
        ID batchprocessid = Database.executeBatch(b1,50);   //can't make batch size bigger as we are doing SOQL in loop.         
    }
}
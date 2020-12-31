/*******************************************************************************************************
 Name: RunBatchProcessesController

 Dependencies:  RunBatchProcessesController controller class, RunBatchProcesses VF page, 
 RunBatchProcessesControllerTest test class

 Description: Common controller to run any batch processes.

 Instructions: Can be accessed from 'Batch Processes' custom VF tab
    
 *******************************************************************************************************
 Revision History:
 
     7/9/2019 - Created new
     11/8/2019 - Added method to run batch to populate EV OIDs
 ******************************************************************************************************/

public with sharing class RunBatchProcessesController {
    
    public RunBatchProcessesController(){
        
    }
    
    public void RunALVBatch(){
        RunALVForInterCertsBatch batch = new RunALVForInterCertsBatch('');
        Database.executebatch(batch,1);
    }
    
    public void RunBatchToUpdateDoppelganger(){
        RunBatchToUpdateDoppelganger batch = new RunBatchToUpdateDoppelganger('');
        Database.executeBatch(batch,50);
    }
    
    public void RunBatchToUpdateEVOIDs(){
        RunBatchToUpdateEVOIDs batch = new RunBatchToUpdateEVOIDs();
        Database.executebatch(batch);
    }
    
    public void RunVerifyRevocationBatch(){
        RunBatchToVerifyRevocation batch = new RunBatchToVerifyRevocation('');
        Database.executeBatch(batch,1);
    }
    
    public void RunBatchToUpdateUserFields(){
        Database.executeBatch(new RunBatchToClearPIIonUser ());
    }
}
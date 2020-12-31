/*
    Test class for RunBatchProcessesController
*/
@isTest
public with sharing class RunBatchProcessesControllerTest {
    
    static testmethod void testRunALVBatch(){
        RunBatchProcessesController controller = new RunBatchProcessesController();
        controller.RunALVBatch();
    }
    
    static testmethod void testDoppelgangerbatch(){
        RunBatchProcessesController controller = new RunBatchProcessesController();
        controller.RunBatchToUpdateDoppelganger();
    }
    
    static testmethod void testPopulateOIDs(){
        RunBatchProcessesController controller = new RunBatchProcessesController();
        controller.RunBatchToUpdateEVOIDs();
    }
    
    static testmethod void testVerifyRevocation(){
        RunBatchProcessesController controller = new RunBatchProcessesController();
        controller.RunVerifyRevocationBatch();
    }
    
    static testmethod void testUserUpdate(){
        RunBatchProcessesController controller = new RunBatchProcessesController();
        controller.RunBatchToUpdateUserFields();
    }
}
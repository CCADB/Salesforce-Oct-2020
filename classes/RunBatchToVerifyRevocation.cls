/*******************************************************************************************************
 Name: RunBatchToVerifyRevocation

 Dependencies: RunBatchToVerifyRevocation class, VerifyRevocationController, VerifyRevocationControllerTest,
 RunVerifyRevocationSchedulerClass

 Description: Batch Program is created to update Revocation Verification field on revoked Intermediate certs
 but does not make changes to Mozilla OneCRL Status.
 The callouts are made from VerifyRevocationController to a tool to process intermediate certs with 
 Revocation_Status__c = 'Revoked' and and Revocation_Verification__c  = null. 
 
 This batch can also be executed from 'Batch Processes' custom tab.
 
 Instructions: To run this batch use the dev console and execute the following:
               RunBatchToVerifyRevocation batch = new RunBatchToVerifyRevocation('');
               Database.executeBatch(batch,1);
 
 *******************************************************************************************************
 Revision History:
 
     11/18/2019 - Created new class
                 
 ******************************************************************************************************/
 
global class RunBatchToVerifyRevocation implements Database.Batchable<Sobject>, Database.AllowsCallouts {
    global final String Query;
    
    global RunBatchToVerifyRevocation (String q){
        if(string.isnotblank(q)){
            Query = q;
        } else {
            Query = 'SELECT Id FROM Account ' +
                    'WHERE RecordType.Name = \'Intermediate Certificate\' AND Revocation_Status__c = \'Revoked\'' +
                    'AND Revocation_Verification__c  = null ';
        }
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC){
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext BC, List<Account> lstAccounts){
        if(lstAccounts.size() == 1) {
            VerifyRevocationController controller = new VerifyRevocationController(new Apexpages.standardcontroller(lstAccounts[0]));
            controller.CallAPIToVerifyRevocation();
        }   
    }
    
    global void finish(Database.BatchableContext BC){
    
    }
}
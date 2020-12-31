/*******************************************************************************************************
 Name: RunBatchToUpdateDoppelganger

 Dependencies:  RunBatchToUpdateDoppelganger controller class, RunDoppelgangerBatchSchedulerClass,
 RunBatchProcessesController, RunBatchToUpdateConstrainedDoppelganger, RunBatchToUpdateDoppelgangerTest,
 AccountMessageInlineController, AccountMessageInlinePage, 
 CommonMethods, CommonMethodsTest,
 RunBatchProcesses, RunBatchProcessesController

 Description: Batch program was created to update 'Non-constrained Doppelganger?' flag.

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
 
global class RunBatchToUpdateDoppelganger implements Database.Batchable<Sobject> {
    static Date dttoday = system.today(); 
    global final String Query = 'SELECT Id, Name, CA_Owner__c, ' +
               'Subject_SPKI_SHA256__c,Has_Non_constrained_Doppelganger__c ' +
               'FROM Account ' +
               'WHERE RecordType.Name = \'Intermediate Certificate\' AND Subject_SPKI_SHA256__c != null AND Technically_Constrained__c = TRUE ' + 
               'AND Valid_To_GMT__c >: dttoday AND Revocation_Status__c = \'Not Revoked\''; //'';
    
    global RunBatchToUpdateDoppelganger (String q){
        if(string.isnotblank(q)){
            Query = q;
        }
        //system.debug('Query  ::: '+Query );
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC){
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext BC, List<Account> lstAccounts){
        if(lstAccounts.size() > 0){
            List<Account> lstAccToUpdate = new List<Account>();
            for(Account objAcc: lstAccounts){
                List<Account> lstSameSubjectSPKI = CommonMethods.getSameSubjectSPKIInterCerts(objAcc.Subject_SPKI_SHA256__c);
                if(lstSameSubjectSPKI.size() > 0){
                    Account acc = new Account(Id = objAcc.Id);
                    acc.Has_Non_constrained_Doppelganger__c = true;
                    lstAccToUpdate.add(acc);
                }
            }
            if(lstAccToUpdate.size() > 0){
                update lstAccToUpdate;
            }
        }
    }
    
    global void finish(Database.BatchableContext BC){
    
    }
    
}
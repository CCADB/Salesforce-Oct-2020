/*
    Description: Batch program to parse PEM info using PEMParserController
    
    If PEM info (x509 field) is not null then add to the batch processing
*/

global class PEMParserBatch implements Database.Batchable<sObject>,Database.AllowsCallouts{

    global final String Query;
    
    global PEMParserBatch(String q){
        Query = q;
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC){
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext BC, List<Account> lstAccounts){
        List<Account> lstAccToUpdate = new List<Account>();
        for(Account acc: lstAccounts){
            if(acc.X_509_Certificate_PEM__c != null) {
                Account objAccToUpdate = new Account();
                objAccToUpdate = PEMParserController.parsePEM(acc.X_509_Certificate_PEM__c); 
                objAccToUpdate.Id = acc.Id;
                lstAccToUpdate.add(objAccToUpdate);
            }
        }
        if(lstAccToUpdate.size() > 0){
            update lstAccToUpdate;
        }
    }
    
    global void finish(Database.BatchableContext BC){
    }
}
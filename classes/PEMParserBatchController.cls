/*
    Description: PEMParserBatchController is used to Run Batch from VF page.
*/
public with sharing class PEMParserBatchController {
    public String errorText { get; set; }
    public PageReference startBatch() {
        errorText = ' ';
        Id batchId = Database.executeBatch(new PEMParserBatch('select Id,Name,X_509_Certificate_PEM__c from Account Where RecordType.DeveloperName = \'Root_Certificate\' or RecordType.DeveloperName = \'Intermediate_Certificate\''), 1);
        System.debug('batchId: '+batchId);
        return null;
    }
}
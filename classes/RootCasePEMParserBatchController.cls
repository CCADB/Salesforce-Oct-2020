/*
    Description: PEMParserBatchController is used to Run Batch from VF page.
*/
public with sharing class RootCasePEMParserBatchController {
    
    public String errorText { get; set; }
    
    public PageReference startBatch() {
        errorText = ' ';
        Id batchId = Database.executeBatch(new RootCasePEMParserBatch('select Id,Name,X_509_Certificate_PEM__c from Root_Case__c Where RecordType.DeveloperName = \'CA_Root_Inclusion_Request\''), 1);
        System.debug('batchId: '+batchId);
        return null;
    }
}
public with sharing class RunAuditArchiveBatchController {

    public String errorText { get; set; }

    public PageReference startBatch() {
        
        errorText = ' ';
        Id batchId = Database.executeBatch(new RunAuditArchiveBatch(), 1);
        System.debug('batchId: '+batchId);
        return null;
    }

}
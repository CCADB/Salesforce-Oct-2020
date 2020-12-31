trigger RootCaseTrigger on Root_Case__c (before insert, before update, after insert, after update) {
// Trigger for the case object which handles all the events and based on the event delegates the task 
// to the corresponding trigger handler method in the CaseTriggerHelper class

    if(trigger.isBefore){
        
       RootCaseTriggerHelper.SetDefaultForCAOwnerRootInclusionRequest(Trigger.New);
       RootCaseTriggerHelper.SetAllFieldsVerifiedField(Trigger.New);
       
       if(trigger.isInsert) {
        
           RootCaseTriggerHelper.defaultFieldsRootCaseInsert(Trigger.New);
           // RootCaseTriggerHelper.SetAccountStatusField(Trigger.New);             
           RootCaseTriggerHelper.EnforceRequestStatusRulesForInserts(Trigger.New);
           
       }
        
       if(trigger.isUpdate) {
          
           RootCaseTriggerHelper.defaultFieldsOnRootCertificateChange(Trigger.New, Trigger.OldMap);
           RootCaseTriggerHelper.EnforceRequestStatusRulesForUpdates(Trigger.New, Trigger.OldMap); 
           RootCaseTriggerHelper.EnforceValidationForInclusionRootCases(Trigger.New, Trigger.OldMap);
       }        
    }
    
    if(Trigger.isAfter){
        
        if(Trigger.isUpdate){
           RootCaseTriggerHelper.rollupRootCaseStatusToCase(Trigger.New, Trigger.OldMap);
           RootCaseTriggerHelper.RollUpCaseStatusForRootInclusion(Trigger.New, Trigger.OldMap);
        }
        
        //update mozilla status and microsoft status for root certs.
        RootCaseTriggerHelper.updateStatusOnCase(Trigger.New, Trigger.OldMap, Trigger.isUpdate); 
        
        //Sharing Root Case
        //RootCaseTriggerHelper.ManualRootCaseSharing(Trigger.New); 
        
        //update audit gaps
        RootCaseTriggerHelper.UpdateAuditGaps(Trigger.New, Trigger.OldMap, Trigger.IsInsert);
        
        //validate test websites.
        RootCaseTriggerHelper.ValidateTestWebites(Trigger.New, Trigger.Oldmap, Trigger.IsInsert, Trigger.IsUpdate);
    }
}
// Trigger for the case object which handles all the events and based on the event delegates the task 
// to the corresponding trigger handler method in the accountTriggerHelper class

trigger AccountTrigger on Account (before insert, before update, after insert, after update, before delete) {
    
    if(!AccountTriggerHelper.isRecursiveUpdate) {
        if(trigger.isBefore){
            
            if(trigger.isInsert) {
                AccountTriggerHelper.SetAccountStatusFieldOnInsert(Trigger.New);
                AccountTriggerHelper.validateParentAccountForIntermediateCA(Trigger.new);
                //uncommented as request given to check only audit period end date when audit are same.
                AccountTriggerHelper.checkAuditInfoWhenSameLink(Trigger.New);//      not needed
                AccountTriggerHelper.ClearAuditFieldsWhenAuditSameAsParent(Trigger.New);
                AccountTriggerHelper.ReplaceCPACanadaURLs(Trigger.New);
                AccountTriggerHelper.UpdateDerivedTrustBits(Trigger.New, Trigger.OldMap, Trigger.isInsert, Trigger.isUpdate);
                AccountTriggerHelper.UpdateOwnerWhenAccountCreatedFromCA(Trigger.New);
            }
            
            if(trigger.isUpdate){
                AccountTriggerHelper.validateParentAccountForIntermediateCA(Trigger.new);
                //uncommented as request given to check only audit period end date when audit are same.
                AccountTriggerHelper.checkAuditInfoWhenSameLink(Trigger.New); //      not needed
                AccountTriggerHelper.ClearAuditFieldsWhenAuditSameAsParent(Trigger.New);
                AccountTriggerHelper.ReplaceCPACanadaURLs(Trigger.New);
                AccountTriggerHelper.UpdateDerivedTrustBits(Trigger.New, Trigger.OldMap, Trigger.isInsert, Trigger.isUpdate);
                //make ALV date processed blank
                AccountTriggerHelper.UpdateALVDateProcessed(Trigger.New, Trigger.OldMap);
                //make Revocation Verification blank
                AccountTriggerHelper.UpdateRevocationVerification(Trigger.New, Trigger.OldMap);
            }       
        }
        
        //trigger will be called for After Insert & before insert and update, only for single record, bulk request is not supported.
        if(Trigger.size == 1 && !Trigger.isDelete && ((Trigger.isAfter && Trigger.isInsert) || Trigger.isBefore)){
            
            Account oldAccount = null;
            if(!Trigger.isInsert){
                oldAccount = Trigger.oldMap.get(Trigger.new[0].Id);
            }
            AccountTriggerHelper.updateCAOwnerFields(Trigger.new[0], oldAccount);
        }
        
        if(Trigger.size == 1 && Trigger.isDelete && Trigger.isBefore){
            //system.debug('Trigger.old: '+Trigger.old);
            String errorMessage = AccountTriggerHelper.checkDeleteValidation(Trigger.old[0]);
            
            if(errorMessage != null){
                Trigger.old[0].addError(errorMessage);    
            }
        }
        
        //populate policy identifiers
        if(trigger.isAfter && trigger.isUpdate){
            AccountTriggerHelper.UpdatePolicyIdentifierOnCAOwner(trigger.new, trigger.oldmap);
        }
        
       /* if(trigger.isAfter && (trigger.isUpdate || trigger.isInsert) && !AccountTriggerHelper.isAccountTriggerRunning)
        {
          AccountTriggerHelper.isAccountTriggerRunning = true;
          AccountTriggerHelper.extract509CertificateAfterUpdate(trigger.old,trigger.new,trigger.oldMap,trigger.newMap);
        }*/
        //Code added by Sunil
        if(trigger.isAfter && trigger.IsInsert) {
            AccountManualShareTriggerHelper.ManualAccountSharing(trigger.New);
            AccountManualShareTriggerHelper.TransferOwnerAndManualSharingForInternalUsers(Trigger.New);
            //AuditProgramFutureTesting.CopyFileArchiveRecords(Trigger.New, Trigger.Oldmap);
        }
        //When Owner has changed - re create sharing
        if(trigger.isAfter && trigger.isUpdate){
            AccountManualShareTriggerHelper.UpdateManualSharingOwnerChanged(trigger.new, trigger.oldmap);
        }
        //download audit files and create file archive records.   
        if(trigger.isAfter && (trigger.IsUpdate || trigger.isInsert)) {
            FileArchiveFutureCallForAccount.UpdateFileArchiveOnAuditDateChange(Trigger.New, Trigger.Oldmap);
            FileArchiveFutureCallForAccount.CreateFileArchiveRecords(Trigger.New, Trigger.Oldmap);
        }
    }
}
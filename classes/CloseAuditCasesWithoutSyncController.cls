/*
    Description: class is used for closeing case
*/
public with sharing class CloseAuditCasesWithoutSyncController {
    
    //flag is used to show case complete section
    public boolean isCaseComplete {get; set;}
    
    //Reason to enter close case
    public string ReasontoCloseCase {get; set;}
    
    //case id
    Id caseid; 
    
    public CloseAuditCasesWithoutSyncController(ApexPages.StandardController controller) {
        caseid = controller.getId();
        
        List<Case> lstCase = new List<Case>([select Id, Request_Status__c, Status from Case Where Id =: caseid]);
        
        //check if case status is complete then set flag to true
        if(lstCase.size() > 0 && lstCase[0].Request_Status__c == 'Complete'){
            isCaseComplete = true;
        }
    }
    
    //method is used to close case and update reason
    public PageReference CloseCaseWithoutSync(){
        try {
            //check if reason is not blank then it should close case
            if(string.isnotblank(ReasontoCloseCase)){
                List<Root_Case__c> lstRootcases = new List<Root_Case__c>([select Id, Request_Status__c from 
                        Root_Case__c Where Case_No__c =: caseid]);
                for(Root_Case__c objRC: lstRootcases){
                    objRC.Request_Status__c = 'Complete';
                }
                if(lstRootcases.size() > 0){
                    //ignore case triggers.
                    CaseTriggerHelper.isCaseRecursive = true;
                    update lstRootcases;
                }
                Case objcase = new Case();
                objcase.Id = caseid;
                objcase.Request_Status__c = 'Complete';
                objcase.Reason_for_Close_without_Sync__c = ReasontoCloseCase;
                objcase.Status = 'Closed';
                update objcase;
                return new PageReference('/'+caseid);
            } else {
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error,'Please enter reason to close case without syncing.'));
                return null;
            }
        } catch (exception ex){
            apexpages.addMessages(ex);
            return null;
        }
    }
    
}
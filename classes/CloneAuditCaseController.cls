/*
    Description: Class is created to clone audit case
    All case fields get copied except audit links, aududitor location, statuses, ALV fields, 
    Authenticity confirmation, description & comments.
*/
public with sharing class CloneAuditCaseController {
    
    public Id CaseId;
    
    public CloneAuditCaseController(Apexpages.StandardController ctrl) {
        CaseId = ctrl.getId();
    }
    
    public PageReference CloneAuditCase(){
        Id ClonedCaseId = null;
        try {
            DescribeSObjectResult describeResult = CaseId.getSObjectType().getDescribe();
            
            List<String> fieldNames = new List<String>( describeResult.fields.getMap().keySet() );
    
            String query = ' SELECT ' + String.join( fieldNames, ',' ) +
                  ' FROM Case WHERE ' + ' id = :CaseId ' + ' LIMIT 1 ';
    
            // return generic list of sobjects or typecast to expected type
            List<Case> lstCases = Database.query( query );
            
            Case objClonedCase = lstCases[0].Clone(false);
             
             
            objClonedCase.Request_Status__c = 'Initial Request Received';   
                     
            objClonedCase.Auditor_Verified__c = 'Not Verified';
            
            // objClonedCase.Auditor_New__c = '';
            // objClonedCase.Auditor_Location_New__c = null;
            
            objClonedCase.Standard_Audit_Statement_Link__c = '';
            objClonedCase.Standard_Audit_Authenticity_Confirmed__c = false;
            objClonedCase.Standard_Audit_Auto_Review_Status__c = '';           
            objClonedCase.Standard_Audit_Auto_Review_Results__c = '';
            objClonedCase.Standard_Audit_ALV_Comments__c = '';
            objClonedCase.Standard_Deviation__c = False;
            objClonedCase.Standard_Deviation_Comments__c = '';
            objClonedCase.Standard_Audit_Verified__c = 'Not Verified';
            
            objClonedCase.Code_Signing_Audit_Statement_Link__c = '';
            objClonedCase.Code_Signing_Audit_Authenticity_Confirm__c = false;
            objClonedCase.Code_Signing_Audit_ALV_Status__c = '';
            objClonedCase.Code_Signing_Audit_ALV_Results__c = '';
            objClonedCase.Code_Signing_Audit_ALV_Comments__c = ''; 
            objClonedCase.Code_Signing_Deviation__c = False;
            objClonedCase.Code_Signing_Deviation_Comments__c = '';
            objClonedCase.Code_Signing_Audit_Verified__c = 'Not Verified';
            
            objClonedCase.BR_Audit_Statement_Link__c = '';
            objClonedCase.BR_Audit_Authenticity_Confirmed__c = false;
            objClonedCase.BR_Audit_Auto_Review_Status__c = '';
            objClonedCase.BR_Audit_Auto_Review_Results__c = '';
            objClonedCase.BR_Audit_ALV_Comments__c = ''; 
            objClonedCase.BR_Deviation__c = False;
            objClonedCase.BR_Deviation_Comments__c = '';
            objClonedCase.BR_Audit_Statement_Link_Verified__c = 'Not Verified';  
            
            objClonedCase.EV_Audit_Statement_Link__c = '';        
            objClonedCase.EV_SSL_Audit_Authenticity_Confirmed__c = false;
            objClonedCase.EV_SSL_Audit_Auto_Review_Status__c = '';
            objClonedCase.EV_SSL_Audit_Auto_Review_Results__c = '';
            objClonedCase.EV_SSL_Audit_ALV_Comments__c = ''; 
            objClonedCase.EV_SSL_Deviation__c = False;
            objClonedCase.EV_SSL_Deviation_Comments__c = '';
            objClonedCase.EV_Audit_Statement_Link_Verified__c = 'Not Verified';
             
            objClonedCase.EV_Code_Signing_Audit_Statement_Link__c = '';           
            objClonedCase.EV_Code_Signing_Audit_Auth_Confirmed__c = false;
            objClonedCase.EV_Code_Signing_Audit_AutoReviewStatus__c = '';
            objClonedCase.EV_Code_Signing_Audit_AutoReviewResults__c = '';
            objClonedCase.EV_Code_Signing_Audit_ALV_Comments__c = '';
            objClonedCase.EV_Code_Signing_Deviation__c = False;
            objClonedCase.EV_Code_Signing_Deviation_Comments__c = '';
            objClonedCase.EV_Code_Signing_Verified__c = 'Not Verified';
            
            objClonedCase.CP_CPS_Links_Verified__c = 'Not Verified';
            
            objClonedCase.Status = 'Open'; 
            objClonedCase.Description = ''; 
            objClonedCase.Comments__c = ''; 
            objClonedCase.Internal_Comments_on_Case__c = ''; 
            objClonedCase.Latest_Case_Comment__c = '';
            
            insert objClonedCase;
            ClonedCaseId = objClonedCase.Id;
        } catch (Exception ex) {
            Apexpages.addmessages(ex);
            return null;
        }
        return new PageReference('/'+ClonedCaseId);
    }
}
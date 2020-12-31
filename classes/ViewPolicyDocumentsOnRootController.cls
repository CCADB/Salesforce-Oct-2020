/*
    Description:Controller is created to ViewPolicyDocumentsOnRoot
*/
public without sharing class ViewPolicyDocumentsOnRootController {
    
    public List<Policy_Document_On_Certificate__c> lstPolicyDocumentsOnCertificates {get; set;}
    public boolean isShowDeleted {get; set;}
    public Account objRootCertificate {get; set;}
    
    public ViewPolicyDocumentsOnRootController (Apexpages.standardcontroller controller){
        Id rootID = controller.getID();
        isShowDeleted = false;
        List<Account> lstAccounts = new List<Account>([select Id, Name, ParentId, Parent.Document_Repository__c, 
                    Parent.Document_Repository_Description__c from Account Where Id =: rootId]);
        
        if(lstAccounts.size() > 0){
            objRootCertificate = lstAccounts[0];
            set<Id> setOfPolicyDocIds = new set<Id>();
            List<PolicyDocumentAssociation_On_Certificate__c> lstPolicyDocumentAssociations = new List<PolicyDocumentAssociation_On_Certificate__c>([select 
                        Id, Policy_Document__c from PolicyDocumentAssociation_On_Certificate__c Where Certificate_Name__c =: objRootCertificate.Id]);
            for(PolicyDocumentAssociation_On_Certificate__c PDA: lstPolicyDocumentAssociations){
                setOfPolicyDocIds.add(PDA.Policy_Document__c);
            }
            
            lstPolicyDocumentsOnCertificates = new List<Policy_Document_On_Certificate__c>([select Id, Name, Associated_Trust_Bits__c, Is_Deleted__c,
                        Comments__c, Document_Last_Updated_Date__c, Document_Link__c, Document_Type__c,Policy_Identifiers__c
                        //(Select Id, Name, Certificate_Name__c,Policy_Document__c from Policy_Document_Associations__r)
                        FROM Policy_Document_On_Certificate__c 
                        WHERE Id =: setOfPolicyDocIds Order by Document_Last_Updated_Date__c desc]);
            
        }
        
    }
    
}
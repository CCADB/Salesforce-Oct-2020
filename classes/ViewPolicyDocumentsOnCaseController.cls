/*
    Description:Controller is created to ViewPolicyDocumentsOnCase
*/
public without sharing class ViewPolicyDocumentsOnCaseController {
    
    public List<Policy_Document_On_Case__c> lstPolicyDocumentsOnCases {get; set;}
    public List<Policy_Document_Association_On_Case__c> lstPDAssociations {get; set;}
    public boolean isShowDeleted {get; set;}
    public Case objCase{get; set;}
    
    public ViewPolicyDocumentsOnCaseController (Apexpages.standardcontroller controller){
        Id caseId = controller.getID();
        isShowDeleted = false;
        List<Case> lstCases = new List<Case>([select Id, CaseNumber, AccountId, 
                    Policy_Documentation__c, CA_Document_Repository__c,
                    Account.Document_Repository__c, 
                    Account.Document_Repository_Description__c from Case Where Id =: caseId]);
        
        if(lstCases.size() > 0){
            objCase = lstCases [0];
            
            lstPolicyDocumentsOnCases = new List<Policy_Document_On_Case__c>([select Id, Name, Associated_Trust_Bits__c, Action__c,
                        Comments__c, Document_Last_Updated_Date__c, Document_Link__c, Document_Type__c,Policy_Identifiers__c,
                        (Select Id, Name, Certificate_Name__c,Certificate_Name__r.Name, Certificate_Name__r.Status__c,
                        Certificate_Name__r.Microsoft_Status__c, Certificate_Name__r.SHA_256_Fingerprint__c,
                        Policy_Document__c,Action__c from Policy_Document_Associations__r), Document_Verified__c
                        FROM Policy_Document_On_Case__c
                        WHERE Case__c =: objCase.Id Order by Document_Last_Updated_Date__c desc]);
            
        }
    }
    
    public void BindAssociations(){
        lstPDAssociations  = new List<Policy_Document_Association_On_Case__c>();
        if(apexpages.currentpage().getparameters().get('index') != null){
            Integer index = integer.valueof(apexpages.currentpage().getparameters().get('index'));
            if(lstPolicyDocumentsOnCases.size() > index){
                lstPDAssociations = lstPolicyDocumentsOnCases[index].Policy_Document_Associations__r;
            }
        }
    }
}
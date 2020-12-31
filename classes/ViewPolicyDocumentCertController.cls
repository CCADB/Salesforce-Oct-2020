/*
    Controller is created to View Policy Document Certs
*/
public without sharing class ViewPolicyDocumentCertController {
    
    public boolean isShowDeleted {get; set;}
    public Policy_Document_On_Certificate__c PDCertificate {get; set;}
    public List<PolicyDocumentAssociation_On_Certificate__c> lstAssociationsRecords {get; set;}
    public List<Policy_Document_History__c> lstPDHistories {get; set;}
    
    public ViewPolicyDocumentCertController(apexpages.standardcontroller controller){
        Id pdId = controller.getId();
        isShowDeleted = true;
        List<Policy_Document_On_Certificate__c> lstPDC = new List<Policy_Document_On_Certificate__c>([select Id, Name,
                    Document_Type__c,Document_Link__c, Document_Last_Updated_Date__c,Associated_Trust_Bits__c,
                    Comments__c, Policy_Identifiers__c, Is_Deleted__c    
                    FROM Policy_Document_On_Certificate__c Where Id =: pdId Order by Document_Last_Updated_Date__c desc]);
        if(lstPDC.size() > 0){
            PDCertificate = lstPDC[0];
        }
        lstAssociationsRecords = new List<PolicyDocumentAssociation_On_Certificate__c>([Select Id,Name,
                    Certificate_Name__c, Certificate_Name__r.Name, Certificate_Name__r.SHA_256_Fingerprint__c,
                    Is_Deleted__c, Certificate_Name__r.Status__c, Certificate_Name__r.Microsoft_Status__c, 
                    Certificate_Name__r.Valid_From_GMT__c, Certificate_Name__r.Valid_To_GMT__c
                    from PolicyDocumentAssociation_On_Certificate__c Where Policy_Document__c =: pdId]);
        lstPDHistories = new List<Policy_Document_History__c>([select Id,Name, Notes__c, LastModifiedDate, LastModifiedBy.Name from Policy_Document_History__c Where 
                Policy_Document__c =: pdID Order by LastModifiedDate desc]);
    }
}
/*******************************************************************************************************
 Name: AllAuditHistoryController

 Dependencies:  AllAuditHistoryController controller class, AllAuditHistoryControllerTest, AllAuditHistory vf page

 Description: This report generates data from File Archive & association records for root and
 intermeduate certs.
 
 Sort by CA Owner Name, then Audit Statement Date, then Audit ExternalLink, then certificate type

 Instructions:  None

 *******************************************************************************************************
 Revision History:
 
     6/27/2020 - Created new
     7/7/2020 - Updated class to without sharing
     7/29/2020 - Added new field to the report 'Internal Link For CAs'

 ******************************************************************************************************/

public without sharing class AllAuditHistoryController {
    
    public transient List<File_Archive_Association__c> lstFAAssociation {get; set;}
    
    public AllAuditHistoryController(){
        lstFAAssociation = [SELECT Id, Name, Certificate_Name__r.CA_Owner__c, File_Archive__r.External_Link__c, 
                File_Archive__r.Internal_Link__c, File_Archive__r.Internal_Link_For_CAs__c, File_Archive__r.Document_Type__c, 
                File_Archive__r.Audit_Statement_Date__c, File_Archive__r.Period_Start_Date__c, 
                File_Archive__r.Period_End_Date__c, Certificate_Name__r.Name, Certificate_Name__r.RecordType.Name,
                Certificate_Name__r.SHA_256_Fingerprint__c, Certificate_Name__c, Certificate_Name__r.OneCRL_Status__c, 
                Certificate_Name__r.Status__c, Certificate_Name__r.Trust_Bits__c,  
                Certificate_Name__r.Approval_Bug__c, Certificate_Name__r.NSS_Release_When_First_Included__c, 
                Certificate_Name__r.Firefox_Release_When_First_Included__c, Certificate_Name__r.NSS_Release_When_Removed__c, 
                Certificate_Name__r.Firefox_Release_When_Removed__c, Certificate_Name__r.Removal_Bug_No_or_Date__c
                FROM File_Archive_Association__c ORDER BY Certificate_Name__r.CA_Owner__c, File_Archive__r.Audit_Statement_Date__c, 
                File_Archive__r.External_Link__c, Certificate_Name__r.RecordType.Name];
        
    }
}
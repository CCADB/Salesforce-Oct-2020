/*******************************************************************************************************
 Name: RSHomePageControllerMSFT

 Dependencies: RSHomePageControllerMSFT controller class, RSHomePageMSFT vf page, RSHomePageControllerMSFTTest test class

 Description: This is Microsoft's Root Store's Task List report (added to home page). It generates
 various reports wih record count. Detail report is only displayed when the 
 record count is greater than 1.
    
    Report sections showing the following ...
    
    1) Open Leads assigned to Microsoft
    2) Open Audit Cases assigned to Microsoft
    3) Expired Root Certificates in Microsoft’s program
    
 Instructions: Add the VF page to Root Store's home page
 *******************************************************************************************************
 Revision History:
     9/3/2019 - Created new class.
     9/9/2019 - Adding a new section '“CAs with no Included Roots”'
     9/23/2019 - Added a new section 'CAs Missing Emails'
 ******************************************************************************************************/
 
public with sharing class RSHomePageControllerMSFT {
    
    public List<Lead> lstOpenLeads {get; set;}
    public List<Case> lstAuditCases {get; set;}
    public List<Account> lstExpiredRootCertificates {get; set;}
    public List<Account> lstCAswithNoIncludedRootCerts {get; set;}
    public List<Account> lstCAsMissingEmails {get; set;}
    
    public RSHomePageControllerMSFT(){
    
        lstOpenLeads = new List<Lead>([select Id, Name, Website, Company, Organization_Type__c, CP_CPS_document_URLs__c, Sponsored_By__c 
                                       from Lead where Status != 'Denied' and IsConverted = false and Sponsored_By__c = 'Microsoft' 
                                       Order by Sponsored_By__c desc]);
                    
        lstAuditCases = new List<Case>([select ID, CaseNumber, AccountId, Account.Name, Case_Progress__c, Request_Status__c,Latest_Case_Comment__c,
                        Case_Assigned_To__c, Case_Assigned_To__r.Name, Subject, LastModifiedDate, LastModifiedById, LastModifiedBy.Name
                        From Case Where RecordType.Name = 'CA Audit Update Request' AND Request_Status__c != 'Complete'
                        And Case_Assigned_To__r.Name = 'Karina Sirota'
                        Order by LastModifiedDate]);
        
        lstExpiredRootCertificates = new List<Account>([select Id, Name, ParentId, Parent.Name, Valid_From_GMT__c, Valid_To_GMT__c, 
                        Microsoft_Trust_Bits__c, Microsoft_Status__c from Account WHERE RecordType.Name = 'Root Certificate' 
                        AND Microsoft_Status__c in ('Included') 
                        AND Valid_To_GMT__c < TODAY Order by Parent.Name,Name]);
        
        //find CAs with No Included Root certs
        List<Account> lstCAOwners = new List<Account>([select Id,Name,(Select Id, Name, ParentId, Parent.Name, 
                                Parent.Microsoft_Status__c, Comments__c ,Microsoft_Status__c FROM ChildAccounts Where 
                                RecordType.Name = 'Root Certificate' AND Microsoft_Status__c in ('Included')) 
                                FROM Account Where RecordType.Name = 'CA Owner' 
                                AND Microsoft_Status__c in ('Included')]);
        set<Id> setOfCAOwnerId = new set<Id>();                        
        for(Account acc: lstCAOwners){
            if(acc.ChildAccounts.size() == 0){
                setOfCAOwnerId.add(acc.Id);
            }
        }         
        lstCAswithNoIncludedRootCerts = new List<Account>([Select Id, Name, ParentId, Parent.Name, 
                        Parent.Microsoft_Status__c, Comments__c ,Microsoft_Status__c 
                        FROM Account Where ParentId =: setOfCAOwnerId
                        Order by Parent.Name, Name]);
        
        lstCAsMissingEmails = new List<Account>([select Id,Name,Microsoft_Status__c from Account Where RecordType.Name = 'CA Owner'
                        AND Microsoft_Status__c in ('Included') AND CA_Email_Alias_1__c = null AND CA_Email_Alias_2__c = null
                        Order by Name]);
    }
}
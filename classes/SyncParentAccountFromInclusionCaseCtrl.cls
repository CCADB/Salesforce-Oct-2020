/*******************************************************************************************************
 Name: SyncParentAccountFromInclusionCaseCtrl

 Dependencies: SyncParentAccountFromInclusionCaseCtrl controller class, SyncParentAccountFromInclusionCase 
 vf page, SyncParentAccountFromIncluCaseCtrlTest, SyncRootAccountFromInclusionCaseCtrl, 
 SyncRootAccountFromInclusionCase vf page, SyncRootAccountFromInclusionCaseCtrlTest

 Description: This is the controller class for the SyncParentAccountFromInclusionCase VF page.
 When the "Sync MozillaRootInclusionInfo" button is clicked from any from Case page for Record Type 
 'CA Root Inclusion Request' type "Case", the user is redirected to SyncParentAccountFromInclusionCase VF page. 
 
 Here the user has options to update two sets of records CA Owner record and Root Certificate record: 
 1. Update the displayed fields from the Case record to the Parent Account (or the CA Owner).     
    AND
 2. Update and iterate through the Root Case records which are associated with this Case and
    allow user to update assiciated Root Certificate record on Account.
        
 Sync can be done for CA Owner, Auditor, Audit, CP/CPS, Test Websites fields when data is "Data Verified"
 and Case Status is at any stage.
  
 Mozilla fields can only be synced when Case.Request Status is 'Complete' or 'Included or Pending EV'.
 
 Parent Account (CA Owner) Status is set to 'Included' only if all related Cases are 'Complete' or 'Included, Pending EV'
     
 Instructions: None   
 *******************************************************************************************************
 Revision History:
 
     10/15/2018    Created new class
     6/13/2019     Updated program to reate cseparate sections for auditor, audit, cp/cps fields and 
                   allow users to copy individual sections
 ******************************************************************************************************/

global with sharing class SyncParentAccountFromInclusionCaseCtrl {

    // flag that indicates whether the record was updated. 
    // the next actions that a user could perform are presented on the screen based on the value of this flag
    Boolean isRecordUpdated=false;
   
    // flag that indicates whether the user rejected to update the parent account
    // the next actions that a user could perform are presented on the screen based on the value of this flag
    Boolean isUpdateCancelled=false; 
    
    // object that holds all the details which are fetched using SOQL
    private Case caseDetailsSo;
   
    // the parent account object which is associated with the root case.
    private Account parentAccountSo;   
     
    // boolean flag to check whether the request status is complete or not
    // if the flag is set as true then we do not allow the user to proceed
    // with the sync process, instead we display a message to the user.
    public Boolean isRequestStatusIncludedOrComplete {get;set;}
    
    // constructor method for standard controller
    public SyncParentAccountFromInclusionCaseCtrl(ApexPages.StandardController stdController) {
         
         // query all the details for this record  
         caseDetailsSo = [select AccountId, CaseNumber, CA_Email_Alias_1__c, Link_to_Bugzilla_Bug__c, 
         Company_Website__c, Organizational_Type__c, Geographic_Focus__c, Primary_Market_Customer_Base__c, Request_Status__c, Status,
         Recognized_CAA_Domains__c,Problem_Reporting_Mechanism__c, Street__c, City__c, State__c, Zip_Postal_Code__c, Country__c
         from Case where id = :stdController.getId() limit 1];
         
         isRequestStatusIncludedOrComplete =false;
        
         //if(caseDetailsSo.request_status__c == 'Included, Pending EV'  || caseDetailsSo.request_status__c == 'Complete' ) {
         
             isRequestStatusIncludedOrComplete = true;
             // fetch all the root cases associated with the current case
             // get the parent account details 
             parentAccountSo = [select name, CA_Email_Alias_1__c, CA_Email_Alias_2__c,
                                   approval_bug__c, Organizational_Type__c, company_website__c,  
                                   Geographic_Focus__c, Primary_Market_Customer_Base__c, Status__c,Problem_Reporting_Mechanism__c,
                                   Last_Sync_Case_No__c, Last_Sync_Date_Time__c,Recognized_CAA_Domains__c,
                                   BillingStreet, BillingCity, BillingState, BillingPostalCode, BillingCountry
                                   from account where id =:caseDetailsSo.AccountId and type = 'Owner'];      
         //}
    }

   // update the parent account and redirect to same page showing that the record got updated successfully
   public PageReference syncAccount() {
   
        // if any additional fields need to be synced from case to parent account then 
        // those fields need to be added to this section
        
        this.parentAccountSo.type = 'Owner';
        this.parentAccountSo.Company_Website__c     = this.caseDetailsSo.Company_Website__c;
        this.parentAccountSo.CA_Email_Alias_1__c    = this.caseDetailsSo.CA_Email_Alias_1__c;
        this.parentAccountSo.Organizational_Type__c = this.caseDetailsSo.Organizational_Type__c;
        this.parentAccountSo.Geographic_Focus__c    = this.caseDetailsSo.Geographic_Focus__c;
        this.parentAccountSo.Primary_Market_Customer_Base__c = this.caseDetailsSo.Primary_Market_Customer_Base__c;
        this.parentAccountSo.Recognized_CAA_Domains__c = this.caseDetailsSo.Recognized_CAA_Domains__c;
        this.parentAccountSo.Problem_Reporting_Mechanism__c = this.caseDetailsSo.Problem_Reporting_Mechanism__c;
        
        if(this.caseDetailsSo.Street__c != null && this.caseDetailsSo.Street__c != '')
            this.parentAccountSo.BillingStreet = this.caseDetailsSo.Street__c;
        if(this.caseDetailsSo.City__c != null && this.caseDetailsSo.City__c != '')
            this.parentAccountSo.BillingCity = this.caseDetailsSo.City__c;
        if(this.caseDetailsSo.State__c != null && this.caseDetailsSo.State__c!= '')
            this.parentAccountSo.BillingState = this.caseDetailsSo.State__c;
        if(this.caseDetailsSo.Zip_Postal_Code__c != null && this.caseDetailsSo.Zip_Postal_Code__c != '')
            this.parentAccountSo.BillingPostalCode = this.caseDetailsSo.Zip_Postal_Code__c;
        if(this.caseDetailsSo.Country__c != null && this.caseDetailsSo.Country__c!= '')
            this.parentAccountSo.BillingCountry = this.caseDetailsSo.Country__c;
        
        this.parentAccountSo.Last_Sync_Case_No__c   = this.caseDetailsSo.CaseNumber;
        this.parentAccountSo.Last_Sync_Date_Time__c = System.now();
        
        // Set Parent Account = 'Included' only if all related Cases are 'Complete' or 'Included, Pending EV'
        
        Boolean areAllCasesComplete = true;
        
        for(Case caseSO: [select Request_Status__c from case where accountId = :caseDetailsSo.AccountId]) {
            if(caseSo.request_status__c != 'Complete' && caseSo.request_status__c != 'Included, Pending EV') {
             areAllCasesComplete = false;
            }
        }
        
        if(areAllCasesComplete) {
            this.parentAccountSo.status__c = 'Included' ; 
        }
        
        update parentAccountSo;
        
        // set the flag which would help to indicate the correct message on the page
        isRecordUpdated= true;
        
        // Lastly, set Sync execution date/time on Case record
        this.caseDetailsSo.Last_Sync_Date_Time__c = System.now();
        update caseDetailsSo;
        
        return null;
    }
    
    // if there is no root case then don't 
    // upon user confirmation redirect the user to the next step i.e. to sync the root account
    public PageReference redirectToSyncRootAccount() {
        
        Integer rootCaseCount = [SELECT count() 
                                FROM Root_case__c
                                WHERE case_no__c = :caseDetailsSo.id
                                AND request_status__c NOT IN ('On Hold','Denied')];
                              
        // if there are one or more root cases associated with the current case
        if(rootCaseCount > 0) {
            PageReference caseSoPageRef = new PageReference('/apex/SyncRootAccountFromInclusionCase?id=' +this.caseDetailsSo.id); 
            caseSoPageRef.setRedirect(true);
            return caseSoPageRef;
        }
        return null;
    }
    

  // if the user hits cancel redirect back to the root case
   public PageReference redirectToCase() {
        PageReference caseSoPageRef = new PageReference('/' +this.caseDetailsSo.id);
        caseSoPageRef.setRedirect(true);
        return caseSoPageRef;        
    }
    
  // when the user hits cancel redirect to the same page with the status in URL so that an acknowledgement message is shown to the user.
   public PageReference cancelSyncAccount() {
       isUpdateCancelled = true;
       return null;
    }
    
   public Case getCaseDetailsSo()   {  return this.caseDetailsSo;  }
    
   public Account getParentAccount()  {  return this.parentAccountSo; }
  
   public Boolean getIsRecordUpdated() { return this.isRecordUpdated;  }
     
   public Boolean getIsUpdateCancelled() { return this.isUpdateCancelled;  }
}
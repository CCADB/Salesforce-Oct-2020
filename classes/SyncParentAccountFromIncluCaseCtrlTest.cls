/*
    Description: Test class for SyncParentAccountFromInclusionCaseCtrl. Sync program for New Inclusion type case.
*/
/*******************************************************************************************************
 Name: SyncParentAccountFromIncluCaseCtrlTest

 Dependencies: SyncParentAccountFromInclusionCaseCtrl controller class, SyncParentAccountFromInclusionCase 
 vf page, SyncParentAccountFromIncluCaseCtrlTest, SyncRootAccountFromInclusionCaseCtrl, 
 SyncRootAccountFromInclusionCase vf page, SyncRootAccountFromInclusionCaseCtrlTest

 Description: This is a test class for SyncParentAccountFromInclusionCaseCtrl.
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

@isTest 
public class SyncParentAccountFromIncluCaseCtrlTest {
    
    static testMethod void TestSync() {
      
        // create the parent account  - record type = Owner
        Account parentAccount = TestUtils.getCAOwner();
        insert parentAccount;
        
        // create the contact associated with the parent account
        Contact parentContact = TestUtils.getContact(parentAccount.id);
        insert parentContact;
        
        // create the child account - record type = Root
        Account childAccount = TestUtils.getRootCertificate(parentAccount.id);
        childAccount.Name = 'child root account 1';
        
        // create the child account - record type = Root
        Account childAccount1 = TestUtils.getRootCertificate(parentAccount.id);
        childAccount.Name = 'child root account 2';
        
        // create the child account - record type = Root
        Account childAccount2 = TestUtils.getRootCertificate(parentAccount.id);
        childAccount.Name = 'child root account 3';
        
        insert new list<Account>{childAccount, childAccount1, childAccount2};
        
        // create a case
        Case accountCaseA = TestUtils.getCase(parentAccount.id);
        accountCaseA.request_status__c  = 'Initial Request Received';         
        accountCaseA.Status = 'Open';
        accountCaseA.Request_Status__c = 'Data Verified';
        accountCaseA.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('CA Root Inclusion Request').getRecordTypeID();
        accountCaseA.Case_Progress__c = 'Verification by Root Store';
        accountCaseA.Address_Verified__c = 'Data Verified';
        accountCaseA.CA_Owner_Information_Verified__c  = 'Data Verified';
        accountCaseA.Auditor_Verified__c = 'Data Verified';
        accountCaseA.Case_Progress__c = 'Verification by Root Store';
        accountCaseA.Standard_Audit_Verified__c = 'Data Verified';
        accountCaseA.Code_Signing_Audit_Verified__c = 'Not Applicable';
        accountCaseA.BR_Audit_Statement_Link_Verified__c = 'Data Verified';
        accountCaseA.EV_Audit_Statement_Link_Verified__c = 'Data Verified';
        accountCaseA.EV_Code_Signing_Verified__c = 'Data Verified';
        accountCaseA.CP_CPS_Links_Verified__c = 'Data Verified';
        accountCaseA.Required_Practices_Verified__c  = 'Not Applicable';
        accountCaseA.Forbidden_Practices_Verified__c = 'Not Applicable';
        insert accountCaseA;
        
        // create the root case and associate it with the case
        Root_Case__c rootCaseA1 = TestUtils.getRootCase(accountCaseA.id, parentAccount.Id);
        if(Schema.SObjectType.Root_Case__c.getRecordTypeInfosByName().get('CA Root Inclusion Request') != null)
        rootCaseA1.RecordTypeId = Schema.SObjectType.Root_Case__c.getRecordTypeInfosByName().get('CA Root Inclusion Request').getRecordTypeID();
        
        Root_Case__c rootCaseA2 = TestUtils.getRootCase(accountCaseA.id, parentAccount.Id);
        if(Schema.SObjectType.Root_Case__c.getRecordTypeInfosByName().get('CA Root Inclusion Request') != null)
        rootCaseA1.RecordTypeId = Schema.SObjectType.Root_Case__c.getRecordTypeInfosByName().get('CA Root Inclusion Request').getRecordTypeID();
        
        Root_Case__c rootCaseA3 = TestUtils.getRootCase(accountCaseA.id, parentAccount.Id);
        if(Schema.SObjectType.Root_Case__c.getRecordTypeInfosByName().get('CA Root Inclusion Request') != null)
        rootCaseA1.RecordTypeId = Schema.SObjectType.Root_Case__c.getRecordTypeInfosByName().get('CA Root Inclusion Request').getRecordTypeID();
        
        insert new List<Root_Case__c>{rootCaseA1,rootCaseA2,rootCaseA3};
        
        //update accountid to the same value to invoke EnforceAccountRules method
        accountCaseA.accountid = parentContact.accountId;
        update accountCaseA;
        
        //changes request_status__c in proper sequence
        rootCaseA1.request_status__c  = 'Information Verification In Process';
        rootCaseA2.request_status__c  = 'Information Verification In Process';
        rootCaseA3.request_status__c  = 'Information Verification In Process';
        update new List<Root_Case__c>{rootCaseA1,rootCaseA2,rootCaseA3};
        
        rootCaseA1.request_status__c  = 'In Detailed CP/CPS Review';
        rootCaseA1.Application_Information_Verified__c = 'Data Verified';
        rootCaseA1.PKI_Hierarchy_Verified__c = 'Data Verified';
        rootCaseA1.Apply_Audit_Verified__c = 'Data Verified';
        rootCaseA1.Test_Website_Verified__c = 'Data Verified';
        rootCaseA1.Test_Results_Verified__c = 'Data Verified';
        rootCaseA1.Mozilla_fields_Verified__c = 'Data Verified';
        rootCaseA2.request_status__c  = 'In Detailed CP/CPS Review';
        rootCaseA2.Application_Information_Verified__c = 'Data Verified';
        rootCaseA2.PKI_Hierarchy_Verified__c = 'Data Verified';
        rootCaseA2.Apply_Audit_Verified__c = 'Data Verified';
        rootCaseA2.Test_Website_Verified__c = 'Data Verified';
        rootCaseA2.Test_Results_Verified__c = 'Data Verified';
        rootCaseA2.Mozilla_fields_Verified__c = 'Data Verified';
        rootCaseA3.request_status__c  = 'In Detailed CP/CPS Review';
        rootCaseA3.Application_Information_Verified__c = 'Data Verified';
        rootCaseA3.PKI_Hierarchy_Verified__c = 'Data Verified';
        rootCaseA3.Apply_Audit_Verified__c = 'Data Verified';
        rootCaseA3.Test_Website_Verified__c = 'Data Verified';
        rootCaseA3.Test_Results_Verified__c = 'Data Verified';
        rootCaseA3.Mozilla_fields_Verified__c = 'Data Verified';
        update new List<Root_Case__c>{rootCaseA1,rootCaseA2,rootCaseA3};
        
        // Start the test
        Test.startTest();
        
        rootCaseA1.request_status__c  = 'In Public Discussion';
        rootCaseA2.request_status__c  = 'In Public Discussion';
        rootCaseA3.request_status__c  = 'In Public Discussion';
        update new List<Root_Case__c>{rootCaseA1,rootCaseA2,rootCaseA3};
        
        rootCaseA1.request_status__c   = 'Pending Approval';
        rootCaseA2.request_status__c  = 'Pending Approval';
        rootCaseA3.request_status__c  = 'Pending Approval';
        update new List<Root_Case__c>{rootCaseA1,rootCaseA2,rootCaseA3};
        
        rootCaseA1.request_status__c   = 'Approved, Pending Inclusion';
        rootCaseA2.request_status__c  = 'Approved, Pending Inclusion';
        rootCaseA3.request_status__c  = 'Approved, Pending Inclusion';
        update new List<Root_Case__c>{rootCaseA1,rootCaseA2,rootCaseA3};
        
        rootCaseA1.request_status__c  = 'Complete';
        rootCaseA2.request_status__c  = 'Complete';
        rootCaseA3.request_status__c  = 'Denied';
        update new List<Root_Case__c>{rootCaseA1,rootCaseA2,rootCaseA3};
        
        accountCaseA.request_status__c  = 'Complete';
        update accountCaseA;    
        
        // create a standard controller instance 
        ApexPages.StandardController standardcontroller = new ApexPages.StandardController(accountCaseA);
        
        SyncParentAccountFromInclusionCaseCtrl syncPAController= new SyncParentAccountFromInclusionCaseCtrl(standardController);
        
        Apexpages.currentpage().getParameters().put('id', String.valueOf(accountCaseA.Id));
        
        syncPAController.syncAccount(); 
        syncPAController.redirectToCase();
        syncPAController.redirectToSyncRootAccount();
        syncPAController.cancelSyncAccount();
        syncPAController.redirectToCase();             
        syncPAController.getCaseDetailsSO();
        syncPAController.getParentAccount();
        syncPAController.getIsRecordUpdated();
        syncPAController.getIsUpdateCancelled(); 
        test.stopTest();
    }  
}
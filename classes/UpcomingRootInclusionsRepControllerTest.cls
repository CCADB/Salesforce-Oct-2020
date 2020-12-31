/**

Test Case for the following Controller Extension:
UpcomingRootInclusionsReportController

**/

@isTest 
public class UpcomingRootInclusionsRepControllerTest{

    static testMethod void validateTest() {
        //create the parent account  - record type = Owner
        Account parentAccount = TestUtils.getCAOwner();
        insert parentAccount;
        
        // create the contact associated with the parent account
        Contact parentContact = TestUtils.getContact(parentAccount.id);
        insert parentContact;
        
        // create the child account - record type = Root
        Account childAccount = TestUtils.getRootCertificate(parentAccount.id);
        insert childAccount;
        
        // create a case
        Case accountCaseA = TestUtils.getCase(parentAccount.id);
        accountCaseA.request_status__c  = 'Initial Request Received';         
        accountCaseA.Status = 'Open';
        accountCaseA.Request_Status__c = 'Data Verified';
        accountCaseA.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('CA Root Inclusion Request').getRecordTypeID();
        accountCaseA.Case_Progress__c = 'Verification by Root Store';
        accountCaseA.CA_Owner_Information_Verified__c  = 'Data Verified';
        accountCaseA.Address_Verified__c = 'Not Applicable';
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
        Root_Case__c rootCaseA1 = TestUtils.getRootCase(accountCaseA.id,parentAccount.Id);
        rootCaseA1.RecordTypeId = Schema.SObjectType.Root_Case__c.getRecordTypeInfosByName().get('CA Root Inclusion Request').getRecordTypeID(); 
        rootCaseA1.Request_status__c   = 'Initial Request Received';         
        rootCaseA1.Apply_Standard_Audit__c = true;
        rootCaseA1.Apply_BR_Audit__c = true;
        rootCaseA1.Apply_EV_Audit__c = true;         
        rootCaseA1.Case_No__c = accountCaseA.Id;
        rootCaseA1.CA_Owner_Name_Existing__c = parentAccount.Id;
        rootCaseA1.Root_Certificate_Name_Existing__c = childAccount.Id;
        insert rootCaseA1;
        
        rootCaseA1.Request_Status__c = 'Information Verification In Process';
        rootCaseA1.Application_Information_Verified__c = 'Data Verified';
        rootCaseA1.PKI_Hierarchy_Verified__c = 'Data Verified';
        rootCaseA1.Apply_Audit_Verified__c = 'Data Verified';
        rootCaseA1.Test_Website_Verified__c = 'Data Verified';
        rootCaseA1.Test_Results_Verified__c = 'Data Verified';
        rootCaseA1.Mozilla_fields_Verified__c = 'Data Verified';
        update rootCaseA1;
        
        Test.startTest();
        
        rootCaseA1.Request_Status__c = 'In Detailed CP/CPS Review';
        rootCaseA1.All_Fields_Verified__c = 'Yes';
        update rootCaseA1;
        
        rootCaseA1.request_status__c = 'In Public Discussion';
        update rootCaseA1;
        
        rootCaseA1.request_status__c = 'Pending Approval';
        update rootCaseA1;
        
        rootCaseA1.request_status__c = 'Approved, Pending Inclusion';
        update rootCaseA1;
           
        PageReference pref = Page.UpcomingRootInclusionsReportCSVFormat;
        Test.setCurrentPage(pref);
        
        
        UpcomingRootInclusionsReportController pacrc = new UpcomingRootInclusionsReportController();
        pacrc.getCurrentDate();
        
        Test.stopTest();
    
    }

}
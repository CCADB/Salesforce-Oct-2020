/*
 * test class for 'setAuditFileArchive' method of CaseTriggerHelper
 */
@isTest(SeeAllData=false)
public class CaseTriggerHelperTest {
  static testMethod void testAuditFileMethod() {
    Account caOwnerAcc = TestUtils.getCAOwner();
    insert caOwnerAcc;

    Case caseSO = TestUtils.getCase(caOwnerAcc.Id);
    caseSO.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName()
      .get('CA Audit Update Request')
      .getRecordTypeId();
    insert caseSO;

    caseSO.Standard_Audit_Auto_Review_Results__c = 'Cleaned=Fail';
    caseSO.Code_Signing_Audit_ALV_Results__c = 'Cleaned=Fail';
    caseSO.BR_Audit_Auto_Review_Results__c = 'Cleaned=Fail';
    caseSO.EV_SSL_Audit_Auto_Review_Results__c = 'Cleaned=Fail';
    caseSO.EV_Code_Signing_Audit_AutoReviewResults__c = 'Cleaned=Fail';
    update caseSO;

    File_Archive__c fileArchived1 = new File_Archive__c(
      Document_Type__c = 'BR Audit',
      External_Link__c = caseSO.BR_Audit_Statement_Link__c,
      Internal_Link__c = 'br-audit-link.com',
      CA_Owner__c = caseSO.AccountId
    );

    File_Archive__c fileArchived2 = new File_Archive__c(
      Document_Type__c = 'EV SSL Audit',
      External_Link__c = caseSO.EV_Audit_Statement_Link__c,
      Internal_Link__c = 'ev-audit-link.com',
      CA_Owner__c = caseSO.AccountId
    );

    insert new List<File_Archive__c>{ fileArchived1, fileArchived2 };
    caseSO.CA_Owner_Information_Verified__c = 'Data Verified';
    caseSO.Address_Verified__c = 'Data Verified';
    //caseSO.Auditor_Verified__c = 'Data Verified';
    caseSO.Standard_Audit_Verified__c = 'Data Verified';
    caseSO.Code_Signing_Audit_Verified__c = 'Data Verified';
    caseSO.BR_Audit_Statement_Link_Verified__c = 'Data Verified';
    caseSO.EV_Audit_Statement_Link_Verified__c = 'Data Verified';
    caseSO.EV_Code_Signing_Verified__c = 'Data Verified';
    caseSO.CP_CPS_Links_Verified__c = 'Data Verified';
    caseSO.Required_Practices_Verified__c = 'Not Applicable';
    caseSO.Forbidden_Practices_Verified__c = 'Not Applicable';

    update caseSO;

    try {
      caseSO.Standard_Deviation_Comments__c = 'Test';
      caseSO.Code_Signing_Deviation_Comments__c = 'Test';
      caseSO.BR_Deviation_Comments__c = 'Test';
      caseSO.EV_SSL_Deviation_Comments__c = 'Test';
      caseSO.EV_Code_Signing_Deviation_Comments__c = 'Test';
      update caseSO;
    } catch (Exception ex) {
    }
  }

  static testMethod void testAllFieldVerified() {
    Account caOwnerAcc = TestUtils.getCAOwner();
    insert caOwnerAcc;

    Case caseSO = TestUtils.getCase(caOwnerAcc.Id);
    caseSO.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName()
      .get('CA Root Inclusion Request')
      .getRecordTypeId();
    caseSO.Policy_Documentation__c = 'test';
    caseSO.Other_Relevant_Documents__c = 'Other_Relevant_Documents__c';
    insert caseSO;

    File_Archive__c fileArchived1 = new File_Archive__c(
      Document_Type__c = 'BR Audit',
      External_Link__c = caseSO.BR_Audit_Statement_Link__c,
      Internal_Link__c = 'br-audit-link.com',
      CA_Owner__c = caseSO.AccountId
    );

    File_Archive__c fileArchived2 = new File_Archive__c(
      Document_Type__c = 'EV SSL Audit',
      External_Link__c = caseSO.EV_Audit_Statement_Link__c,
      Internal_Link__c = 'ev-audit-link.com',
      CA_Owner__c = caseSO.AccountId
    );

    insert new List<File_Archive__c>{ fileArchived1, fileArchived2 };

    // create the child account - record type = Root
    Account childAccount = TestUtils.getRootCertificate(caOwnerAcc.id);
    childAccount.Name = 'child root account 1';
    childAccount.Standard_Audit_Period_End_Date__c = system.today().addDays(-6);
    insert childAccount;

    // create the root case and associate it with the case
    Root_Case__c rootCaseA1 = TestUtils.getRootCase(caseSO.id, caOwnerAcc.Id);
    rootCaseA1.request_status__c = 'Initial Request Received';
    rootCaseA1.Apply_Standard_Audit__c = true;
    //rootCaseA1.EV_Audit_Type__c = 'WebTrust';
    rootCaseA1.Apply_BR_Audit__c = true;
    rootCaseA1.Apply_EV_Audit__c = true;
    rootCaseA1.Case_No__c = caseSO.Id;
    rootCaseA1.CA_Owner_Name_Existing__c = caOwnerAcc.Id;
    rootCaseA1.Root_Certificate_Name_Existing__c = childAccount.Id;
    rootCaseA1.Application_Information_Verified__c = 'Data Verified';
    rootCaseA1.PKI_Hierarchy_Verified__c = 'Data Verified';
    rootCaseA1.Apply_Audit_Verified__c = 'Data Verified';
    rootCaseA1.Test_Website_Verified__c = 'Data Verified';
    rootCaseA1.Test_Results_Verified__c = 'Data Verified';
    rootCaseA1.Mozilla_fields_Verified__c = 'Data Verified';
    rootCaseA1.RecordTypeId = Schema.SObjectType.Root_Case__c.getRecordTypeInfosByName()
      .get('CA Root Inclusion Request')
      .getRecordTypeID();
    insert rootCaseA1;

    caseSO.Address_Verified__c = 'Data Verified';
    caseSO.CA_Owner_Information_Verified__c = 'Data Verified';
    caseSO.Auditor_Verified__c = 'Data Verified';
    caseSo.Case_Progress__c = 'Verification by Root Store';
    caseSO.Standard_Audit_Verified__c = 'Data Verified';
    caseSO.Code_Signing_Audit_Verified__c = 'Not Applicable';
    caseSO.BR_Audit_Statement_Link_Verified__c = 'Data Verified';
    caseSO.EV_Audit_Statement_Link_Verified__c = 'Data Verified';
    caseSO.EV_Code_Signing_Verified__c = 'Data Verified';
    caseSO.CP_CPS_Links_Verified__c = 'Data Verified';
    caseSO.Required_Practices_Verified__c = 'Not Applicable';
    caseSO.Forbidden_Practices_Verified__c = 'Not Applicable';
    update caseSO;

    rootCaseA1.request_status__c = 'Information Verification In Process';
    update rootCaseA1;

    Test.startTest();

    //caseSO.request_status__c   = 'Information Verification In Process';
    //update caseSO;

    rootCaseA1.request_status__c = 'In Detailed CP/CPS Review';
    update rootCaseA1;

    rootCaseA1.request_status__c = 'In Public Discussion';
    update rootCaseA1;

    rootCaseA1.request_status__c = 'Pending Approval';
    update rootCaseA1;

    

    /*rootCaseA1.request_status__c   = 'Approved, Pending Inclusion';
        update rootCaseA1;
        
        rootCaseA1.request_status__c   = 'Denied';
        update rootCaseA1;*/

    caseSO.Request_Status__c = 'Complete';
    update caseSO;

    /*rootCaseA1.request_status__c   = 'Request Withdrawn by CA';
        update rootCaseA1;
        
        caseSO.Request_Status__c = 'Request Withdrawn by CA';
        update caseSO;*/

    Case caseSO1 = TestUtils.getCase(caOwnerAcc.Id);
    caseSO1.Request_Status__c = 'Complete';
    caseSO1.Status = 'Closed';
    caseSO1.Policy_Documentation__c = 'tata';
    caseSO1.Other_Relevant_Documents__c = 'Other_Relevant_Documents__c2';
    insert caseSO1;
    try {
      //caseSO1.Subject = 'Subject Changed';
      caseSO1.Priority = 'High';
      update caseSO1;
    } catch (Exception ex) {
    }
    Test.stopTest();
  }

  static testMethod void testAuditGaps() {
    Account caOwnerAcc = TestUtils.getCAOwner();
    insert caOwnerAcc;

    Case caseSO = TestUtils.getCase(caOwnerAcc.Id);
    caseSO.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName()
      .get('CA Audit Update Request')
      .getRecordTypeId();
    insert caseSO;

    // create the child account - record type = Root
    Account childAccount = TestUtils.getRootCertificate(caOwnerAcc.id);
    childAccount.Name = 'child root account 1';
    childAccount.Standard_Audit_Period_End_Date__c = system.today().addDays(-6);
    insert childAccount;

    // create the root case and associate it with the case
    Root_Case__c rootCaseA1 = TestUtils.getRootCase(caseSO.id, caOwnerAcc.Id);
    rootCaseA1.Root_Certificate_Name_Existing__c = childAccount.ID;
    insert rootCaseA1;

    caseSO.Standard_Audit_Period_Start_Date__c = system.today().addDays(-2);
    caseSO.Standard_Audit_Period_End_Date__c = system.today().addDays(-1);
    update caseSO;

    //CPACanada_File__c data
    CPACanada_File__c objCPACanada = new CPACanada_File__c();
    objCPACanada.Name = '2268';
    objCPACanada.Report_URL__c = 'https://www.cpacanada.ca/GenericHandlers/AptifyAttachmentHandler.ashx?AttachmentID=221040';
    objCPACanada.Seal_URL__c = 'https://www.cpacanada.ca/webtrustseal?sealid=2268';
    objCPACanada.Report_Id__c = '221040';
    insert objCPACanada;

    caseSO.Standard_Audit_Statement_Link__c = 'https://www.cpacanada.ca/webtrustseal?sealid=2268';
    caseSO.Code_Signing_Audit_Statement_Link__c = 'https://www.cpacanada.ca/webtrustseal?sealid=2268';
    caseSO.BR_Audit_Statement_Link__c = 'https://www.cpacanada.ca/webtrustseal?sealid=2268';
    caseSO.EV_Audit_Statement_Link__c = 'https://www.cpacanada.ca/webtrustseal?sealid=2268';
    caseSO.EV_Code_Signing_Audit_Statement_Link__c = 'https://www.cpacanada.ca/webtrustseal?sealid=2268';
    update caseSO;
  }
}
/*
    Description: Test class for AuditCaseProgressBarController
*/
@isTest
public with sharing class AuditCaseProgressBarControllerTest {
  static testMethod void testAuditCaseProgressBar() {
    Account caOwnerAcc = TestUtils.getCAOwner();
    insert caOwnerAcc;

    // create auditor
    Auditor__c auditor = TestUtils.getAuditor();
    insert auditor;

    // create auditor location
    Auditor_Location__c auditorlocation = TestUtils.getAuditorLocation(
      auditor.Id
    );
    insert auditorlocation;

    Case caseSO = TestUtils.getCase(caOwnerAcc.Id);
    caseSO.Standard_Audit_Period_End_Date__c = null;
    caseSO.Code_Signing_Audit_Period_End_Date__c = null;
    caseSO.BR_Audit_Period_End_Date__c = null;
    caseSO.EV_Audit_Period_End_Date__c = null;
    caseSO.Standard_Audit_Authenticity_Confirmed__c = true;
    caseSO.BR_Audit_Authenticity_Confirmed__c = true;
    caseSO.EV_Code_Signing_Audit_Auth_Confirmed__c = true;
    caseSO.EV_SSL_Audit_Authenticity_Confirmed__c = true;
    caseSO.Auditor_New__c = auditor.Id;
    caseSO.Auditor_Location_New__c = auditorlocation.Id;
    insert caseSO;

    Policy_Document_On_Case__c PDOC = new Policy_Document_On_Case__c(
      Document_Link__c = 'https://CPCPS1.com',
      Document_Type__c = 'CP/CPS',
      Additional_Policy_Identifiers__c = '8.5.2',
      Case__c = caseSO.Id
    );
    insert PDOC;

    Apexpages.currentpage().getParameters().put('id', caseSO.Id);
    AuditCaseProgressBarController objACPBar = new AuditCaseProgressBarController(
      new Apexpages.standardcontroller(caseSO)
    );

    auditorlocation.Auditor_Qualifications__c = 'Test Qualifications';
    update auditorlocation;

    caseSO.CA_Document_Repository__c = 'Test document repository';
    update caseSO;

    Apexpages.currentpage().getParameters().put('id', caseSO.Id);
    objACPBar = new AuditCaseProgressBarController(
      new Apexpages.standardcontroller(caseSO)
    );

    // create the child account - record type = Root
    Account childAccount = SyncParentAccountFromCaseControllerTest.getChildAccount(
      caOwnerAcc.id
    );
    childAccount.Name = 'child root account 1';
    childAccount.Standard_Audit_Period_End_Date__c = system.today().addDays(-6);
    insert childAccount;

    // create the root case and associate it with the case
    Root_Case__c rootCaseA1 = TestUtils.getRootCase(caseSO.id, caOwnerAcc.Id);
    rootCaseA1.Request_Status__c = 'Initial Request Received';
    rootCaseA1.Apply_Standard_Audit__c = true;
    //rootCaseA1.EV_Audit_Type__c = 'WebTrust';
    rootCaseA1.Apply_BR_Audit__c = true;
    rootCaseA1.Apply_EV_Audit__c = true;
    rootCaseA1.Case_No__c = caseSO.Id;
    rootCaseA1.CA_Owner_Name_Existing__c = caOwnerAcc.Id;
    rootCaseA1.Root_Certificate_Name_Existing__c = childAccount.Id;
    rootCaseA1.RecordTypeId = Schema.SObjectType.Root_Case__c.getRecordTypeInfosByName()
      .get('CA Root Inclusion Request')
      .getRecordTypeID();
    insert rootCaseA1;

    Apexpages.currentpage().getParameters().put('id', caseSO.Id);
    objACPBar = new AuditCaseProgressBarController(
      new Apexpages.standardcontroller(caseSO)
    );

    caseSO.Standard_Audit_Auto_Review_Results__c = 'ALV Result';
    update caseSO;

    Apexpages.currentpage().getParameters().put('id', caseSO.Id);
    objACPBar = new AuditCaseProgressBarController(
      new Apexpages.standardcontroller(caseSO)
    );
    objACPBar.CheckCaseProgress();

    caseSO.Request_Status__c = 'Verification by Root Store';
    update caseSO;
    objACPBar.CheckCaseProgress();

    caseSO.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName()
      .get('CA Audit Update Request')
      .getRecordTypeId();
    update caseSO;
    objACPBar.CheckCaseProgress();
  }
}
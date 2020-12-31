@isTest
public with sharing class SyncPolicyDocumentsControllerTest {
  @testsetup
  static void CreateTestRecords() {
    //create the parent account  - record type = Owner
    Account caowner = TestUtils.getCAOwner();
    caowner.Policy_Identifiers__c = '1.1.1; 2.2.2';
    insert caowner;

    List<Account> lstNewRootCerts = new List<Account>();
    //create the child account - record type = Root
    Account rootCert = TestUtils.getRootCertificate(caowner.id);
    rootCert.Status__c = 'Included';
    lstNewRootCerts.add(rootCert);

    //create the child account - record type = Root
    Account rootCert2 = TestUtils.getRootCertificate(caowner.id);
    rootCert2.Status__c = 'Included';
    lstNewRootCerts.add(rootCert2);
    insert lstNewRootCerts;

    //create a case for CA Owner
    Case caseSO = TestUtils.getCase(caowner.Id);
    caseSO.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName()
      .get('CA Audit Update Request')
      .getRecordTypeId();
    insert caseSO;

    // create the root case and associate it with the case
    Root_Case__c rootCaseA1 = TestUtils.getRootCase(caseSO.id, caowner.Id);
    rootCaseA1.request_status__c = 'Initial Request Received';
    rootCaseA1.Apply_Standard_Audit__c = true;
    rootCaseA1.CA_Owner_Name_Existing__c = caowner.Id;
    rootCaseA1.Root_Certificate_Name_Existing__c = rootCert.Id;
    insert rootCaseA1;

    Policy_Document_On_Certificate__c PDC = new Policy_Document_On_Certificate__c(
      Document_Link__c = 'https://CPCPS.com',
      Document_Type__c = 'CP/CPS',
      Document_Last_Updated_Date__c = system.today().addDays(-5),
      Comments__c = 'test'
    );
    insert PDC;

    PolicyDocumentAssociation_On_Certificate__c PDAC = new PolicyDocumentAssociation_On_Certificate__c(
      Policy_Document__c = PDC.Id,
      Certificate_Name__c = lstNewRootCerts[0].Id
    );
    insert PDAC;

    Policy_Document_On_Case__c PDOC = new Policy_Document_On_Case__c(
      Document_Link__c = 'https://CPCPS1.com',
      Document_Type__c = 'CP/CPS',
      Additional_Policy_Identifiers__c = '8.5.2',
      Case__c = caseSO.Id,
      Document_Verified__c = 'Data Verified',
      Document_Last_Updated_Date__c = system.today(),
      Comments__c = 'abc',
      Associated_Trust_Bits__c = 'Secure Email',
      Policy_Identifiers__c = 'tst'
    );
    insert PDOC;

    Policy_Document_On_Case__c PDOC2 = new Policy_Document_On_Case__c(
      Document_Link__c = 'https://CPCPS1.com',
      Document_Type__c = 'CP/CPS',
      Additional_Policy_Identifiers__c = '8.5.2',
      Case__c = caseSO.Id,
      Document_Verified__c = 'Data Verified',
      Document_Last_Updated_Date__c = system.today(),
      Comments__c = 'abc',
      Associated_Trust_Bits__c = 'Secure Email',
      Policy_Identifiers__c = 'tst'
    );
    insert PDOC2;

    Policy_Document_Association_On_Case__c PDACase = new Policy_Document_Association_On_Case__c(
      Case__c = caseSo.Id,
      Certificate_Name__c = rootCert2.Id,
      Policy_Document__c = PDOC.Id
    );
    insert PDACase;

    Policy_Document_Association_On_Case__c PDACase2 = new Policy_Document_Association_On_Case__c(
      Case__c = caseSo.Id,
      Certificate_Name__c = rootCert2.Id,
      Policy_Document__c = PDOC2.Id
    );
    insert PDACase2;
  }

  static testMethod void TestSyncPolicyDoc() {
    SyncPolicyDocumentsController controller1 = new SyncPolicyDocumentsController(
      new Apexpages.standardcontroller(new case(Id = null))
    );
    Case caseobj = [SELECT Id FROM Case LIMIT 1];
    SyncPolicyDocumentsController controller = new SyncPolicyDocumentsController(
      new Apexpages.standardcontroller(caseobj)
    );
    Test.startTest();

    controller.SyncPolicyDocument();
    controller.nextPolicyDocument();
    SyncPolicyDocumentsController.codecoveragetest();
    Test.stopTest();
  }
}
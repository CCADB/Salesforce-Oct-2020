/*
    Description: Test class for AddUpdateRootCasesController
*/
@isTest
public with sharing class AddUpdateRootCasesControllerTest {
  static testMethod void TestAddUpdateRootCases() {
    //create the parent account  - record type = Owner
    Account parentAccount = TestUtils.getCAOwner();
    insert parentAccount;

    // create the contact associated with the parent account
    Contact parentContact = TestUtils.getContact(parentAccount.id);
    insert parentContact;

    // create the child account - record type = Root
    Account childAccount = TestUtils.getRootCertificate(parentAccount.id);
    childAccount.Status__c = 'Included';
    childAccount.Valid_To_GMT__c = system.Today().addMonths(2);
    insert childAccount;

    Account childAccount1 = TestUtils.getRootCertificate(parentAccount.id);
    childAccount1.Name = 'Root 2';
    childAccount1.Status__c = 'Included';
    childAccount1.Valid_To_GMT__c = system.Today().addMonths(2);
    insert childAccount1;
    
    Account childAccount2 = TestUtils.getRootCertificate(parentAccount.id);
    childAccount2.Name = 'Root 3';
    childAccount2.Status__c = 'Included';
    childAccount2.Valid_To_GMT__c = system.Today().addMonths(2);
    insert childAccount2;

    // create a case
    Case accountCaseA = TestUtils.getCase(parentAccount.id);
    accountCaseA.request_status__c = 'Initial Request Received';
    accountCaseA.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('CA Root Inclusion Request').getRecordTypeId();
    insert accountCaseA;
    
    Test.startTest();
        //create the root case and associate it with the case
        Root_Case__c rootCaseA1 = TestUtils.getRootCase(accountCaseA.id, parentAccount.Id);
        rootCaseA1.request_status__c = 'Initial Request Received';
        rootCaseA1.Apply_Standard_Audit__c = true;
        rootCaseA1.Apply_BR_Audit__c = true;
        rootCaseA1.Apply_EV_Audit__c = true;
        rootCaseA1.Case_No__c = accountCaseA.Id;
        rootCaseA1.CA_Owner_Name_Existing__c = parentAccount.Id;
        rootCaseA1.Root_Certificate_Name_Existing__c = childAccount.Id;
        
        Root_Case__c rootCaseA2 = TestUtils.getRootCase(accountCaseA.id, parentAccount.Id);
        rootCaseA2.SHA_256_Fingerprint__c = '1234567890123456789012345678901234567852';
        rootCaseA2.Certificate_Serial_Number__c = '753159';
        rootCaseA2.request_status__c = 'Initial Request Received';
        rootCaseA2.Apply_Standard_Audit__c = true;
        rootCaseA2.Apply_BR_Audit__c = true;
        rootCaseA2.Apply_EV_Audit__c = true;
        rootCaseA2.Case_No__c = accountCaseA.Id;
        rootCaseA2.CA_Owner_Name_Existing__c = parentAccount.Id;
        //rootCaseA1.Root_Certificate_Name_Existing__c = childAccount.Id;
        insert new List<Root_Case__c>{rootCaseA1, rootCaseA2};
    
        AddUpdateRootCasesController objcontroller = new AddUpdateRootCasesController(new Apexpages.standardcontroller(accountCaseA));
        for(AddUpdateRootCasesController.WrapperRootCases wrap: objcontroller.lstWrapAllRootCases){
            wrap.objRootCase.Apply_Standard_Audit__c = true;
        }
        objcontroller.NextToRootCase();
        if (objcontroller.lstWrapAllRootCases.size() > 1) {
          objcontroller.lstWrapAllRootCases[1].objRootCase.Apply_Standard_Audit__c = true;
        }
        objcontroller.lstWrapAllRootCases[0].objRootCase.Apply_Standard_Audit__c = false;
        objcontroller.lstWrapAllRootCases[0].objRootCase.Apply_Code_Signing_Audit__c = false;
        objcontroller.lstWrapAllRootCases[0].objRootCase.Apply_BR_Audit__c = false;
        objcontroller.lstWrapAllRootCases[0].objRootCase.Apply_EV_Audit__c = false;
        objcontroller.lstWrapAllRootCases[0].objRootCase.Apply_EV_Code_Signing_Audit__c = false;
        objcontroller.NextToRootCase();

    Test.stopTest();
  }

  static testMethod void TestAddUpdateRootCasesWithPEM() {
    //create the parent account  - record type = Owner
    Account parentAccount = TestUtils.getCAOwner();
    insert parentAccount;

    // create the contact associated with the parent account
    Contact parentContact = TestUtils.getContact(parentAccount.id);
    insert parentContact;

    // create the child account - record type = Root
    Account childAccount = TestUtils.getRootCertificate(parentAccount.id);
    childAccount.Status__c = 'Included';
    insert childAccount;

    // create a case
    Case accountCaseA = TestUtils.getCase(parentAccount.id);
    accountCaseA.request_status__c = 'Initial Request Received';
    insert accountCaseA;

    Test.startTest();

    AddUpdateRootCasesController objcontroller = new AddUpdateRootCasesController(
      new Apexpages.standardcontroller(accountCaseA)
    );
    objcontroller.AddPEMInfo();
    objcontroller.strPEMInfo = TestUtils.strPEMInfo;
    Map<String, HttpCalloutMock> endpoint2TestResp = new Map<String, HttpCalloutMock>();

    string strResponse = '{"id":25095119,"serialNumber":"0C","version":3,"signatureAlgorithm":"SHA1WithRSA","issuer":{"id":23,"c":["EU"],"o":["AC Camerfirma SA CIF A82743287"],"ou":["http://www.chambersign.org"],"cn":"Chambers of Commerce Root"},"validity":{"notBefore":"2009-01-20T10:20:19Z","notAfter":"2019-01-18T10:20:19Z"},"subject":{"c":["ES"],"o":["AC Camerfirma SA"],"ou":["http://www.camerfirma.com"],"cn":"AC Camerfirma Codesign v2"},"key":{"alg":"RSA","size":2048,"exponent":3},"x509v3Extensions":{"authorityKeyId":"45T1sU3p26EpW1eLTXYGduHRooo=","subjectKeyId":"aRqUcqDRlv89VirY/itHGBWdsO4=","keyUsage":["Certificate Sign","CRL Sign"],"extendedKeyUsage":[],"extendedKeyUsageOID":[],"subjectAlternativeName":[],"crlDistributionPoint":["http://crl.camerfirma.com/chambersroot.crl","http://crl1.camerfirma.com/chambersroot.crl"],"policyIdentifiers":["2.5.29.32.0"],"isTechnicallyConstrained":false},"x509v3BasicConstraints":"Critical","ca":true,"validationInfo":{"Android":{},"Apple":{"isValid":true},"Microsoft":{},"Mozilla":{},"Ubuntu":{}},"firstSeenTimestamp":"2017-06-27T21:26:31.524236Z","lastSeenTimestamp":"2017-06-27T21:26:31.524236Z","hashes":{"sha1":"7240558E1CE4A0C77D4072625596D6749AF9D797","sha256":"9BC4F171FF9AA224F00C799E80490E31010E3475A08FE64DC9A9C4192EB0C0B1","spki-sha256":"0CE5D2685B4A973997E1C75A229DA5814281F09C9F90A9E882337A3A90837FD3","subject-spki-sha256":"BD1B46C7C5253FE92B574FEADF9F555E6E093FA44D652BA8F56549F382B0FBAA","pin-sha256":"DOXSaFtKlzmX4cdaIp2lgUKB8JyfkKnogjN6OpCDf9M="},"ciscoUmbrellaRank":2147483647,"mozillaPolicyV2_5":{"IsTechnicallyConstrained":false}}';

    //set mock response
    SingleRequestMock mockrequest = new SingleRequestMock(
      201,
      'Complete',
      strResponse,
      null
    );
    endpoint2TestResp.put(
      'https://tls-observatory.services.mozilla.com/api/v1/certificate',
      mockrequest
    );

    MockHttpResponseGenerator multiMockGen = new MockHttpResponseGenerator(
      endpoint2TestResp
    );

    Test.setMock(HttpCalloutMock.class, multiMockGen);
    objcontroller.ValidatePEMInfo();
    objcontroller.CreateRootCert();
    objcontroller.CancelPEMInfo();

    Test.stopTest();
  }
}
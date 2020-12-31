/*******************************************************************************************************
 Name: CreateCertUsingPEMCtrlTest

 Dependencies: CreateCertUsingPEMCtrl class, CreateCertUsingPEM vf page,
 CreateCertUsingPEMCtrlTest test class

 Description: This is test class for CreateCertUsingPEMCtrl.
 The controller class CreateCertUsingPEMCtrl and VF page CreateCertUingPEM programs are being 
 used to create root or intermediate cert using PEM. This process is invoked by standard buttons:
 
 'NewRootCertForThisOwner' on CA Owner page allows user to enter PEM for a root certificate.
 
 'NewIntermediateCert' on Root Certificate records allows user to enter PEM for an intermediate certificate.
 
 The PEM info is validated and parsed. If there are no errors in parsing, user is allowed to add new 
 root/intermediate certificate record.
  
 It button passes Account Parent Id and Record Type under which the new recordis created.
 
 Instructions:  A cert checker webservice is invoked from here to parse PEM Info PEMParserController.parsePEM(pemInfoStr);

 *******************************************************************************************************
 Revision History:
 
     12/31/2019 - Created new class
      
 ******************************************************************************************************/
 
@isTest
public with sharing class CreateCertUsingPEMCtrlTest {
    static testmethod void testCreateRootCertUsingPEM(){
    
        Account accountSo = TestUtils.getCAOwner();
        insert accountSo;
        
        Test.startTest();
        
        Map<String, HttpCalloutMock> endpoint2TestResp = new Map<String,HttpCalloutMock>();
        
        string strResponse = '{"id":25095119,"serialNumber":"0C","version":3,"signatureAlgorithm":"SHA1WithRSA","issuer":{"id":23,"c":["EU"],"o":["AC Camerfirma SA CIF A82743287"],"ou":["http://www.chambersign.org"],"cn":"Chambers of Commerce Root"},"validity":{"notBefore":"2009-01-20T10:20:19Z","notAfter":"2019-01-18T10:20:19Z"},"subject":{"c":["ES"],"o":["AC Camerfirma SA"],"ou":["http://www.camerfirma.com"],"cn":"AC Camerfirma Codesign v2"},"key":{"alg":"RSA","size":2048,"exponent":3},"x509v3Extensions":{"authorityKeyId":"45T1sU3p26EpW1eLTXYGduHRooo=","subjectKeyId":"aRqUcqDRlv89VirY/itHGBWdsO4=","keyUsage":["Certificate Sign","CRL Sign"],"extendedKeyUsage":[],"extendedKeyUsageOID":[],"subjectAlternativeName":[],"crlDistributionPoint":["http://crl.camerfirma.com/chambersroot.crl","http://crl1.camerfirma.com/chambersroot.crl"],"policyIdentifiers":["2.5.29.32.0"],"isTechnicallyConstrained":false},"x509v3BasicConstraints":"Critical","ca":true,"validationInfo":{"Android":{},"Apple":{"isValid":true},"Microsoft":{},"Mozilla":{},"Ubuntu":{}},"firstSeenTimestamp":"2017-06-27T21:26:31.524236Z","lastSeenTimestamp":"2017-06-27T21:26:31.524236Z","hashes":{"sha1":"7240558E1CE4A0C77D4072625596D6749AF9D797","sha256":"9BC4F171FF9AA224F00C799E80490E31010E3475A08FE64DC9A9C4192EB0C0B1","spki-sha256":"0CE5D2685B4A973997E1C75A229DA5814281F09C9F90A9E882337A3A90837FD3","subject-spki-sha256":"BD1B46C7C5253FE92B574FEADF9F555E6E093FA44D652BA8F56549F382B0FBAA","pin-sha256":"DOXSaFtKlzmX4cdaIp2lgUKB8JyfkKnogjN6OpCDf9M="},"ciscoUmbrellaRank":2147483647,"mozillaPolicyV2_5":{"IsTechnicallyConstrained":false}}';
        
        //set mock response
        SingleRequestMock mockrequest = new SingleRequestMock(201, 'Complete', strResponse, null);
        endpoint2TestResp.put('https://tls-observatory.services.mozilla.com/api/v1/certificate', mockrequest);

        MockHttpResponseGenerator multiMockGen = new MockHttpResponseGenerator(endpoint2TestResp);
        
        Test.setMock(HttpCalloutMock.class, multiMockGen);
        
        //create root certificate
        ApexPages.currentPage().getParameters().put('id',accountSo.Id);
        ApexPages.currentPage().getParameters().put('recordtype','Root');
        CreateCertUsingPEMCtrl ctrl = new CreateCertUsingPEMCtrl(new Apexpages.standardcontroller(accountSo));
        ctrl.cancel();
        ctrl.pemInfoStr = TestUtils.strPEMInfo;
        ctrl.submit();
        ctrl.showUpdateButton();
        ctrl.CreateCert();
        
        Test.stopTest();
        
    }
    
    static testmethod void testCreateInterCertUsingPEM(){
        Account accountSo = TestUtils.getCAOwner();
        insert accountSo;
        
        //create a ROOT CA
        Account rootCA = TestUtils.getRootCertificate(accountSo.Id);
        insert rootCa;
        
        Test.startTest();
        
        Map<String, HttpCalloutMock> endpoint2TestResp = new Map<String,HttpCalloutMock>();
        
        string strResponse = '{"id":25095119,"serialNumber":"0C","version":3,"signatureAlgorithm":"SHA1WithRSA","issuer":{"id":23,"c":["EU"],"o":["AC Camerfirma SA CIF A82743287"],"ou":["http://www.chambersign.org"],"cn":"Chambers of Commerce Root"},"validity":{"notBefore":"2009-01-20T10:20:19Z","notAfter":"2019-01-18T10:20:19Z"},"subject":{"c":["ES"],"o":["AC Camerfirma SA"],"ou":["http://www.camerfirma.com"],"cn":"AC Camerfirma Codesign v2"},"key":{"alg":"RSA","size":2048,"exponent":3},"x509v3Extensions":{"authorityKeyId":"45T1sU3p26EpW1eLTXYGduHRooo=","subjectKeyId":"aRqUcqDRlv89VirY/itHGBWdsO4=","keyUsage":["Certificate Sign","CRL Sign"],"extendedKeyUsage":[],"extendedKeyUsageOID":[],"subjectAlternativeName":[],"crlDistributionPoint":["http://crl.camerfirma.com/chambersroot.crl","http://crl1.camerfirma.com/chambersroot.crl"],"policyIdentifiers":["2.5.29.32.0"],"isTechnicallyConstrained":false},"x509v3BasicConstraints":"Critical","ca":true,"validationInfo":{"Android":{},"Apple":{"isValid":true},"Microsoft":{},"Mozilla":{},"Ubuntu":{}},"firstSeenTimestamp":"2017-06-27T21:26:31.524236Z","lastSeenTimestamp":"2017-06-27T21:26:31.524236Z","hashes":{"sha1":"7240558E1CE4A0C77D4072625596D6749AF9D797","sha256":"9BC4F171FF9AA224F00C799E80490E31010E3475A08FE64DC9A9C4192EB0C0B1","spki-sha256":"0CE5D2685B4A973997E1C75A229DA5814281F09C9F90A9E882337A3A90837FD3","subject-spki-sha256":"BD1B46C7C5253FE92B574FEADF9F555E6E093FA44D652BA8F56549F382B0FBAA","pin-sha256":"DOXSaFtKlzmX4cdaIp2lgUKB8JyfkKnogjN6OpCDf9M="},"ciscoUmbrellaRank":2147483647,"mozillaPolicyV2_5":{"IsTechnicallyConstrained":false}}';
        
        //set mock response
        SingleRequestMock mockrequest = new SingleRequestMock(201, 'Complete', strResponse, null);
        endpoint2TestResp.put('https://tls-observatory.services.mozilla.com/api/v1/certificate', mockrequest);

        MockHttpResponseGenerator multiMockGen = new MockHttpResponseGenerator(endpoint2TestResp);
        
        Test.setMock(HttpCalloutMock.class, multiMockGen);
        
        //create root certificate
        ApexPages.currentPage().getParameters().put('id',rootCa.Id);
        ApexPages.currentPage().getParameters().put('recordtype','Intermediate');
        CreateCertUsingPEMCtrl ctrl = new CreateCertUsingPEMCtrl(new Apexpages.standardcontroller(rootCa));
        ctrl.cancel();
        ctrl.pemInfoStr = TestUtils.strPEMInfo;
        ctrl.submit();
        ctrl.showUpdateButton();
        ctrl.CreateCert();
        
        //create cert again to cover exception
        ctrl.submit();
        
        ctrl.CreateCert();
        
        Test.stopTest();
    }
}
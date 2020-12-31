/*
    Description: Test class for UpdatePEMInfoForRootandInterCert
*/
@isTest
public with sharing class UpdatePEMInfoForRootandInterCertTest {
    
    static string strPEMInfo = '-----BEGIN CERTIFICATE-----' +
     'MIIGTDCCBTSgAwIBAgIBDDANBgkqhkiG9w0BAQUFADB/MQswCQYDVQQGEwJFVTEn' +
     'MCUGA1UEChMeQUMgQ2FtZXJmaXJtYSBTQSBDSUYgQTgyNzQzMjg3MSMwIQYDVQQL' +
     'ExpodHRwOi8vd3d3LmNoYW1iZXJzaWduLm9yZzEiMCAGA1UEAxMZQ2hhbWJlcnMg' +
     'b2YgQ29tbWVyY2UgUm9vdDAeFw0wOTAxMjAxMDIwMTlaFw0xOTAxMTgxMDIwMTla' +
     'MIHtMQswCQYDVQQGEwJFUzEiMCAGCSqGSIb3DQEJARYTaW5mb0BjYW1lcmZpcm1h' +
     'LmNvbTFDMEEGA1UEBxM6TWFkcmlkIChzZWUgY3VycmVudCBhZGRyZXNzIGF0IHd3' +
     'dy5jYW1lcmZpcm1hLmNvbS9hZGRyZXNzKTESMBAGA1UEBRMJQTgyNzQzMjg3MSIw' +
     'IAYDVQQLExlodHRwOi8vd3d3LmNhbWVyZmlybWEuY29tMRkwFwYDVQQKExBBQyBD' +
     'YW1lcmZpcm1hIFNBMSIwIAYDVQQDExlBQyBDYW1lcmZpcm1hIENvZGVzaWduIHYy' +
     'MIIBIDANBgkqhkiG9w0BAQEFAAOCAQ0AMIIBCAKCAQEAyNwx4WbAIQBcJThZtBE6' +
     'N9ccwdpjuZ0GyJxkPWmjNRaCDSkobnmbUt5LKshzKIX/wovAjFcn71XNa4NY6DPg' +
     'XHteg5Ff62AsMIbudu/cdsAVUSRJF/+lgVbBQOtxS8qMesNPKoD/cL24z3esDqhR' +
     '1AxtJ2WhdfTmI0SK6EHbGMHJzMrxsvJ7x5sOxU7yHDF3heF5apJRsyAA/hU1kpju' +
     'uUAgmkDhQSod6H+fLyUC2uu+0Ka93C2h6CB5IppZkOJ42E9jtmJgOI9ZOnxMV2Hv' +
     'vrNb1SY8i36DPHGmPCEhGjCn2ezuDCoeQP1LLc22Iea05104BxusEBkOjVES7npq' +
     'lwIBA6OCAmQwggJgMBIGA1UdEwEB/wQIMAYBAf8CAQIwbgYDVR0fBGcwZTAwoC6g' +
     'LIYqaHR0cDovL2NybC5jYW1lcmZpcm1hLmNvbS9jaGFtYmVyc3Jvb3QuY3JsMDGg' +
     'L6AthitodHRwOi8vY3JsMS5jYW1lcmZpcm1hLmNvbS9jaGFtYmVyc3Jvb3QuY3Js' +
     'MB0GA1UdDgQWBBRpGpRyoNGW/z1WKtj+K0cYFZ2w7jCBqwYDVR0jBIGjMIGggBTj' +
     'lPWxTenboSlbV4tNdgZ24dGiiqGBhKSBgTB/MQswCQYDVQQGEwJFVTEnMCUGA1UE' +
     'ChMeQUMgQ2FtZXJmaXJtYSBTQSBDSUYgQTgyNzQzMjg3MSMwIQYDVQQLExpodHRw' +
     'Oi8vd3d3LmNoYW1iZXJzaWduLm9yZzEiMCAGA1UEAxMZQ2hhbWJlcnMgb2YgQ29t' +
     'bWVyY2UgUm9vdIIBADB1BggrBgEFBQcBAQRpMGcwPQYIKwYBBQUHMAKGMWh0dHA6' +
     'Ly93d3cuY2FtZXJmaXJtYS5jb20vY2VydHMvUk9PVC1DSEFNQkVSUy5jcnQwJgYI' +
     'KwYBBQUHMAGGGmh0dHA6Ly9vY3NwLmNhbWVyZmlybWEuY29tMA4GA1UdDwEB/wQE' +
     'AwIBBjAeBgNVHREEFzAVgRNpbmZvQGNhbWVyZmlybWEuY29tMCcGA1UdEgQgMB6B' +
     'HGNoYW1iZXJzcm9vdEBjaGFtYmVyc2lnbi5vcmcwPQYDVR0gBDYwNDAyBgRVHSAA' +
     'MCowKAYIKwYBBQUHAgEWHGh0dHA6Ly9wb2xpY3kuY2FtZXJmaXJtYS5jb20wDQYJ' +
     'KoZIhvcNAQEFBQADggEBADOSqMcVWLnxmZPaWwZlwhnChTwoICkDCiZMrwGEcRHD' +
     'y+XpcOm9LwjHABoEe1RKSefF+KrpGAmYNLy6TpfWvJCemqw0KBpzwKFo8eKjc4pH' +
     'p/RHa+Oq5i0F090drej2IoLpQwzHEpd9Haj0KxSS/e6AZR7FbBykeajt1L8TwptJ' +
     'BJMrEhY6Ov0bsupZweMTbSGVhZDYn3Wau482XnZ1jHvrjA93lTcCpNZoqUxRnLME' +
     '0qeI+b49MKOBILCU3JsVqWd6+eilbeJnqI6B7plxn1K/8ZN68fnlVULGniLe4uG7' +
     '+gzqD4AmWxSyk0FzyggVxtTKx6S/u3BxY9Y/GoPEsf0=' +
     '-----END CERTIFICATE-----';

    static testmethod void TestUpdatePEMInfoForRoorandInterCert() {
        Account acc = TestUtils.getCAOwner();
        insert acc;
        
        //create a ROOT CA
        Account rootCA = TestUtils.getRootCertificate(acc.Id);
        insert rootCa;
        
        Map<String, HttpCalloutMock> endpoint2TestResp = new Map<String,HttpCalloutMock>();
        
        string strResponse = '{"id":25095119,"serialNumber":"0C","version":3,"signatureAlgorithm":"SHA1WithRSA","issuer":{"id":23,"c":["EU"],"o":["AC Camerfirma SA CIF A82743287"],"ou":["http://www.chambersign.org"],"cn":"Chambers of Commerce Root"},"validity":{"notBefore":"2009-01-20T10:20:19Z","notAfter":"2019-01-18T10:20:19Z"},"subject":{"c":["ES"],"o":["AC Camerfirma SA"],"ou":["http://www.camerfirma.com"],"cn":"AC Camerfirma Codesign v2"},"key":{"alg":"RSA","size":2048,"exponent":3},"x509v3Extensions":{"authorityKeyId":"45T1sU3p26EpW1eLTXYGduHRooo=","subjectKeyId":"aRqUcqDRlv89VirY/itHGBWdsO4=","keyUsage":["Certificate Sign","CRL Sign"],"extendedKeyUsage":[],"extendedKeyUsageOID":[],"subjectAlternativeName":[],"crlDistributionPoint":["http://crl.camerfirma.com/chambersroot.crl","http://crl1.camerfirma.com/chambersroot.crl"],"policyIdentifiers":["2.5.29.32.0"],"isTechnicallyConstrained":false},"x509v3BasicConstraints":"Critical","ca":true,"validationInfo":{"Android":{},"Apple":{"isValid":true},"Microsoft":{},"Mozilla":{},"Ubuntu":{}},"firstSeenTimestamp":"2017-06-27T21:26:31.524236Z","lastSeenTimestamp":"2017-06-27T21:26:31.524236Z","hashes":{"sha1":"7240558E1CE4A0C77D4072625596D6749AF9D797","sha256":"9BC4F171FF9AA224F00C799E80490E31010E3475A08FE64DC9A9C4192EB0C0B1","spki-sha256":"0CE5D2685B4A973997E1C75A229DA5814281F09C9F90A9E882337A3A90837FD3","subject-spki-sha256":"BD1B46C7C5253FE92B574FEADF9F555E6E093FA44D652BA8F56549F382B0FBAA","pin-sha256":"DOXSaFtKlzmX4cdaIp2lgUKB8JyfkKnogjN6OpCDf9M="},"ciscoUmbrellaRank":2147483647,"mozillaPolicyV2_5":{"IsTechnicallyConstrained":false}}';
        
        //set mock response
        SingleRequestMock mockrequest = new SingleRequestMock(201, 'Complete', strResponse, null);
        endpoint2TestResp.put('https://tls-observatory.services.mozilla.com/api/v1/certificate', mockrequest);

        MockHttpResponseGenerator multiMockGen = new MockHttpResponseGenerator(endpoint2TestResp);
        
        Test.startTest();
        
        Test.setMock(HttpCalloutMock.class, multiMockGen);
        
        ApexPages.currentPage().getParameters().put('id',rootCa.Id);
        UpdatePEMInfoForRootandInterCertCtrl objcontroller = new UpdatePEMInfoForRootandInterCertCtrl(new Apexpages.standardcontroller(rootCa));
        objcontroller.pemInfoStr = strPEMInfo;
        objcontroller.submit();
        objcontroller.updateCert();
        objcontroller.cancel();
        objcontroller.showUpdateButton();
        Test.stopTest();
    }
    
    static testmethod void TestUpdatePEMInfoForRoorandInterCert1() {
        Account acc = TestUtils.getCAOwner();
        insert acc;
        
        //create a ROOT CA
        Account rootCA = TestUtils.getRootCertificate(acc.Id);
        insert rootCa;
        
        Map<String, HttpCalloutMock> endpoint2TestResp = new Map<String,HttpCalloutMock>();
        
        string strResponse = '{"id":25095119,"serialNumber":"0C","version":3,"signatureAlgorithm":"SHA1WithRSA","issuer":{"id":23,"c":["EU"],"o":["AC Camerfirma SA CIF A82743287"],"ou":["http://www.chambersign.org"],"cn":"Chambers of Commerce Root"},"validity":{"notBefore":"2009-01-20T10:20:19Z","notAfter":"2019-01-18T10:20:19Z"},"subject":{"c":["ES"],"o":["AC Camerfirma SA"],"ou":["http://www.camerfirma.com"],"cn":"AC Camerfirma Codesign v2"},"key":{"alg":"RSA","size":2048,"exponent":3},"x509v3Extensions":{"authorityKeyId":"45T1sU3p26EpW1eLTXYGduHRooo=","subjectKeyId":"aRqUcqDRlv89VirY/itHGBWdsO4=","keyUsage":["Certificate Sign","CRL Sign"],"extendedKeyUsage":[],"extendedKeyUsageOID":[],"subjectAlternativeName":[],"crlDistributionPoint":["http://crl.camerfirma.com/chambersroot.crl","http://crl1.camerfirma.com/chambersroot.crl"],"policyIdentifiers":["2.5.29.32.0"],"isTechnicallyConstrained":false},"x509v3BasicConstraints":"Critical","ca":true,"validationInfo":{"Android":{},"Apple":{"isValid":true},"Microsoft":{},"Mozilla":{},"Ubuntu":{}},"firstSeenTimestamp":"2017-06-27T21:26:31.524236Z","lastSeenTimestamp":"2017-06-27T21:26:31.524236Z","hashes":{"sha1":"7240558E1CE4A0C77D4072625596D6749AF9D797","sha256":"9BC4F171FF9AA224F00C799E80490E31010E3475A08FE64DC9A9C4192EB0C0B1","spki-sha256":"0CE5D2685B4A973997E1C75A229DA5814281F09C9F90A9E882337A3A90837FD3","subject-spki-sha256":"BD1B46C7C5253FE92B574FEADF9F555E6E093FA44D652BA8F56549F382B0FBAA","pin-sha256":"DOXSaFtKlzmX4cdaIp2lgUKB8JyfkKnogjN6OpCDf9M="},"ciscoUmbrellaRank":2147483647,"mozillaPolicyV2_5":{"IsTechnicallyConstrained":true}}';
        
        //set mock response
        SingleRequestMock mockrequest = new SingleRequestMock(300, 'Failure', strResponse, null);
        endpoint2TestResp.put('https://tls-observatory.services.mozilla.com/api/v1/certificate', mockrequest);

        MockHttpResponseGenerator multiMockGen = new MockHttpResponseGenerator(endpoint2TestResp);
        
        Test.startTest();
        
        Test.setMock(HttpCalloutMock.class, multiMockGen);
        
        ApexPages.currentPage().getParameters().put('id',rootCa.Id);
        UpdatePEMInfoForRootandInterCertCtrl objcontroller = new UpdatePEMInfoForRootandInterCertCtrl(new Apexpages.standardcontroller(rootCa));
        objcontroller.pemInfoStr = strPEMInfo;
        objcontroller.submit();
        objcontroller.updateCert();
        objcontroller.cancel();
        objcontroller.showUpdateButton();
        
        //set mock response
        mockrequest = new SingleRequestMock(201, 'Success', strResponse, null);
        endpoint2TestResp.put('https://tls-observatory.services.mozilla.com/api/v1/certificate', mockrequest);
        
        multiMockGen = new MockHttpResponseGenerator(endpoint2TestResp);
        Test.setMock(HttpCalloutMock.class, multiMockGen);
        
        ApexPages.currentPage().getParameters().put('id',rootCa.Id);
        objcontroller = new UpdatePEMInfoForRootandInterCertCtrl(new Apexpages.standardcontroller(rootCa));
        objcontroller.pemInfoStr = strPEMInfo;
        objcontroller.submit();
        objcontroller.updateCert();
        objcontroller.cancel();
        objcontroller.showUpdateButton();
        
        //to cover exception
        try {
            objcontroller.certificateId = UserInfo.getUserId();
            objcontroller.updateCert();
        } catch (Exception ex){}
        
        Test.stopTest();
    }

}
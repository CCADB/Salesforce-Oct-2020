// This utility class is invoked from CreateIntermediateCertController
// whenever the user clicks on the Create Intermediate Cert Button from root cert or owner cert
// they provide the PEM info on a screen
// this info is sent to the cert checker webservice and the response is mapped to several fields on the account record

public class X509CertificateCheckerUtility {


 public static Account x509CertChecker(String pemInfoStr)
 {
   
     Account tempAccountSo;
         
     // create new HTTP request 
     HttpRequest request = new HttpRequest();
      
     // set the endpoint
      
     // request.setEndpoint('http://cert-checker.allizom.org/jx509');       // production site      
     // request.setEndpoint('http://cert-checker.allizom.org/jx509-devel'); // test site     
     // request.setEndpoint('https://jx509withecc.herokuapp.com');          // Heroku site  
     request.setEndpoint('https://jx509witheccandcertid.herokuapp.com');    // Heroku site

     request.setMethod('POST');
      
     // set the certificate info as the request body 
     request.setBody(pemInfoStr);  
     HttpResponse responseStr;        
      
     // string strResponse = UploadFile(pemInfoStr);
      
      /***** TEST CODE **********
      
      request.setEndpoint('https://tls-observatory.services.mozilla.com/api/v1/certificate');
      request.setMethod('POST');

      // set the certificate info as the request body by manually crafting a multipart/form-data body
      String boundary = String.valueOf(DateTime.now().getTime());
      String body = 'Content-Type: multipart/form-data; boundary=------------------------' + boundary + '\r\n';
      body += '--------------------------' + boundary + '\r\n';
      body += 'Content-Disposition: form-data; name="certificate"; filename="cert.pem"\r\n';
      body += 'Content-Type: application/octet-stream\r\n\r\n';
      body += pemInfoStr;
      body += '\r\n--------------------------' + boundary + '--';

      request.setBody(body);
      request.setHeader('Content-Length', String.valueof(body.length()));
       
      ******* END OF TEST CODE *********/

      
      
      /******* SECOND TEST - REMOVED ENCODING ************
      
       //  HttpRequest request = new HttpRequest();
        request.setEndpoint('https://tls-observatory.services.mozilla.com/api/v1/certificate');
        request.setMethod('POST');
        
        pemInfoStr = '-----BEGIN CERTIFICATE-----\r\n';
        pemInfoStr += 'MIIDbTCCAlWgAwIBAgIBATANBgkqhkiG9w0BAQUFADBYMQswCQYDVQQGEwJKUDEr\r\n'; 
        pemInfoStr += 'MCkGA1UEChMiSmFwYW4gQ2VydGlmaWNhdGlvbiBTZXJ2aWNlcywgSW5jLjEcMBoG\r\n'; 
        pemInfoStr += 'A1UEAxMTU2VjdXJlU2lnbiBSb290Q0ExMTAeFw0wOTA0MDgwNDU2NDdaFw0yOTA0\r\n'; 
        pemInfoStr += 'MDgwNDU2NDdaMFgxCzAJBgNVBAYTAkpQMSswKQYDVQQKEyJKYXBhbiBDZXJ0aWZp\r\n'; 
        pemInfoStr += 'Y2F0aW9uIFNlcnZpY2VzLCBJbmMuMRwwGgYDVQQDExNTZWN1cmVTaWduIFJvb3RD\r\n'; 
        pemInfoStr += 'QTExMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA/XeqpRyQBTvLTJsz\r\n'; 
        pemInfoStr += 'i1oURaTnkBbR31fSIRCkF/3frNYfp+TbfPfs37gD2pRY/V1yfIw/XwFndBWW4wI8\r\n'; 
        pemInfoStr += 'h9uuywGOwvNmxoVF9ALGOrVisq/6nL+k5tSAMJjzDbaTj6nU2DbysPyKyiyhFTOV\r\n'; 
        pemInfoStr += 'MdrAG/LuYpmGYz+/3ZMqg6h2uRMft85OQoWPIucuGvKVCbIFtUROd6EgvanyTgp9\r\n'; 
        pemInfoStr += 'UK31BQ1FT0Zx/Sg+U/sE2C3XZR1KG/rPO7AxmjVuyIsG0wCR8pQIZUyxNAYAeoni\r\n'; 
        pemInfoStr += '8McDWc/V1uinMrPmmECGxc0nEovMe863ETxiYAcjPitAbpSACW22s293bzUIUPsC\r\n'; 
        pemInfoStr += 'h8U+iQIDAQABo0IwQDAdBgNVHQ4EFgQUW/hNT7KlhtQ60vFjmqC+CfZXt94wDgYD\r\n'; 
        pemInfoStr += 'VR0PAQH/BAQDAgEGMA8GA1UdEwEB/wQFMAMBAf8wDQYJKoZIhvcNAQEFBQADggEB\r\n'; 
        pemInfoStr += 'AKChOBZmLqdWHyGcBvod7bkixTgm2E5P7KN/ed5GIaGHd48HCJqypMWvDzKYC3xm\r\n'; 
        pemInfoStr += 'KbabfSVSSUOrTC4rbnpwrxYO4wJs+0LmGJ1F2FXI6Dvd5+H0LgscNFxsWEr7jIhQ\r\n'; 
        pemInfoStr += 'X5Ucv+2rIrVls4W6ng+4reV6G4pQOh29Dbx7VFALuUKvVaAYga1lme++5Jy/xIWr\r\n'; 
        pemInfoStr += 'QbJUb9wlze144o4MjQlJ3WN7WmmWAiGovVJZ6X01y8hSyn+B/tlr0/cR7SXf+Of5\r\n'; 
        pemInfoStr += 'pPpyl4RTDaXQMhhRdlkUbA/r7F+AjHVDg8OFmP9Mni0N5HeDk061lgeLKBObjBmN\r\n';
        pemInfoStr += 'QSdJQO7e5iNEOdyhIta6A/I=\r\n'; 
        pemInfoStr += '-----END CERTIFICATE-----';

        // set the certificate info as the request body by manually crafting a multipart/form-data body
        String boundary = String.valueOf(DateTime.now().getTime());
        String body = 'Content-Type: multipart/form-data; boundary=------------------------' + boundary + '\r\n';
        body += '--------------------------' + boundary + '\r\n';
        body += 'Content-Disposition: form-data; name="certificate"; filename="cert.pem"\r\n';
        body += 'Content-Type: application/octet-stream\r\n\r\n';
        body += pemInfoStr;
        body += '\r\n--------------------------' + boundary + '--';

        request.setBody(body);
        request.setHeader('Content-Length',String.valueof(body.length()));
       
        request.setTimeout(120000);
        HttpResponse responseStr = (new Http()).send(request);
        system.debug('The response is ====> ' + responseStr.getbody());
      
       ****** END oF SECOND TEST *********/
      
      // invoke the webservice and get the response
      if(!test.isRunningtest())
      {
        responseStr = (new Http()).send(request); 
      }
      else
      {
      responseStr = new HttpResponse();
      // responseStr.setBody('{"issuerCN":"DigiCert Trusted Root G4","issuerOU":"www.digicert.com","issuerO":"DigiCert Inc","issuerC":"US","subjectCN":"DigiCert Trusted Server CA G4","subjectOU":null,"subjectO":"DigiCert Inc","subjectC":"US","sha1Fingerprint":"876217035658b958f359fba589d630c4042d961b","sha256Fingerprint":"6e8d952fdbabad8de3d61e094393739b5a47371a52bdcb2a3c2f8c43622f640f","notBefore":"Thu, 01 Aug 2013 12:00:00 GMT","notAfter":"Tue, 01 Aug 2028 12:00:00 GMT","version":3,"serialNumber":"03637e538cfd86e1603527d6f2b80ff4","signatureAlgorithm":"sha384WithRSAEncryption","signatureHashAlgorithm":"sha256","publicKeySize":4096,"publicKeyAlgorithm":"RSA","publicKeyPublicExponent":65537,"basicConstraints":"cA: true, pathLenConstraint: 0","keyUsage":"digitalSignature, keyCertSign, cRLSign","extKeyUsage":"(not present)","ocsp":"http://ocsp.digicert.com","crl":"http://crl4.digicert.com/DigiCertTrustedRootG4.crl"}');
      /*responseStr.setBody('{"issuerCN":"Sample Issuer CN","issuerOU":"Sample Issuer OU","issuerO":
      "Sample Issuer O","issuerC":"Sample Issuer C","subjectCN":"Sample Subject CN","subjectOU":null,
      "subjectO":"Sample Subject O","subjectC":"Sample Subject C","sha1Fingerprint":"876217035658b958f359fba589d630c4042d961b",
      "sha256Fingerprint":"6e8d952fdbabad8de3d61e094393739b5a47371a52bdcb2a3c2f8c43622f640f",
      "notBefore":"Thu, 01 Aug 2013 12:00:00 GMT","notAfter":"Tue, 01 Aug 2028 12:00:00 GMT",
      "version":3,"serialNumber":"03637e538cfd86e1603527d6f2b80ff4","signatureAlgorithm":"sha384WithRSAEncryption",
      "signatureHashAlgorithm":"sha256","publicKeySize":4096,"publicKeyAlgorithm":"RSA","publicKeyPublicExponent":65537,
      "basicConstraints":"cA: true, pathLenConstraint: 0","keyUsage":"digitalSignature, keyCertSign, cRLSign",
      "extKeyUsage":"(not present)","ocsp":"http:sample.company.com","crl":"http://sample.company.com/root.crl",
      "technicallyConstrained":"no",
      "certID:"5A:44:C7:5E:49:7A:90:0C:A7:95:D6:36:46:7D:15:EB:57:25:73:93:99:1C:33:FA:19:2B:01:F3:68:C1:78:35"}');
      */
      CertCheckerResponseJSON obj = new CertCheckerResponseJSON();
      obj.issuerCN = 'Sample Issuer CN';
      obj.issuerOU = 'Sample Issuer OU';
      obj.issuerO = 'Sample Issuer O';
      obj.issuerC = 'Sample Issuer C';
      obj.subjectCN = 'Sample Subject CN';
      obj.subjectOU = 'Sample Subject OU';
      obj.subjectO = 'Sample Subject O';
      obj.subjectC = 'Sample Subject C';
      obj.sha1Fingerprint = 'CE:6A:64:A3:09:E4:2F:BB:D9:85:1C:45:3E:64:09:EA:E8:7D:60:F1';
      obj.sha256Fingerprint = '51:84:7C:8C:BD:2E:9A:72:C9:1E:29:2D:2A:E2:47:D7:DE:1E:3F:D2:70:54:7A:20:EF:7D:61:0F:38:B8:84:2C';
      obj.notBefore = 'Thu, 01 Aug 2013 12:00:00 GMT';
      obj.notAfter = 'Tue, 01 Aug 2028 12:00:00 GMT';
      obj.version = '3';
      obj.serialNumber = '03637e538cfd86e1603527d6f2b80ff4';
      obj.signatureAlgorithm = 'sha384WithRSAEncryption';
      obj.signatureHashAlgorithm = 'sha256';
      obj.publicKeySize = '4096';
      obj.publicKey = 'RSA 1024 bits';
      obj.publicKeyAlgorithm = 'RSA 1024 bits';
      obj.publicKeyPublicExponent = '65537';
      obj.basicConstraints = 'cA: true, pathLenConstraint: 0';
      obj.keyUsage = '(not present)';
      obj.extKeyUsage = '(not present)';
      obj.ocsp = 'http:sample.company.com';
      obj.crl = 'test crl';
      obj.technicallyConstrained = 'no';
      obj.certID = '5A:44:C7:5E:49:7A:90:0C:A7:95:D6:36:46:7D:15:EB:57:25:73:93:99:1C:33:FA:19:2B:01:F3:68:C1:78:35';
      
      obj.errors = new String[]{};
      
      String reqBody = JSON.serialize(obj);
      responseStr.setBody(reqBody);
      responseStr.setStatusCode(200);
      }
      
      
      CertCheckerResponseJSON resp;
       
      if(responseStr.getStatusCode()==200 || test.isRunningTest())
      {
        // set the extraction results and turn off the warning message that is displayed when the process begins      
        tempAccountSo = New Account(Extraction_Results__c=responseStr.getBody(),Display_Warning_or_Message__c =false);
      
        // Parse JSON response to get all the field values.
        // JSONParser parser = JSON.createParser(responseStr.getBody());
        resp = (CertCheckerResponseJSON) (JSON.deserialize(responseStr.getBody(),CertCheckerResponseJSON.class));
     
      }
      else
      {
       tempAccountSo = New Account(Extraction_Results__c='WebService Unavailable. Please try again later.',Display_Warning_or_Message__c =false,Display_Webservice_Not_Available__c=true);
      }  
      
      // Add line breaks in 'Extaction Results' as the data is a too long to be displayed on VF page
      
      tempAccountSo.Extraction_Results__c = tempAccountSo.Extraction_Results__c.replace('","','",\r\n"');      
      
      // if the response is not null map the response to the fields on the account object
      if(resp!=null)
      {
      
      // prepare a map where key is the string value of month and value is the integer value of the month
      // we need this to parse the valid from and valid to dates
      Map <String,Integer> dateMap = New Map<String,Integer> {
        'Jan' => 1, 'Feb' => 2, 'Mar' => 3, 'Apr' => 4, 'May' => 5,    'Jun' => 6,
        'Jul' => 7, 'Aug' => 8, 'Sep' => 9, 'Oct' => 10, 'Nov' => 11, 'Dec'  => 12};

        // if(resp.errors!=null && resp.errors.size() > 0 || (resp.issuerCN==null && resp.issuerOU==null && resp.issuerO==null 
        //                                                   && resp.subjectCN==null && resp.subjectOU==null && resp.subjectO==null)
          
        if(resp.errors!=null && resp.errors.size() > 0)
        {
          tempAccountSo.Display_Webservice_Failed_Message__c = true;
        }
        
        // Issuer Info
        tempAccountSo.Certificate_Issuer_Common_Name__c = resp.issuerCN ;
        tempAccountSo.Certificate_Issuer_Organizational_Unit__c = resp.issuerOU ;
        tempAccountSo.Certificate_Issuer_Organization__c = resp.issuerO;
        
        // Subject Info
        tempAccountSo.Certificate_Subject_Common_Name__c = resp.subjectCN ;       
        tempAccountSo.name = resp.subjectCN == null ? '<Fill in Cert Name>' : resp.subjectCN;
        tempAccountSo.Certificate_Subject_Organization_Unit__c = resp.subjectOU;
        tempAccountSo.Certificate_Subject_Organization__c = resp.subjectO;
        tempAccountSo.Subject__c = 'CN=' + resp.subjectCN + ', OU=' + resp.subjectOU + ', O=' + resp.subjectO + ', C=' + resp.subjectC;
        
        // SHA1 & SHA-256 Fingerprint Info
        if(resp.sha1Fingerprint != null && resp.sha1Fingerprint.length() > 0)
        tempAccountSo.SHA_1_Fingerprint__c =  resp.sha1Fingerprint ;
        tempAccountSo.SHA_256_Fingerprint__c = resp.sha256Fingerprint ;
        
        // Valid From and To Dates
        String tempDateStr;
        String[] tempDateArr; 
        if(resp.notBefore!=null && resp.notBefore.length() > 0)
        {
          tempDateStr= resp.notBefore.subStringAfter(',');
          tempDateArr= tempDateStr.split(' ');
          tempAccountSo.Valid_From_GMT__c =   Date.newInstance(Integer.valueOf(tempDateArr[3].trim()),dateMap.get(tempDateArr[2].trim()),Integer.valueOf(tempDateArr[1].trim()));
        }

        if(resp.notAfter!=null && resp.notAfter.length()  > 0)
        {
         tempDateStr= resp.notAfter.subStringAfter(',');
         tempDateArr= tempDateStr.split(' ');
 
         tempAccountSo.Valid_To_GMT__c = Date.newInstance(Integer.valueOf(tempDateArr[3].trim()),dateMap.get(tempDateArr[2].trim()),Integer.valueOf(tempDateArr[1].trim()));
        }
        
        /*** Signing Key Parameters field has been deleted
        if(resp.publicKey!=null && resp.publicKey.length()>0)
        {
          if(resp.publicKey.contains('RSA 1024'))
           {
           tempAccountSo.Signing_Key_Parameters__c = '1024';
           }
           else if(resp.publicKey.contains('RSA 2048'))
           {
           tempAccountSo.Signing_Key_Parameters__c = '2048';
           }
           else if(resp.publicKey.contains('RSA 4096'))
           {
           tempAccountSo.Signing_Key_Parameters__c = '4096';
           }
           else if(resp.publicKey.contains('EC secp256r1'))
           {
           tempAccountSo.Signing_Key_Parameters__c = 'ECC P-256';
           }
           else if(resp.publicKey.contains('EC secp384r1'))
           {
           tempAccountSo.Signing_Key_Parameters__c = 'ECC P-384';
           }
           else if(resp.publicKey.contains('EC secp521r1'))
           {
           tempAccountSo.Signing_Key_Parameters__c = 'ECC P-521';
           }         
        }
        ***/
        
        tempAccountSo.Public_Key_Algorithm__c = resp.publicKey;    
        tempAccountSo.Certificate_Serial_Number__c = resp.serialNumber ;
        // tempAccountSo.Signature_Algorithm__c = resp.signatureAlgorithm;   deleted
        tempAccountSo.Signature_Hash_Algorithm__c = resp.signatureAlgorithm; 
        //tempAccountSo.Basic_Constraints__c = resp.basicConstraints ;
        tempAccountSo.Key_Usage__c = resp.keyUsage ;
        
        // use only first 255 chars for Extended Key Usage
        if(resp.extkeyUsage != null && resp.extkeyUsage.length() > 255)
          tempAccountSo.Extended_Key_Usage__c = resp.extkeyUsage.left(252) + '...';
        else 
          tempAccountSo.Extended_Key_Usage__c = resp.extkeyUsage ;
          
        //tempAccountSo.OCSP_URL_s__c = resp.ocsp;
        
        // CRL returned by certChecker can sometimes contain very long text. Extract only the portion of the url ending in '.crl'
        tempAccountSo.CRL_URL_s__c = '';
        if (resp.crl == '(not present)') {
           tempAccountSo.CRL_URL_s__c = resp.crl;
        }
        else {
           if(resp.crl != null && resp.crl.length() > 0) {
              List<String> splitCrlUrl = resp.crl.split(',');
              for (String CrlUrl : splitCrlUrl) {
                  CrlUrl = CrlUrl.trim();
                  if (CrlUrl.indexOfIgnoreCase('http') == 0) {
                    if (tempAccountSo.CRL_URL_s__c != null && tempAccountSo.CRL_URL_s__c.length() > 0) {
                       tempAccountSo.CRL_URL_s__c += ', ';
                    }
                    tempAccountSo.CRL_URL_s__c += CrlUrl;
               
                  }
               }
            }
         }
        
        // Checking for technical constrained flag - additional condition to check for null and converted to lower case and then compare with 'yes'
        tempAccountSo.Technically_Constrained__c = resp.technicallyConstrained != null && resp.technicallyConstrained.toLowerCase().equals('yes') ? true : false;
        
        //tempAccountSo.Certificate_ID__c = resp.certID ;
        tempAccountSo.Certificate_Version__c = resp.version;
        
      }
     
     return tempAccountSo; 
    
   }
 
   /*public static string UploadFile(string PEMInfo){
        string pemInfoStr = '-----BEGIN CERTIFICATE-----\n';
        pemInfoStr += 'MIIDbTCCAlWgAwIBAgIBATANBgkqhkiG9w0BAQUFADBYMQswCQYDVQQGEwJKUDEr\n'; 
        pemInfoStr += 'MCkGA1UEChMiSmFwYW4gQ2VydGlmaWNhdGlvbiBTZXJ2aWNlcywgSW5jLjEcMBoG\n'; 
        pemInfoStr += 'A1UEAxMTU2VjdXJlU2lnbiBSb290Q0ExMTAeFw0wOTA0MDgwNDU2NDdaFw0yOTA0\n'; 
        pemInfoStr += 'MDgwNDU2NDdaMFgxCzAJBgNVBAYTAkpQMSswKQYDVQQKEyJKYXBhbiBDZXJ0aWZp\n'; 
        pemInfoStr += 'Y2F0aW9uIFNlcnZpY2VzLCBJbmMuMRwwGgYDVQQDExNTZWN1cmVTaWduIFJvb3RD\n'; 
        pemInfoStr += 'QTExMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA/XeqpRyQBTvLTJsz\n'; 
        pemInfoStr += 'i1oURaTnkBbR31fSIRCkF/3frNYfp+TbfPfs37gD2pRY/V1yfIw/XwFndBWW4wI8\n'; 
        pemInfoStr += 'h9uuywGOwvNmxoVF9ALGOrVisq/6nL+k5tSAMJjzDbaTj6nU2DbysPyKyiyhFTOV\n'; 
        pemInfoStr += 'MdrAG/LuYpmGYz+/3ZMqg6h2uRMft85OQoWPIucuGvKVCbIFtUROd6EgvanyTgp9\n'; 
        pemInfoStr += 'UK31BQ1FT0Zx/Sg+U/sE2C3XZR1KG/rPO7AxmjVuyIsG0wCR8pQIZUyxNAYAeoni\n'; 
        pemInfoStr += '8McDWc/V1uinMrPmmECGxc0nEovMe863ETxiYAcjPitAbpSACW22s293bzUIUPsC\n'; 
        pemInfoStr += 'h8U+iQIDAQABo0IwQDAdBgNVHQ4EFgQUW/hNT7KlhtQ60vFjmqC+CfZXt94wDgYD\n'; 
        pemInfoStr += 'VR0PAQH/BAQDAgEGMA8GA1UdEwEB/wQFMAMBAf8wDQYJKoZIhvcNAQEFBQADggEB\n'; 
        pemInfoStr += 'AKChOBZmLqdWHyGcBvod7bkixTgm2E5P7KN/ed5GIaGHd48HCJqypMWvDzKYC3xm\n'; 
        pemInfoStr += 'KbabfSVSSUOrTC4rbnpwrxYO4wJs+0LmGJ1F2FXI6Dvd5+H0LgscNFxsWEr7jIhQ\n'; 
        pemInfoStr += 'X5Ucv+2rIrVls4W6ng+4reV6G4pQOh29Dbx7VFALuUKvVaAYga1lme++5Jy/xIWr\n'; 
        pemInfoStr += 'QbJUb9wlze144o4MjQlJ3WN7WmmWAiGovVJZ6X01y8hSyn+B/tlr0/cR7SXf+Of5\n'; 
        pemInfoStr += 'pPpyl4RTDaXQMhhRdlkUbA/r7F+AjHVDg8OFmP9Mni0N5HeDk061lgeLKBObjBmN\n';
        pemInfoStr += 'QSdJQO7e5iNEOdyhIta6A/I=\n'; 
        pemInfoStr += '-----END CERTIFICATE-----\n\n';
        if(string.IsBlank(PEMInfo)) {
            PEMInfo = pemInfoStr;
        }
        String boundary = '----------------------------'+String.valueOf(DateTime.now().getTime());
        HttpRequest request = new HttpRequest();
        request.setEndpoint('https://tls-observatory.services.mozilla.com/api/v1/certificate');
        request.setMethod('POST');
        request.setHeader('Content-Type', 'multipart/form-data;boundary=' + boundary + '');
        //set the certificate info as the request body by manually crafting a multipart/form-data body
        String strMainBody = '';
        strMainBody = '--';
        strMainBody += boundary;
        strMainBody += '\r\n';
        strMainBody += 'Content-Disposition: form-data; name=\"certificate\"; filename=\"certificate.pem\"\r\n';
        strMainBody += 'Content-Type: application/octet-stream\r\n';
        strMainBody += '\r\n';
        strMainBody += PEMInfo;
        strMainBody += '\r\n';
        strMainBody += '--';
        strMainBody += boundary;
        strMainBody += '--';
        strMainBody += '\r\n';
        //request.setBodyAsBlob(bodyBlob);
        request.setbody(strMainBody);
        request.setTimeout(120000);
        HttpResponse responseStr = (new Http()).send(request);
        system.debug(responseStr.getbody());
        return string.valueof(responseStr.getbody());
   }*/
   
   // wrapper class to deserialize the JSON response from the cert checker webservice
   class CertCheckerResponseJSON {
       
       public CertCheckerResponseJSON(){}
       
       public String issuerCN                {get;set;}
       public String issuerOU                {get;set;}
       public String issuerO                 {get;set;}
       public String issuerC                 {get;set;}
       public String subjectCN               {get;set;}
       public String subjectOU               {get;set;}
       public String subjectO                {get;set;}
       public String subjectC                {get;set;}
       public String sha1Fingerprint         {get;set;}
       public String sha256Fingerprint       {get;set;}
       public String notBefore               {get;set;}
       public String notAfter                {get;set;}
       public String version                 {get;set;}
       public String serialNumber            {get;set;}
       public String signatureAlgorithm      {get;set;} 
       public String signatureHashAlgorithm  {get;set;}
       public String publicKeySize           {get;set;}
       public String publicKey               {get;set;}
       public String publicKeyAlgorithm      {get;set;}
       public String publicKeyPublicExponent {get;set;}
       public String basicConstraints        {get;set;}
       public String keyUsage                {get;set;}
       public String extKeyUsage             {get;set;}
       public String ocsp                    {get;set;}            
       public String crl                     {get;set;}  
       public String technicallyConstrained  {get;set;} 
       public String certID                  {get;set;}  
                
       public String[] errors                {get;set;}            
  }

 
}
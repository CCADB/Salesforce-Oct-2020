/*
    Description: PEM parser controller is used to call TLS observatory and parse PEM info
    
    For each request sent to TLS Observatory...
     - set endpoint (staging/production)
     - construct Request Body and creating form-data request using boundary and pem info
    
    If the response is not 201 (fail) then populate Extraction Results with the JSON retunred by TLS Obeservatory.
    Parse TLS Obs Response results into invidual fields using PEMParserClass
    
    Note: Some of JSONGenerator lines are commented which was used to generate JSON and compare old extraction results while testing.
    ***History***
    05/14/19     Added else condition when extend key usage is provided in response then we are setting blank. 
    09/06/2019   Added condition to set flag Has Non-constrained Doppelganger?
    09/09/2019   Populate policyIdentifiers to new custom field called Policy Indentifiers
*/
public with sharing class PEMParserController {
    
    public static Account parsePEM(String pemInfoStr){
   
        Account tempAccountSo;
        
        if(string.IsnotBlank(pemInfoStr)) {
            String boundary = '----------------------------'+String.valueOf(DateTime.now().getTime());
            HttpRequest request = new HttpRequest();
            
            // this is new production site
            request.setEndpoint('https://tls-observatory.services.mozilla.com/api/v1/certificate');
            
            // this is new staging site - to be used temporarily
            // request.setEndpoint('https://tls-observatory.stage.mozaws.net/api/v1/certificate');
            
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
            strMainBody += pemInfoStr;
            strMainBody += '\r\n';
            strMainBody += '--';
            strMainBody += boundary;
            strMainBody += '--';
            strMainBody += '\r\n';
            //request.setBodyAsBlob(bodyBlob);
            request.setbody(strMainBody);
            request.setTimeout(120000);
            HttpResponse responseStr = (new Http()).send(request);
            
            PEMParserClass pemclass;
            
            if(responseStr.getStatusCode() == 201) {
                // Parse JSON response to get all the field values.
                //system.debug('responseStr.getBody() :::: '+responseStr.getBody());
                string strResponse = responseStr.getBody();
                
                strResponse = strResponse.replace('subject-spki-sha256','subjectspkisha256').replace('spki-sha256','spkisha256').replace('pin-sha256','pinsha256');
                
                pemclass = PEMParserClass.parse(strResponse);
                
                //set the extraction results and turn off the warning message that is displayed when the process begins      
                tempAccountSo = new Account(Extraction_Results__c = JSON.serialize(pemclass), Display_Warning_or_Message__c = false);
            
                //Check for CA if it is false then display error message
                if(!pemclass.ca && ApexPages.currentPage() != null) {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'This PEM is for an end-entity certificate. Only add root or intermediate certificates to the CCADB.')); 
                    return null;
                } 
                
                // Add line breaks in 'Extaction Results' as the data is a too long to be displayed on VF page      
                tempAccountSo.Extraction_Results__c = tempAccountSo.Extraction_Results__c.replace('","','",\r\n"');
                
                // if the response is not null map the response to the fields on the account object
                if(pemclass != null) {
                    tempAccountSo.Display_Webservice_Failed_Message__c = false;
                    
                    //We are not using JSON to parse, we are storing tls obs response to Extraction Results field.
                    //generate custom extraction result from tls observatory
                    //start main object
                    /*JSONGenerator gen = JSON.createGenerator(true);
                    gen.writeStartObject();*/
                    
                    // Issuer Info CN, OU, O, C
                    if(pemclass.issuer != null) {
                        if(pemclass.issuer.CN != null) {
                            tempAccountSo.Certificate_Issuer_Common_Name__c = pemclass.issuer.CN;
                        }
                        if(pemclass.issuer.OU != null && pemclass.issuer.OU.size() > 0) 
                            tempAccountSo.Certificate_Issuer_Organizational_Unit__c = string.join(pemclass.issuer.OU,', ');        
                        if(pemclass.issuer.O != null && (pemclass.issuer.O.size() > 0))
                            tempAccountSo.Certificate_Issuer_Organization__c = string.join(pemclass.issuer.O,', ');
                            
                        //tempAccountSo.Issuer__c = (pemclass.issuer.CN != null ? ('CN=' + pemclass.issuer.CN) : '') + (pemclass.issuer.OU != null && pemclass.issuer.OU.size() > 0 ? ('; OU=' + string.join(pemclass.issuer.OU,', ')) : '') + (pemclass.issuer.O != null && pemclass.issuer.O.size() > 0 ? ('; O=' + string.join(pemclass.issuer.O,', ')) : '') + (pemclass.issuer.C != null && pemclass.issuer.C.size() > 0 ? '; C=' + string.join(pemclass.issuer.C,', ') : '');                            
                          
                          tempAccountSo.Issuer__c = createSujectIssuer(pemclass.issuer.CN, pemclass.issuer.OU, pemclass.issuer.O, pemclass.issuer.C);
                                                      
                        /*gen.writeStringField('issuerCN', tempAccountSo.Certificate_Issuer_Common_Name__c != null ? tempAccountSo.Certificate_Issuer_Common_Name__c : '');
                        gen.writeStringField('issuerOU', tempAccountSo.Certificate_Issuer_Organizational_Unit__c != null ? tempAccountSo.Certificate_Issuer_Organizational_Unit__c : '');
                        gen.writeStringField('issuerO', tempAccountSo.Certificate_Issuer_Organization__c != null ? tempAccountSo.Certificate_Issuer_Organization__c : '');
                        if(pemclass.issuer.C != null && (pemclass.issuer.C.size() > 0))
                            gen.writeStringField('issuerC', string.join(pemclass.issuer.c,','));*/
                    }
                    
                    //serial number
                    tempAccountSo.Certificate_Serial_Number__c = pemclass.serialNumber;
                    
                    // Subject Info CN, OU, O, C
                    if(pemclass.Subject != null) {
                        if(pemclass.subject.CN != null){
                            tempAccountSo.Certificate_Subject_Common_Name__c = pemclass.subject.CN; 
                        } 
                         
                         if ((tempAccountSo.name == null || tempAccountSo.name == '<Fill in Cert Name>') 
                             && pemclass.subject.CN != null)
                                 tempAccountSo.name = pemclass.subject.CN;                   
                            
                        // tempAccountSo.name = pemclass.subject.CN == null ? '<Fill in Cert Name>' : pemclass.subject.CN;
                        
                        if(pemclass.subject.OU != null && pemclass.subject.OU.size() > 0) 
                            tempAccountSo.Certificate_Subject_Organization_Unit__c = string.join(pemclass.subject.OU,', ');
                        if(pemclass.subject.O != null && pemclass.subject.O.size() > 0)
                            tempAccountSo.Certificate_Subject_Organization__c = string.join(pemclass.subject.O,', ');
                                                        
                        //tempAccountSo.Subject__c = (pemclass.subject.CN != null ? ('CN=' + pemclass.subject.CN) : '') + (pemclass.subject.OU != null && pemclass.subject.OU.size() > 0 ? ('; OU=' + string.join(pemclass.subject.OU,', ')) : '') + (pemclass.subject.O != null && pemclass.subject.O.size() > 0 ? ('; O=' + string.join(pemclass.subject.O,', ')) : '') + (pemclass.subject.C != null && pemclass.subject.C.size() > 0 ? '; C=' + string.join(pemclass.subject.C,', ') : '');
                        tempAccountSo.Subject__c = createSujectIssuer(pemclass.subject.CN, pemclass.subject.OU, pemclass.subject.O, pemclass.subject.C);                     
                                          
                        /*gen.writeStringField('subjectCN', tempAccountSo.Certificate_Subject_Common_Name__c != null ? tempAccountSo.Certificate_Subject_Common_Name__c : '');
                        gen.writeStringField('subjectOU', tempAccountSo.Certificate_Subject_Organization_Unit__c != null ? tempAccountSo.Certificate_Subject_Organization_Unit__c : '');
                        gen.writeStringField('subjectO', tempAccountSo.Certificate_Subject_Organization__c != null ? tempAccountSo.Certificate_Subject_Organization__c : '');
                        if(pemclass.subject.C != null && (pemclass.subject.C.size() > 0))
                            gen.writeStringField('subjectC', string.join(pemclass.subject.c,','));*/
                        
                    }
                    
                    // SHA1 & SHA-256 Fingerprint Info
                    if(pemclass.Hashes != null) {
                        if(pemclass.Hashes.sha1 != null){
                            tempAccountSo.SHA_1_Fingerprint__c =  pemclass.Hashes.sha1;
                        } 
                        if(pemclass.Hashes.sha256 != null){
                            tempAccountSo.SHA_256_Fingerprint__c = pemclass.Hashes.sha256;
                        }
                        if(pemclass.Hashes.spkisha256 != null) {
                            tempAccountSo.SPKI_SHA256__c = pemclass.Hashes.spkisha256;
                        }
                        if(pemclass.Hashes.subjectspkisha256 != null) {
                            // to be deprecated - tempAccountSo.Certificate_ID__c = pemclass.Hashes.subjectspkisha256;
                            tempAccountSo.Subject_SPKI_SHA256__c = pemclass.Hashes.subjectspkisha256;
                        }
                        /*gen.writeStringField('sha1Fingerprint', tempAccountSo.SHA_1_Fingerprint__c != null ? tempAccountSo.SHA_1_Fingerprint__c : '');
                        gen.writeStringField('sha256Fingerprint', tempAccountSo.SHA_256_Fingerprint__c != null ? tempAccountSo.SHA_256_Fingerprint__c : '');*/
                    }
                    
                    // Valid From and To Dates
                    if(pemclass.Validity != null){
                        String tempDateStr;
                        String[] tempDateArr; 
                        if(pemclass.Validity.notBefore != null && pemclass.Validity.notBefore.length() > 0) {
                            //gen.writeStringField('notBefore', pemclass.Validity.notBefore);
                            tempDateStr = pemclass.Validity.notBefore.split('T')[0];
                            tempDateArr = tempDateStr.split('-');
                            tempAccountSo.Valid_From_GMT__c =   Date.newInstance(Integer.valueOf(tempDateArr[0].trim()),Integer.valueOf(tempDateArr[1].trim()),Integer.valueOf(tempDateArr[2].trim()));
                        }
                        
                        if(pemclass.Validity.notAfter !=null && pemclass.Validity.notAfter.length()  > 0) {
                            //gen.writeStringField('notAfter', pemclass.Validity.notAfter);
                            tempDateStr = pemclass.Validity.notAfter.split('T')[0];
                            tempDateArr = tempDateStr.split('-');
                            tempAccountSo.Valid_To_GMT__c = Date.newInstance(Integer.valueOf(tempDateArr[0].trim()),Integer.valueOf(tempDateArr[1].trim()),Integer.valueOf(tempDateArr[2].trim()));
                        }
                    }
                    
                    tempAccountSo.Certificate_Version__c = string.valueof(pemclass.version);
                    
                    /*gen.writeStringField('version', tempAccountSo.Certificate_Version__c != null ? tempAccountSo.Certificate_Version__c : '');
                    
                    gen.writeStringField('serialNumber', tempAccountSo.Certificate_Serial_Number__c != null ? tempAccountSo.Certificate_Serial_Number__c : '');*/
                    
                    // tempAccountSo.Signature_Algorithm__c = pemclass.signatureAlgorithm;   deleted
                    tempAccountSo.Signature_Hash_Algorithm__c = pemclass.signatureAlgorithm; 
                    
                    //gen.writeStringField('signatureAlgorithm', tempAccountSo.Signature_Hash_Algorithm__c != null ? tempAccountSo.Signature_Hash_Algorithm__c : '');
                    
                    if(pemclass.key != null) {
                        string publickey = '';
                        if(pemclass.key.alg == 'RSA'){
                            publickey = pemclass.key.alg + ' ' + pemclass.key.size + ' bits';
                        } else if(pemclass.key.alg == 'ECDSA'){
                            publickey = 'EC secp' + pemclass.key.size + 'r1';
                        } else {
                            publickey = 'Could not interpret public key algorithm: '+pemclass.key;
                        }
                        
                        tempAccountSo.Public_Key_Algorithm__c = publickey; 
                        
                        /*gen.writeStringField('publicKey', tempAccountSo.Public_Key_Algorithm__c != null ? tempAccountSo.Public_Key_Algorithm__c : '');
                        gen.writeStringField('publicKeyAlgorithm', pemclass.key.alg != null ? pemclass.key.alg : '');*/
    
                    }
                                    
                    // basic constaints not found so used - x509v3BasicConstraints
                    // tempAccountSo.Basic_Constraints__c = pemclass.x509v3BasicConstraints;
                    // Keep OCSP and Basic Constraints in deprecated section – do not update from program
                    
                    // gen.writeStringField('basicConstraints', tempAccountSo.Basic_Constraints__c != null ? tempAccountSo.Basic_Constraints__c : '');
                    
                    if(pemclass.x509v3Extensions != null){
                        
                        //policy indentifier
                        if(pemclass.x509v3Extensions.policyIdentifiers != null && pemclass.x509v3Extensions.policyIdentifiers.size() > 0){
                            tempAccountSo.Policy_Identifiers__c = string.join(pemclass.x509v3Extensions.policyIdentifiers,'; ');
                        }
                        
                        if(pemclass.x509v3Extensions.keyUsage != null && pemclass.x509v3Extensions.keyUsage.size() > 0) {
                            tempAccountSo.Key_Usage__c = string.join(pemclass.x509v3Extensions.keyUsage,', ');
                        }
                        //gen.writeStringField('keyUsage', tempAccountSo.Key_Usage__c != null ? tempAccountSo.Key_Usage__c : '');
                        // use only first 255 chars for Extended Key Usage
                        /*if(pemclass.x509v3Extensions.extendedKeyUsage != null && pemclass.x509v3Extensions.extendedKeyUsage.size() > 255)
                            tempAccountSo.Extended_Key_Usage__c = pemclass.x509v3Extensions.extendedKeyUsage.left(252) + '...';
                        else */
                        if(pemclass.x509v3Extensions.extendedKeyUsage != null && pemclass.x509v3Extensions.extendedKeyUsage.size() > 0) {
                            string strExtendKeyUsage = string.join(pemclass.x509v3Extensions.extendedKeyUsage, ',');
                            if(string.isnotblank(strExtendKeyUsage) && strExtendKeyUsage.length() > 200){
                                strExtendKeyUsage = strExtendKeyUsage.left(200) + '...';
                            }
                            tempAccountSo.Extended_Key_Usage__c = strExtendKeyUsage;
                        }
                        //added this condition because when extended key usage was not provided then it was not overrideing old value. 
                        else {
                            tempAccountSo.Extended_Key_Usage__c = '';
                        }
                        
                        // Line below added by Poonam
                        //gen.writeStringField('extKeyUsage', tempAccountSo.Extended_Key_Usage__c != null ? tempAccountSo.Extended_Key_Usage__c : '');
                        
                        //crl urls    
                        tempAccountSo.CRL_URL_s__c = '';
                        if (pemclass.x509v3Extensions.crlDistributionPoint != null && pemclass.x509v3Extensions.crlDistributionPoint.size() > 0) {
                            tempAccountSo.CRL_URL_s__c = string.join(pemclass.x509v3Extensions.crlDistributionPoint,', ');
                        }
                        //gen.writeStringField('crl', tempAccountSo.CRL_URL_s__c);
                    }                
                    // Checking for technical constrained flag - additional condition to check for null and converted to lower case and then compare with 'yes'
                    
                    // 3 lines below not returning correct tech cons - commented by Poonam
                    // if(pemclass.mozillaPolicyV2_5 != null) {
                    //    tempAccountSo.Technically_Constrained__c = pemclass.mozillaPolicyV2_5.isTechnicallyConstrained != null ? false : pemclass.mozillaPolicyV2_5.isTechnicallyConstrained;
                    // }
                    
                    if(pemclass.mozillaPolicyV2_5 != null && pemclass.mozillaPolicyV2_5.isTechnicallyConstrained != null) {
                          tempAccountSo.Technically_Constrained__c = pemclass.mozillaPolicyV2_5.isTechnicallyConstrained;
                    }
                    
                    //set Has Non-constrained Doppelganger? flag
                    if(tempAccountSo.Subject_SPKI_SHA256__c != null && tempAccountSo.Technically_Constrained__c){
                        List<Account> lstSameSubjectSPKI = CommonMethods.getSameSubjectSPKIInterCerts(tempAccountSo.Subject_SPKI_SHA256__c);
                        if(lstSameSubjectSPKI.size() > 0){
                            tempAccountSo.Has_Non_constrained_Doppelganger__c = true;
                        }
                    }
                    
                    //gen.writeStringField('technicallyConstrained', tempAccountSo.Technically_Constrained__c ? 'yes' : 'no');
                    //gen.writeStringField('certID', tempAccountSo.Certificate_ID__c != null ? tempAccountSo.Certificate_ID__c : '');
                    //gen.writeStringField('hash(SPKI)', tempAccountSo.SPKI_SHA256__c != null ? tempAccountSo.SPKI_SHA256__c : '');
                    //gen.writeStringField('hash(Subject + SPKI)', tempAccountSo.Subject_SPKI_SHA256__c != null ? tempAccountSo.Subject_SPKI_SHA256__c : '');
                    //this parameter not returnd by TLS Obs 
                    //tempAccountSo.OCSP_URL_s__c = pemclass.ocsp;
                    //Keep OCSP and Basic Constraints in deprecated section – do not update from program
                    
                    //tempAccountSo.New_Extraction_Results__c = gen.getAsString().replace('","','",\r\n"');
                    
                }
            } else if(responseStr != null) {
                string strErrorMessage = 'Error Statuscode: ' +responseStr.getStatusCode() + ' Message: '+ responseStr.getbody();
                tempAccountSo = new Account(Extraction_Results__c= strErrorMessage, Display_Warning_or_Message__c = false, Display_Webservice_Not_Available__c=true);
            } else {
                tempAccountSo = new Account(Extraction_Results__c='Error: WebService Unavailable. Please try again later.', Display_Warning_or_Message__c = false, Display_Webservice_Not_Available__c=true);
            }
            // system.debug('tempAccountSo  ::: '+tempAccountSo);
        }
        return tempAccountSo;
    }
    
    public static string createSujectIssuer(string strCN, List<string> strOU, List<string> strO, List<string> strC){
        string str = '';
        if(strCN != null && string.isnotblank(strCN)) {
            str = 'CN='+strCN;
        }
        if(strOU != null && strOU.size() > 0){
            if(string.isnotblank(str)) str += ';';
            str += ' OU=' + string.join(strOU,', ');
        }
        if(strO != null && strO.size() > 0){
            if(string.isnotblank(str)) str += ';';
            str += ' O=' + string.join(strO,', ');
        }
        if(strC != null && strC.size() > 0){
            if(string.isnotblank(str)) str += ';';
            str += ' C=' + string.join(strC,', ');
        }
        return str;
    }
        
}
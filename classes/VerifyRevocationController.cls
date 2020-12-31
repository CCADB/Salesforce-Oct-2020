/*******************************************************************************************************
 Name: VerifyRevocationController

 Dependencies: VerifyRevocationController class, VerifyRevocationControllerTest class,
 VerifyRevocation VF page, RunVerifyRevocationSchedulerClass

 Description: This controller class was created to verify revoked intermediate certs.
 This functionility is invoked from a button "Verify Revocation" on intermediate certs page.
 
 Revocation Status = Revoked and 
 Date of Revocation not blank and 
 CRL URL(s) or Alternate CRL not blank
 
 When above conditions are met call the tool 'https://crlverification-dot-ccadb-231121.appspot.com/'.
 If the crlverification result is ‘PASS’ and ‘OneCRL Status’ is blank, then ‘OneCRL Status’ is 
 updated to “Ready to Add”. This field can only be updated by Mozilla or System Admin profiles.
 Whenever crlverification result is FAIL, “Revocation Verification” to say “FAILED” and 
 update the errors that crlVerification provides regarding why it failed. 
 
 "OneCRL Status" field does not get updated when called by batch program (RunBatchToVerifyRevocation)
 "OneCRL Status" field is set only when it is empty. 
 "OneCRL Status" field is not updated when the parent cert is revoked. 
 
 If the Revocation reason is blank then do not pass this attribute in the https request,
 
 crlverification tool check for following and returns a JSON
 - CRL presence and downloadability
 - Serial number presence within the CRL
 - Datetime checking
 - Revocation reason checking
 
 Sample input:
 {
  "crl": <list of alternate CRL and CRL URL(s)>
  "serial": String(Hex),
  "revocationDate": String(YYYY/MM/DD),
  "revocationReason": Optional<ReasonCode>
 }
 
 Sample Output:
 // PASS case
 {
  "crl": "http://crl.ws.symantec.com/pca1-g3.crl",
  "serial": "fc788d52d4441678243b9882cb15b4",
  "revocationDate": "2019/05/07"
 }

 // Note that "Errors" is an array of strings, as multiple errors may be detected.
 {
  "Errors": [],
  "Result": "PASS"
 }

 
 Previously this process was run manually by root store: openssl crl -inform DER -text -noout -in crlfile.crl

 Instructions: To test the tool use curl -d '{"crl": "http://crl.pkioverheid.nl/DomOrganisatiePersoonLatestCRL-G3.crl","serial": "329CAB52A80A2E3F","revocationDate": "2019/06/27", "revocationReason": "(4) superseded"}' https://crlverification-dot-ccadb-231121.appspot.com/ 

 *******************************************************************************************************
 Revision History:
 
     10/26/2019 - Created new class
     10/30/2019 - ‘OneCRL Status’ to be only updated by Mozilla or System Admin profiles.
     10/30/2019 - If the Revocation reason is blank then do not pass this attribute in the https request,
     12/07/2019 - "OneCRL Status" field is set only when it is empty. 
                  "OneCRL Status" field is not updated when the parent cert is revoked.  
     04/08/2020 - "Derived Trust Bits" has "Server Authentication" then update 'Ready to Add' else 'Not Applicable'       
 ******************************************************************************************************/
 
public with sharing class VerifyRevocationController {
    
    public Account objAccount {get; set;}
    
    public VerifyRevocationController(Apexpages.standardcontroller controller){
        Id accId = controller.getId();
        objAccount = new Account();
        
        if(accId != null) {
            List<Account> lstAccount = new List<Account>([select Id, Name, Revocation_Status__c, Date_of_Revocation__c, OneCRL_Status__c,
                                 CRL_URL_s__c,Alternate_CRL__c,Certificate_Serial_Number__c,RFC_5280_Revocation_Reason_Code__c,
                                 Derived_Trust_Bits__c,
                                 Parent.Revocation_Status__c FROM Account WHERE Id =: accId]);    
            if(lstAccount.size() > 0) {
                objAccount = lstAccount[0];  
            }
        }
    }
    
    public void CallAPIToVerifyRevocation(){
        try {
           
            if(objAccount.Revocation_Status__c != 'Revoked' && Apexpages.currentpage() != null){
                ApexPages.addMessage(new Apexpages.Message(ApexPages.Severity.Error,'If this cert is revoked, then update the Revocation Status.'));             
                return;
            }
            
            if(objAccount.Date_of_Revocation__c == null  && Apexpages.currentpage() != null){
                ApexPages.addMessage(new Apexpages.Message(ApexPages.Severity.Error,'If this cert is revoked, then update the Date of Revocation.'));             
                return; 
            }
            
            /* if(objAccount.RFC_5280_Revocation_Reason_Code__c == null){
                ApexPages.addMessage(new Apexpages.Message(ApexPages.Severity.Error,'If this cert is revoked, then update the Revocation Reason.'));             
                return;
            }*/
            
            string crlURL = '';
            if(objAccount.CRL_URL_s__c == null && string.isblank(objAccount.CRL_URL_s__c)){
                if(objAccount.Alternate_CRL__c == null && string.isblank(objAccount.Alternate_CRL__c) && Apexpages.currentpage() != null) {
                    ApexPages.addMessage(new Apexpages.Message(ApexPages.Severity.Error,'No CRL.'));             
                    return;
                } else {
                    crlURL = objAccount.Alternate_CRL__c;
                }
            } else {
                crlURL = objAccount.CRL_URL_s__c;
            }
            
            List<string> lstCRLURLs = new List<string>();
            
            // first add alternate crl and then append crlurls to the list
            if(string.isnotblank(objAccount.Alternate_CRL__c)) {
                lstCRLURLs.add('"'+objAccount.Alternate_CRL__c+'"');
            }
            if(string.isnotblank(objAccount.CRL_URL_s__c)) {
                if(objAccount.CRL_URL_s__c.contains(', ')){
                    for(string strCRL: objAccount.CRL_URL_s__c.split(', ')){
                        lstCRLURLs.add('"'+strCRL+'"');
                    }
                } else {
                    lstCRLURLs.add('"'+objAccount.CRL_URL_s__c+'"');
                }
            }
                                             
            /*if(string.isnotblank(crlURL) && crlURL.contains(',')){
                crlURL = crlURL.split(',')[0].trim();
            }*/
                       
            if(string.isnotblank(crlURL)){
                crlURL = string.join(lstCRLURLs, ',');             
            }
            // system.debug('After Join crlURL ::: '+crlURL);
                                   
            HttpRequest req = new HttpRequest();
            HTTPResponse res;
            req.setEndpoint('https://crlverification-dot-ccadb-231121.appspot.com/');
            string RequestBody = '';
                   
            string revocationDate = '';
            if (objAccount.Date_of_Revocation__c != null) {
                string year = string.valueof(objAccount.Date_of_Revocation__c.year());
                string month = string.valueof(objAccount.Date_of_Revocation__c.month());
                string day = string.valueof(objAccount.Date_of_Revocation__c.day());
                //revocationDate = DateTime.NewInstance(objAccount.Date_of_Revocation__c.year(),objAccount.Date_of_Revocation__c.month(),objAccount.Date_of_Revocation__c.day(),0,0,0).format('YYYY/MM/dd');   
                revocationDate = year +'/'+(month.length() == 1 ? ('0'+month) : month)+'/'+(day.length() == 1 ? ('0'+day) : day);
            }       
            
            if(objAccount.RFC_5280_Revocation_Reason_Code__c == null)  
                 RequestBody += '{"crl": ['+crlURL+'],"serial": "'+objAccount.Certificate_Serial_Number__c+'","revocationDate": "'+revocationDate+'"}';
            else
                 RequestBody += '{"crl": ['+crlURL+'],"serial": "'+objAccount.Certificate_Serial_Number__c+'","revocationDate": "'+revocationDate+'", "revocationReason": "'+objAccount.RFC_5280_Revocation_Reason_Code__c+'"}';
            //system.debug('RequestBody ::: '+RequestBody);
            
            req.setBody(RequestBody);
            req.setMethod('POST');
            req.setTimeOut(120000);
            req.setHeader('Content-Type','application/json');
            string strResponse = '';
            if(!Test.isRunningTest()){
                Http http = new Http();
                res = http.send(req);
                strResponse = res.getBody();
            } else {
                if(objAccount.RFC_5280_Revocation_Reason_Code__c == null){
                    strResponse += '{"Errors": [],"Result": "FAIL"}';
                } else {
                    strResponse += '{"Errors": [],"Result": "PASS"}';
                }
            }
            Map<String, Object> results = (Map<String, Object>) JSON.deserializeUntyped(strResponse);
            
            if(results.containskey('Result')){
                string result = string.valueof(results.get('Result'));
                List<Object> lstObjectErrors = (List<Object>)results.get('Errors');
                List<string> lstErrors = new List<string>();
                for(Object obj: lstObjectErrors){
                    lstErrors.add(string.valueof(obj));
                }
                if(result == 'PASS'){
                    Id profileId = UserInfo.getProfileId();
                    List<Profile> lstProfile = new List<Profile>([select Id from Profile Where Id =: profileId and Name in ('Standard User - Mozilla','System Administrator - Mozilla')]);
                    
                    // only Mozilla users or System Admins can update OneCRL Status
                    // do not allow batch program to update OneCRL Status              
                    if(lstProfile.size() > 0 && string.isblank(objAccount.OneCRL_Status__c) && objAccount.Parent.Revocation_Status__c != 'Revoked'
                        && !System.isBatch()){
                        //check derived trust bits has Server Authentication
                        if(objAccount.Derived_Trust_Bits__c != null && objAccount.Derived_Trust_Bits__c.contains('Server Authentication')){
                            objAccount.OneCRL_Status__c = 'Ready to Add';
                        } else {
                            objAccount.OneCRL_Status__c = 'Not Applicable';
                        }
                    }
                    objAccount.Revocation_Verification__c = 'Revocation automatically verified on '+system.now().format('MM/dd/YYYY'); 
                    if(Apexpages.currentpage() != null) {
                        ApexPages.addMessage(new Apexpages.Message(ApexPages.Severity.CONFIRM,objAccount.Revocation_Verification__c));  
                    } 
                } else if(result == 'FAIL') {
                    // objAccount.Revocation_Verification__c = 'FAILED: '+string.join(lstErrors, ',');
                    
                    String errorString = string.join(lstErrors, ',');
                    if(Apexpages.currentpage() != null) {
                        // ApexPages.addMessage(new Apexpages.Message(ApexPages.Severity.Error,objAccount.Revocation_Verification__c)); 
                        ApexPages.addMessage(new Apexpages.Message(ApexPages.Severity.Error, errorString));
                    }
                    
                    if(errorString.length() > 255)
                        errorString = errorString.substring(0, 240);
   
                    objAccount.Revocation_Verification__c = 'FAILED: ' + errorString;  
   
                }
                update objAccount;
            } else if(Apexpages.currentpage() != null) {
                ApexPages.addMessage(new Apexpages.Message(ApexPages.Severity.Error,'Result is not found. '+strResponse));
            }
           
        } catch (Exception ex){
            if(Apexpages.currentpage() != null) {
                Apexpages.addMessages(ex);
            }
        }
        
    }
}
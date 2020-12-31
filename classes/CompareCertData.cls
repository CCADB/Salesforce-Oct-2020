/*******************************************************************************************************
 Name: CompareCertData

 Dependencies:  CompareCertData controller class, CompareCertDataTest, CompareCertData vf page

 Description: CompareCertData controller gets input from the certdata parsing tool. The parsing tool 
 returns only a list of simple objects - not the full parsing results of certdata.txt. certdata.txt file contains 
 the object definitions for the certs and other information "built into" NSS.

     Webservice from https://certdatadiff-dot-ccadb-231121.appspot.com/certdata returns
           type SimpleEntry struct {
           PEM         string `json:"PEM"`
           Fingerprint string `json:"sha256"`
           TrustWeb    bool   `json:"trustWeb"`
           TrustEmail  bool   `json:"trustEmail"`
           }

 The controller classs generates data for following reports by comparing the CCADB and certdata.txt:

 1) "Trust Bits Different between CCADB and certdata.txt"
 This section will be for the entries in certdata.txt that have a corresponding entry in the CCADB 
 (based on SHA256 Fingerprint OR based on Issuer and Serial #), but the trust bit values (Websites; Email) 
 do not match values retuned by the tool in certdata trustWeb and trustEmail.
 Columns:
 Certificate Name <link>, Mozilla Status, Mozilla Trustbits, certdata trustWeb, certdata trustEmail, 
 SHA-256 Fingerprint, Serial Number

 2) "In certdata.txt but not in CCADB"
 This section will be for the entries in certdata.txt that there is no corresponding record for in the CCADB
 (based on SHA256 Fingerprint OR based on Issuer and Serial #).
 Columns:
 Common Name, certdata trustWeb, certdata trustEmail, SHA-256 Fingerprint, Serial Number

 This section of the report, uses the following logic to find the name:

 If (SHA256 found in CCADB) or (serial Number and issuer name is found in CCADB)
     then use the certificate name from CCADB 
 else
     use the issue CN from the tool output

 3) "In CCADB but not in certdata.txt"
 This section will be for the root cert records in the CCADB that have Mozilla status of Included or Change Requested, 
 but were not found in certdata.txt (based on SHA256 Fingerprint OR based on Issuer and Serial #).
 Columns:
 Certificate Name <link>, Mozilla Status, Mozilla Trustbits, SHA-256 Fingerprint, Serial Number

 4) "Values consistent between CCADB and certdata.txt"
 This section will be for the entries in certdata.txt that have a corresponding entry in the CCADB 
 (based on SHA256 Fingerprint OR based on Issuer and Serial #), and both the trust bit values are the same.
 Columns:
 Certificate Name <link>, Mozilla Status, Mozilla Trustbits, certdata trustWeb, certdata trustEmail, 
 SHA-256 Fingerprint, Serial Number
 
 Instructions:  

 *******************************************************************************************************
 Revision History:
 
     1/22/2018 - Created new

     4/28/2019 - Removed the use of heroku app.
                 Saving old notes -> To install certdata parsing tool on Heroku, first clone, create and 
                 deploy the github repository from Mozilla's OneCRL-Tools.

                        heroku login
                        git clone https://github.com/mozilla/OneCRL-Tools
                        cd OneCRL-Tools
                        heroku create
                        ./deploy_to_heroku.sh
         
                 Replaced heroku app with https://certdatadiff-dot-ccadb-231121.appspot.com/certdata  
     6/24/2020 - Changed for "Values consistent between CCADB and certdata.txt" section. Compared both 
                 CCADB Trustbits (Websites and Email) with trustweb and trustemail. If they do not match
                 a record gets added to "Trust Bits Different..." section.  
     
 ******************************************************************************************************/

public with sharing class CompareCertData {
    
    public integer countAllJSON {get; set;}
    
    public transient List<wrapperExtractResult> lstWrapperMResult {get; set;}
    
    public transient List<wrapperExtractResult> lstWrapperTrustBits {get; set;}
    public transient List<wrapperExtractResult> lstWrapperConsitent {get; set;}
    
    public transient List<Account> lstofRootCertsNotFoundInNSS {get; set;}
    
    public CompareCertData(){
    
        lstWrapperMResult = new List<wrapperExtractResult>();
        lstWrapperTrustBits = new List<wrapperExtractResult>();
        lstWrapperConsitent = new List<wrapperExtractResult>();
        lstofRootCertsNotFoundInNSS = new List<Account>();
        
        LoadAllCertsAndCheck();
    }
    
    
    public void LoadAllCertsAndCheck(){
        
        HttpRequest hReq = new HttpRequest();
        // OLD -> hReq.setEndpoint('https://onecrltools.herokuapp.com/certdataold');
        // OLD -> hReq.setEndpoint('https://onecrltools.herokuapp.com/certdata');  
        hReq.setEndpoint('https://certdatadiff-dot-ccadb-231121.appspot.com/certdata');   
        hReq.setMethod('GET');
        Http http = new Http();
        HttpResponse hRes = null;
        hRes = http.send(hReq);
        string strResponse = hRes.getBody();
        
        // here we got results from certdata parser
        List<wrapperResult> lstWrapperResult = (List<wrapperResult>)JSON.deserializeStrict(strResponse, List<wrapperResult>.class);
        countAllJSON = lstWrapperResult.size();
    
        set<string> setCCADBSha256 = new set<string>();
        set<string> setCCADBSerialNumber = new set<string>();
        set<string> setCCADBIssuer = new set<string>();
        map<string,Account> mapSha256Accounts = new map<string,Account>(); // match on SH256 or Issuer+SerialNo
        map<string,Account> mapIssuerSerialAccounts = new map<string,Account>(); // match on SH256 or Issuer+SerialNo
        
        //querying all root certificates
        List<Account> lstAllRootsCerts = [select Id,Name,Certificate_Serial_Number__c,Certificate_Issuer_Common_Name__c,
                SHA_256_Fingerprint__c,Status__c,Trust_Bits__c from Account Where RecordType.DeveloperName = 'Root_Certificate'
                and Name != '<Fill in Cert Name>'];
                //and Status__c in ('Included', 'Change Request') and Trust_Bits__c INCLUDES ('Email', 'Trust_Bits__c')
        
        //loop thorugh all roots certs and fill set and maps.
        for(Account objacc: lstAllRootsCerts){
            setCCADBSha256.add(objacc.SHA_256_Fingerprint__c);
            setCCADBSerialNumber.add(objacc.Certificate_Serial_Number__c);
            setCCADBIssuer.add(objacc.Certificate_Issuer_Common_Name__c);
            mapSha256Accounts.put(objacc.SHA_256_Fingerprint__c, objacc);
            string key = objacc.Certificate_Serial_Number__c + '#' + objacc.Certificate_Issuer_Common_Name__c;
            mapIssuerSerialAccounts.put(key, objacc);
        }
        
        set<string> setNSSSha256 = new set<string>();
        set<string> setNSSSerialNumber = new set<string>();
        set<string> setNSSIssuer = new set<string>();
        
        //create a list of missing certs
        for(wrapperResult objwrapper: lstWrapperResult){
            //if(objwrapper.trustWeb && objwrapper.trustEmail){           
                string issuer = objwrapper.issuer;
                
                //replace : in certdata.txt 
                if(objwrapper.sha256 != null) {
                    objwrapper.sha256 = objwrapper.sha256.replace(':','');
                }
                
                //convert serialnumber to uppercase
                if(objwrapper.serialNumber != null) {
                    objwrapper.serialNumber = objwrapper.serialNumber.toUpperCase();
                }
                
                string issuername = objwrapper.issuer.substring(objwrapper.issuer.indexof('CN=')+3, objwrapper.issuer.length());
                
                Account objMatchFoundAcc = new Account();
                
                //checking id ccadb have sha256 or (serial number + issuer)
                if(setCCADBSha256.contains(objwrapper.sha256) || (setCCADBSerialNumber.contains(objwrapper.serialNumber)
                                            && setCCADBIssuer.contains(issuername))){
                    
                    wrapperExtractResult objWrap = new wrapperExtractResult();
                    if(setCCADBSha256.contains(objwrapper.sha256) && mapSha256Accounts.containskey(objwrapper.sha256)) {
                        objWrap.objAccount = mapSha256Accounts.get(objwrapper.sha256);
                    } else if(setCCADBSerialNumber.contains(objwrapper.serialNumber) && setCCADBIssuer.contains(issuername)) {
                        string key = objwrapper.serialNumber + '#' + issuername;
                        if(mapIssuerSerialAccounts.containskey(key)){
                            objWrap.objAccount = mapIssuerSerialAccounts.get(key);
                        }
                    }
                    objMatchFoundAcc = objWrap.objAccount;
                    objWrap.CCADBtrustEmail = false;
                    objWrap.CCADBtrustWeb = false;
                    if(objWrap.objAccount != null && objWrap.objAccount.Trust_Bits__c != null){
                        if(objWrap.objAccount.Trust_Bits__c.contains('Email')){
                            objWrap.CCADBtrustEmail = true;
                        } 
                        if (objWrap.objAccount.Trust_Bits__c.contains('Websites')){
                            objWrap.CCADBtrustWeb = true;
                        } 
                    }
                    objWrap.sha256 = objwrapper.sha256;
                    objWrap.serialNumber = objwrapper.serialNumber;
                    objWrap.issuer = objwrapper.issuer;
                    objWrap.CommonName = issuername;
                    objWrap.trustWeb = objwrapper.trustWeb;
                    objWrap.trustEmail = objwrapper.trustEmail;
                    //system.debug('objWrap ::: '+objWrap);
                    //if it is trust web in CCADB and certdata.txt then add to Consitent list else Missing Trust bits list
                    if(objMatchFoundAcc.Status__c == 'Included' || objMatchFoundAcc.Status__c == 'Change Request') {
                        /*if(objWrap.CCADBtrustWeb && objWrap.trustWeb && objWrap.trustEmail && objWrap.CCADBtrustEmail) {
                            // report #4
                            lstWrapperConsitent.add(objWrap);
                        } else if((objWrap.CCADBtrustWeb && objWrap.trustWeb && !objWrap.CCADBtrustEmail) || (objWrap.CCADBtrustEmail && objWrap.trustEmail && !objWrap.CCADBtrustWeb)){
                            // report #4
                            lstWrapperConsitent.add(objWrap);
                        } else {*/
                        //both values matches then add it to consistent lsit
                        if(objWrap.CCADBtrustWeb == objWrap.trustWeb && objWrap.trustEmail == objWrap.CCADBtrustEmail) {
                            // report #4
                            lstWrapperConsitent.add(objWrap);
                        } else {
                            // report #1
                            lstWrapperTrustBits.add(objWrap); 
                        }
                    }                     
                }
                //#2 compare with CCADB and found in certdata.text and not found in CCADB
                if(!setCCADBSha256.contains(objwrapper.sha256) && !setCCADBSerialNumber.contains(objwrapper.serialNumber)
                    && !setCCADBIssuer.contains(issuername) || (objMatchFoundAcc != null && objMatchFoundAcc.Status__c != 'Included' && objMatchFoundAcc.Status__c != 'Change Request')){
                    wrapperExtractResult objWrap = new wrapperExtractResult();
                    objWrap.sha256 = objwrapper.sha256;
                    objWrap.serialNumber = objwrapper.serialNumber;
                    objWrap.issuer = objwrapper.issuer;
                    objWrap.CommonName = issuername;
                    objWrap.trustWeb = objwrapper.trustWeb;
                    objWrap.objAccount = objMatchFoundAcc;
                    objWrap.trustEmail = objwrapper.trustEmail;
                    lstWrapperMResult.add(objWrap);
                }
                setNSSSha256.add(objwrapper.sha256);
                setNSSSerialNumber.add(objwrapper.serialNumber);
                setNSSIssuer.add(issuername);
            //}
        }
        
                
        //#3 create a list of certs that are not in certdat.txt but in CCADB
        for(Account objacc: lstAllRootsCerts){
            if(!setNSSSha256.contains(objacc.SHA_256_Fingerprint__c) && !setNSSSerialNumber.contains(objacc.Certificate_Serial_Number__c)
                    && !setNSSIssuer.contains(objacc.Certificate_Issuer_Common_Name__c)){
                if(objacc.Status__c == 'Included' || objacc.Status__c == 'Change Request') {
                    lstofRootCertsNotFoundInNSS.add(objAcc);
                }
            }
        }
    }
    
    public class wrapperResult {
        public string PEM {get; set;}
        public string sha256 {get; set;}
        public string serialNumber {get; set;}
        public string issuer {get; set;}
        public boolean trustWeb {get; set;}
        public boolean trustEmail {get; set;}
        
    }
    
    public class wrapperExtractResult {
        public Account objAccount {get; set;}
        public string sha256 {get; set;}
        public string serialNumber {get; set;}
        public string issuer {get; set;}
        public string CommonName {get; set;}
        public boolean trustWeb {get; set;}
        public boolean trustEmail {get; set;}
        public boolean CCADBtrustWeb {get; set;}
        public boolean CCADBtrustEmail {get; set;}
        
        public wrapperExtractResult (){
            objAccount = new Account();
            trustWeb = false;
            trustEmail = false;
            CCADBtrustWeb = false;
            CCADBtrustEmail = false;
        }
    }
}
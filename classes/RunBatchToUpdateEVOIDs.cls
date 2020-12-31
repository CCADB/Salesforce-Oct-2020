/*******************************************************************************************************
 Name: RunBatchToUpdateEVOIDs

 Dependencies: RunBatchToUpdateEVOIDs controller class, RunEVOIDBatchSchedulerClass class, 
 RunBatchToUpdateEVOIDsTest test class
 
 Description: This batch is created to make callout to EVChecker tool and update 
 “ExtendedValidation.cpp OIDs” field by matching SHA-256 Fingerprint on root certificates.
 
 A scheduler class will run this batch job nightly and update the certs only when there is a 
 change. This process can be run from "Batch Processes" tab too.
 
 The tool (https://evchecker-dot-ccadb-231121.appspot.com) parses a Mozilla file 
 (https://hg.mozilla.org/mozilla-central/file/tip/security/certverifier/ExtendedValidation.cpp) and 
 returns the resuts in JSON:
 
 type EVInfo struct {
    DottedOID         string
    OIDName           string
    SHA256Fingerprint string
    Issuer            string
    Serial            string
 }
 
 This will enable CCADB to:
 - Identify which intermediate certs are enabled for EV, based on the Policy OIDs in their PEM
 - Have a data integrity report comparing EV OIDs known in CCADB versus ExtendedValidation.cpp.
 
 Instructions: Add Remote Site Setting: https://evchecker-dot-ccadb-231121.appspot.com
 *******************************************************************************************************
 Revision History:
 
     11/12/2019 - Created new class.

 ******************************************************************************************************/
 
global class RunBatchToUpdateEVOIDs implements Database.Batchable<Sobject>, Database.AllowsCallouts{
    //used dummy query to run batch
    global final String Query = 'SELECT Id, Name FROM Account Limit 1';
      
    global Database.QueryLocator start(Database.BatchableContext BC){
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext BC, List<Account> lstAccounts){
        if(lstAccounts.size() > 0){
            CallAPI();
        }
    }
    
    global void finish(Database.BatchableContext BC){
    
    }
    
    public static void CallAPI(){
        HttpRequest hReq = new HttpRequest();
        hReq.setEndpoint('https://evchecker-dot-ccadb-231121.appspot.com/nightly');   
        hReq.setMethod('GET');
        Http http = new Http();
        HttpResponse hRes = null;
        string strResponse = '';
        if(Test.isRunningTest()){
            strResponse = '{'+
                              + '"Error": "",'+
                              + '"EVInfos": [{'+
                              +    '"DottedOID": "1.3.6.1.4.1.6334.1.100.1",'+
                              +    '"OIDName": "Cybertrust EV OID",'+
                              +    '"SHA256Fingerprint": "960ADF0063E96356750C2965DD0A0867DA0B9CBD6E77714AEAFB2349AB393DA3",'+
                              +    '"Issuer": "CN=Cybertrust Global Root,O=Cybertrust, Inc",'+
                              +    '"Serial": "00000000000400000000010F85AA2D48"'+
                              +  '}]' +
                        +'}';
        } else {
            hRes = http.send(hReq);
            strResponse = hRes.getBody();
        }
        
        wrapperEVInfos wrapEVInfos = (wrapperEVInfos)JSON.deserialize(strResponse, wrapperEVInfos.class);
        
        set<string> setSHA256Fingerprints = new set<string>();
        //set<string> setSerial = new set<string>();
        map<string, List<string>> mapofDottedOIDs = new map<string, List<string>>();
        //loop on all EVInfos
        for(wrapperEVOID evoid: wrapEVInfos.EVInfos){
            if(string.isnotblank(evoid.SHA256Fingerprint)){
                setSHA256Fingerprints.add(evoid.SHA256Fingerprint);
            }
            /*if(string.isnotblank(evoid.Serial)){
                setSerial.add(evoid.Serial);
            }*/
            string key = evoid.SHA256Fingerprint;//+'#'+evoid.Serial;
            if(mapofDottedOIDs.containskey(key)){
                mapofDottedOIDs.get(key).add(evoid.DottedOID);
            } else {
                mapofDottedOIDs.put(key, new List<string>{evoid.DottedOID});
            }
        }
        map<string, Account> mapExistAccountIds = new map<string, Account>();
        if(setSHA256Fingerprints.size() > 0/* || setSerial.size() > 0*/){
            List<Account> lstAccounts = new List<Account>([select Id,Name,SHA_256_Fingerprint__c,Certificate_Serial_Number__c,
                    ExtendedValidation_cpp_OIDs__c from Account Where 
                    SHA_256_Fingerprint__c =: setSHA256Fingerprints]);// OR Certificate_Serial_Number__c =: setSerial
            for(Account acc: lstAccounts){
                string key = acc.SHA_256_Fingerprint__c;//+'#'+acc.Certificate_Serial_Number__c;
                mapExistAccountIds.put(key, acc);
            } 
            set<id> setofAccIds = new set<Id>(); 
            List<Account> lstAccountsToUpdate = new List<Account>();
            for(string key: mapofDottedOIDs.keyset()){
                if(mapExistAccountIds.containskey(key) && !setofAccIds.contains(mapExistAccountIds.get(key).Id)){
                    string EVCPPOIDs = string.join(mapofDottedOIDs.get(key),'; ');
                    if(EVCPPOIDs != mapExistAccountIds.get(key).ExtendedValidation_cpp_OIDs__c) {
                        Account acc = new Account(Id = mapExistAccountIds.get(key).Id);
                        acc.ExtendedValidation_cpp_OIDs__c = EVCPPOIDs;
                        lstAccountsToUpdate.add(acc);
                        setofAccIds.add(acc.Id);
                    }
                }
            }
            if(lstAccountsToUpdate.size() > 0){
                Database.update(lstAccountsToUpdate,false);
            }      
        }
    }
    
    /*
        Wrapper class
    */
    public class wrapperEVInfos {
        public string Error;    
        public List<wrapperEVOID> EVInfos;
    }
    
    public class wrapperEVOID {
        public string DottedOID;
        public string OIDName;
        public string SHA256Fingerprint;
        public string Issuer;
        public string Serial;
    }
    
}
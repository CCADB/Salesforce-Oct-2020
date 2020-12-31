/*******************************************************************************************************
 Name: OneCRLCertStorageReportController 
 
 Dependencies: OneCRLCertStorageReportController, OneCRLCertStorageReport vf page, 
 OneCRLCertStorageReportControllerTest

 Description: Cert_storage is the new OneCRL (replacing Data Integrity - OneCRL revocations.txt)

 This report shows discrepancies between CCADB public report 
 (PublicIntermediateCertsRevokedWithPEMCSV) and OneCRL data in cert_storage in Firefox Nightly.

 curl -X GET  https://kintointegrity-dot-ccadb-231121.appspot.com/ccadb_cert_storage
 
 The endpoint creates different buckets and this report maps them in corresponding sections: 

 added_and_present_in_cert_storage -> "Added to OneCRL" and in OneCRL 

 expired_and_present_in_cert_storage -> "Cert Expired" and in OneCRL 

 ready_to_add_and_present_in_cert_storage -> "Ready to Add" and in OneCRL 

 Absent_from_ccadb_and_present_in_cert_storage -> Not in CCADB but in OneCRL 

    Note that for this section there will not be SHA-256 values for most of them, so no mapping 
    to the cert records in the CCADB for this section.
    
 Added_and_absent_from_cert_storage -> "Added to OneCRL" but not in OneCRL 

 expired_and_absent_from_cert_storage -> "Cert Expired" and not in OneCRL 

 ready_to_add_and_absent_from_cert_storage -> "Ready to Add" and not in OneCRL 

   Extra processing on CCDB side to pull out the records with “Parent Cert Revoked” revocation status.

 No_revocation_status_and_absent_from_cert_storage -> No "OneCRL Status" given in the CCADB report - Revocation Status of "Parent Cert Revoked"

   Extra processing on CCADB side to pull out the records with Revocation Status other than “Parent Cert Revoked”
   
 No_revocation_status_and_absent_from_cert_storage -> No "OneCRL Status" given in the CCADB report - Revocation Status other than "Parent Cert Revoked" (Number of records: 10)
 
 Sample JSON structure returned by the tool (issuer, serial, sha)....
 {
  "added_and_present_in_cert_storage": [
    {
      "issuer_name": "CN=WISeKey CertifyID Policy GB CA 1,O=WISeKey,C=CH",
      "serial": "09:8B:AD:EE:59:C7:FA:B9",
      "sha_256": "68E6292FD4AA384D63A5F4FA8BD885BD1656E3509BA4206673E0660A169FE701"
    },
    {
      "issuer_name": "OU=Security Communication RootCA2,O=SECOM Trust Systems CO.\\,LTD.,C=JP",
      "serial": "22:B9:B1:48:37:13:B9:93:B6",
      "sha_256": "623A9F2163E33585905B6F65A4997596FC785FA54437A41D22794A5F47813A29"
    },
    
    .
    .
    .
    
 There can also be following entries (subject, key_hash, sha)....
 
 {
  "subject": "C=NL, O=DigiNotar, CN=DigiNotar Root CA, Email=info@diginotar.nl",
  "key_hash": "qQOvjAe7kbDZ4/OjDG1TM5/FvUfl1r20dlmIYMBooCQ=",
  "sha_256": null
 },   
 
 For additioanl references https://github.com/mozilla/CCADB-Tools   
 
 Instructions: Remote site setting for the tool should be active in the Salesforce org (OneCRLCertStorage)
 *******************************************************************************************************
 Revision History:
 
     11/5/2019 - Created new class
     12/5/2019 - Added Mozilla Root Status to 2 sections of the report
     6/10/2020 - Updated code to handle subject, key_hash, sha entries in JSON resopse. Also added a new 
                 section for these values and named it 'Distrusted by Subject and Key'
 ******************************************************************************************************/

public with sharing class OneCRLCertStorageReportController {
    
    public transient WrapperAllOneCRLs wrapOneCRLs {get; set;}
    
    public transient List<wrapperOneCRL> lstDistructedKeyHas {get; set;}
    
    public OneCRLCertStorageReportController(){
    
        wrapOneCRLs = new WrapperAllOneCRLs();
        lstDistructedKeyHas = new List<wrapperOneCRL>();
         
        LoadOneCRLData();
    }
    
    public void LoadOneCRLData(){
        
        HttpRequest hReq = new HttpRequest();
        // stopped working hReq.setEndpoint('https://kintointegrity-dot-ccadb-231121.appspot.com/ccadb_cert_storage'); 
        // stopped working hReq.setEndpoint('http://34.107.213.59/ccadb_cert_storage');  
        // stopped working hReq.setEndpoint('http://34.236.154.37/ccadb_cert_storage');  
        
        hReq.setEndpoint('http://34.107.213.59/ccadb_cert_storage'); 
       
        hReq.setTimeout(120000); 
        hReq.setMethod('GET');
        Http http = new Http();
        HttpResponse hRes = null;
        string strResponse = '';
        if(Test.isRunningTest()){
            strResponse = '{'+
                          '"added_and_present_in_cert_storage": ['+
                            '{'+
                              '"issuer_name": "CN=cPanel",'+
                              '"serial": "5AE4653E507975C3C793E362DA6F7CB9",'+
                              '"sha_256": "C61E8AE4B701345DD0C06495BA0BE106757955D85D76C734ADAD116710AAB0C2"'+
                            '},'+
                            '{'+
                              '"subject": "C=NL, O=DigiNotar, CN=DigiNotar Root CA, Email=info@diginotar.nl",'+
                              '"key_hash": "qQOvjAe7kbDZ4/OjDG1TM5/FvUfl1r20dlmIYMBooCQ=",'+
                              '"sha_256": null'+
                           '}'+
                          '],'+
                          '"added_and_absent_from_cert_storage": ['+
                            '{'+
                              '"issuer_name": "CN=cPanel",'+
                              '"serial": "5AE4653E507975C3C793E362DA6F7CB9",'+
                              '"sha_256": "C61E8AE4B701345DD0C06495BA0BE106757955D85D76C734ADAD116710AAB0C2"'+
                            '}'+
                          '],'+
                          '"expired_and_present_in_cert_storage": ['+
                            '{'+
                              '"issuer_name": "CN=cPanel",'+
                              '"serial": "5AE4653E507975C3C793E362DA6F7CB9",'+
                              '"sha_256": "C61E8AE4B701345DD0C06495BA0BE106757955D85D76C734ADAD116710AAB0C2"'+
                            '},'+
                            '{'+
                              '"subject": "C=NL, O=DigiNotar, CN=DigiNotar Root CA, Email=info@diginotar.nl",'+
                              '"key_hash": "qQOvjAe7kbDZ4/OjDG1TM5/FvUfl1r20dlmIYMBooCQ=",'+
                              '"sha_256": null'+
                           '}'+
                          '],'+
                          '"expired_and_absent_from_cert_storage": ['+
                            '{'+
                              '"issuer_name": "CN=cPanel",'+
                              '"serial": "5AE4653E507975C3C793E362DA6F7CB9",'+
                              '"sha_256": "C61E8AE4B701345DD0C06495BA0BE106757955D85D76C734ADAD116710AAB0C2"'+
                            '}'+
                          '],'+
                          '"ready_to_add_and_present_in_cert_storage": ['+
                            '{'+
                              '"issuer_name": "CN=cPanel",'+
                              '"serial": "5AE4653E507975C3C793E362DA6F7CB9",'+
                              '"sha_256": "C61E8AE4B701345DD0C06495BA0BE106757955D85D76C734ADAD116710AAB0C2"'+
                            '},'+
                            '{'+
                              '"subject": "C=NL, O=DigiNotar, CN=DigiNotar Root CA, Email=info@diginotar.nl",'+
                              '"key_hash": "qQOvjAe7kbDZ4/OjDG1TM5/FvUfl1r20dlmIYMBooCQ=",'+
                              '"sha_256": null'+
                           '}'+
                          '],'+
                          '"ready_to_add_and_absent_from_cert_storage": ['+
                            '{'+
                              '"issuer_name": "CN=cPanel",'+
                              '"serial": "5AE4653E507975C3C793E362DA6F7CB9",'+
                              '"sha_256": "C61E8AE4B701345DD0C06495BA0BE106757955D85D76C734ADAD116710AAB0C2"'+
                            '}'+
                          '],'+
                          '"absent_from_ccadb_and_present_in_cert_storage": ['+
                            '{'+
                              '"issuer_name": "CN=cPanel",'+
                              '"serial": "5AE4653E507975C3C793E362DA6F7CB9",'+
                              '"sha_256": "C61E8AE4B701345DD0C06495BA0BE106757955D85D76C734ADAD116710AAB0C2"'+
                            '}'+
                          '],'+
                          '"absent_from_ccadb_and_absent_from_cert_storage": ['+
                            '{'+
                              '"issuer_name": "CN=cPanel",'+
                              '"serial": "5AE4653E507975C3C793E362DA6F7CB9",'+
                              '"sha_256": "C61E8AE4B701345DD0C06495BA0BE106757955D85D76C734ADAD116710AAB0C2"'+
                            '}'+
                          '],'+
                          '"no_revocation_status_and_in_cert_storage": ['+
                            '{'+
                              '"issuer_name": "CN=cPanel",'+
                              '"serial": "5AE4653E507975C3C793E362DA6F7CB9",'+
                              '"sha_256": "C61E8AE4B701345DD0C06495BA0BE106757955D85D76C734ADAD116710AAB0C2"'+
                            '}'+
                          '],'+
                          '"no_revocation_status_and_absent_from_cert_storage": ['+
                            '{'+
                              '"issuer_name": "CN=cPanel",'+
                              '"serial": "5AE4653E507975C3C793E362DA6F7CB9",'+
                              '"sha_256": "C61E8AE4B701345DD0C06495BA0BE106757955D85D76C734ADAD116710AAB0C2"'+
                            '}'+
                          ']'+
                        '}';
        } else {
            hRes = http.send(hReq);
            strResponse = hRes.getBody();
        }
        
        wrapOneCRLs = (WrapperAllOneCRLs)JSON.deserialize(strResponse, WrapperAllOneCRLs.class);
        
        //system.debug('result ::: '+wrapOneCRLs);
        
        map<string, Account> mapInterCerts = new map<string, Account>();
        
        for(Account objAcc: [select Id,Name,OneCRL_Status__c,SHA_256_Fingerprint__c,Certificate_Issuer_Common_Name__c,
                    Certificate_Issuer_Organization__c,Certificate_Serial_Number__c,Revocation_Status__c,Mozilla_Root_Status__c
                    from Account Where RecordType.Name = 'Intermediate Certificate']){
            mapInterCerts.put(objAcc.SHA_256_Fingerprint__c, objAcc);
        }
        
        if(wrapOneCRLs != null) {
            Integer index = 0;
            List<Integer> lstIndexs = new List<Integer>();
            for(wrapperOneCRL wp: wrapOneCRLs.added_and_present_in_cert_storage){
                wp = fillWCRL(wp, mapInterCerts);
                //fill distrcuted subject key has list
                if(wp.subject != null && string.isnotblank(wp.subject)){
                    lstDistructedKeyHas.add(wp);
                    lstIndexs.add(index);
                }
                index++;
            }
            //remove record from index
            if(lstIndexs.size() > 0){
                for(Integer id: lstIndexs){
                    wrapOneCRLs.added_and_present_in_cert_storage.remove(id);
                }
            }
            
            index = 0;
            lstIndexs = new List<Integer>();
            for(wrapperOneCRL wp: wrapOneCRLs.added_and_absent_from_cert_storage){
                wp = fillWCRL(wp, mapInterCerts);
                //fill distrcuted subject key has list
                if(wp.subject != null && string.isnotblank(wp.subject)){
                    lstDistructedKeyHas.add(wp);
                    lstIndexs.add(index);
                }
                index++;
            }
            //remove record from index
            if(lstIndexs.size() > 0){
                for(Integer id: lstIndexs){
                    wrapOneCRLs.added_and_absent_from_cert_storage.remove(id);
                }
            }
            
            index = 0;
            lstIndexs = new List<Integer>();
            for(wrapperOneCRL wp: wrapOneCRLs.expired_and_present_in_cert_storage){
                wp = fillWCRL(wp, mapInterCerts);
                //fill distrcuted subject key has list
                if(wp.subject != null && string.isnotblank(wp.subject)){
                    lstDistructedKeyHas.add(wp);
                    lstIndexs.add(index);
                }
                index++;
            }
            //remove record from index
            if(lstIndexs.size() > 0){
                for(Integer id: lstIndexs){
                    wrapOneCRLs.expired_and_present_in_cert_storage.remove(id);
                }
            }
            
            index = 0;
            lstIndexs = new List<Integer>();
            for(wrapperOneCRL wp: wrapOneCRLs.expired_and_absent_from_cert_storage){
                wp = fillWCRL(wp, mapInterCerts);
                //fill distrcuted subject key has list
                if(wp.subject != null && string.isnotblank(wp.subject)){
                    lstDistructedKeyHas.add(wp);
                    lstIndexs.add(index);
                }
                index++;
            }
            //remove record from index
            if(lstIndexs.size() > 0){
                for(Integer id: lstIndexs){
                    wrapOneCRLs.expired_and_absent_from_cert_storage.remove(id);
                }
            }
            
            index = 0;
            lstIndexs = new List<Integer>();
            for(wrapperOneCRL wp: wrapOneCRLs.ready_to_add_and_present_in_cert_storage){
                wp = fillWCRL(wp, mapInterCerts);
                //fill distrcuted subject key has list
                if(wp.subject != null && string.isnotblank(wp.subject)){
                    lstDistructedKeyHas.add(wp);
                    lstIndexs.add(index);
                }
                index++;
            }
            //remove record from index
            if(lstIndexs.size() > 0){
                for(Integer id: lstIndexs){
                    wrapOneCRLs.ready_to_add_and_present_in_cert_storage.remove(id);
                }
            }
            
            index = 0;
            lstIndexs = new List<Integer>();
            for(wrapperOneCRL wp: wrapOneCRLs.ready_to_add_and_absent_from_cert_storage){
                wp = fillWCRL(wp, mapInterCerts);
                //fill distrcuted subject key has list
                if(wp.subject != null && string.isnotblank(wp.subject)){
                    lstDistructedKeyHas.add(wp);
                    lstIndexs.add(index);
                }
                index++;
            }
            //remove record from index
            if(lstIndexs.size() > 0){
                for(Integer id: lstIndexs){
                    wrapOneCRLs.ready_to_add_and_absent_from_cert_storage.remove(id);
                }
            }
            
            index = 0;
            lstIndexs = new List<Integer>();
            for(wrapperOneCRL wp: wrapOneCRLs.absent_from_ccadb_and_present_in_cert_storage){
                wp = fillWCRL(wp, mapInterCerts);
                //fill distrcuted subject key has list
                if(wp.subject != null && string.isnotblank(wp.subject)){
                    lstDistructedKeyHas.add(wp);
                    lstIndexs.add(index);
                }
                index++;
            }
            //remove record from index
            if(lstIndexs.size() > 0){
                for(Integer id: lstIndexs){
                    wrapOneCRLs.absent_from_ccadb_and_present_in_cert_storage.remove(id);
                }
            }
            
            index = 0;
            lstIndexs = new List<Integer>();
            for(wrapperOneCRL wp: wrapOneCRLs.no_revocation_status_and_absent_from_cert_storage){
                wp = fillWCRL(wp, mapInterCerts);
                //fill distrcuted subject key has list
                if(wp.subject != null && string.isnotblank(wp.subject)){
                    lstDistructedKeyHas.add(wp);
                    lstIndexs.add(index);
                }
                index++;
            }
            //remove record from index
            if(lstIndexs.size() > 0){
                for(Integer id: lstIndexs){
                    wrapOneCRLs.no_revocation_status_and_absent_from_cert_storage.remove(id);
                }
            }
            
            wrapOneCRLs.added_and_present_in_cert_storage.sort();
            wrapOneCRLs.added_and_absent_from_cert_storage.sort();
            wrapOneCRLs.expired_and_present_in_cert_storage.sort();
            wrapOneCRLs.expired_and_absent_from_cert_storage.sort();
            wrapOneCRLs.ready_to_add_and_present_in_cert_storage.sort();
            wrapOneCRLs.ready_to_add_and_absent_from_cert_storage.sort();
            wrapOneCRLs.absent_from_ccadb_and_present_in_cert_storage.sort();
            wrapOneCRLs.no_revocation_status_and_absent_from_cert_storage.sort();
        }
    }
    
    //fill wrapper class by common function
    public wrapperOneCRL fillWCRL(wrapperOneCRL wp, map<string, Account> mapInterCerts){
        if(wp.serial != null && string.isnotblank(wp.serial)){
            wp.serial = wp.serial.replace(':',''); 
        }
        if(wp.sha_256 != null && mapInterCerts.containskey(wp.sha_256)) {
            wp.objAccount = mapInterCerts.get(wp.sha_256);
            wp.issuercommonname = wp.objAccount.Certificate_Issuer_Common_Name__c;
        } else {
            wp.objAccount = new Account();
        }
        return wp;
    }
    
    /*
        Wrapper classes
    */
    public class WrapperAllOneCRLs {
        public List<wrapperOneCRL> added_and_present_in_cert_storage {get; set;}
        public List<wrapperOneCRL> added_and_absent_from_cert_storage {get; set;}
        public List<wrapperOneCRL> expired_and_present_in_cert_storage {get; set;}
        public List<wrapperOneCRL> expired_and_absent_from_cert_storage {get; set;}
        public List<wrapperOneCRL> ready_to_add_and_present_in_cert_storage {get; set;}
        public List<wrapperOneCRL> ready_to_add_and_absent_from_cert_storage {get; set;}
        public List<wrapperOneCRL> absent_from_ccadb_and_present_in_cert_storage {get; set;}
        //public List<wrapperOneCRL> absent_from_ccadb_and_absent_from_cert_storage {get; set;}
        //public List<wrapperOneCRL> no_revocation_status_and_in_cert_storage{get; set;}
        public List<wrapperOneCRL> no_revocation_status_and_absent_from_cert_storage {get; set;}
        public WrapperAllOneCRLs () {
            added_and_present_in_cert_storage = new List<wrapperOneCRL>();
            added_and_absent_from_cert_storage = new List<wrapperOneCRL>();
            expired_and_present_in_cert_storage = new List<wrapperOneCRL>();
            expired_and_absent_from_cert_storage = new List<wrapperOneCRL>();
            ready_to_add_and_present_in_cert_storage = new List<wrapperOneCRL>();
            ready_to_add_and_absent_from_cert_storage = new List<wrapperOneCRL>();
            absent_from_ccadb_and_present_in_cert_storage = new List<wrapperOneCRL>();
            //absent_from_ccadb_and_absent_from_cert_storage  = new List<wrapperOneCRL>();
            //no_revocation_status_and_in_cert_storage = new List<wrapperOneCRL>();
            no_revocation_status_and_absent_from_cert_storage = new List<wrapperOneCRL>();
        }
    }
    
    public class wrapperOneCRL implements Comparable {
        public string issuer {get; set;}
        public string serial {get; set;}
        public string sha_256 {get; set;}
        public string subject {get; set;}
        public string key_hash {get; set;}
        public Account objAccount {get; set;}
        public string issuercommonname {get; set;}
        
        public Integer compareTo(Object objToCompare) {
            wrapperOneCRL compareToRec = (wrapperOneCRL)objToCompare;
            if (issuercommonname > compareToRec.issuercommonname) {
                return 1;
            } else if (issuercommonname < compareToRec.issuercommonname) {
                return -1;
            } else {
                if (serial > compareToRec.serial) {
                    return 1;
                } else if (serial < compareToRec.serial) {
                    return -1;
                } else {
                    return 0;
                }          
            } 
        }
    }
}
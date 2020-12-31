/*******************************************************************************************************
  THIS REPORT IS OBSOLETED - IT HAS BEEN REPLACED BY OneCRLCertStorageReport "OneCRL Cert Storage Report"
  *******************************************************************************************************

 Name: OneCRLDataIntegrityReportController

 Dependencies: OneCRLDataIntegrityReport controller class, OneCRLDataIntegrityReport vf page, 
 OneCRLDataIntegrityReportControllerTest test class

 Description: This program generates a user friendly report for Salesforce users to show
 discrepancies between CCADB public report (PublicIntermediateCertsRevokedWithPEMCSV) and 
 the OneCRL Raw Data file (https://firefox.settings.services.mozilla.com/v1/buckets/blocklists/collections/certificates/records) 
 using a tool https://onecrldiff-dot-ccadb-231121.appspot.com/
 
 Tool details can be found on Github
 https://github.com/mozilla/CCADB-Tools/blob/master/oneCRLDiffCCADB/oneCRL/oneCRL.go

 The tool output has JOSN format:
 type Cert struct {
    serial           string // Decimal representation
    revocationStatus string // "OneCRL Status" from the CCADB report
    issuerCN         string // Issuer Common Name
    issuerON         string // Issuer Organization Name
    fingerprint      string // "SHA-256 Fingerprint" from the CCADB report
 }
 
 Tool produces 9 different errors categories:

    "Added to OneCRL" and in OneCRL
    "Cert Expired" and in OneCRL
    "Ready to Add" and in OneCRL 
    Not in CCADB but in OneCRL 
    "Added to OneCRL" but not in OneCRL 
    "Cert Expired" and not in OneCRL
    "Ready to Add" and not in OneCRL 
    No "OneCRL Status" given in the CCADB report - Revocation Status of "Parent Cert Revoked" 
    No "OneCRL Status" given in the CCADB report - Revocation Status of "Not Revoked" or blank
    

 Instructions: Remote site setting for the tool should be active in the Salesforce org
 *******************************************************************************************************
 Revision History:
 
     6/28/2019 - Created new class
     8/5/2019  - For No "OneCRL Status"section, separated the records with Revocation Status of 
                (“Parent Cert Revoked”) and ("Not Revoked", blank)
     2/9/2020 - Updated report description                      
 ******************************************************************************************************/
 
public with sharing class OneCRLDataIntegrityReportController {
    
    public transient WrapperAllOneCRLs wrapOneCRLs {get; set;}
    
    public OneCRLDataIntegrityReportController(){
    
        wrapOneCRLs = new WrapperAllOneCRLs();
         
        LoadOneCRLData();
    }
    
    public void LoadOneCRLData(){
        
        HttpRequest hReq = new HttpRequest();
        hReq.setEndpoint('https://onecrldiff-dot-ccadb-231121.appspot.com');   
        hReq.setMethod('GET');
        Http http = new Http();
        HttpResponse hRes = null;
        string strResponse = '';
        if(Test.isRunningTest()){
            strResponse = '{'+
                          '"AddedAndPresentInOneCRL": ['+
                            '{'+
                              '"serial": "4E94C4FF77765012587D81F0D8B4A8C3",'+
                              '"revocationStatus": "Added to OneCRL",'+
                              '"issuerCN": "BT Class 2 CA - G2",'+
                              '"issuerON": "British Telecommunications plc",'+
                              '"fingerprint": "C61E8AE4B701345DD0C06495BA0BE106757955D85D76C734ADAD116710AAB0C2"'+
                            '}'+
                          '],'+
                          '"ExpiredAndPresentInOneCRL": ['+
                            '{'+
                              '"serial": "4E94C4FF77765012587D81F0D8B4A8C3",'+
                              '"revocationStatus": "Added to OneCRL",'+
                              '"issuerCN": "BT Class 2 CA - G2",'+
                              '"issuerON": "British Telecommunications plc",'+
                              '"fingerprint": "C61E8AE4B701345DD0C06495BA0BE106757955D85D76C734ADAD116710AAB0C2"'+
                            '}'+
                          '],'+
                          '"ReadyToAddAndPresentInOneCRL": ['+
                            '{'+
                              '"serial": "4E94C4FF77765012587D81F0D8B4A8C3",'+
                              '"revocationStatus": "Added to OneCRL",'+
                              '"issuerCN": "BT Class 2 CA - G2",'+
                              '"issuerON": "British Telecommunications plc",'+
                              '"fingerprint": "C61E8AE4B701345DD0C06495BA0BE106757955D85D76C734ADAD116710AAB0C2"'+
                            '}'+
                          '],'+
                          '"AbsentFromCCADBAndPresentInOneCRL": ['+
                          '{'+
                              '"serial": "4E94C4FF77765012587D81F0D8B4A8C3",'+
                              '"revocationStatus": "Added to OneCRL",'+
                              '"issuerCN": "BT Class 2 CA - G2",'+
                              '"issuerON": "British Telecommunications plc",'+
                              '"fingerprint": "C61E8AE4B701345DD0C06495BA0BE106757955D85D76C734ADAD116710AAB0C2"'+
                            '}'+
                          '],'+
                          '"AddedAndAbsentFromOneCRL": ['+
                            '{'+
                              '"serial": "4E94C4FF77765012587D81F0D8B4A8C3",'+
                              '"revocationStatus": "Added to OneCRL",'+
                              '"issuerCN": "BT Class 2 CA - G2",'+
                              '"issuerON": "British Telecommunications plc",'+
                              '"fingerprint": "C61E8AE4B701345DD0C06495BA0BE106757955D85D76C734ADAD116710AAB0C2"'+
                            '}'+
                          '],'+
                          '"ExpiredAndAbsentFromOneCRL": ['+
                            '{'+
                              '"serial": "4E94C4FF77765012587D81F0D8B4A8C3",'+
                              '"revocationStatus": "Added to OneCRL",'+
                              '"issuerCN": "BT Class 2 CA - G2",'+
                              '"issuerON": "British Telecommunications plc",'+
                              '"fingerprint": "C61E8AE4B701345DD0C06495BA0BE106757955D85D76C734ADAD116710AAB0C2"'+
                            '}'+
                          '],'+
                          '"ReadyToAddAndAbsentFromOneCRL": ['+
                            '{'+
                              '"serial": "4E94C4FF77765012587D81F0D8B4A8C3",'+
                              '"revocationStatus": "Added to OneCRL",'+
                              '"issuerCN": "BT Class 2 CA - G2",'+
                              '"issuerON": "British Telecommunications plc",'+
                              '"fingerprint": "C61E8AE4B701345DD0C06495BA0BE106757955D85D76C734ADAD116710AAB0C2"'+
                            '}'+
                          '],'+
                          '"AbsentFromCCADBAndAbsentFromOneCRL": ['+
                            '{'+
                              '"serial": "4E94C4FF77765012587D81F0D8B4A8C3",'+
                              '"revocationStatus": "Added to OneCRL",'+
                              '"issuerCN": "BT Class 2 CA - G2",'+
                              '"issuerON": "British Telecommunications plc",'+
                              '"fingerprint": "C61E8AE4B701345DD0C06495BA0BE106757955D85D76C734ADAD116710AAB0C2"'+
                            '}'+
                          '],'+
                          '"NoRevocationStatus": ['+
                            '{'+
                              '"serial": "4E94C4FF77765012587D81F0D8B4A8C3",'+
                              '"revocationStatus": "Added to OneCRL",'+
                              '"issuerCN": "BT Class 2 CA - G2",'+
                              '"issuerON": "British Telecommunications plc",'+
                              '"fingerprint": "C61E8AE4B701345DD0C06495BA0BE106757955D85D76C734ADAD116710AAB0C2"'+
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
                    Certificate_Issuer_Organization__c,Certificate_Serial_Number__c,Revocation_Status__c
                    from Account Where RecordType.Name = 'Intermediate Certificate']){
            mapInterCerts.put(objAcc.SHA_256_Fingerprint__c, objAcc);
        }
        
        if(wrapOneCRLs != null) {
            for(wrapperOneCRL wp: wrapOneCRLs.AddedAndPresentInOneCRL){
                if(wp.fingerprint != null && mapInterCerts.containskey(wp.fingerprint)) {
                    wp.objAccount = mapInterCerts.get(wp.fingerprint);
                } else {
                    wp.objAccount = new Account();
                }
            }
            for(wrapperOneCRL wp: wrapOneCRLs.ExpiredAndPresentInOneCRL){
                if(wp.fingerprint != null && mapInterCerts.containskey(wp.fingerprint)) {
                    wp.objAccount = mapInterCerts.get(wp.fingerprint);
                } else {
                    wp.objAccount = new Account();
                }
            }
            for(wrapperOneCRL wp: wrapOneCRLs.ReadyToAddAndPresentInOneCRL){
                if(wp.fingerprint != null && mapInterCerts.containskey(wp.fingerprint)) {
                    wp.objAccount = mapInterCerts.get(wp.fingerprint);
                } else {
                    wp.objAccount = new Account();
                }
            }
            for(wrapperOneCRL wp: wrapOneCRLs.AbsentFromCCADBAndPresentInOneCRL){
                if(wp.fingerprint != null && mapInterCerts.containskey(wp.fingerprint)) {
                    wp.objAccount = mapInterCerts.get(wp.fingerprint);
                } else {
                    wp.objAccount = new Account();
                }
            }
            for(wrapperOneCRL wp: wrapOneCRLs.AddedAndAbsentFromOneCRL){
                if(wp.fingerprint != null && mapInterCerts.containskey(wp.fingerprint)) {
                    wp.objAccount = mapInterCerts.get(wp.fingerprint);
                } else {
                    wp.objAccount = new Account();
                }
            }
            for(wrapperOneCRL wp: wrapOneCRLs.ExpiredAndAbsentFromOneCRL){
                if(wp.fingerprint != null && mapInterCerts.containskey(wp.fingerprint)) {
                    wp.objAccount = mapInterCerts.get(wp.fingerprint);
                } else {
                    wp.objAccount = new Account();
                }
            }
            for(wrapperOneCRL wp: wrapOneCRLs.ReadyToAddAndAbsentFromOneCRL){
                if(wp.fingerprint != null && mapInterCerts.containskey(wp.fingerprint)) {
                    wp.objAccount = mapInterCerts.get(wp.fingerprint);
                } else {
                    wp.objAccount = new Account();
                }
            }
            for(wrapperOneCRL wp: wrapOneCRLs.AbsentFromCCADBAndAbsentFromOneCRL){
                if(wp.fingerprint != null && mapInterCerts.containskey(wp.fingerprint)) {
                    wp.objAccount = mapInterCerts.get(wp.fingerprint);
                } else {
                    wp.objAccount = new Account();
                }
            }
            for(wrapperOneCRL wp: wrapOneCRLs.NoRevocationStatus){
                if(wp.fingerprint != null && mapInterCerts.containskey(wp.fingerprint)) {
                    wp.objAccount = mapInterCerts.get(wp.fingerprint);
                } else {
                    wp.objAccount = new Account();
                }
            }
            
        }
    }
    
    /*
        Wrapper classes
    */
    public class WrapperAllOneCRLs {
        public List<wrapperOneCRL> AddedAndPresentInOneCRL{get; set;}
        public List<wrapperOneCRL> ExpiredAndPresentInOneCRL{get; set;}
        public List<wrapperOneCRL> ReadyToAddAndPresentInOneCRL{get; set;}
        public List<wrapperOneCRL> AbsentFromCCADBAndPresentInOneCRL{get; set;}
        public List<wrapperOneCRL> AddedAndAbsentFromOneCRL{get; set;}
        public List<wrapperOneCRL> ExpiredAndAbsentFromOneCRL{get; set;}
        public List<wrapperOneCRL> ReadyToAddAndAbsentFromOneCRL{get; set;}
        public List<wrapperOneCRL> AbsentFromCCADBAndAbsentFromOneCRL{get; set;}
        public List<wrapperOneCRL> NoRevocationStatus{get; set;}
        public WrapperAllOneCRLs () {
            AddedAndPresentInOneCRL = new List<wrapperOneCRL>();
            ExpiredAndPresentInOneCRL = new List<wrapperOneCRL>();
            ReadyToAddAndPresentInOneCRL = new List<wrapperOneCRL>();
            AbsentFromCCADBAndPresentInOneCRL = new List<wrapperOneCRL>();
            AddedAndAbsentFromOneCRL = new List<wrapperOneCRL>();
            ExpiredAndAbsentFromOneCRL = new List<wrapperOneCRL>();
            ReadyToAddAndAbsentFromOneCRL = new List<wrapperOneCRL>();
            AbsentFromCCADBAndAbsentFromOneCRL = new List<wrapperOneCRL>();
            NoRevocationStatus = new List<wrapperOneCRL>();
        }
    }
    
    public class wrapperOneCRL {
        public string serial {get; set;}
        public string revocationStatus {get; set;}
        public string issuerCN {get; set;}
        public string issuerON {get; set;}
        public string fingerprint {get; set;}
        public Account objAccount {get; set;}
    }
}
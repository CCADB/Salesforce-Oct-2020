/*******************************************************************************************************
 Name: CPACanadaServiceController

 Dependencies:  CPACanadaServiceController, CPACanadaServiceDeltaBatch, 
 CPACanadaServiceAllScheduler, CPACanadaServiceDeltaScheduler, CPACanadaServiceControllerTest

 Description: Class is created for call API to get CPA Canada report file urls and update in Salesforce.
 
 Program logic is driven by 'parseResponse' parameter, it can be 'All' or 'Delta'
 
    -> All CPACanada Files from SF are stored in map.
    -> If all fields (Seal id, Seal url, Report id, Report urls) on SF record match Delta records or All records 
       then do nothing.    
    -> If None of existing CPACanda records matches with 4 fields, then we will create a new CPACanada record.
    -> If the Seal ID exists in Salesforce then update is done to the record. 
    -> If Seal url/Report id/Report url found that means partial match, an email alert is sent.
    -> If the record count is different when DELTA job is running then ALL job is automatically launched to sync all records
    -> Email alert is sent when there is any connection issue, exception, whenever there is a partial match on the record.
    -> Email goes out to 'CCADB Admin' and 'Mozilla CA Program Manager' orgwide addresses. From address is CCADB Support.
      
 
 Instructions:  
    -- To run program from dev console 
    Debug stements have "getResponse  :::", "CPACanada :::: "
    GET ALL CPACANADA FILEs
        ***CPACanadaServiceController.getAllCPACanadaFiles();
    GET DELTA CPACANADA FIles
        ***CPACanadaServiceController.getDeltaCPACanadaFiles();
        Run Batch for 'DELTA' records (if count doesn't match, 'ALL' records job is launched to sync all records)
        CPACanadaServiceDeltaBatch batch = new CPACanadaServiceDeltaBatch();
        Database.executebatch(batch, 1);
    
    ==Test Scheduled Job==
    String sched1 = '0 43 10 ?  '; // set time whenever you want to run
    CPACanadaServiceAllScheduler SC = new CPACanadaServiceAllScheduler(); //take instance of schedule job which you want to schedule.
    System.schedule('Test All CPACanada', sched1, SC);  
    
 *******************************************************************************************************
 Revision History:
 
     2/19/2019 - Created new class
     4/10/2019 - Allow batch job to update existing records in Salesforce (Seal Id can have updates to Report
                 URL and Report Id in case there are corrections done by CPACanada)
    
 ******************************************************************************************************/

public with sharing class CPACanadaServiceController{
    
    @future(callout=true)
    public static void getDeltaCPACanadaFiles() {
        List<CPACanada_API_Detail__c> lstCPACanadaAPI = new List<CPACanada_API_Detail__c>([select Id,Name,End_Point__c,Grant_Type__c,
                    Password__c,Username__c from CPACanada_API_Detail__c Where Name = 'CPACanada API' Limit 1]);
        if(lstCPACanadaAPI.size() > 0) {
            string EndPoint = lstCPACanadaAPI[0].End_Point__c;
            string FinalEndPoint = EndPoint + 'api/data/getalldeltarecords';
            ClsCPACanada cpaCanadaFiles = getCPACanadaFiles(FinalEndPoint, 'GET');
            parseResponse(cpaCanadaFiles, 'Delta');
        }
    }
    
    @future(callout=true)
    public static void getAllCPACanadaFiles(){
        List<CPACanada_API_Detail__c> lstCPACanadaAPI = new List<CPACanada_API_Detail__c>([select Id,Name,End_Point__c,Grant_Type__c,
                    Password__c,Username__c from CPACanada_API_Detail__c Where Name = 'CPACanada API' Limit 1]);
        if(lstCPACanadaAPI.size() > 0) {
            string EndPoint = lstCPACanadaAPI[0].End_Point__c;
            string FinalEndPoint = EndPoint + 'api/data/getallrecords';
            ClsCPACanada cpaCanadaFiles = getCPACanadaFiles(FinalEndPoint, 'POST');
            parseResponse(cpaCanadaFiles, 'All'); 
        }
    }
    
    public static boolean parseResponse(ClsCPACanada cpaCanadaFiles, string type){
        Boolean isCountMatch = true;
        try {
            if(cpaCanadaFiles !=  null && string.isnotblank(cpaCanadaFiles.status) && cpaCanadaFiles.status.tolowercase() == 'success'){
                map<string, CPACanada_File__c> mapSealIdWiseCPACanadaFiles = new map<string, CPACanada_File__c>();
                for(CPACanada_File__c objCPACanada: [select Id,Name,Report_Id__c,Report_URL__c,Seal_URL__c from CPACanada_File__c]){
                    mapSealIdWiseCPACanadaFiles.put(objCPACanada.Name.tolowercase(), objCPACanada);
                    mapSealIdWiseCPACanadaFiles.put(objCPACanada.Report_Id__c.tolowercase(), objCPACanada);
                    mapSealIdWiseCPACanadaFiles.put(objCPACanada.Report_URL__c.tolowercase(), objCPACanada);
                    mapSealIdWiseCPACanadaFiles.put(objCPACanada.Seal_URL__c.tolowercase(), objCPACanada);
                } 
                Integer countOfDeltaRecords = Integer.valueof(cpaCanadaFiles.countOfDeltaRecords);
                Integer countOfAllRecords = Integer.valueof(cpaCanadaFiles.countOfAllRecords);
                string strEmailBody = '';
                if((type == 'All' && countOfAllRecords > 0) || (type == 'Delta' && countOfDeltaRecords > 0)) {
                    List<CPACanada_File__c> lstCPACanadaFilesToUpsert = new List<CPACanada_File__c>();
                    //system.debug('Count of CPACanada Files from API ::: '+cpaCanadaFiles.listOfFileMappings.size());
                    for(cls_listOfFileMappings filemapping: cpaCanadaFiles.listOfFileMappings){
                        //system.debug('CPACanada API :::: '+filemapping);
                        string sealId = filemapping.sealID.trim().tolowercase();
                        string sealURL = filemapping.sealURL.trim().tolowercase();
                        string reportId = filemapping.reportID.trim().tolowercase();
                        string reportURL = filemapping.reportURL.trim().tolowercase();
                        //contains all fields in SF CPACanada database
                        if(mapSealIdWiseCPACanadaFiles.containskey(sealId) && mapSealIdWiseCPACanadaFiles.containskey(sealURL) && mapSealIdWiseCPACanadaFiles.containskey(reportId) &&
                            mapSealIdWiseCPACanadaFiles.containskey(reportURL)){
                            //get record id
                            string recordId = mapSealIdWiseCPACanadaFiles.get(sealId).Id;
                            //compare record id with all 4 fields and if matches then matched with 4 fields.
                            if(recordId == mapSealIdWiseCPACanadaFiles.get(sealURL).Id && recordId == mapSealIdWiseCPACanadaFiles.get(reportId).Id &&
                                recordId == mapSealIdWiseCPACanadaFiles.get(reportURL).Id) {
                                //record match with 4 all fields.
                            } else {
                                //this is case where Seal URL, Report Id, Report URL is exist on any other Seal Id. - we will skip that record.
                                strEmailBody += '\n\nCPACanda Seal ID: '+filemapping.SealID.trim() + '\nCPACanda Seal URL: ' + filemapping.sealURL.trim() + '\nCPACanda Report Id: ' + filemapping.reportID.trim() + '\nCPACanda Report URL: '+ filemapping.reportURL.trim() + '\nCCADB Salesforce Record Id: '+ recordId;
                            }
                        } 
                        //contains any of one value in SF database
                        else if(mapSealIdWiseCPACanadaFiles.containskey(sealId) || mapSealIdWiseCPACanadaFiles.containskey(sealURL) || mapSealIdWiseCPACanadaFiles.containskey(reportId) ||
                            mapSealIdWiseCPACanadaFiles.containskey(reportURL)){
                            //if seal url exist but seal id is different
                            if(mapSealIdWiseCPACanadaFiles.containskey(sealURL) && mapSealIdWiseCPACanadaFiles.get(sealURL).Name != sealId){
                                strEmailBody += '\n\nCPACanda Seal ID: '+filemapping.SealID.trim() + '\nCPACanda Seal URL: ' + filemapping.sealURL.trim() + '\nCPACanda Report Id: ' + filemapping.reportID.trim() + '\nCPACanda Report URL: '+ filemapping.reportURL.trim() + '\nCCADB Salesforce Record Id: '+ mapSealIdWiseCPACanadaFiles.get(sealURL).Id;
                            } else 
                            //if report Id exist but seal id is different
                            if(mapSealIdWiseCPACanadaFiles.containskey(reportId) && mapSealIdWiseCPACanadaFiles.get(reportId).Name != sealId){
                                strEmailBody += '\n\nCPACanda Seal ID: '+filemapping.SealID.trim() + '\nCPACanda Seal URL: ' + filemapping.sealURL.trim() + '\nCPACanda Report Id: ' + filemapping.reportID.trim() + '\nCPACanda Report URL: '+ filemapping.reportURL.trim() + '\nCCADB Salesforce Record Id: '+ mapSealIdWiseCPACanadaFiles.get(reportId).Id;
                            } else
                            //if report url exist but seal id is different
                            if(mapSealIdWiseCPACanadaFiles.containskey(reportURL) && mapSealIdWiseCPACanadaFiles.get(reportURL).Name != sealId){
                                strEmailBody += '\n\nCPACanda Seal ID: '+filemapping.SealID.trim() + '\nCPACanda Seal URL: ' + filemapping.sealURL.trim() + '\nCPACanda Report Id: ' + filemapping.reportID.trim() + '\nCPACanda Report URL: '+ filemapping.reportURL.trim() + '\nCCADB Salesforce Record Id: '+ mapSealIdWiseCPACanadaFiles.get(reportURL).Id;
                            } else 
                            //seal id contains
                            if(mapSealIdWiseCPACanadaFiles.containskey(sealId)){
                                CPACanada_File__c objCF = new CPACanada_File__c();
                                objCF.Id = mapSealIdWiseCPACanadaFiles.get(sealId).Id;
                                objCF.Name = filemapping.sealID.trim();
                                objCF.Report_Id__c = filemapping.reportID.trim();
                                objCF.Seal_URL__c = filemapping.sealURL.trim();
                                objCF.Report_URL__c = filemapping.reportURL.trim();
                                lstCPACanadaFilesToUpsert.add(objCF);
                            }
                        }
                        //create a new record. 
                        else {
                            CPACanada_File__c objCF = new CPACanada_File__c();
                            objCF.Name = filemapping.sealID.trim();
                            objCF.Report_Id__c = filemapping.reportID.trim();
                            objCF.Seal_URL__c = filemapping.sealURL.trim();
                            objCF.Report_URL__c = filemapping.reportURL.trim();
                            lstCPACanadaFilesToUpsert.add(objCF);
                        }
                    }
                    if(lstCPACanadaFilesToUpsert.size() > 0) {
                        upsert lstCPACanadaFilesToUpsert;
                    }
                } 
                //query and compare size for all CPA Canada records
                string EBody = '';
                List<CPACanada_File__c> lstAllFiles = [select Id,Name,Report_Id__c,Report_URL__c,Seal_URL__c from CPACanada_File__c];
                if(lstAllFiles.size() != countOfAllRecords){
                    isCountMatch = false;
                    if(type == 'All'){
                        EBody = 'Count of Salesforce records '+lstAllFiles.size() +' does not match count of CPACanada records '+countOfAllRecords+'';
                    }
                    if(string.isnotblank(strEmailBody)){
                        EBody += '\nOne or more records sent by CPACanada have partial match on CCADB record(s):\n';
                        EBody += strEmailBody;
                    }
                }
                if(string.isnotblank(strEmailBody) && string.isblank(EBody)){
                    EBody += '\nOne or more records sent by CPACanada have partial match on CCADB record(s):\n';
                    EBody += strEmailBody;
                }
                if(string.isnotblank(EBody)){
                    sendEmail(EBody);
                }
            } else {
                sendEmail('CPACanada API is not giving correct response.');
            }
        } catch (Exception ex){
            sendEmail('Error: '+ ex.getMessage() + ' at Line ' + ex.getLineNumber());
        }
        return isCountMatch;
    }
    
    public static void sendEmail(string strBody){
        if(string.isnotblank(strBody)) {
            //create a new instance of singleEmailMessage
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            
            List<String> lstToAddresses = new List<String>();
            for(OrgWideEmailAddress orgWide : [select id, Address, DisplayName from OrgWideEmailAddress where DisplayName = 'Mozilla CA Program Manager' 
                    or DisplayName = 'CCADB Support' or DisplayName = 'CCADB Admin']) {
                if(orgWide.DisplayName == 'CCADB Support') {
                    mail.setOrgWideEmailAddressId(orgWide.id); 
                }
                
                //set the TO addresses on the email
                if(orgWide.DisplayName != 'CCADB Support') {
                    lstToAddresses.add(orgWide.address);
                }
            }
            mail.setToAddresses(lstToAddresses);
            mail.setSubject('CPACanada - WebTrust (New Seals Batch Job)');
            
            string strEmailBody = '\nPlease check for possible error conditions:\n\n';
            strEmailBody += strBody;
            
            mail.setPlainTextBody(strEmailBody);   
            if(!Test.IsRunningTest()){
                Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
            }
        }
    }
    
    public static ClsCPACanada getCPACanadaFiles(string EndPoint, string HTTPMethod){
        string strToken = getToken();
        ClsCPACanada cpaCanadaFiles;
        HTTPResponse getResponse = SendRequest(EndPoint,HTTPMethod,'',strToken,'application/json');
        string strResponse = '';
        if(getResponse != null && getResponse.getStatusCode() == 200 && string.isnotblank(getResponse.getBody())){
            strResponse = getResponse.getBody();
        } else if(Test.IsRunningTest()) {
            strResponse = '"{\"status\":\"Success\",\"countOfDeltaRecords\":\"2\",\"countOfAllRecords\":\"2\",\"listOfFileMappings\":[{\"SealID\":\"499\",\"ReportID\":\"221273\",\"reportURL\":\"https://www.cpacanada.ca/generichandlers/aptifyattachmenthandler.ashx?attachmentid=221273\",\"sealURL\":\"https://www.cpacanada.ca/webtrustseal?sealid=499\"},{\"SealID\":\"10000\",\"ReportID\":\"221649\",\"reportURL\":\"https://www.cpacanada.ca/generichandlers/aptifyattachmenthandler.ashx?attachmentid=221649\",\"sealURL\":\"https://www.cpacanada.ca/webtrustseal?sealid=10000\"}]}"';
        }
        if(string.isnotblank(strResponse)) { 
            strResponse = strResponse.replaceall('\\\\', '');
            strResponse = strResponse.removeStart('"');
            strResponse = strResponse.removeEnd('"');
            cpaCanadaFiles = parseCPACanadaResponse(strResponse);
        }
        return cpaCanadaFiles;
    }
    
    public static string getToken(){
        string strToken = '';
        
        List<CPACanada_API_Detail__c> lstCPACanadaAPI = new List<CPACanada_API_Detail__c>([select Id,Name,End_Point__c,Grant_Type__c,
                    Password__c,Username__c from CPACanada_API_Detail__c Where Name = 'CPACanada API' Limit 1]);
        if(lstCPACanadaAPI.size() > 0) {
            string EndPoint = lstCPACanadaAPI[0].End_Point__c;
            string Username = lstCPACanadaAPI[0].Username__c;
            string Password = lstCPACanadaAPI[0].Password__c;
            string GrantType = lstCPACanadaAPI[0].Grant_Type__c;
            
            String Parameters = 'grant_type='+ EncodingUtil.urlEncode(GrantType ,'UTF-8') 
                                + '&username=' + EncodingUtil.urlEncode(Username,'UTF-8') 
                                + '&password=' + EncodingUtil.urlEncode(Password, 'UTF-8');
            
            string FinalEndPoint = EndPoint + 'token';
            string strTestResponse = '{'+
                    '"access_token": "K6KSmLewTygwzy4TTGvQjVwZTUPgRydbUGcvuMPXDDMgcyXsVirR6k3u8COjpuTqcSJXmSUUBNzsOAd3Z7Lo8XCXPBXSLM5RH6RHdJPzu2W961TKVLSyd-L6T1YXgKZp7NqHwlc7F6LaDW9Y9OV14cjTuymA3LsptfLkUjrmkmiAWicVr78TzjQzC8z4SWrUrw90eEI1En2-a3vQeJz8Q2ncTbUuvjiFEXRrHC1q0XuVwz3jp040Godi72jWdIfmioHyeTYFOSFPWshh51aHmQuohY1180Csodd8FM_DPHX35tkq3DWgSLogcmlSjQBl",'+
                    '"token_type": "bearer",'+
                    '"expires_in": 86399'+
                '}';
            HTTPResponse getResponse = SendRequest(FinalEndPoint,'POST',Parameters,'','application/x-www-form-urlencoded');
            
            if(getResponse != null && getResponse.getStatusCode() == 200 && string.isnotblank(getResponse.getBody())){
                string strResponse = getResponse.getBody();
                Map<String, Object> mapResponse = (Map<String, Object>)JSON.deserializeUntyped(strResponse);
                if(mapResponse.containskey('access_token')){
                    strToken = string.valueof(mapResponse.get('access_token'));
                }
            }
        }
        return strToken;
    }
    
    public static HTTPResponse SendRequest(string Endpoint, string RequestMethod, string RequestBody, string Token,  string ContentType){
        HttpRequest req = new HttpRequest();
        HTTPResponse res;
        try {
            req.setEndpoint(Endpoint);
            if(string.isnotblank(RequestBody)){
                req.setBody(RequestBody);
            }
            req.setMethod(RequestMethod);
            req.setTimeOut(120000);
            req.setHeader('Content-Type',ContentType);
            req.setHeader('Content-Length', string.valueof(RequestBody.length()));
            if(string.isnotblank(Token)){
                req.setHeader('Authorization','Bearer '+Token);
            }
            if(!Test.isRunningTest()){
                Http http = new Http();
                res = http.send(req);
                //system.debug('res '+res);
            }
            return res;
        } catch(Exception ex){
            sendEmail(res != null ? res.getBody() : ('Error: '+ ex.getMessage() + ' at Line ' + ex.getLineNumber()));
            return res;
        }
    }
    
    public class ClsCPACanada {
        public String status;   //Success
        public String countOfDeltaRecords;  //7
        public String countOfAllRecords;    //9
        public cls_listOfFileMappings[] listOfFileMappings;
    }
    
    public class cls_listOfFileMappings {
        public String sealID;   //10005
        public String reportID; //220268
        public String reportURL;    //https://www.cpacanada.ca/generichandlers/aptifyattachmenthandler.ashx?attachmentid=220268
        public String sealURL;  //https://www.cpacanada.ca/webtrustseal?sealid=10005
    }
    
    public static ClsCPACanada parseCPACanadaResponse(String json){
        return (ClsCPACanada) System.JSON.deserialize(json, ClsCPACanada.class);
    }
}
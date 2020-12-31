/*
    Description: Audit Archieve Helper
    Changes:
    Date                Change
    25th March 2018     added condtion to check if content type is only pdf then it should download files
    28 Nov 2018 Made exception for CPACanada files - convert the url to lowercase and allow any file type 
*/

public class RunAuditArchiveBatchHelper {
    
    private String sessionId, folderId;
    public Set<String> existingRemoteSiteSettings;
    
    public RunAuditArchiveBatchHelper(String sessionId, String folderId, Set<String> existingRemoteSiteSettings){
        
        this.sessionId = sessionId;
        this.folderId = folderId;
        this.existingRemoteSiteSettings = existingRemoteSiteSettings;
    }
    
    public class MetadataServiceExamplesException extends Exception { }
    
    /*
    * method to return unique alphanumeric numbers
    */
    public String getRandomName(){
    
        String hashString = '1000' + String.valueOf(Datetime.now().formatGMT('yyyy-MM-dd HH:mm:ss.SSS'));
        Blob hash = Crypto.generateDigest('MD5', Blob.valueOf(hashString));
        String hexDigest = EncodingUtil.convertToHex(hash);
        return hexDigest;
    }
    
    /**
     * Example helper method to interpret a SaveResult, throws an exception if errors are found
     *
    public void handleSaveResults(MetadataService.SaveResult saveResult) {
        // Nothing to see?
        if(saveResult==null || saveResult.success)
            return;
        // Construct error message and throw an exception
        if(saveResult.errors!=null) {
            List<String> messages = new List<String>();
            messages.add(
                (saveResult.errors.size() == 1 ? 'Error ' : 'Errors ') +
                    'occured processing component ' + saveResult.fullName + '.');
            for(MetadataService.Error error : saveResult.errors)
                messages.add(
                    error.message + ' (' + error.statusCode + ').' +
                    ( error.fields!=null && error.fields.size()>0 ?
                        ' Fields ' + String.join(error.fields, ',') + '.' : '' ) );
            if(messages.size()>0)
                throw new MetadataServiceExamplesException(String.join(messages, ' '));
        }
        
        if(!saveResult.success)
            throw new MetadataServiceExamplesException('Request failed with no specified error.');
    }*/
    
    public Boolean createRemoteSiteSetting(String domain, String sessionId){
        
        String rName = getRandomName();
        rName = 'z' + rName;
        MetadataService.MetadataPort service = createService(sessionId);     
        MetadataService.RemoteSiteSetting remoteSiteSetting = new MetadataService.RemoteSiteSetting();
        remoteSiteSetting.fullName = rName;//'Audit_File_External_System.now();//TODO: put here random unique name
        remoteSiteSetting.description = 'Remote Site URL for Audit File - Used by internal batch program.';
        remoteSiteSetting.disableProtocolSecurity = false;
        remoteSiteSetting.isActive = true;
        remoteSiteSetting.url = domain;
        
        List<MetadataService.SaveResult> results = new List<MetadataService.SaveResult>();
        //handleSaveResults(results[0]);
        if(!Test.isRunningTest()){
            results = service.createMetadata(new MetadataService.Metadata[] { remoteSiteSetting });
            if(results == null || results[0].errors != null){
                return false;
            }
        }
        
        return true;
    }
    
    public static MetadataService.MetadataPort createService(String sessionId) {
        
        MetadataService.MetadataPort service = new MetadataService.MetadataPort();
        service.SessionHeader = new MetadataService.SessionHeader_element();
        service.SessionHeader.sessionId = sessionId;
        return service;
    }
    
    public static Set<String> getExistingRemoteSettings(String sessionId){
        
        /* 
        //Commenting this method because this allow us to fetch only 10 settings at a moment. 
        //instead used below tooling api to fetch al domain
        
        Set<String> setUniqueDomains = new Set<String>();
        MetadataService.MetadataPort service = createService(sessionId);     
        List<MetadataService.ListMetadataQuery> queries = new List<MetadataService.ListMetadataQuery>();        
        MetadataService.ListMetadataQuery queryRemoteSiteSettings = new MetadataService.ListMetadataQuery();
        queryRemoteSiteSettings.type_x = 'RemoteSiteSetting';
        queries.add(queryRemoteSiteSettings);            
        MetadataService.FileProperties[] fileProperties = service.listMetadata(queries, 25);
        List<String> uniqueRemoteSiteNames = new List<String>();
        
        for(MetadataService.FileProperties fileProperty : fileProperties){
            // System.debug(fileProperty.fullName);
            uniqueRemoteSiteNames.add(fileProperty.fullName);
        }
        //TODO: read can only read upto 10 remote site; we need to move read logic in constructor    
        MetadataService.IReadResult readResult = service.readMetadata('RemoteSiteSetting', uniqueRemoteSiteNames);
        // System.debug(JSON.serialize(readResult));
        RemoteSiteSettingJSON2Apex response = RemoteSiteSettingJSON2Apex.parse(JSON.serialize(readResult));
        for(RemoteSiteSettingJSON2Apex.Records result : response.records){
            if(result.isActive)
                 setUniqueDomains.add(result.url);
        }

        return setUniqueDomains;
        */
        
        Set<String> setUniqueDomains = new Set<String>();
        String instanceURL = System.URL.getSalesforceBaseUrl().getHost().remove('-api');
        String toolingendpoint = 'https://'+instanceURL+'/services/data/v37.0/tooling/query/?q=select+EndpointUrl+from+RemoteProxy+where+isActive+=+true';
        HttpRequest hReq = new HttpRequest();
        hReq.setHeader('Authorization', 'Bearer ' + sessionId);
        hReq.setHeader('Content-Type', 'application/json');
        hReq.setEndpoint(toolingendpoint);
        hReq.setMethod('GET');
        Http http = new Http();
        HttpResponse hRes;
        if(!Test.IsRunningTest()) {
            hRes = http.send(hReq);
        } else {
            setUniqueDomains.add('https://cert.webtrust.org');
        }
        if(hRes != null && hRes.getStatusCode() == 200){
            // System.debug('hRes: '+hRes.getBody());
            ReadRemoteProxyJSON2Apex obj = ReadRemoteProxyJSON2Apex.parse(hRes.getBody());
            for(ReadRemoteProxyJSON2Apex.Records urls : obj.Records){
                setUniqueDomains.add(urls.EndpointUrl);
            }
        }
        
        return setUniqueDomains;
    }
    
    public void registerDomainToRemoteSiteSettings(String auditURL){
        
        String domain;
        
        try{
            URL auditFileUrl = new URL(auditURL);
            domain = auditFileUrl.getProtocol() + '://' + auditFileUrl.getHost();
        }catch(Exception e){
            domain = auditURL;
            // System.debug('ProtocolException: '+e.getMessage());
        }
        // System.debug('Creating RemoteProxy for: '+domain);
        if(!this.existingRemoteSiteSettings.contains(domain)){
            
            Boolean isSuccess = this.createRemoteSiteSetting(domain, this.sessionId);
            if(isSuccess){
                this.existingRemoteSiteSettings.add(domain);
            }
        }
    }
    
    private HttpResponse doCallout(String endPoint){
        
        HttpRequest hReq = new HttpRequest();
        hReq.setEndpoint(endPoint);
        hReq.setMethod('GET');
        Http http = new Http();
        HttpResponse hRes = null;
        try{
            hRes = http.send(hReq);
        }catch(CalloutException cExep){
            // System.debug('CalloutException: '+cExep.getMessage());
            throw new MetadataServiceExamplesException(cExep.getMessage());
        }
        
        return hRes;
        
    }
    
    private String getFileName(String requestHeader, Date auditDate){
        
        String fileName = null;
        String fileName2 = auditDate != null ? auditDate.format() : '';
        if(requestHeader != null){
            
            Pattern regex = Pattern.compile('(?<=filename=\").*?(?=\")');
            Matcher regexMatcher = regex.matcher(requestHeader);
            if (regexMatcher.find()) {
                fileName = regexMatcher.group();
            }
            
        }
        
        fileName = fileName != null ? fileName2 + ' - ' + fileName : fileName2 + ' - ' + getRandomName();
        
        return fileName;
    }
    
    public CalloutResult doFetchDocument(String accountId, String parentAccountId, Date auditDate, String endPoint, String documentType){
        
        CalloutResult result = new CalloutResult();
        Attachment doc;
        HttpResponse hRes;
        if(Limits.getCallouts() != Limits.getLimitCallouts()){
            
            try{
                //added condition to check if endpoint is cpacanada then make it lower case as It is giving error when endpoint has some caps letters.
                //E.G.=>https://www.cpacanada.ca/GenericHandlers/AptifyAttachmentHandler.ashx?AttachmentID=221722
                if(endPoint.contains('www.cpacanada.ca')){
                    endPoint = endPoint.toLowercase();    
                }
                hRes = doCallout(endPoint);
            }catch(MetadataServiceExamplesException exp){
                result.status = exp.getMessage();
                //if(exp.getMessage() == 'Server chose TLSv1, but that protocol version is not enabled or not supported by the client.'){
                    result.documentSO = null;
                    result.statuscode = 500;
                    result.status = exp.getMessage();
                //}
            }
            
            Boolean redirect = false;
            //added condtion to check if content type is only pdf then it should download files - 25th March 2018
            //added condition to chekc if endpoint is www.cpacanada.ca then also allow them without checking content type - 27th Nov 18
            if(result.statuscode != 500 && hRes != null && hRes.getStatusCode() == 200 && (endPoint.contains('www.cpacanada.ca') || hRes.getHeader('Content-Type') == 'application/pdf'  || Test.isRunningTest())){//ContentType = 'Pdf'
                doc = new Attachment(Name = getFileName(hRes.getHeader('Content-Disposition'), auditDate), ParentId = parentAccountId, Body = hRes.getBodyAsBlob(),
                Description = accountId+'-'+documentType, contentType = hRes.getHeader('Content-Type'));//'00l21000000K8K9AAK'
                result.documentSO = doc;
                result.statuscode = 200;
                result.status = 'OK';
            }
            
            if(result.statuscode != 500 && hRes != null && hRes.getStatusCode() >= 300 && hRes.getStatusCode() <= 307 && hRes.getStatusCode() != 306){
                
                do{
                    String loc = hRes.getHeader('Location'); // get location of the redirect
                    // System.debug('**Loc: '+loc);
                    
                    if(loc == null) {
                        redirect = false;
                        continue;
                    }
                    
                    this.registerDomainToRemoteSiteSettings(loc);
                    try{
                    
                        hRes = doCallout(loc);
                            }catch(MetadataServiceExamplesException exp){
                        result.status = exp.getMessage();
                        //if(exp.getMessage() == 'Server chose TLSv1, but that protocol version is not enabled or not supported by the client.'){
                            result.statuscode = 500;
                        //}
                    }
                    //added condtion to check if content type is only pdf then it should download files - 25th March 2018
                    if(hRes != null && hRes.getStatusCode() == 200 && (hRes.getHeader('Content-Type') == 'application/pdf' || Test.isRunningTest())){
                        redirect = false;//ContentType = 'Pdf'
                        doc = new Attachment(Name = getFileName(hRes.getHeader('Content-Disposition'), auditDate), ParentId = parentAccountId, Body = hRes.getBodyAsBlob(),
                        Description = accountId+'-'+documentType, contentType = hRes.getHeader('Content-Type'));//'00l21000000K8K9AAK'
                        result.documentSO = doc;
                        result.statuscode = 200;
                        result.status = 'OK';
                    }
            
                    if(hRes != null && result.statuscode != 500 && hRes.getStatusCode() != 500 && hRes.getStatusCode() >= 300 && hRes.getStatusCode() <= 307 && hRes.getStatusCode() != 306) {
                        redirect= true;
                    }
                    
                } while(redirect && Limits.getCallouts() != Limits.getLimitCallouts());
            }
        }
        
        return result;
    }
    
    public class CalloutResult {
        
        public Attachment documentSO{get; set;}
        public Integer statusCode{get; set;}
        public String status{get; set;}
        
        public CalloutResult(){
            documentSO = new Attachment();
            statusCode = 0;
            status = '';
        }
    }
}
public with sharing class GetUrlsController {
    
    public String internalUserUrl {get; set;}
    public String communityUserUrl {get; set;}
    public String MozillaRootInclusionUrl {get; set;}
    private String objectId;
    
    public GetUrlsController(){
        this.MozillaRootInclusionUrl = '';
        this.objectId = ApexPages.currentPage().getParameters().get('id');
        this.internalUserUrl = protocolAndHost + '/' + this.objectId;
        
        List<Domain> lstDomains = [SELECT Domain, DomainType FROM Domain];
        this.communityUserUrl = 'https://'+ lstDomains[0].Domain + '/' + this.objectId;
        
        if(objectId != null) {
            List<Case> lstCase = new List<Case>([select Id,CaseNumber from Case Where Id =: objectId and RecordType.Name = 'CA Root Inclusion Request']);
            if(lstCase.size() > 0) {
                MozillaRootInclusionUrl = 'https://ccadb-public.secure.force.com/mozilla/PrintViewForCase?CaseNumber='+lstCase[0].CaseNumber;
            }
        }
    }
    
    public PageReference goBack(){
        
        PageReference pref = new PageReference('/'+this.objectId);
        return pref;
    }
    
    /**
     * Determines the true API hostname for a Salesforce org using the Identity API.
     * eg 'https://pod.salesforce.com' (most orgs)
     * eg 'https://custom.my.salesforce.com' (my domain)
     * eg 'https://custom--dev.pod.my.salesforce.com' (sandbox orgs)
     */
    static public String protocolAndHost {
        get {
            if (protocolAndHost == null) {
                //memoize
                String orgId = UserInfo.getOrganizationId();
                String userId = UserInfo.getUserId();
                String sessionId = UserInfo.getSessionId();
    
                //we can trust getSalesforceBaseUrl within batches and schedules (but not in VF)
                if (sessionId == null) return Url.getSalesforceBaseUrl().toExternalForm().replace('http:', 'https:');
    
                PageReference pr = new PageReference('/id/' + orgId + '/' + userId);
                pr.getParameters().put('oauth_token', sessionId);
                pr.getParameters().put('format', 'json');
    
                //within test context use url class, else derive from identity api
                String data = Test.isRunningTest() ? '{"urls": {"rest": "' + Url.getSalesforceBaseUrl().toExternalForm() + '"}}' : pr.getContent().toString();
                Map<String,Object> result = (Map<String,Object>)Json.deserializeUntyped(data);
                Map<String,Object> urls = (Map<String,Object>)result.get('urls');
                Url rest = new Url((String)urls.get('rest'));
                protocolAndHost = rest.getProtocol() + '://' + rest.getHost();
            }
    
            return protocolAndHost;
        }
    }
}
@isTest
global class MockHttpResponseGenerator implements HttpCalloutMock{
    
    Map<String, HttpCalloutMock> requests;
    
    public MockHttpResponseGenerator(Map<String, HttpCalloutMock> requests) {
        this.requests = requests;
    }
    
    public HTTPResponse respond(HTTPRequest req) {
        
        HttpCalloutMock mock = requests.get(req.getEndpoint());
        HTTPResponse resp;
        if (mock != null) {
            resp = mock.respond(req);
        }
            
        return resp;
    }
}
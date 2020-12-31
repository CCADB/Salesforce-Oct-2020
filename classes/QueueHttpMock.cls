@isTest
public class QueueHttpMock implements HttpCalloutMock {
    
    HttpResponse[] responses = new HttpResponse[0];
    
    public void addResponse(HttpResponse response) {
        responses.add(response);
    }
    
    public HttpResponse respond(HttpRequest request) {
        return responses.remove(0);
    }
}
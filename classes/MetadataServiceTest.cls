@isTest
public class MetadataServiceTest{
    
    private class WebServiceMockImpl implements WebServiceMock{
    
        public void doInvoke(Object stub, Object request, Map<String, Object> response, String endpoint, String soapAction, 
        String requestName, String responseNS, String responseName, String responseType) {
            
            if(request instanceof MetadataService.listMetadata_element)//keep
                response.put('response_x', new MetadataService.listMetadataResponse_element());//keep
            else if(request instanceof  MetadataService.createMetadata_element)//keep
                response.put('response_x', new MetadataService.createMetadataResponse_element());//keep
            return;
        }
    }
    
    @IsTest
    private static void testListMetadata() {   
        
        System.Test.setMock(WebServiceMock.class, new WebServiceMockImpl());
        MetadataService metaDataService = new MetadataService();
        MetadataService.MetadataPort metaDataPort = new MetadataService.MetadataPort();
        
        metaDataPort.listMetadata(null, null);
    }
    
    @IsTest
    private static void testReadMetadata() {   
        
        System.Test.setMock(WebServiceMock.class, new WebServiceMockImpl());
        MetadataService metaDataService = new MetadataService();
        MetadataService.MetadataPort metaDataPort = new MetadataService.MetadataPort();
        try{
            metaDataPort.readMetadata('RemoteSiteSettings', new String[]{'google.com', 'salesforce.com'});
        }catch(Exception e){}
    }
    
    @IsTest
    private static void testCreateMetadata() {   
        
        System.Test.setMock(WebServiceMock.class, new WebServiceMockImpl());
        MetadataService metaDataService = new MetadataService();
        MetadataService.MetadataPort metaDataPort = new MetadataService.MetadataPort();
        
        metaDataPort.createMetadata(null);
    }
    
    @isTest
    private static void coverGeneratedCodeTypes(){
        
        new MetadataService.listMetadataResponse_element();
        new MetadataService.ReadResult();
        new MetadataService.RetrieveResult();
        new MetadataService.RetrieveMessage();
        new MetadataService.Error();
        new MetadataService.ExtendedErrorDetails();
        new MetadataService.LogInfo();
        new MetadataService.ListMetadataQuery();
        new MetadataService.readRemoteSiteSettingResponse_element();
        new MetadataService.SaveResult();
        new MetadataService.createMetadataResponse_element();
        new MetadataService.createMetadata_element();
        new MetadataService.readMetadata_element();
        new MetadataService.listMetadataResponse_element();
        new MetadataService.AllOrNoneHeader_element();
        new MetadataService.DebuggingInfo_element();
        new MetadataService.DebuggingHeader_element();
        new MetadataService.SessionHeader_element();
        new MetadataService.CallOptions_element();
        new MetadataService.FileProperties();
        new MetadataService.RemoteSiteSetting();
        
    }
    
    @isTest
    private static void elfMissingGetRecordsTest(){
        new MetadataService.ReadRemoteSiteSettingResult().getRecords();
    }
    
    @isTest
    private static void elfMissingGetResultTest(){
        new MetadataService.readRemoteSiteSettingResponse_element().getResult();
    }
}
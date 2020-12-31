@isTest
public class RunAuditArchiveBatchTest{
    
    public static string strOrgInstance = System.URL.getSalesforceBaseURL().toExternalForm();
    
    static testmethod void testMethod0(){
        
        RunAuditArchiveBatchController obj = new RunAuditArchiveBatchController();
        obj.startBatch();
        
        //schduled job
        RunAuditArchiveBatchSchedulerClass.scheduleMe('Test Run Audit Batch');
    }
    
    static testmethod void testMethod1(){
        
        Account caOwnerAccount = getCAOwnerAccount();
        insert caOwnerAccount;
        
        Account rootAccount = getChildAccount();
        rootAccount.ParentId = caOwnerAccount.Id;
        rootAccount.Standard_Audit__c = 'https://cert.webtrust.org/SealFile?seal=1987&file=pdf';
        rootAccount.Standard_Audit_Type__c = 'WebTrust';
        rootAccount.Standard_Audit_Statement_Date__c = system.today().addDays(10);
        rootAccount.Standard_Audit_Period_Start_Date__c = system.today().addDays(2);
        rootAccount.Standard_Audit_Period_End_Date__c = system.today().addDays(5);
        rootAccount.BR_Audit__c = 'https://cert.webtrust.org/SealFile?seal=1988&file=pdf';
        rootAccount.BR_Audit_Type__c = 'WebTrust';
        rootAccount.BR_Audit_Statement_Date__c = system.today().addDays(10);
        rootAccount.BR_Audit_Period_Start_Date__c = system.today().addDays(2);
        rootAccount.BR_Audit_Period_End_Date__c = system.today().addDays(5);
        rootAccount.EV_Audit__c = 'https://cert.webtrust.org/SealFile?seal=1989&file=pdf';
        rootAccount.EV_Audit_Type__c = 'WebTrust';
        rootAccount.EV_Audit_Statement_Date__c = system.today().addDays(10);
        rootAccount.EV_Audit_Period_Start_Date__c = system.today().addDays(2);
        rootAccount.EV_Audit_Period_End_Date__c = system.today().addDays(5);
        rootAccount.EV_Code_Signing_Audit__c = 'https://cert.webtrust.org/SealFile?seal=1989&file=pdf';
        rootAccount.EV_Code_Signing_Audit_Type__c= 'WebTrust';
        rootAccount.EV_Code_Signing_Audit_Statement_Date__c = system.today().addDays(10);
        rootAccount.EV_Code_Signing_Audit_Period_Start_Date__c = system.today().addDays(2);
        rootAccount.EV_Code_Signing_Audit_Period_End_Date__c = system.today().addDays(5);
        insert rootAccount;
        
        String remotesiteSeetingResponse = '{'+
          '"size" : 1,'+
          '"totalSize" : 1,'+
         '"done" : true,'+
          '"queryLocator" : null,'+
          '"entityTypeName" : "RemoteProxy",'+
          '"records" : [ {'+
            '"attributes" : {'+
              '"type" : "RemoteProxy",'+
              '"url" : "/services/data/v37.0/tooling/sobjects/RemoteProxy/0rp21000000CfBOAA0"'+
            '},'+
            '"EndpointUrl" : '+strOrgInstance+''+
          '} ]'+
        '}';
        
        SingleRequestMock mock1 = new SingleRequestMock(200, 'Complete', remotesiteSeetingResponse, null);
        RunAuditArchiveBatch batch = new RunAuditArchiveBatch();
        
        Test.startTest();
            
            Test.setMock(HttpCalloutMock.class, mock1);
            Database.executeBatch(batch, 1);
            
        Test.stopTest();
    }
    
    //only std link is valid
    static testmethod void testMethod2(){
        
        Account caOwnerAccount = getCAOwnerAccount();
        insert caOwnerAccount;
        
        Account rootAccount = getChildAccount();
        rootAccount.ParentId = caOwnerAccount.Id;
        rootAccount.Standard_Audit__c = 'https://cert.webtrust.org/SealFile?seal=1987&file=pdf';
        rootAccount.Standard_Audit_Type__c = 'WebTrust';
        rootAccount.Standard_Audit_Statement_Date__c = system.today().addDays(10);
        rootAccount.Standard_Audit_Period_Start_Date__c = system.today().addDays(2);
        rootAccount.Standard_Audit_Period_End_Date__c = system.today().addDays(5);
        rootAccount.BR_Audit__c = 'https://cert.webtrust.org/SealFile?seal=1988&file=pdf';
        rootAccount.BR_Audit_Type__c = 'WebTrust';
        rootAccount.BR_Audit_Statement_Date__c = system.today().addDays(10);
        rootAccount.BR_Audit_Period_Start_Date__c = system.today().addDays(2);
        rootAccount.BR_Audit_Period_End_Date__c = system.today().addDays(5);
        rootAccount.EV_Audit__c = 'https://cert.webtrust.org/SealFile?seal=1989&file=pdf';
        rootAccount.EV_Audit_Type__c = 'WebTrust';
        rootAccount.EV_Audit_Statement_Date__c = system.today().addDays(10);
        rootAccount.EV_Audit_Period_Start_Date__c = system.today().addDays(2);
        rootAccount.EV_Audit_Period_End_Date__c = system.today().addDays(5);
        rootAccount.EV_Code_Signing_Audit__c = 'https://cert.webtrust.org/SealFile?seal=1989&file=pdf';
        rootAccount.EV_Code_Signing_Audit_Type__c= 'WebTrust';
        rootAccount.EV_Code_Signing_Audit_Statement_Date__c = system.today().addDays(10);
        rootAccount.EV_Code_Signing_Audit_Period_Start_Date__c = system.today().addDays(2);
        rootAccount.EV_Code_Signing_Audit_Period_End_Date__c = system.today().addDays(5);
        insert rootAccount;
        
        String remotesiteSeetingResponse = '{'+
          '"size" : 1,'+
          '"totalSize" : 1,'+
         '"done" : true,'+
          '"queryLocator" : null,'+
          '"entityTypeName" : "RemoteProxy",'+
          '"records" : [ {'+
            '"attributes" : {'+
              '"type" : "RemoteProxy",'+
              '"url" : "/services/data/v37.0/tooling/sobjects/RemoteProxy/0rp21000000CfBOAA0"'+
            '},'+
            '"EndpointUrl" : '+strOrgInstance+''+
          '} ]'+
        '}';
        
        Map<String, HttpCalloutMock> endpoint2TestResp = new Map<String,HttpCalloutMock>();
        
        //get remote site
        SingleRequestMock mock1 = new SingleRequestMock(200, 'Complete', remotesiteSeetingResponse, null);
        endpoint2TestResp.put(''+strOrgInstance+'/services/data/v37.0/tooling/query/?q=select+EndpointUrl+from+RemoteProxy+where+isActive+=+true', mock1);
        
        //response to std audit
        SingleRequestMock mock2 = new SingleRequestMock(200, 'Complete', Blob.valueOf('test1'), null);
        endpoint2TestResp.put('https://cert.webtrust.org/SealFile?seal=1987&file=pdf', mock2);
        
        //response to std audit
        SingleRequestMock mock3 = new SingleRequestMock(200, 'Complete', Blob.valueOf('test2'), null);
        endpoint2TestResp.put('https://cert.webtrust.org/SealFile?seal=1988&file=pdf', mock3);
        
        //response to std audit
        SingleRequestMock mock4 = new SingleRequestMock(200, 'Complete', Blob.valueOf('test3'), null);
        endpoint2TestResp.put('https://cert.webtrust.org/SealFile?seal=1989&file=pdf', mock4);
        
        MockHttpResponseGenerator multiMockGen = new MockHttpResponseGenerator(endpoint2TestResp);
        
        RunAuditArchiveBatch batch = new RunAuditArchiveBatch();
        
        Test.startTest();
            
            Test.setMock(HttpCalloutMock.class, multiMockGen);
            Database.executeBatch(batch, 1);
            
        Test.stopTest();
    }
    
    static testmethod void testMethod5(){
        
        Account caOwnerAccount = getCAOwnerAccount();
        insert caOwnerAccount;
        
       
        File_Archive__c fArc1 = new File_Archive__c(CA_Owner__c = caOwnerAccount.Id, 
        External_Link__c = 'https://cert.webtrust.org/SealFile?seal=1987&file=pdf', 
        Internal_Link__c = ''+strOrgInstance+'/servlet/servlet.FileDownload?file=00P21000000cRRiEAM',
        Document_Type__c = 'Standard Audit');
        
        File_Archive__c fArc2 = new File_Archive__c(CA_Owner__c = caOwnerAccount.Id, 
        External_Link__c = 'https://cert.webtrust.org/SealFile?seal=1988file=pdf', 
        Internal_Link__c = ''+strOrgInstance+'/servlet/servlet.FileDownload?file=00P21000000cRRiEAM',
        Document_Type__c = 'BR Audit');
        
        File_Archive__c fArc3 = new File_Archive__c(CA_Owner__c = caOwnerAccount.Id, 
        External_Link__c = 'https://cert.webtrust.org/SealFile?seal=1989&file=pdf', 
        Internal_Link__c = ''+strOrgInstance+'/servlet/servlet.FileDownload?file=00P21000000cRRiEAM',
        Document_Type__c = 'EV Code Signing Audit;EV SSL Audit');
        
        insert new List<File_Archive__c>{fArc1, fArc2, fArc3};
        
        Account rootAccount = getChildAccount();
        rootAccount.ParentId = caOwnerAccount.Id;
        rootAccount.Standard_Audit__c = 'https://cert.webtrust.org/SealFile?seal=1987&file=pdf';
        rootAccount.Standard_Audit_Type__c = 'WebTrust';
        rootAccount.Standard_Audit_Statement_Date__c = system.today().addDays(10);
        rootAccount.Standard_Audit_Period_Start_Date__c = system.today().addDays(2);
        rootAccount.Standard_Audit_Period_End_Date__c = system.today().addDays(5);
        rootAccount.BR_Audit__c = 'https://cert.webtrust.org/SealFile?seal=1988&file=pdf';
        rootAccount.BR_Audit_Type__c = 'WebTrust';
        rootAccount.BR_Audit_Statement_Date__c = system.today().addDays(10);
        rootAccount.BR_Audit_Period_Start_Date__c = system.today().addDays(2);
        rootAccount.BR_Audit_Period_End_Date__c = system.today().addDays(5);
        rootAccount.EV_Audit__c = 'https://cert.webtrust.org/SealFile?seal=1989&file=pdf';
        rootAccount.EV_Audit_Type__c = 'WebTrust';
        rootAccount.EV_Audit_Statement_Date__c = system.today().addDays(10);
        rootAccount.EV_Audit_Period_Start_Date__c = system.today().addDays(2);
        rootAccount.EV_Audit_Period_End_Date__c = system.today().addDays(5);
        rootAccount.EV_Code_Signing_Audit__c = 'https://cert.webtrust.org/SealFile?seal=1989&file=pdf';
        rootAccount.EV_Code_Signing_Audit_Type__c= 'WebTrust';
        rootAccount.EV_Code_Signing_Audit_Statement_Date__c = system.today().addDays(10);
        rootAccount.EV_Code_Signing_Audit_Period_Start_Date__c = system.today().addDays(2);
        rootAccount.EV_Code_Signing_Audit_Period_End_Date__c = system.today().addDays(5);
        insert rootAccount;

        
        String remotesiteSeetingResponse = '{'+
          '"size" : 1,'+
          '"totalSize" : 1,'+
         '"done" : true,'+
          '"queryLocator" : null,'+
          '"entityTypeName" : "RemoteProxy",'+
          '"records" : [ {'+
            '"attributes" : {'+
              '"type" : "RemoteProxy",'+
              '"url" : "/services/data/v37.0/tooling/sobjects/RemoteProxy/0rp21000000CfBOAA0"'+
            '},'+
            '"EndpointUrl" : '+strOrgInstance+''+
          '} ]'+
        '}';
        
        Map<String, HttpCalloutMock> endpoint2TestResp = new Map<String,HttpCalloutMock>();
        
        //get remote site
        SingleRequestMock mock1 = new SingleRequestMock(200, 'Complete', remotesiteSeetingResponse, null);
        endpoint2TestResp.put(''+strOrgInstance+'/services/data/v37.0/tooling/query/?q=select+EndpointUrl+from+RemoteProxy+where+isActive+=+true', mock1);
        
        //response to std audit
        SingleRequestMock mock2 = new SingleRequestMock(200, 'Complete', Blob.valueOf('test1'), null);
        endpoint2TestResp.put('https://cert.webtrust.org/SealFile?seal=1987&file=pdf', mock2);
        
        //response to std audit
        SingleRequestMock mock3 = new SingleRequestMock(200, 'Complete', Blob.valueOf('test2'), null);
        endpoint2TestResp.put('https://cert.webtrust.org/SealFile?seal=1988&file=pdf', mock3);
        
        //response to std audit
        SingleRequestMock mock4 = new SingleRequestMock(200, 'Complete', Blob.valueOf('test3'), null);
        endpoint2TestResp.put('https://cert.webtrust.org/SealFile?seal=1989&file=pdf', mock4);
        
        MockHttpResponseGenerator multiMockGen = new MockHttpResponseGenerator(endpoint2TestResp);
        
        RunAuditArchiveBatch batch = new RunAuditArchiveBatch();
        
        Test.startTest();
            
            Test.setMock(HttpCalloutMock.class, multiMockGen);
            Database.executeBatch(batch, 1);
            
        Test.stopTest();
    }
        
    //only std link is valid
    static testmethod void testMethod3(){
        
        Account caOwnerAccount = getCAOwnerAccount();
        insert caOwnerAccount;
        
        Account rootAccount = getChildAccount();
        rootAccount.ParentId = caOwnerAccount.Id;
        rootAccount.Standard_Audit__c = 'https://cert.webtrust.org/SealFile?seal=1987&file=pdf';
        rootAccount.Standard_Audit_Type__c = 'WebTrust';
        rootAccount.Standard_Audit_Statement_Date__c = system.today().addDays(10);
        rootAccount.Standard_Audit_Period_Start_Date__c = system.today().addDays(2);
        rootAccount.Standard_Audit_Period_End_Date__c = system.today().addDays(5);
        rootAccount.BR_Audit__c = 'https://cert.webtrust.org/SealFile?seal=1987&file=pdf';
        rootAccount.BR_Audit_Type__c = 'WebTrust';
        rootAccount.BR_Audit_Statement_Date__c = system.today().addDays(10);
        rootAccount.BR_Audit_Period_Start_Date__c = system.today().addDays(2);
        rootAccount.BR_Audit_Period_End_Date__c = system.today().addDays(5);
        rootAccount.EV_Audit__c = 'https://cert.webtrust.org/SealFile?seal=1987&file=pdf';
        rootAccount.EV_Audit_Type__c = 'WebTrust';
        rootAccount.EV_Audit_Statement_Date__c = system.today().addDays(10);
        rootAccount.EV_Audit_Period_Start_Date__c = system.today().addDays(2);
        rootAccount.EV_Audit_Period_End_Date__c = system.today().addDays(5);
        rootAccount.EV_Code_Signing_Audit__c = 'https://cert.webtrust.org/SealFile?seal=1989&file=pdf';
        rootAccount.EV_Code_Signing_Audit_Type__c= 'WebTrust';
        rootAccount.EV_Code_Signing_Audit_Statement_Date__c = system.today().addDays(10);
        rootAccount.EV_Code_Signing_Audit_Period_Start_Date__c = system.today().addDays(2);
        rootAccount.EV_Code_Signing_Audit_Period_End_Date__c = system.today().addDays(5);
        //insert rootAccount;
        
        Account rootAccount2 = getChildAccount();
        rootAccount2.ParentId = caOwnerAccount.Id;
        rootAccount2.Standard_Audit__c = 'https://cert.webtrust.org/SealFile?seal=1987&file=pdf';
        rootAccount2.Standard_Audit_Type__c = 'WebTrust';
        rootAccount2.Standard_Audit_Statement_Date__c = system.today().addDays(10);
        rootAccount2.Standard_Audit_Period_Start_Date__c = system.today().addDays(2);
        rootAccount2.Standard_Audit_Period_End_Date__c = system.today().addDays(5);
        rootAccount2.BR_Audit__c = 'https://cert.webtrust.org/SealFile?seal=1987&file=pdf';
        rootAccount2.BR_Audit_Type__c = 'WebTrust';
        rootAccount2.BR_Audit_Statement_Date__c = system.today().addDays(10);
        rootAccount2.BR_Audit_Period_Start_Date__c = system.today().addDays(2);
        rootAccount2.BR_Audit_Period_End_Date__c = system.today().addDays(5);
        rootAccount2.EV_Audit__c = 'https://cert.webtrust.org/SealFile?seal=1987&file=pdf';
        rootAccount2.EV_Audit_Type__c = 'WebTrust';
        rootAccount2.EV_Audit_Statement_Date__c = system.today().addDays(10);
        rootAccount2.EV_Audit_Period_Start_Date__c = system.today().addDays(2);
        rootAccount2.EV_Audit_Period_End_Date__c = system.today().addDays(5);
        insert new list<account>{rootAccount, rootAccount2};
        
        String remotesiteSeetingResponse = '{'+
          '"size" : 1,'+
          '"totalSize" : 1,'+
         '"done" : true,'+
          '"queryLocator" : null,'+
          '"entityTypeName" : "RemoteProxy",'+
          '"records" : [ {'+
            '"attributes" : {'+
              '"type" : "RemoteProxy",'+
              '"url" : "/services/data/v37.0/tooling/sobjects/RemoteProxy/0rp21000000CfBOAA0"'+
            '},'+
            '"EndpointUrl" : '+strOrgInstance+''+
          '} ]'+
        '}';
        
        Map<String, HttpCalloutMock> endpoint2TestResp = new Map<String,HttpCalloutMock>();
        
        //get remote site
        SingleRequestMock mock1 = new SingleRequestMock(200, 'Complete', remotesiteSeetingResponse, null);
        endpoint2TestResp.put(''+strOrgInstance+'/services/data/v37.0/tooling/query/?q=select+EndpointUrl+from+RemoteProxy+where+isActive+=+true', mock1);
        
        //response to std audit
        SingleRequestMock mock2 = new SingleRequestMock(200, 'Complete', Blob.valueOf('test1'), null);
        endpoint2TestResp.put('https://cert.webtrust.org/SealFile?seal=1987&file=pdf', mock2);
        
        //response to std audit
        SingleRequestMock mock3 = new SingleRequestMock(200, 'Complete', Blob.valueOf('test1'), null);
        endpoint2TestResp.put('https://cert.webtrust.org/SealFile?seal=1989&file=pdf', mock3);
                
        MockHttpResponseGenerator multiMockGen = new MockHttpResponseGenerator(endpoint2TestResp);
        
        RunAuditArchiveBatch batch = new RunAuditArchiveBatch();
        
        Test.startTest();
            
            Test.setMock(HttpCalloutMock.class, multiMockGen);
            Database.executeBatch(batch, 2);
            
        Test.stopTest();
    }
    
    
    //only std link is valid
    static testmethod void testMethod4(){
        
        Account caOwnerAccount = getCAOwnerAccount();
        insert caOwnerAccount;
        
        Account rootAccount = getChildAccount();
        rootAccount.ParentId = caOwnerAccount.Id;
        rootAccount.Standard_Audit__c = 'https://cert.webtrust.org/SealFile?seal=1987&file=pdf';
        rootAccount.Standard_Audit_Type__c = 'WebTrust';
        rootAccount.Standard_Audit_Statement_Date__c = system.today().addDays(10);
        rootAccount.Standard_Audit_Period_Start_Date__c = system.today().addDays(2);
        rootAccount.Standard_Audit_Period_End_Date__c = system.today().addDays(5);
        rootAccount.BR_Audit__c = 'https://cert.webtrust.org/SealFile?seal=1988&file=pdf';
        rootAccount.BR_Audit_Type__c = 'WebTrust';
        rootAccount.BR_Audit_Statement_Date__c = system.today().addDays(10);
        rootAccount.BR_Audit_Period_Start_Date__c = system.today().addDays(2);
        rootAccount.BR_Audit_Period_End_Date__c = system.today().addDays(5);
        rootAccount.EV_Audit__c = 'https://cert.webtrust.org/SealFile?seal=1989&file=pdf';
        rootAccount.EV_Audit_Type__c = 'WebTrust';
        rootAccount.EV_Audit_Statement_Date__c = system.today().addDays(10);
        rootAccount.EV_Audit_Period_Start_Date__c = system.today().addDays(2);
        rootAccount.EV_Audit_Period_End_Date__c = system.today().addDays(5);
        rootAccount.EV_Code_Signing_Audit__c = 'https://cert.webtrust.org/SealFile?seal=1989&file=pdf';
        rootAccount.EV_Code_Signing_Audit_Type__c= 'WebTrust';
        rootAccount.EV_Code_Signing_Audit_Statement_Date__c = system.today().addDays(10);
        rootAccount.EV_Code_Signing_Audit_Period_Start_Date__c = system.today().addDays(2);
        rootAccount.EV_Code_Signing_Audit_Period_End_Date__c = system.today().addDays(5);
        insert rootAccount;
        
        String remotesiteSeetingResponse = '{'+
          '"size" : 1,'+
          '"totalSize" : 1,'+
         '"done" : true,'+
          '"queryLocator" : null,'+
          '"entityTypeName" : "RemoteProxy",'+
          '"records" : [ {'+
            '"attributes" : {'+
              '"type" : "RemoteProxy",'+
              '"url" : "/services/data/v37.0/tooling/sobjects/RemoteProxy/0rp21000000CfBOAA0"'+
            '},'+
            '"EndpointUrl" : '+strOrgInstance+''+
          '} ]'+
        '}';
        
        Map<String, HttpCalloutMock> endpoint2TestResp = new Map<String,HttpCalloutMock>();
        
        //get remote site
        SingleRequestMock mock1 = new SingleRequestMock(200, 'Complete', remotesiteSeetingResponse, null);
        endpoint2TestResp.put(''+strOrgInstance+'/services/data/v37.0/tooling/query/?q=select+EndpointUrl+from+RemoteProxy+where+isActive+=+true', mock1);
        
        //create remote site
        SingleRequestMock mock_0 = new SingleRequestMock(200, 'Complete', Blob.valueOf('test'), new Map<String, String>{});
        endpoint2TestResp.put('https://www.google.com', mock_0);
        
        //response to std audit
        SingleRequestMock mock2 = new SingleRequestMock(300, 'Complete', 'test', new Map<String, String> {'Location' => 'https://www.google.com'});
        endpoint2TestResp.put('https://cert.webtrust.org/SealFile?seal=1987&file=pdf', mock2);
        
        //response to std audit
        SingleRequestMock mock3 = new SingleRequestMock(200, 'Complete', Blob.valueOf('test2'), null);
        endpoint2TestResp.put('https://cert.webtrust.org/SealFile?seal=1988&file=pdf', mock3);
        
        //response to std audit
        SingleRequestMock mock4 = new SingleRequestMock(200, 'Complete', Blob.valueOf('test3'), null);
        endpoint2TestResp.put('https://cert.webtrust.org/SealFile?seal=1989&file=pdf', mock4);
        
        MockHttpResponseGenerator multiMockGen = new MockHttpResponseGenerator(endpoint2TestResp);
        
        RunAuditArchiveBatch batch = new RunAuditArchiveBatch();
        
        Test.startTest();
            
            Test.setMock(HttpCalloutMock.class, multiMockGen);
            Database.executeBatch(batch, 1);
            
        Test.stopTest();
    }
    
    static testMethod void testRemoteSiteSettingJSON2Apex() {
        
        String json = '{\"records_type_info\":[\"records\",\"http://soap.sforce.com/2006/04/metadata\",null,\"0\",\"-1\",\"false\"],\"records\":[{\"fullName\":null,\"url_type_info\":[\"url\",\"http://soap.sforce.com/2006/04/metadata\",null,\"1\",\"1\",\"false\"],\"url\":\"https://jx509withecc.herokuapp.com\",\"type_att_info\":[\"xsi:type\"],\"type\":\"RemoteSiteSetting\",\"isActive_type_info\":[\"isActive\",\"http://soap.sforce.com/2006/04/metadata\",null,\"1\",\"1\",\"false\"],\"isActive\":false,\"fullName_type_info\":[\"fullName\",\"http://soap.sforce.com/2006/04/metadata\",null,\"0\",\"1\",\"false\"],\"fullName\":\"jx509withECC\",\"field_order_type_info\":[\"fullName\",\"description\",\"disableProtocolSecurity\",\"isActive\",\"url\"],\"disableProtocolSecurity_type_info\":[\"disableProtocolSecurity\",\"http://soap.sforce.com/2006/04/metadata\",null,\"1\",\"1\",\"false\"],\"disableProtocolSecurity\":false,\"description_type_info\":[\"description\",\"http://soap.sforce.com/2006/04/metadata\",null,\"0\",\"1\",\"false\"],\"description\":null,\"apex_schema_type_info\":[\"http://soap.sforce.com/2006/04/metadata\",\"true\",\"false\"]},{\"fullName\":null,\"url_type_info\":[\"url\",\"http://soap.sforce.com/2006/04/metadata\",null,\"1\",\"1\",\"false\"],\"url\":\"http://cert-checker.allizom.org\",\"type_att_info\":[\"xsi:type\"],\"type\":\"RemoteSiteSetting\",\"isActive_type_info\":[\"isActive\",\"http://soap.sforce.com/2006/04/metadata\",null,\"1\",\"1\",\"false\"],\"isActive\":true,\"fullName_type_info\":[\"fullName\",\"http://soap.sforce.com/2006/04/metadata\",null,\"0\",\"1\",\"false\"],\"fullName\":\"CertChecker\",\"field_order_type_info\":[\"fullName\",\"description\",\"disableProtocolSecurity\",\"isActive\",\"url\"],\"disableProtocolSecurity_type_info\":[\"disableProtocolSecurity\",\"http://soap.sforce.com/2006/04/metadata\",null,\"1\",\"1\",\"false\"],\"disableProtocolSecurity\":false,\"description_type_info\":[\"description\",\"http://soap.sforce.com/2006/04/metadata\",null,\"0\",\"1\",\"false\"],\"description\":\"This utility accessed to parse PEM information for Intermediate Certs\",\"apex_schema_type_info\":[\"http://soap.sforce.com/2006/04/metadata\",\"true\",\"false\"]},{\"fullName\":null,\"url_type_info\":[\"url\",\"http://soap.sforce.com/2006/04/metadata\",null,\"1\",\"1\",\"false\"],\"url\":\"https://jx509.herokuapp.com\",\"type_att_info\":[\"xsi:type\"],\"type\":\"RemoteSiteSetting\",\"isActive_type_info\":[\"isActive\",\"http://soap.sforce.com/2006/04/metadata\",null,\"1\",\"1\",\"false\"],\"isActive\":false,\"fullName_type_info\":[\"fullName\",\"http://soap.sforce.com/2006/04/metadata\",null,\"0\",\"1\",\"false\"],\"fullName\":\"jx509AtHeroku\",\"field_order_type_info\":[\"fullName\",\"description\",\"disableProtocolSecurity\",\"isActive\",\"url\"],\"disableProtocolSecurity_type_info\":[\"disableProtocolSecurity\",\"http://soap.sforce.com/2006/04/metadata\",null,\"1\",\"1\",\"false\"],\"disableProtocolSecurity\":false,\"description_type_info\":[\"description\",\"http://soap.sforce.com/2006/04/metadata\",null,\"0\",\"1\",\"false\"],\"description\":null,\"apex_schema_type_info\":[\"http://soap.sforce.com/2006/04/metadata\",\"true\",\"false\"]},{\"fullName\":null,\"url_type_info\":[\"url\",\"http://soap.sforce.com/2006/04/metadata\",null,\"1\",\"1\",\"false\"],\"url\":\"'+strOrgInstance+'\",\"type_att_info\":[\"xsi:type\"],\"type\":\"RemoteSiteSetting\",\"isActive_type_info\":[\"isActive\",\"http://soap.sforce.com/2006/04/metadata\",null,\"1\",\"1\",\"false\"],\"isActive\":true,\"fullName_type_info\":[\"fullName\",\"http://soap.sforce.com/2006/04/metadata\",null,\"0\",\"1\",\"false\"],\"fullName\":\"Metadata_API\",\"field_order_type_info\":[\"fullName\",\"description\",\"disableProtocolSecurity\",\"isActive\",\"url\"],\"disableProtocolSecurity_type_info\":[\"disableProtocolSecurity\",\"http://soap.sforce.com/2006/04/metadata\",null,\"1\",\"1\",\"false\"],\"disableProtocolSecurity\":false,\"description_type_info\":[\"description\",\"http://soap.sforce.com/2006/04/metadata\",null,\"0\",\"1\",\"false\"],\"description\":\"'+strOrgInstance+' & '+strOrgInstance+'\",\"apex_schema_type_info\":[\"http://soap.sforce.com/2006/04/metadata\",\"true\",\"false\"]},{\"fullName\":null,\"url_type_info\":[\"url\",\"http://soap.sforce.com/2006/04/metadata\",null,\"1\",\"1\",\"false\"],\"url\":\"https://jx509witheccandcertid.herokuapp.com\",\"type_att_info\":[\"xsi:type\"],\"type\":\"RemoteSiteSetting\",\"isActive_type_info\":[\"isActive\",\"http://soap.sforce.com/2006/04/metadata\",null,\"1\",\"1\",\"false\"],\"isActive\":true,\"fullName_type_info\":[\"fullName\",\"http://soap.sforce.com/2006/04/metadata\",null,\"0\",\"1\",\"false\"],\"fullName\":\"jx509witheccandcertid\",\"field_order_type_info\":[\"fullName\",\"description\",\"disableProtocolSecurity\",\"isActive\",\"url\"],\"disableProtocolSecurity_type_info\":[\"disableProtocolSecurity\",\"http://soap.sforce.com/2006/04/metadata\",null,\"1\",\"1\",\"false\"],\"disableProtocolSecurity\":false,\"description_type_info\":[\"description\",\"http://soap.sforce.com/2006/04/metadata\",null,\"0\",\"1\",\"false\"],\"description\":null,\"apex_schema_type_info\":[\"http://soap.sforce.com/2006/04/metadata\",\"true\",\"false\"]}],\"field_order_type_info\":[\"records\"],\"apex_schema_type_info\":[\"http://soap.sforce.com/2006/04/metadata\",\"true\",\"false\"]}';
        RemoteSiteSettingJSON2Apex r = RemoteSiteSettingJSON2Apex.parse(json);
        System.assert(r != null);

        json = '{\"TestAMissingObject\": { \"TestAMissingArray\": [ { \"TestAMissingProperty\": \"Some Value\" } ] } }';
        RemoteSiteSettingJSON2Apex objRoot = new RemoteSiteSettingJSON2Apex(System.JSON.createParser(json));
        System.assert(objRoot != null);
        System.assert(objRoot.records_type_info == null);
        System.assert(objRoot.records == null);
        System.assert(objRoot.field_order_type_info == null);
        System.assert(objRoot.apex_schema_type_info == null);

        json = '{\"TestAMissingObject\": { \"TestAMissingArray\": [ { \"TestAMissingProperty\": \"Some Value\" } ] } }';
        RemoteSiteSettingJSON2Apex.Records objRecords = new RemoteSiteSettingJSON2Apex.Records(System.JSON.createParser(json));
        System.assert(objRecords != null);
        System.assert(objRecords.fullName == null);
        System.assert(objRecords.url_type_info == null);
        System.assert(objRecords.url == null);
        System.assert(objRecords.type_att_info == null);
        System.assert(objRecords.type_Z == null);
        System.assert(objRecords.isActive_type_info == null);
        System.assert(objRecords.isActive == null);
        System.assert(objRecords.fullName_type_info == null);
        System.assert(objRecords.field_order_type_info == null);
        System.assert(objRecords.disableProtocolSecurity_type_info == null);
        System.assert(objRecords.disableProtocolSecurity == null);
        System.assert(objRecords.description_type_info == null);
        System.assert(objRecords.description == null);
        System.assert(objRecords.apex_schema_type_info == null);
    }
    
    static testMethod void testReadRemoteProxyJSON2Apex() {
        
        String json = '{\"size\":3,\"totalSize\":3,\"done\":true,\"queryLocator\":null,\"entityTypeName\":\"RemoteProxy\",\"records\":[{\"attributes\":{\"type\":\"RemoteProxy\",\"url\":\"/services/data/v37.0/tooling/sobjects/RemoteProxy/0rp21000000CfBOAA0\"},\"EndpointUrl\":\"'+strOrgInstance+'\"},{\"attributes\":{\"type\":\"RemoteProxy\",\"url\":\"/services/data/v37.0/tooling/sobjects/RemoteProxy/0rpo00000004ZvMAAU\"},\"EndpointUrl\":\"https://jx509witheccandcertid.herokuapp.com\"},{\"attributes\":{\"type\":\"RemoteProxy\",\"url\":\"/services/data/v37.0/tooling/sobjects/RemoteProxy/0rpo0000000H15hAAC\"},\"EndpointUrl\":\"http://cert-checker.allizom.org\"}]}';
        ReadRemoteProxyJSON2Apex r = ReadRemoteProxyJSON2Apex.parse(json);
        System.assert(r != null);

        json = '{\"TestAMissingObject\": { \"TestAMissingArray\": [ { \"TestAMissingProperty\": \"Some Value\" } ] } }';
        ReadRemoteProxyJSON2Apex objRoot = new ReadRemoteProxyJSON2Apex(System.JSON.createParser(json));
        System.assert(objRoot != null);
        System.assert(objRoot.size == null);
        System.assert(objRoot.totalSize == null);
        System.assert(objRoot.done == null);
        System.assert(objRoot.queryLocator == null);
        System.assert(objRoot.entityTypeName == null);
        System.assert(objRoot.records == null);

        json = '{\"TestAMissingObject\": { \"TestAMissingArray\": [ { \"TestAMissingProperty\": \"Some Value\" } ] } }';
        ReadRemoteProxyJSON2Apex.Attributes objAttributes = new ReadRemoteProxyJSON2Apex.Attributes(System.JSON.createParser(json));
        System.assert(objAttributes != null);
        System.assert(objAttributes.type_Z == null);
        System.assert(objAttributes.url == null);

        json = '{\"TestAMissingObject\": { \"TestAMissingArray\": [ { \"TestAMissingProperty\": \"Some Value\" } ] } }';
        ReadRemoteProxyJSON2Apex.Records objRecords = new ReadRemoteProxyJSON2Apex.Records(System.JSON.createParser(json));
        System.assert(objRecords != null);
        System.assert(objRecords.attributes == null);
        System.assert(objRecords.EndpointUrl == null);
    }
        
    public static Account getCAOwnerAccount(){

        Account parentAccount = new Account();
        parentAccount.recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('CA Owner').getRecordTypeID();
        parentAccount.name = 'ParentAccount';
        parentAccount.type = 'Owner';
        parentAccount.status__c= 'Included';
        parentAccount.Revocation_Status__c = 'Included';
        parentAccount.phone='2128425500';
        parentAccount.website  = 'https//www.test.com';
        parentAccount.valid_From_GMT__c= date.today()+1;
        parentAccount.valid_to_GMT__c= date.today()+10;
        parentAccount.company_website__c=  'https//www.test.com';
        parentAccount.organizational_type__c=  'Organizational Type';
        parentAccount.geographic_focus__c=  'Geographic focus';
        parentAccount.primary_market_customer_base__c = 'Primary Market';
        return parentAccount;
    }
    
     public static Account getChildAccount() {
        
        Account parentAccount = new Account();
        parentAccount.recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Root Certificate').getRecordTypeID();
        parentAccount.name = '<Fill in Cert Name>';
        parentAccount.type = 'Owner';
        parentAccount.phone='2128425500';
        parentAccount.website  = 'https//www.test.com';
        parentAccount.valid_From_GMT__c= date.today()+1;
        parentAccount.valid_to_GMT__c= date.today()+10;
        parentAccount.company_website__c=  'https//www.test.com';
        parentAccount.organizational_type__c=  'Organizational Type';
        parentAccount.geographic_focus__c=  'Geographic focus';
        parentAccount.primary_market_customer_base__c = 'Primary Market';
        parentAccount.SHA_1_Fingerprint__c = 'CA:BD:2A:79:A1:07:6A:31:F2:1D:25:36:35:CB:03:9D:43:29:A5:E8';
        parentAccount.SHA_256_Fingerprint__c = '96:BC:EC:06:26:49:76:F3:74:60:77:9A:CF:28:C5:A7:CF:E8:A3:C0:AA:E1:1A:8F:FC:EE:05:C0:BD:DF:08:C6';
        return parentAccount;
    }
}
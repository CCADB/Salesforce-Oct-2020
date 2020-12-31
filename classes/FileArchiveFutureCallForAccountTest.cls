/*
    Description: Test class FileArchiveFutureCallForAccount
*/
@isTest
public with sharing class FileArchiveFutureCallForAccountTest{
    
    public static string strOrgInstance = System.URL.getSalesforceBaseURL().toExternalForm();
    
    static testmethod void TestFileArchiveFuture(){
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
        
        Account caOwnerAccount = getCAOwnerAccount();
        insert caOwnerAccount;
        
        File_Archive__c fArc1 = new File_Archive__c(CA_Owner__c = caOwnerAccount.Id, 
        External_Link__c = 'https://cert.webtrust.org/SealFile?seal=1987&file=pdf', 
        Internal_Link__c = ''+strOrgInstance+'/servlet/servlet.FileDownload?file=00P21000000cRRiEAM',
        Document_Type__c = 'Standard Audit');
        
        File_Archive__c fArc2 = new File_Archive__c(CA_Owner__c = caOwnerAccount.Id, 
        External_Link__c = 'https://cert.webtrust.org/SealFile?seal=1988&file=pdf', 
        Internal_Link__c = ''+strOrgInstance+'/servlet/servlet.FileDownload?file=00P21000000cRRiEAM',
        Document_Type__c = 'BR Audit;Code Signing Audit');
        
        File_Archive__c fArc3 = new File_Archive__c(CA_Owner__c = caOwnerAccount.Id, 
        External_Link__c = 'https://cert.webtrust.org/SealFile?seal=1989&file=pdf', 
        Internal_Link__c = ''+strOrgInstance+'/servlet/servlet.FileDownload?file=00P21000000cRRiEAM',
        Document_Type__c = 'EV Code Signing Audit;EV SSL Audit');
        
        File_Archive__c fArc4 = new File_Archive__c(CA_Owner__c = caOwnerAccount.Id, 
        External_Link__c = 'https://cert.webtrust.org/SealFile?seal=1990&file=pdf', 
        Internal_Link__c = ''+strOrgInstance+'/servlet/servlet.FileDownload?file=00P21000000cRRiEAM',
        Document_Type__c = 'EV Code Signing Audit;EV SSL Audit;Code Signing Audit');
        
        insert new List<File_Archive__c>{fArc1, fArc2, fArc3,fArc4};
        
        Account rootAccount = getChildAccount();
        rootAccount.ParentId = caOwnerAccount.Id;
        rootAccount.Standard_Audit__c = 'https://cert.webtrust.org/SealFile?seal=1987&file=pdf';
        rootAccount.Standard_Audit_Type__c = 'WebTrust';
        rootAccount.Standard_Audit_Statement_Date__c = system.today().addDays(10);
        rootAccount.Standard_Audit_Period_Start_Date__c = system.today().addDays(2);
        rootAccount.Standard_Audit_Period_End_Date__c = system.today().addDays(5);
        rootAccount.Standard_Deviation__c = true;
        rootAccount.Code_Signing_Audit__c = 'https://cert.webtrust.org/SealFile?seal=1988&file=pdf';
        rootAccount.Code_Signing_Audit_Type__c = 'WebTrust';
        rootAccount.Code_Signing_Audit_Statement_Date__c = system.today().addDays(10);
        rootAccount.Code_Signing_Audit_Period_Start_Date__c = system.today().addDays(2);
        rootAccount.Code_Signing_Audit_Period_End_Date__c = system.today().addDays(5);
        rootAccount.Code_Signing_Deviation__c = true;
        rootAccount.BR_Audit__c = 'https://cert.webtrust.org/SealFile?seal=1988&file=pdf';
        rootAccount.BR_Audit_Type__c = 'WebTrust';
        rootAccount.BR_Audit_Statement_Date__c = system.today().addDays(10);
        rootAccount.BR_Audit_Period_Start_Date__c = system.today().addDays(2);
        rootAccount.BR_Audit_Period_End_Date__c = system.today().addDays(5);
        rootAccount.BR_Deviation__c = true;
        rootAccount.EV_Audit__c = 'https://cert.webtrust.org/SealFile?seal=1989&file=pdf';
        rootAccount.EV_Audit_Type__c = 'WebTrust';
        rootAccount.EV_Audit_Statement_Date__c = system.today().addDays(10);
        rootAccount.EV_Audit_Period_Start_Date__c = system.today().addDays(2);
        rootAccount.EV_Audit_Period_End_Date__c = system.today().addDays(5);
        rootAccount.EV_SSL_Deviation__c = true;
        rootAccount.EV_Code_Signing_Audit__c = 'https://cert.webtrust.org/SealFile?seal=1990&file=pdf';
        rootAccount.EV_Code_Signing_Audit_Type__c= 'WebTrust';
        rootAccount.EV_Code_Signing_Audit_Statement_Date__c = system.today().addDays(10);
        rootAccount.EV_Code_Signing_Audit_Period_Start_Date__c = system.today().addDays(2);
        rootAccount.EV_Code_Signing_Audit_Period_End_Date__c = system.today().addDays(5);
        rootAccount.EV_Code_Signing_Deviation__c = true;
        insert rootAccount;
        
        Test.setMock(HttpCalloutMock.class, multiMockGen);
        
        FileArchiveFutureCallForAccount.FutureCallCreateAuditFiles(rootAccount.Id);
    }
    
    static testmethod void TestFileArchiveFutureAllNewAuditURL(){
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
        
        //response to std audit
        SingleRequestMock mock2 = new SingleRequestMock(200, 'Complete', Blob.valueOf('test1'), null);
        endpoint2TestResp.put('https://cert.webtrust.org/SealFile?seal=1987&file=pdf', mock2);
        
        //response to std audit
        SingleRequestMock mock3 = new SingleRequestMock(200, 'Complete', Blob.valueOf('test2'), null);
        endpoint2TestResp.put('https://cert.webtrust.org/SealFile?seal=1988&file=pdf', mock3);
        
        //response to std audit
        SingleRequestMock mock4 = new SingleRequestMock(200, 'Complete', Blob.valueOf('test3'), null);
        endpoint2TestResp.put('https://cert.webtrust.org/SealFile?seal=1989&file=pdf', mock4);
        
        //response to std audit
        SingleRequestMock mock5 = new SingleRequestMock(200, 'Complete', Blob.valueOf('test3'), null);
        endpoint2TestResp.put('https://cert.webtrust.org/SealFile?seal=1990&file=pdf', mock5);
        
        MockHttpResponseGenerator multiMockGen = new MockHttpResponseGenerator(endpoint2TestResp);
        
        Account caOwnerAccount = getCAOwnerAccount();
        insert caOwnerAccount;
        
        Account rootAccount = getChildAccount();
        rootAccount.ParentId = caOwnerAccount.Id;
        rootAccount.Standard_Audit__c = 'https://cert.webtrust.org/SealFile?seal=1987&file=pdf';
        rootAccount.Standard_Audit_Type__c = 'WebTrust';
        rootAccount.Standard_Audit_Statement_Date__c = system.today().addDays(10);
        rootAccount.Standard_Audit_Period_Start_Date__c = system.today().addDays(2);
        rootAccount.Standard_Audit_Period_End_Date__c = system.today().addDays(5);
        rootAccount.Standard_Deviation__c = true;
        rootAccount.BR_Audit__c = 'https://cert.webtrust.org/SealFile?seal=1988&file=pdf';
        rootAccount.BR_Audit_Type__c = 'WebTrust';
        rootAccount.BR_Audit_Statement_Date__c = system.today().addDays(10);
        rootAccount.BR_Audit_Period_Start_Date__c = system.today().addDays(2);
        rootAccount.BR_Audit_Period_End_Date__c = system.today().addDays(5);
        rootAccount.BR_Deviation__c = true;
        rootAccount.EV_Audit__c = 'https://cert.webtrust.org/SealFile?seal=1989&file=pdf';
        rootAccount.EV_Audit_Type__c = 'WebTrust';
        rootAccount.EV_Audit_Statement_Date__c = system.today().addDays(10);
        rootAccount.EV_Audit_Period_Start_Date__c = system.today().addDays(2);
        rootAccount.EV_Audit_Period_End_Date__c = system.today().addDays(5);
        rootAccount.EV_SSL_Deviation__c = true;
        rootAccount.EV_Code_Signing_Audit__c = 'https://cert.webtrust.org/SealFile?seal=1990&file=pdf';
        rootAccount.EV_Code_Signing_Audit_Type__c= 'WebTrust';
        rootAccount.EV_Code_Signing_Audit_Statement_Date__c = system.today().addDays(10);
        rootAccount.EV_Code_Signing_Audit_Period_Start_Date__c = system.today().addDays(2);
        rootAccount.EV_Code_Signing_Audit_Period_End_Date__c = system.today().addDays(5);
        rootAccount.EV_Code_Signing_Deviation__c = true;
        insert rootAccount;
        
        Test.setMock(HttpCalloutMock.class, multiMockGen);
        
        FileArchiveFutureCallForAccount.FutureCallCreateAuditFiles(rootAccount.Id);
        FileArchiveFutureCallForAccount.sendEmail('Exception email');
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
        parentAccount.name = 'ChildAccount';
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
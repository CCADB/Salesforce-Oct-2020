/*******************************************************************************************************
 Name: CPACanadaServiceControllerTest

 Dependencies: CPACanadaServiceController, CPACanadaServiceDeltaBatch, 
 CPACanadaServiceAllScheduler, CPACanadaServiceDeltaScheduler, CPACanadaServiceControllerTest

 Description: Test class for CPA Canada Controller
 
 Class is created for call API to get CPA Canada report file urls and update in Salesforce.
 
 Program logic is driven by 'parseResponse' parameter, it can be 'All' or 'Delta'
 
 
 Instructions:  
    
 *******************************************************************************************************
 Revision History:
 
     2/19/2019 - Created new class
     
 ******************************************************************************************************/

@isTest
public with sharing class CPACanadaServiceControllerTest {
    
    static testmethod void testCPACanadaAll(){
        
        CPACanada_API_Detail__c cpacanada = new CPACanada_API_Detail__c();
        cpacanada.Name = 'CPACanada API';
        cpacanada.End_Point__c = 'https://test.com';
        cpacanada.Grant_Type__c = 'xxxxxx';
        cpacanada.Password__c = 'xxxxxx';
        cpacanada.Username__c = 'xxxxxx';
        insert cpacanada; 
        
        CPACanada_File__c file = new CPACanada_File__c();
        file.name = '499';
        file.Report_Id__c = '221273';
        file.Seal_URL__c= 'https://www.cpacanada.ca/webtrustseal?sealid=499';
        file.Report_URL__c = 'https://www.cpacanada.ca/generichandlers/aptifyattachmenthandler.ashx?attachmentid=221273';
        insert file;
        
        CPACanadaServiceController.getAllCPACanadaFiles();
        
        file.Report_Id__c = '2212734';
        update file;
        
        CPACanadaServiceController.getAllCPACanadaFiles();
        
        CPACanadaServiceAllScheduler.scheduleMe('CPACanada Sync All Files'+System.now());
    }
    
    static testmethod void testCPACanadaDelta(){
        
        CPACanada_API_Detail__c cpacanada = new CPACanada_API_Detail__c();
        cpacanada.Name = 'CPACanada API';
        cpacanada.End_Point__c = 'https://test.com';
        cpacanada.Grant_Type__c = 'xxxxxx';
        cpacanada.Password__c = 'xxxxxx';
        cpacanada.Username__c = 'xxxxxx';
        insert cpacanada; 
        
        CPACanada_File__c file = new CPACanada_File__c();
        file.name = '499';
        file.Report_Id__c = '221273';
        file.Seal_URL__c= 'https://www.cpacanada.ca/webtrustseal?sealid=499';
        file.Report_URL__c = 'https://www.cpacanada.ca/generichandlers/aptifyattachmenthandler.ashx?attachmentid=221273';
        insert file;
        
        CPACanadaServiceController.getDeltaCPACanadaFiles();
        
        file.Report_Id__c = '2212734';
        update file;
        
        CPACanadaServiceController.getDeltaCPACanadaFiles();
        
        CPACanadaServiceDeltaScheduler.scheduleMe('CPACanada Sync Delta Files '+System.now());
        
        CPACanadaServiceDeltaBatch batch = new CPACanadaServiceDeltaBatch();
        Database.executebatch(batch, 1);
        
        CPACanadaServiceController.sendEmail('CPACanada API is not giving correct response.');
    }
}
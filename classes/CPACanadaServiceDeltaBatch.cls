/*******************************************************************************************************
 Name: CPACanadaServiceDeltaBatch

 Dependencies: CPACanadaServiceController, CPACanadaServiceDeltaBatch, 
 CPACanadaServiceAllScheduler, CPACanadaServiceDeltaScheduler, CPACanadaServiceControllerTest

 Description: Batch has created to call Delta API and if count doesn't match then call API to sync all CPACanada files.
 
 Class is created for call API to get CPA Canada report file urls and update in Salesforce.
  
 Instructions:  
 
    
 *******************************************************************************************************
 Revision History:
 
     2/19/2019 - Created new class
     
 ******************************************************************************************************/

public class CPACanadaServiceDeltaBatch implements Database.Batchable<Sobject>, Database.AllowsCallouts, Database.Stateful{
    
    public boolean isCPACountMatch = true;
    
    public Database.QueryLocator start(Database.BatchableContext BC){
        string strQuery = 'select Id,Name,End_Point__c,Grant_Type__c, Password__c,Username__c from CPACanada_API_Detail__c Where Name = \'CPACanada API\' Limit 1';
        return Database.getQueryLocator(strQuery);
    }
    
    public void execute(Database.BatchableContext BC, List<CPACanada_API_Detail__c> lstCPACanadaAPIDetail){
        if(lstCPACanadaAPIDetail.size() > 0) {
            string EndPoint = lstCPACanadaAPIDetail[0].End_Point__c;
            string FinalEndPoint = EndPoint + 'api/data/getalldeltarecords';
            CPACanadaServiceController.ClsCPACanada cpaCanadaFiles = CPACanadaServiceController.getCPACanadaFiles(FinalEndPoint, 'GET');
            isCPACountMatch = CPACanadaServiceController.parseResponse(cpaCanadaFiles, 'Delta');
            system.debug('isCPACountMatch  ::: '+isCPACountMatch);
        }
    }
    
    public void finish(Database.BatchableContext BC){
        //if count doesn't match
        if(!isCPACountMatch || Test.IsRunningTest()){
            List<CPACanada_API_Detail__c> lstCPACanadaAPI = new List<CPACanada_API_Detail__c>([select Id,Name,End_Point__c,Grant_Type__c,
                    Password__c,Username__c from CPACanada_API_Detail__c Where Name = 'CPACanada API' Limit 1]);
            if(lstCPACanadaAPI.size() > 0) {
                string EndPoint = lstCPACanadaAPI[0].End_Point__c;
                string FinalEndPoint = EndPoint + 'api/data/getallrecords';
                CPACanadaServiceController.ClsCPACanada cpaCanadaFiles = CPACanadaServiceController.getCPACanadaFiles(FinalEndPoint, 'POST');
                CPACanadaServiceController.parseResponse(cpaCanadaFiles, 'All'); 
            }
        }
    }
}
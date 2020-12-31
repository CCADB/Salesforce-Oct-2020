/*
    Descrption: Test class for CustomReportsAndProcessesController
*/
@isTest
public with sharing class CustomReportsAndProcessesControllerTest {
    
    static testmethod void TestDocumentation(){
        
        Custom_Reports_and_Processes__c document = new Custom_Reports_and_Processes__c();
        document.Name__c = 'Report 1';
        document.Used_By__c = 'Mozilla Internal';
        document.Type__c = 'Custom Report';
        document.Lightning_Enabled__c = 'Yes';
        insert document;
        
        CustomReportsAndProcessesController controller = new CustomReportsAndProcessesController();
        controller.strUsedBy = 'Mozilla Internal';
        controller.objDocumentFilter.Type__c = 'Custom Report';
        controller.objDocumentFilter.Lightning_Enabled__c = 'Yes';
        controller.filterDocumentation();
        Apexpages.currentpage().getparameters().put('index','0');
        controller.EditDocument();
        controller.SaveDocument();
        controller.CancelDocument();
        controller.getCurrentDate();
    }
    
}
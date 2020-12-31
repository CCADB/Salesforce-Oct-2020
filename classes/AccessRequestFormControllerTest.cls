/*
    Test class for AccessRequestFormController
*/
@isTest
public with sharing class AccessRequestFormControllerTest {
    
    static testMethod void validateAccessRequestForm() {
        Lead lead = new Lead();
        AccessRequestFormController controller = new AccessRequestFormController(new Apexpages.standardcontroller(lead));
        controller.doverify();
        
        lead.FirstName = 'Test FirstName1';
        lead.LastName = 'Test LastName1';
        lead.Company = 'Test CompanyName';
        lead.Email = 'test@gmail.com';
        
        controller = new AccessRequestFormController(new Apexpages.standardcontroller(lead));
        controller.doverify();
        
        lead.FirstName = 'Test FirstName2';
        lead.LastName = 'Test LastName2';
        lead.Company = 'Test CompanyName';
        lead.Email = 'test@gmail.com';
        lead.Salesforce_Terms_of_Service__c = 'I confirm that my CA can abide by the Salesforce Terms of Service';
        
        controller = new AccessRequestFormController(new Apexpages.standardcontroller(lead));
        
        controller.doverify();
        controller.strConfirmEmail = 'test1@gmail.com';
        controller.doverify();
        controller.strConfirmEmail = 'test@gmail.com';
        controller.doverify();
    }
}
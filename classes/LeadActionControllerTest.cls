/*******************************************************************************************************
 Name: LeadActionControllerTest

 Dependencies: LeadActionController controller class, LeadAction VF page, LeadActionTest class

 Description: Test class is created for LeadAction class. Once the Lead is converted, email is sent
 to the CA (Lead Convert email template). Another email is sent to admin@ccadb.org to issue license (no 
 template used). Lead conversion creates CA Owner and a Contact records.
 
 Instructions: Lead standard fields are automatically mapped by the lead conversion process.
 *******************************************************************************************************
 Revision History:
 
     4/30/2019 - Created new class
 *******************************************************************************************************/
 
@isTest
public with sharing class LeadActionControllerTest {
    
    static testMethod void TestLeadAction() {
        LeadActionController controller = new LeadActionController(new Apexpages.standardcontroller(new Lead()));
        controller.BackToRecord();
        
        Lead lead = new Lead(LastName = 'Test Lead',Company = 'Test Company', Email = 'test@gmail.com');
        insert lead;
        
        Apexpages.currentPage().getParameters().put('type','close');
        controller = new LeadActionController(new Apexpages.standardcontroller(lead));
        controller.CloseLeadWOConvert();
        controller.objLead.Reason_for_Denial__c = 'Test Reason';
        controller.CloseLeadWOConvert();
        
        lead = new Lead(LastName = 'Test Lead 1', Company = 'Test Company 1', Email = 'test1@gmail.com',
                        Alternate_CA_Name_s__c = 'Legal Company Name', Sponsored_By__c = 'Mozilla', 
                        CP_CPS_document_URLs__c = 'CP/CPS Document URLs');
        insert lead;
        Apexpages.currentPage().getParameters().put('type','convert');
        controller = new LeadActionController(new Apexpages.standardcontroller(lead));
        controller.BackToRecord();
    }
}
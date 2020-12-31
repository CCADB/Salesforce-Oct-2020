@isTest
private class CACommSummaryReportControllerTest{

  static testmethod void testSurveyReport() {
   
    // intialize the class which has the test data

    PageReference pageRef = Page.CACommSummaryReport;
    
     // create a CA Owner
     Account caOwnerAccount= getCAOwnerAccount();
     insert caOwnerAccount;
     
     // create a contact who would take the survey
     Contact contactSo = New Contact();
     contactSo.lastName = 'test';
     contactSo.accountId = caOwnerAccount.id;
     insert contactSo;
    
    // create a survey
    CA_Communication__c commSO = New CA_Communication__c ();
    commSo.name='Test';
    commSo.message__c='Test';
    insert commso;
    
    // create a dummy question 
    CA_Comm_Question__c  commQuestSo = new CA_Comm_Question__c ();
    commQuestSo.CA_Comm__c = commSo.id;
    commQuestSo.Order_No__c = 1;
    commQuestSo.Question__c = 'test';
    commQuestSo.question_type__c = 'Free Text (Multi line text box)';
    insert commQuestSo;
   
    // create dummy responses 
    CA_Comm_Response__c  commResponse = New CA_Comm_Response__c ();
    commResponse.Question_Id__c= commQuestSo.id;
    commResponse.response__c = 'test';
    commResponse.ca_owner__c = caOwnerAccount.id;
    commResponse.contact__c = contactSo.id;
    insert commResponse;
    CA_Comm_Response__c  commResponse2 = New CA_Comm_Response__c ();
    commResponse2.Question_Id__c= commQuestSo.id;
    commResponse2.response__c = 'test';
    commResponse2.ca_owner__c = caOwnerAccount.id;
    commResponse2.contact__c = contactSo.id;
    insert commResponse2;
    
    // set the survey id as one of the page parameters, this is used by the controller class 
    pageRef.getParameters().put('CommunicationId', commSo.id);  

    
    // set the current page reference
    Test.setCurrentPage(pageRef); 
 
    // initialize the controller class 
    CACommSummaryReportController commSummReportController= new CACommSummaryReportController();
 }
 
   public static Account getCAOwnerAccount()
    {
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

}
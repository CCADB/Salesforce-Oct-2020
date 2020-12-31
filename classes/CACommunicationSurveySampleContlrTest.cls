@isTest
public class CACommunicationSurveySampleContlrTest {
    private static @testsetup void setupData(){
        
        CA_Communication__c survey = new CA_Communication__c(Name = 'test survey0', Expiration_Date__c = System.today().addDays(7),
        Message__c = 'test message');
        insert survey;
        
        CA_Comm_Question__c question1 = new CA_Comm_Question__c(CA_Comm__c = survey.Id, Order_No__c = 1, Question__c = 'que 1', 
        Question_Type__c = 'Single Select (Radio buttons)',
        Required__c = true, Response_Option_1__c = 'Yes', Response_Option_2__c = 'No');
        //insert question1;
        
        CA_Comm_Question__c question2 = new CA_Comm_Question__c(CA_Comm__c = survey.Id, Order_No__c = 2, Question__c = 'que 2', 
        Question_Type__c = 'Multi Select (Check boxes)',
        Required__c = true, Response_Option_1__c = 'Yes', Response_Option_2__c = 'No');
        //insert question2;
        
        CA_Comm_Question__c question3 = new CA_Comm_Question__c(CA_Comm__c = survey.Id, Order_No__c = 3, Question__c = 'que 3', 
        Question_Type__c = 'Free Text (Multi line text box)',
        Required__c = false, Default_Text__c = 'Default_Text__c');
        
        CA_Comm_Question__c question4 = new CA_Comm_Question__c(CA_Comm__c = survey.Id, Order_No__c = 3, Question__c = 'que 4', 
        Question_Type__c = 'Date Type', Required__c = false);
        
        insert new List<CA_Comm_Question__c>{question1, question2, question3, question4};
    }
    
    static testmethod void testCase1(){
        
        PageReference pref = Page.CACommunicationSurveySample;
        Test.setCurrentPage(pref);
        
        CA_Communication__c survey = [SELECT Id FROM CA_Communication__c WHERE Name = 'test survey0' LIMIT 1];
        ApexPages.currentPage().getParameters().put('CACommunicationId', survey.Id);
        
        CACommunicationSurveySampleController obj = new CACommunicationSurveySampleController();
    }
    
    static testmethod void testCase2(){
        
        PageReference pref = Page.CACommunicationSurveySample;
        Test.setCurrentPage(pref);
        CA_Comm_Question__c question1 = [SELECT Id FROM CA_Comm_Question__c LIMIT 1];
        //CA_Communication__c survey = [SELECT Id FROM CA_Communication__c WHERE Name = 'test survey0' LIMIT 1];
        ApexPages.currentPage().getParameters().put('CACommunicationId', question1.Id);
        
        CACommunicationSurveySampleController obj = new CACommunicationSurveySampleController();
    }
    
    static testmethod void testCase3(){
        
        PageReference pref = Page.CACommunicationSurveySample;
        Test.setCurrentPage(pref);
        
        CA_Communication__c survey = [SELECT Id FROM CA_Communication__c WHERE Name = 'test survey0' LIMIT 1];
        ApexPages.currentPage().getParameters().put('CACommunicationId', 'abcd1234');
        
        CACommunicationSurveySampleController obj = new CACommunicationSurveySampleController();
    }
}
@isTest
public class CACommunicationSurveyControllerTest {

    private static @testsetup void setupData(){
        
        Account acc = new Account(Name = 'test account', status__c= 'Included', 
        RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('CA Owner').getRecordTypeID());
        insert acc;
        
        Contact con = new Contact(LastName = 'testName', AccountId = acc.Id);
        insert con;
        
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
        
        CA_Comm_Question__c question4 = new CA_Comm_Question__c(CA_Comm__c = survey.Id, Order_No__c = 4, Question__c = 'que 4', 
        Question_Type__c = 'Date Type', Required__c = false);
        
        insert new List<CA_Comm_Question__c>{question1, question2, question3, question4};
        
        Test.startTest();
            //this is admin user
            User loggedInUser = new User(Alias = 'standt', Email='loggedin.user1@testorg.com', 
            EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
            LocaleSidKey='en_US', ProfileId = UserInfo.getProfileId(), 
            TimeZoneSidKey='America/Los_Angeles', UserName='loggedin.user1@testorg.com');

        System.runAs(loggedInUser) {
                
                Profile p = [SELECT Id FROM Profile WHERE Name = 'Customer Community Plus User']; 
                //this is community user
                User communityUser = new User(Alias = 'standt', Email='standardportaluser_mozilla@testorg.com', 
                    EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
                    LocaleSidKey='en_US', ProfileId = p.Id, 
                    TimeZoneSidKey='America/Los_Angeles', UserName='standardportaluser_mozilla@testorg.com',
                    ContactId = con.Id, IsActive = true);
                    
                insert communityUser;
        }
        
        Test.stopTest();
    }
    
    static testmethod void test1_WithInternalUser(){
        
        PageReference pref = Page.CACommunicationSurvey;
        Test.setCurrentPage(pref);
        
        CA_Communication__c survey = [SELECT Id FROM CA_Communication__c WHERE Name = 'test survey0' LIMIT 1];
        CACommunicationSurveyController obj = new CACommunicationSurveyController();
        obj.selectedSurveyId = survey.Id;
        
        //lstQuestions
        obj.getUserContact();
        obj.getQuesionnairies();
        
        for(CACommunicationSurveyController.Question que : obj.lstQuestions){
            que.selectedOption = '0';
            que.selectedOptions = new List<String>{'1'};
            que.choices = 'Yes';
        }
        
        obj.submitResults();
        obj.doCancel();
    }
    
    
    static testmethod void test1_WithExternalUser(){
        
        User communityUser = [SELECT Id, ContactId, Contact.AccountId, Profile.Name, UserType FROM User WHERE Email = 'standardportaluser_mozilla@testorg.com' LIMIT 1];
        System.debug('user: '+communityUser);
        System.runAs(communityUser){
        
        PageReference pref = Page.CACommunicationSurvey;
        Test.setCurrentPage(pref);
        
        CA_Communication__c survey = [SELECT Id FROM CA_Communication__c WHERE Name = 'test survey0' LIMIT 1];
        CACommunicationSurveyController obj = new CACommunicationSurveyController();
        obj.selectedSurveyId = survey.Id;
        //lstQuestions
        obj.getUserContact();
        obj.getQuesionnairies();
        
        for(CACommunicationSurveyController.Question que : obj.lstQuestions){
            que.selectedOption = '0';
            que.selectedOptions = new List<String>{'1'};
            que.choices = 'Yes';
        }
        
        obj.submitResults();
        obj.doCancel();
        
        }
    }
    
    
    static testmethod void test1_WithInternalUser_ExistinSurvey(){
        
        User communityUser = [SELECT Id, ContactId, Contact.AccountId, Profile.Name, UserType FROM User WHERE Email = 'standardportaluser_mozilla@testorg.com' LIMIT 1];
        
        CA_Communication__c survey = [SELECT Id FROM CA_Communication__c WHERE Name = 'test survey0' LIMIT 1];
        
        List<CA_Comm_Question__c> lstQue = [SELECT Id, Order_No__c, Question__c, Question_Type__c, Required__c, 
                                            Response_Option_1__c, Response_Option_2__c
                                            FROM CA_Comm_Question__c
                                            WHERE CA_Comm__c = :survey.Id 
                                            ORDER BY Order_No__c];
        
        
        List<CA_Comm_Response__c> lstResponse = new List<CA_Comm_Response__c>();
        for(CA_Comm_Question__c que : lstQue){
            
            CA_Comm_Response__c res1 = new CA_Comm_Response__c();
            res1.CA_Owner__c = communityUser.Contact.AccountId;
            res1.Contact__c = communityUser.ContactId;
            res1.Question_Id__c = que.Id;
            res1.Response__c = 'Yes';
            res1.Response_Option_No__c = '1';
            res1.Date_Type_Response__c = date.today();
            lstResponse.add(res1);
        }
        
        insert lstResponse;
        
        PageReference pref = Page.CACommunicationSurvey;
        Test.setCurrentPage(pref);
        
        ApexPages.currentPage().getParameters().put('CACommunicationId', survey.Id);
        ApexPages.currentPage().getParameters().put('ContactId', [SELECT Id FROM Contact WHERE LastName = 'testName'].Id);
        
        CACommunicationSurveyController obj = new CACommunicationSurveyController();
        obj.selectedSurveyId = survey.Id;
        //lstQuestions
        obj.getUserContact();
        obj.getQuesionnairies();
        
        for(CACommunicationSurveyController.Question que : obj.lstQuestions){
            que.selectedOption = '0';
            que.selectedOptions = new List<String>{'1'};
            que.choices = 'Yes';
        }
        
        obj.submitResults();
        obj.doCancel();
    }
    
    static testmethod void test_blankRequiredValues1_ExistinSurvey(){
        
        User communityUser = [SELECT Id, ContactId, Contact.AccountId, Profile.Name, UserType FROM User WHERE Email = 'standardportaluser_mozilla@testorg.com' LIMIT 1];
        
        CA_Communication__c survey = [SELECT Id FROM CA_Communication__c WHERE Name = 'test survey0' LIMIT 1];
        
        List<CA_Comm_Question__c> lstQue = [SELECT Id, Order_No__c, Question__c, Question_Type__c, Required__c, 
                                            Response_Option_1__c, Response_Option_2__c
                                            FROM CA_Comm_Question__c
                                            WHERE CA_Comm__c = :survey.Id 
                                            ORDER BY Order_No__c];
        
        for(CA_Comm_Question__c que : lstQue){
            que.Required__c = true;
        }
        update lstQue;
        
        List<CA_Comm_Response__c> lstResponse = new List<CA_Comm_Response__c>();
        for(CA_Comm_Question__c que : lstQue){
            
            CA_Comm_Response__c res1 = new CA_Comm_Response__c();
            res1.CA_Owner__c = communityUser.Contact.AccountId;
            res1.Contact__c = communityUser.ContactId;
            res1.Question_Id__c = que.Id;
            res1.Response__c = 'Yes';
            res1.Response_Option_No__c = '1';
            res1.Date_Type_Response__c = date.today();
            lstResponse.add(res1);
        }
        
        insert lstResponse;
        
        PageReference pref = Page.CACommunicationSurvey;
        Test.setCurrentPage(pref);
        
        ApexPages.currentPage().getParameters().put('CACommunicationId', survey.Id);
        ApexPages.currentPage().getParameters().put('ContactId', [SELECT Id FROM Contact WHERE LastName = 'testName'].Id);
        
        CACommunicationSurveyController obj = new CACommunicationSurveyController();
        obj.selectedSurveyId = survey.Id;
        //lstQuestions
        obj.getUserContact();
        obj.getQuesionnairies();
        
        for(CACommunicationSurveyController.Question que : obj.lstQuestions){
            que.required = true;
            que.selectedOption = null;
            que.renderSelectRadio = 'true';
            que.renderSelectCheckboxes = 'true';
            que.selectedOptions = null;
            que.renderFreeText = 'false';
            que.choices = null;
            que.dateResonse.Date_Type_Response__c = null;
        }
        
        obj.submitResults();
        obj.doCancel();
    }
    
    static testmethod void test_blankRequiredValues2_ExistinSurvey(){
        
        User communityUser = [SELECT Id, ContactId, Contact.AccountId, Profile.Name, UserType FROM User WHERE Email = 'standardportaluser_mozilla@testorg.com' LIMIT 1];
        
        CA_Communication__c survey = [SELECT Id FROM CA_Communication__c WHERE Name = 'test survey0' LIMIT 1];
        
        List<CA_Comm_Question__c> lstQue = [SELECT Id, Order_No__c, Question__c, Question_Type__c, Required__c, 
                                            Response_Option_1__c, Response_Option_2__c
                                            FROM CA_Comm_Question__c
                                            WHERE CA_Comm__c = :survey.Id 
                                            ORDER BY Order_No__c];
        
        for(CA_Comm_Question__c que : lstQue){
            que.Required__c = true;
        }
        update lstQue;
        
        List<CA_Comm_Response__c> lstResponse = new List<CA_Comm_Response__c>();
        for(CA_Comm_Question__c que : lstQue){
            
            CA_Comm_Response__c res1 = new CA_Comm_Response__c();
            res1.CA_Owner__c = communityUser.Contact.AccountId;
            res1.Contact__c = communityUser.ContactId;
            res1.Question_Id__c = que.Id;
            res1.Response__c = 'Yes';
            res1.Response_Option_No__c = '1';
            res1.Date_Type_Response__c = date.today();
            lstResponse.add(res1);
        }
        
        insert lstResponse;
        
        PageReference pref = Page.CACommunicationSurvey;
        Test.setCurrentPage(pref);
        
        ApexPages.currentPage().getParameters().put('CACommunicationId', survey.Id);
        ApexPages.currentPage().getParameters().put('ContactId', [SELECT Id FROM Contact WHERE LastName = 'testName'].Id);
        
        CACommunicationSurveyController obj = new CACommunicationSurveyController();
        obj.selectedSurveyId = survey.Id;
        //lstQuestions
        obj.getUserContact();
        obj.getQuesionnairies();
        
        for(CACommunicationSurveyController.Question que : obj.lstQuestions){
            que.required = true;
            que.selectedOption = null;
            que.renderSelectRadio = 'false';
            que.renderSelectCheckboxes = 'true';
            que.selectedOptions = null;
            que.renderFreeText = 'false';
            que.choices = null;
            que.dateResonse.Date_Type_Response__c = null;
        }
        
        obj.submitResults();
        obj.doCancel();
    }
    
    static testmethod void test_blankRequiredValues3_ExistinSurvey(){
        
        User communityUser = [SELECT Id, ContactId, Contact.AccountId, Profile.Name, UserType FROM User WHERE Email = 'standardportaluser_mozilla@testorg.com' LIMIT 1];
        
        CA_Communication__c survey = [SELECT Id FROM CA_Communication__c WHERE Name = 'test survey0' LIMIT 1];
        
        List<CA_Comm_Question__c> lstQue = [SELECT Id, Order_No__c, Question__c, Question_Type__c, Required__c, 
                                            Response_Option_1__c, Response_Option_2__c
                                            FROM CA_Comm_Question__c
                                            WHERE CA_Comm__c = :survey.Id 
                                            ORDER BY Order_No__c];
        
        for(CA_Comm_Question__c que : lstQue){
            que.Required__c = true;
        }
        update lstQue;
        
        List<CA_Comm_Response__c> lstResponse = new List<CA_Comm_Response__c>();
        for(CA_Comm_Question__c que : lstQue){
            
            CA_Comm_Response__c res1 = new CA_Comm_Response__c();
            res1.CA_Owner__c = communityUser.Contact.AccountId;
            res1.Contact__c = communityUser.ContactId;
            res1.Question_Id__c = que.Id;
            res1.Response__c = 'Yes';
            res1.Response_Option_No__c = '1';
            res1.Date_Type_Response__c = date.today();
            lstResponse.add(res1);
        }
        
        insert lstResponse;
        
        PageReference pref = Page.CACommunicationSurvey;
        Test.setCurrentPage(pref);
        
        ApexPages.currentPage().getParameters().put('CACommunicationId', survey.Id);
        ApexPages.currentPage().getParameters().put('ContactId', [SELECT Id FROM Contact WHERE LastName = 'testName'].Id);
        
        CACommunicationSurveyController obj = new CACommunicationSurveyController();
        obj.selectedSurveyId = survey.Id;
        //lstQuestions
        obj.getUserContact();
        obj.getQuesionnairies();
        
        for(CACommunicationSurveyController.Question que : obj.lstQuestions){
            que.required = true;
            que.selectedOption = null;
            que.renderSelectRadio = 'false';
            que.renderSelectCheckboxes = 'false';
            que.selectedOptions = null;
            que.renderFreeText = 'true';
            que.choices = null;
            que.dateResonse.Date_Type_Response__c = null;
        }
        
        obj.submitResults();
        obj.doCancel();
    }
    
    static testmethod void test_blankRequiredValues4_ExistinSurvey(){
        
        User communityUser = [SELECT Id, ContactId, Contact.AccountId, Profile.Name, UserType FROM User WHERE Email = 'standardportaluser_mozilla@testorg.com' LIMIT 1];
        
        CA_Communication__c survey = [SELECT Id FROM CA_Communication__c WHERE Name = 'test survey0' LIMIT 1];
        
        List<CA_Comm_Question__c> lstQue = [SELECT Id, Order_No__c, Question__c, Question_Type__c, Required__c, 
                                            Response_Option_1__c, Response_Option_2__c
                                            FROM CA_Comm_Question__c
                                            WHERE CA_Comm__c = :survey.Id 
                                            ORDER BY Order_No__c];
        
        for(CA_Comm_Question__c que : lstQue){
            que.Required__c = true;
        }
        update lstQue;
        
        List<CA_Comm_Response__c> lstResponse = new List<CA_Comm_Response__c>();
        for(CA_Comm_Question__c que : lstQue){
            
            CA_Comm_Response__c res1 = new CA_Comm_Response__c();
            res1.CA_Owner__c = communityUser.Contact.AccountId;
            res1.Contact__c = communityUser.ContactId;
            res1.Question_Id__c = que.Id;
            res1.Response__c = 'Yes';
            res1.Response_Option_No__c = '1';
            res1.Date_Type_Response__c = date.today();
            lstResponse.add(res1);
        }
        
        insert lstResponse;
        
        PageReference pref = Page.CACommunicationSurvey;
        Test.setCurrentPage(pref);
        
        ApexPages.currentPage().getParameters().put('CACommunicationId', survey.Id);
        ApexPages.currentPage().getParameters().put('ContactId', [SELECT Id FROM Contact WHERE LastName = 'testName'].Id);
        
        CACommunicationSurveyController obj = new CACommunicationSurveyController();
        obj.selectedSurveyId = survey.Id;
        //lstQuestions
        obj.getUserContact();
        obj.getQuesionnairies();
        
        for(CACommunicationSurveyController.Question que : obj.lstQuestions){
            que.required = true;
            que.selectedOption = null;
            que.renderSelectRadio = 'false';
            que.renderSelectCheckboxes = 'false';
            que.selectedOptions = null;
            que.renderFreeText = 'false';
            que.renderDateType = 'true';
            que.choices = null;
            que.dateResonse.Date_Type_Response__c = null;
        }
        
        obj.submitResults();
        obj.doCancel();
    }
    
    static testmethod void test1_WithExternalUser_ExistinSurvey(){
        
        User communityUser = [SELECT Id, ContactId, Contact.AccountId, Profile.Name, UserType FROM User WHERE Email = 'standardportaluser_mozilla@testorg.com' LIMIT 1];
        CA_Communication__c survey = [SELECT Id FROM CA_Communication__c WHERE Name = 'test survey0' LIMIT 1];
        
        List<CA_Comm_Question__c> lstQue = [SELECT Id, Order_No__c, Question__c, Question_Type__c, Required__c, 
                                            Response_Option_1__c, Response_Option_2__c
                                            FROM CA_Comm_Question__c
                                            WHERE CA_Comm__c = :survey.Id 
                                            ORDER BY Order_No__c];
        
        
        List<CA_Comm_Response__c> lstResponse = new List<CA_Comm_Response__c>();
        for(CA_Comm_Question__c que : lstQue){
            
            CA_Comm_Response__c res1 = new CA_Comm_Response__c();
            res1.CA_Owner__c = communityUser.Contact.AccountId;
            res1.Contact__c = communityUser.ContactId;
            res1.Question_Id__c = que.Id;
            res1.Response__c = 'Yes';
            res1.Response_Option_No__c = '1';
            lstResponse.add(res1);
        }
        
        insert lstResponse;
    
        //System.debug('user: '+communityUser);
        
        PageReference pref = Page.CACommunicationSurvey;
        Test.setCurrentPage(pref);
        
        ApexPages.currentPage().getParameters().put('CACommunicationId', survey.Id);
        ApexPages.currentPage().getParameters().put('ContactId', [SELECT Id FROM Contact WHERE LastName = 'testName'].Id);
        
        CACommunicationSurveyController obj = new CACommunicationSurveyController();
        
        //lstQuestions
        obj.selectedSurveyId = survey.Id;
        obj.getUserContact();
        obj.getQuesionnairies();
        
        for(CACommunicationSurveyController.Question que : obj.lstQuestions){
            que.selectedOption = '0';
            que.selectedOptions = new List<String>{'1'};
            que.choices = 'Yes';
        }
        
        obj.submitResults();
        obj.doCancel();
    }
    
    static testmethod void test_SurveyWithNoQuestions(){
        
        User communityUser = [SELECT Id, ContactId, Contact.AccountId, Profile.Name, UserType FROM User WHERE Email = 'standardportaluser_mozilla@testorg.com' LIMIT 1];
        CA_Communication__c survey = new CA_Communication__c(Name = 'test survey1', Expiration_Date__c = System.today().addDays(7));
        insert survey;
        
        PageReference pref = Page.CACommunicationSurvey;
        Test.setCurrentPage(pref);
        
        ApexPages.currentPage().getParameters().put('CACommunicationId', survey.Id);
        ApexPages.currentPage().getParameters().put('ContactId', [SELECT Id FROM Contact WHERE LastName = 'testName'].Id);
        
        CACommunicationSurveyController obj = new CACommunicationSurveyController();
        obj.selectedSurveyId = survey.Id;
        //lstQuestions
        obj.getUserContact();
        obj.getQuesionnairies();
    
        obj.doCancel();
    }
}
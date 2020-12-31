@isTest
public class UpdatePortalContactInfoTest{
    
    static testmethod void testUpdatePortalContactInfo(){
        
        Account acc = new Account(Name = 'test account', status__c= 'Included', RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('CA Owner').getRecordTypeID());
        insert acc;
        
        Contact con = new Contact(LastName = 'testName', AccountId = acc.Id);
        insert con;
        
        Test.startTest();
        
        User loggedInUser = new User(Alias = 'standt', Email='loggedin.user1@testorg.com', 
        EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
        LocaleSidKey='en_US', ProfileId = UserInfo.getProfileId(), 
        TimeZoneSidKey='America/Los_Angeles', UserName='loggedin.user1@testorg.com');

        System.runAs(loggedInUser) {
                
            Profile p = [SELECT Id FROM Profile WHERE Name = 'Customer Community Plus User']; 
        
            User u = new User(Alias = 'standt', Email='standardportaluser_mozilla@testorg.com', 
                EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
                LocaleSidKey='en_US', ProfileId = p.Id, 
                TimeZoneSidKey='America/Los_Angeles', UserName='standardportaluser_mozilla@testorg.com',
                ContactId = con.Id, IsActive = true);
                
            insert u;
            
            u.IsActive = false;
            update u;
                
        }
        
        Test.stopTest();
        
    }
    
    static testmethod void testShareIntermediateCerts(){
        
        Account acc = new Account(Name='Test CA Owner');
        insert acc;
        
        // create a ROOT CA
        Account rootCA = New Account();
        rootCA.recordTypeId= Schema.SObjectType.Account.getRecordTypeInfosByName().get('Root Certificate').getRecordTypeId(); 
        rootCa.name = 'Root 1';
        rootCa.parentId = acc.id;
        rootCa.X_509_Certificate_PEM__c = 'abc';
        insert rootCa;
        
        // create intermediate CA
        Account testAccount = New Account();
        testAccount.name = 'Intermedia Certificate 1';
        testAccount.recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Intermediate Certificate').getRecordTypeId();
        testAccount.Status__c = 'Removed';
        testAccount.parentId = rootCA.id;
        testAccount.X_509_Certificate_PEM__c = 'abc';
        testAccount.CA_Owner_Id__c = acc.Id;
        insert testAccount;
        
        Contact con = new Contact(LastName = 'Contact Last Name', Email = 'testclass@userrole.com', 
                AccountId = acc.id, Type__c = 'Primary POC');
        con.recordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('CA Contact').getRecordTypeId();
        insert con;
                
        Test.startTest();
        
        User loggedInUser = new User();
        loggedInUser.ProfileId = [SELECT Id FROM Profile WHERE Name = 'Customer Community Plus Login User For CCADB' AND UserType = 'PowerCustomerSuccess' LIMIT 1].Id;
        loggedInUser.EmailEncodingKey = 'ISO-8859-1';
        loggedInUser.LanguageLocaleKey = 'en_US';
        loggedInUser.TimeZoneSidKey = 'America/New_York';
        loggedInUser.LocaleSidKey = 'en_US';
        loggedInUser.FirstName = 'first';
        loggedInUser.LastName = 'last';
        loggedInUser.Username = 'test@test1234098.com';   
        loggedInUser.CommunityNickname = 'testUser09887123';
        loggedInUser.Alias = 't1';
        loggedInUser.Email = 'no@email.com';
        loggedInUser.IsActive = true;
        loggedInUser.ContactId = con.Id;
        insert loggedInUser;
        
        Test.stopTest();
        
    }
}
/*******************************************************************************************************
 Name: RunBatchToClearPIIonUserTest

 Dependencies: RunBatchToClearPIIonUser, RunBatchToClearPIIonUserTest,
 RunBatchProcesses, RunBatchProcessesController, RunBatchProcessesControllerTest

 Description: This batch process has been created to clear the PII information on daily basis.
 
 CompanyName
 Department
 Division
 EmployeeNumber
 Title
 Street
 City
 State
 PostalCode
 Country
 Fax
 Phone
 MobilePhone (cleared this field for Community users and inactive Standard users) 
 
 User Type = 'AutomatedProcess','Guest','CsnOnly','CloudIntegrationUser' are not updated by this program.
 
 Instructions: 
    RUN A BATCH NOW:
       Database.executeBatch(new RunBatchToClearPIIonUser ());
    SCHEDULE A CLASS:
       RunBatchToClearPIIonUser.scheduleMe('Batch to clear PII fields on User Records');
 *******************************************************************************************************
 Revision History:
 
     10/5/2020 - Created new.
     
 ******************************************************************************************************/
@isTest(seealldata=false)
public with sharing class RunBatchToClearPIIonUserTest {
    static testmethod void TestUpdateUser(){
        UserRole userrole = [Select Id, DeveloperName From UserRole Where DeveloperName = 'CA_Program_Manager'];
        
        User adminUser = [Select Id, UserRoleId From User Where Id =: UserInfo.getUserId() Limit 1];

        adminUser.UserRoleId = userRole.Id;
        update adminUser;
        
        System.runAs(adminUser){
        
            Account acc = TestUtils.getCAOwner();
            insert acc;
                
            Contact con = TestUtils.getContact(acc.id);
            con.recordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('CA Contact').getRecordTypeId();
            insert con;
            
            
            User user = new User();
            user.ProfileId = [SELECT Id FROM Profile WHERE Name = 'Customer Community Plus Login User - CAs' AND UserType = 'PowerCustomerSuccess' LIMIT 1].Id;
            user.EmailEncodingKey = 'ISO-8859-1';
            user.LanguageLocaleKey = 'en_US';
            user.TimeZoneSidKey = 'America/New_York';
            user.LocaleSidKey = 'en_US';
            user.FirstName = 'first';
            user.LastName = 'last';
            user.Username = 'test@test1234098.com';   
            user.CommunityNickname = 'testUser09887123';
            user.Alias = 't1';
            user.Email = 'no@email.com';
            user.IsActive = true;
            user.ContactId = con.Id;
            user.CompanyName = 'Test Company';
            user.MobilePhone = '1234567890';
            insert user;
            
            RunBatchToClearPIIonUser.scheduleMe('Batch To Clear PII fields on User');
            
            Test.startTest();
            
            //run a batch.
            Database.executeBatch(new RunBatchToClearPIIonUser(),300);
            
            Test.stopTest();
        }
    }
}
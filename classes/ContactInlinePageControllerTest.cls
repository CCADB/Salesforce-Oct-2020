/*******************************************************************************************************
 Name: ContactInlinePageControllerTest

 Dependencies: ContactInlinePageController controller class, ContactInlinePage vf page, 
 ContactInlinePageControllerTest test class

 Description: This class was created to restrict CAs (community users) to only see contacts belonging 
 to their organization. The program checks for logged in user record and fetches the associated Account
 and Contact records. The sharing rules or the Contact have been set to private. The vf page has been 
 added to CA Owner record and the standard related list has been removed.
 
 Instructions: None
 *******************************************************************************************************
 Revision History:
 
     09/18/2020 - Created new class
     
 ******************************************************************************************************/
 
@isTest
public with sharing class ContactInlinePageControllerTest {

    static testmethod void TestContactInlinePage() {
        Account caowner = TestUtils.getCAOwner();
        insert caowner;
        Contact con = TestUtils.getContact(caowner.Id);
        insert con;
        ContactInlinePageController controller = new ContactInlinePageController(new Apexpages.standardcontroller(caowner));
        
        User user = new User();
        //user.UserRoleId = urole.Id;//UserInfo.getUserRoleId();//
        //user.ProfileID = [Select Id From Profile Where UserType = 'PowerCustomerSuccess' LIMIT 1].id;
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
        
        System.RunAs(user) {
            controller = new ContactInlinePageController(new Apexpages.standardcontroller(caowner));
        }
    }
}
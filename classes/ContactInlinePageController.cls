/*******************************************************************************************************
 Name: ContactInlinePageController

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

public without sharing class ContactInlinePageController {
    
    public List<Contact> lstContacts {get; set;}
    public string strErrorMessage {get; set;}
    
    public ContactInlinePageController(Apexpages.standardcontroller controller){
        lstContacts = new List<Contact>();
        strErrorMessage = '';
        Id accId = controller.getId();
        List<User> lstLoggedUser = new List<User>([Select Id, ContactId, AccountId from USer Where Id =: UserInfo.getUserId()]);
        if(lstLoggedUser.size() > 0){
            if(lstLoggedUser[0].ContactId != null && accId == lstLoggedUser[0].AccountId) {
                lstContacts = new List<Contact>([Select Id, Name, Email, Type__c, Has_Bugzilla_Account__c, Is_Community_User__c, 
                                                Is_Community_User_Active__c, Last_Login__c 
                                                 from Contact 
                                                 where AccountId =: lstLoggedUser[0].AccountId
                                                 and Type__c != 'Obsolete'
                                                 order by Type__c]);
                if(lstContacts.size() == 0){
                    strErrorMessage = 'No records to display';
                }
            } else {
                strErrorMessage  = 'This Contacts list is only available when viewing your own CA.';
                //this is for internal users
                //lstContacts = new List<Contact>([Select Id, Name, Email, Type__c, Has_Bugzilla_Account__c, Is_Community_User__c, Is_Community_User_Active__c, Last_Login__c from Contact Where AccountId =: accId]);
            }
        }
    }
}
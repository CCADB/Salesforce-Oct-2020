/************
Description: Controller to update Last Login field on Contact from User object for all community users. 
************/

public with sharing class UpdateLastLoginController {

    public UpdateLastLoginController(){
        
    }
    
    public static void UpdateContacts(){
        //query all active and community users
        List<User> lstUsers = new List<User>([SELECT Id, Name, Email, IsActive, LastLoginDate, IsPortalEnabled, 
                    ContactId FROM User Where IsPortalEnabled = true and IsActive = true]);
        //map that stores contact id and last login
        map<Id,DateTime> mapContactWiseLastLogin = new map<Id,DateTime>();
        for(User objUser: lstUsers){
            mapContactWiseLastLogin.put(objUser.ContactId, objUser.LastLoginDate);
        }
        if(mapContactWiseLastLogin.size() > 0){
            List<Contact> lstContactToUpdate = new List<Contact>();
            List<Contact> lstAllContacts = new List<Contact>([select Id,Last_Login__c, Name from Contact Where 
                            Id in: mapContactWiseLastLogin.keyset()]);
            for(Contact objContact: lstAllContacts){
                //we are checking this because to avoid to update all contacts. 
                //we will update only those contact which doesn't have same last login
                //check if contact doesn't have same last login then we will update that contact
                if(mapContactWiseLastLogin.containskey(objContact.Id) && 
                    objContact.Last_Login__c != mapContactWiseLastLogin.get(objContact.Id)){
                    objContact.Last_Login__c = mapContactWiseLastLogin.get(objContact.Id);
                    lstContactToUpdate.add(objContact);
                }
            }
            try {
                if(lstContactToUpdate.size() > 0){
                    update lstContactToUpdate;
                    if(ApexPages.currentPage() != null){
                        ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.Confirm,'Last Login info on Contact records has been updated successfully!');
                        ApexPages.addMessage(myMsg);
                    }
                } else {
                    if(ApexPages.currentPage() != null){
                        ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.Info,'Last Login info on Contact records is up-to-date.');
                        ApexPages.addMessage(myMsg);
                    }
                }
            } catch (Exception ex){
                if(ApexPages.currentPage() != null){
                    Apexpages.addMessages(ex);
                }
            }
        }
    }
}
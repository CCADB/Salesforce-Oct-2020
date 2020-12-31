/*
 Description:Class is used for Custom Login Page for community
 */
global with sharing class CustomLoginController {
    global String username{get;set;}
    global String password{get;set;}
    global CustomLoginController () {}
    global boolean isLoginFailed{get;set;}
    global PageReference forwardToCustomAuthPage() {
    
        return new PageReference( '/CustomLogin');
    }
    global PageReference login() {
        PageReference ref = Site.login(username, password, null);
        if(ref == null){
            isLoginFailed=true;
            return null;
        } else {
            //code commented because created program to run daily and update last login field
            /* REMOVE WITH SHARING KEYWORD FROM CLASS - because to all access to edit contact*/
            /*List<User> lstUser = new List<User>([select Id,ContactId,LastLoginDate from User Where Username =: username]);
            if(lstUser.size() > 0 && lstUser[0].ContactId != null) {
                Contact objContact = new Contact();
                objContact.Id = lstUser[0].ContactId;
                objContact.Last_Login__c = lstUser[0].LastLoginDate;   // track user last login date
                update objContact;
            }*/
            
            return ref;
        }  
    }
}
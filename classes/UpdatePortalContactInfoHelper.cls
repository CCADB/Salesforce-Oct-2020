/******************************************************************************************************
 Helper class to UpdatePortalContactInfo trigger (on User object)

 UpdatePortalContactInfoHelper: updates the user login info for Contacts who are enabled as 
 customer community users

 ShareIntermediateCerts: *** THIS METHOD IS NO BULKIFIED ****
 When the a contact is created with type = Primary POC or POC, this method is called to transfer 
 ownership & share the intermediate certs if owned by internal users. Inter certs must have CRU permissions
 on all records which are related to the same CA Owner

******************************************************************************************************/

public class UpdatePortalContactInfoHelper{
    
    // @future is used to solve the Mixed DML Operations error
    @future(Callout = false)
    public static void updateContactInfo(Map<Id, Boolean> isActiveMap, Map<Id, String> profileNameMap){
        
        List<Contact> updateContacts = new List<Contact>();
        
        for(Id contactId : profileNameMap.keySet()){
           
          updateContacts.add(new Contact(Id = contactId, Is_Community_User__c = true, Is_Community_User_Active__c = isActiveMap.get(contactId), Community_User_Profile__c = profileNameMap.get(contactId))); 
        }
        
        try{
            update updateContacts;    
        }catch(Exception exp){
            System.debug('Cannot handle because of async mode.');
        }
    }
    
    /* This code gets triggered when community use gets created.*/
    /* Check if portal user and the contact id not null */
   
    public static void ShareIntermediateCerts(List<User> lstInsertedUsers){
        if(lstInsertedUsers[0].IsPortalEnabled && lstInsertedUsers[0].ContactId != null) {
            // we are querying on User and contact and checking contact type is Primary POC or POC. 
            // trigger should run only if contact is Primary POC or POC.
            List<User> lstPOCUser = new List<User>([select Id,Contact.Account.Id,UserRoleId from User Where Id =: lstInsertedUsers[0].Id and
                Contact.Type__c in ('Primary POC','POC')]);
            if(lstPOCUser.size() > 0) {
                //call future method to avoic MIX DML exception
                ShareInterCerts(lstPOCUser[0].Id);
            }
        }
    }
    
    @future
    public static void ShareInterCerts(string userId){
        //querying on user and if it is Primary POC or POC.
        List<User> lstPOCUser = new List<User>([select Id,Contact.Account.Id,UserRoleId from User Where Id =: userId and
                Contact.Type__c in ('Primary POC','POC')]);
        if(lstPOCUser.size() > 0) {
            //get all internal users
            List<User> lstInternalUsers = new List<User>([Select Id from User Where IsPortalEnabled = false]);
                    
            //find group id from user role of newly user created
            string GroupId = '';
            for(Group objG: [SELECT Id, Name, DeveloperName, RelatedId, Type, Email FROM 
                            Group Where RelatedId =: lstPOCUser[0].UserRoleId and Type =: 'Role']){
                GroupId = objG.Id;
            }
            
            //get record type id
            String ICertificateRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Intermediate Certificate').getRecordTypeId();
            
            List<AccountShare> lstAccountSharetoInsert = new List<AccountShare>();
            List<Account> lstAccToUpdate = new List<Account>();
            //querying all intermediate accounts that are created by Internal users and CA Owner should be related account of user
            for(Account objAccount: [Select Id,RecordTypeId from Account Where RecordTypeId =: ICertificateRecordTypeId 
                    and CA_Owner_ID__c =: lstPOCUser[0].Contact.Account.Id and OwnerId in: lstInternalUsers]){
                //create manual share record
                if(objAccount.RecordTypeId == ICertificateRecordTypeId && string.isnotblank(GroupId)){
                    AccountShare objAccountShare = new AccountShare();
                    objAccountShare.AccountAccessLevel = 'Edit';
                    objAccountShare.ContactAccessLevel = 'Read';
                    objAccountShare.OpportunityAccessLevel = 'Read';
                    objAccountShare.CaseAccessLevel = 'Read';
                    objAccountShare.AccountId = objAccount.Id;
                    objAccountShare.UserOrGroupId = GroupId ;
                    lstAccountSharetoInsert.add(objAccountShare);
                }
                //set owner id
                if(objAccount.RecordTypeId == ICertificateRecordTypeId) {
                    Account objAccToUpdate = new Account();
                    objAccToUpdate.Id = objAccount.Id;
                    objAccToUpdate.OwnerId = lstPOCUser[0].Id;
                    lstAccToUpdate.add(objAccToUpdate);
                }
            }
            
            //update list of account that changes owner. 
            if(lstAccToUpdate.size() > 0){
                update lstAccToUpdate;
            }
            
            //create manual share records for intermediate certs.
            if(lstAccountSharetoInsert.size() > 0) {
                insert lstAccountSharetoInsert;
            }
        }
    }
}
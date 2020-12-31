/*
// This method replaces sharing rules from sharing settings
// This method is used to add manually share intermediate cert records for community user. 
// Community users beloning to same UserGroup can read/edit each others intermediate certs other can only read.
// It is called from trigger each time when community user inserts and updates.
//updates
// 04/19/2018        Added try-catch exception while updating accounts to show validation exception.
*/
public class AccountManualShareTriggerHelper {
    //New method for sharing by Sunil
    public static void ManualAccountSharing(List<Account> lstallAccounts) {
        String ICertificateRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Intermediate Certificate').getRecordTypeId();
        set<Id> setAccountIds = new set<Id>();
        boolean isCommunityUser = false;
        string strLoggedUserRoleId = '';
        string strUserGroupId = '';
        //get Parent RoleId for Portal Users
        List<User> lstUsers = new List<User>([select Id,Name,Contact.Account.Id,IsPortalEnabled,UserRoleId from User Where Id =: UserInfo.getUserId()]); 
        if(lstUsers.size() > 0 && lstUsers[0].IsPortalEnabled && lstUsers[0].UserRoleId != null) {
            isCommunityUser = true;
            strLoggedUserRoleId = lstUsers[0].UserRoleId;
        }
        // find the user group for CA Owner
        List<Group> lstCAOwnergroup = new List<Group>([SELECT Id, Name, DeveloperName, RelatedId, Type, Email FROM 
                            Group Where RelatedId =: strLoggedUserRoleId and Type =: 'Role']);
        if(lstCAOwnergroup.size() > 0) {
            strUserGroupId = lstCAOwnergroup[0].Id;
        }
        if(isCommunityUser) {
            if(string.Isnotblank(strUserGroupId)){
                // assign access level 
                List<AccountShare> lstAccountSharetoUpsert = new List<AccountShare>();
                for(Account objAccount: lstallAccounts){
                    if(objAccount.RecordTypeId == ICertificateRecordTypeId){
                        AccountShare objAccountShare = new AccountShare();
                        objAccountShare.AccountAccessLevel = 'Edit';
                        objAccountShare.ContactAccessLevel = 'Read';
                        objAccountShare.OpportunityAccessLevel = 'Read';
                        objAccountShare.CaseAccessLevel = 'Read';
                        objAccountShare.AccountId = objAccount.Id;
                        objAccountShare.UserOrGroupId = strUserGroupId;
                        lstAccountSharetoUpsert.add(objAccountShare);
                    }
                }
                
                if(lstAccountSharetoUpsert.size() > 0) {
                    upsert lstAccountSharetoUpsert;
                }
            }
        } else {
            for(Account objAccount: lstallAccounts){
                if(objAccount.RecordTypeId == ICertificateRecordTypeId){
                    // Commented by Poonam on 5/17/2017 - allow internal users to add intermediate certs until Microsoft CAs are added to the community
                    // objAccount.addError('Root Store Manager should not create intermediate cert record. Please ask CA to login as community user to create an intermediate cert.');
                }
            }
        }
    }
    
    public static void TransferOwnerAndManualSharingForInternalUsers(List<Account> lstallAccounts){
        String ICertificateRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Intermediate Certificate').getRecordTypeId();
        boolean isInternalUser = false;
        
        //get Parent RoleId for Portal Users
        List<User> lstUsers = new List<User>([select Id,Name,Contact.Account.Id,IsPortalEnabled,UserRoleId from User Where Id =: UserInfo.getUserId()]); 
        if(lstUsers.size() > 0 && !lstUsers[0].IsPortalEnabled) {
            isInternalUser = true;
        }
        if(isInternalUser) {
            set<Id> setCAOwnerAccountIds = new set<Id>();
            
            //key as Account Id and value as Contact Id
            map<Id,Id> mapAccountWisePOC = new map<Id,Id>();
            
            for(Account objAcc: lstallAccounts){
                if(objAcc.CA_Owner_ID__c != null && objAcc.CA_Owner_ID__c != '') { 
                    setCAOwnerAccountIds.add(objAcc.CA_Owner_ID__c);
                }
            }
            if(setCAOwnerAccountIds.size() > 0) {
                for(Contact objCon: [select Id,Name,Type__c,AccountId from Contact Where AccountId in:setCAOwnerAccountIds 
                            and Type__c in ('Primary POC','POC') and Is_Community_User__c = true]){
                    if(objCon.Type__c == 'Primary POC') {
                        mapAccountWisePOC.put(objCon.AccountId, objCon.Id);
                    } else if(objCon.Type__c == 'POC' && !mapAccountWisePOC.containskey(objCon.AccountId)){
                        mapAccountWisePOC.put(objCon.AccountId, objCon.Id); 
                    }
                }
            }
            //key as Role Id and value as Account Id
            map<Id,Id> mapUserWiseRole = new map<Id,Id>();
            
            //key as Account Id and value as User Id
            map<Id,Id> mapUserWiseAccount = new map<Id,Id>();
            
            for(User objUser: [select Id,Name,Contact.Account.Id,IsPortalEnabled, UserRoleId from User Where 
                        ContactId in: mapAccountWisePOC.values() and IsPortalEnabled = true and IsActive = true]){
                mapUserWiseRole.put(objUser.UserRoleId, objUser.Contact.Account.Id);
                mapUserWiseAccount.put(objUser.Contact.Account.Id, objUser.Id);
            }
            //key as Account Id and value as Group Id
            map<Id,Id> mapAccountWiseGroup = new map<Id,Id>();
            for(Group objG: [SELECT Id, Name, DeveloperName, RelatedId, Type, Email FROM 
                            Group Where RelatedId =: mapUserWiseRole.keyset() and Type =: 'Role']){
                if(mapUserWiseRole.containskey(objG.RelatedId)) {
                    mapAccountWiseGroup.put(mapUserWiseRole.get(objG.RelatedId),objG.Id);    
                }
            }
            List<AccountShare> lstAccountSharetoInsert = new List<AccountShare>();
            List<Account> lstAccToUpdate = new List<Account>();
            for(Account objAccount: lstallAccounts){
                if(objAccount.RecordTypeId == ICertificateRecordTypeId && objAccount.CA_Owner_ID__c != null && mapAccountWiseGroup.containskey(objAccount.CA_Owner_ID__c)){
                    AccountShare objAccountShare = new AccountShare();
                    objAccountShare.AccountAccessLevel = 'Edit';
                    objAccountShare.ContactAccessLevel = 'Read';
                    objAccountShare.OpportunityAccessLevel = 'Read';
                    objAccountShare.CaseAccessLevel = 'Read';
                    objAccountShare.AccountId = objAccount.Id;
                    objAccountShare.UserOrGroupId = mapAccountWiseGroup.get(objAccount.CA_Owner_ID__c);
                    lstAccountSharetoInsert.add(objAccountShare);
                }
                if(objAccount.RecordTypeId == ICertificateRecordTypeId && objAccount.CA_Owner_ID__c != null && mapUserWiseAccount.containskey(objAccount.CA_Owner_ID__c)) {
                    Account objAccToUpdate = new Account();
                    objAccToUpdate.Id = objAccount.Id;
                    objAccToUpdate.OwnerId = mapUserWiseAccount.get(objAccount.CA_Owner_ID__c);
                    lstAccToUpdate.add(objAccToUpdate);
                }
            }
            
            if(lstAccToUpdate.size() > 0){
                try {
                    update lstAccToUpdate;
                } catch (Exception ex){
                    for(Account objAcc: lstallAccounts) {
                        string ErrorMessage = 'Trigger Error - Cannot proceed to update record due to following errors:: ' + ex.getMessage();
                        objAcc.addError(ErrorMessage);
                    }
                }
            }
            
            if(lstAccountSharetoInsert.size() > 0) {
                insert lstAccountSharetoInsert;
            }
        }
    }
    
    //update Sharing when Owner has changed
    public static void UpdateManualSharingOwnerChanged(List<Account> lstallAccounts, map<Id, Account> mapOldAccounts){
        String ICertificateRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Intermediate Certificate').getRecordTypeId();
        
        set<Id> setCAOwnerAccountIds = new set<Id>();
        
        //key as Account Id and value as Contact Id
        map<Id,Id> mapAccountWisePOC = new map<Id,Id>();
        
        for(Account objAcc: lstallAccounts){
            if(objAcc.OwnerId != mapOldAccounts.get(objAcc.Id).OwnerId && objAcc.CA_Owner_ID__c != null && objAcc.CA_Owner_ID__c != '') { 
                setCAOwnerAccountIds.add(objAcc.CA_Owner_ID__c);
            }
        }
        if(setCAOwnerAccountIds.size() > 0) {
            for(Contact objCon: [select Id,Name,Type__c,AccountId from Contact Where AccountId in:setCAOwnerAccountIds 
                        and Type__c in ('Primary POC','POC') and Is_Community_User__c = true]){
                if(objCon.Type__c == 'Primary POC') {
                    mapAccountWisePOC.put(objCon.AccountId, objCon.Id);
                } else if(objCon.Type__c == 'POC' && !mapAccountWisePOC.containskey(objCon.AccountId)){
                    mapAccountWisePOC.put(objCon.AccountId, objCon.Id); 
                }
            }
        }
        //key as Role Id and value as Account Id
        map<Id,Id> mapUserWiseRole = new map<Id,Id>();
        
        //key as Account Id and value as User Id
        map<Id,Id> mapUserWiseAccount = new map<Id,Id>();
        
        for(User objUser: [select Id,Name,Contact.Account.Id,IsPortalEnabled, UserRoleId from User Where 
                    ContactId in: mapAccountWisePOC.values() and IsPortalEnabled = true and IsActive = true]){
            mapUserWiseRole.put(objUser.UserRoleId, objUser.Contact.Account.Id);
            mapUserWiseAccount.put(objUser.Contact.Account.Id, objUser.Id);
        }
        //key as Account Id and value as Group Id
        map<Id,Id> mapAccountWiseGroup = new map<Id,Id>();
        for(Group objG: [SELECT Id, Name, DeveloperName, RelatedId, Type, Email FROM 
                        Group Where RelatedId =: mapUserWiseRole.keyset() and Type =: 'Role']){
            if(mapUserWiseRole.containskey(objG.RelatedId)) {
                mapAccountWiseGroup.put(mapUserWiseRole.get(objG.RelatedId),objG.Id);    
            }
        }
        List<AccountShare> lstAccountSharetoInsert = new List<AccountShare>();
        for(Account objAccount: lstallAccounts){
            if(objAccount.RecordTypeId == ICertificateRecordTypeId && objAccount.CA_Owner_ID__c != null && mapAccountWiseGroup.containskey(objAccount.CA_Owner_ID__c)){
                AccountShare objAccountShare = new AccountShare();
                objAccountShare.AccountAccessLevel = 'Edit';
                objAccountShare.ContactAccessLevel = 'Read';
                objAccountShare.OpportunityAccessLevel = 'Read';
                objAccountShare.CaseAccessLevel = 'Read';
                objAccountShare.AccountId = objAccount.Id;
                objAccountShare.UserOrGroupId = mapAccountWiseGroup.get(objAccount.CA_Owner_ID__c);
                lstAccountSharetoInsert.add(objAccountShare);
            }
        }
        //insert account share
        if(lstAccountSharetoInsert.size() > 0) {
            insert lstAccountSharetoInsert;
        }
    }
}
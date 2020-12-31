/******************************************************************************************************
   User Trigger
   
   1) Trigger updates the user login info for Contacts who are enabled as customer community users. 
      Method called is 'UpdatePortalContactInfoHelper.UpdatePortalContactInfo'

   2) When the a contact is created with type = Primary POC or POC,
      'UpdatePortalContactInfoHelper.ShareIntermediateCerts' is called to transfer ownership & share the 
      intermediate certs if created by internal users     
******************************************************************************************************/

trigger UpdatePortalContactInfo on User (after Insert, after Update) {
    
    // When new user is created for POC contact, transfer ownership & apply sharing rules for inter cert records
    if(Trigger.isAfter && Trigger.IsInsert){
        UpdatePortalContactInfoHelper.ShareIntermediateCerts(Trigger.New);
    }
    
    Map<Id, String> mapProfileName = new Map<Id, String>();
    Map<Id, Boolean> mapContactToActiveUser = new Map<Id, Boolean>();
    Map<Id, String> mapContactToProfileName = new Map<Id, String>();
    
    if(Trigger.isAfter){
        
        Set<Id> profileIds = new Set<Id>();
        for(User newUser : Trigger.new){
            
            profileIds.add(newUser.ProfileId);
            
        }
        
        if(profileIds.size() > 0){
            
            for(Profile uProfile : [SELECT Id, Name FROM Profile WHERE Id IN :profileIds]){
                mapProfileName.put(uProfile.Id, uProfile.Name);
            }
        }
    }
    
    for(User portalUser : Trigger.new){
        
        if(Trigger.isAfter && (Trigger.isInsert && portalUser.ContactId != null) || (Trigger.isUpdate && (portalUser.ContactId != null && (portalUser.IsActive != Trigger.OldMap.get(portalUser.Id).IsActive ||
            portalUser.ProfileId != Trigger.OldMap.get(portalUser.Id).ProfileId)))){
            
            mapContactToActiveUser.put(portalUser.ContactId, portalUser.IsActive);
            mapContactToProfileName.put(portalUser.ContactId, mapProfileName.get(portalUser.profileId));
            
        }   
    }
    
    if(mapContactToActiveUser.size() > 0){
        UpdatePortalContactInfoHelper.updateContactInfo(mapContactToActiveUser, mapContactToProfileName);
    }
}
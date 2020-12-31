// Trigger for the Contact object which handles all the events and based on the event delegates the task 
// to the corresponding trigger handler method in the ContactTriggerHelper class

trigger ContactTrigger on Contact (before insert, before update) {

    if(trigger.isBefore){
    
        //set prefix if contact type is obosolete or other
        if(!ContactTriggerHelper.isRecursion && (trigger.isInsert || trigger.isUpdate)) {
            ContactTriggerHelper.PrefixFirstNameWithAsterisk (Trigger.New); 
        } 
        
        // Set Account Id for Auditor Contacts
        ContactTriggerHelper.SetAccountIdForAuditorContacts (Trigger.New);      
    }
}
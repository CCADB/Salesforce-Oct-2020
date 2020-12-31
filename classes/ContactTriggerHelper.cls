/*******************************************************************************************************************
 SetAccountIdForAuditorContacts: Set Account Id for all Auditor Contacts.
 
 PrefixFirstNameWithAsterisk : Prefix '**' to FirstName when Type is set to 'Obsolete' or 'Other'
 for record type 'CA Contact'. If Type is set to any other type, then remove '**', if it has the prefix.
*******************************************************************************************************************/


public class ContactTriggerHelper {
    
    //handle recursion
    public static boolean isRecursion = false;
    
    public static void PrefixFirstNameWithAsterisk(List<Contact> contactSoLst) {
     
        // get the record type ID of the 'CA Contact' records
        Id contactCARecordTypeId;
        if(Schema.SObjectType.Contact.getRecordTypeInfosByName().get('CA Contact') != null) {
            contactCARecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('CA Contact').getRecordTypeId();
        }
         
        //loop over all the contact which were inserted
        for(Contact contactSo : contactSoLst){  
            isRecursion = true; 
            if(contactSO.RecordTypeId == contactCARecordTypeId && contactSo.Type__c != null && 
              (contactSo.Type__c.equals('Obsolete') || contactSo.Type__c.equals('Other'))){
                  if (contactSo.FirstName == null) {
                     contactSo.FirstName = '**';
                  }
                  else if (!contactSo.FirstName.contains('**')) {
                     contactSo.FirstName = '**' + contactSo.FirstName;
                  }                 
                // contactSo.FirstName = (contactSo.FirstName != null && contactSo.FirstName.contains('**')) ? contactSo.FirstName : ('**' + contactSo.FirstName);
            } else if(contactSo.FirstName != null && contactSo.FirstName.contains('**')) {
                contactSo.FirstName = contactSo.FirstName.replace('**','');
            }            
        }      
    }
    
    public static void SetAccountIdForAuditorContacts(List<Contact> contactSoLst) {
     
        // get the record type ID of the 'Auditors' records
        Id accountRecordTypeId;
        if(Schema.SObjectType.Account.getRecordTypeInfosByName().get('Auditors') != null) {
            accountRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Auditors').getRecordTypeId();
        }
        
        // fetch 'Auditors' record from Account object        
        List<Account> lstaccountSo = new List<Account>([SELECT Id, Name FROM Account WHERE RecordTypeId = :accountRecordTypeId LIMIT 1]);        
        
        // get the record type ID of the 'Auditor Contact' records
        Id contactCARecordTypeId;
        if(Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Auditor Contact') != null) {
            contactCARecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Auditor Contact').getRecordTypeId();
        }
         
        // set Account id for all Auditor Contact records
        for(Contact contactSo : contactSoLst){ 
           if(contactSO.RecordTypeId == contactCARecordTypeId && lstaccountSo.size() > 0) { 
              contactSo.AccountId = lstaccountSo[0].id;
           }
           
        }
     
     }
}
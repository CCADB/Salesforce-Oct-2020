/**

Test Case for the ContactTrigger apex trigger and ContactTrigger helper apex class

**/

@isTest 
public class ContactTriggerTest{
    
    static testMethod void validateContact() {
    
        // create 'CA Owner' Account record
        Account caowner = New Account();
        caowner.recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('CA Owner').getRecordTypeId(); 
        caowner.name = 'Test Account';        
        insert caowner;
            
        // create 'CA Contact' of type 'POC'
        Contact caContact = new Contact (FirstName = 'Test FName', LastName = 'Test LName', Email = 'testclass@gmail.com', AccountId = caowner.id, Type__c = 'Other');
        caContact.recordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('CA Contact').getRecordTypeId();
        insert caContact;
        
        ContactTriggerHelper.isRecursion = false;
        List<Contact> lstContacts = new List<Contact>([select Id, FirstName, LastName, Email, Type__c from Contact Where Id =: caContact.Id]);
        lstContacts[0].Type__c = 'POC';
        update lstContacts[0];
               
        // create 'Auditors' Account record
        Account auditorAccount = New Account();
        auditorAccount.recordTypeId= Schema.SObjectType.Account.getRecordTypeInfosByName().get('Auditors').getRecordTypeId(); 
        auditorAccount.name = 'Auditors';        
        insert auditorAccount;
        
        // create 'Auditor Contact' of type 'Auditor'
        Contact auditorContact = new Contact (FirstName = 'Test FName', LastName = 'Test LName', Email = 'testclass@gmail.com', AccountId = auditorAccount.id);
        auditorContact.recordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Auditor Contact').getRecordTypeId();
        insert auditorContact;
            
    }
}
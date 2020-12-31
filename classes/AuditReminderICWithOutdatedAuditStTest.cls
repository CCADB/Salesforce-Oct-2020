/**

Test Case for the following Controller Extension:
AuditReminderICWithOutdatedAuditSt Batch Program

**/

@isTest 
public class AuditReminderICWithOutdatedAuditStTest {

    static testMethod void validateTest() {
        // create the parent account  - record type = Owner
        Account parentAccount = TestUtils.getCAOwner();
        parentAccount.status__c = 'Included';
        parentAccount.CA_Email_Alias_1__c = Userinfo.getUserEmail();
        parentAccount.CA_Email_Alias_2__c = 'test@gmail.com';
        insert parentAccount;
        
        // create the contact associated with the parent account
        Contact parentContact = TestUtils.getContact(parentAccount.id);
        parentContact.recordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('CA Contact').getRecordTypeId();
        parentContact.Email = 'test1@gmail.com';
        parentContact.Type__c = 'POC';
        insert parentContact;
        
        //create the Root Certificates
        Account rootAccount = TestUtils.getRootCertificate(parentAccount.id);
        rootAccount.SHA_1_Fingerprint__c= '12345678901234567890123456789012345600000';
        rootAccount.Trust_Bits__c = 'Email';
        rootAccount.Status__c = 'Included';
        insert rootAccount;
        
        //create the intermediate certs
        Account intercertAccount = TestUtils.getIntermediateCertificate(rootAccount.id);
        intercertAccount.SHA_1_Fingerprint__c= '12345678901234567890123456789012345600000';
        intercertAccount.Trust_Bits__c = 'Email';
        intercertAccount.Root_Cert_ID__c = rootAccount.id;
        intercertAccount.Status__c = 'Included';
        intercertAccount.Valid_From_GMT__c = Date.Today()+1;
        intercertAccount.Valid_To_GMT__c = Date.Today()+1;  // not expired
        intercertAccount.Standard_Audit__c = 'https://stdaudit.com';
        intercertAccount.Standard_Audit_Type__c = 'WebTrust';
        intercertAccount.Standard_Audit_Statement_Date__c = Date.Today() - 460; // older than one year + 3 months - audits due
        intercertAccount.Standard_Audit_Period_Start_Date__c = Date.Today() - 460;
        intercertAccount.Standard_Audit_Period_End_Date__c = Date.Today() - 460;
        intercertAccount.Certificate_Issuer_Organization__c = 'Test IO';
        intercertAccount.Certificate_Issuer_Organizational_Unit__c = 'Test IOU';
        intercertAccount.Approval_Bug__c = 'Test';
        intercertAccount.NSS_Release_When_First_Included__c = 'Test';
        intercertAccount.Firefox_Release_When_First_Included__c = 'Test';
        intercertAccount.Mozilla_Applied_Constraints__c = 'Test';
        intercertAccount.Certificate_Policy_CP__c = 'Test';
        intercertAccount.Certification_Practice_Statement_CPS__c = 'Test';
        intercertAccount.X_509_Certificate_PEM__c = 'Test';
        intercertAccount.Mozilla_Audit_Alert__c = 'Test';
        insert intercertAccount;
        
        AuditReminderICWithOutdatedAuditStBatch b1 = new AuditReminderICWithOutdatedAuditStBatch(true);
        ID batchprocessid = Database.executeBatch(b1,10);
        
        AuditReminderICWithOutdatedAuditStSchd.scheduleMe('Mozilla: Run Audit Reminder For Out Dated Inter Certs Batch on 1st Sunday of Every Month'); 
        AuditReminderICOutdatedUpdateAlertSchdlr.scheduleMe('Mozilla: Run Audit Reminder For Out Dated Inter Certs Batch on Every Day 5 AM'); 
        
        AuditReminderICWithOutdatedAuditStCtrl objctrl = new AuditReminderICWithOutdatedAuditStCtrl();
        objctrl.startBatch();  
        objctrl.startBatchToUpdateAuditAlert();  
    }

}
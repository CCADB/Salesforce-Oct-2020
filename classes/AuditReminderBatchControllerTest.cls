/**************************************************************************************

Test Case for the following Controller Extensions:

** AuditReminderBatchHelper - Executes the logic for sending the reminder emails to 
   the CA Owners based on Standard/BR/EV audit dates.
** AuditReminderBatchController - controller class for the RunAuditReminderBatch VF page
   which displays status of batch jobs.
** AuditReminderBatch - implements Database.Batchable for each record selected for 
   processing.

**/

@isTest 

public class AuditReminderBatchControllerTest {
    
    static testMethod void myTestForAuditReminder() {
      
        // create the parent account  - record type = Owner
        Account parentAccount = TestUtils.getCAOwner();
        parentAccount.status__c = 'Included';
        insert parentAccount;
        
        // create the contact associated with the parent account
        Contact parentContact = TestUtils.getContact(parentAccount.id);
        parentContact.recordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('CA Contact').getRecordTypeId();
        insert parentContact;
        
        // create the child accounts - record type = Root
        Account childAccount1 = TestUtils.getRootCertificate(parentAccount.id);
        childAccount1.SHA_1_Fingerprint__c= '12345678901234567890123456789012345600000';
        childAccount1.Trust_Bits__c = 'Email';
        childAccount1.Standard_Audit__c = 'http://www.google.com/StandardAudit.pdf';
        childAccount1.Standard_Audit_Statement_Date__c = date.today()-396; // courtesy reminder for 1yr + 30 to 120 days old
        childAccount1.Standard_Audit_Period_End_Date__c = date.today()-396;
        childAccount1.Standard_Audit_Period_Start_Date__c = date.today()-396;
        childAccount1.Standard_Audit_Type__c = 'WebTrust';
        childAccount1.BR_Audit__c = 'http://www.google.com/BRAudit.pdf';
        childAccount1.BR_Audit_Statement_Date__c = date.today();
        childAccount1.BR_Audit_Period_End_Date__c = date.today();
        childAccount1.BR_Audit_Period_Start_Date__c = date.today();
        childAccount1.BR_Audit_Type__c = 'WebTrust';
        childAccount1.EV_Audit__c = 'http://www.google.com/EVAudit.pdf';
        childAccount1.EV_Audit_Statement_Date__c = date.today();
        childAccount1.EV_Audit_Period_End_Date__c= date.today();
        childAccount1.EV_Audit_Period_Start_Date__c = date.today();
        childAccount1.EV_Audit_Type__c = 'WebTrust';
        childAccount1.ev_policy_oid_s__c = '';
        childAccount1.status__c = 'Included';
        insert childAccount1;
        
        Account childAccount2 = TestUtils.getRootCertificate(parentAccount.id);
        childAccount2.SHA_1_Fingerprint__c= '1234000890123456789012345678901234567890';
        childAccount2.Trust_Bits__c = 'Email;Websites';
        childAccount2.Standard_Audit__c = 'http://www.google.com/StandardAudit.pdf';
        childAccount2.Standard_Audit_Statement_Date__c = date.today();
        childAccount2.Standard_Audit_Period_End_Date__c = date.today();
        childAccount2.Standard_Audit_Period_Start_Date__c = date.today();
        childAccount2.Standard_Audit_Type__c = 'WebTrust';
        childAccount2.BR_Audit__c = 'http://www.google.com/BRAudit.pdf';
        childAccount2.BR_Audit_Statement_Date__c = date.today()-490; // overdue reminder for 1yr + 120 to 240 days old
        childAccount2.BR_Audit_Period_End_Date__c = date.today()-490;
        childAccount2.BR_Audit_Period_Start_Date__c = date.today()-490;
        childAccount2.BR_Audit_Type__c = 'WebTrust';
        childAccount2.EV_Audit__c = 'http://www.google.com/EVAudit.pdf';
        childAccount2.EV_Audit_Statement_Date__c = date.today();
        childAccount2.EV_Audit_Type__c = 'WebTrust';
        childAccount2.EV_Audit_Period_End_Date__c= date.today();
        childAccount2.EV_Audit_Period_Start_Date__c = date.today();
        childAccount2.ev_policy_oid_s__c = '';
        childAccount2.status__c = 'Included';
        insert childAccount2;
        
        Account childAccount3 = TestUtils.getRootCertificate(parentAccount.id);
        childAccount3.SHA_1_Fingerprint__c= '123456789789456789012345678901234567890';
        childAccount3.Trust_Bits__c = 'Email;Websites';
        childAccount3.Standard_Audit__c = 'http://www.google.com/StandardAudit.pdf';
        childAccount3.Standard_Audit_Statement_Date__c = date.today();
        childAccount3.Standard_Audit_Type__c = 'WebTrust';
        childAccount3.Standard_Audit_Period_End_Date__c = date.today();
        childAccount3.Standard_Audit_Period_Start_Date__c = date.today();
        childAccount3.BR_Audit__c = 'http://www.google.com/BRAudit.pdf';
        childAccount3.BR_Audit_Statement_Date__c = date.today();
        childAccount3.BR_Audit_Type__c = 'WebTrust';
        childAccount3.BR_Audit_Period_End_Date__c = date.today();
        childAccount3.BR_Audit_Period_Start_Date__c = date.today();
        childAccount3.EV_Audit__c = 'http://www.google.com/EVAudit.pdf';
        childAccount3.EV_Audit_Statement_Date__c = date.today()-610; // Danger of Removal reminder for 1yr + 240+ days old
        childAccount3.EV_Audit_Period_End_Date__c= date.today()-610;
        childAccount3.EV_Audit_Period_Start_Date__c = date.today()-610;
        childAccount3.EV_Audit_Type__c = 'Webtrust';
        childAccount3.ev_policy_oid_s__c = 'Some data';
        childAccount3.status__c = 'Included';
        insert childAccount3;
        
        // create a CA Program user
        User CAUser = getUser();
        
        // system.debug('accountLst='+accountLst);
        
        // *************************** START PROCESS ***********************************      
        
        // Start the test
        Test.startTest();
        
            AuditReminderBatchController batchController = new AuditReminderBatchController();
            batchController.startBatch(); 
            batchController.startBatchToUpdateAuditAlert();       
            batchJobs batchJobsController = new BatchJObs();
            batchJobsController.getBatchJobs();
            AuditReminderBatchSchedulerClass.scheduleMe('Audit Reminder Batch ' + System.now());
            AuditReminderBatchUpdateAlertFieldSchdlr.scheduleMe('Audit Reminder Batch Audit Alert ' + System.now());
            
        // ***************************** END PROCESS ***********************************
        
        // End the test
        Test.stopTest();
        
        //audit reminder summary only
        AuditReminderSummaryOnlyController controller = new AuditReminderSummaryOnlyController();
        controller.startBatch(); 
        controller.startBatchToUpdateAuditAlert();
    }
   
    public static User getUser()
    {
        Profile CAProfile = [SELECT Id FROM Profile WHERE Name='Standard User - Mozilla']; 
        
        User CAUser = new User(Alias = 'CAUser', 
                               Email='CAUser@mozilla.com', 
                               UserName='CAUser@mozilla.com',
                               CA_Program_Manager__c = True,
                               ProfileId = CAProfile.Id
                              );       
        return CAUser;
    }
 
}
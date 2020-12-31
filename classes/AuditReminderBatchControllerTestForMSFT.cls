/**************************************************************************************

Test Case for the following Controller Extensions:

** AuditReminderBatchHelperForMSFT - Executes the logic for sending the reminder emails to 
   the CA Owners based on Standard/BR/EV audit dates.
** AuditReminderBatchControllerForMSFT - controller class for the RunAuditReminderBatchForMSFT VF page
   which displays status of batch jobs.
** AuditReminderBatchForMSFT - implements Database.Batchable for each record selected for 
   processing.

**/

@isTest 

public class AuditReminderBatchControllerTestForMSFT {
    
    static testMethod void myTestForAuditReminder() {
        
        // create the parent account  - record type = Owner
        Account parentAccount = TestUtils.getCAOwner();
        parentAccount.microsoft_status__c = 'Included';
        insert parentAccount;
        
        // create the contact associated with the parent account
        Contact parentContact = TestUtils.getContact(parentAccount.id);
        parentContact.recordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('CA Contact').getRecordTypeId();
        insert parentContact;
        
        // create the child accounts - record type = Root
        Account childAccount = TestUtils.getRootCertificate(parentAccount.id);
        childAccount.microsoft_status__c = 'Included';
        childAccount.Microsoft_EV_Enabled__c = true;
        childAccount.Microsoft_Trust_Bits__c = 'Server Authentication;Code Signing';
        childAccount.Standard_Audit__c = 'http://';  // missing info
        childAccount.Standard_Audit_Statement_Date__c = date.today()-396; // past date
        childAccount.Standard_Audit_Period_Start_Date__c = date.today()-396;
        childAccount.Standard_Audit_Period_End_Date__c = date.today()-396;
        childAccount.Standard_Audit_Type__c = 'WebTrust';
        childAccount.ev_policy_oid_s__c = '';
        
        
        Account childAccount1 = TestUtils.getRootCertificate(parentAccount.id);
        childAccount1.microsoft_status__c = 'Included';
        childAccount1.Microsoft_EV_Enabled__c = true;
        childAccount1.Microsoft_Trust_Bits__c = 'Server Authentication;Code Signing';
        childAccount1.Standard_Audit__c = 'http://';  // missing info
        childAccount1.Standard_Audit_Statement_Date__c = date.today()-500; // past date
        childAccount1.Standard_Audit_Period_Start_Date__c = date.today()-500;
        childAccount1.Standard_Audit_Period_End_Date__c = date.today()-500;
        childAccount1.Standard_Audit_Type__c = 'WebTrust';
        childAccount1.ev_policy_oid_s__c = '';
        
        Account childAccount2 = TestUtils.getRootCertificate(parentAccount.id);
        childAccount2.microsoft_status__c = 'Included';
        childAccount2.Microsoft_EV_Enabled__c = true;
        childAccount2.Microsoft_Trust_Bits__c = 'Server Authentication;Code Signing';
        childAccount2.Standard_Audit__c = 'http://standardaudit.com'; 
        childAccount2.Standard_Audit_Statement_Date__c = date.today();
        childAccount2.Standard_Audit_Period_Start_Date__c = date.today();
        childAccount2.Standard_Audit_Period_End_Date__c = date.today();
        childAccount2.Standard_Audit_Type__c = 'WebTrust';
        childAccount2.EV_Audit__c = 'http://evaudit.com';  // missing info
        childAccount2.EV_Audit_Statement_Date__c = date.today()-500; // past date
        childAccount2.EV_Audit_Period_Start_Date__c = date.today()-500;
        childAccount2.EV_Audit_Period_End_Date__c = date.today()-500;
        childAccount2.EV_Audit_Type__c = 'WebTrust';
        childAccount2.BR_Audit__c = 'http://';  // missing info
        childAccount2.BR_Audit_Statement_Date__c = date.today()-400; // past date
        childAccount2.BR_Audit_Period_Start_Date__c = date.today()-400;
        childAccount2.BR_Audit_Period_End_Date__c = date.today()-400;
        childAccount2.BR_Audit_Type__c = 'WebTrust';
        childAccount2.ev_policy_oid_s__c = '';
        
        insert new List<Account>{childAccount, childAccount1, childAccount2};
        
        // create a CA Program user
        User CAUser = getUser();
        
        // system.debug('accountLst='+accountLst);
        
        // *************************** START PROCESS ***********************************      
        
        // Start the test
        Test.startTest();
        
        AuditReminderBatchControllerForMSFT batchController = new AuditReminderBatchControllerForMSFT();
        batchController.startBatch();        
        batchJobs batchJobsController = new BatchJObs();
        batchJobsController.getBatchJobs();
        AuditReminderBatchSchedulerClassForMSFT.scheduleMe('Audit Reminder Batch For MSFT ' + System.now());
        batchController.startSummaryBatch();
        // ***************************** END PROCESS ***********************************
        
        // End the test
        Test.stopTest();
    }
    
    public static User getUser(){
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
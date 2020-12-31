@isTest
public class SyncAuditUpdateOnRootFromCaseCntrlTest{
    
    static testmethod void testSyncUpdateRoot1(){
        
        // create the parent account  - record type = Owner
        Account parentAccount = TestUtils.getCAOwner();
        parentAccount.Recognized_CAA_Domains__c = 'Test 1';
        parentAccount.Problem_Reporting_Mechanism__c = 'Test 2';
        insert parentAccount;
        
        // create the contact associated with the parent account
        Contact parentContact = TestUtils.getContact(parentAccount.id);
        insert parentContact;
        
        // create the child account - record type = Root
        Account childAccount = TestUtils.getRootCertificate(parentAccount.id);
        childAccount.Name = 'child root account 1';
        insert childAccount;
        
        Account childAccount1 = TestUtils.getRootCertificate(parentAccount.id);
        childAccount1.Name = 'child root account 2';
        insert childAccount1;
        
        Account childAccount2 = TestUtils.getRootCertificate(parentAccount.id);
        childAccount2.Name = 'child root account 3';
        insert childAccount2;
        
        // create auditor
        Auditor__c auditor = TestUtils.getAuditor();
        insert auditor;
        
        // create auditor location
        Auditor_Location__c auditorlocation = TestUtils.getAuditorLocation(auditor.Id);
        insert auditorlocation;
        
        // create a case
        Case accountCaseA = TestUtils.getCase(parentAccount.id);
        accountCaseA.request_status__c  = 'Initial Request Received'; 
        accountCaseA.Recognized_CAA_Domains__c = 'Test 3';
        accountCaseA.Problem_Reporting_Mechanism__c = 'Test 4'; 
        accountCaseA.Auditor_New__c = auditor.Id;
        accountCaseA.Auditor_Location_New__c = auditorlocation.Id;      
        accountCaseA.Standard_Audit_Statement_Link__c = 'https://www.cpacanada.ca/generichandlers/aptifyattachmenthandler.ashx?attachmentid=221273';
        accountCaseA.Code_Signing_Audit_Statement_Link__c = 'https://www.cpacanada.ca/generichandlers/aptifyattachmenthandler.ashx?attachmentid=221273';
        accountCaseA.BR_Audit_Statement_Link__c = 'https://www.cpacanada.ca/generichandlers/aptifyattachmenthandler.ashx?attachmentid=221273';
        accountCaseA.EV_Audit_Statement_Link__c = 'https://www.cpacanada.ca/generichandlers/aptifyattachmenthandler.ashx?attachmentid=221273';
        accountCaseA.EV_Code_Signing_Audit_Statement_Link__c = 'https://www.cpacanada.ca/generichandlers/aptifyattachmenthandler.ashx?attachmentid=221273';
        insert accountCaseA;
        
        accountCaseA.Request_Status__c = 'Data Verified';
        update accountCaseA;
        
        Test.startTest();
        
        // create the root case and associate it with the case
        Root_Case__c rootCaseA1 = TestUtils.getRootCase(accountCaseA.id,parentAccount.Id);
        rootCaseA1.request_status__c   = 'Initial Request Received';         
        rootCaseA1.Apply_Standard_Audit__c = true;
        rootCaseA1.Apply_Code_Signing_Audit__c = true;
        rootCaseA1.Apply_BR_Audit__c = true;
        rootCaseA1.Apply_EV_Audit__c = true;
        rootCaseA1.Apply_EV_Code_Signing_Audit__c = true;        
        rootCaseA1.Case_No__c = accountCaseA.Id;
        rootCaseA1.CA_Owner_Name_Existing__c = parentAccount.Id;
        rootCaseA1.Root_Certificate_Name_Existing__c = childAccount.Id;
        //insert rootCaseA1;
        
        Root_Case__c rootCaseA2 = TestUtils.getRootCase(accountCaseA.id,parentAccount.Id);
        rootCaseA2.request_status__c = 'Initial Request Received';         
        rootCaseA2.Apply_Standard_Audit__c = true;
        rootCaseA2.Apply_Code_Signing_Audit__c = true;
        rootCaseA2.Apply_BR_Audit__c = true;
        rootCaseA2.Apply_EV_Audit__c = true;
        rootCaseA2.Apply_EV_Code_Signing_Audit__c = true;
        rootCaseA2.Case_No__c = accountCaseA.Id;
        rootCaseA2.CA_Owner_Name_Existing__c = parentAccount.Id;
        rootCaseA2.Root_Certificate_Name_Existing__c = childAccount1.Id;
        //insert rootCaseA2;
        
        Root_Case__c rootCaseA3 = TestUtils.getRootCase(accountCaseA.id,parentAccount.Id);
        rootCaseA3.Request_Status__c =  'Initial Request Received';   
        rootCaseA3.Apply_Standard_Audit__c = true;
        rootCaseA3.Apply_Code_Signing_Audit__c = true;
        rootCaseA3.Apply_BR_Audit__c = true;
        rootCaseA3.Apply_EV_Audit__c = true;
        rootCaseA3.Apply_EV_Code_Signing_Audit__c = true;
        rootCaseA3.CA_Owner_Name_Existing__c = parentAccount.Id;
        rootCaseA3.Root_Certificate_Name_Existing__c = childAccount2.Id;
        rootCaseA3.Case_No__c = accountCaseA.Id;
        insert new List<Root_Case__c>{rootCaseA1,rootCaseA2,rootCaseA3};
        rootCaseA1.Request_Status__c = 'Data Verified';
        rootCaseA2.Request_Status__c = 'Data Verified';
        rootCaseA3.Request_Status__c = 'Data Verified';
        update new List<Root_Case__c>{rootCaseA1,rootCaseA2,rootCaseA3};
         
        System.debug(rootCaseA1);
        List<Root_Case__c> lstRootCases =  [SELECT Name, case_no__c, case_no__r.accountid, case_no__r.Account.Name,
                              CA_Owner_Name_Existing__r.Name, Root_Certificate_Name_Existing__r.Name,
                              SHA_1__c,
                              Test_Website_Valid__c, Test_Website_Expired__c, Test_Website_Revoked__c, Request_Status__c,
                              Apply_Standard_Audit__c, Apply_BR_Audit__c, Apply_EV_Audit__c,Apply_Code_Signing_Audit__c ,
                              Root_Certificate_Name_Existing__c,Apply_EV_Code_Signing_Audit__c 
                              FROM Root_Case__c WHERE Case_No__c = :accountCaseA.Id AND Request_Status__c = 'Data Verified'
                              ORDER BY NAME];
                              system.debug('lstRootCases: '+lstRootCases.size());
        
        
            PageReference pref = Page.SyncAuditUpdateOnRootFromCase;
            Test.setCurrentPage(pref);
            ApexPages.CurrentPage().getParameters().put('id', accountCaseA.Id); 
            
            SyncAuditUpdateOnRootFromCaseController obj = new SyncAuditUpdateOnRootFromCaseController(new ApexPages.StandardController(accountCaseA));
            obj.SyncCAOwner();
            obj.syncAccount();
            obj.next();
            obj.cancelSyncAccount();
            obj.cancelSyncCAOwner();
            obj.goBack();
        
        Test.stopTest();
    }

}
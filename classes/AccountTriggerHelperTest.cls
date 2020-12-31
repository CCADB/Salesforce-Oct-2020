/**

Test Case for the AccountTrigger apex trigger and AccountTriggerHelper apex class

**/

@isTest 
public class AccountTriggerHelperTest{
    
    static testMethod void validateAccount() {
    
        Account acc = TestUtils.getCAOwner();
        insert acc;
            
        Contact con = TestUtils.getContact(acc.id);
        con.recordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('CA Contact').getRecordTypeId();
        insert con;
        
        //UserRole urole = [Select PortalType, PortalAccountId From UserRole where PortalType = 'CustomerPortal' and PortalAccountId != null limit 1];
        
        User user = new User();
        //user.UserRoleId = urole.Id;//UserInfo.getUserRoleId();//
        //user.ProfileID = [Select Id From Profile Where UserType = 'PowerCustomerSuccess' LIMIT 1].id;
        user.ProfileId = [SELECT Id FROM Profile WHERE Name = 'Customer Community Plus Login User - CAs' AND UserType = 'PowerCustomerSuccess' LIMIT 1].Id;
        user.EmailEncodingKey = 'ISO-8859-1';
        user.LanguageLocaleKey = 'en_US';
        user.TimeZoneSidKey = 'America/New_York';
        user.LocaleSidKey = 'en_US';
        user.FirstName = 'first';
        user.LastName = 'last';
        user.Username = 'test@test1234098.com';   
        user.CommunityNickname = 'testUser09887123';
        user.Alias = 't1';
        user.Email = 'no@email.com';
        user.IsActive = true;
        user.ContactId = con.Id;
        //user.PortalRole = 'Manager';
        insert user;
        
        AccountShare aShare = new AccountShare();
        aShare.AccountAccessLevel = 'Edit';
        aShare.ContactAccessLevel = 'Edit';
        aShare.OpportunityAccessLevel = 'Edit';
        aShare.RowCause = 'Manual';
        aShare.AccountId = acc.Id;
        aShare.UserOrGroupId = user.Id;
        insert aShare;
        
        System.RunAs(user) {
        
            // create a ROOT CA
            Account rootCA = TestUtils.getRootCertificate(acc.Id); 
            rootCa.X_509_Certificate_PEM__c = 'abc';
            rootCa.Status__c = 'Included';
            rootCa.Trust_Bits__c = 'Websites';
            rootCa.Subject_SPKI_SHA256__c = 'C90FBC2664485F6D3175055A45EF10D2EB6E6C7E027DF1A1D526458C42F4269X';
            insert rootCa;
            
            Test.startTest(); 
            
            // create intermediate CA
            Account testAccount = TestUtils.getIntermediateCertificate(rootCa.Id);
            testAccount.X_509_Certificate_PEM__c = 'abc';
            testAccount.Subject_SPKI_SHA256__c = 'C90FBC2664485F6D3175055A45EF10D2EB6E6C7E027DF1A1D526458C42F4269Y';
            testAccount.Extended_Key_Usage__c = 'ExtKeyUsageEmailProtection,ExtKeyUsageClientAuth';
            insert testAccount;
            testAccount.Revocation_Status__c = 'Not Revoked';
            testAccount.Extended_Key_Usage__c = '1.2.3.4, 2.3.4.5, 3.4.5.6';
            update testAccount;
            
            // create a ROOT CA
            Account rootCA1 = TestUtils.getRootCertificate(acc.Id); 
            rootCa1.X_509_Certificate_PEM__c = 'abc';
            rootCa1.Status__c = 'Included';
            rootCa1.Microsoft_Status__c = 'Included';
            rootCa1.Microsoft_Trust_Bits__c = 'Client Authentication;Code Signing';
            rootCa1.Subject_SPKI_SHA256__c = 'C90FBC2664485F6D3175055A45EF10D2EB6E6C7E027DF1A1D526458C42F4269Z';
            insert rootCa1;
            
            testAccount.X_509_Certificate_PEM__c = 'test';
            testAccount.parentId = rootCa1.id;
            testAccount.Extended_Key_Usage__c = '';
            update testAccount;
            
            acc.Name = 'SymantecAccount';
            update acc;
            
            Test.stopTest();
        }
        
        Account accountSo = New Account(name='SymantecAccount');
        insert accountSo;
        
        accountSo.Name = 'NameChanged';
        update accountSo;
    }
    
    static testMethod void TestInternalUserSharing() {
    
        Account acc = TestUtils.getCAOwner();
        insert acc;
            
        Contact con = TestUtils.getContact(acc.id);
        con.Type__c = 'Primary POC';
        con.Is_Community_User__c = true;
        con.recordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('CA Contact').getRecordTypeId();
        insert con;
        
        User user = new User();
        user.ProfileId = [SELECT Id FROM Profile WHERE Name = 'Customer Community Plus Login User - CAs' AND UserType = 'PowerCustomerSuccess' LIMIT 1].Id;
        user.EmailEncodingKey = 'ISO-8859-1';
        user.LanguageLocaleKey = 'en_US';
        user.TimeZoneSidKey = 'America/New_York';
        user.LocaleSidKey = 'en_US';
        user.FirstName = 'first';
        user.LastName = 'last';
        user.Username = 'test@test1234098.com';   
        user.CommunityNickname = 'testUser09887123';
        user.Alias = 't1';
        user.Email = 'no@email.com';
        user.IsActive = true;
        user.ContactId = con.Id;
        insert user;
        
        // create a ROOT CA
        Account rootCA = TestUtils.getRootCertificate(acc.Id); 
        rootCa.X_509_Certificate_PEM__c = 'abc';
        insert rootCa;
        
        Test.startTest();
        
        rootCa.Name = 'Root 2';
        update rootCa;
        
        // create intermediate CA
        Account testAccount = TestUtils.getIntermediateCertificate(rootCa.Id);
        testAccount.CA_Owner_Id__c = acc.Id;
        testAccount.Audits_Same_as_Parent__c = true;
        insert testAccount;
        
        rootCa.Standard_Audit__c = 'http://google.com';
        rootCa.Standard_Audit_Type__c = 'WebTrust';
        rootCa.Standard_Audit_Statement_Date__c = system.today();
        rootCa.Standard_Audit_Period_Start_Date__c = system.today().addDays(-3);
        rootCa.Standard_Audit_Period_End_Date__c = system.today().addDays(-2);
        update rootCa;
        
        Test.stopTest();
    }
    
    static testMethod void TestValidateAuditInfo() {
        
        Account acc = TestUtils.getCAOwner();
        insert acc;
        
        CPACanada_File__c objCPACanada = new CPACanada_File__c();
        objCPACanada.Name = '10149';
        objCPACanada.Report_Id__c = '225352';
        objCPACanada.Report_URL__c = 'https://www.cpacanada.ca/generichandlers/aptifyattachmenthandler.ashx?attachmentid=225352';
        objCPACanada.Seal_URL__c = 'https://www.cpacanada.ca/webtrustseal?sealid=10149';
        insert objCPACanada;
            
        // create a ROOT CA
        Account rootCA = TestUtils.getRootCertificate(acc.Id);
        rootCa.X_509_Certificate_PEM__c = 'abc';
        rootCa.CA_Owner_ID__c = acc.Id;
        rootCa.Policy_Identifiers__c = 'Test';
        insert rootCa;
        
        // create intermediate CA
        Account testAccount = TestUtils.getIntermediateCertificate(rootCa.Id);
        testAccount.Status__c = 'Removed';
        testAccount.X_509_Certificate_PEM__c = 'abc';
        testAccount.CA_Owner_Id__c = acc.Id;
        testAccount.Policy_Identifiers__c = 'Test1';
        insert testAccount;
        
        try {
            
            testaccount.Standard_Audit__c = '';
            testaccount.Code_Signing_Audit__c = '';
            testaccount.BR_Audit__c = '';
            testaccount.EV_Audit__c = '';
            testaccount.EV_Code_Signing_Audit__c = '';
            testaccount.Standard_Audit__c = 'http://google.com';
            testaccount.Code_Signing_Audit__c = 'http://google.com';
            testaccount.Standard_Audit_Statement_Date__c = system.today();
            testaccount.Code_Signing_Audit_Statement_Date__c = system.today().addDays(2);
            testAccount.Policy_Identifiers__c = 'Test2';
            update testAccount;
        } catch (Exception ex){}
        
        try {
            testaccount.Standard_Audit__c = '';
            testaccount.Code_Signing_Audit__c = '';
            testaccount.BR_Audit__c = '';
            testaccount.EV_Audit__c = '';
            testaccount.EV_Code_Signing_Audit__c = '';
            testaccount.Standard_Audit__c = 'https://www.cpacanada.ca/webtrustseal?sealid=10149';
            testaccount.Code_Signing_Audit__c = 'http://google.com';
            testaccount.Standard_Audit_Statement_Date__c = system.today();
            testaccount.Code_Signing_Audit_Statement_Date__c = system.today();
            testaccount.Standard_Audit_Period_Start_Date__c = system.today();
            testaccount.Code_Signing_Audit_Period_Start_Date__c = system.today().addDays(2);
            update testAccount;
        } catch (Exception ex){}
        
        try {
            testaccount.Standard_Audit__c = '';
            testaccount.Code_Signing_Audit__c = '';
            testaccount.BR_Audit__c = '';
            testaccount.EV_Audit__c = '';
            testaccount.EV_Code_Signing_Audit__c = '';
            testaccount.Standard_Audit__c = 'http://google.com';
            testaccount.Code_Signing_Audit__c = 'https://www.cpacanada.ca/webtrustseal?sealid=10149';
            testaccount.Standard_Audit_Statement_Date__c = system.today();
            testaccount.Code_Signing_Audit_Statement_Date__c = system.today();
            testaccount.Standard_Audit_Period_Start_Date__c = system.today();
            testaccount.Code_Signing_Audit_Period_Start_Date__c = system.today();
            testaccount.Standard_Audit_Period_End_Date__c = system.today();
            testaccount.Code_Signing_Audit_Period_End_Date__c = system.today().addDays(2);
            update testAccount;
        } catch (Exception ex){}
        
        try {
            testaccount.Code_Signing_Audit__c = '';
            testaccount.BR_Audit__c = '';
            testaccount.EV_Audit__c = '';
            testaccount.EV_Code_Signing_Audit__c = '';
            testaccount.BR_Audit__c = 'http://google.com';
            testaccount.Code_Signing_Audit__c = 'http://google.com';
            testaccount.Code_Signing_Audit_Statement_Date__c = system.today();
            testaccount.BR_Audit_Statement_Date__c = system.today().addDays(2);
            update testAccount;
        } catch (Exception ex){}
        
        try {
            testaccount.Code_Signing_Audit__c = '';
            testaccount.BR_Audit__c = '';
            testaccount.EV_Audit__c = '';
            testaccount.EV_Code_Signing_Audit__c = '';
            testaccount.BR_Audit__c = 'https://www.cpacanada.ca/webtrustseal?sealid=10149';
            testaccount.Code_Signing_Audit__c = 'http://google.com';
            testaccount.Code_Signing_Audit_Statement_Date__c = system.today();
            testaccount.BR_Audit_Statement_Date__c = system.today();
            testaccount.Code_Signing_Audit_Period_Start_Date__c = system.today();
            testaccount.BR_Audit_Period_Start_Date__c = system.today().addDays(2);
            update testAccount;
        } catch (Exception ex){}
        
        try {
            testaccount.Code_Signing_Audit__c = '';
            testaccount.BR_Audit__c = '';
            testaccount.EV_Audit__c = '';
            testaccount.EV_Code_Signing_Audit__c = '';
            testaccount.BR_Audit__c = 'http://google.com';
            testaccount.Code_Signing_Audit__c = 'http://google.com';
            testaccount.Code_Signing_Audit_Statement_Date__c = system.today();
            testaccount.BR_Audit_Statement_Date__c = system.today();
            testaccount.Code_Signing_Audit_Period_Start_Date__c = system.today();
            testaccount.BR_Audit_Period_Start_Date__c = system.today();
            testaccount.Code_Signing_Audit_Period_End_Date__c = system.today();
            testaccount.BR_Audit_Period_End_Date__c = system.today();
            update testAccount;
        } catch (Exception ex){}
        
        
        try {
            testaccount.Code_Signing_Audit__c = '';
            testaccount.BR_Audit__c = '';
            testaccount.EV_Audit__c = '';
            testaccount.EV_Code_Signing_Audit__c = '';
            testaccount.EV_Audit__c = 'http://google.com';
            testaccount.Code_Signing_Audit__c = 'http://google.com';
            testaccount.Code_Signing_Audit_Statement_Date__c = system.today();
            testaccount.EV_Audit_Statement_Date__c = system.today().addDays(2);
            update testAccount;
        } catch (Exception ex){}
        
        try {
            testaccount.Code_Signing_Audit__c = '';
            testaccount.BR_Audit__c = '';
            testaccount.EV_Audit__c = '';
            testaccount.EV_Code_Signing_Audit__c = '';
            testaccount.EV_Audit__c = 'https://www.cpacanada.ca/webtrustseal?sealid=10149';
            testaccount.Code_Signing_Audit__c = 'http://google.com';
            testaccount.Code_Signing_Audit_Statement_Date__c = system.today();
            testaccount.EV_Audit_Statement_Date__c = system.today();
            testaccount.Code_Signing_Audit_Period_Start_Date__c = system.today();
            testaccount.EV_Audit_Period_Start_Date__c = system.today().addDays(2);
            update testAccount;
        } catch (Exception ex){}
        
        try {
            testaccount.Code_Signing_Audit__c = '';
            testaccount.BR_Audit__c = '';
            testaccount.EV_Audit__c = '';
            testaccount.EV_Code_Signing_Audit__c = '';
            testaccount.EV_Audit__c = 'http://google.com';
            testaccount.Code_Signing_Audit__c = 'http://google.com';
            testaccount.Code_Signing_Audit_Statement_Date__c = system.today();
            testaccount.EV_Audit_Statement_Date__c = system.today();
            testaccount.Code_Signing_Audit_Period_Start_Date__c = system.today();
            testaccount.EV_Audit_Period_Start_Date__c = system.today();
            testaccount.Code_Signing_Audit_Period_End_Date__c = system.today();
            testaccount.EV_Audit_Period_End_Date__c = system.today();
            update testAccount;
        } catch (Exception ex){}
        
        try {
            testaccount.Code_Signing_Audit__c = '';
            testaccount.BR_Audit__c = '';
            testaccount.EV_Audit__c = '';
            testaccount.EV_Code_Signing_Audit__c = '';
            testaccount.EV_Code_Signing_Audit__c = 'http://google.com';
            testaccount.Code_Signing_Audit__c = 'http://google.com';
            testaccount.Code_Signing_Audit_Statement_Date__c = system.today();
            testaccount.EV_Code_Signing_Audit_Statement_Date__c = system.today().addDays(2);
            update testAccount;
        } catch (Exception ex){}
        
        try {
            testaccount.Code_Signing_Audit__c = '';
            testaccount.BR_Audit__c = '';
            testaccount.EV_Audit__c = '';
            testaccount.EV_Code_Signing_Audit__c = '';
            testaccount.EV_Code_Signing_Audit__c = 'http://google.com';
            testaccount.Code_Signing_Audit__c = 'http://google.com';
            testaccount.Code_Signing_Audit_Statement_Date__c = system.today();
            testaccount.EV_Code_Signing_Audit_Statement_Date__c = system.today();
            testaccount.Code_Signing_Audit_Period_Start_Date__c = system.today();
            testaccount.EV_Code_Signing_Audit_Period_Start_Date__c = system.today().addDays(2);
            update testAccount;
        } catch (Exception ex){}
        
        try {
            testaccount.Code_Signing_Audit__c = '';
            testaccount.BR_Audit__c = '';
            testaccount.EV_Audit__c = '';
            testaccount.EV_Code_Signing_Audit__c = '';
            testaccount.EV_Code_Signing_Audit__c = 'http://google.com';
            testaccount.Code_Signing_Audit__c = 'http://google.com';
            testaccount.Code_Signing_Audit_Statement_Date__c = system.today();
            testaccount.EV_Code_Signing_Audit_Statement_Date__c = system.today();
            testaccount.Code_Signing_Audit_Period_Start_Date__c = system.today();
            testaccount.EV_Code_Signing_Audit_Period_Start_Date__c = system.today();
            testaccount.Code_Signing_Audit_Period_End_Date__c = system.today();
            testaccount.EV_Code_Signing_Audit_Period_End_Date__c = system.today();
            update testAccount;
        } catch (Exception ex){}
        
        
        try {
            testaccount.Standard_Audit__c = '';
            testaccount.Code_Signing_Audit__c = '';
            testaccount.BR_Audit__c = '';
            testaccount.EV_Audit__c = '';
            testaccount.EV_Code_Signing_Audit__c = '';
            testaccount.Standard_Audit__c = 'http://google.com';
            testaccount.BR_Audit__c = 'http://google.com';
            testaccount.Standard_Audit_Statement_Date__c = system.today();
            testaccount.BR_Audit_Statement_Date__c = system.today().addDays(2);
            update testAccount;
        } catch (Exception ex){}
            
        try {
            testaccount.Standard_Audit__c = '';
            testaccount.Code_Signing_Audit__c = '';
            testaccount.BR_Audit__c = '';
            testaccount.EV_Audit__c = '';
            testaccount.EV_Code_Signing_Audit__c = '';
            testaccount.Standard_Audit__c = 'http://google.com';
            testaccount.BR_Audit__c = 'http://google.com';
            testaccount.Standard_Audit_Period_Start_Date__c = system.today();
            testaccount.BR_Audit_Period_Start_Date__c = system.today().addDays(2);
            testaccount.BR_Audit_Statement_Date__c = system.today();
            update testAccount;
        } catch (Exception ex){}
            
        try {
            testaccount.Code_Signing_Audit__c = '';
            testaccount.BR_Audit__c = '';
            testaccount.EV_Audit__c = '';
            testaccount.EV_Code_Signing_Audit__c = '';
            testaccount.Standard_Audit__c = 'http://google.com';
            testaccount.BR_Audit__c = 'http://google.com';
            testaccount.Standard_Audit_Period_End_Date__c = system.today();
            testaccount.BR_Audit_Period_End_Date__c = system.today().addDays(2);
            testaccount.BR_Audit_Period_Start_Date__c = system.today();
            testaccount.BR_Audit_Statement_Date__c = system.today();
            update testAccount;
        } catch (Exception ex){}
            
        try {
            testaccount.Code_Signing_Audit__c = '';
            testaccount.BR_Audit__c = '';
            testaccount.EV_Audit__c = '';
            testaccount.EV_Code_Signing_Audit__c = '';
            testaccount.Standard_Audit__c = 'http://google.com';
            testaccount.EV_Audit__c = 'http://google.com';
            testaccount.Standard_Audit_Statement_Date__c = system.today();
            testaccount.EV_Audit_Statement_Date__c = system.today().addDays(2);
            update testAccount;
        } catch (Exception ex){}
        
        try {
            testaccount.Code_Signing_Audit__c = '';
            testaccount.BR_Audit__c = '';
            testaccount.EV_Audit__c = '';
            testaccount.EV_Code_Signing_Audit__c = '';
            testaccount.Standard_Audit__c = 'http://google.com';
            testaccount.EV_Audit__c = 'http://google.com';
            testaccount.Standard_Audit_Period_Start_Date__c = system.today();
            testaccount.EV_Audit_Period_Start_Date__c = system.today().addDays(2);
            testaccount.EV_Audit_Statement_Date__c = system.today();
            update testAccount;
        } catch (Exception ex){}
            
        try {
            testaccount.Code_Signing_Audit__c = '';
            testaccount.BR_Audit__c = '';
            testaccount.EV_Audit__c = '';
            testaccount.EV_Code_Signing_Audit__c = '';
            testaccount.Standard_Audit__c = 'http://google.com';
            testaccount.EV_Audit__c = 'http://google.com';
            testaccount.Standard_Audit_Period_End_Date__c = system.today();
            testaccount.EV_Audit_Period_End_Date__c = system.today().addDays(2);
            testaccount.EV_Audit_Period_Start_Date__c = system.today();
            testaccount.EV_Audit_Statement_Date__c = system.today();
            update testAccount;
        } catch (Exception ex){}
            
        try {
            testaccount.Code_Signing_Audit__c = '';
            testaccount.BR_Audit__c = '';
            testaccount.EV_Audit__c = '';
            testaccount.EV_Code_Signing_Audit__c = '';
            testaccount.Standard_Audit__c = 'http://google.com';
            testaccount.EV_Code_Signing_Audit__c = 'http://google.com';
            testaccount.Standard_Audit_Statement_Date__c = system.today();
            testaccount.EV_Code_Signing_Audit_Statement_Date__c = system.today().addDays(2);
            update testAccount;
        } catch (Exception ex){}
            
        try {
            testaccount.Code_Signing_Audit__c = '';
            testaccount.BR_Audit__c = '';
            testaccount.EV_Audit__c = '';
            testaccount.EV_Code_Signing_Audit__c = '';
            testaccount.Standard_Audit__c = 'http://google.com';
            testaccount.EV_Code_Signing_Audit__c = 'http://google.com';
            testaccount.Standard_Audit_Period_Start_Date__c = system.today();
            testaccount.EV_Code_Signing_Audit_Period_Start_Date__c = system.today().addDays(2);
            testaccount.EV_Code_Signing_Audit_Statement_Date__c = system.today();
            update testAccount;
        } catch (Exception ex){}
            
        try {
            testaccount.Code_Signing_Audit__c = '';
            testaccount.BR_Audit__c = '';
            testaccount.EV_Audit__c = '';
            testaccount.EV_Code_Signing_Audit__c = '';
            testaccount.Standard_Audit__c = 'http://google.com';
            testaccount.EV_Code_Signing_Audit__c = 'http://google.com';
            testaccount.Standard_Audit_Period_End_Date__c = system.today();
            testaccount.EV_Code_Signing_Audit_Period_End_Date__c = system.today().addDays(2);
            testaccount.EV_Code_Signing_Audit_Period_Start_Date__c = system.today();
            testaccount.EV_Code_Signing_Audit_Statement_Date__c = system.today();
            update testAccount;
        } catch (Exception ex){}
            
        try {
            testaccount.Code_Signing_Audit__c = '';
            testaccount.BR_Audit__c = '';
            testaccount.EV_Audit__c = '';
            testaccount.EV_Code_Signing_Audit__c = '';
            testaccount.BR_Audit__c = 'http://google1.com';
            testaccount.EV_Audit__c = 'http://google1.com';
            testaccount.BR_Audit_Statement_Date__c = system.today();
            testaccount.EV_Audit_Statement_Date__c = system.today().addDays(2);
            update testAccount;
        } catch (Exception ex){}
            
        try {
            testaccount.Code_Signing_Audit__c = '';
            testaccount.BR_Audit__c = '';
            testaccount.EV_Audit__c = '';
            testaccount.EV_Code_Signing_Audit__c = '';
            testaccount.BR_Audit__c = 'http://google1.com';
            testaccount.EV_Audit__c = 'http://google1.com';
            testaccount.BR_Audit_Period_Start_Date__c = system.today();
            testaccount.EV_Audit_Period_Start_Date__c = system.today().addDays(2);
            testaccount.EV_Audit_Statement_Date__c = system.today();
            update testAccount;
        } catch (Exception ex){}
            
        try {
            testaccount.Code_Signing_Audit__c = '';
            testaccount.BR_Audit__c = '';
            testaccount.EV_Audit__c = '';
            testaccount.EV_Code_Signing_Audit__c = '';
            testaccount.BR_Audit__c = 'http://google1.com';
            testaccount.EV_Audit__c = 'http://google1.com';
            testaccount.BR_Audit_Period_End_Date__c = system.today();
            testaccount.EV_Audit_Period_End_Date__c = system.today().addDays(2);
            testaccount.EV_Audit_Period_Start_Date__c = system.today();
            testaccount.EV_Audit_Statement_Date__c = system.today();
            update testAccount;
        } catch (Exception ex){}
            
        try {
            testaccount.Code_Signing_Audit__c = '';
            testaccount.BR_Audit__c = '';
            testaccount.EV_Audit__c = '';
            testaccount.EV_Code_Signing_Audit__c = '';
            testaccount.BR_Audit__c = 'http://google1.com';
            testaccount.EV_Code_Signing_Audit__c = 'http://google1.com';
            testaccount.BR_Audit_Statement_Date__c = system.today();
            testaccount.EV_Code_Signing_Audit_Statement_Date__c = system.today().addDays(2);
            update testAccount;
        } catch (Exception ex){}
            
        try {
            testaccount.Code_Signing_Audit__c = '';
            testaccount.BR_Audit__c = '';
            testaccount.EV_Audit__c = '';
            testaccount.EV_Code_Signing_Audit__c = '';
            testaccount.BR_Audit__c = 'http://google1.com';
            testaccount.EV_Code_Signing_Audit__c = 'http://google1.com';
            testaccount.BR_Audit_Period_Start_Date__c = system.today();
            testaccount.EV_Code_Signing_Audit_Period_Start_Date__c = system.today().addDays(2);
            testaccount.EV_Code_Signing_Audit_Statement_Date__c = system.today();
            update testAccount;
        } catch (Exception ex){}
            
        try {
            testaccount.Code_Signing_Audit__c = '';
            testaccount.BR_Audit__c = '';
            testaccount.EV_Audit__c = '';
            testaccount.EV_Code_Signing_Audit__c = '';
            testaccount.BR_Audit__c = 'http://google1.com';
            testaccount.EV_Code_Signing_Audit__c = 'http://google1.com';
            testaccount.BR_Audit_Period_End_Date__c = system.today();
            testaccount.EV_Code_Signing_Audit_Period_End_Date__c = system.today().addDays(2);
            testaccount.EV_Code_Signing_Audit_Period_Start_Date__c = system.today();
            testaccount.EV_Code_Signing_Audit_Statement_Date__c = system.today();
            update testAccount;
        } catch (Exception ex){}
            
        try {
            testaccount.Code_Signing_Audit__c = '';
            testaccount.BR_Audit__c = '';
            testaccount.EV_Audit__c = '';
            testaccount.EV_Code_Signing_Audit__c = '';
            testaccount.EV_Audit__c = 'http://google1.com';
            testaccount.EV_Code_Signing_Audit__c = 'http://google1.com';
            testaccount.EV_Audit_Statement_Date__c = system.today();
            testaccount.EV_Code_Signing_Audit_Statement_Date__c = system.today().addDays(2);
            update testAccount;
        } catch (Exception ex){}
            
        try {
            testaccount.Code_Signing_Audit__c = '';
            testaccount.BR_Audit__c = '';
            testaccount.EV_Audit__c = '';
            testaccount.EV_Code_Signing_Audit__c = '';
            testaccount.EV_Audit__c = 'http://google1.com';
            testaccount.EV_Code_Signing_Audit__c = 'http://google1.com';
            testaccount.EV_Audit_Period_Start_Date__c = system.today();
            testaccount.EV_Code_Signing_Audit_Period_Start_Date__c = system.today().addDays(2);
            testaccount.EV_Code_Signing_Audit_Statement_Date__c = system.today();
            update testAccount;
        } catch (Exception ex){}
            
        try {
            testaccount.Code_Signing_Audit__c = '';
            testaccount.BR_Audit__c = '';
            testaccount.EV_Audit__c = '';
            testaccount.EV_Code_Signing_Audit__c = '';
            testaccount.EV_Audit__c = 'http://google1.com';
            testaccount.EV_Code_Signing_Audit__c = 'http://google1.com';
            testaccount.EV_Audit_Period_End_Date__c = system.today();
            testaccount.EV_Code_Signing_Audit_Period_End_Date__c = system.today().addDays(2);
            testaccount.EV_Code_Signing_Audit_Period_Start_Date__c = system.today();
            testaccount.EV_Code_Signing_Audit_Statement_Date__c = system.today();
            update testAccount;
        } catch (Exception ex){}
        
        try {
            delete rootCa;
        } catch (Exception ex){}
    }
}
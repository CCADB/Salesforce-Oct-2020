/**

Test Case for the following Controller Extensions:
- CreateRootCertController
- X509CertificateCheckerUtility

**/

@isTest 
public class CreateRootCertControllerTest{

    static testmethod void testRootCert2(){
        
        Account accountSo = TestUtils.getCAOwner();
        insert accountSo;
        
        // create a ROOT CA
        Account rootCA = TestUtils.getRootCertificate(accountSo.Id);
        rootCa.X_509_Certificate_PEM__c = TestUtils.strPEMInfo;
        insert rootCa;
        
        // create a standard controller instance 
        ApexPages.StandardController standardcontroller = new ApexPages.StandardController(rootCA);
        
        CreateRootCertController createrootCertController= new CreateRootCertController(standardController);
        
        PageReference pageRef = Page.CreateRootCert;
        pageRef.getParameters().put('id', String.valueOf(rootCA.Id));
        Test.setCurrentPage(pageRef);
        
        createrootCertController.submit();
        createrootCertController.pemInfoStr = 'testrem';
        createrootCertController.submit();
        createrootCertController.pemInfoStr = TestUtils.strPEMInfo;
        createrootCertController.submit();
        createrootCertController.pemInfoStr = 'BEGIN CERTIFICATEasdasdsadsEND CERTIFICATE';
        createrootCertController.submit();
        createrootCertController.pemInfoStr = 'BEGIN CERTIFICATEasdsadBEGIN CERTIFICATE';
        createrootCertController.submit();    
        
        createrootCertController.parentAccountId = rootCA.id;
        createrootCertController.skip();
        
        Test.startTest();
        
        createrootCertController.CreateRootCert();
        
        Account parentAccount2 = TestUtils.getCAOwner();
        insert parentAccount2;
        
        createrootCertController.parentAccountId = parentAccount2.id; 
        createrootCertController.updateRootCert();
        
        parentAccount2.Extraction_Results__c = 'Test';
        update parentAccount2;
        createrootCertController.parentAccountId = parentAccount2.id; 
        createrootCertController.updateRootCert();
        
        createrootCertController.cancel(); 
        createrootCertController.cloneRootCert();  
        createrootCertController.cloneRootCert(); 
        
        Test.stopTest(); 
    }
    
    static testMethod void testRootCert1() {
    
        Account acc = TestUtils.getCAOwner();
        insert acc;
        
        Contact con = TestUtils.getContact(acc.Id);
        insert con;
        
        UserRole urole = [Select PortalType, PortalAccountId From UserRole where PortalType = 'CustomerPortal' limit 1];
        
        User user = new User();
        //user.UserRoleId = urole.Id;
        //user.ProfileID = [Select Id From Profile Where UserType = 'PowerCustomerSuccess' LIMIT 1].id;
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
        
        user.ProfileID = [SELECT Id FROM Profile WHERE Name = 'Customer Community Plus Login User - CAs' AND UserType = 'PowerCustomerSuccess' LIMIT 1].id;
        user.PortalRole = 'Manager';
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
              
            // do all of my tests
            Account acc1 = TestUtils.getCAOwner();
            insert acc1;
            
            // create a ROOT CA
            Account rootCA = TestUtils.getRootCertificate(acc.Id);
            rootCa.X_509_Certificate_PEM__c = TestUtils.strPEMInfo;
            insert rootCa;
            
            // create Root CA
            Account testAccount = TestUtils.getRootCertificate(acc.Id);
            testAccount.name = 'Hello-';
            testAccount.X_509_Certificate_PEM__c = 'abc';
            insert testAccount;
            
            test.startTest();
            
            ApexPages.StandardController standardcontroller = new ApexPages.StandardController(testAccount);
            
            CreateRootCertController createInterCertController= new CreateRootCertController(standardController);
            
            PageReference pageRef = Page.CreateRootCert;
            pageRef.getParameters().put('id', String.valueOf(testAccount.Id));
            Test.setCurrentPage(pageRef);
            createInterCertController.pemInfoStr  = 'testPEM';
            createInterCertController.submit();
            
            createInterCertController.pemInfoStr = TestUtils.strPEMInfo;
            createInterCertController.submit();
            
            createInterCertController.parentAccountId = testAccount.id;
            createInterCertController.skip();
            createInterCertController.CreateRootCert();
            
            Account parentAccount2 = TestUtils.getCAOwner();
            insert parentAccount2;
            
            createInterCertController.parentAccountId=   parentAccount2.id; 
            createInterCertController.updateRootCert();
            createInterCertController.cancel(); 
            createInterCertController.cloneRootCert(); 
            createInterCertController.showUpdateButton();
            Test.stoptest();
        }
    }
    
    // additional test method to handle the scenario
    // when pem info is not provided by the user
    static testMethod void validateCreateInterCert2() {
    
        // create the parent account  - record type = Owner
        Account parentAccount = TestUtils.getCAOwner();
        insert parentAccount;
        
        // create a standard controller instance 
        ApexPages.StandardController standardcontroller = new ApexPages.StandardController(parentAccount);
        
        CreateRootCertController createInterCertController= new CreateRootCertController(standardController);
        
        PageReference pageRef = Page.CreateRootCert;
        pageRef.getParameters().put('id', String.valueOf(parentAccount.Id));
        Test.setCurrentPage(pageRef);
        createInterCertController.pemInfoStr  = null;
        createInterCertController.submit();
        // createInterCertController.copyParentAuditData();
        
        Test.startTest();
        
        Account childAccount = TestUtils.getRootCertificate(parentAccount.Id);
        childAccount.parentId = parentAccount.id;
        insert childAccount ;
        
        standardcontroller = new ApexPages.StandardController(childAccount);
        
        createInterCertController= new CreateRootCertController(standardController);
        
        pageRef = Page.CreateRootCert;
        pageRef.getParameters().put('id', String.valueOf(childAccount.Id));
        Test.setCurrentPage(pageRef);
        // createInterCertController.copyParentAuditData();
        Test.stopTest();
    }
}
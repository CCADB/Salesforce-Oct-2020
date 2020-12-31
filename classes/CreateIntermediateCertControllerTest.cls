/**

*** THIS PROGRAM HAS BEEN OBSOLETED on 2/19/2020 *** 
*** Another program CreateCertUsingPEMCtrl is being used which is a one-step process ***

Test Case for the following Controller Extensions:
- CreateIntermediateCertController
- X509CertificateCheckerUtility

 **THIS PROGRAM IS NOT USING ANYWHERE** As we recreated a program to create Intermediate cert using PEM this program is not useful.

**/

@isTest 
public class CreateIntermediateCertControllerTest{

    static testmethod void testInterMediateCert1(){
    
        Account accountSo = TestUtils.getCAOwner();
        insert accountSo;
        
        // create a standard controller instance 
        ApexPages.StandardController stndcontroller = new ApexPages.StandardController(accountSo);
        CreateIntermediateCertController ctrInterCertController= new CreateIntermediateCertController(stndcontroller);
        ctrInterCertController.copyParentAuditData();
        
        // create a ROOT CA
        Account rootCA = TestUtils.getRootCertificate(accountSo.Id);
        rootCa.X_509_Certificate_PEM__c = TestUtils.strPEMInfo;
        insert rootCa;
        
        // create intermediate CA
        Account testAccount = TestUtils.getIntermediateCertificate(rootCa.Id);
        testAccount.X_509_Certificate_PEM__c = TestUtils.strPEMInfo;
        insert testAccount;
         
        // create a standard controller instance 
        ApexPages.StandardController standardcontroller = new ApexPages.StandardController(testAccount);
        
        CreateIntermediateCertController createInterCertController= new CreateIntermediateCertController(standardController);
        
        PageReference pageRef = Page.CreateIntermediateCert;
        pageRef.getParameters().put('id', String.valueOf(accountSo.Id));
        Test.setCurrentPage(pageRef);
        
        //cover submit method
        createInterCertController.submit();
        createInterCertController.pemInfoStr  = 'testPEM';
        createInterCertController.submit();
        createInterCertController.pemInfoStr = TestUtils.strPEMInfo;
        createInterCertController.submit();
        
        //cover skip method
        createInterCertController.parentAccountId = accountSo.id;
        createInterCertController.skip();
        
        test.startTest();
        
        //create intermedia certs
        createInterCertController.createIntermediateCert();
        
        Account parentAccount2 = TestUtils.getCAOwner();
        insert parentAccount2;
        
        createInterCertController.parentAccountId = parentAccount2.id; 
        createInterCertController.updateIntermediateCert();
        
        parentAccount2.Extraction_Results__c = 'Test';
        update parentAccount2;
        createInterCertController.parentAccountId = parentAccount2.id; 
        createInterCertController.updateIntermediateCert();
        
        createInterCertController.cancel(); 
        createInterCertController.cloneIntermediateCert(); 
        createInterCertController.copyParentAuditData();
        createInterCertController.showUpdateButton(); 
        
        test.stopTest();  
    }
    
    static testMethod void testInterMediateCert2() {
    
        Account acc = TestUtils.getCAOwner();
        insert acc;
        
        Contact con = TestUtils.getContact(acc.Id);
        insert con;
        
        UserRole urole = [Select PortalType, PortalAccountId From UserRole where PortalType = 'CustomerPortal' limit 1];
        
        User user = new User();
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
        //update profile name as this is changed. - Customer Community Plus Login User For CCADB
        user.ProfileID = [SELECT Id FROM Profile WHERE Name = 'Customer Community Plus Login User - CAs' 
                AND UserType = 'PowerCustomerSuccess' LIMIT 1].id;
        user.PortalRole = 'Manager';
        insert user;
        
        System.RunAs(user) {
        
            // create a ROOT CA
            Account rootCA = TestUtils.getRootCertificate(acc.Id);
            rootCa.X_509_Certificate_PEM__c = TestUtils.strPEMInfo;
            insert rootCa;
            
            // create intermediate CA
            Account testAccount = TestUtils.getIntermediateCertificate(rootCa.Id);
            testAccount.X_509_Certificate_PEM__c = TestUtils.strPEMInfo;
            insert testAccount;
            
            test.startTest();
            
            ApexPages.StandardController standardcontroller = new ApexPages.StandardController(testAccount);
            
            CreateIntermediateCertController createInterCertController= new CreateIntermediateCertController(standardController);
            
            PageReference pageRef = Page.CreateIntermediateCert;
            pageRef.getParameters().put('id', String.valueOf(testAccount.Id));
            Test.setCurrentPage(pageRef);
            createInterCertController.pemInfoStr  = TestUtils.strPEMInfo;
            createInterCertController.submit();
            createInterCertController.parentAccountId = testAccount.id;
            createInterCertController.skip();
            createInterCertController.createIntermediateCert();
            //CA Owner Certs are not modified by Community User.
            /*Account parentAccount2 = getParentAccount();
            insert parentAccount2;
            createInterCertController.parentAccountId=   parentAccount2.id; 
            createInterCertController.updateIntermediateCert();*/
            createInterCertController.cancel(); 
            createInterCertController.cloneIntermediateCert(); 
            createInterCertController.copyParentAuditData();
            Test.stoptest();
        }
    }
}
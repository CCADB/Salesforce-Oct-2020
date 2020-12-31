/*******************************************************************************************************
 Name: PublicAllIntermediateCertsControllerTest

 Dependencies: PublicAllIntermediateCertsController, PublicAllIntermediateCertsCSV, 
 PublicAllIntermediateCertsWithPEMCSV, PublicAllIntermediateCertsControllerTest
 
 Description: This report generates list intermediate certs (Non-revoked) in hierarchy. 
 Report name used is 'Public Non-Revoked Intermediate Certificates'

 Instructions: None

 *******************************************************************************************************
 Revision History:
 
     05/16/2016 - Created new
     11/20/2019 - Added Subordinate CA Owner field to the report

 ******************************************************************************************************/


@isTest 
public class PublicAllIntermediateCertsControllerTest{

    static testMethod void validateController() {
    
        Account parentAccount = getParentAccount();
        insert parentAccount;
        
        Id profile = [select id from profile Where Name ='Customer Community Plus Login User - CAs' AND UserType = 'PowerCustomerSuccess' LIMIT 1].id;
       
       
        Contact con = new Contact(LastName ='testCon',AccountId = parentAccount.Id);
        insert con;  
                  
        User user = new User(alias = 'test123', email='test123@noemail.com',
                emailencodingkey='UTF-8', lastname='Testing', languagelocalekey='en_US',
                localesidkey='en_US', profileid = profile, country='United States',IsActive =true,
                ContactId = con.Id,
                timezonesidkey='America/Los_Angeles', username='tester@noemail.com');
       
        system.runAs(user) {
            // create the child account - record type = Root
            Account rootAccount = getRootAccount(parentAccount.id);
            insert rootAccount ;
            
            
            // create the child account - record type = Root
            Account childAccount = getChildAccount(rootAccount.id);
            insert childAccount;
        }
        
        PageReference pref = Page.PublicAllIntermediateCerts;
        Test.setCurrentPage(pref);
        
        PublicAllIntermediateCertsController pacrc = new PublicAllIntermediateCertsController ();
    }
    
    static testMethod void validateBatch() {
    
        Account parentAccount = getParentAccount();
        insert parentAccount;
        
        Id profile = [select id from profile Where Name ='Customer Community Plus Login User - CAs' Limit 1].id;
       
       
        Contact con = new Contact(LastName ='testCon',AccountId = parentAccount.Id);
        insert con;  
                  
        User user = new User(alias = 'test123', email='test123@noemail.com',
                emailencodingkey='UTF-8', lastname='Testing', languagelocalekey='en_US',
                localesidkey='en_US', profileid = profile, country='United States',IsActive =true,
                ContactId = con.Id,
                timezonesidkey='America/Los_Angeles', username='tester@noemail.com');
       
        system.runAs(user) {
        
            // create the child account - record type = Root
            Account rootAccount = getRootAccount(parentAccount.id);
            insert rootAccount ;
            
            // create the child account - record type = Root
            Account childAccount = getChildAccount(rootAccount.id);
            childAccount.CA_Owner_Id__c = parentAccount.Id;
            insert childAccount;
            
            Test.StartTest();
            
            Account childAccount2 = getChildAccount2(rootAccount.id);
            childAccount2.CA_Owner_Id__c = parentAccount.Id;
            insert childAccount2;
            
            Account childAccount3 = getChildAccount2(childAccount2.id);
            childAccount3.CA_Owner_Id__c = parentAccount.Id;
            insert childAccount3;
            
            Test.StopTest();
           
        }
        
        PublicAllIntermediateCertsBatch paicb = new PublicAllIntermediateCertsBatch();
        Database.executeBatch(paicb);
    }
    
    
    static testMethod void validateScheduler() {
    
        Account parentAccount = getParentAccount();
        insert parentAccount;
        
        Id profile = [select id from profile Where Name ='Customer Community Plus Login User - CAs' Limit 1].id;
       
       
        Contact con = new Contact(LastName ='testCon',AccountId = parentAccount.Id);
        insert con;  
                  
        User user = new User(alias = 'test123', email='test123@noemail.com',
                emailencodingkey='UTF-8', lastname='Testing', languagelocalekey='en_US',
                localesidkey='en_US', profileid = profile, country='United States',IsActive =true,
                ContactId = con.Id,
                timezonesidkey='America/Los_Angeles', username='tester@noemail.com');
       
        system.runAs(user) {
        
            // create the child account - record type = Root
            Account rootAccount = getRootAccount(parentAccount.id);
            insert rootAccount ;
            
            
            // create the child account - record type = Root
            Account childAccount = getChildAccount(rootAccount.id);
            insert childAccount;
            Account childAccount2 = getChildAccount2(rootAccount.id);
            insert childAccount2;
            new List<Account>{childAccount, childAccount2};
        }
        
        PublicAllInterCertScheduler.scheduleMe('Public AllIntermediate Certs Batch ' + System.now());
    
    }
    
    
    public static Account getParentAccount()
    {
        Account parentAccount = new Account();
        parentAccount.recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('CA Owner').getRecordTypeID();
        parentAccount.name = 'ParentAccount';
        parentAccount.type = 'Owner';
        parentAccount.status__c= 'Included';
        parentAccount.Revocation_Status__c = 'Included';
        parentAccount.website  = 'https//www.test.com';
        parentAccount.valid_From_GMT__c= date.today()+1;
        parentAccount.valid_to_GMT__c= date.today()+10;
        parentAccount.company_website__c=  'https//www.test.com';
        parentAccount.organizational_type__c=  'Organizational Type';
        parentAccount.geographic_focus__c=  'Geographic focus';
        parentAccount.primary_market_customer_base__c = 'Primary Market';
        return parentAccount;
    }
    
    public static Account getRootAccount(ID parentAccountId)
    {
        Account childAccount = new Account();
        childAccount.recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Root Certificate').getRecordTypeID();
        childAccount.name = 'ChildAccount';
        childAccount.type = 'Root';
        childAccount.phone='2128425500';
        childAccount.status__c = 'Included';
        childAccount.Revocation_Status__c = 'Not Revoked';
        childAccount.website  = 'https//www.test.com';
        childAccount.valid_From_GMT__c= date.today()+1;
        childAccount.valid_to_GMT__c= date.today()+10;
        childAccount.company_website__c=  'https//www.test.com';
        childAccount.SHA_1_Fingerprint__c= '26143151E02B45DDBADD5D8E56530DAAE328CF90';
        childAccount.SHA_256_Fingerprint__c= '2EA1DB6719D6041A06FC0898E5B3CF349A8FA8ECEE85EDB005965628F617F7C8';
        childAccount.Subject_SPKI_SHA256__c = '22079DEDFC1EACCC7BDFE81857DF8FC3D7F0BC31B79C4D91C9658FF67B256633';
        
        childAccount.parentid = parentAccountId;
        
        return childAccount;
    }
    
    
    
    public static Account getChildAccount(ID parentAccountId)
    {
        Account childAccount = new Account();
        childAccount.recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Intermediate Certificate').getRecordTypeID();
        childAccount.name = 'ChildAccount';
        childAccount.type = 'Root';
        childAccount.phone='2128425500';
        childAccount.Revocation_Status__c = 'Not Revoked';
        childAccount.website  = 'https//www.test.com';
        childAccount.valid_From_GMT__c= date.today()+1;
        childAccount.valid_to_GMT__c= date.today()+10;
        childAccount.company_website__c=  'https//www.test.com';
        childAccount.technically_constrained__c = false;
        childAccount.Revocation_Status__c = 'Not Revoked';
        childAccount.root_Cert_id__c=parentAccountId;
        childAccount.SHA_1_Fingerprint__c= '06143151E02B45DDBADD5D8E56530DAAE328CF90';
        childAccount.SHA_256_Fingerprint__c= '0EA1DB6719D6041A06FC0898E5B3CF349A8FA8ECEE85EDB005965628F617F7C8';
        childAccount.Subject_SPKI_SHA256__c = '02079DEDFC1EACCC7BDFE81857DF8FC3D7F0BC31B79C4D91C9658FF67B256633';
        childAccount.parentid = parentAccountId;
        childAccount.Certificate_Issuer_Common_Name__c = 'test';
        childAccount.Certificate_Issuer_Organization__c= 'test';
        childAccount.Certificate_Subject_Common_Name__c= 'test';
        childAccount.Certificate_Subject_Organization__c= 'test';
        childAccount.Extended_Key_Usage__c= 'test';
        childAccount.Certificate_Policy_CP__c= 'test';
        childAccount.Certification_Practice_Statement_CPS__c= 'test';
        //childAccount.Standard_Audit__c= 'http://www.google.com/StandardAudit.pdf';    
        //childAccount.BR_Audit__c= 'http://www.google.com/BRAudit.pdf';            
        childAccount.Auditor__c= 'test';            
        //childAccount.Management_Assertions_By__c= 'test';            
        childAccount.X_509_Certificate_PEM__c= 'test';            
        
        return childAccount;
    }
    
    public static Account getChildAccount2(ID parentAccountId)
    {
        Account childAccount = new Account();
        childAccount.recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Intermediate Certificate').getRecordTypeID();
        childAccount.name = 'ChildAccount2';
        childAccount.type = 'Root';
        childAccount.phone='2128425600';
        childAccount.Revocation_Status__c = 'Not Revoked';
        childAccount.website  = 'https//www.test.com';
        childAccount.valid_From_GMT__c= date.today()+1;
        childAccount.valid_to_GMT__c= date.today()+10;
        childAccount.company_website__c=  'https//www.test.com';
        childAccount.SHA_1_Fingerprint__c= '16143151E02B45DDBADD5D8E56530DAAE328CF90';
        childAccount.SHA_256_Fingerprint__c= '1EA1DB6719D6041A06FC0898E5B3CF349A8FA8ECEE85EDB005965628F617F7C8';
        childAccount.Subject_SPKI_SHA256__c = '12079DEDFC1EACCC7BDFE81857DF8FC3D7F0BC31B79C4D91C9658FF67B256633';
        childAccount.parentid = parentAccountId;
        
        return childAccount;
    }
}
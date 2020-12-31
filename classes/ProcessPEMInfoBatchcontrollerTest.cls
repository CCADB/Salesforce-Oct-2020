/*
* test class for following apex classes:
*
* ProcessPEMInfoBatch - 
* ProcessPEMInfoBatchController
* ProcessPEMInfoBatchScheduler
* ProcessPEMInfoBatchHelper
*
*/
@isTest(SeeAllData = false)
public class ProcessPEMInfoBatchcontrollerTest{
    
    //Test method for "ProcessPEMInfoBatchController" apex class
    static testmethod void testProcessPEMInfoBatchController(){
        
        PageReference pref = Page.ProcessPEMInfoBatch;
        Test.setCurrentPage(pref);
        
        ProcessPEMInfoBatchController obj = new ProcessPEMInfoBatchController();
        obj.startBatch();
    }
    
    //test method for "ProcessPEMInfoScheduler" apex class
    static testmethod void testProcessPEMInfoScheduler(){
        
        Test.startTest();
        String jobId = ProcessPEMInfoScheduler.scheduleMe('test job - 24-09-2016');
        Test.stopTest();
    }
    
    //Test method for "ProcessPEMInfoBatch" & "ProcessPEMInfoBatchHelper" apex class
    static testmethod void testProcessPEMInfoBatch1(){
        
        String intermediateCertRecordType = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Intermediate Certificate').getRecordTypeID();
        
        String PEMinfo = '-----BEGIN CERTIFICATE-----' +
               'MIIDg6P3qMZLWh1K8F/30ltoN10igQ35y' +
               'Bx4GG+Ub/zMhkrtTClipcItkEwu7fHEdZN6/wQKh' +
               '-----END CERTIFICATE-----'; 
        
        Account parentAccount = new Account(Name= 'Test');
        insert parentAccount;
        
        Id profile = [select id from profile Where Name ='Customer Community Plus Login User For CCADB' AND UserType = 'PowerCustomerSuccess' LIMIT 1].id;
       
       
        Contact con = new Contact(LastName ='testCon',AccountId = parentAccount.Id);
        insert con;  
                  
        User user = new User(alias = 'test123', email='test123@noemail.com',
                emailencodingkey='UTF-8', lastname='Testing', languagelocalekey='en_US',
                localesidkey='en_US', profileid = profile, country='United States',IsActive =true,
                ContactId = con.Id,
                timezonesidkey='America/Los_Angeles', username='tester@noemail.com');
       
        system.runAs(user) {
            Account rootcertificate = new Account(RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Root Certificate').getRecordTypeID());
            rootcertificate.Name = 'Test Root Cert Account';
            rootcertificate.X_509_Certificate_PEM__c = PEMinfo;
            rootcertificate.Extraction_Results__c = 'test';
            rootcertificate.parentid = parentAccount.Id;
            insert rootcertificate;
            Account intermediateAcc = new Account(RecordTypeId = intermediateCertRecordType);
            intermediateAcc.Name = 'Test Intermediate Cert Account';
            intermediateAcc.X_509_Certificate_PEM__c = PEMinfo;
            intermediateAcc.Extraction_Results__c = 'test';
            intermediateAcc.parentid = rootcertificate.Id;
            insert intermediateAcc;
        }
        
        ProcessPEMInfoBatchController obj = new ProcessPEMInfoBatchController();
        obj.startBatch();
    }
}
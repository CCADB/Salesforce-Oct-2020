/*
* test class for 'UploadFileController'
*/
@isTest(SeeAllData = false)
public class UploadFileControllerTest{    /****   UNUSED TEST CLASS  *****
    
    static testmethod void testErrorCondition(){
        
        Account caOwnerAcc = getCAOwnerAccount();
        insert caOwnerAcc;
        
        Case caseSO = getCase(caOwnerAcc.Id);
        insert caseSO;
        
        PageReference pref = Page.UploadFile;
        pref.getParameters().put('id', caseSO.Id);
        pref.getParameters().put('documentType', 'Standard Audit');
        Test.setCurrentPage(pref);
        
        ApexPages.standardController stdCon = new ApexPages.standardController(caseSO);
        UploadFileController obj = new UploadFileController(stdCon);
        
        PageReference redirectURL = obj.uploadFile();
        
        System.assertEquals(redirectURL, null);
    }
    
    static testmethod void testStdAuditFileUpload(){
        
        Account caOwnerAcc = getCAOwnerAccount();
        insert caOwnerAcc;
        
        Case caseSO = getCase(caOwnerAcc.Id);
        insert caseSO;
        
        PageReference pref = Page.UploadFile;
        pref.getParameters().put('id', caseSO.Id);
        pref.getParameters().put('documentType', 'Standard Audit');
        Test.setCurrentPage(pref);
        
        Blob body = Blob.valueOf('test document');
        
        ApexPages.standardController stdCon = new ApexPages.standardController(caseSO);
        UploadFileController obj = new UploadFileController(stdCon);
        obj.fileData = body;
        obj.fileName = 'Standard Audit document';
        
        PageReference redirectURL = obj.uploadFile();
        
        //System.assertEquals([SELECT Name FROM Document WHERE Name = 'Standard Audit document' LIMIT 1][0].Name, 'Standard Audit document');
        System.assertEquals([SELECT Name FROM Attachment WHERE Name = 'Standard Audit document' LIMIT 1][0].Name, 'Standard Audit document');
    }
    
    static testmethod void testBRAuditFileUpload(){
        
        Account caOwnerAcc = getCAOwnerAccount();
        insert caOwnerAcc;
        
        Case caseSO = getCase(caOwnerAcc.Id);
        insert caseSO;
        
        PageReference pref = Page.UploadFile;
        pref.getParameters().put('id', caseSO.Id);
        pref.getParameters().put('documentType', 'BR Audit');
        Test.setCurrentPage(pref);
        
        Blob body = Blob.valueOf('test document');
        
        ApexPages.standardController stdCon = new ApexPages.standardController(caseSO);
        UploadFileController obj = new UploadFileController(stdCon);
        obj.fileData = body;
        obj.fileName = 'BR Audit document';
        
        PageReference redirectURL = obj.uploadFile();
        
        System.assertEquals([SELECT Name FROM Attachment WHERE Name = 'BR Audit document' LIMIT 1][0].Name, 'BR Audit document');
    }
    
    static testmethod void testEVAuditFileUpload(){
        
        Account caOwnerAcc = getCAOwnerAccount();
        insert caOwnerAcc;
        
        Case caseSO = getCase(caOwnerAcc.Id);
        insert caseSO;
        
        PageReference pref = Page.UploadFile;
        pref.getParameters().put('id', caseSO.Id);
        pref.getParameters().put('documentType', 'EV Audit');
        Test.setCurrentPage(pref);
        
        Blob body = Blob.valueOf('test document');
        
        ApexPages.standardController stdCon = new ApexPages.standardController(caseSO);
        UploadFileController obj = new UploadFileController(stdCon);
        obj.fileData = body;
        obj.fileName = 'EV Audit document';
        
        PageReference redirectURL = obj.uploadFile();
        
        System.assertEquals([SELECT Name FROM Attachment WHERE Name = 'EV Audit document' LIMIT 1][0].Name, 'EV Audit document');
    }
    
    static testmethod void testCPAuditFileUpload(){
        
        Account caOwnerAcc = getCAOwnerAccount();
        insert caOwnerAcc;
        
        Case caseSO = getCase(caOwnerAcc.Id);
        insert caseSO;
        
        PageReference pref = Page.UploadFile;
        pref.getParameters().put('id', caseSO.Id);
        pref.getParameters().put('documentType', 'CP');
        Test.setCurrentPage(pref);
        
        Blob body = Blob.valueOf('test document');
        
        ApexPages.standardController stdCon = new ApexPages.standardController(caseSO);
        UploadFileController obj = new UploadFileController(stdCon);
        obj.fileData = body;
        obj.fileName = 'CP Audit document';
        
        PageReference redirectURL = obj.uploadFile();
        
        System.assertEquals([SELECT Name FROM Attachment WHERE Name = 'CP Audit document' LIMIT 1][0].Name, 'CP Audit document');
    }
    
    static testmethod void testCPSAuditFileUpload(){
        
        Account caOwnerAcc = getCAOwnerAccount();
        insert caOwnerAcc;
        
        Case caseSO = getCase(caOwnerAcc.Id);
        insert caseSO;
        
        PageReference pref = Page.UploadFile;
        pref.getParameters().put('id', caseSO.Id);
        pref.getParameters().put('documentType', 'CPS');
        Test.setCurrentPage(pref);
        
        Blob body = Blob.valueOf('test document');
        
        ApexPages.standardController stdCon = new ApexPages.standardController(caseSO);
        UploadFileController obj = new UploadFileController(stdCon);
        obj.fileData = body;
        obj.fileName = 'CPS Audit document';
        
        PageReference redirectURL = obj.uploadFile();
        
        System.assertEquals([SELECT Name FROM Attachment WHERE Name = 'CPS Audit document' LIMIT 1][0].Name, 'CPS Audit document');
    }
    
    public static Account getCAOwnerAccount(){

        Account parentAccount = new Account();
        parentAccount.recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('CA Owner').getRecordTypeID();
        parentAccount.name = 'ParentAccount';
        parentAccount.type = 'Owner';
        parentAccount.status__c= 'Included';
        parentAccount.Revocation_Status__c = 'Included';
        parentAccount.phone='2128425500';
        parentAccount.website  = 'https//www.test.com';
        parentAccount.valid_From_GMT__c= date.today()+1;
        parentAccount.valid_to_GMT__c= date.today()+10;
        parentAccount.company_website__c=  'https//www.test.com';
        parentAccount.organizational_type__c=  'Organizational Type';
        parentAccount.geographic_focus__c=  'Geographic focus';
        parentAccount.primary_market_customer_base__c = 'Primary Market';
        return parentAccount;
    }
    
    public static Case getCase(Id accountId){
        Case caseSO = new Case(AccountId = accountId);
        caseSO.subject = 'test audit request case';
        caseSO.Status = 'Open';
        return caseSO;
    }   *****/
}
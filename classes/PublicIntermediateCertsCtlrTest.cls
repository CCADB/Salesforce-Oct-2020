/**

Test Case for the following Controller Extension:
PublicIntermediateCertsController

**/

@isTest 
public class PublicIntermediateCertsCtlrTest{

    static testMethod void validateTest() {
  
        Account parentAccount = getParentAccount();
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
            // create the child account - record type = Root
            Account childAccount = getChildAccount(parentAccount.id);
            childAccount.recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Root Certificate').getRecordTypeID();
            insert childAccount;
            
            Account childAccount1 = getChildAccount(childAccount.id);
            insert childAccount1;
        }
        PageReference pref = Page.PublicIntermediateCertsCSVFormat;
        Apexpages.currentpage().getparameters().put('CAOwnerName','ParentAccount');
        Test.setCurrentPage(pref);
        
        PageReference pageRef = Page.PublicIntermediateCerts;
        Apexpages.currentpage().getparameters().put('CAOwnerName','ParentAccount');
        PublicIntermediateCertsController pacrc = new PublicIntermediateCertsController();
        Apexpages.currentpage().getparameters().put('CAOwnerName','');
        PublicIntermediateCertsController pacrc1 = new PublicIntermediateCertsController();
        pacrc1.getCurrentDate();
    }
  
    public static Account getParentAccount()
    {
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
    
    
    public static Account getChildAccount(ID parentAccountId)
    {
        Account childAccount = new Account();
        childAccount.recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Intermediate Certificate').getRecordTypeID();
        childAccount.name = 'ChildAccount';
        childAccount.Status__c = 'Included';
        childAccount.OneCRL_Status__c = 'Ready to Add';
        childAccount.Certificate_Issuer_Organization__c = 'Test IO';
        childAccount.Certificate_Issuer_Organizational_Unit__c = 'Test IOU';
        childAccount.Certificate_Issuer_Common_Name__c = 'Test CName';
        childAccount.Certificate_Subject_Common_Name__c = 'Test SName';
        childAccount.Certificate_Subject_Organization__c = 'Test OName';
        childAccount.OneCRL_Bug_Number__c = '123';
        childAccount.CRL_URL_s__c = 'Test URL';
        //childAccount.OCSP_URL_s__c = 'Test ';
        childAccount.Comments__c = 'Test Comment';
        childAccount.Approval_Bug__c = 'Test';
        childAccount.NSS_Release_When_First_Included__c = 'Test';
        childAccount.Firefox_Release_When_First_Included__c = 'Test';
        childAccount.Mozilla_Applied_Constraints__c = 'Test';
        childAccount.Certificate_Policy_CP__c = 'Test';
        childAccount.Certification_Practice_Statement_CPS__c = 'Test';
        childAccount.X_509_Certificate_PEM__c = 'Test';
        childAccount.phone='2128425500';
        childAccount.Revocation_Status__c = 'Not Revoked';
        childAccount.website  = 'https//www.test.com';
        childAccount.valid_From_GMT__c= date.today()+1;
        childAccount.valid_to_GMT__c= date.today()+10;
        childAccount.company_website__c=  'https//www.test.com';
        childAccount.SHA_1_Fingerprint__c= '7A9CA651E9786E82EA05DA63610FE7BD9800B718';
        childAccount.SHA_256_Fingerprint__c= '832266D6BA8CBFCBF28E0614A01D9F4C39B8E41F7C87D2077DBB6C03840CA9C2';
        childAccount.Subject_SPKI_SHA256__c= '9C4F7F92E663D63A92CBE13E82C3F7AE023BE530E2FAC54BAD690BC77A82C184';
        childAccount.parentid = parentAccountId;
        
        return childAccount;
    }

}
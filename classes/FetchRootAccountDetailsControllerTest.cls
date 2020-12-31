/**

Test Case for the following Controller Extension:
FetchRootAccountDetailsController

**/

@isTest 
public class FetchRootAccountDetailsControllerTest{
    
    static testMethod void validateFetchRootAccountDetails() {
    
     // create the parent account  - record type = Owner
     Account parentAccount = getParentAccount();
     parentAccount.Name = 'parent root account 1';
     insert parentAccount;
     
     // create the contact associated with the parent account
     Contact parentContact = getParentContact(parentAccount.id);
     parentContact.firstName = 'parent_firstname';
     parentContact.lastName = 'parent_lastname';
     insert parentContact;
     
     // create the root account  - record type = Root
     Account rootAccount = getrootAccount(parentAccount.Id);
     insert rootAccount;
     
     Case caseSO = getCase(parentAccount.Id, parentContact.Id); 
     insert caseSO;
     
     // create a case
     Root_Case__c accountCase = getRootCase(parentAccount.Id, rootAccount.id, caseSO.Id);
     insert accountCase;
     
     Root_Case__c rootCaseWithoutAccount = getRootCase(null, null, caseSO.Id);
     insert rootCaseWithoutAccount;
     
     // create a standard controller instance 
     ApexPages.StandardController standardcontroller = new ApexPages.StandardController(accountCase);
     
     FetchRootAccountDetailsController fetchRootAccController= new FetchRootAccountDetailsController(standardController);
     
     fetchRootAccController.showErrorMessage();
     
     fetchRootAccController.fetchRootAccountDetailsOnRootCase();
    
    // execute scenario where the case does not have any account
     standardcontroller = new ApexPages.StandardController(rootCaseWithoutAccount);
     fetchRootAccController= new FetchRootAccountDetailsController(standardController);
     fetchRootAccController.fetchRootAccountDetailsOnRootCase();     
    
    }
    
      public static Account getrootAccount(Id parentAccountId)
    {
        Account rootAccount = new Account();
        rootAccount.recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Root Certificate').getRecordTypeID();
        rootAccount.name = 'RootAccount';
        rootAccount.phone='2128425500';
        rootAccount.website  = 'https//www.test.com';
        rootAccount.company_website__c=  'https//www.test.com';
        rootAccount.parentid = parentAccountId;
        return rootAccount;
    }
    
    
     public static Root_Case__c getRootCase(Id caownerAccountId, ID accountId, Id caseId)
    {
        Root_Case__c rootCaseDetailsSO = new Root_Case__c();
        rootCaseDetailsSO.Root_Certificate_Name_Existing__c=accountId;
        rootCaseDetailsSO.CA_Owner_Name_Existing__c = caownerAccountId;
        rootCaseDetailsSO.Root_Certificate_Name__c = 'Test Root';
        rootCaseDetailsSO.Request_Status__c = 'Initial Request Received';
        rootCaseDetailsSo.SHA_1_Fingerprint__c = '1:2:3:4:5';
        //rootCaseDetailsSO.Certificate_Signature_Algorithm__c= 'Certificate name';
        //rootCaseDetailsSO.Signing_Key_Parameters__c = 'Signing Key Parameters';
        rootCaseDetailsSO.Trust_Bits__c = 'Trust Bits';
        rootCaseDetailsSO.Case_No__c = caseId;
        rootCaseDetailsSO.Apply_Standard_Audit__c = true;
        rootCaseDetailsSO.Apply_BR_Audit__c = true;
        rootCaseDetailsSO.Apply_EV_Audit__c = true;
        return rootCaseDetailsSO ;
    }
    
    public static Case getCase(ID accountId, Id contactID)
    {
        Case caseDetailsSO = new CAse();
        caseDetailsSO.contactid = contactId;
        caseDetailsSO.accountid=accountId;
        caseDetailsSO.subject='test';
        caseDetailsSO.request_status__c = 'Initial Request Received';
        caseDetailsSO.new_contact_name__c='test user';
        caseDetailsSO.new_contact_type__c='Primary POC';
        caseDetailsSO.new_contact_email__c = 'test@test.com' ;
        caseDetailsSO.new_contact_phone__c = '23456789';
        caseDetailsSO.new_contact_department__c = 'CA Program Dept';
        caseDetailsSO.new_contact_title__c = 'CA Program Manager';
        caseDetailsSO.company_website__c = 'https://www.test1233.com';
        caseDetailsSO.organizational_type__c = 'Organizational Type';
        caseDetailsSO.geographic_focus__c= 'Geographic focus';
        //caseDetailsSO.Company_Website_Verified__c = 'Verified';              
        //caseDetailsSO.Organizational_Type_Verified__c = 'Not Applicable';              
        //caseDetailsSO.Organizational_Type_Others_Verified__c = 'Verified';               
        //caseDetailsSO.Geographic_Focus_Verified__c = 'Not Applicable'; 
        //caseDetailsSO.Primary_Market_Customer_Base_Verified__c = 'Verified';              
        //caseDetailsSO.Impact_to_Mozilla_Users_Verified__c = 'Verified';               
        //caseDetailsSO.CA_s_Reponse_to_Recom_Prac_Verified__c = 'Not Applicable';               
        //caseDetailsSO.CA_s_Response_to_Prob_Prac_Verified__c = 'Verified'; 
              
        return caseDetailsSO ;
    }
    
    public static Contact getParentContact(ID accountid)
    {
        Contact parentContact = new Contact();
        parentcontact.firstname = 'FirstName';
        parentcontact.accountid = accountId;
        parentcontact.lastname = 'LastName';
        parentcontact.email= 'LastName@firstname.com';
        parentcontact.phone= '456786588';
        parentcontact.type__c= 'Primary POC';
        
        return parentContact;
    }
    
    public static Account getParentAccount()
    {
        Account parentAccount = new Account();
        parentAccount.recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('CA Owner').getRecordTypeID();
        parentAccount.name = 'ParentAccount';
        parentAccount.type = 'Owner';
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
}
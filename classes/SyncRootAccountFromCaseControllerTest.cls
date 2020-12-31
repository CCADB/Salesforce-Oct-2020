@isTest
public class SyncRootAccountFromCaseControllerTest{
    
    static testmethod void test1(){
     
     String PEMinfo = '-----BEGIN CERTIFICATE-----' +
               'MIIDg6P3qMZLWh1K8F/30ltoN10igQ35y' +
               'Bx4GG+Ub/zMhkrtTClipcItkEwu7fHEdZN6/wQKh' +
               '-----END CERTIFICATE-----';
           
     // create the parent account  - record type = Owner
     Account parentAccount = getParentAccount();
     parentAccount.Name = 'parent root account 1';
     parentAccount.X_509_Certificate_PEM__c = PEMinfo;
     insert parentAccount;
     
     // create the contact associated with the parent account
     Contact parentContact = getParentContact(parentAccount.id);
     parentContact.firstName = 'parent_firstname';
     parentContact.lastName = 'parent_lastname';
     insert parentContact;
     
     // create the child account - record type = Root
     Account childAccount = getChildAccount(parentAccount.id);
     parentAccount.X_509_Certificate_PEM__c = PEMinfo;
     childAccount.Name = 'child root account 1';
     //insert childAccount;
     
     // create the child account - record type = Root
     Account childAccount1 = getChildAccount(parentAccount.id);
     childAccount1.X_509_Certificate_PEM__c = PEMinfo;
     childAccount1.Name = 'child root account 2';
     //insert childAccount;
     
     // create the child account - record type = Root
     Account childAccount2 = getChildAccount(parentAccount.id);
     childAccount2.X_509_Certificate_PEM__c = PEMinfo;
     childAccount2.Name = 'child root account 3';
     insert new list<Account>{childAccount, childAccount1, childAccount2};
     
     // create a case
     Case accountCaseA = getCase(parentAccount.id, parentContact.id);
     if(Schema.SObjectType.Case.getRecordTypeInfosByName().get('CA Owner/Root Inclusion Request') != null)
         accountCaseA.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('CA Owner/Root Inclusion Request').getRecordTypeID();
     insert accountCaseA;
     
            
     // create the root case and associate it with the case
     Root_Case__c rootCaseA1 = getRootCase(accountCaseA.id, parentAccount.Id, childAccount.Id);
     rootCaseA1.SHA_1_Fingerprint__c = '12:40:56:78:90:14:34:56:78:90:12:34:56:78:90:12:34:56:78:90';
     rootCaseA1.X_509_Certificate_PEM__c = PEMinfo;
     if(Schema.SObjectType.Root_Case__c.getRecordTypeInfosByName().get('CA Owner/Root Inclusion Request') != null)
         rootCaseA1.RecordTypeId = Schema.SObjectType.Root_Case__c.getRecordTypeInfosByName().get('CA Owner/Root Inclusion Request').getRecordTypeID();
     //insert rootCaseA1;

     Root_Case__c rootCaseA2 = getRootCase(accountCaseA.id, parentAccount.Id, childAccount1.Id);
     rootCaseA2.SHA_1_Fingerprint__c = '12:36:56:78:90:16:34:56:78:90:12:34:56:78:90:12:34:56:78:90';
     rootCaseA2.X_509_Certificate_PEM__c = PEMinfo;
     if(Schema.SObjectType.Root_Case__c.getRecordTypeInfosByName().get('CA Owner/Root Inclusion Request') != null)
         rootCaseA2.RecordTypeId = Schema.SObjectType.Root_Case__c.getRecordTypeInfosByName().get('CA Owner/Root Inclusion Request').getRecordTypeID();
     //insert rootCaseA2;

     Root_Case__c rootCaseA3 = getRootCase(accountCaseA.id, parentAccount.Id, childAccount2.Id);
     rootCaseA3.SHA_1_Fingerprint__c = '12:38:56:78:90:18:34:56:78:90:12:34:56:78:90:12:34:56:78:90';
     rootCaseA3.X_509_Certificate_PEM__c = PEMinfo;
     if(Schema.SObjectType.Root_Case__c.getRecordTypeInfosByName().get('CA Owner/Root Inclusion Request') != null)
         rootCaseA3.RecordTypeId = Schema.SObjectType.Root_Case__c.getRecordTypeInfosByName().get('CA Owner/Root Inclusion Request').getRecordTypeID();
     insert new List<Root_Case__c>{rootCaseA1, rootCaseA2, rootCaseA3};
     
     // Start the test
     Test.startTest();
     
     PageReference pageRef = Page.SyncRootAccountFromCase; 
     ApexPages.StandardController standardcontroller = new ApexPages.StandardController(accountCaseA);
     Test.setCurrentPage(pageRef);
     ApexPages.currentPage().getParameters().put('id', accountCaseA.Id);
     //standardcontroller = new ApexPages.StandardController(accountCaseA);
     
     SyncRootAccountFromCaseController syncRootAccController= new SyncRootAccountFromCaseController(standardController);
    
     syncRootAccController.createNewAccountSoInstance('test account', accountCaseA.Id); 
     syncRootAccController.syncAccount(); 
     syncRootAccController.redirectToSyncContact(); 
     syncRootAccController.cancelSyncAccount(); 
     syncRootAccController.redirectToRootCase();
     syncRootAccController.next();
     
     syncRootAccController.getRootCase();
     syncRootAccController.getParentAccount();
     syncRootAccController.getTotalRootCaseCount();
     syncRootAccController.getCurrentRecordCount();
     syncRootAccController.getRootAccountExists();
     
     test.stopTest();
     
    }
    
    public static Account getParentAccount() {
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

    public static Contact getParentContact(ID accountid){
        
        Contact parentContact = new Contact();
        parentcontact.firstname = 'FirstName';
        parentcontact.accountid = accountId;
        parentcontact.lastname = 'LastName';
        parentcontact.email= 'LastName@firstname.com';
        parentcontact.phone= '456786588';
        parentcontact.type__c= 'Primary POC';
        
        return parentContact;
    }

   public static Account getChildAccount(ID parentAccountId) {
        
        Account childAccount = new Account();
        childAccount.recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Root Certificate').getRecordTypeID();
        childAccount.name = 'ChildAccount';
        childAccount.type = 'Root';
        childAccount.phone='2128425500';
        childAccount.website  = 'https//www.test.com';
        childAccount.valid_From_GMT__c= date.today()+1;
        childAccount.valid_to_GMT__c= date.today()+10;
        childAccount.company_website__c=  'https//www.test.com';
        childAccount.SHA_1_Fingerprint__c= '12:34:56:78:90:12:34:56:78:90:12:34:56:78:90:12:34:56:78:90';
        childAccount.parentid = parentAccountId;
        
        return childAccount;
    }
    
   public static Case getCase(ID accountId, Id contactID) {
        
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
    
   public static Root_Case__c getRootCase(ID caseID, Id caOwnerId, Id rootAccountId) {
         
         Root_Case__c rootCaseSO = TestUtils.getRootCase(caseId, caOwnerId);
         rootCaseSO.Root_Certificate_Name_Existing__c = rootAccountId;
         /*rootCaseSO.root_certificate_name__c = 'ChildAccount';
         rootCaseSO.case_no__c = caseID;
         rootCaseSO.CA_Owner_Name_Existing__c = caOwnerId;
         rootCaseSO.Root_Certificate_Name_Existing__c = rootAccountId;
         rootCaseSO.Apply_Standard_Audit__c = true;
         rootCaseSO.Apply_BR_Audit__c = true;
         rootCaseSO.Apply_EV_Audit__c = true;
         
         rootCaseSO.valid_from__c = date.today()+1;
         rootCaseSO.valid_to__c = date.today()+10;
         rootCaseSO.SHA_1_Fingerprint__c = '12:34:56:78:90:12:34:56:78:90:12:34:56:78:90:12:34:56:78:90';
         rootCaseSO.trust_bits__c = 'Websites';
         rootCaseSO.BR_Audit__c = 'www.company.com/brauditdocument.html';
         rootCaseSO.EV_Policy_OID_s__c = 'Not EV';
         rootCaseSO.EV_Audit__c = 'www.company.com/evauditdocument.html';
         rootCaseSO.NSS_Release_When_First_Included__c = 'NSS 1.0';
         rootCaseSO.Firefox_Release_When_First_Included__c = 'Firefox 1.0';             
                             
         RootCaseSO.O_From_Issuer_Field_Verified__c = 'Verified';  
         RootCaseSO.OU_From_Issuer_Field_Verified__c = 'Verified';   
         RootCaseSO.Certificate_Summary_Verified__c = 'Not Applicable';  
         RootCaseSO.Root_Certificate_Download_URL_Verified__c = 'Verified';  
         RootCaseSO.SHA_1_Fingerprint_Verified__c = 'Verified';  
         RootCaseSO.SHA_256_Fingerprint_Verified__c = 'Verified';   
         RootCaseSO.Valid_From_Verified__c = 'Verified';  
         RootCaseSO.Valid_To_Verified__c = 'Not Applicable';  
         RootCaseSO.Certificate_Version_Verified__c = 'Verified';  
         RootCaseSO.Cert_Signature_Algorithm_Verified__c = 'Verified';   
         RootCaseSO.Signing_Key_Parameters_Verified__c = 'Not Applicable';   
         RootCaseSO.TestWebsiteURLSSLorExCert_Verified__c = 'Verified';         
         RootCaseSO.CRL_URL_Verified__c = 'Verified';  
         RootCaseSO.OCSP_URL_Verified__c = 'Verified';  
         RootCaseSO.Revocation_Tested_Verified__c = 'Verified'; 
         RootCaseSO.CA_Browser_Forum_Lint_Test_Verified__c = 'Verified'; 
         RootCaseSO.Test_Website_Lint_Test_Verified__c = 'Verified';  
         RootCaseSO.Trust_Bits_Verified__c = 'Verified';  
         RootCaseSO.SSL_Validation_Type_Verified__c = 'Not Applicable';  
         RootCaseSO.EV_Policy_OID_s_Verified__c = 'Verified';  
         RootCaseSO.EV_Tested_Verified__c = 'Verified';  
         RootCaseSO.Root_Stores_Included_In_Verified__c = 'Verified';  
         RootCaseSO.Mozilla_Applied_Constraints_Verified__c = 'Verified';  
         RootCaseSO.CA_Hierarchy_Verified__c = 'Verified';  
         RootCaseSO.Externally_Operated_SubCAs_Verified__c = 'Verified';  
         RootCaseSO.Cross_Signing_Verified__c = 'Verified';  
         RootCaseSO.Tech_Cons_on_3rd_party_Iss_Verified__c = 'Verified'; 
         RootCaseSO.Policy_Documentation_Verified__c = 'Verified';  
         RootCaseSO.CA_Document_Repository_Verified__c = 'Verified'; 
         RootCaseSO.CP_Verified__c = 'Verified' ; 
         RootCaseSO.CPS_Verified__c = 'Verified';  
         RootCaseSO.Other_Relevant_Documents_Verified__c = 'Verified';  
         RootCaseSO.Auditor_Name_Verified__c = 'Verified'; 
         RootCaseSO.Auditor_Website_Verified__c = 'Verified';  
         RootCaseSO.Auditor_Qualifications_Verified__c = 'Verified';  
         RootCaseSO.Management_Assertions_By_Verified__c = 'Verified';
         RootCaseSO.Standard_Audit_Verified__c = 'Verified'; 
         RootCaseSO.Standard_Audit_Type_Verified__c = 'Verified';   
         RootCaseSO.Standard_Audit_Statement_Dt_Verified__c = 'Verified';  
         RootCaseSO.Standard_Audit_Period_Dates_Verified__c = 'Verified';
         RootCaseSO.BR_Audit_Verified__c = 'Verified';  
         RootCaseSO.BR_Audit_Type_Verified__c = 'Verified';  
         RootCaseSO.BR_Audit_Statement_Date_Verified__c = 'Not Applicable'; 
         RootCaseSO.BR_Audit_Period_Dates_Verified__c = 'Verified'; 
         RootCaseSO.EV_Audit_Verified__c = 'Verified';              
         RootCaseSO.EV_Audit_Type_Verified__c = 'Verified';              
         RootCaseSO.EV_Audit_Statement_Date_Verified__c = 'Not Applicable'; 
         RootCaseSO.EV_SSL_Audit_Period_Dates_Verified__c = 'Verified';              
         RootCaseSO.BR_Commitment_to_Comply_Verified__c = 'Verified';               
         RootCaseSO.SSL_Verification_Procedures_Verified__c = 'Verified';               
         RootCaseSO.EV_SSL_Verification_Proc_Verified__c = 'Verified';               
         RootCaseSO.Org_Verification_Procedure_Verified__c = 'Verified';              
         RootCaseSO.Email_Addr_Verification_Proc_Verified__c = 'Not Applicable';               
         RootCaseSO.Code_Signing_Subs_Verif_Proc_Verified__c = 'Verified';               
         RootCaseSO.Multi_Factor_Authentication_Verified__c = 'Verified';               
         RootCaseSO.Network_Security_Verified__c = 'Verified';               
         RootCaseSO.Publ_Discl_Audited_subCAs_Verified__c = 'Not Applicable';
         RootCaseSO.Comments_by_Mozilla_on_Root_Case__c = 'Comments on Root';*/
        

        return rootCaseSO ;
    }
}
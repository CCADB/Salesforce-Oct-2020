/*
    Description: Test class for Delete Certs
*/
@IsTest
public with sharing class DeleteCertsControllerTest {
    
     static testmethod void testDeleteCerts(){    
        
         //create the parent account  - record type = Owner
         Account parentAccount = SyncParentAccountFromCaseControllerTest.getParentAccount();
         parentAccount.Name = 'parent root account 1';
         insert parentAccount;
         
         // create the child account - record type = Root
         Account childAccount = SyncParentAccountFromCaseControllerTest.getChildAccount(parentAccount.id);
         childAccount.Name = 'child root account 1';
         childAccount.X_509_Certificate_PEM__c = 'Test PEM Info';
         insert childAccount;
         
         Account testaccount = new Account(Name = 'Test Account');
         insert testaccount;
         
         //delete record - id not found
         DeleteCertsController deletecerts1 = new DeleteCertsController(new Apexpages.standardcontroller(new Account()));
         deletecerts1.deleteAccount();
         
         //delete parent record - has child records
         DeleteCertsController deletecerts2 = new DeleteCertsController(new Apexpages.standardcontroller(parentAccount));
         deletecerts2.deleteAccount();
         
         //delete parent record - PEM Info given
         DeleteCertsController deletecerts3 = new DeleteCertsController(new Apexpages.standardcontroller(childAccount));
         deletecerts3.deleteAccount();
         
         //delete parent record - PEM Info given
         DeleteCertsController deletecerts4 = new DeleteCertsController(new Apexpages.standardcontroller(testaccount));
         deletecerts4.deleteAccount();
         
    }
}
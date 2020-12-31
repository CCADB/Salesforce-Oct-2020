/*
    Description: test class for RootCasesEditTestWebsitesController
*/
@isTest
private class RootCasesEditTestWebsitesControllerTest {
    
    static testmethod void testTestWebsitesMethod(){ 
        
        Account caOwnerAcc = TestUtils.getCAOwner();
        insert caOwnerAcc;
        
        Case caseSO = TestUtils.getCase(caOwnerAcc.Id);
        caseSO.Standard_Audit_Authenticity_Confirmed__c = True;
        caseSO.BR_Audit_Authenticity_Confirmed__c = True;
        caseSO.EV_Code_Signing_Audit_Auth_Confirmed__c = True;
        caseSO.EV_SSL_Audit_Authenticity_Confirmed__c = True;
        insert caseSO;
        
        // create the child account - record type = Root
        Account childAccount = TestUtils.getRootCertificate(caOwnerAcc.id);
        childAccount.Name = 'child root account 1';
        insert childAccount;
        
        Root_Case__c rootCaseA1 = TestUtils.getRootCase(caseSO.id,caOwnerAcc.Id);
        rootCaseA1.request_status__c   = 'Initial Request Received';         
        rootCaseA1.Apply_Standard_Audit__c = true;
        rootCaseA1.Apply_BR_Audit__c = true;
        rootCaseA1.Apply_EV_Audit__c = true;         
        rootCaseA1.Case_No__c = caseSO.Id;
        rootCaseA1.CA_Owner_Name_Existing__c = caOwnerAcc.Id;
        rootCaseA1.Root_Certificate_Name_Existing__c = childAccount.Id;
        rootCaseA1.RecordTypeId = Schema.SObjectType.Root_Case__c.getRecordTypeInfosByName().get('CA Audit Update Request').getRecordTypeID();
        insert rootCaseA1;
        
        RootCasesEditTestWebsitesController editctrl = new RootCasesEditTestWebsitesController(new Apexpages.standardcontroller(caseSO));
        editctrl.UpdateRootCases();
        if(editctrl.lstAllRootCases.size() > 0){
            editctrl.lstAllRootCases[0].Test_Website_Valid__c = '';
            editctrl.UpdateRootCases();
            editctrl.lstAllRootCases[0].Test_Website_Valid__c = 'test.com';
            editctrl.lstAllRootCases[0].Test_Website_Revoked__c = 'test.com';
            editctrl.lstAllRootCases[0].Test_Website_Expired__c = 'test.com';
            editctrl.UpdateRootCases();
            editctrl.lstAllRootCases[0].Test_Website_Valid__c = 'https://comodocertificationauthority-ev.comodoca.com/';
            editctrl.lstAllRootCases[0].Test_Website_Revoked__c = 'https://comodocertificationauthority-ev.comodoca.com:442/';
            editctrl.lstAllRootCases[0].Test_Website_Expired__c = 'https://comodocertificationauthority-ev.comodoca.com:444/';
            editctrl.UpdateRootCases();
        }
    }
}
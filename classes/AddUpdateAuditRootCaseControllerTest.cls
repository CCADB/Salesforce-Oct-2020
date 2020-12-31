/*
    Description: test class for AddUpdateAuditRootCaseController
*/
@isTest
private class AddUpdateAuditRootCaseControllerTest {
    static testmethod void testAuditFileMethod(){ 
        
        Account caOwnerAcc = CaseTriggerHelperTest.getCAOwnerAccount();
        insert caOwnerAcc;
        
        Case caseSO = CaseTriggerHelperTest.getCase(caOwnerAcc.Id);
        caseSO.Standard_Audit_Authenticity_Confirmed__c = True;
        caseSO.BR_Audit_Authenticity_Confirmed__c = True;
        caseSO.EV_Code_Signing_Audit_Auth_Confirmed__c = True;
        caseSO.EV_SSL_Audit_Authenticity_Confirmed__c = True;
        insert caseSO;
        
        // create the child account - record type = Root
        Account childAccount = SyncParentAccountFromCaseControllerTest.getChildAccount(caOwnerAcc.id);
        childAccount.Name = 'child root account 1';
        insert childAccount;
        
        AddUpdateAuditRootCaseController newauditrootcases = new AddUpdateAuditRootCaseController(new apexpages.standardcontroller(caseSO));
        newauditrootcases.NextToRootCase();
        if(newauditrootcases.lstWrapAllRootCases.size() > 0){
            newauditrootcases.lstWrapAllRootCases[0].objRootCase.Apply_Standard_Audit__c = true;
            newauditrootcases.lstWrapAllRootCases[0].isSelected = true;    
        }
        newauditrootcases.NextToRootCase();
    }
}
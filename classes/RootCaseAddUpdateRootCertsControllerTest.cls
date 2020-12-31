/*
    Description: test class for RootCaseAddUpdateRootCertsController
*/
@isTest
private class RootCaseAddUpdateRootCertsControllerTest {
    static testmethod void testAuditFileMethod(){ 
        
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
        childAccount.Status__c = 'Included';
        insert childAccount;
        
        RootCaseAddUpdateRootCertsController newauditrootcases = new RootCaseAddUpdateRootCertsController(new apexpages.standardcontroller(caseSO));
        newauditrootcases.NextToRootCase();
        if(newauditrootcases.lstWrapAllRootCases.size() > 0){
            newauditrootcases.lstWrapAllRootCases[0].objRootCase.Apply_Standard_Audit__c = true;
            newauditrootcases.lstWrapAllRootCases[0].isSelected = true;    
        }
        newauditrootcases.NextToRootCase();
    }
}
/*
    Description: Tes class for Clone case Controller
*/
@isTest
public with sharing class CloneAuditCaseControllerTest {
    
    static testmethod void TestCloneCase(){
        //Account caOwnerAcc = CaseTriggerHelperTest.getCAOwnerAccount();
        Account caOwnerAcc = TestUtils.getCAOwner();
        insert caOwnerAcc;
        
        //Case caseSO = CaseTriggerHelperTest.getCase(caOwnerAcc.Id);
        Case caseSO = TestUtils.getCase(caOwnerAcc.Id);
        caseSO.Standard_Audit_Authenticity_Confirmed__c = True;
        caseSO.BR_Audit_Authenticity_Confirmed__c = True;
        caseSO.EV_Code_Signing_Audit_Auth_Confirmed__c = True;
        caseSO.EV_SSL_Audit_Authenticity_Confirmed__c = True;
        insert caseSO; 
        
        CloneAuditCaseController clonedcase = new CloneAuditCaseController(new Apexpages.standardcontroller(caseSO)); 
        clonedcase.CloneAuditCase();  
    }
}
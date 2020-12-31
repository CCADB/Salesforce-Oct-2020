/*
    Description: Test class for CaseMessageInlinePageController
    
*/
@isTest
public with sharing class CaseMessageInlinePageControllerTest {

    static testMethod void TestCaseCPACanadaURLChanged() {
        Account caOwnerAcc = TestUtils.getCAOwner();
        insert caOwnerAcc;
        
        Case caseSO = TestUtils.getCase(caOwnerAcc.Id);
        caseSO.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('CA Audit Update Request').getRecordTypeId();
        caseSO.Standard_Audit_Statement_Link__c = 'https://www.cpacanada.ca/generichandlers/aptifyattachmenthandler.ashx?attachmentid=221273';
        caseSO.Code_Signing_Audit_Statement_Link__c = 'https://www.cpacanada.ca/generichandlers/aptifyattachmenthandler.ashx?attachmentid=221273';
        caseSO.BR_Audit_Statement_Link__c = 'https://www.cpacanada.ca/generichandlers/aptifyattachmenthandler.ashx?attachmentid=221273';
        caseSO.EV_Audit_Statement_Link__c = 'https://www.cpacanada.ca/generichandlers/aptifyattachmenthandler.ashx?attachmentid=221273';
        caseSO.EV_Code_Signing_Audit_Statement_Link__c = 'https://www.cpacanada.ca/generichandlers/aptifyattachmenthandler.ashx?attachmentid=221273';
        insert caseSO;
        
        CaseMessageInlinePageController controller = new CaseMessageInlinePageController(new Apexpages.standardcontroller(caseSO));
                 
    }
}
/*
    Controller: Created a controller for Case Print View
*/

//public with sharing class PrintViewCaseController {

public class PrintViewCaseController {
  public transient Case objCase { get; set; }

  public transient List<Policy_Document_On_Case__c> lstPolicyDocumentsOnCases {
    get;
    set;
  }
  public transient List<Root_Case__c> lstRootCases { get; set; }

  public PrintViewCaseController(Apexpages.standardcontroller controller) {
    lstPolicyDocumentsOnCases = new List<Policy_Document_On_Case__c>();
    objCase = new Case();
    lstRootCases = new List<Root_Case__c>();
    Id caseid = controller.getId();
    if (
      caseid != null ||
      Apexpages.currentPage().getParameters().get('CaseNumber') != null
    ) {
      string casenumber = string.valueof(
        Apexpages.currentPage().getParameters().get('CaseNumber')
      );
      // get case details
      Map<String, Schema.SObjectField> caseFields = Schema.getGlobalDescribe()
        .get('Case')
        .getDescribe()
        .fields.getMap();
      string strCaseQuery = 'SELECT';
      for (String s : caseFields.keySet()) {
        strCaseQuery += ' ' + s + ',';
      }
      strCaseQuery += ' Case.Account.Name,';
      // Strip off the last comma if it exists.
      if (
        strCaseQuery.subString(
          strCaseQuery.Length() - 1,
          strCaseQuery.Length()
        ) == ','
      ) {
        strCaseQuery = strCaseQuery.subString(0, strCaseQuery.Length() - 1);
      }

      strCaseQuery += ' FROM Case Where Id =: caseid or CaseNumber =: casenumber';
      system.debug('strCaseQuery  :: ' + strCaseQuery);
      List<Case> lstCase = Database.Query(strCaseQuery);
      if (lstCase.size() > 0) {
        objCase = lstCase[0];
        caseid = objCase.Id;
      }

      // get case details
      Map<String, Schema.SObjectField> rootcaseFields = Schema.getGlobalDescribe()
        .get('Root_Case__c')
        .getDescribe()
        .fields.getMap();
      string strRootCaseQuery = 'SELECT';
      for (String s : rootcaseFields.keySet()) {
        strRootCaseQuery += ' ' + s + ',';
      }
      // Strip off the last comma if it exists.
      if (
        strRootCaseQuery.subString(
          strRootCaseQuery.Length() - 1,
          strRootCaseQuery.Length()
        ) == ','
      ) {
        strRootCaseQuery = strRootCaseQuery.subString(
          0,
          strRootCaseQuery.Length() - 1
        );
      }
      strRootCaseQuery += ' FROM Root_Case__c Where Case_No__c =: caseid ';
      system.debug('strRootCaseQuery :: ' + strRootCaseQuery);
      lstRootCases = Database.Query(strRootCaseQuery);

      //fill Policy Document
      lstPolicyDocumentsOnCases = new List<Policy_Document_On_Case__c>(
        [
          SELECT
            Document_Type__c,
            Document_Verified__c,
            Document_Link__c,
            Document_Last_Updated_Date__c,
            Associated_Trust_Bits__c,
            Policy_Identifiers__c,
            Additional_Policy_Identifiers__c,
            Comments__c,
            (
              SELECT
                id,
                Certificate_Name__r.SHA_256_Fingerprint__c,
                Certificate_Name__c,
                Certificate_Name__r.Name
              FROM Policy_Document_Associations__r
              WHERE Action__c != 'Delete'
              ORDER BY Certificate_Name__r.Name
            )
          FROM Policy_Document_On_Case__c
          WHERE Case__c = :caseid AND Action__c != 'Delete'
        ]
      );
    }
  }
}
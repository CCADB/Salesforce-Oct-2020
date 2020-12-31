/*
    Description: Controller is created for AddPolicyDocuments
    
    - create audit case as a root store from CA Owner page or from Case tab
    - default "Instructions" field on Case provides the step
    - Fill Auditor, Audit info and Save
    - Use 'Add/Update Root Cases' button
    - Use 'Update Policy Documents' custom page to try the following:
           1)  Policy Doc records get added to the Case only if the associated root certificates (root cases added in previous step) have the policy doc records  
           2) use the edit button to make changes to the 'CA Document Repository' & 'Policy Documentation', Policy Document & Association sections; observe the warning messages
           3) check or uncheck the checkboxes under Policy Document Associations to add or delete root certs
           4) use the delete or undelete to delete an entire Policy Document section
           5) leave the fields blank to see the warnings
           6) fill an invalid url (incorrect url format) for Document Link, old date for Last Update Date to verify error checking
           7) click on 'Add Policy Document' button to add new policy doc & associations
           8) try the 'Go back' button when you have one or more sections in edit mode
           9) set 'Document Verified?' to 'Data Verified' manually or use the 'Verify All Document' button
           10) hover over 'i' next to the fields to review help text
    - if the policy document records have  'Document Verified?'  = 'Data Verified', you can  try the 'Sync Policy Documents' process
      or you can complete the processes related to Test Websites
    - run ALV
    - default text for Instructions changes
    - default progress bar changes to root store's progress bar on Case page
    - verify data and change the 'Data Verified?' fields to 'Data Verified' or 'Not Applicable'
    - sync Policy Documents
    - sync Audit Info
    - Request Status changes to Complete and Case = Closed
    - Go to the root certificates for which the policy doc was synced and check the Policy Doc custom section
         1) Toggle the 'Show Deleted' button to see/hide the records marked as deleted
         2) Click on 'Id' link to see details of the Policy Doc, it's associated root certs and History
    - Check the History notes
    
 09-14-2020 Updated filter condition to select the Root Certifcates for Policy Doc section
            And Valid_To_GMT__c >= Today
            And (Status__c IN ('Not Yet Included','Included','Change Requested') 
            OR  Microsoft_Status__c IN ('Not Included','Included','Change Requested','Pending','Not Before')) 
*/
public without sharing class AddPolicyDocumentsController {
            public Case objCase { get; set; }
  public boolean isCaseEdit { get; set; }
            public boolean isError { get; set; }
  public boolean isAnyWarning { get; set; }
  public List<wrapAdditionalPolicyDocs> lstwrapAdditionalPolicyDocs {
    get;
    set;
  }
  public List<Account> lstRootCertificates;
  public List<string> lstPolicyIdentifiers { get; set; }
  public boolean isCaseNeedToUpdate = true;
  public wrapAdditionalPolicyDocs wrapPDBeforeSave;

  public AddPolicyDocumentsController(Apexpages.standardController controller) {
    objCase = (Case) controller.getRecord();
    isCaseEdit = false;
    isError = false;
    isAnyWarning = false;
    isCaseNeedToUpdate = false;
    wrapPDBeforeSave = new wrapAdditionalPolicyDocs();
    List<Case> lstCase = new List<Case>(
      [
        SELECT
          Id,
          CaseNumber,
          AccountId,
          Account.Policy_Identifiers__c,
          CA_Document_Repository__c,
          Policy_Documentation__c,
          Request_Status__c,
          IsClosed,
          Account.Document_Repository__c,
          Account.Document_Repository_Description__c,
          (SELECT Id, Root_Certificate_Name_Existing__c FROM Root_Cases__r)
        FROM Case
        WHERE Id = :objCase.Id
      ]
    );
    if (lstCase.size() > 0) {
      objCase = lstCase[0];
      lstRootCertificates = new List<Account>(
        [
          SELECT
            Id,
            Name,
            Status__c,
            Microsoft_Status__c,
            Revocation_Status__c,
            Valid_From_GMT__c,
            Valid_To_GMT__c,
            SHA_256_Fingerprint__c,
            Trust_Bits__c,
            Microsoft_Trust_Bits__c
          FROM Account
          WHERE
            RecordType.Name = 'Root Certificate'
            AND ParentId = :objCase.AccountId
            // AND (Status__c IN ('Included', 'Change Requested')
            // OR Microsoft_Status__c IN ('Included', 'Change Requested'))          
            
            And Valid_To_GMT__c >= Today
            And (Status__c IN ('Not Yet Included','Included','Change Requested') 
            OR  Microsoft_Status__c IN ('Not Included','Included','Change Requested','Pending','Not Before')) 
           
          ORDER BY Name
        ]
      );
      
      
      if (
        objCase.CA_Document_Repository__c == null ||
        string.isblank(objCase.CA_Document_Repository__c)
      ) {
        objCase.CA_Document_Repository__c = objCase.Account.Document_Repository__c;
        isCaseNeedToUpdate = true;
      }
      if (
        objCase.Policy_Documentation__c == null ||
        string.isblank(objCase.Policy_Documentation__c)
      ) {
        objCase.Policy_Documentation__c = objCase.Account.Document_Repository_Description__c;
        isCaseNeedToUpdate = true;
      }
      if (objCase.Root_Cases__r.size() == 0) {
        isError = true;
        ApexPages.Message myMsg = new ApexPages.Message(
          ApexPages.Severity.Error,
          'Please add Root Cases by using the button \'Add/Update Root Cases\' before adding Policy Documents.'
        );
        ApexPages.addMessage(myMsg);
        return;
      }
      lstPolicyIdentifiers = new List<string>();
      if (objCase.Account.Policy_Identifiers__c != null) {
        string[] arrPolicyIdentifiers = objCase.Account.Policy_Identifiers__c.split(
          ';'
        );
        for (string str : arrPolicyIdentifiers) {
          if (string.isnotblank(str)) {
            lstPolicyIdentifiers.add(str.trim());
          }
        }
      }
      lstPolicyIdentifiers.sort();
    }
    //LoadAdditionalPolicyDocs();
  }

  public void CreateAdditionalPolicyDocs() {
    try {
      //if case is closed or request status is compelted then don't create additional policy docs. added on 12th Aug 2020
      if (
        !isError &&
        objCase.Request_Status__c != 'Complete' &&
        !objCase.IsClosed
      ) {
        set<Id> setOfRootCertIds = new Set<Id>();
        for (Root_Case__c rc : objCase.Root_Cases__r) {
          setOfRootCertIds.add(rc.Root_Certificate_Name_Existing__c);
        }
        set<Id> setOfPolicyDocIds = new Set<Id>();
        List<PolicyDocumentAssociation_On_Certificate__c> lstPolicyDocumentAssociations = new List<PolicyDocumentAssociation_On_Certificate__c>(
          [
            SELECT Id, Policy_Document__c
            FROM PolicyDocumentAssociation_On_Certificate__c
            WHERE
              Certificate_Name__c IN :setOfRootCertIds
              AND Is_Deleted__c = FALSE
          ]
        );
        for (
          PolicyDocumentAssociation_On_Certificate__c PDA : lstPolicyDocumentAssociations
        ) {
          setOfPolicyDocIds.add(PDA.Policy_Document__c);
        }

        //check existing policy documents on case
        map<Id, set<Id>> mapExistingPolicyDocumentIds = new Map<Id, set<Id>>();
        map<Id, Policy_Document_On_Case__c> mapExistingPolicyDocument = new Map<Id, Policy_Document_On_Case__c>();
        for (Policy_Document_On_Case__c PDC : [
          SELECT
            Id,
            Source_Policy_Doc_Id__c,
            (
              SELECT Id, Certificate_Name__c, Source_Policy_Doc_Assoc_Id__c
              FROM Policy_Document_Associations__r
              WHERE Source_Policy_Doc_Assoc_Id__c != NULL
            )
          FROM Policy_Document_On_Case__c
          WHERE Case__c = :objCase.Id AND Source_Policy_Doc_Id__c != NULL
        ]) {
          set<Id> setOfPolicyAssIds = new Set<Id>();
          for (
            Policy_Document_Association_On_Case__c PDAC : PDC.Policy_Document_Associations__r
          ) {
            setOfPolicyAssIds.add(PDAC.Source_Policy_Doc_Assoc_Id__c);
          }
          mapExistingPolicyDocumentIds.put(
            PDC.Source_Policy_Doc_Id__c,
            setOfPolicyAssIds
          );
          mapExistingPolicyDocument.put(PDC.Source_Policy_Doc_Id__c, PDC);
        }

        map<Integer, Policy_Document_On_Case__c> mapPolicyDocumentsOnCase = new Map<Integer, Policy_Document_On_Case__c>();
        map<Integer, List<Policy_Document_Association_On_Case__c>> mapPolicyDocumentsAssociations = new Map<Integer, List<Policy_Document_Association_On_Case__c>>();
        Integer index = 0;
        for (Policy_Document_On_Certificate__c PDC : [
          SELECT
            Id,
            Name,
            Associated_Trust_Bits__c,
            Comments__c,
            Document_Last_Updated_Date__c,
            Document_Link__c,
            Document_Type__c,
            Policy_Identifiers__c,
            (
              SELECT Id, Name, Certificate_Name__c, Policy_Document__c
              FROM Policy_Document_Associations__r
              WHERE Is_Deleted__c = FALSE
            )
          FROM Policy_Document_On_Certificate__c
          WHERE Id = :setOfPolicyDocIds AND Is_Deleted__c = FALSE
        ]) {
          Policy_Document_On_Case__c PDCase = new Policy_Document_On_Case__c();
          if (!mapExistingPolicyDocumentIds.containskey(PDC.Id)) {
            PDCase.Case__c = objCase.Id;
            PDCase.Associated_Trust_Bits__c = PDC.Associated_Trust_Bits__c;
            PDCase.Comments__c = PDC.Comments__c;
            PDCase.Document_Last_Updated_Date__c = PDC.Document_Last_Updated_Date__c;
            PDCase.Document_Link__c = PDC.Document_Link__c;
            PDCase.Document_Type__c = PDC.Document_Type__c;
            PDCase.Policy_Identifiers__c = PDC.Policy_Identifiers__c;
            PDCase.Source_Policy_Doc_Id__c = PDC.Id;
            PDCase.Action__c = 'Update';
          } else if (mapExistingPolicyDocument.containskey(PDC.Id)) {
            PDCase = mapExistingPolicyDocument.get(PDC.Id);
          }

          mapPolicyDocumentsOnCase.put(index, PDCase);

          List<Policy_Document_Association_On_Case__c> lstPolicyDocs = new List<Policy_Document_Association_On_Case__c>();
          set<Id> setOfPolicyAssociationIds = mapExistingPolicyDocumentIds.containskey(
              PDC.Id
            )
            ? mapExistingPolicyDocumentIds.get(PDC.Id)
            : new Set<Id>();
          for (
            PolicyDocumentAssociation_On_Certificate__c PDA : PDC.Policy_Document_Associations__r
          ) {
            if (!setOfPolicyAssociationIds.contains(PDA.Id)) {
              Policy_Document_Association_On_Case__c PDAssociation = new Policy_Document_Association_On_Case__c();
              PDAssociation.Case__c = objCase.Id;
              PDAssociation.Certificate_Name__c = PDA.Certificate_Name__c;
              PDAssociation.Source_Policy_Doc_Assoc_Id__c = PDA.Id;
              PDAssociation.Action__c = 'Update';
              lstPolicyDocs.add(PDAssociation);
            }
          }
          mapPolicyDocumentsAssociations.put(index, lstPolicyDocs);
          index++;
        }

        //added on 27/08/2020 to check all policy documents are verified or not
        // If all policy documents are verified then do not create new policy documents from root certificate
        Boolean checkAllPolicyDocumentIsVerified = true;
        set<string> setofVerifiedStatus = new set<string>{'Data Verified','System Verified','Complete'};
        List<Policy_Document_On_Case__c> lstPolicyDocsOnCase = new List<Policy_Document_On_Case__c>([
          SELECT id, Document_Verified__c
          FROM Policy_Document_On_Case__c
          WHERE
            Case__c = :objCase.Id AND
            Action__c != 'Delete'
        ]);
        for (Policy_Document_On_Case__c objPDOC : lstPolicyDocsOnCase) {
          if(!setofVerifiedStatus.contains(objPDOC.Document_Verified__c)){  
              checkAllPolicyDocumentIsVerified = false; break;
          }
        }
        //if no policy documents on case then set as false to create a new policy documents.
        if(lstPolicyDocsOnCase.size() == 0) checkAllPolicyDocumentIsVerified = false; 
        //end  on 27/08/2020 to check all policy documents are verified or not

        if (
          mapPolicyDocumentsOnCase.size() > 0 &&
          !checkAllPolicyDocumentIsVerified
        ) {
          upsert mapPolicyDocumentsOnCase.values();
          List<Policy_Document_Association_On_Case__c> lstPolicyAssociationDocsToInsert = new List<Policy_Document_Association_On_Case__c>();
          for (Integer count : mapPolicyDocumentsAssociations.keyset()) {
            if (mapPolicyDocumentsOnCase.containskey(count)) {
              Policy_Document_On_Case__c pdc = mapPolicyDocumentsOnCase.get(
                count
              );
              for (
                Policy_Document_Association_On_Case__c pdac : mapPolicyDocumentsAssociations.get(
                  count
                )
              ) {
                pdac.Policy_Document__c = pdc.Id;
                lstPolicyAssociationDocsToInsert.add(pdac);
              }
            }
          }
          insert lstPolicyAssociationDocsToInsert;
        }
        //commented this condition because we wanted to update instructions
        if (isCaseNeedToUpdate) {
          update objCase;
        }
      }
      LoadAdditionalPolicyDocs();
    } catch (Exception ex) {
      Apexpages.addMessages(Ex);
    }
  }

  public void AutoUpdateRequestStatus() {
    try {
      List<Policy_Document_On_Case__c> lstPolicyDocumentsUpdate = new List<Policy_Document_On_Case__c>();
      boolean isAnySucceedData = false;
      for (wrapAdditionalPolicyDocs policydoc : lstwrapAdditionalPolicyDocs) {
        boolean isAnyMissingData = false;
        if (policydoc.additionalPolicyDoc.Id != null) {
          string DocumentVerified = policydoc.additionalPolicyDoc.Document_Verified__c;
          if (
            policydoc.additionalPolicyDoc.Document_Verified__c !=
            'Data Verified' &&
            policydoc.additionalPolicyDoc.Document_Verified__c != 'Complete'
          ) {
            if (
              policydoc.additionalPolicyDoc.Document_Type__c != null &&
              policydoc.additionalPolicyDoc.Document_Link__c != null &&
              policydoc.additionalPolicyDoc.Document_Last_Updated_Date__c !=
              null &&
              policydoc.additionalPolicyDoc.Associated_Trust_Bits__c != null
            ) {
              policydoc.additionalPolicyDoc.Document_Verified__c = 'System Verified';
              isAnySucceedData = true;
              lstPolicyDocumentsUpdate.add(policydoc.additionalPolicyDoc);
            } else {
              isAnyMissingData = true;
            }
          }
          boolean isAnyAssociationRecord = false;
          for (
            Policy_Document_Association_On_Case__c PDAC : policydoc.additionalPolicyDoc.Policy_Document_Associations__r
          ) {
            if (PDAC.Action__c != 'Delete') {
              isAnyAssociationRecord = true;
            }
          }
          if (!isAnyAssociationRecord) {
            isAnySucceedData = false;
            policydoc.additionalPolicyDoc.Document_Verified__c = DocumentVerified;
            ApexPages.Message myMsg = new ApexPages.Message(
              ApexPages.Severity.ERROR,
              'One or more Policy Document is missing associated root certificates. Scroll to see each section.'
            );
            ApexPages.addMessage(myMsg);
            //return;
          }
          if (isAnyMissingData) {
            policydoc.additionalPolicyDoc.Document_Verified__c = DocumentVerified;
            ApexPages.Message myMsg = new ApexPages.Message(
              ApexPages.Severity.ERROR,
              'One or more Policy Document is missing data. Scroll to see each section.'
            );
            ApexPages.addMessage(myMsg);
            //return;
          }
        }
      }

      if (lstPolicyDocumentsUpdate.size() > 0 && isAnySucceedData) {
        update lstPolicyDocumentsUpdate;
      }
      LoadAdditionalPolicyDocs();
      if (isAnySucceedData) {
        ApexPages.Message myMsg = new ApexPages.Message(
          ApexPages.Severity.CONFIRM,
          'Auto updated Request Status to "System Verified".'
        );
        ApexPages.addMessage(myMsg);
      }
    } catch (Exception ex) {
      Apexpages.addMessages(ex);
    }
  }

  public void LoadAdditionalPolicyDocs() {
    try {
      lstwrapAdditionalPolicyDocs = new List<wrapAdditionalPolicyDocs>();

      List<Policy_Document_On_Case__c> lstAdditionalPolicyDocs = new List<Policy_Document_On_Case__c>(
        [
          SELECT
            Id,
            Name,
            Associated_Trust_Bits__c,
            Comments__c,
            Document_Last_Updated_Date__c,
            Document_Verified__c,
            Document_Link__c,
            Document_Type__c,
            Policy_Identifiers__c,
            Action__c,
            Source_Policy_Doc_Id__c,
            Additional_Policy_Identifiers__c,
            (
              SELECT
                Id,
                Name,
                Certificate_Name__c,
                Case__c,
                Policy_Document__c,
                Action__c,
                Source_Policy_Doc_Assoc_Id__c
              FROM Policy_Document_Associations__r
            )
          FROM Policy_Document_On_Case__c
          WHERE Case__c = :objCase.Id
          ORDER BY Document_Last_Updated_Date__c DESC
        ]
      );

      //fill map of id with existing Ids. key as Certificate id and value as record
      map<string, Policy_Document_Association_On_Case__c> mapOfApplyPolicyDocs = new Map<string, Policy_Document_Association_On_Case__c>();
      for (Policy_Document_On_Case__c Policy : lstAdditionalPolicyDocs) {
        for (
          Policy_Document_Association_On_Case__c applyPolicy : Policy.Policy_Document_Associations__r
        ) {
          string strKey = Policy.ID + '#' + applyPolicy.Certificate_Name__c;
          mapOfApplyPolicyDocs.put(strKey, applyPolicy);
        }
      }
      //system.debug('mapOfApplyPolicyDocs ::: '+mapOfApplyPolicyDocs);
      //fill wrapper with all root cases
      for (Policy_Document_On_Case__c Policydoc : lstAdditionalPolicyDocs) {
        wrapAdditionalPolicyDocs wrapPolicyDoc = new wrapAdditionalPolicyDocs();
        wrapPolicyDoc.additionalPolicyDoc = Policydoc;
        boolean isEmpty = false;
        string strWarningsAll = '';
        //check for warnings.
        if (string.isblank(Policydoc.Document_Type__c)) {
          strWarningsAll += 'Document Type is blank. Must populate this field.<br />';
          isEmpty = true;
        }
        if (string.isblank(Policydoc.Document_Link__c)) {
          strWarningsAll += 'Document Link is blank. Must populate this field.<br />';
          isEmpty = true;
        } /*else {
                    if(!isValidPDFFile(Policydoc.Document_Link__c)){
                        strWarningsAll += 'Please provide valid Document Link. <br />';
                        isEmpty = true;
                    }
                }*/
        if (Policydoc.Document_Last_Updated_Date__c == null) {
          strWarningsAll += 'Document Last Updated Date is blank. Must populate this field.<br />';
          isEmpty = true;
        }
        if (string.isblank(Policydoc.Associated_Trust_Bits__c)) {
          strWarningsAll += 'Associated Trust Bits is blank. Must populate this field.<br />';
          isEmpty = true;
        }
        if (
          string.isblank(Policydoc.Policy_Identifiers__c) &&
          string.isblank(Policydoc.Additional_Policy_Identifiers__c)
        ) {
          strWarningsAll += 'Policy Identifiers is blank. Must populate this field.<br />';
          isEmpty = true;
        }
        if (
          PolicyDoc.Document_Last_Updated_Date__c != null &&
          PolicyDoc.Document_Last_Updated_Date__c < system.today().addYears(-1)
        ) {
          strWarningsAll += 'Document Last Updated Date is older than one year. <br />';
          isEmpty = true;
        }
        if (Policydoc.Additional_Policy_Identifiers__c != null) {
          string[] arrPIs = Policydoc.Additional_Policy_Identifiers__c.split(
            ';'
          );
          for (string PI : arrPIs) {
            if (string.isnotblank(PI)) {
              PI = PI.trim();
              //pattern to validate number and dot
              Pattern patt = Pattern.compile('^\\d+(\\.\\d+)*$');
              if (!patt.matcher(PI).matches()) {
                strWarningsAll += 'Additional Policy Identifiers must only contain numbers and periods, and be separated by semicolons. For example: 2.23.140.1.2; 2.23.140.1.1<br/>';
                isEmpty = true;
              }
              if (lstPolicyIdentifiers.contains(PI)) {
                strWarningsAll +=
                  'Duplicate value added to Additional Policy Identifiers: ' +
                  PI +
                  '<br/>';
                isEmpty = true;
              }
            }
          }
        }
        if (PolicyDoc.Policy_Document_Associations__r.size() == 0) {
          strWarningsAll += 'No Root Certificates Associated. <br />';
          isEmpty = true;
        }
        string strWarningsIAll = '';

        if (isEmpty) {
          strWarningsIAll +=
            '<span style="font-weight:bold;">Warning(s)</span><br/>' +
            strWarningsAll;
        }
        if (string.isnotblank(strWarningsIAll)) {
          isAnyWarning = true;
        }
        List<wrapApplyPolicyDocs> lstTempApplyPolicyDocs = new List<wrapApplyPolicyDocs>();
        Integer count = 0;
        for (Account objRoot : lstRootCertificates) {
          string Key = Policydoc.Id + '#' + objRoot.Id;
          system.debug('Key  ::: ' + Key);
          if (mapOfApplyPolicyDocs.containskey(Key)) {
            Policy_Document_Association_On_Case__c PDAC = mapOfApplyPolicyDocs.get(
              Key
            );
            boolean isSelected = true;
            if (PDAC.Action__c == 'Delete') {
              isSelected = false;
            } else {
              count++;
            }
            lstTempApplyPolicyDocs.add(
              new wrapApplyPolicyDocs(
                isSelected,
                objRoot,
                mapOfApplyPolicyDocs.get(Key)
              )
            );
          } else {
            lstTempApplyPolicyDocs.add(
              new wrapApplyPolicyDocs(
                false,
                objRoot,
                new Policy_Document_Association_On_Case__c(
                  Certificate_Name__c = objRoot.Id,
                  Policy_Document__c = Policydoc.Id,
                  Case__c = objCase.Id
                )
              )
            );
          }
        }
        if (
          Policydoc.Policy_Identifiers__c != null &&
          string.isnotblank(Policydoc.Policy_Identifiers__c)
        ) {
          List<string> lstAllPI = Policydoc.Policy_Identifiers__c.split(';');
          if (lstAllPI.size() > 0) {
            lstAllPI.sort();
            wrapPolicyDoc.lstdocPolicyIdentifiers = lstAllPI;
          }
        }
        wrapPolicyDoc.strWarnings = strWarningsIAll;
        wrapPolicyDoc.countRootCerts = count;
        wrapPolicyDoc.lstApplyPolicyDocs = lstTempApplyPolicyDocs;
        lstwrapAdditionalPolicyDocs.add(wrapPolicyDoc);
      }
    } catch (Exception ex) {
      Apexpages.addMessages(ex);
    }
  }

  public void EditCase() {
    isCaseEdit = true;
  }

  public void ClearCase() {
    isCaseEdit = false;
  }

  public void SaveCase() {
    try {
      if (objCase.CA_Document_Repository__c != null) {
        objCase.CA_Document_Repository__c = objCase.CA_Document_Repository__c.replace(
          ',',
          ';'
        );
      }
      update objCase;
      isCaseEdit = false;
      ApexPages.Message myMsg = new ApexPages.Message(
        ApexPages.Severity.CONFIRM,
        'Changes Saved Sucessfully.'
      );
      ApexPages.addMessage(myMsg);
    } catch (Exception ex) {
      Apexpages.addMessages(ex);
    }
  }

  public void CancelPolicyDoc() {
    try {
      if (
        Apexpages.currentpage().getParameters().get('index') != null &&
        Apexpages.currentpage().getParameters().get('index') != ''
      ) {
        Integer index = Integer.valueof(
          Apexpages.currentpage().getParameters().get('index')
        );
        if (lstwrapAdditionalPolicyDocs.size() > index) {
          if (wrapPDBeforeSave != null) {
            lstwrapAdditionalPolicyDocs[index] = wrapPDBeforeSave;
          }
          lstwrapAdditionalPolicyDocs[index].isEdit = false;
        }
      }
    } catch (Exception ex) {
      Apexpages.addMessages(ex);
    }
  }

  public void EditPolicyDoc() {
    try {
      if (
        Apexpages.currentpage().getParameters().get('editindex') != null &&
        Apexpages.currentpage().getParameters().get('editindex') != ''
      ) {
        Integer editIndex = Integer.valueof(
          Apexpages.currentpage().getParameters().get('editindex')
        );
        if (lstwrapAdditionalPolicyDocs.size() > editIndex) {
          wrapPDBeforeSave = new wrapAdditionalPolicyDocs();
          wrapPDBeforeSave = (wrapAdditionalPolicyDocs) JSON.deserialize(
            JSON.serialize(lstwrapAdditionalPolicyDocs[editIndex]),
            wrapAdditionalPolicyDocs.class
          );
          lstwrapAdditionalPolicyDocs[editIndex].isEdit = true;
        }
      }
    } catch (Exception ex) {
      Apexpages.addMessages(ex);
    }
  }

  public void DeletePolicyDoc() {
    try {
      if (Apexpages.currentpage().getParameters().get('deleteindex') != null) {
        Integer deleteindex = Integer.valueof(
          Apexpages.currentpage().getParameters().get('deleteindex')
        );
        if (lstwrapAdditionalPolicyDocs.size() > deleteindex) {
          if (
            lstwrapAdditionalPolicyDocs[deleteindex].additionalPolicyDoc.Id !=
            null
          ) {
            set<string> setOfStages = new Set<String>{
              'Data Verified',
              'System Verified',
              'Complete'
            };
            if (
              setOfStages.contains(
                lstwrapAdditionalPolicyDocs[deleteindex]
                  .additionalPolicyDoc.Document_Verified__c
              )
            ) {
              ApexPages.Message myMsg = new ApexPages.Message(
                ApexPages.Severity.Error,
                'Policy Doc is already Verified/Complete, You cannot delete it.'
              );
              ApexPages.addMessage(myMsg);
              return;
            }

            //delete lstwrapAdditionalPolicyDocs[deleteindex].additionalPolicyDoc;
            if (
              lstwrapAdditionalPolicyDocs[deleteindex]
                .additionalPolicyDoc.Action__c == 'Delete'
            ) {
              lstwrapAdditionalPolicyDocs[deleteindex]
                .additionalPolicyDoc.Action__c = 'Update';
            } else {
              if (
                string.isblank(
                  lstwrapAdditionalPolicyDocs[deleteindex]
                    .additionalPolicyDoc.Source_Policy_Doc_Id__c
                )
              ) {
                lstwrapAdditionalPolicyDocs[deleteindex]
                  .additionalPolicyDoc.Document_Verified__c = 'Complete';
              }
              lstwrapAdditionalPolicyDocs[deleteindex]
                .additionalPolicyDoc.Action__c = 'Delete';
            }
            update lstwrapAdditionalPolicyDocs[deleteindex].additionalPolicyDoc;
            //mark delete policy document on root certificates
            /*if(lstwrapAdditionalPolicyDocs[deleteindex].additionalPolicyDoc.Source_Policy_Doc_Id__c != null) {
                            List<Policy_Document_On_Certificate__c> lstPolicyDocRootCertificate = new List<Policy_Document_On_Certificate__c>([Select Id,
                                Is_Deleted__c, Associated_Trust_Bits__c , Comments__c , Document_Last_Updated_Date__c , Document_Link__c ,
                                Document_Type__c , Policy_Identifiers__c from Policy_Document_On_Certificate__c 
                                Where Id =: lstwrapAdditionalPolicyDocs[deleteindex].additionalPolicyDoc.Source_Policy_Doc_Id__c
                                and Is_Deleted__c = false]);
                            if(lstPolicyDocRootCertificate.size() > 0){
                                lstPolicyDocRootCertificate[0].Is_Deleted__c = true;
                                //lstPolicyDocRootCertificate[0].Associated_Trust_Bits__c = '';
                                //lstPolicyDocRootCertificate[0].Comments__c = '';
                                //lstPolicyDocRootCertificate[0].Document_Last_Updated_Date__c = null;
                                //lstPolicyDocRootCertificate[0].Document_Link__c = '';
                                //lstPolicyDocRootCertificate[0].Document_Type__c = '';
                                //lstPolicyDocRootCertificate[0].Policy_Identifiers__c = '';
                                //create history record
                                string NotesForChangedFields = '*Synced From Case Number: '+objCase.CaseNumber+'*\n';
                                NotesForChangedFields += 'Sync Action Performed: Deleted from Case';
                                if(lstPolicyDocRootCertificate[0].Document_Link__c != null){
                                    NotesForChangedFields += 'Updated Document Link from '+lstPolicyDocRootCertificate[0].Document_Link__c + ' to null.\n';
                                }
                                if(lstPolicyDocRootCertificate[0].Document_Type__c != null){
                                    NotesForChangedFields += 'Updated Document Type from '+lstPolicyDocRootCertificate[0].Document_Type__c + ' to null.\n';
                                }
                                if(lstPolicyDocRootCertificate[0].Document_Last_Updated_Date__c != null){
                                    string certlastupdatedate = 'null';
                                    if(lstPolicyDocRootCertificate[0].Document_Last_Updated_Date__c != null) {
                                        certlastupdatedate = Datetime.newInstance(lstPolicyDocRootCertificate[0].Document_Last_Updated_Date__c, Time.newInstance(0, 0,0, 0)).format('MM/dd/YYYY');
                                    }
                                    NotesForChangedFields += 'Updated Document Last Updated Date from '+certlastupdatedate  + ' to null.\n';
                                }
                                if(lstPolicyDocRootCertificate[0].Associated_Trust_Bits__c != null){
                                    NotesForChangedFields += 'Updated Associated Trust Bits from '+lstPolicyDocRootCertificate[0].Associated_Trust_Bits__c + ' to null.\n';
                                }   
                                if(lstPolicyDocRootCertificate[0].Policy_Identifiers__c != null){
                                    NotesForChangedFields += 'Updated Policy Identifier from '+lstPolicyDocRootCertificate[0].Policy_Identifiers__c + ' to null.\n';
                                } 
                                if(lstPolicyDocRootCertificate[0].Comments__c != null){
                                    NotesForChangedFields += 'Updated Comments from '+lstPolicyDocRootCertificate[0].Comments__c + ' to null.\n';
                                }
                                update lstPolicyDocRootCertificate[0]; 
                                
                                Policy_Document_History__c PDH = new Policy_Document_History__c(Policy_Document__c = lstPolicyDocRootCertificate[0].Id, Notes__c = NotesForChangedFields);
                                insert PDH;
                            }
                        }*/
          }
          //lstwrapAdditionalPolicyDocs.remove(deleteindex);
        }
      }
    } catch (Exception ex) {
      Apexpages.addMessages(ex);
    }
  }

  public void SavePolicyDoc() {
    SavePoint sp = Database.setSavepoint();
    try {
      if (
        Apexpages.currentpage().getParameters().get('index') != null &&
        Apexpages.currentpage().getParameters().get('index') != ''
      ) {
        Integer index = Integer.valueof(
          Apexpages.currentpage().getParameters().get('index')
        );
        if (lstwrapAdditionalPolicyDocs.size() > index) {
          wrapAdditionalPolicyDocs wrapPolicy = lstwrapAdditionalPolicyDocs[
            index
          ];
          List<Policy_Document_Association_On_Case__c> lstApplyPolicy = new List<Policy_Document_Association_On_Case__c>();
          set<Id> setOfPolicyAssIdsToDelete = new Set<Id>();
          boolean isAnyAssociationSelected = false;
          List<Policy_Document_On_Case__c> lstPDCase = new List<Policy_Document_On_Case__c>(
            [
              SELECT
                Id,
                Document_Verified__c,
                Document_Type__c,
                Document_Last_Updated_Date__c,
                Associated_Trust_Bits__c,
                Policy_Identifiers__c,
                Additional_Policy_Identifiers__c,
                Comments__c,
                Document_Link__c
              FROM Policy_Document_On_Case__c
              WHERE Id = :wrapPolicy.additionalPolicyDoc.Id
            ]
          );
          string DocVerified = lstPDCase.size() > 0
            ? lstPDCase[0].Document_Verified__c
            : '';
          boolean isAssociationUpdated = false;
          for (
            wrapApplyPolicyDocs applyPolicy : wrapPolicy.lstApplyPolicyDocs
          ) {
            if (applyPolicy.isSelected) {
              isAnyAssociationSelected = true;
              if (
                applyPolicy.objApplyPolicyDoc.Certificate_Name__c == null &&
                applyPolicy.objAcc.Id != null
              ) {
                applyPolicy.objApplyPolicyDoc.Certificate_Name__c = applyPolicy.objAcc.Id;
              }
              if (applyPolicy.objApplyPolicyDoc.Case__c == null) {
                applyPolicy.objApplyPolicyDoc.Case__c = objCase.Id;
              }
              if (applyPolicy.objApplyPolicyDoc.Action__c == 'Delete') {
                applyPolicy.objApplyPolicyDoc.Action__c = 'Create';
                isAssociationUpdated = true;
              }
              if (applyPolicy.objApplyPolicyDoc.Id == null) {
                isAssociationUpdated = true;
              }
              lstApplyPolicy.add(applyPolicy.objApplyPolicyDoc);
            } else if (applyPolicy.objApplyPolicyDoc.Id != null) {
              applyPolicy.objApplyPolicyDoc.Action__c = 'Delete';
              isAssociationUpdated = true;
              lstApplyPolicy.add(applyPolicy.objApplyPolicyDoc);
              /*if(applyPolicy.objApplyPolicyDoc.Source_Policy_Doc_Assoc_Id__c != null) {
                                setOfPolicyAssIdsToDelete.add(applyPolicy.objApplyPolicyDoc.Source_Policy_Doc_Assoc_Id__c);
                            }*/
              //lstApplyPolicyDelete.add(applyPolicy.objApplyPolicyDoc);
            }
          }
          if (
            (wrapPolicy.additionalPolicyDoc.Document_Verified__c ==
            'Data Verified' ||
            wrapPolicy.additionalPolicyDoc.Document_Verified__c ==
            'System Verified') && !isAnyAssociationSelected
          ) {
            //ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR, 'One or more Policy Document is missing associated root certificates. Scroll to see each section.');
            ApexPages.Message myMsg = new ApexPages.Message(
              ApexPages.Severity.ERROR,
              'Cannot set Request Status to Data Verified or System Verified for Policy Doc ' +
              (wrapPolicy.additionalPolicyDoc.Id != null
                ? wrapPolicy.additionalPolicyDoc.Name
                : 'New') +
              ' with No associated Root Certs.'
            );
            ApexPages.addMessage(myMsg);
            return;
          }
          //update state to Not Verified when update policy doc - changed on 30th July
          if (
            (DocVerified == 'Data Verified' ||
            DocVerified == 'System Verified')
          ) {
            if (
              lstPDCase[0].Document_Type__c !=
              wrapPolicy.additionalPolicyDoc.Document_Type__c ||
              lstPDCase[0].Document_Link__c !=
              wrapPolicy.additionalPolicyDoc.Document_Link__c ||
              lstPDCase[0].Document_Last_Updated_Date__c !=
              wrapPolicy.additionalPolicyDoc.Document_Last_Updated_Date__c ||
              lstPDCase[0].Associated_Trust_Bits__c !=
              wrapPolicy.additionalPolicyDoc.Associated_Trust_Bits__c ||
              lstPDCase[0].Policy_Identifiers__c !=
              wrapPolicy.additionalPolicyDoc.Policy_Identifiers__c ||
              lstPDCase[0].Additional_Policy_Identifiers__c !=
              wrapPolicy.additionalPolicyDoc.Additional_Policy_Identifiers__c ||
              lstPDCase[0].Comments__c !=
              wrapPolicy.additionalPolicyDoc.Comments__c ||
              isAssociationUpdated
            ) {
              wrapPolicy.additionalPolicyDoc.Document_Verified__c = 'Not Verified';
            }
          }
          string ErrorMessage = 'Invalid Document link, URL must begin with \'https\' and can only contain letters, numbers and following characters: + & @ # / % ? = ~- _ | ! : , . ; [ ] ( ) ';
          Pattern httpPattern = Pattern.compile(
            '^[hH][tT][tT][pP][0-9A-Za-z+&@#/%?=~\\-_|!:,.;\\[\\]()]*$'
          );

          if (
            wrapPolicy.additionalPolicyDoc.Document_Link__c != null &&
            !httpPattern.matcher(
                wrapPolicy.additionalPolicyDoc.Document_Link__c
              )
              .matches()
          ) {
            if (wrapPolicy.strWarnings.contains('Document Link is Blank.')) {
              wrapPolicy.strWarnings = wrapPolicy.strWarnings.replace(
                'Document Link is Blank.',
                ErrorMessage
              );
            } else if (!wrapPolicy.strWarnings.contains(ErrorMessage)) {
              wrapPolicy.strWarnings += ErrorMessage;
            }
            ApexPages.Message myMsg = new ApexPages.Message(
              ApexPages.Severity.ERROR,
              ErrorMessage
            );
            ApexPages.addMessage(myMsg);
            return;
          }
          if (
            wrapPolicy.additionalPolicyDoc.Additional_Policy_Identifiers__c !=
            null
          ) {
            wrapPolicy.additionalPolicyDoc.Additional_Policy_Identifiers__c = wrapPolicy.additionalPolicyDoc.Additional_Policy_Identifiers__c.replace(
              ',',
              ';'
            );
          }
          upsert wrapPolicy.additionalPolicyDoc;

          //mark association records delete on root cert associations.
          /*if(setOfPolicyAssIdsToDelete.size() > 0){
                        List<PolicyDocumentAssociation_On_Certificate__c> lstPolicyDocumentAssociations = new List<PolicyDocumentAssociation_On_Certificate__c>([select Id, 
                                Policy_Document__c, Certificate_Name__c, Certificate_Name__r.Name, Certificate_Name__r.SHA_256_Fingerprint__c,
                                Source_Policy_Doc_Assoc_Id__c
                                from PolicyDocumentAssociation_On_Certificate__c Where Id in: setOfPolicyAssIdsToDelete]);
                        string NotesForDeletedAssociation = '*Synced From Case Number: '+objCase.CaseNumber+'*\nSync Action Performed: Deleted\n Associations Deleted: \n';
                        Id PolicyDocumentId;      
                        for(PolicyDocumentAssociation_On_Certificate__c PDA: lstPolicyDocumentAssociations){
                            NotesForDeletedAssociation += '- '+ PDA.Certificate_Name__r.Name + ' (SHA-256: '+PDA.Certificate_Name__r.SHA_256_Fingerprint__c +').\n';
                            PolicyDocumentId = PDA.Policy_Document__c;
                        }
                        delete lstPolicyDocumentAssociations;
                        //create history record
                        Policy_Document_History__c PDH = new Policy_Document_History__c(Policy_Document__c = PolicyDocumentId, Notes__c = NotesForDeletedAssociation);
                        insert PDH;
                    }*/

          if (lstApplyPolicy.size() > 0) {
            for (Policy_Document_Association_On_Case__c pda : lstApplyPolicy) {
              if (pda.Policy_Document__c == null) {
                pda.Policy_Document__c = wrapPolicy.additionalPolicyDoc.Id;
              }
              if (pda.Id == null || pda.Action__c == null) {
                pda.Action__c = 'Create';
              }
            }
            upsert lstApplyPolicy;
          }

          List<Policy_Document_On_Case__c> lstAdditionalPolicyDocs = new List<Policy_Document_On_Case__c>(
            [
              SELECT
                Id,
                Name,
                Associated_Trust_Bits__c,
                Comments__c,
                Document_Last_Updated_Date__c,
                Document_Verified__c,
                Document_Link__c,
                Document_Type__c,
                Policy_Identifiers__c,
                Action__c,
                Source_Policy_Doc_Id__c,
                Additional_Policy_Identifiers__c,
                (
                  SELECT
                    Id,
                    Name,
                    Certificate_Name__c,
                    Case__c,
                    Policy_Document__c,
                    Action__c
                  FROM Policy_Document_Associations__r
                )
              FROM Policy_Document_On_Case__c
              WHERE Id = :wrapPolicy.additionalPolicyDoc.Id
            ]
          );
          //fill map of id with existing Ids. key as Certificate id and value as record
          map<string, Policy_Document_Association_On_Case__c> mapOfApplyPolicyDocs = new Map<string, Policy_Document_Association_On_Case__c>();
          for (Policy_Document_On_Case__c Policy : lstAdditionalPolicyDocs) {
            for (
              Policy_Document_Association_On_Case__c applyPolicy : Policy.Policy_Document_Associations__r
            ) {
              string strKey = Policy.ID + '#' + applyPolicy.Certificate_Name__c;
              mapOfApplyPolicyDocs.put(strKey, applyPolicy);
            }
          }
          //fill wrapper with all root cases
          for (Policy_Document_On_Case__c Policydoc : lstAdditionalPolicyDocs) {
            wrapAdditionalPolicyDocs wrapPolicyDoc = new wrapAdditionalPolicyDocs();
            wrapPolicyDoc.additionalPolicyDoc = Policydoc;
            boolean isEmpty = false;
            string strWarningsAll = '';
            //check for warnings.
            if (string.isblank(Policydoc.Document_Type__c)) {
              strWarningsAll += 'Document Type is blank. Must populate this field.<br />';
              isEmpty = true;
            }
            if (string.isblank(Policydoc.Document_Link__c)) {
              strWarningsAll += 'Document Link is blank. Must populate this field.<br />';
              isEmpty = true;
            } /*else {
                            if(!isValidPDFFile(Policydoc.Document_Link__c)){
                                strWarningsAll += 'Please provide valid Document Link. <br />';
                                isEmpty = true;
                            }
                        }*/
            if (Policydoc.Document_Last_Updated_Date__c == null) {
              strWarningsAll += 'Document Last Updated Date is blank. Must populate this field.<br />';
              isEmpty = true;
            }
            if (string.isblank(Policydoc.Associated_Trust_Bits__c)) {
              strWarningsAll += 'Associated Trust Bits is blank. Must populate this field.<br />';
              isEmpty = true;
            }
            if (
              string.isblank(Policydoc.Policy_Identifiers__c) &&
              string.isblank(Policydoc.Additional_Policy_Identifiers__c)
            ) {
              strWarningsAll += 'Policy Identifiers is blank. Must populate this field.<br />';
              isEmpty = true;
            }
            if (
              PolicyDoc.Document_Last_Updated_Date__c != null &&
              PolicyDoc.Document_Last_Updated_Date__c <
              system.today().addYears(-1)
            ) {
              strWarningsAll += 'Document Last Updated Date is older than one year. <br />';
              isEmpty = true;
            }
            if (Policydoc.Additional_Policy_Identifiers__c != null) {
              string[] arrPIs = Policydoc.Additional_Policy_Identifiers__c.split(
                ';'
              );
              for (string PI : arrPIs) {
                if (string.isnotblank(PI)) {
                  PI = PI.trim();
                  //pattern to validate number and dot
                  Pattern patt = Pattern.compile('^\\d+(\\.\\d+)*$');
                  if (!patt.matcher(PI).matches()) {
                    strWarningsAll += 'Additional Policy Identifiers must only contain numbers and periods, and be separated by semicolons. For example: 2.23.140.1.2; 2.23.140.1.1<br/>';
                    isEmpty = true;
                  }
                  if (lstPolicyIdentifiers.contains(PI)) {
                    strWarningsAll +=
                      'Duplicate value added to Additional Policy Identifiers: ' +
                      PI +
                      ' <br/>';
                    isEmpty = true;
                  }
                }
              }
            }
            if (PolicyDoc.Policy_Document_Associations__r.size() == 0) {
              strWarningsAll += 'No Root Certificates Associated. <br />';
              isEmpty = true;
            }
            string strWarningsIAll = '';

            if (isEmpty) {
              strWarningsIAll +=
                '<span style="font-weight:bold;">Warning(s)</span><br/>' +
                strWarningsAll;
            }
            List<wrapApplyPolicyDocs> lstTempApplyPolicyDocs = new List<wrapApplyPolicyDocs>();
            Integer count = 0;
            for (Account objRoot : lstRootCertificates) {
              string Key = Policydoc.Id + '#' + objRoot.Id;
              if (mapOfApplyPolicyDocs.containskey(Key)) {
                Policy_Document_Association_On_Case__c PDAC = mapOfApplyPolicyDocs.get(
                  Key
                );
                boolean isSelected = true;
                if (PDAC.Action__c == 'Delete') {
                  isSelected = false;
                } else {
                  count++;
                }
                lstTempApplyPolicyDocs.add(
                  new wrapApplyPolicyDocs(isSelected, objRoot, PDAC)
                );
              } else {
                lstTempApplyPolicyDocs.add(
                  new wrapApplyPolicyDocs(
                    false,
                    objRoot,
                    new Policy_Document_Association_On_Case__c(
                      Certificate_Name__c = objRoot.Id,
                      Policy_Document__c = Policydoc.Id,
                      Case__c = objCase.Id
                    )
                  )
                );
              }
            }
            if (
              Policydoc.Policy_Identifiers__c != null &&
              string.isnotblank(Policydoc.Policy_Identifiers__c)
            ) {
              List<string> lstAllPI = Policydoc.Policy_Identifiers__c.split(
                ';'
              );
              if (lstAllPI.size() > 0) {
                lstAllPI.sort();
                wrapPolicyDoc.lstdocPolicyIdentifiers = lstAllPI;
              }
            }
            wrapPolicyDoc.strWarnings = strWarningsIAll;
            wrapPolicyDoc.countRootCerts = count;
            wrapPolicyDoc.lstApplyPolicyDocs = lstTempApplyPolicyDocs;
            lstwrapAdditionalPolicyDocs[index] = wrapPolicyDoc;
            lstwrapAdditionalPolicyDocs[index].isEdit = false;
          }
          isAnyWarning = false;
          //check if there is any warning
          for (wrapAdditionalPolicyDocs wrap : lstwrapAdditionalPolicyDocs) {
            if (string.isnotblank(wrap.strWarnings)) {
              isAnyWarning = true;
            }
          }

          ApexPages.Message myMsg = new ApexPages.Message(
            ApexPages.Severity.CONFIRM,
            'Changes Saved Sucessfully.'
          );
          ApexPages.addMessage(myMsg);
        }
      }
    } catch (Exception ex) {
      Database.rollback(sp);
      Apexpages.addMessages(ex);
    }
  }

  public void AddNewPolicyDoc() {
    try {
      wrapAdditionalPolicyDocs wrapPolicyDoc = new wrapAdditionalPolicyDocs();
      wrapPolicyDoc.additionalPolicyDoc = new Policy_Document_On_Case__c(
        Case__c = objCase.Id,
        Document_Verified__c = 'Not Verified',
        Action__c = 'Create'
      );
      wrapPolicyDoc.isEdit = true;
      List<wrapApplyPolicyDocs> lstTempApplyPolicyDocs = new List<wrapApplyPolicyDocs>();
      for (Account objRoot : lstRootCertificates) {
        lstTempApplyPolicyDocs.add(
          new wrapApplyPolicyDocs(
            false,
            objRoot,
            new Policy_Document_Association_On_Case__c(
              Certificate_Name__c = objRoot.Id,
              Case__c = objCase.Id
            )
          )
        );
      }
      wrapPolicyDoc.lstApplyPolicyDocs = lstTempApplyPolicyDocs;
      //take in temp list
      List<wrapAdditionalPolicyDocs> lstTempToAll = lstwrapAdditionalPolicyDocs;
      lstwrapAdditionalPolicyDocs = new List<wrapAdditionalPolicyDocs>();
      lstwrapAdditionalPolicyDocs.add(wrapPolicyDoc);
      //copy values to object when clears
      wrapPDBeforeSave = new wrapAdditionalPolicyDocs();
      wrapPDBeforeSave = (wrapAdditionalPolicyDocs) JSON.deserialize(
        JSON.serialize(wrapPolicyDoc),
        wrapAdditionalPolicyDocs.class
      );
      //add temp list again
      lstwrapAdditionalPolicyDocs.addall(lstTempToAll);
    } catch (Exception ex) {
      Apexpages.addMessages(ex);
    }
  }

  /*public PageReference SaveChanges(){
        //Create a savepoint
        Savepoint sp = Database.setSavepoint();
        try {
            
            List<Policy_Document_On_Case__c> lstAdditionalPolicyUpserts = new List<Policy_Document_On_Case__c>();
            
            map<Policy_Document_On_Case__c, List<Policy_Document_Association_On_Case__c>> mapAdditionalPolicy = new map<Policy_Document_On_Case__c, List<Policy_Document_Association_On_Case__c>>();
            
            List<Policy_Document_Association_On_Case__c> lstApplyPolicyDelete = new List<Policy_Document_Association_On_Case__c>();
            List<Policy_Document_Association_On_Case__c> lstApplyPolicyUpsert = new List<Policy_Document_Association_On_Case__c>();
            boolean isAnyWarning = false;
            for(wrapAdditionalPolicyDocs wrapPolicy: lstwrapAdditionalPolicyDocs){
                //if(wrapPolicy.additionalPolicyDoc.Document_Link__c == null || wrapPolicy.additionalPolicyDoc.Document_Type__c == null){
                //    ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,'Document Type and Document Link is required for Policy Document ID - ' + (wrapPolicy.additionalPolicyDoc.ID != null ? wrapPolicy.additionalPolicyDoc.Name : 'New'));
                //    ApexPages.addMessage(myMsg);
                //   return null;
                //}
                //check for warnings.
                if(string.isblank(wrapPolicy.additionalPolicyDoc.Document_Type__c) || string.isblank(wrapPolicy.additionalPolicyDoc.Document_Link__c) || wrapPolicy.additionalPolicyDoc.Document_Last_Updated_Date__c == null ||
                    string.isblank(wrapPolicy.additionalPolicyDoc.Associated_Trust_Bits__c) || string.isblank(wrapPolicy.additionalPolicyDoc.Policy_Identifiers__c) || 
                    (wrapPolicy.additionalPolicyDoc.Document_Last_Updated_Date__c != null && wrapPolicy.additionalPolicyDoc.Document_Last_Updated_Date__c < system.today().addYears(-1)) ||
                    wrapPolicy.additionalPolicyDoc.Policy_Document_Associations__r.size() == 0){
                    isAnyWarning = true;
                }
                List<Policy_Document_Association_On_Case__c> lstApplyPolicy = new List<Policy_Document_Association_On_Case__c>();
                for(wrapApplyPolicyDocs applyPolicy: wrapPolicy.lstApplyPolicyDocs){
                    if(applyPolicy.isSelected){
                        if(applyPolicy.objApplyPolicyDoc.Certificate_Name__c == null && applyPolicy.objAcc.Id != null){
                            applyPolicy.objApplyPolicyDoc.Certificate_Name__c = applyPolicy.objAcc.Id;
                        }
                        if(applyPolicy.objApplyPolicyDoc.Case__c == null){
                            applyPolicy.objApplyPolicyDoc.Case__c = objCase.Id;
                        }
                        lstApplyPolicy.add(applyPolicy.objApplyPolicyDoc);
                    } else if(applyPolicy.objApplyPolicyDoc.Id != null){
                        applyPolicy.objApplyPolicyDoc.Action__c = 'Deleted';
                        lstApplyPolicyUpsert.add(applyPolicy.objApplyPolicyDoc);
                        //lstApplyPolicyDelete.add(applyPolicy.objApplyPolicyDoc);
                    }
                }
                lstAdditionalPolicyUpserts.add(wrapPolicy.additionalPolicyDoc);
                if(lstApplyPolicy.size() > 0) {
                    mapAdditionalPolicy.put(wrapPolicy.additionalPolicyDoc, lstApplyPolicy);
                }
            }
            //update case
            objCase.Any_Warning_for_Policy_Documents__c = isAnyWarning;
            update objCase;
            //upsert additional CP CPS Upserts.
            upsert lstAdditionalPolicyUpserts;
            
            for(Policy_Document_On_Case__c addPolicy: lstAdditionalPolicyUpserts){
                if(mapAdditionalPolicy.containskey(addPolicy)){
                    for(Policy_Document_Association_On_Case__c ApplyPolicy: mapAdditionalPolicy.get(addPolicy)){
                        //Policy_Document_Association_On_Case__c applyPolicyDoc = new Policy_Document_Association_On_Case__c(Case__c = objCase.Id);
                        //applyPolicyDoc.Policy_Document_On_Case__c = addPolicy.Id;
                        //applyPolicyDoc.Certificate_Name__c = ApplyPolicy.Certificate_Name__c;
                        //if(ApplyPolicy.Id != null) {
                        //    applyPolicyDoc.Id = ApplyPolicy.Id;
                        //}
                        if(ApplyPolicy.Policy_Document__c == null){
                            ApplyPolicy.Policy_Document__c = addPolicy.Id;
                        }
                        lstApplyPolicyUpsert.add(ApplyPolicy);
                    }
                }
            }
            //upsert apply CP CPS 
            upsert lstApplyPolicyUpsert;
            
            if(lstApplyPolicyDelete.size() > 0){
                //delete lstApplyPolicyDelete;
            }
            //loads again
            LoadAdditionalPolicyDocs();
            
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.CONFIRM,'Changes Saved Sucessfully.');
            ApexPages.addMessage(myMsg);
            //PageReference pg = new PageReference('/'+objCase.Id);
            //return pg;
            return null;
        } catch (Exception ex){
            Database.rollback(sp);
            Apexpages.addMessages(ex);
            return null;
        }
    }*/

  /*public boolean isValidPDFFile(string DocumentLink){
        try {
            // Instantiate a new http object
            Http h = new Http();
        
             // Instantiate a new HTTP request, specify the method (GET) as well as the endpoint
            HttpRequest req = new HttpRequest();
            req.setEndpoint(DocumentLink);
            req.setMethod('GET');
        
            // Send the request, and return a response
            HttpResponse res = h.send(req);
            system.debug('res' + res);
            if(res.getHeader('Content-Type') == 'application/pdf'){
                return true;        
            } else {
                return false;
            }
        } catch (Exception ex){
            return false;
        }
    }*/

  public class wrapAdditionalPolicyDocs {
    public Policy_Document_On_Case__c additionalPolicyDoc { get; set; }
    public List<string> lstdocPolicyIdentifiers { get; set; }
    public string strWarnings { get; set; }
    public boolean isEdit { get; set; }
    public Integer countRootCerts { get; set; }
    public List<wrapApplyPolicyDocs> lstApplyPolicyDocs { get; set; }
    public wrapAdditionalPolicyDocs() {
      additionalPolicyDoc = new Policy_Document_On_Case__c();
      lstdocPolicyIdentifiers = new List<string>();
      lstApplyPolicyDocs = new List<wrapApplyPolicyDocs>();
      countRootCerts = 0;
      strWarnings = '';
      isEdit = false;
    }
  }

  public class wrapApplyPolicyDocs {
    public boolean isSelected { get; set; }
    public Account objAcc { get; set; }
    public Policy_Document_Association_On_Case__c objApplyPolicyDoc {
      get;
      set;
    }
    public wrapApplyPolicyDocs(
      boolean isSel,
      Account acc,
      Policy_Document_Association_On_Case__c PolicyDoc
    ) {
      this.isSelected = isSel;
      this.objAcc = acc;
      this.objApplyPolicyDoc = PolicyDoc;
    }
  }
}
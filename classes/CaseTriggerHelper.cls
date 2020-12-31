// ========================================================================================================
// CaseTriggerHelper: Trigger for the Case object which handles all the events and based on the event delegates the task 
// to the corresponding trigger handler method in the CaseTriggerHelper class.
// ========================================================================================================
// SetAccountStatusField : (Record Type: CA Owner/Root Inclusion Request) 
// *** NO LONGER NEEDED *** Update related Account Status whenever a new Case is created. 
// ========================================================================================================
// EnforceCAOwnerRule : (Record Type: All)
// Allow cases to be created for 'CA Owner' records only 
// ========================================================================================================
// EnforeAccountRules : (Record Type: CA Owner/Root Inclusion Request) 
// In edit mode - do not allow user to modify Account Name/Owner 
// ========================================================================================================
// SetAllFieldsVerifiedField: (Record Type: CA Owner/Root Inclusion Request)
// Following updates and checks are performed in this trigger when 
// a Root Case record is inserted or updated. Set 'All Fields Verified?' field to 'Yes' if all 
// 'Verified' fields Case object are 'Verified' or 'Not Applicable' 
// ========================================================================================================
// EnforceRequestStatusRulesForInserts : (Record Type: CA Owner/Root Inclusion Request & CA Audit Update Request)
// New Cases must be saved with Request Status "Initial Request Received"
// ========================================================================================================
// EnforceRequestStatusRulesForUpdates : (Record Type: CA Owner/Root Inclusion Request)
// Displays error messages when following conditions are not met.
// 1) "Ready for Public Discussion" can only be selected after all of the Verified fields either
//    "Verified" or "Not Applicable" and all corresponding Root Cases have Request status 
//    of one of "Ready For Public Discussion", "On Hold", "Denied" 
// 2) "In Public Discussion" can only be selected after "Ready for Public Discussion" or "Discussion on Hold"
//     and all corresponding Root Cases have Request status are "In Public Discussion"
// 3) "Discussion on Hold" can only be selected after "In Public Discussion"
//     and all corresponding Root Cases have Request status of "Discussion on Hold" or "In Public Discussion"
// 4) "Pending Approval" can only be selected after "In Public Discussion" or "CA Action Items
//    from Discussion" and all corresponding Root Cases have Request status 
//    of one of "Pending Approval", "On Hold", "Denied" 
// 5) "Approved, Pending Inclusion" or "Approved, Pending Inclusion and EV" can only be selected 
//    after "Pending Approval"
// 6) "Included, Pending EV" can only be selected after either "Pending Approval" or 
//    "Approved, Pending Inclusion and EV"
// 7) "On Hold" and "Denied" requires a short explanation in the public comments section
// 8) "Complete" can only be selected after "Approved, Pending Inclusion" or 
//    "Approved, Pending Inclusion and EV" or "Included, Pending EV"
// 9) A Case can have Request Status as 'Included, Pending EV' or 'Complete' 
//    only when all related root cases are 'On Hold' or 'Denied' or 
//   'Included, Pending EV' or 'Complete'
// 10) When Case.Request_Status is 'Complete' change Case.Status to 'Closed' when all related 
//     Root Cases have  Root_Cases.Request_Status = 'Included, Pending EV' or 
//     'Denied' or 'Complete'
// 11) When Case.Request Status is 'Request Withdrawn by CA' set Case.Status to 'Closed' when all related 
//      Root Cases have  Root_Cases.Request_Status = 'Request Withdrawn by CA'
// 12) When Request Status is 'On Hold' set the Case.Status to 'On Hold'
//     Keep the Case 'Open' when Request Status is other than 'Complete' or 'Denied' or 'Request Withdrawn by CA'
// ========================================================================================================
// Update Log:
// 02/15/2018 - Added new Reuest Status "In Detailed CP/CPS Review" and Changed "Ready for Public Discussion" can only selected after "In Detailed CP/CPS Review".
// 05/02/2018 - Added new UpdateAuditGaps method to check Audit Gaps for all audit.
// 08/29/2018 - Added new populateAuditDeviationForCAAuditUpdateCases method to populate Deviation for audits
// 08/30/2018 - Moved code for method populateAuditDeviationForCAAuditUpdateCases() to JixiServiceController
// 08/31/2018 - Added DefaultCaseAssignedTo method to update 'Case Assigned To' field with the Case Owner when a new Case is created
// 03/05/2019 - Updated DefaultCAOwnerFields method to populate address fields only for root inclusion type case.
// 06/04/2019 - Updated ManualSharing method to allow case sharing for Inclusion type of cases.
// 01/25/2020 - Added Method to update case status to closed on certain criteria for Root Inclusion cases.
// 05/08/2020 - Added a new method to update Instructions.
// 10/20/2020 - Update Audit Gaps method to update warning correctly when Root case is deleted.
// ========================================================================================================


public class CaseTriggerHelper {

   // fetch data from CA Owner record when Case is first created
    public static void DefaultCAOwnerFields(List<Case> lstCases){
        String csAuditUpdateRTId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('CA Audit Update Request').getRecordTypeId();
        String csRootInclusionRTId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('CA Root Inclusion Request').getRecordTypeId();
        set<Id> setCAOwnerId = new set<Id>();
        for(Case cs: lstCases){
            if(cs.RecordTypeId == csAuditUpdateRTId || cs.RecordTypeId == csRootInclusionRTId){
                setCAOwnerId.add(cs.AccountId);
            }
        }
        if(setCAOwnerId.size() > 0){
        
            map<Id,Account> mapAccounts = new map<Id,Account>([select Id,Name,Recognized_CAA_Domains__c,Problem_Reporting_Mechanism__c,Status__c,
                        Company_Website__c, CA_Email_Alias_1__c, Organizational_Type__c, Geographic_Focus__c, Primary_Market_Customer_Base__c,
                        BillingStreet, BillingCity, BillingState, BillingPostalCode, BillingCountry,
                        Microsoft_Contract_Type__c,Microsoft_Status__c,Document_Repository__c,Document_Repository_Description__c
                        from Account Where Id in: setCAOwnerId]);
                        
            for(Case objCS: lstCases){
                if((objCS.RecordTypeId == csAuditUpdateRTId || objCS.RecordTypeId == csRootInclusionRTId) && mapAccounts.containskey(objCS.AccountId)) {
                    if(mapAccounts.get(objCS.AccountId).Status__c != null){
                        objCS.Mozilla_Status__c = mapAccounts.get(objCS.AccountId).Status__c;
                    }
                    if(mapAccounts.get(objCS.AccountId).Microsoft_Status__c != null){
                        objCS.Microsoft_Status__c = mapAccounts.get(objCS.AccountId).Microsoft_Status__c;
                    } 
                    if(mapAccounts.get(objCS.AccountId).Microsoft_Contract_Type__c != null){
                        objCS.Microsoft_Contract_Type__c = mapAccounts.get(objCS.AccountId).Microsoft_Contract_Type__c;
                    } 
                    if(mapAccounts.get(objCS.AccountId).Company_Website__c != null) {
                        objCS.Company_Website__c = mapAccounts.get(objCS.AccountId).Company_Website__c;
                    }
                    if(mapAccounts.get(objCS.AccountId).CA_Email_Alias_1__c != null){
                        objCS.CA_Email_Alias_1__c = mapAccounts.get(objCS.AccountId).CA_Email_Alias_1__c;
                    }            
                    if(mapAccounts.get(objCS.AccountId).Organizational_Type__c != null){
                        objCS.Organizational_Type__c = mapAccounts.get(objCS.AccountId).Organizational_Type__c;
                    }
                    if(mapAccounts.get(objCS.AccountId).Geographic_Focus__c != null){
                        objCS.Geographic_Focus__c = mapAccounts.get(objCS.AccountId).Geographic_Focus__c;
                    }
                    if(mapAccounts.get(objCS.AccountId).Primary_Market_Customer_Base__c != null){
                        objCS.Primary_Market_Customer_Base__c = mapAccounts.get(objCS.AccountId).Primary_Market_Customer_Base__c;
                    }
                    if(mapAccounts.get(objCS.AccountId).Recognized_CAA_Domains__c != null){
                        objCS.Recognized_CAA_Domains__c = mapAccounts.get(objCS.AccountId).Recognized_CAA_Domains__c;
                    }
                    if(mapAccounts.get(objCS.AccountId).Problem_Reporting_Mechanism__c != null){
                        objCS.Problem_Reporting_Mechanism__c = mapAccounts.get(objCS.AccountId).Problem_Reporting_Mechanism__c;
                    }     
                    if(mapAccounts.get(objCS.AccountId).Document_Repository__c != null){
                        objCS.CA_Document_Repository__c = mapAccounts.get(objCS.AccountId).Document_Repository__c;
                    }
                    if(mapAccounts.get(objCS.AccountId).Document_Repository_Description__c != null){
                        objCS.Policy_Documentation__c = mapAccounts.get(objCS.AccountId).Document_Repository_Description__c;
                    }
                    /*if(objCS.Management_Assertions_By__c == null){
                        objCS.Management_Assertions_By__c = mapAccounts.get(objCS.AccountId).Name;
                    } */ 
                    
                    //copy address fields only for root inclusion type of case
                    if(objCS.RecordTypeId == csRootInclusionRTId){
                        if(mapAccounts.get(objCS.AccountId).BillingStreet != null){
                            objCS.Street__c = mapAccounts.get(objCS.AccountId).BillingStreet ;
                        }
                        if(mapAccounts.get(objCS.AccountId).BillingCity != null){
                            objCS.City__c = mapAccounts.get(objCS.AccountId).BillingCity;
                        }
                        if(mapAccounts.get(objCS.AccountId).BillingState != null){
                            objCS.State__c = mapAccounts.get(objCS.AccountId).BillingState;
                        }
                        if(mapAccounts.get(objCS.AccountId).BillingPostalCode != null){
                            objCS.Zip_Postal_Code__c = mapAccounts.get(objCS.AccountId).BillingPostalCode;
                        }
                        if(mapAccounts.get(objCS.AccountId).BillingCountry != null){
                            objCS.Country__c = mapAccounts.get(objCS.AccountId).BillingCountry;
                        }
                    }                
                }
            }
        }
    }
   
    // re-fetch data from CA Owner record whenever Case is updated
    public static void DefaultCAOwnerFieldsOnChange (List<Case> caseSoLst, Map<Id, Case> oldcaseSoLst){
   
        // loop over all the cases which were updated
        String csAuditUpdateRTId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('CA Audit Update Request').getRecordTypeId();
        set<Id> setCAOwnerId = new set<Id>();
        for(Case cs: caseSoLst){
            if(cs.RecordTypeId == csAuditUpdateRTId){
                setCAOwnerId.add(cs.AccountId);
            }
        }
        if(setCAOwnerId.size() > 0){
            map<Id,Account> mapAccounts = new map<Id,Account>([select Id,Name,Recognized_CAA_Domains__c,Problem_Reporting_Mechanism__c,Status__c,Microsoft_Status__c,Microsoft_Contract_Type__c from Account Where Id in: setCAOwnerId]);
            for(Case objCS: caseSoLst){
                if(objCS.RecordTypeId == csAuditUpdateRTId && mapAccounts.containskey(objCS.AccountId)) {
                    if(mapAccounts.get(objCS.AccountId).Status__c != null){
                        objCS.Mozilla_Status__c = mapAccounts.get(objCS.AccountId).Status__c;
                    }
                    if(mapAccounts.get(objCS.AccountId).Microsoft_Status__c != null){
                        objCS.Microsoft_Status__c = mapAccounts.get(objCS.AccountId).Microsoft_Status__c;
                    } 
                    if(mapAccounts.get(objCS.AccountId).Microsoft_Contract_Type__c != null){
                        objCS.Microsoft_Contract_Type__c = mapAccounts.get(objCS.AccountId).Microsoft_Contract_Type__c;  
                    } 
                    /*if(objCS.Management_Assertions_By__c == null){
                        objCS.Management_Assertions_By__c = mapAccounts.get(objCS.AccountId).Name;
                    } */               
                }
            }
        }
    }
    
    public static void UpdateInstructions(List<Case> lstCasesUpdates){
        String csAuditUpdateRTId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('CA Audit Update Request').getRecordTypeId();
        for(Case objCase: lstCasesUpdates){
            if(lstCasesUpdates.size() == 1 && Trigger.isUpdate){
                AuditCaseProgressBarController controller = new AuditCaseProgressBarController(new Apexpages.standardcontroller(objCase));
                controller.CheckCaseProgress();
                for(AuditCaseProgressBarController.WrapperStages wstage: controller.lstWrapperCaseStages){
                    if(wstage.isCurrent){
                        system.debug('wstage.stagename ::: '+wstage.stagename);
                        objCase.Case_Progress__c = wstage.stagename;
                        if(wstage.stagename == 'Add Root Cases'){
                            string strInstructions = '1. Click on the \'Add/Update Root Cases\' button to indicate which root certificates are covered in the audit statements, and which audit ';
                            strInstructions += 'statements apply to each root cert and hierarchy.\n 2. Click on the \'Edit Test Websites\' and \'Audit Letter Validation (ALV)\' buttons.\n\n Note: ';
                            strInstructions += 'You may click on the \'Edit\' and \'Submit\' buttons as many times as you need to save your changes.';
                            objCase.Instructions__c = strInstructions;
                        } else if(wstage.stagename == 'Update Policy Documents'){
                            string strInstructions = '1. Click on the \'Update Policy Documents\'\n';
                            strInstructions += '2. Click on the Update Test Websites.\n';
                            strInstructions += '3. Click on \'Audit Letter Validation (ALV)\' buttons.\n\n'; 
                            strInstructions += 'Note: You may click on the \'Edit\' and \'Submit\' buttons as many times as you need to save your changes.';
                            objCase.Instructions__c = strInstructions;
                        } else if(wstage.stagename == 'Update Test Websites'){
                            string strInstructions = '1. Click on the \'Edit Test Websites\' button to make sure the test websites ';
                            strInstructions  += 'are correct.\n 2. Click on the \'Audit Letter Validation (ALV)\' ';
                            strInstructions  += 'button. \n\nNote: You may click on the \'Edit\' and \'Submit\' buttons as many ';
                            strInstructions  += 'times as you need to save your changes.';
                            objCase.Instructions__c = strInstructions;
                        } else if(wstage.stagename == 'Run ALV'){
                            string strInstructions = '1. Click on the \'Audit Letter Validation (ALV)\' button and resolve any ';
                            strInstructions  += 'issues in your audit statements. \n\n Note: You may click on the \'Edit\' and ';
                            strInstructions  += '\'Submit\' buttons as many times as you need to save your changes.';
                            objCase.Instructions__c = strInstructions;
                        } else if(wstage.stagename == 'Verification by Root Store'){
                            string strInstructions = 'Your Case has been assigned to a root store operator for review as ';
                            strInstructions  += 'described here: https://www.ccadb.org/cas/updates#what-happens-next';
                            objCase.Instructions__c = strInstructions;
                        }
                    }
                    if(wstage.isCompleted && wstage.stagename == 'Run ALV' && objCase.Request_Status__c == 'Initial Request Received'){
                        objCase.Request_Status__c = 'Verification by Root Store';
                    }
                }
            }
            /*if(objCase.Case_Progress__c == 'Add Root Cases'){
                string strInstructions = 'Click on the \'Add/Update Root Cases\' button to indicate which root certificates are covered in the audit statements, and which audit ';
                strInstructions += 'statements apply to each root cert and hierarchy. Then click on the \'Edit Test Websites\' and \'Audit Letter Validation (ALV)\' buttons. Note: ';
                strInstructions += 'You may click on the \'Edit\' and \'Submit\' buttons as many times as you need to save your changes.';
                objCase.Instructions__c = strInstructions;
            }
            if(objCase.Case_Progress__c == 'Update Test Websites'){
                string strInstructions = 'Click on the \'Edit Test Websites\' button to make sure the test websites ';
                strInstructions  += 'are correct. Finally, click on the \'Audit Letter Validation (ALV)\' ';
                strInstructions  += 'button. Note: You may click on the \'Edit\' and \'Submit\' buttons as many ';
                strInstructions  += 'times as you need to save your changes.';
                objCase.Instructions__c = strInstructions;
            }
            if(objCase.Case_Progress__c == 'Run ALV'){
                string strInstructions = 'Click on the \'Audit Letter Validation (ALV)\' button and resolve any ';
                strInstructions  += 'issues in your audit statements. Note: You may click on the \'Edit\' and ';
                strInstructions  += '\'Submit\' buttons as many times as you need to save your changes.';
                objCase.Instructions__c = strInstructions;
            }
            if(objCase.Case_Progress__c == 'Verification by Root Store'){
                string strInstructions = 'Your Case has been assigned to a root store operator for review as ';
                strInstructions  += 'described here: https://www.ccadb.org/cas/updates#what-happens-next';
                objCase.Instructions__c = strInstructions;
            }*/
        }
    }
    
    public static void DefaultCaseAssignedTo (List<Case> caseSoLst) {
        
        // loop over all the cases which were updated
        for(Case caseSO : caseSoLst)
        {
           
         // Set Case Assign To       
         caseSO.Case_Assigned_To__c = caseSO.OwnerId;
        }
    }    
   
    // Allow cases to be created for 'CA Owner' records only 
    public static void EnforceCAOwnerRule (List<Case> caseSoLst) {
        
        // loop over all the cases which were updated
        for(Case caseSO : [select Id,Account.RecordType.Name from Case Where Id in: caseSoLst and AccountId != null])
        {            
            System.debug('Tr RecordType ::: '+caseSO.Account.RecordType.Name);  
            if (caseSO.Account.RecordType.Name != 'CA Owner') {
                caseSO.addError('A case can only be created for a CA Owner. Please correct the data in \'CA Owner/Certificate Name\'');
            } 
        }
    }   
    
    
    //Method create to check for community User
    public static void EnforceCommunityUser(List<Case> caseSoLst){
        // query the user details and check if it is a portal user and get the Owner account ID for that user
        List<User> userSoLst = [select IsPortalEnabled,contact.account.id,contact.account.name from user where id = :UserInfo.getUserId()];
        
        // get the record type ID of the root certificate records 
        Id ownerCARecTypeId= Schema.SObjectType.Account.getRecordTypeInfosByName().get('CA Owner').getRecordTypeId();
        if(userSoLst!=null && userSoLst.size() > 0 && userSoLst[0].isPortalEnabled){
            //if the logged user account is Symantec
            if(userSoLst[0].contact.account.name.startsWith('Symantec')){
                // get all the symantec owner accounts
                Map<Id,Account> symantecAccountMap = New Map<Id,Account>([select id from account where name like 'Symantec%' and recordTypeId=:ownerCARecTypeId]);
                for(Case caseSO: caseSoLst){
                    if(!symantecAccountMap.containskey(caseSO.AccountId)) {
                        caseSO.addError('Invalid selection made for CA Owner/Certificate. Please select CA Owner/Certificate Name as '+ userSoLst[0].contact.account.name + ' or other Symantec brands');
                    }
                }
                
            } else {
                for(Case caseSO: caseSoLst){
                    if(caseSO.AccountId != userSoLst[0].contact.account.Id) {
                        caseSO.addError('Invalid selection made for CA Owner/Certificate. Please select CA Owner/Certificate Name as '+ userSoLst[0].contact.account.name);
                    }
                }
            }
        }
    }
    
    
    public static void EnforceAccountRules (List<Case> caseSoLst,  Map<Id, Case> oldcaseSoLst) {
        
        // loop over all the cases which were updated
        for(Case caseSO : caseSoLst)
        {
           
         // Set oldcaseSo to trigger.old value        
         Case oldcaseSO = oldcaseSOLst.get(caseSo.Id); 
        
         // EnforeAccountRules : In edit mode - do not allow user to modify Account Name/Owner     
          if (oldcaseSO.AccountID != null && caseSO.AccountID != oldcaseSO.AccountID) {
                caseSO.addError('Do not make changes to the CA Owner Name');
             } 
        }
    }   

    public static void SetAllFieldsVerifiedField (List<Case> caseSoLst) {
        
        String caseInclusionRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('CA Root Inclusion Request').getRecordTypeId();
        
        // loop over all the cases which were updated
        for(Case caseSo : caseSoLst) {
            if(caseSO.RecordTypeId == caseInclusionRecordTypeId) {
            
                // Set 'All Fields Verified?' field to 'Yes' if all 'Verified' fields
                // in Root Case object are 'Verified' or 'Not Applicable'  
                
                caseSO.All_Fields_Verified__c = 'Yes'; // initialize
                if(caseSO.CA_Owner_Information_Verified__c != 'Data Verified'){
                    caseSO.All_Fields_Verified__c = 'No';
                }
                if (caseSO.Address_Verified__c != 'Data Verified' && caseSO.Address_Verified__c != 'Not Applicable') {
                    caseSO.All_Fields_Verified__c = 'No';
                }
                if (caseSO.Auditor_Verified__c != 'Data Verified') {
                    caseSO.All_Fields_Verified__c = 'No';
                }
                if (caseSO.Standard_Audit_Verified__c != 'Data Verified' && caseSO.Standard_Audit_Verified__c != 'Not Applicable') {
                    caseSO.All_Fields_Verified__c = 'No';
                }
                if (caseSO.BR_Audit_Statement_Link_Verified__c != 'Data Verified' && caseSO.BR_Audit_Statement_Link_Verified__c != 'Not Applicable') {
                    caseSO.All_Fields_Verified__c = 'No';
                }
                if (caseSO.Code_Signing_Audit_Verified__c != 'Data Verified' && caseSO.Code_Signing_Audit_Verified__c != 'Not Applicable') {
                    caseSO.All_Fields_Verified__c = 'No';
                }
                if (caseSO.EV_Audit_Statement_Link_Verified__c != 'Data Verified' && caseSO.EV_Audit_Statement_Link_Verified__c != 'Not Applicable') {
                    caseSO.All_Fields_Verified__c = 'No';
                }
                if (caseSO.EV_Code_Signing_Verified__c != 'Data Verified' && caseSO.EV_Code_Signing_Verified__c != 'Not Applicable') {
                    caseSO.All_Fields_Verified__c = 'No';
                }
                if (caseSO.CP_CPS_Links_Verified__c != 'Data Verified' && caseSO.CP_CPS_Links_Verified__c != 'Not Applicable') {
                    caseSO.All_Fields_Verified__c = 'No';
                }
                if (caseSO.Required_Practices_Verified__c != 'Data Verified' && caseSO.Required_Practices_Verified__c != 'Not Applicable') {
                    caseSO.All_Fields_Verified__c = 'No';
                }
                if (caseSO.Forbidden_Practices_Verified__c != 'Data Verified' && caseSO.Forbidden_Practices_Verified__c != 'Not Applicable') {
                    caseSO.All_Fields_Verified__c = 'No';
                }                            
            } 
        }    
        
        
        /*// process cases with record type = 'CA Owner/Root Inclusion Request'
        String caseAuditUpdateRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('CA Owner/Root Inclusion Request').getRecordTypeId();
    
            
        // loop over all the cases which were updated
        for(Case caseSo : caseSoLst)
        {
            System.debug('caseSo ::: '+caseSo );
            System.debug('caseSo Account ::: '+caseSo.AccountId );
            if(caseSO.RecordTypeId == caseAuditUpdateRecordTypeId){  // process cases with record type 'CA Owner/Root Inclusion Request'
   
                // Set 'All Fields Verified?' field to 'Yes' if all 'Verified' fields
                // in Root Case object are 'Verified' or 'Not Applicable'  
                
                caseSO.All_Fields_Verified__c = 'Yes'; // initialize
                
                if (caseSO.Company_Website_Verified__c != 'Verified' && 
                caseSO.Company_Website_Verified__c != 'Not Applicable' ) {
                caseSO.All_Fields_Verified__c = 'No';}
                
                if (caseSO.Organizational_Type_Verified__c != 'Verified' && 
                caseSO.Organizational_Type_Verified__c != 'Not Applicable' ) {
                caseSO.All_Fields_Verified__c = 'No';}
                
                if (caseSO.Organizational_Type_Others_Verified__c != 'Verified' && 
                caseSO.Organizational_Type_Others_Verified__c != 'Not Applicable' ) {
                caseSO.All_Fields_Verified__c = 'No';}
                
                if (caseSO.Geographic_Focus_Verified__c != 'Verified' && 
                caseSO.Geographic_Focus_Verified__c != 'Not Applicable' ) {
                caseSO.All_Fields_Verified__c = 'No';}
                
                if (caseSO.Primary_Market_Customer_Base_Verified__c != 'Verified' && 
                caseSO.Primary_Market_Customer_Base_Verified__c != 'Not Applicable' ) {
                caseSO.All_Fields_Verified__c = 'No';}
                
                if (caseSO.Impact_to_Mozilla_Users_Verified__c != 'Verified' && 
                caseSO.Impact_to_Mozilla_Users_Verified__c != 'Not Applicable' ) {
                caseSO.All_Fields_Verified__c = 'No';}
                
                if (caseSO.CA_s_Reponse_to_Recom_Prac_Verified__c != 'Verified' && 
                caseSO.CA_s_Reponse_to_Recom_Prac_Verified__c != 'Not Applicable' ) {
                caseSO.All_Fields_Verified__c = 'No';}
                
                if (caseSO.CA_s_Response_to_Prob_Prac_Verified__c != 'Verified' && 
                caseSO.CA_s_Response_to_Prob_Prac_Verified__c != 'Not Applicable' ) {
                caseSO.All_Fields_Verified__c = 'No';}           
                
            } 
        }     */
    }
    
    public static void EnforceRequestStatusRulesForInserts (List<Case> caseSoLst)
    {
        String caRootInclusionRequestRecordTypeId = Schema.SObjectType.Root_Case__c.getRecordTypeInfosByName().get('CA Root Inclusion Request').getRecordTypeID();
        // loop over all the cases which were inserted
        for(Case caseSo : caseSoLst)
        {
            if (caseSO.RecordTypeId == caRootInclusionRequestRecordTypeId && !caseSO.Request_Status__c.equals('Initial Request Received')) {           
                  caseSO.addError('New Case must be saved with Request Status "Initial Request Received"');
            }
        }
        /*String caOwnerRootInclusionRequestRecordTypeId = Schema.SObjectType.Root_Case__c.getRecordTypeInfosByName().get('CA Owner/Root Inclusion Request').getRecordTypeID();
        // loop over all the cases which were inserted
        for(Case caseSo : caseSoLst)
        {
            if (caseSO.RecordTypeId == caOwnerRootInclusionRequestRecordTypeId && !caseSO.Request_Status__c.equals('Initial Request Received')) {           
                  caseSO.addError('New Case must be saved with Request Status "Initial Request Received"');
            }  
             */
            // A workflow/field update has replaced these commented lines           
            // get case record type id for 'CA Audit Update Request' & set subject field only if record type 'CA Audit Update Request' 
            // String caOwnerRootInclusionRequestRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('CA Audit Update Request').getRecordTypeId();
            /* if(caseSO.RecordTypeId == caOwnerRootInclusionRequestRecordTypeId){  process 'CA Owner/Root Inclusion Request' record types only     
                  DateTime Dt = System.now();
                  String CurrentYear = Dt.format('yyyy');                 
                  caseSO.Subject = CurrentYear + ' Audit ' + caseSO.Account.Name;                                  
            }*/
                
        //}
    }

    public static void EnforceRequestStatusRulesForUpdates (List<Case> caseSoLst,  Map<Id, Case> oldcaseSoLst) {
        
        //code is added by Sunil
        //for deplopment code is commented 
        String caseRootInclusionRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('CA Root Inclusion Request').getRecordTypeId();
        //add case id in to set to get all root cases
        set<Id> setCaseIds = new set<Id>();
        for(Case caseSo : caseSoLst){
            setCaseIds.add(caseSo.Id);
        }
        //map to store key as Id and value as List of all Root case for that Case
        map<Id, List<Root_Case__c>> mapCaseWiseRootCases = new map<Id, List<Root_Case__c>>();
        for(Root_Case__c RootCase: [select Id,case_no__c, Request_status__c from 
                Root_Case__c where case_no__c in: setCaseIds]){
            if(mapCaseWiseRootCases.containskey(RootCase.case_no__c)){
                mapCaseWiseRootCases.get(RootCase.case_no__c).add(RootCase);
            } else {
                mapCaseWiseRootCases.put(RootCase.case_no__c, new List<Root_Case__c>{RootCase});
            }        
        }
        
        set<string> setOfIgnoreStatuses = new set<string>();
        setOfIgnoreStatuses.add('Request Withdrawn by CA');
        setOfIgnoreStatuses.add('Denied');
        
        // loop over all the cases which were updated
        for(Case caseSo : caseSoLst){
            if(caseSO.RecordTypeId == caseRootInclusionRecordTypeId){
                
                List<Root_Case__c> RootCaseLst = new List<Root_Case__c>();
                if(mapCaseWiseRootCases.containskey(caseSo.Id)){
                    RootCaseLst = mapCaseWiseRootCases.get(caseSo.Id);
                } 
                
                // Set oldcaseSo to trigger.old value        
                Case oldcaseSo = oldcaseSOLst.get(caseSo.Id); 
                
                if (!caseSO.Request_Status__c.equals(oldcaseSO.Request_Status__c))
                {
                    //validation for Information Verification In Process
                    /*if(caseSo.Request_Status__c == 'Information Verification In Process') {
                        boolean isAnyRootCaseMatchStatus = false;
                        for(Root_Case__c RootCaseSo : RootCaseLst){
                            if (RootCaseSo.request_status__c == 'Information Verification In Process') {
                                isAnyRootCaseMatchStatus = true;
                                break;
                            }
                        }
                        if(!isAnyRootCaseMatchStatus){
                            caseSO.addError('Request Status "Information Verification In Process" can only be selected if any Root Case is "Information Verification In Process".');
                            return;
                        }
                    }*/
                    
                    //validation for In Detailed CP/CPS Review
                    //along with all fields verified, check mozilla specific verified fields 
                    if(caseSo.Request_Status__c == 'In Detailed CP/CPS Review') {
                        if (caseSO.All_Fields_Verified__c.equals('No')) {
                            caseSO.addError('Request Status "In Detailed CP/CPS Review" can only be selected after all of the Verified fields either "Verified" or "Not Applicable" ');
                            return;
                        } else if (oldcaseSO.Request_Status__c != 'Information Verification In Process'){
                            caseSO.addError('Request Status "In Detailed CP/CPS Review" can only be selected after "Information Verification In Process".');
                            return;
                        }
                        
                        boolean isAnyRootCaseMatchStatus = true;
                        for(Root_Case__c RootCaseSo : RootCaseLst){
                            if (RootCaseSo.request_status__c != 'In Detailed CP/CPS Review' && !setOfIgnoreStatuses.contains(RootCaseSo.request_status__c)) {
                                isAnyRootCaseMatchStatus = false;
                                break;
                            }
                        }
                        if(!isAnyRootCaseMatchStatus){
                            caseSO.addError('Request Status "In Detailed CP/CPS Review" can only be selected when all related Root Cases are "In Detailed CP/CPS Review" or "Request Withdrawn by CA".');
                            return;
                        }
                    }
                    
                    //validation for In Public Discussion
                    if(caseSo.Request_Status__c == 'In Public Discussion') {
                        if (oldcaseSO.Request_Status__c != 'In Detailed CP/CPS Review'){
                             caseSO.addError('Request Status "In Public Discussion" can only be selected after "In Detailed CP/CPS Review".');
                             return;
                        }
                        
                        boolean isAnyRootCaseMatchStatus = true;
                        for(Root_Case__c RootCaseSo : RootCaseLst){
                            if (RootCaseSo.request_status__c != 'In Public Discussion' && !setOfIgnoreStatuses.contains(RootCaseSo.request_status__c)) {
                                isAnyRootCaseMatchStatus = false;
                                break;
                            }
                        }
                        if(!isAnyRootCaseMatchStatus){
                            caseSO.addError('Request Status "In Public Discussion" can only be selected when all related Root Cases are "In Public Discussion" or "Request Withdrawn by CA".');
                            return;
                        }
                    }
                    
                    //validation for Pending Approval
                    if(caseSo.Request_Status__c == '​Pending Approval') {
                        if (oldcaseSO.Request_Status__c != '​In Public Discussion'){
                             caseSO.addError('Request Status "Pending Approval" can only be selected after "​In Public Discussion".');
                             return;
                        }
                        
                        boolean isAnyRootCaseMatchStatus = true;
                        for(Root_Case__c RootCaseSo : RootCaseLst){
                            if (RootCaseSo.request_status__c != '​Pending Approval' && !setOfIgnoreStatuses.contains(RootCaseSo.request_status__c)) {
                                isAnyRootCaseMatchStatus = false;
                                break;
                            }
                        }
                        if(!isAnyRootCaseMatchStatus){
                            caseSO.addError('Request Status "Pending Approval" can only be selected when all related Root Cases are "Pending Approval" or "Denied".');
                            return;
                        }
                    }
                    
                }
            }
        }
        
        
        /* 
        //code is commented on 13th July 18. 
        // process cases with record type = 'CA Owner/Root Inclusion Request'
        String caseAuditUpdateRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('CA Owner/Root Inclusion Request').getRecordTypeId();
        
        //code is added by Sunil
        //add case id in to set to get all root cases
        set<Id> setCaseIds = new set<Id>();
        for(Case caseSo : caseSoLst){
            setCaseIds.add(caseSo.Id);
        }
        //map to store key as Id and value as List of all Root case for that Case
        map<Id, List<Root_Case__c>> mapCaseWiseRootCases = new map<Id, List<Root_Case__c>>();
        for(Root_Case__c RootCase: [select Id,case_no__c, Request_status__c from 
                Root_Case__c where case_no__c in: setCaseIds]){
            if(mapCaseWiseRootCases.containskey(RootCase.case_no__c)){
                mapCaseWiseRootCases.get(RootCase.case_no__c).add(RootCase);
            } else {
                mapCaseWiseRootCases.put(RootCase.case_no__c, new List<Root_Case__c>{RootCase});
            }        
        }
         
        // loop over all the cases which were updated
        for(Case caseSo : caseSoLst)
        {
           
          if(caseSO.RecordTypeId == caseAuditUpdateRecordTypeId){  // process record type 'CA Owner/Root Inclusion Request' only
       
           
         // Set oldcaseSo to trigger.old value        
         Case oldcaseSo = oldcaseSOLst.get(caseSo.Id); 
         
             
         // Get Root Case info in a list        
         //Avoid SOQL query create map 
         //List<Root_Case__c> RootCaseLst = [select request_status__c from Root_Case__c where case_no__c = :caseSo.ID];
         List<Root_Case__c> RootCaseLst = new List<Root_Case__c>();
         if(mapCaseWiseRootCases.containskey(caseSo.Id)){
             RootCaseLst = mapCaseWiseRootCases.get(caseSo.Id);
         } 
            
         // check for request_status field only if this field was modified
         if (!caseSO.Request_Status__c.equals(oldcaseSO.Request_Status__c))
         {
             // 02/15/2018
             // "In Detailed CP/CPS Review" can only be selected after all of the Verified fields either 
             // "Verified" or "Not Applicable", and all corresponding Root Cases have Request status 
             // of one of "In Detailed CP/CPS Review", "On Hold", "Denied" 
              
             if (caseSO.Request_Status__c.equals('In Detailed CP/CPS Review')) 
             {
                 //check old statuses then it should allow back to this status
                 set<string> setofOldStatus = new set<string>{'Ready for Public Discussion','In Public Discussion','Discussion on Hold','CA Action Items from Discussion','Information Verification In Process'};
                 
                 if (caseSO.All_Fields_Verified__c.equals('No')) {
                      caseSO.addError('Request Status "In Detailed CP/CPS Review" can only be selected after all of the Verified fields either "Verified" or "Not Applicable" ');
                 } else if (!setofOldStatus.contains(oldcaseSO.Request_Status__c)){
                     caseSO.addError('Request Status "In Detailed CP/CPS Review" can only be selected after "Information Verification In Process" or "Ready for Public Discussion" or "In Public Discussion" or "Discussion on Hold" or "CA Action Items from Discussion".');
                 }
                 else {
                     
                    // list which holds all the selected RootCaseSo
                    List<Root_Case__c> RootCaseSoToBeCheckedLst = New List<Root_Case__c>();
          
                    for(Root_Case__c RootCaseSo : RootCaseLst)
                    {
                        if (RootCaseSo.request_status__c != 'On Hold' && RootCaseSo.request_status__c != 'Denied' && RootCaseSo.request_status__c != 'In Detailed CP/CPS Review' && RootCaseSo.request_status__c != 'Request Withdrawn by CA') {
                        
                             RootcaseSoToBeCheckedLst.add(RootCaseSo);
                        }
                    }
        
                    // if there is at least one Root Case in the list then flag error
                    if(RootCaseSoToBeCheckedLst.size() > 0)
                    {       
                         caseSO.addError('Request Status "In Detailed CP/CPS Review" can only be selected when all related Root Cases are "On Hold" or "Denied" or "In Detailed CP/CPS Review" or "Request Withdrawn by CA"');
                    }                
                     
                 }
             }       
             
             // 02/15/2018  
             // Request status can only selected after "In Detailed CP/CPS Review"
             // "Ready for Public Discussion" can only be selected after all of the Verified fields either 
             // "Verified" or "Not Applicable", and all corresponding Root Cases have Request status 
             // of one of "Ready For Public Discussion", "On Hold", "Denied" 
              
             if (caseSO.Request_Status__c.equals('Ready for Public Discussion')) 
             {
                 //if (caseSO.All_Fields_Verified__c.equals('No')) {
                 //     caseSO.addError('Request Status "Ready for Public Discussion" can only be selected after all of the Verified fields either "Verified" or "Not Applicable" ');
                 //}
                 
                 if (!oldcaseSO.Request_Status__c.equals('In Detailed CP/CPS Review')){
                     caseSO.addError('Request Status "Ready for Public Discussion" can only be selected after "In Detailed CP/CPS Review"');
                 }
                 else {
                     
                    // list which holds all the selected RootCaseSo
                    List<Root_Case__c> RootCaseSoToBeCheckedLst = New List<Root_Case__c>();
          
                    for(Root_Case__c RootCaseSo : RootCaseLst)
                    {
                        if (RootCaseSo.request_status__c != 'On Hold' && RootCaseSo.request_status__c != 'Denied' && RootCaseSo.request_status__c != 'Ready For Public Discussion' ) {
                        
                             RootcaseSoToBeCheckedLst.add(RootCaseSo);
                        }
                    }
        
                    // if there is at least one Root Case in the list then flag error
                    if(RootCaseSoToBeCheckedLst.size() > 0)
                    {       
                         caseSO.addError('Request Status "Ready for Public Discussion" can only be selected when all related Root Cases are "On Hold" or "Denied" or "Ready for Public Discussion"');
                    }                
                     
                 }
             }
             
     
              // "In Public Discussion" can only be selected after "Ready for Public Discussion" or "Discussion on Hold"
              // and all corresponding Root Cases have Request status 
              // of one of "In Public Discussion", "Discussion on Hold", "On Hold", "Denied" 
    
             if (caseSO.Request_Status__c.equals('In Public Discussion')) {
                 if (!oldcaseSO.Request_Status__c.equals('Ready for Public Discussion') && !oldcaseSO.Request_Status__c.equals('Discussion on Hold')) {
                      caseSO.addError('Request Status "In Public Discussion" can only be selected after "Ready for Public Discussion" or "Discussion on Hold"');
                 }
                 else {
                     
                    // list which holds all the selected RootCaseSo
                    List<Root_Case__c> RootCaseSoToBeCheckedLst = New List<Root_Case__c>();
          
                    for(Root_Case__c RootCaseSo : RootCaseLst)
                    {
                        if (RootCaseSo.request_status__c != 'In Public Discussion') {
                        
                             RootcaseSoToBeCheckedLst.add(RootCaseSo);
                        }
                    }
        
                    // if there is at least one Root Case in the list then flag error
                    if(RootCaseSoToBeCheckedLst.size() > 0)
                    {       
                         caseSO.addError('Request Status "In Public Discussion" can only be selected when all related Root Cases are "In Public Discussion"');
                    }                
                     
                 }
             }
             
             
             // "Discussion on Hold" can only be selected after "In Public Discussion"
             //  and all corresponding Root Cases have Request status of "Discussion on Hold"
             
             if (caseSO.Request_Status__c.equals('Discussion on Hold')) {
                 if (!oldcaseSO.Request_Status__c.equals('In Public Discussion')) {
                      caseSO.addError('Request Status "Discussion on Hold" can only be selected after "In Public Discussion"');
                 }
                 else {
                     
                    // list which holds all the selected RootCaseSo
                    List<Root_Case__c> RootCaseSoToBeCheckedLst = New List<Root_Case__c>();
          
                    for(Root_Case__c RootCaseSo : RootCaseLst)
                    {
                        if (RootCaseSo.request_status__c != 'Discussion on Hold' && RootCaseSo.request_status__c != 'In Public Discussion') {
                        
                             RootcaseSoToBeCheckedLst.add(RootCaseSo);
                        }
                    }
        
                    // if there is at least one Root Case in the list then flag error
                    if(RootCaseSoToBeCheckedLst.size() > 0)
                    {       
                         caseSO.addError('"Discussion on Hold" can only be selected when all related Root Cases are "In Public Discussion" or "Discussion on Hold"');
                    }                
                     
                 }
             }
             
             
             // "Pending Approval" can only be selected after "In Public Discussion" or "CA Action Items from Discussion" 
             // and all corresponding Root Cases have Request status of one of "Pending Approval", "On Hold", "Denied" 
    
             if (caseSO.Request_Status__c.equals('Pending Approval')) {
                 if (!oldcaseSO.Request_Status__c.equals('In Public Discussion') && !oldcaseSO.Request_Status__c.equals('CA Action Items from Discussion')) {
                      caseSO.addError('Request Status "Pending Approval" can only be selected after "In Public Discussion" or "CA Action Items from Discussion"');
                 }
                 else {
                     
                    // list which holds all the selected RootCaseSo
                    List<Root_Case__c> RootCaseSoToBeCheckedLst = New List<Root_Case__c>();
          
                    for(Root_Case__c RootCaseSo : RootCaseLst)
                    {
                        if (RootCaseSo.request_status__c != 'On Hold' && RootCaseSo.request_status__c != 'Denied' && RootCaseSo.request_status__c != 'Pending Approval' ) {
                        
                             RootcaseSoToBeCheckedLst.add(RootCaseSo);
                        }
                    }
        
                    // if there is at least one Root Case in the list then flag error
                    if(RootCaseSoToBeCheckedLst.size() > 0)
                    {       
                         caseSO.addError('Request Status "Pending Approval" can only be selected when all related Root Cases are "On Hold" or "Denied" or "Pending Approval"');
                    }                
                     
                 }
             }
             
             // "Approved, Pending Inclusion" or "Approved, Pending Inclusion and EV" can only be selected after "Pending Approval"
    
            if (caseSO.Request_Status__c.equals('Approved, Pending Inclusion') || caseSO.Request_Status__c.equals('Approved, Pending Inclusion and EV')) {
                 if (!oldcaseSO.Request_Status__c.equals('Pending Approval')) {
                      caseSO.addError('Request Status "Approved, Pending Inclusion" or "Approved, Pending Inclusion and EV" can only be selected after "Pending Approval"');
                 }
                 else {
                     
                    // list which holds all the selected RootCaseSo
                    List<Root_Case__c> RootCaseSoToBeCheckedLst = New List<Root_Case__c>();
          
                    for(Root_Case__c RootCaseSo : RootCaseLst)
                    {
                        if (RootCaseSo.request_status__c != 'On Hold' && RootCaseSo.request_status__c != 'Denied' 
                            && RootCaseSo.request_status__c != 'Approved, Pending Inclusion' && RootCaseSo.request_status__c != 'Approved, Pending Inclusion and EV') {
                        
                             RootcaseSoToBeCheckedLst.add(RootCaseSo);
                        }
                    }
        
                    // if there is at least one Root Case in the list then flag error
                    if(RootCaseSoToBeCheckedLst.size() > 0)
                    {       
                         caseSO.addError('Request Status "Approved, Pending Inclusion" or "Approved, Pending Inclusion and EV" can only be selected when all related Root Cases are "On Hold" or "Denied" or "Approved, Pending Inclusion" or "Approved, Pending Inclusion and EV"');
                    }                
                     
                 }
             }
             
             // "Included, Pending EV" can only be selected after either "Pending Approval" or "Approved, Pending Inclusion and EV"
    
            if (caseSO.Request_Status__c.equals('Included, Pending EV')) {
                 if (!oldcaseSO.Request_Status__c.equals('Pending Approval') && !oldcaseSO.Request_Status__c.equals('Approved, Pending Inclusion and EV')) {
                      caseSO.addError('Request Status "Included, Pending EV" can only be selected after either "Pending Approval" or "Approved, Pending Inclusion and EV"');
                 }
             }
             
     
             // "On Hold" and "Denied" requires a short explanation in the public comments section
             
             if (caseSO.Request_Status__c.equals('On Hold') || caseSO.Request_Status__c.equals('Denied')) {
                 if ((caseSO.Comments__c == NULL) && (caseSO.Internal_Comments_on_Case__c == NULL)) {
                      caseSO.addError('Request Status "On Hold" and "Denied" requires a short explanation in the Internal/Public comments section');
                 }
             }
               
             // "Complete" can only be selected after "Approved, Pending Inclusion" or "Approved, Pending Inclusion and EV" or "Included, Pending EV"
    
             if (caseSO.Request_Status__c.equals('Complete')) {
                 if (!oldcaseSO.Request_Status__c.equals('Approved, Pending Inclusion') && !oldcaseSO.Request_Status__c.equals('Approved, Pending Inclusion and EV') && !oldcaseSO.Request_Status__c.equals('Included, Pending EV')) {
                      caseSO.addError('Request Status "Complete" can only be selected after "Approved, Pending Inclusion" or "Approved, Pending Inclusion and EV" or "Included, Pending EV"');
                 }
             }
            
              //  A Case can have Request Status as 'Included, Pending EV' or 'Complete' 
              //  only when all related root cases are 'On Hold' or 'Denied' or 
              //  'Included, Pending EV' or 'Complete'
                
             if (caseSO.Request_Status__c.equals('Included, Pending EV') || caseSO.Request_Status__c.equals('Complete')) {  
          
                // list which holds all the related RootCaseSo
                List<Root_Case__c> RootCaseSoToBeCheckedLst = New List<Root_Case__c>();
          
                // query the Root Case and iterate over the each RootCaseSo
                for(Root_Case__c RootCaseSo : RootCaseLst) 
                {
                    if (RootCaseSo.request_status__c != 'On Hold' && RootCaseSo.request_status__c != 'Denied' 
                        && RootCaseSo.request_status__c != 'Included, Pending EV' && RootCaseSo.request_status__c != 'Complete' ) {
                        
                         RootcaseSoToBeCheckedLst.add(RootCaseSo);
                   }
                }
        
                // if there is at least one Root Case in the list then flag error
                
                if(RootCaseSoToBeCheckedLst.size() > 0)
                {       
                    caseSO.addError('Request Status "Included, Pending EV" or "Complete" can only be selected when all related Root Cases are "On Hold" or "Denied" or "Included, Pending EV" or "Complete"');
                }
              }
          }
            
          // When Case.Request_Status is 'Complete', change Case.Status to 'Closed' when all related 
          // Root Cases have  Root_Cases.Request_Status = 'Denied' or 'Complete' or 'Request Withdrawn by CA' or 'Included, Pending EV' 
           
            if (caseSO.Request_Status__c.equals('Complete')) {  
      
            // list which holds all the related RootCaseSo
            List<Root_Case__c> RootCaseSoToBeCheckedLst = New List<Root_Case__c>();
      
            // query the Root Case and iterate over the each RootCaseSo
            for(Root_Case__c RootCaseSo : RootCaseLst) 
            {
                if (RootCaseSo.request_status__c != 'Denied' 
                    && RootCaseSo.request_status__c != 'Included, Pending EV' 
                    && RootCaseSo.request_status__c != 'Complete' ) 
                {
                    RootcaseSoToBeCheckedLst.add(RootCaseSo);
                }
            }
   
            if(RootCaseSoToBeCheckedLst.size() > 0) {
                
                caseSO.addError('Request Status "Complete" can only be selected when all related Root Cases are "Included, Pending EV" or "Denied" or "Complete"');
            }
            else {
                caseSO.Status = 'Closed';
            }
         }

         // When Request Status is 'Request Withdrawn by CA' set Status to 'Closed' when all related 
         // Root Cases have  Root_Cases.Request_Status = 'Request Withdrawn by CA'

            if (caseSO.Request_Status__c.equals('Request Withdrawn by CA')) {  
      
            // list which holds all the related RootCaseSo
            List<Root_Case__c> RootCaseSoToBeCheckedLst = New List<Root_Case__c>();
      
            // query the Root Case and iterate over the each RootCaseSo
            for(Root_Case__c RootCaseSo : RootCaseLst) 
            {
                if (RootCaseSo.request_status__c != 'Request Withdrawn by CA') 
                {
                    RootcaseSoToBeCheckedLst.add(RootCaseSo);
                }
            }
   
            if(RootCaseSoToBeCheckedLst.size() > 0) {
                
                caseSO.addError('Request Status "Request Withdrawn by CA" can only be selected when all related Root Cases are "Request Withdrawn by CA"');
            }
            else {
                caseSO.Status = 'Closed';
            }
         }
          
          // When Request Status is 'On Hold' set the Case.Status to 'On Hold'
          // Keep the Case 'Open' when Request Status is other than 'Complete' or 'Request Withdrawn by CA'
          
          if (caseSO.Request_Status__c.equals('On Hold')) {
                 caseSO.Status = 'On Hold';              
            }
            else if (!caseSO.Request_Status__c.equals('Complete') && !caseSO.Request_Status__c.equals('Denied') && !caseSO.Request_Status__c.equals('Request Withdrawn by CA')) {
                caseSO.Status = 'Open';
            } 
            
          }  // process cases for recod type = 'CA Owner/Root Inclusion Request'
       }
       */
    }

    public static void EnforceRequestStatusRulesForAuditUpdates (List<Case> caseSoLst, Map<Id, Case> oldcaseSoLst){
 
        // process cases with record type = 'CA Audit Update Request'
        String caseAuditUpdateRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('CA Audit Update Request').getRecordTypeId();
     
     
        set<Id> setofCaseIdsToClose = new set<Id>();
        // loop over all the cases which were updated
        for(Case caseSo : caseSoLst){
            if(caseSO.RecordTypeId == caseAuditUpdateRecordTypeId){  // process record type 'CA Audit Update Request' only      
                //Enforce Error if all policy documents are not completed with sync
                if(caseSO.Status == 'Closed' && caseSO.Status != oldcaseSoLst.get(caseSO.Id).Status){
                    setofCaseIdsToClose.add(caseSO.Id);
                }
            }
        }
        set<Id> setofCaseIdsHavingPolicyDocumentWOComplete = new set<Id>();
        if(setofCaseIdsToClose.size() > 0) {
            for(Policy_Document_On_Case__c PDC: [select Id, Case__c from Policy_Document_On_Case__c Where Case__c in: setofCaseIdsToClose
                   and Document_Verified__c != 'Complete']){
                setofCaseIdsHavingPolicyDocumentWOComplete.add(PDC.Case__c);
            }
        }
           
        // loop over all the cases which were updated
        for(Case caseSo : caseSoLst)
        {
           
          if(caseSO.RecordTypeId == caseAuditUpdateRecordTypeId){  // process record type 'CA Audit Update Request' only      
          
          //Enforce Error if all policy documents are not completed with sync
          //Error message should not display when they close case without sync
          if(string.isblank(caseSO.Reason_for_Close_without_Sync__c) && caseSO.Status == 'Closed' && 
              caseSO.Status != oldcaseSoLst.get(caseSO.Id).Status && setofCaseIdsHavingPolicyDocumentWOComplete.contains(caseSO.Id)){
              caseSO.addError('There are policy documents which are not complete. You need to verify Policy Documents before closing Case.');
          }
          
          // Set oldcaseSo to trigger.old value        
          Case oldcaseSO = oldcaseSOLst.get(caseSo.Id); 
          
          // Get Root Case info in a list        
          // List<Root_Case__c> RootCaseLst = [select request_status__c from Root_Case__c where case_no__c = :caseSo.ID];
          
          // system.debug('caseSO.Request_Status__c: '+caseSO.Request_Status__c);
          // system.debug('oldcaseSO.Request_Status__c: '+oldcaseSO.Request_Status__c);
          // system.debug('Standard_Audit_Type__c: '+Standard_Audit_Type__c);
          if ((caseSO.Request_Status__c == 'Complete' && oldcaseSO.Request_Status__c == 'Complete') || 
              (caseSO.Status == 'Closed' && oldcaseSO.Status == 'Closed')) {
          
             if (caseSO.Subject != oldcaseSO.Subject ||
                caseSO.RecordTypeId != caseSO.RecordTypeId ||
                caseSO.Request_Status__c != oldcaseSO.Request_Status__c ||
                caseSO.Recognized_CAA_Domains__c != oldcaseSO.Recognized_CAA_Domains__c ||
                caseSO.Problem_Reporting_Mechanism__c != oldcaseSO.Problem_Reporting_Mechanism__c ||
                caseSO.Standard_Audit_Verified__c != oldcaseSO.Standard_Audit_Verified__c ||
                caseSO.Standard_Audit_Statement_Link__c != oldcaseSO.Standard_Audit_Statement_Link__c ||
                caseSO.Standard_Audit_Type__c !=oldcaseSO.Standard_Audit_Type__c ||
                caseSO.Standard_Audit_Statement_Date__c != oldcaseSO.Standard_Audit_Statement_Date__c ||
                caseSO.Standard_Audit_Period_Start_Date__c != oldcaseSO.Standard_Audit_Period_Start_Date__c ||
                caseSO.Standard_Audit_Period_End_Date__c != oldcaseSO.Standard_Audit_Period_End_Date__c ||
                caseSO.Standard_Audit_Authenticity_Confirmed__c != oldcaseSO.Standard_Audit_Authenticity_Confirmed__c ||
                caseSO.Standard_Audit_ALV_Comments__c != oldcaseSO.Standard_Audit_ALV_Comments__c || 
                caseSO.Auditor_Verified__c != oldcaseSO.Auditor_Verified__c ||
                caseSO.Auditor_New__c != oldcaseSO.Auditor_New__c ||
                caseSO.Auditor_Location_New__c != oldcaseSO.Auditor_Location_New__c ||
                //caseSO.Management_Assertions_By__c !=oldcaseSO.Management_Assertions_By__c ||
                caseSO.Standard_Audit_Verified__c !=oldcaseSO.Standard_Audit_Verified__c ||
                caseSO.Code_Signing_Audit_Verified__c != oldcaseSO.Code_Signing_Audit_Verified__c ||
                caseSO.Code_Signing_Audit_Statement_Link__c != oldcaseSO.Code_Signing_Audit_Statement_Link__c ||
                caseSO.Code_Signing_Audit_Type__c != oldcaseSO.Code_Signing_Audit_Type__c ||
                caseSO.Code_Signing_Audit_Statement_Date__c != oldcaseSO.Code_Signing_Audit_Statement_Date__c ||
                caseSO.Code_Signing_Audit_Period_Start_Date__c != oldcaseSO.Code_Signing_Audit_Period_Start_Date__c ||
                caseSO.Code_Signing_Audit_Period_End_Date__c != oldcaseSO.Code_Signing_Audit_Period_End_Date__c ||
                caseSO.Code_Signing_Audit_Authenticity_Confirm__c != oldcaseSO.Code_Signing_Audit_Authenticity_Confirm__c ||
                caseSO.Code_Signing_Audit_ALV_Comments__c != oldcaseSO.Code_Signing_Audit_ALV_Comments__c ||
                caseSO.BR_Audit_Statement_Link_Verified__c != oldcaseSO.BR_Audit_Statement_Link_Verified__c ||
                caseSO.BR_Audit_Statement_Link__c != oldcaseSO.BR_Audit_Statement_Link__c ||
                caseSO.BR_Audit_Type__c != oldcaseSO.BR_Audit_Type__c ||
                caseSO.BR_Audit_Statement_Date__c != oldcaseSO.BR_Audit_Statement_Date__c ||
                caseSO.BR_Audit_Period_Start_Date__c != oldcaseSO.BR_Audit_Period_Start_Date__c ||
                caseSO.BR_Audit_Period_End_Date__c != oldcaseSO.BR_Audit_Period_End_Date__c ||
                caseSO.BR_Audit_Authenticity_Confirmed__c != oldcaseSO.BR_Audit_Authenticity_Confirmed__c ||
                caseSO.BR_Audit_ALV_Comments__c != oldcaseSO.BR_Audit_ALV_Comments__c ||                               
                caseSO.EV_Audit_Statement_Link_Verified__c !=oldcaseSO.EV_Audit_Statement_Link_Verified__c ||
                caseSO.EV_Audit_Statement_Link__c !=oldcaseSO.EV_Audit_Statement_Link__c ||
                caseSO.EV_Audit_Type__c !=oldcaseSO.EV_Audit_Type__c ||
                caseSO.EV_Audit_Statement_Date__c !=oldcaseSO.EV_Audit_Statement_Date__c ||
                caseSO.EV_Audit_Period_Start_Date__c !=oldcaseSO.EV_Audit_Period_Start_Date__c ||
                caseSO.EV_Audit_Period_End_Date__c !=oldcaseSO.EV_Audit_Period_End_Date__c || 
                caseSO.EV_SSL_Audit_Authenticity_Confirmed__c != oldcaseSO.EV_SSL_Audit_Authenticity_Confirmed__c ||               
                caseSO.EV_SSL_Audit_ALV_Comments__c != oldcaseSO.EV_SSL_Audit_ALV_Comments__c ||                
                caseSO.EV_Code_Signing_Verified__c !=oldcaseSO.EV_Code_Signing_Verified__c ||                                           
                caseSO.EV_Code_Signing_Audit_Statement_Link__c !=oldcaseSO.EV_Code_Signing_Audit_Statement_Link__c ||
                caseSO.EV_Code_Signing_Audit_Type__c !=oldcaseSO.EV_Code_Signing_Audit_Type__c ||               
                caseSO.EV_Code_Signing_Audit_Statement_Date__c !=oldcaseSO.EV_Code_Signing_Audit_Statement_Date__c ||
                caseSO.EV_Code_Signing_Audit_Period_Start_Date__c !=oldcaseSO.EV_Code_Signing_Audit_Period_Start_Date__c ||
                caseSO.EV_Code_Signing_Audit_Period_End_Date__c !=oldcaseSO.EV_Code_Signing_Audit_Period_End_Date__c ||
                caseSO.EV_Code_Signing_Audit_Auth_Confirmed__c != oldcaseSO.EV_Code_Signing_Audit_Auth_Confirmed__c ||
                caseSO.EV_Code_Signing_Audit_ALV_Comments__c != oldcaseSO.EV_Code_Signing_Audit_ALV_Comments__c ||                                          
                caseSO.CP_CPS_Links_Verified__c != oldcaseSO.CP_CPS_Links_Verified__c ||
                caseSO.CA_Document_Repository__c != oldcaseSO.CA_Document_Repository__c ||
                caseSO.Certificate_Policy_Link__c != oldcaseSO.Certificate_Policy_Link__c ||
                caseSO.Certification_Practice_Statement_Link__c != oldcaseSO.Certification_Practice_Statement_Link__c ||
                caseSO.CP_CPS_Last_Updated_Date__c != oldcaseSO.CP_CPS_Last_Updated_Date__c ||
                caseSO.Policy_Documentation__c != oldcaseSO.Policy_Documentation__c ||
                caseSO.CP_CPS_Links_Verified__c != oldcaseSO.CP_CPS_Links_Verified__c ||
                caseSO.Description != oldcaseSO.Description ||
                caseSO.Internal_Comments_on_Case__c != oldcaseSO.Internal_Comments_on_Case__c ||
                caseSO.Comments__c != oldcaseSO.Comments__c ||
                caseSO.Status != oldcaseSO.Status ||
                caseSO.Priority != oldcaseSO.Priority){
                    
                    caseSO.addError('Completed & Closed Case cannot be modified.');
                }
          
          }
          
          //do not allow user to modify auditor field
          if (caseSO.Auditor_Verified__c == oldcaseSO.Auditor_Verified__c && 
              caseSO.Auditor_Verified__c == 'Data Verified' &&
               (caseSo.Auditor_New__c != oldcaseSO.Auditor_New__c ||
               caseSo.Auditor_Location_New__c != oldcaseSO.Auditor_Location_New__c)){
               caseSO.addError('Data has been verified. You cannot modify Auditor fields'); 
           }
          
          //check Standard audit verified field and Audit Authenticity Confirmed is false
          if (caseSO.Standard_Audit_Verified__c != oldcaseSO.Standard_Audit_Verified__c && 
              caseSO.Standard_Audit_Verified__c == 'Data Verified' && !caseSo.Standard_Audit_Authenticity_Confirmed__c){
              caseSO.addError('Standard Audit Authenticity Confirmed should be checked before Data Verified.'); 
          }
          
          //do not allow user to modify standard audit block 
          if (caseSO.Standard_Audit_Verified__c == oldcaseSO.Standard_Audit_Verified__c && 
              caseSO.Standard_Audit_Verified__c == 'Data Verified' && 
              (caseSo.Standard_Audit_Statement_Link__c != oldcaseSO.Standard_Audit_Statement_Link__c ||  
               caseSo.Standard_Audit_Type__c != oldcaseSO.Standard_Audit_Type__c || 
               caseSo.Standard_Audit_Statement_Date__c != oldcaseSO.Standard_Audit_Statement_Date__c || 
               caseSo.Standard_Audit_Period_Start_Date__c != oldcaseSO.Standard_Audit_Period_Start_Date__c ||
               caseSo.Standard_Audit_Period_End_Date__c != oldcaseSO.Standard_Audit_Period_End_Date__c ||             
               //caseSo.Management_Assertions_By__c != oldcaseSO.Management_Assertions_By__c ||
               caseSo.Standard_Audit_Authenticity_Confirmed__c != oldcaseSo.Standard_Audit_Authenticity_Confirmed__c ||
               caseSo.Standard_Audit_ALV_Comments__c != oldcaseSO.Standard_Audit_ALV_Comments__c ||
               caseSo.Standard_Deviation__c != oldcaseSo.Standard_Deviation__c ||
               caseSo.Standard_Deviation_Comments__c != oldcaseSO.Standard_Deviation_Comments__c
               )) {
               caseSO.addError('Data has been verified. You cannot modify Standard Audit fields');                      
          }
          
          //check Code signing audit verified field and Audit Authenticity Confirmed is false
          if (caseSO.Code_Signing_Audit_Verified__c != oldcaseSO.Code_Signing_Audit_Verified__c && 
              caseSO.Code_Signing_Audit_Verified__c == 'Data Verified' && !caseSo.Code_Signing_Audit_Authenticity_Confirm__c){
              caseSO.addError('Code Signing Audit Authenticity Confirmed should be checked before Data Verified.'); 
          }
          
          // do not allow user to modify code signing audit block 
          if (caseSO.Code_Signing_Audit_Verified__c == oldcaseSO.Code_Signing_Audit_Verified__c &&
              caseSO.Code_Signing_Audit_Verified__c == 'Data Verified' && 
              (caseSo.Code_Signing_Audit_Statement_Link__c != oldcaseSO.Code_Signing_Audit_Statement_Link__c ||  
              caseSo.Code_Signing_Audit_Type__c != oldcaseSO.Code_Signing_Audit_Type__c || 
              caseSo.Code_Signing_Audit_Statement_Date__c != oldcaseSO.Code_Signing_Audit_Statement_Date__c || 
              caseSo.Code_Signing_Audit_Period_Start_Date__c != oldcaseSO.Code_Signing_Audit_Period_Start_Date__c ||
              caseSo.Code_Signing_Audit_Period_End_Date__c != oldcaseSO.Code_Signing_Audit_Period_End_Date__c ||
              caseSo.Code_Signing_Audit_Authenticity_Confirm__c != oldcaseSO.Code_Signing_Audit_Authenticity_Confirm__c ||
              caseSo.Code_Signing_Audit_ALV_Comments__c != oldcaseSO.Code_Signing_Audit_ALV_Comments__c ||
              caseSo.Code_Signing_Deviation__c != oldcaseSo.Code_Signing_Deviation__c ||
              caseSo.Code_Signing_Deviation_Comments__c != oldcaseSO.Code_Signing_Deviation_Comments__c
              )) {
              caseSO.addError('Data has been verified. You cannot modify Code Signing audit fields');                      
          }
          
          //check BR audit verified field and Audit Authenticity Confirmed is false
          if (caseSO.BR_Audit_Statement_Link_Verified__c != oldcaseSO.BR_Audit_Statement_Link_Verified__c  && 
              caseSO.BR_Audit_Statement_Link_Verified__c == 'Data Verified' && !caseSo.BR_Audit_Authenticity_Confirmed__c){
              caseSO.addError('BR Audit Authenticity Confirmed should be checked before Data Verified.'); 
          }
                      
          // do not allow user to modify BR audit block 
          if (caseSO.BR_Audit_Statement_Link_Verified__c == oldcaseSO.BR_Audit_Statement_Link_Verified__c &&
              caseSO.BR_Audit_Statement_Link_Verified__c == 'Data Verified' && 
              (caseSo.BR_Audit_Statement_Link__c != oldcaseSO.BR_Audit_Statement_Link__c ||  
              caseSo.BR_Audit_Type__c != oldcaseSO.BR_Audit_Type__c || 
              caseSo.BR_Audit_Statement_Date__c != oldcaseSO.BR_Audit_Statement_Date__c || 
              caseSo.BR_Audit_Period_Start_Date__c != oldcaseSO.BR_Audit_Period_Start_Date__c ||
              caseSo.BR_Audit_Period_End_Date__c != oldcaseSO.BR_Audit_Period_End_Date__c ||
              caseSo.BR_Audit_Authenticity_Confirmed__c != oldcaseSO.BR_Audit_Authenticity_Confirmed__c ||
              caseSo.BR_Audit_ALV_Comments__c != oldcaseSO.BR_Audit_ALV_Comments__c ||
              caseSo.BR_Deviation__c != oldcaseSo.BR_Deviation__c ||
              caseSo.BR_Deviation_Comments__c != oldcaseSO.BR_Deviation_Comments__c
              )) {
              caseSO.addError('Data has been verified. You cannot modify BR audit fields');                      
          }
          
          //check EV SSL audit verified field and Audit Authenticity Confirmed is false
          if (caseSO.EV_Audit_Statement_Link_Verified__c != oldcaseSO.EV_Audit_Statement_Link_Verified__c && 
              caseSO.EV_Audit_Statement_Link_Verified__c == 'Data Verified' && !caseSo.EV_SSL_Audit_Authenticity_Confirmed__c){
              caseSO.addError('EV SSL Audit Authenticity Confirmed should be checked before Data Verified.'); 
          }
          //system.debug('AA ::: '+caseSo.EV_SSL_Audit_ALV_Comments__c.escapeJava()+ 'BB :: ' + oldcaseSO.EV_SSL_Audit_ALV_Comments__c.escapeJava());
          //system.debug('AA ::: '+caseSo.EV_SSL_Deviation_Comments__c.escapeJava()+ 'BB :: ' + oldcaseSO.EV_SSL_Deviation_Comments__c.escapeJava());
          //system.debug('AA ::: '+caseSo.EV_Audit_Statement_Link__c.escapeJava()+ 'BB :: ' +  oldcaseSO.EV_Audit_Statement_Link__c.escapeJava());
          // do not allow user to modify EV SSL audit block 
          if (caseSO.EV_Audit_Statement_Link_Verified__c == oldcaseSO.EV_Audit_Statement_Link_Verified__c &&
              caseSO.EV_Audit_Statement_Link_Verified__c == 'Data Verified' && 
              (caseSo.EV_Audit_Statement_Link__c != oldcaseSO.EV_Audit_Statement_Link__c ||  
              caseSo.EV_Audit_Type__c != oldcaseSO.EV_Audit_Type__c || 
              caseSo.EV_Audit_Statement_Date__c != oldcaseSO.EV_Audit_Statement_Date__c || 
              caseSo.EV_Audit_Period_Start_Date__c != oldcaseSO.EV_Audit_Period_Start_Date__c ||
              caseSo.EV_Audit_Period_End_Date__c != oldcaseSO.EV_Audit_Period_End_Date__c ||
              caseSo.EV_SSL_Audit_Authenticity_Confirmed__c != oldcaseSO.EV_SSL_Audit_Authenticity_Confirmed__c ||
              caseSo.EV_SSL_Audit_ALV_Comments__c != oldcaseSO.EV_SSL_Audit_ALV_Comments__c ||
              caseSo.EV_SSL_Deviation__c != oldcaseSo.EV_SSL_Deviation__c ||
              caseSo.EV_SSL_Deviation_Comments__c != oldcaseSO.EV_SSL_Deviation_Comments__c
              )) {
              caseSO.addError('Data has been verified. You cannot modify EV SSL audit fields');                      
          }
          
          //check EV Code Signing audit verified field and Audit Authenticity Confirmed is false
          if (caseSO.EV_Code_Signing_Verified__c != oldcaseSO.EV_Code_Signing_Verified__c && 
              caseSO.EV_Code_Signing_Verified__c == 'Data Verified' && !caseSo.EV_Code_Signing_Audit_Auth_Confirmed__c){
              caseSO.addError('EV Code Signing Authenticity Confirmed should be checked before Data Verified.'); 
          }
          
          // do not allow user to modify EV Code Signing audit block 
          if (caseSO.EV_Code_Signing_Verified__c == oldcaseSO.EV_Code_Signing_Verified__c &&
              caseSO.EV_Code_Signing_Verified__c == 'Data Verified' && 
              (caseSo.EV_Code_Signing_Audit_Statement_Link__c != oldcaseSO.EV_Code_Signing_Audit_Statement_Link__c ||  
              caseSo.EV_Code_Signing_Audit_Type__c != oldcaseSO.EV_Code_Signing_Audit_Type__c || 
              caseSo.EV_Code_Signing_Audit_Statement_Date__c != oldcaseSO.EV_Code_Signing_Audit_Statement_Date__c || 
              caseSo.EV_Code_Signing_Audit_Period_Start_Date__c != oldcaseSO.EV_Code_Signing_Audit_Period_Start_Date__c ||
              caseSo.EV_Code_Signing_Audit_Period_End_Date__c != oldcaseSO.EV_Code_Signing_Audit_Period_End_Date__c ||
              caseSo.EV_Code_Signing_Audit_Auth_Confirmed__c != oldcaseSO.EV_Code_Signing_Audit_Auth_Confirmed__c ||
              caseSo.EV_Code_Signing_Audit_ALV_Comments__c != oldcaseSO.EV_Code_Signing_Audit_ALV_Comments__c ||
              caseSo.EV_Code_Signing_Deviation__c != oldcaseSo.EV_Code_Signing_Deviation__c ||
              caseSo.EV_Code_Signing_Deviation_Comments__c != oldcaseSO.EV_Code_Signing_Deviation_Comments__c
              )) {
              
              caseSO.addError('Data has been verified. You cannot modify EV Code Signing audit fields');                      
          }          
          
          // Commented by Poonam on 8/24/2020
          // do not allow user to modify CP/CPS audit block 
          /* if (caseSO.CP_CPS_Links_Verified__c == 'Data Verified' && 
              (caseSo.CA_Document_Repository__c != oldcaseSO.CA_Document_Repository__c ||  
               caseSo.Policy_Documentation__c != oldcaseSO.Policy_Documentation__c || 
               caseSo.Certificate_Policy_Link__c != oldcaseSO.Certificate_Policy_Link__c || 
               caseSo.Certification_Practice_Statement_Link__c != oldcaseSO.Certification_Practice_Statement_Link__c ||
               caseSo.CP_CPS_Last_Updated_Date__c != oldcaseSO.CP_CPS_Last_Updated_Date__c)) {
              
               caseSO.addError('Data has been verified. You cannot modify CP/CPS information');                      
          } */
                     
          // if all fields verified, change the Request Status to 'Data Verified'
          if (caseSO.Request_Status__c != 'Complete') {
              if (caseSO.Auditor_Verified__c != oldcaseSO.Auditor_Verified__c ||
              caseSO.Standard_Audit_Verified__c != oldcaseSO.Standard_Audit_Verified__c ||
              caseSO.Code_Signing_Audit_Verified__c != oldcaseSO.Code_Signing_Audit_Verified__c ||
              caseSO.BR_Audit_Statement_Link_Verified__c != oldcaseSO.BR_Audit_Statement_Link_Verified__c ||
              caseSO.EV_Audit_Statement_Link_Verified__c != oldcaseSO.EV_Audit_Statement_Link_Verified__c ||
              caseSO.EV_Code_Signing_Verified__c != oldcaseSO.EV_Code_Signing_Verified__c ||
              caseSO.CP_CPS_Links_Verified__c != oldcaseSO.CP_CPS_Links_Verified__c) {
                  if ((caseSO.Auditor_Verified__c != null && caseSO.Auditor_Verified__c.equals('Data Verified')) && 
                      (caseSO.Standard_Audit_Verified__c != null && (caseSO.Standard_Audit_Verified__c.equals('Data Verified') || caseSO.Standard_Audit_Verified__c.equals('Not Applicable'))) && 
                      ((caseSO.Code_Signing_Audit_Verified__c != null && (caseSO.Code_Signing_Audit_Verified__c.equals('Data Verified') || caseSO.Code_Signing_Audit_Verified__c.equals('Not Applicable')))) &&
                      ((caseSO.BR_Audit_Statement_Link_Verified__c != null && (caseSO.BR_Audit_Statement_Link_Verified__c.equals('Data Verified') || caseSO.BR_Audit_Statement_Link_Verified__c.equals('Not Applicable')))) &&
                      ((caseSO.EV_Audit_Statement_Link_Verified__c != null && (caseSO.EV_Audit_Statement_Link_Verified__c.equals('Data Verified') || caseSO.EV_Audit_Statement_Link_Verified__c.equals('Not Applicable')))) &&
                      ((caseSO.EV_Code_Signing_Verified__c != null && (caseSO.EV_Code_Signing_Verified__c.equals('Data Verified') || caseSO.EV_Code_Signing_Verified__c.equals('Not Applicable')))) &&                     
                      (caseSO.CP_CPS_Links_Verified__c != null && caseSO.CP_CPS_Links_Verified__c.equals('Data Verified'))){
                      //commented exist code and change status from Data Verified to 'Verification By Root Store' - on 11th May 2020
                      caseSO.Request_Status__c = 'Verification By Root Store'; 
                      //caseSO.Request_Status__c = 'Data Verified';
                  } else {
                      caseSO.Request_Status__c = 'Initial Request Received';
                  }
              } 
            }
            // do not allow root store manager to approve a case if the data is not verified
            if (caseSO.Request_Status__c != 'Complete' && caseSO.Request_Status__c != 'Data Verified' && caseSO.Approval_Status__c == 'Approved') {
                caseSO.addError('Root Store Manager must verify audit fields and set verified fields to ‘Data Verified’ before approving the case.');
            }
          } 
       } // for loop all cases of type 'CA Audit Update Request'
    }
    
    //New method for sharing by Sunil
    public static void ManualCaseSharing(List<Case> lstModifiedCases) {
        set<Id> setCaseIds = new set<Id>();
        set<Id> setAccountIds = new set<Id>();
        for(Case objCase: lstModifiedCases){
            setCaseIds.add(objCase.Id);
            setAccountIds.add(objCase.AccountId);
        }
        map<Id,set<Id>> mapAccountWiseGroup = new map<Id,set<Id>>();
        map<Id,Id> mapAccountwiseUR = new map<Id,Id>();
        for(UserRole objUR: [Select Id, Name, PortalAccountId From UserRole Where PortalAccountId in: setAccountIds]){
            mapAccountwiseUR.put(objUR.Id,objUR.PortalAccountId);
        }
        for(Group objG : [SELECT Id, Name, DeveloperName, RelatedId, Type, Email FROM 
                    Group Where RelatedId in: mapAccountwiseUR.keyset()]){
            if(mapAccountwiseUR.containskey(objG.RelatedId)) {
                if(mapAccountWiseGroup.containskey(mapAccountwiseUR.get(objG.RelatedId))){
                    mapAccountWiseGroup.get(mapAccountwiseUR.get(objG.RelatedId)).add(objG.Id);
                } else {
                    mapAccountWiseGroup.put(mapAccountwiseUR.get(objG.RelatedId), new set<Id>{objG.Id});
                }
            }
        }
        map<Id,List<CaseShare>> mapExistingCaseSharing = new map<Id,List<CaseShare>>();
        map<Id,set<Id>> mapExistingCaseSharingGroup = new map<Id,set<Id>>();
        for(CaseShare objCS : [SELECT Id, CaseId, UserOrGroupId, CaseAccessLevel, RowCause, LastModifiedDate, 
                LastModifiedById, IsDeleted FROM CaseShare Where CaseId in :setCaseIds]){
            if(mapExistingCaseSharing.containskey(objCS.CaseId)) {
                mapExistingCaseSharing.get(objCS.CaseId).add(objCS);
            } else {
                mapExistingCaseSharing.put(objCS.CaseId, new List<CaseShare>{objCS});
            }
            if(mapExistingCaseSharingGroup.containskey(objCS.CaseId)){
                mapExistingCaseSharingGroup.get(objCS.CaseId).add(objCS.UserOrGroupId);
            } else {
                mapExistingCaseSharingGroup.put(objCS.CaseId, new set<Id>{objCS.UserOrGroupId});
            }
        } 
        //String caseAuditUpdateRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('CA Audit Update Request').getRecordTypeId();
        List<CaseShare> lstCaseSharetoUpsert = new List<CaseShare>();
        for(Case objCase: lstModifiedCases){
            //commented record type id condition 
            //if(objCase.RecordTypeId == caseAuditUpdateRecordTypeId){
                if(mapExistingCaseSharing.containskey(objCase.Id)) {
                    if(mapAccountWiseGroup.containskey(objCase.AccountId)) {
                        for(Id groupId: mapAccountWiseGroup.get(objCase.AccountId)){
                            system.debug('Group Id ::: '+groupId);
                            if(mapExistingCaseSharingGroup.containskey(objCase.Id) &&
                                !mapExistingCaseSharingGroup.get(objCase.Id).contains(groupId)) {
                                CaseShare objCaseShare = new CaseShare();
                                objCaseShare.CaseAccessLevel = 'Edit';
                                objCaseShare.CaseId = objCase.Id;
                                objCaseShare.UserOrGroupId = groupId;
                                lstCaseSharetoUpsert.add(objCaseShare);
                            }
                        }
                    }
                } else {
                    if(mapAccountWiseGroup.containskey(objCase.AccountId)) {
                        for(Id groupId: mapAccountWiseGroup.get(objCase.AccountId)){
                            CaseShare objCaseShare = new CaseShare();
                            objCaseShare.CaseAccessLevel = 'Edit';
                            objCaseShare.CaseId = objCase.Id;
                            objCaseShare.UserOrGroupId = groupId;
                            lstCaseSharetoUpsert.add(objCaseShare);
                        }
                    }
                }
            /*} else {
                if(mapExistingCaseSharing.containskey(objCase.Id)) {
                    for(CaseShare objCS: mapExistingCaseSharing.get(objCase.Id)) {
                        if(objCS.RowCause == 'RelatedPortalUser' && objCS.CaseAccessLevel == 'Edit'){
                            objCS.CaseAccessLevel = 'Read';
                            lstCaseSharetoUpsert.add(objCS);
                        }
                    }
                }
            }*/
        }
        
        if(lstCaseSharetoUpsert.size() > 0) {
            upsert lstCaseSharetoUpsert;
        }
    }
    
    
    /*
        Method is used to check for Audit Gaps between Root Case and Certificate
    */
    public static void UpdateAuditGaps(List<Case> lstCasesUpdated, map<Id,Case> mapOldCases){
        set<Id> setOfCaseIds = new set<Id>();
        for(Case objCase: lstCasesUpdated){
            //check if audit start date has changed then it should check for audit gaps
            if(objCase.Standard_Audit_Period_Start_Date__c != mapOldCases.get(objCase.Id).Standard_Audit_Period_Start_Date__c ||
                objCase.Code_Signing_Audit_Period_Start_Date__c != mapOldCases.get(objCase.Id).Code_Signing_Audit_Period_Start_Date__c ||
                objCase.BR_Audit_Period_Start_Date__c != mapOldCases.get(objCase.Id).BR_Audit_Period_Start_Date__c ||
                objCase.EV_Audit_Period_Start_Date__c != mapOldCases.get(objCase.Id).EV_Audit_Period_Start_Date__c ||
                objCase.EV_Code_Signing_Audit_Period_Start_Date__c != mapOldCases.get(objCase.Id).EV_Code_Signing_Audit_Period_Start_Date__c ||
                objCase.Count_of_Root_Case_s__c != mapOldCases.get(objCase.Id).Count_of_Root_Case_s__c){
                setOfCaseIds.add(objCase.Id);
            }
        }
        if(setOfCaseIds.size() > 0){
            List<Root_Case__c> lstRootCasesToUpdate = new List<Root_Case__c>();
            //check and update root cases if there is any audit date gap
            for(Root_Case__c objRC: [select Id,Name,Root_Certificate_Name_Existing__c, 
                    Case_No__c,Case_No__r.Standard_Audit_Period_Start_Date__c, Root_Certificate_Name_Existing__r.Standard_Audit_Period_End_Date__c,
                    Case_No__r.Code_Signing_Audit_Period_Start_Date__c, Root_Certificate_Name_Existing__r.Code_Signing_Audit_Period_End_Date__c,
                    Case_No__r.BR_Audit_Period_Start_Date__c, Root_Certificate_Name_Existing__r.BR_Audit_Period_End_Date__c,
                    Case_No__r.EV_Audit_Period_Start_Date__c, Root_Certificate_Name_Existing__r.EV_Audit_Period_End_Date__c,
                    Case_No__r.EV_Code_Signing_Audit_Period_Start_Date__c, Root_Certificate_Name_Existing__r.EV_Code_Signing_Audit_Period_End_Date__c,
                    Apply_Standard_Audit__c,Apply_BR_Audit__c,Apply_EV_Audit__c,Apply_EV_Code_Signing_Audit__c,Apply_Code_Signing_Audit__c,
                    Standard_Audit_Date_Gap__c,BR_Audit_Date_Gap__c,EV_SSL_Audit_Date_Gap__c,EV_Code_Signing_Audit_Date_Gap__c,Code_Signing_Audit_Date_Gap__c ,
                    Test_Website_Valid__c,Test_Website_Revoked__c,Test_Website_Expired__c,Microsoft_Trust_Bits__c,Trust_Bits__c
                    from Root_Case__c Where Case_No__c in: setOfCaseIds]){
                if(objRC.Root_Certificate_Name_Existing__c != null){
                    //default set all audit gaps false
                    objRC.Standard_Audit_Date_Gap__c = false;
                    objRC.Code_Signing_Audit_Date_Gap__c = false;
                    objRC.BR_Audit_Date_Gap__c = false;
                    objRC.EV_SSL_Audit_Date_Gap__c = false;
                    objRC.EV_Code_Signing_Audit_Date_Gap__c = false;
                    //check if daysbetween root certs's audit end date and case's audit start date is greater than > 2 then flag audit gap
                    if(objRC.Apply_Standard_Audit__c && objRC.Case_No__r.Standard_Audit_Period_Start_Date__c != null && objRC.Root_Certificate_Name_Existing__r.Standard_Audit_Period_End_Date__c != null &&
                        objRC.Root_Certificate_Name_Existing__r.Standard_Audit_Period_End_Date__c.DaysBetween(objRC.Case_No__r.Standard_Audit_Period_Start_Date__c) > 2){
                        objRC.Standard_Audit_Date_Gap__c = true;
                    }
                    if(objRC.Apply_Code_Signing_Audit__c && objRC.Case_No__r.Code_Signing_Audit_Period_Start_Date__c != null && objRC.Root_Certificate_Name_Existing__r.Code_Signing_Audit_Period_End_Date__c != null &&
                        objRC.Root_Certificate_Name_Existing__r.Code_Signing_Audit_Period_End_Date__c.DaysBetween(objRC.Case_No__r.Code_Signing_Audit_Period_Start_Date__c) > 2){
                        objRC.Code_Signing_Audit_Date_Gap__c = true;
                    }
                    system.debug('objRC.Code_Signing_Audit_Date_Gap__c ::: '+objRC.Code_Signing_Audit_Date_Gap__c);
                    if(objRC.Apply_BR_Audit__c && objRC.Case_No__r.BR_Audit_Period_Start_Date__c != null && objRC.Root_Certificate_Name_Existing__r.BR_Audit_Period_End_Date__c != null &&
                        objRC.Root_Certificate_Name_Existing__r.BR_Audit_Period_End_Date__c.DaysBetween(objRC.Case_No__r.BR_Audit_Period_Start_Date__c) > 2){
                        objRC.BR_Audit_Date_Gap__c = true;
                    }
                    if(objRC.Apply_EV_Audit__c && objRC.Case_No__r.EV_Audit_Period_Start_Date__c != null && objRC.Root_Certificate_Name_Existing__r.EV_Audit_Period_End_Date__c != null &&
                        objRC.Root_Certificate_Name_Existing__r.EV_Audit_Period_End_Date__c.DaysBetween(objRC.Case_No__r.EV_Audit_Period_Start_Date__c) > 2){
                        objRC.EV_SSL_Audit_Date_Gap__c = true;
                    }
                    if(objRC.Apply_EV_Code_Signing_Audit__c && objRC.Case_No__r.EV_Code_Signing_Audit_Period_Start_Date__c != null && objRC.Root_Certificate_Name_Existing__r.EV_Code_Signing_Audit_Period_End_Date__c != null &&
                        objRC.Root_Certificate_Name_Existing__r.EV_Code_Signing_Audit_Period_End_Date__c.DaysBetween(objRC.Case_No__r.EV_Code_Signing_Audit_Period_Start_Date__c ) > 2){
                        objRC.EV_Code_Signing_Audit_Date_Gap__c = true;
                    }
                    lstRootCasesToUpdate.add(objRC);
                }
            }
            if(lstRootCasesToUpdate.size() > 0){
                update lstRootCasesToUpdate;
            }
            
            map<Id,Case> mapCasesToUpdate = new map<Id,Case>();
            //check and update flag on case if there is any root case has audit date gap
            for(Case objCase: [select Id,CaseNumber, (select Id,Name,Root_Certificate_Name_Existing__c,EV_Code_Signing_Audit_Date_Gap__c, 
                    Case_No__c,Standard_Audit_Date_Gap__c,Code_Signing_Audit_Date_Gap__c,BR_Audit_Date_Gap__c,EV_SSL_Audit_Date_Gap__c,Audit_Gap__c from Root_Cases__r)
                    from Case Where Id in: setOfCaseIds]){
                //default set all audit gaps false
                objCase.Standard_Audit_Gap_For_All_Root_Cases__c = false;
                objCase.Code_Signing_Audit_Gap_For_All_Root_Case__c = false;
                objCase.BR_Audit_Gap_For_All_Root_Cases__c = false;
                objCase.EV_SSL_Audit_Gap_For_All_Root_Cases__c = false;
                objCase.EVCodeSigning_AuditGap_For_All_RootCases__c = false;
                //check all related root cases, if any of audit gap is true then it should set on case.
                for(Root_Case__c objRC: objCase.Root_Cases__r) {
                    if(objRC.Audit_Gap__c){ 
                        if(objRC.Standard_Audit_Date_Gap__c){
                            objCase.Standard_Audit_Gap_For_All_Root_Cases__c = true;
                        }
                        if(objRC.Code_Signing_Audit_Date_Gap__c){
                            objCase.Code_Signing_Audit_Gap_For_All_Root_Case__c = true;
                        }
                        if(objRC.BR_Audit_Date_Gap__c){
                            objCase.BR_Audit_Gap_For_All_Root_Cases__c = true;
                        }
                        if(objRC.EV_SSL_Audit_Date_Gap__c){
                            objCase.EV_SSL_Audit_Gap_For_All_Root_Cases__c = true;
                        }
                        if(objRC.EV_Code_Signing_Audit_Date_Gap__c){
                            objCase.EVCodeSigning_AuditGap_For_All_RootCases__c = true;
                        }
                    }
                }
                mapCasesToUpdate.put(objCase.Id, objCase);
            }
            if(mapCasesToUpdate.size() > 0){
                isCaseRecursive = true;
                update mapCasesToUpdate.values();
                isCaseRecursive = false;
            }
        }
    } 
    
  /*
        THIS LOGIC HAS BEEN MOVE TO JixiServciceController
        Popupate Audit Deviation from ALV Results.
    */
    
    /* public static void populateAuditDeviationForCAAuditUpdateCases(List<Case> lstCasesUpdated, map<Id,Case> mapOfOldCases){
        // process cases with record type = 'CA Audit Update Request'
        String caseAuditUpdateRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('CA Audit Update Request').getRecordTypeId();
        
        for(Case objCase: lstCasesUpdated){
            if(objCase.RecordTypeId == caseAuditUpdateRecordTypeId){
                //standard audits
                if(objCase.Standard_Audit_Verified__c != 'Data Verified') {
                    if(objCase.Standard_Audit_Auto_Review_Results__c != null && objCase.Standard_Audit_Auto_Review_Results__c != mapofOldCases.get(objCase.Id).Standard_Audit_Auto_Review_Results__c) {
                        if (objCase.Standard_Audit_Auto_Review_Results__c.contains('Cleaned=Fail')){
                        objCase.Standard_Deviation__c = true;
                    }  else {
                        objCase.Standard_Deviation__c = false;
                    } 
                  }
                }
                //code signing audits
                if(objCase.Code_Signing_Audit_Verified__c != 'Data Verified') {
                    if(objCase.Code_Signing_Audit_ALV_Results__c != null && objCase.Code_Signing_Audit_ALV_Results__c != mapofOldCases.get(objCase.Id).Code_Signing_Audit_ALV_Results__c) {
                        if (objCase.Code_Signing_Audit_ALV_Results__c.contains('Cleaned=Fail')){
                        objCase.Code_Signing_Deviation__c = true;
                    } else {
                        objCase.Code_Signing_Deviation__c = false;
                    }
                  }
                }
                //br audits
                if(objCase.BR_Audit_Statement_Link_Verified__c != 'Data Verified') {
                    if(objCase.BR_Audit_Auto_Review_Results__c != null && objCase.BR_Audit_Auto_Review_Results__c != mapofOldCases.get(objCase.Id).BR_Audit_Auto_Review_Results__c) {
                       if (objCase.BR_Audit_Auto_Review_Results__c.contains('Cleaned=Fail')){
                        objCase.BR_Deviation__c = true;
                    } else {
                        objCase.BR_Deviation__c = false;
                    }
                  }
                }
                //ev ssl audits
                if(objCase.EV_Audit_Statement_Link_Verified__c != 'Data Verified') {
                    if(objCase.EV_SSL_Audit_Auto_Review_Results__c != null && objCase.EV_SSL_Audit_Auto_Review_Results__c != mapofOldCases.get(objCase.Id).EV_SSL_Audit_Auto_Review_Results__c) {
                      if (objCase.EV_SSL_Audit_Auto_Review_Results__c.contains('Cleaned=Fail')){
                        objCase.EV_SSL_Deviation__c = true;
                    }  else {
                        objCase.EV_SSL_Deviation__c = false;
                    }
                  }
                }
                //ev code signing audits
                if(objCase.EV_Code_Signing_Verified__c != 'Data Verified') {
                    if(objCase.EV_Code_Signing_Audit_AutoReviewResults__c != null && objCase.EV_Code_Signing_Audit_AutoReviewResults__c != mapofOldCases.get(objCase.Id).EV_Code_Signing_Audit_AutoReviewResults__c) {
                      if (objCase.EV_Code_Signing_Audit_AutoReviewResults__c.contains('Cleaned=Fail')){
                        objCase.EV_Code_Signing_Deviation__c = true;
                    } else {
                        objCase.EV_Code_Signing_Deviation__c = false;
                    } 
                  }
                }
            }
        }
    } */
    
    /*
        Method is used to Enforce Validation if fields are verified dont allow to change
    */
    public static void EnforceValidationForInclusionCases(List<Case> caseSoLst, Map<Id, Case> oldcaseSoLst){
        //process cases with record type = 'CA Root Inclusion Request'
        String caseInclusionRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('CA Root Inclusion Request').getRecordTypeId();
 
        // loop over all the cases which were updated
        for(Case caseSo : caseSoLst) {
            //process record type 'CA Root Inclusion Request' only 
            if(caseSO.RecordTypeId == caseInclusionRecordTypeId){      
             
                //Set oldcaseSo to trigger.old value        
                Case oldcaseSO = oldcaseSOLst.get(caseSo.Id); 
                
                //CA Owner Information 
                if(caseSO.CA_Owner_Information_Verified__c == oldcaseSO.CA_Owner_Information_Verified__c 
                    && caseSO.CA_Owner_Information_Verified__c == 'Data Verified' && 
                    (caseSO.Company_Website__c != oldcaseSO.Company_Website__c ||
                    caseSO.CA_Email_Alias_1__c != oldcaseSO.CA_Email_Alias_1__c ||
                    caseSO.Organizational_Type__c != oldcaseSO.Organizational_Type__c ||
                    caseSO.Geographic_Focus__c != oldcaseSO.Geographic_Focus__c ||
                    caseSO.Primary_Market_Customer_Base__c != oldcaseSO.Primary_Market_Customer_Base__c ||
                    caseSO.Recognized_CAA_Domains__c != oldcaseSO.Recognized_CAA_Domains__c ||
                    caseSO.Problem_Reporting_Mechanism__c != oldcaseSO.Problem_Reporting_Mechanism__c)) {
                    caseSO.addError('Data has been verified. You cannot modify CA Owner Information fields');
                }
                
                //check if address fields are verified
                if(caseSO.Address_Verified__c == oldcaseSO.Address_Verified__c
                    && caseSO.Address_Verified__c == 'Data Verified' && 
                    (caseSO.Street__c != oldcaseSO.Street__c ||
                    caseSO.City__c != oldcaseSO.City__c ||
                    caseSO.State__c != oldcaseSO.State__c ||
                    caseSO.Zip_Postal_Code__c != oldcaseSO.Zip_Postal_Code__c ||
                    caseSO.Country__c != oldcaseSO.Country__c)) {
                    caseSO.addError('Data has been verified. You cannot modify CA Address fields');
                }
                
                //do not allow user to modify auditor field
                if (caseSO.Auditor_Verified__c == oldcaseSO.Auditor_Verified__c && 
                    caseSO.Auditor_Verified__c == 'Data Verified' &&
                    (caseSo.Auditor_New__c != oldcaseSO.Auditor_New__c ||
                    caseSo.Auditor_Location_New__c != oldcaseSO.Auditor_Location_New__c)){
                    caseSO.addError('Data has been verified. You cannot modify Auditor fields'); 
                }
                
                //check Standard audit verified field and Audit Authenticity Confirmed is false
                if (caseSO.Standard_Audit_Verified__c != oldcaseSO.Standard_Audit_Verified__c && 
                    caseSO.Standard_Audit_Verified__c == 'Data Verified' && !caseSo.Standard_Audit_Authenticity_Confirmed__c){
                    caseSO.addError('Standard Audit Authenticity Confirmed should be checked before Data Verified.'); 
                }
                
                //do not allow user to modify standard audit block 
                if (caseSO.Standard_Audit_Verified__c == oldcaseSO.Standard_Audit_Verified__c && 
                    caseSO.Standard_Audit_Verified__c == 'Data Verified' && 
                    (caseSo.Standard_Audit_Statement_Link__c != oldcaseSO.Standard_Audit_Statement_Link__c ||  
                    caseSo.Standard_Audit_Type__c != oldcaseSO.Standard_Audit_Type__c || 
                    caseSo.Standard_Audit_Statement_Date__c != oldcaseSO.Standard_Audit_Statement_Date__c || 
                    caseSo.Standard_Audit_Period_Start_Date__c != oldcaseSO.Standard_Audit_Period_Start_Date__c ||
                    caseSo.Standard_Audit_Period_End_Date__c != oldcaseSO.Standard_Audit_Period_End_Date__c ||             
                    caseSo.Standard_Audit_Authenticity_Confirmed__c != oldcaseSo.Standard_Audit_Authenticity_Confirmed__c ||
                    caseSo.Standard_Audit_ALV_Comments__c != oldcaseSO.Standard_Audit_ALV_Comments__c ||
                    caseSo.Standard_Deviation__c != oldcaseSo.Standard_Deviation__c ||
                    caseSo.Standard_Deviation_Comments__c != oldcaseSO.Standard_Deviation_Comments__c)) {
                    caseSO.addError('Data has been verified. You cannot modify Standard Audit fields');                      
                }
                
                //check Code signing audit verified field and Audit Authenticity Confirmed is false
                if (caseSO.Code_Signing_Audit_Verified__c != oldcaseSO.Code_Signing_Audit_Verified__c && 
                    caseSO.Code_Signing_Audit_Verified__c == 'Data Verified' && !caseSo.Code_Signing_Audit_Authenticity_Confirm__c){
                    caseSO.addError('Code Signing Audit Authenticity Confirmed should be checked before Data Verified.'); 
                }
                
                // do not allow user to modify code signing audit block 
                if (caseSO.Code_Signing_Audit_Verified__c == oldcaseSO.Code_Signing_Audit_Verified__c &&
                    caseSO.Code_Signing_Audit_Verified__c == 'Data Verified' && 
                    (caseSo.Code_Signing_Audit_Statement_Link__c != oldcaseSO.Code_Signing_Audit_Statement_Link__c ||  
                    caseSo.Code_Signing_Audit_Type__c != oldcaseSO.Code_Signing_Audit_Type__c || 
                    caseSo.Code_Signing_Audit_Statement_Date__c != oldcaseSO.Code_Signing_Audit_Statement_Date__c || 
                    caseSo.Code_Signing_Audit_Period_Start_Date__c != oldcaseSO.Code_Signing_Audit_Period_Start_Date__c ||
                    caseSo.Code_Signing_Audit_Period_End_Date__c != oldcaseSO.Code_Signing_Audit_Period_End_Date__c ||
                    caseSo.Code_Signing_Audit_Authenticity_Confirm__c != oldcaseSO.Code_Signing_Audit_Authenticity_Confirm__c ||
                    caseSo.Code_Signing_Audit_ALV_Comments__c != oldcaseSO.Code_Signing_Audit_ALV_Comments__c ||
                    caseSo.Code_Signing_Deviation__c != oldcaseSo.Code_Signing_Deviation__c ||
                    caseSo.Code_Signing_Deviation_Comments__c != oldcaseSO.Code_Signing_Deviation_Comments__c)) {
                    caseSO.addError('Data has been verified. You cannot modify Code Signing audit fields');                      
                }
                
                //check BR audit verified field and Audit Authenticity Confirmed is false
                if (caseSO.BR_Audit_Statement_Link_Verified__c != oldcaseSO.BR_Audit_Statement_Link_Verified__c  && 
                    caseSO.BR_Audit_Statement_Link_Verified__c == 'Data Verified' && !caseSo.BR_Audit_Authenticity_Confirmed__c){
                    caseSO.addError('BR Audit Authenticity Confirmed should be checked before Data Verified.'); 
                }
                
                // do not allow user to modify BR audit block 
                if (caseSO.BR_Audit_Statement_Link_Verified__c == oldcaseSO.BR_Audit_Statement_Link_Verified__c &&
                    caseSO.BR_Audit_Statement_Link_Verified__c == 'Data Verified' && 
                    (caseSo.BR_Audit_Statement_Link__c != oldcaseSO.BR_Audit_Statement_Link__c ||  
                    caseSo.BR_Audit_Type__c != oldcaseSO.BR_Audit_Type__c || 
                    caseSo.BR_Audit_Statement_Date__c != oldcaseSO.BR_Audit_Statement_Date__c || 
                    caseSo.BR_Audit_Period_Start_Date__c != oldcaseSO.BR_Audit_Period_Start_Date__c ||
                    caseSo.BR_Audit_Period_End_Date__c != oldcaseSO.BR_Audit_Period_End_Date__c ||
                    caseSo.BR_Audit_Authenticity_Confirmed__c != oldcaseSO.BR_Audit_Authenticity_Confirmed__c ||
                    caseSo.BR_Audit_ALV_Comments__c != oldcaseSO.BR_Audit_ALV_Comments__c ||
                    caseSo.BR_Deviation__c != oldcaseSo.BR_Deviation__c ||
                    caseSo.BR_Deviation_Comments__c != oldcaseSO.BR_Deviation_Comments__c)) {
                    caseSO.addError('Data has been verified. You cannot modify BR audit fields');                      
                }
                
                //check EV SSL audit verified field and Audit Authenticity Confirmed is false
                if (caseSO.EV_Audit_Statement_Link_Verified__c != oldcaseSO.EV_Audit_Statement_Link_Verified__c && 
                    caseSO.EV_Audit_Statement_Link_Verified__c == 'Data Verified' && !caseSo.EV_SSL_Audit_Authenticity_Confirmed__c){
                    caseSO.addError('EV SSL Audit Authenticity Confirmed should be checked before Data Verified.'); 
                }
                
                // do not allow user to modify EV SSL audit block 
                if (caseSO.EV_Audit_Statement_Link_Verified__c == oldcaseSO.EV_Audit_Statement_Link_Verified__c &&
                    caseSO.EV_Audit_Statement_Link_Verified__c == 'Data Verified' && 
                    (caseSo.EV_Audit_Statement_Link__c != oldcaseSO.EV_Audit_Statement_Link__c ||  
                    caseSo.EV_Audit_Type__c != oldcaseSO.EV_Audit_Type__c || 
                    caseSo.EV_Audit_Statement_Date__c != oldcaseSO.EV_Audit_Statement_Date__c || 
                    caseSo.EV_Audit_Period_Start_Date__c != oldcaseSO.EV_Audit_Period_Start_Date__c ||
                    caseSo.EV_Audit_Period_End_Date__c != oldcaseSO.EV_Audit_Period_End_Date__c ||
                    caseSo.EV_SSL_Audit_Authenticity_Confirmed__c != oldcaseSO.EV_SSL_Audit_Authenticity_Confirmed__c ||
                    caseSo.EV_SSL_Audit_ALV_Comments__c != oldcaseSO.EV_SSL_Audit_ALV_Comments__c ||
                    caseSo.EV_SSL_Deviation__c != oldcaseSo.EV_SSL_Deviation__c ||
                    caseSo.EV_SSL_Deviation_Comments__c != oldcaseSO.EV_SSL_Deviation_Comments__c)) {
                    caseSO.addError('Data has been verified. You cannot modify EV SSL audit fields');                      
                }
                
                //check EV Code Signing audit verified field and Audit Authenticity Confirmed is false
                if (caseSO.EV_Code_Signing_Verified__c != oldcaseSO.EV_Code_Signing_Verified__c && 
                    caseSO.EV_Code_Signing_Verified__c == 'Data Verified' && !caseSo.EV_Code_Signing_Audit_Auth_Confirmed__c){
                    caseSO.addError('EV Code Signing Authenticity Confirmed should be checked before Data Verified.'); 
                }
                
                // do not allow user to modify EV Code Signing audit block 
                if (caseSO.EV_Code_Signing_Verified__c == oldcaseSO.EV_Code_Signing_Verified__c &&
                    caseSO.EV_Code_Signing_Verified__c == 'Data Verified' && 
                    (caseSo.EV_Code_Signing_Audit_Statement_Link__c != oldcaseSO.EV_Code_Signing_Audit_Statement_Link__c ||  
                    caseSo.EV_Code_Signing_Audit_Type__c != oldcaseSO.EV_Code_Signing_Audit_Type__c || 
                    caseSo.EV_Code_Signing_Audit_Statement_Date__c != oldcaseSO.EV_Code_Signing_Audit_Statement_Date__c || 
                    caseSo.EV_Code_Signing_Audit_Period_Start_Date__c != oldcaseSO.EV_Code_Signing_Audit_Period_Start_Date__c ||
                    caseSo.EV_Code_Signing_Audit_Period_End_Date__c != oldcaseSO.EV_Code_Signing_Audit_Period_End_Date__c ||
                    caseSo.EV_Code_Signing_Audit_Auth_Confirmed__c != oldcaseSO.EV_Code_Signing_Audit_Auth_Confirmed__c ||
                    caseSo.EV_Code_Signing_Audit_ALV_Comments__c != oldcaseSO.EV_Code_Signing_Audit_ALV_Comments__c ||
                    caseSo.EV_Code_Signing_Deviation__c != oldcaseSo.EV_Code_Signing_Deviation__c ||
                    caseSo.EV_Code_Signing_Deviation_Comments__c != oldcaseSO.EV_Code_Signing_Deviation_Comments__c)) {
                    caseSO.addError('Data has been verified. You cannot modify EV Code Signing audit fields');                      
                }          
                
                // Commented by Poonam on 8/24/2020
                // do not allow user to modify CP/CPS audit block 
                /* if (caseSO.CP_CPS_Links_Verified__c == oldcaseSO.CP_CPS_Links_Verified__c &&
                    caseSO.CP_CPS_Links_Verified__c == 'Data Verified' && 
                    (caseSo.CA_Document_Repository__c != oldcaseSO.CA_Document_Repository__c ||  
                    caseSo.Certificate_Policy_Link__c != oldcaseSO.Certificate_Policy_Link__c || 
                    caseSo.Certification_Practice_Statement_Link__c != oldcaseSO.Certification_Practice_Statement_Link__c ||
                    caseSo.CP_CPS_Last_Updated_Date__c != oldcaseSO.CP_CPS_Last_Updated_Date__c ||
                    caseSo.Policy_Documentation__c.replace('\r','') != oldcaseSO.Policy_Documentation__c.replace('\r','') ||
                    caseSo.Other_Relevant_Documents__c.replace('\r','') != oldcaseSO.Other_Relevant_Documents__c.replace('\r',''))) {
                    caseSO.addError('Data has been verified. You cannot modify CP/CPS information');                      
                }*/
                
                //do not allow user to modify required practice fields
                if (caseSO.Required_Practices_Verified__c == oldcaseSO.Required_Practices_Verified__c &&
                    caseSO.Required_Practices_Verified__c == 'Data Verified' && 
                    (caseSo.Required_Practices__c != oldcaseSO.Required_Practices__c ||  
                    caseSo.CAs_Response_to_Required_Practices__c != oldcaseSO.CAs_Response_to_Required_Practices__c ||
                    caseSo.Link_To_Bugzilla_Bug__c != oldcaseSO.Link_To_Bugzilla_Bug__c ||
                    caseSo.BR_Self_Assessment__c != oldcaseSo.BR_Self_Assessment__c)) {
                    caseSO.addError('Data has been verified. You cannot modify Required Practice Information.');                      
                }
                system.debug('caseSo.Forbidden_Practices__c ::: '+caseSo.Forbidden_Practices__c.escapeUnicode());
                system.debug('oldcaseSO.Forbidden_Practices__c ::: '+oldcaseSO.Forbidden_Practices__c.escapeUnicode());
                system.debug('caseSo.CAs_Response_to_Forbidden_Practices__c ::: '+caseSo.CAs_Response_to_Forbidden_Practices__c.escapeUnicode());
                system.debug('oldcaseSO.CAs_Response_to_Forbidden_Practices__c ::: '+oldcaseSO.CAs_Response_to_Forbidden_Practices__c.escapeUnicode());
                if(caseSo.Forbidden_Practices__c.trim() != oldcaseSO.Forbidden_Practices__c.trim()){
                    system.debug('changed');
                }
                if(caseSo.CAs_Response_to_Forbidden_Practices__c.trim() != oldcaseSO.CAs_Response_to_Forbidden_Practices__c.trim()){
                    system.debug('changed');
                }
                //do not allow user to modify forbidden practice fields
                if (caseSO.Forbidden_Practices_Verified__c == oldcaseSO.Forbidden_Practices_Verified__c &&
                    caseSO.Forbidden_Practices_Verified__c == 'Data Verified' && 
                    (caseSo.Forbidden_Practices__c != oldcaseSO.Forbidden_Practices__c ||  
                    caseSo.CAs_Response_to_Forbidden_Practices__c != oldcaseSO.CAs_Response_to_Forbidden_Practices__c)) {
                    caseSO.addError('Data has been verified. You cannot modify Forbidden Practice Information.');                      
                }
            }
        }
    }
    
    /*
        Method is used to replace CPA File URLs
    */
    public static boolean isCaseRecursive = false;
    public static void ReplaceCPACanadaURLs(List<Case> lstCases){
        map<string, CPACanada_File__c> mapCPACanadaFiles = new map<string, CPACanada_File__c>();
        
        for(CPACanada_File__c objCC: [select Id,Name,Report_Id__c,Report_URL__c,Seal_URL__c from CPACanada_File__c]){
            mapCPACanadaFiles.put(objCC.Name, objCC);
        }
        List<Case> lstCasesToUpdate = new List<Case>();
        //Case comments
        List<CaseComment> lstCaseComments = new List<CaseComment>();
        for(Case objCase: lstCases){
            string strCaseComment = '';
            boolean isValidCPACanadaURLFound = false;
            Case objCaseToUpdate = new Case(Id = objCase.Id);
            if(objCase.Standard_Audit_Statement_Link__c != null && (objCase.Standard_Audit_Statement_Link__c.contains('www.cpacanada.ca/webtrustseal?sealid') || 
                objCase.Standard_Audit_Statement_Link__c.contains('cert.webtrust.org/ViewSeal?id'))) {
                string strStandardAudit = getCPACanadaURL(mapCPACanadaFiles, objCase.Standard_Audit_Statement_Link__c);
                if(string.isnotblank(strStandardAudit)){
                    isValidCPACanadaURLFound = true;
                    strCaseComment += 'Standard Audit Statement "'+objCase.Standard_Audit_Statement_Link__c+'" is a seal URL and it has been mapped by the system to the report URL "'+strStandardAudit+'"\n';
                    objCaseToUpdate.Standard_Audit_Statement_Link__c = strStandardAudit;
                    //populate seal id 
                    objCaseToUpdate.Standard_Audit_Seal_ID__c = getSealId(objCase.Standard_Audit_Statement_Link__c);
                }
            }
            if(objCase.Code_Signing_Audit_Statement_Link__c != null && (objCase.Code_Signing_Audit_Statement_Link__c.contains('www.cpacanada.ca/webtrustseal?sealid') ||
                objCase.Code_Signing_Audit_Statement_Link__c.contains('cert.webtrust.org/ViewSeal?id'))) {
                //objCase.Code_Signing_Audit_Statement_Link__c = getCPACanadaURL(mapCPACanadaFiles, objCase.Code_Signing_Audit_Statement_Link__c);
                string strCodeSigningAudit = getCPACanadaURL(mapCPACanadaFiles, objCase.Code_Signing_Audit_Statement_Link__c);
                if(string.isnotblank(strCodeSigningAudit)){
                    isValidCPACanadaURLFound = true;
                    strCaseComment += 'Code Signing Audit Statement "'+objCase.Code_Signing_Audit_Statement_Link__c +'" is a seal URL and it has been mapped by the system to the report URL "'+strCodeSigningAudit+'"\n';
                    objCaseToUpdate.Code_Signing_Audit_Statement_Link__c = strCodeSigningAudit;
                    //populate seal id 
                    objCaseToUpdate.Code_Signing_Audit_Seal_ID__c = getSealId(objCase.Code_Signing_Audit_Statement_Link__c);
                }
            }
            if(objCase.BR_Audit_Statement_Link__c != null && (objCase.BR_Audit_Statement_Link__c.contains('www.cpacanada.ca/webtrustseal?sealid') || 
                objCase.BR_Audit_Statement_Link__c.contains('cert.webtrust.org/ViewSeal?id'))) {
                //objCase.BR_Audit_Statement_Link__c = getCPACanadaURL(mapCPACanadaFiles, objCase.BR_Audit_Statement_Link__c);
                string strBRAudit = getCPACanadaURL(mapCPACanadaFiles, objCase.BR_Audit_Statement_Link__c);
                if(string.isnotblank(strBRAudit)){
                    isValidCPACanadaURLFound = true;
                    strCaseComment += 'BR Audit Statement "'+objCase.BR_Audit_Statement_Link__c +'" is a seal URL and it has been mapped by the system to the report URL "'+strBRAudit+'"\n';
                    objCaseToUpdate.BR_Audit_Statement_Link__c = strBRAudit;
                    //populate seal id 
                    objCaseToUpdate.BR_Audit_Seal_ID__c = getSealId(objCase.BR_Audit_Statement_Link__c);
                }
            }
            if(objCase.EV_Audit_Statement_Link__c != null && (objCase.EV_Audit_Statement_Link__c.contains('www.cpacanada.ca/webtrustseal?sealid') || 
                objCase.EV_Audit_Statement_Link__c.contains('cert.webtrust.org/ViewSeal?id'))) {
                //objCase.EV_Audit_Statement_Link__c = getCPACanadaURL(mapCPACanadaFiles, objCase.EV_Audit_Statement_Link__c);
                string strEVAudit = getCPACanadaURL(mapCPACanadaFiles, objCase.EV_Audit_Statement_Link__c);
                if(string.isnotblank(strEVAudit)){
                    isValidCPACanadaURLFound = true;
                    strCaseComment += 'EV SSL Audit Statement "'+objCase.EV_Audit_Statement_Link__c +'" is a seal URL and it has been mapped by the system to the report URL "'+strEVAudit+'"\n';
                    objCaseToUpdate.EV_Audit_Statement_Link__c = strEVAudit;
                    //populate seal id 
                    objCaseToUpdate.EV_SSL_Audit_Seal_ID__c = getSealId(objCase.EV_Audit_Statement_Link__c);
                }
            }
            if(objCase.EV_Code_Signing_Audit_Statement_Link__c != null && (objCase.EV_Code_Signing_Audit_Statement_Link__c.contains('www.cpacanada.ca/webtrustseal?sealid') || 
                objCase.EV_Code_Signing_Audit_Statement_Link__c.contains('cert.webtrust.org/ViewSeal?id'))) {
                //objCase.EV_Code_Signing_Audit_Statement_Link__c = getCPACanadaURL(mapCPACanadaFiles, objCase.EV_Code_Signing_Audit_Statement_Link__c);
                string strEVCodeSigningAudit = getCPACanadaURL(mapCPACanadaFiles, objCase.EV_Code_Signing_Audit_Statement_Link__c);
                if(string.isnotblank(strEVCodeSigningAudit)){
                    isValidCPACanadaURLFound = true;
                    strCaseComment += 'EV Code Signing Audit Statement "'+objCase.EV_Code_Signing_Audit_Statement_Link__c +'" is a seal URL and it has been mapped by the system to the report URL "'+strEVCodeSigningAudit+'"\n';
                    objCaseToUpdate.EV_Code_Signing_Audit_Statement_Link__c = strEVCodeSigningAudit;
                    //populate seal id 
                    objCaseToUpdate.EV_Code_Signing_Audit_Seal_ID__c = getSealId(objCase.EV_Code_Signing_Audit_Statement_Link__c);
                }
            }
            if(isValidCPACanadaURLFound && string.isnotblank(strCaseComment)){
                lstCasesToUpdate.add(objCaseToUpdate);
                CaseComment cc = new CaseComment(ParentId = objCase.Id,CommentBody = strCaseComment);
                lstCaseComments.add(cc);
            }
        }
        if(lstCasesToUpdate.size() > 0) {
            isCaseRecursive = true;
            update lstCasesToUpdate;
            if(lstCaseComments.size() > 0) {
                insert lstCaseComments;
            }
        }
    }
    
    public static string getCPACanadaURL(map<string, CPACanada_File__c> mapFileURLs, string strAuditURL){
        string strNewAuditURL = '';
        if((strAuditURL.contains('www.cpacanada.ca/webtrustseal?sealid') || strAuditURL.contains('cert.webtrust.org/ViewSeal?id'))
                 && strAuditURL.contains('=')){
            string strSealId = strAuditURL.split('=')[1];
            if(mapFileURLs.size() > 0 && mapFileURLs.containskey(strSealId)){
                strNewAuditURL = mapFileURLs.get(strSealId).Report_URL__c;
            }
        }
        return strNewAuditURL;
    } 
    
    public static string getSealId(string strAuditURL){
        string strSealId = '';
        if((strAuditURL.contains('www.cpacanada.ca/webtrustseal?sealid') || strAuditURL.contains('cert.webtrust.org/ViewSeal?id'))
                 && strAuditURL.contains('=')){
            strSealId = strAuditURL.split('=')[1];
        }
        return strSealId;
    }
    
    /*
        Method to update Case Status for Root Inclusion cases
    */
    public static void UpdateRootInclusionCaseStatus(List<Case> lstCasesToUpdated){
        set<string> setofRequestStatus = new set<string>();
        setofRequestStatus.add('Request Withdrawn by CA');
        setofRequestStatus.add('Denied');
        setofRequestStatus.add('Complete');
        setofRequestStatus.add('Closed - CA Unresponsive');
        //process cases with record type = 'CA Root Inclusion Request'
        String caseInclusionRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('CA Root Inclusion Request').getRecordTypeId();
        
        for(Case objCase: lstCasesToUpdated){
            if(objCase.RecordTypeId == caseInclusionRecordTypeId && objCase.Status == 'Open' && setofRequestStatus.contains(objCase.Request_Status__c)){
                objCase.Status = 'Closed';
            }
        }
    }
}
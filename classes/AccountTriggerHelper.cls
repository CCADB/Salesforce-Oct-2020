// ========================================================================================================
// AccountTriggerHelper: Trigger for the Account object which handles all the events and based 
// on the event delegates the task to the corresponding trigger handler method in the AccountTriggerHelper class.
// ========================================================================================================
// SetAccountStatusField : Update related Account Status whenever a new Account is created. 
// ========================================================================================================
// UpdateDerivedTrustBits & GetDerivedTrustBits: Update Derived Trust Bits on Intermediate Cert.
// Intermediate certs must be Not be Revoked or Expired (Valid To >= Today). 
// If Extended Key Usage is populated on inter cert, then map the values for EKU and populated Derived Trust Bits.
// If Extended Key Usage is blank or (not present) then check for Parent Root Cert's Trust Bits (as in 1 & 2) and get the union.
// 1. If the Parent Root cert is Included/Change Requested in Mozilla then 
//       get the Mozilla Trust bits and map them
//   else ignore Mozilla Trust Bits
// 2. If the Parent Root cert is Included/Change Requested in Microsoft then
//       get the Microsoft Trust bits and map them
//    else ignore Microsoft Trust Bits
// Also check for other Root certs which are included and has same Subject + SPKI and get the union of 
// Trust Bits from all Root Certs for Derived Trust Bits as described above (i.e. only get the trust bits 
// from Mozilla if the root is included/change requested for Mozilla, and likewise for Microsoft).
// 
// Added new logic for intermediate certs whose parent is also an intermediate cert. 
// (certs cannot have more Derived Trust bits than the union of their parents’ Derived Trust Bits)
// Keep the above Derived Trust Bits logic as-is (List 1).
// After List 1 is created with the current logic, if the parent is an intermediate cert, create List2:
// List2 consists of the parent cert’s Derived Trust bits, unioned with the Derived Trust bits of all 
// of the parent cert’s unexpired doppelganger certs (certs with same Subject+SPKI)
// Then remove anything from List1 that is not in List2.
//
// In other words ...
// If the parent cert is an intermediate cert, then take the union of the
// Derived Trust Bits of all non-expired intermediate certs with the parent
// cert's Subject+SPKI. The cert cannot have more Derived Trust Bits than
// what is in that resulting list.
//
// The batch job which runs ALV for inter certs also uses the same methods.
//
// ========================================================================================================    
// updateCAOwnerFields: This method set the ultimate parent to CA Owner and CA Owner Ids fields for all 
// account hiearachy levels. If the user makes account name change or parent id it is reflected in the hiearrchy.
// ========================================================================================================  
// UpdateRevocationVerification: Added method is reset Revocation Verification when necessary fields has changed
// ========================================================================================================  
// UpdateOwnerWhenAccountCreatedFromCA: Add method to transfer ownership to internal user when a root cert is 
// created by CA via Root Inclusion. Check custom setting CCADB_Setting.Default_Root_Cert_Owner__c for the default usesr.
// ========================================================================================================  
// 03/30/2018        Added New function checkAuditInfoWhenSameLink to check when Audit URLs are same.
// 04/19/2018        Added try-catch exception while updating accounts to show validation exception.
// 02/12/2019        Added new logic when audit same as parent is checked, clear all other audit fields for Intermediate Cert.
// 03/12/2019        Added new method to replace CPACanada URL for Intermediate Certs.
// 04/15/2019        Added Message if CPA Canada Report url has changed then show message.
// 05/12/2019        Added UpdateDerivedTrustBits method, to populate Dervied Trust bits on Intermediate Cert for ALV process.
// 06/17/2019        Updated checkAuditInfoWhenSameLink method to when audit are same and if Period end date is not same then populate error message, commented to check for other dates.
// 09/12/2019        Added UpdateALVDateProcessed to make ALV date processed blank whenever any audit has changed.
// 09/12/2019        Added UpdatePolicyIdentifierOnCAOwner to populate policy identifier on CA Owner.
// 10/26/2019        Updated UpdateALVDateProcessed method to update child accounts to make ALV fields blank when audit fields changed.
// 12/07/2019        Added UpdateRevocationVerification() method is reset Revocation Verification when necessary fields has changed
// 6/14/2020         Chnaged in UpdatePolicyIdentifierOnCAOwner method to instead of roll up from all certs, 
//                   do append whenver any child cert is updated policy identifiers.
//  09/25/2020       UpdateDerivedTrustBits - added logic to process inter certs which have parent as inter cert. 
//                   See the dcumentation above.
//  09/29/2020       Add UpdateOwnerWhenAccountCreatedFromCA method to transfer ownership to internal user
//                   when a root cert is created by a CA
// ========================================================================================================


public class AccountTriggerHelper {
    
 // define a static boolean variable to avoid recursive trigger update
 public static boolean isAccountTriggerRunning = false;
 
  // this method is invoked whenever a new account is created
  // the requirement is to set the status on account as 'Not Yet Included'
  public static void SetAccountStatusFieldonInsert(List<Account> accountSoLst) {
   
   // loop over all the account which were inserted
   for(Account accountSo : accountSoLst)
    {   
        if(accountSo.status__c==null || accountSo.status__c.length()==0)
        {
         accountSo.status__c = 'Not Yet Included';
        }
    }
  }
   
  public static void validateParentAccountForIntermediateCA(List<Account> accountSoLst) {
  
   // get the record type ID of the intermediate CA records
   Id intermediateCARecTypeId= Schema.SObjectType.Account.getRecordTypeInfosByName().get('Intermediate Certificate').getRecordTypeId();

   // get the record type ID of the root certificate records 
   Id rootCARecTypeId= Schema.SObjectType.Account.getRecordTypeInfosByName().get('Root Certificate').getRecordTypeId();

   // get the record type ID of the root certificate records 
   Id ownerCARecTypeId= Schema.SObjectType.Account.getRecordTypeInfosByName().get('CA Owner').getRecordTypeId();

   // get the ID of the current user
   Id currentUserId =    UserInfo.getUserId();
   
   //all CA Owners
   set<Id> setParentIds = new set<Id>();
   for(Account accountSo: accountSoLst){
       setParentIds.add(accountSo.ParentId);
   }
   map<Id,string> mapCAOwners = new map<Id,string>();
   for(Account accountSo: [select Id,RecordTypeId,Name from Account Where Id in: setParentIds and RecordTypeId =: ownerCARecTypeId]){
       mapCAOwners.put(accountSo.Id,accountSo.Name);
   }
   //System.debug('mapCAOwners :::: '+mapCAOwners);
   
   //checking intermediate certificate can't create under CA Owner
   for(Account accountSo: accountSoLst){
       if(accountSo.recordTypeId == intermediateCARecTypeId && mapCAOwners.containskey(accountSo.ParentId)) {
           accountSo.addError('You cannot select '+mapCAOwners.get(accountSo.ParentId)+' as Parent CA Owner. Please select a Root Cert or Intermediate Cert.');     
       }  
   }

   // query the user details and check if it is a portal user and get the Owner account ID for that user
   List<User> userSoLst = [select IsPortalEnabled,contact.account.id,contact.account.name from user where id = :currentUserId];
    
   // intermediate cert can have only root/inter certs as their parents. this 
   // validation is done only for portal users
   if(userSoLst!=null && userSoLst.size() > 0 && userSoLst[0].isPortalEnabled)
   //if(userSoLst!=null && userSoLst.size() > 0 )
   {
     
    // set which holds list of all valid parentIDs 
    Set<Id> rootCAIDSet = New Set<Id>();
    
    List<Account> rootAccountSOLst = New List<Account>();
    
    // special case to handle the exceptional scenario for Symantec Accounts
    // When a portal user for any of Symantec Accounts (symantec or sy-geotrust or sy-verisign) 
    // logs in and creates an intermediate CA, they should be able to select the root certificate of any of these owner accounts
     Map<Id,Account> symantecAccountMap;
     List<ID> currentParent      = new List<ID>{};
    // check if the portal user is associated with any of the symantec accounts
    if(userSoLst[0].contact!=null && userSoLst[0].contact.account.name.startsWith('Symantec'))
    {
      // get all the symantec owner accounts
       symantecAccountMap = New Map<Id,Account>([select id from account where name like 'Symantec%' and recordTypeId=:ownerCARecTypeId]);
     
      
      // get all the root CAs for these owner accounts
      rootAccountSOLst  = [select name from Account where parentId in :symantecAccountMap.keySet() and (recordTypeId=:rootCARecTypeId or recordTypeId = :intermediateCARecTypeId)  ];
      for(Id accountId : symantecAccountMap.keySet())
      {
        currentParent.add(accountId );      
      }
      
    }
    else
    {
      
      // non-symantec accounts 
      rootAccountSoLst = [select name from Account where parentId = :userSoLst[0].contact.accountid  and (recordTypeId=:rootCARecTypeId   or recordTypeId = :intermediateCARecTypeId )];
      currentParent.add(userSoLst[0].contact.accountid );
    }
    //system.debug('##currentParent='+currentParent);
    
/*
     //loop over each root certificate and put it in the map
     for(Account accountSo : rootAccountSoLst )
     {
       rootCAIdSet.add(accountSo.id);
     }

     for(Account accountSo: accountSoLst)
    {
      if(accountSo.recordTypeId == intermediateCARecTypeId)
      {
       accountSo.CA_Owner_For_Inter_Cert__c = userSoLst[0].contact.account.name;
      }
    }
          
    List<Account> interCaAccountsLst ;
    
    // get all the intermediate certs where the roots are their parents
    interCaAccountsLst = [select name from Account where parentId in :rootCAIdSet and recordTypeId = :intermediateCARecTypeId];

     for(Account accountSo : interCaAccountsLst )
     {
       rootCAIdSet.add(accountSo.id);
     }
    */ 
     Boolean endOfStructure = false;

      List<Account> al            = new List<Account>{};
           Set<Id> recordIdSet= new Set<Id>(currentParent);
     while ( !endOfStructure ){


       al = [ SELECT id FROM Account a WHERE a.ParentID IN : CurrentParent ORDER BY a.Name ];            

            if( al.size() == 0 ){
                endOfStructure = true;
            }
            else{
                currentParent.clear();
                for ( Integer i = 0 ; i < al.size(); i++ ){
                    //Change below
                    Account a = al[i];
                    currentParent.add( a.id );
                    recordIdSet.add(a.id);
                }
           }
         }  

     
    //system.debug('##recordIdset='+recordIdSet);
     // loop over the existing records which are inserted/updated
      for(Account accountSo: accountSoLst)
      {
          // for each intermediate CA record if the parentId does not exist in the map of valid rootCA then throw an error.
          //if(accountSo.recordTypeId == intermediateCARecTypeId && (!rootCAIdSet.contains(accountSo.ParentId) || (Trigger.isUpdate && accountSo.parentId == accountso.id)))
           if(accountSo.recordTypeId == intermediateCARecTypeId && (!recordIdSet.contains(accountSo.ParentId) || (Trigger.isUpdate && accountSo.parentId == accountso.id))){
               accountSo.addError('Invalid selection made for Parent CA Owner/Certificate. Please select a Root Cert or Intermediate Cert owned by ' + userSoLst[0].contact.account.name);
           }          
      }  
   }
  }
    
    /*
    * recrusive method, will set CA Owner Info to all its children records
    */
    public static List<Account> defaultCA_OwnerOnChildRecords(Set<Id> parentAccId, String ultimateParentAccName, String ultimateParentAccId, List<Account> thisList){
        //System.debug('in recursive call..');
        //List<Account> lstAccountToUpdate = new List<Account>();
        Set<Id> parentRecordIds = new Set<Id>();
        
        List<Account> childrenRecords = [SELECT Id, ParentId FROM Account WHERE ParentId IN :parentAccId];
        
        if(childrenRecords.isEmpty()){
            //System.debug('end of recursive call..');
            return thisList;
        }
        
        for(Account acc : childrenRecords){
            //system.debug('**child record: '+acc.Id);
            thisList.add(new Account(Id = acc.Id, CA_Owner__c = ultimateParentAccName, CA_Owner_ID__c = ultimateParentAccId));
            parentRecordIds.add(acc.Id);
        }
        
        return defaultCA_OwnerOnChildRecords(parentRecordIds, ultimateParentAccName, ultimateParentAccId, thisList);
    }
    
    /*
    * Recursive method, to get ULTIMATE parent account
    */
    public static Account getUltimateParent(Id parentAccountId, String ultimateParentRecordTypeId){
        
        List<Account> parentRecord = [SELECT Id, Name, RecordTypeId, ParentId FROM Account WHERE Id = :parentAccountId];
        
        if(parentRecord.size() > 0){
            
            if(ultimateParentRecordTypeId == parentRecord[0].RecordTypeId){
                
                return parentRecord[0];
            }
            
            return getUltimateParent(parentRecord[0].ParentId, ultimateParentRecordTypeId);
        }
        
        return null;//should never reach here..
    }
    
    /*
    * method called from Trigger - contains Logic to populate CA Owner Info of current + child records.
    */
    public static void updateCAOwnerFields(Account newAccount, Account oldAccount){
        
        String caOwnerRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('CA Owner').getRecordTypeId();
        String rootCertRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Root Certificate').getRecordTypeId();
        String intermediateCertRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Intermediate Certificate').getRecordTypeId();
        
        //Case-I if there is an update in CA Owner Account's Name, update all it's child records with correcr CA Owner Name
        if(Trigger.isBefore && Trigger.isUpdate && newAccount.Name != oldAccount.Name && newAccount.RecordTypeId == caOwnerRecordTypeId){
            
            //system.debug('CASE-I change in account name of CA Owner Account.');
            
            newAccount.CA_Owner__c = newAccount.Name;
            newAccount.CA_Owner_ID__c = newAccount.Id;
            
            List<Account> lstAccountToUpdate = defaultCA_OwnerOnChildRecords(new Set<Id>{newAccount.Id}, newAccount.Name, newAccount.Id, new List<Account>{});
            //system.debug('list to update: '+lstAccountToUpdate.size());
            if(lstAccountToUpdate.size() > 0){
                try {
                    update lstAccountToUpdate;
                } catch (Exception ex){
                    string ErrorMessage = 'Trigger Error - Cannot proceed to update record due to following errors: ' + ex.getMessage();
                    newAccount.addError(ErrorMessage);
                }
            }
            
            return;
        }
        
        //Case-II if there is a change in ParentId in any "intermediate" or "Root" accounts.
        if(Trigger.isBefore && Trigger.isUpdate && newAccount.RecordTypeId != caOwnerRecordTypeId && newAccount.ParentId != oldAccount.ParentId && newAccount.ParentId != null){
            
            //system.debug('CASE-II update in parent Id');
            //Two sub-cases
            //1. change in parent Id of Root Certificate ->  
                //I. get the Immediate Parent -update in the CA Owner and CA Owner Id field
                //II. get all the child records - update will correct CA Owner & CA Owner Id fields.
            
            if(rootCertRecordTypeId == newAccount.RecordTypeId){
                
                //get Immediate Parent - hope "Root Cert" can we child of "CA Owner" Only if not then ignore - check with Poonamji and confirm
                List<Account> parentAccount = [SELECT Id, Name FROM Account WHERE Id = :newAccount.ParentId AND RecordTypeId = :caOwnerRecordTypeId];
                //system.debug('CASE-II - subcase - I.  update in parent Id of root cert');
                if(parentAccount.size() > 0){
                    //I.
                    newAccount.CA_Owner__c = parentAccount[0].Name;
                    newAccount.CA_Owner_ID__c = parentAccount[0].Id;
                    //II.
                    List<Account> lstAccountToUpdate = defaultCA_OwnerOnChildRecords(new Set<Id>{newAccount.Id}, parentAccount[0].Name, parentAccount[0].Id, new List<Account>{});
                    //system.debug('list to update: '+lstAccountToUpdate.size());
                    if(lstAccountToUpdate.size() > 0){
                        try {
                            update lstAccountToUpdate;
                        } catch (Exception ex){
                            string ErrorMessage = 'Trigger Error - Cannot proceed to update record due to following errors: ' + ex.getMessage();
                            newAccount.addError(ErrorMessage);
                        }
                    }
                    
                    return;
                }
            }
            
            //2. change in the parent Id of Intermediate Certificate -> 
                //I. get the ULTIMATE Parent - update CA Owner and CA Owner Id field
                //II. get all the child records - update will correct CA Owner & CA Owner Id fields.
            
            if(intermediateCertRecordTypeId == newAccount.RecordTypeId){
                
                //I.
                Account ultimanteParent = getUltimateParent(newAccount.ParentId, caOwnerRecordTypeId);
                
                if(ultimanteParent != null){
                    newAccount.CA_Owner__c = ultimanteParent.Name;
                    newAccount.CA_Owner_ID__c = ultimanteParent.Id;
                    
                    //II.
                    List<Account> lstAccountToUpdate = defaultCA_OwnerOnChildRecords(new Set<Id>{newAccount.Id}, ultimanteParent.Name, ultimanteParent.Id, new List<Account>{});
                    if(lstAccountToUpdate.size() > 0){
                        try {
                            update lstAccountToUpdate;
                        }  catch (Exception ex){
                            string ErrorMessage = 'Trigger Error - Cannot proceed to update record due to following errors: ' + ex.getMessage();
                            newAccount.addError(ErrorMessage);
                        }
                    }
                    
                    return;
                }
            }
        }
        
        //Case-III if root record inserted then update its "CA Owner" and "CA Owner Id" field of the same account
        if(Trigger.isAfter && Trigger.isInsert && newAccount.RecordTypeId == caOwnerRecordTypeId){
            
            //system.debug('CASE-III new CA Owner ACcount inserted');
            Account selfUpdate = new Account(Id = newAccount.Id, CA_Owner__c = newAccount.Name, CA_Owner_ID__c = newAccount.Id);
            try {
                update selfUpdate;
            }  catch (Exception ex){
                string ErrorMessage = 'Trigger Error - Cannot proceed to update record due to following errors: ' + ex.getMessage();
                newAccount.addError(ErrorMessage);
            }
        }
        
        //Case-IV
        if(Trigger.isBefore && Trigger.isInsert && newAccount.RecordTypeId != caOwnerRecordTypeId && newAccount.ParentId != null){
            //system.debug('CASE-IV Insert new intermediate or root certificate');
            
            //I. If Root Certificate inserted - get Immediate Parent & update correct CA Owner and CA Owner Id
            if(rootCertRecordTypeId == newAccount.RecordTypeId){
                List<Account> parentAccount = [SELECT Id, Name FROM Account WHERE Id = :newAccount.ParentId AND RecordTypeId = :caOwnerRecordTypeId];
                
                if(parentAccount.size() > 0){
                    //I.
                    newAccount.CA_Owner__c = parentAccount[0].Name;
                    newAccount.CA_Owner_ID__c = parentAccount[0].Id;
                }
                
                return;
            }
            
            //II. If Intermediate Certificate inserted - get ULTIMATE parent and update
            if(intermediateCertRecordTypeId == newAccount.RecordTypeId){
                
                Account ultimanteParent = getUltimateParent(newAccount.ParentId, caOwnerRecordTypeId);
                
                if(ultimanteParent != null){
                    newAccount.CA_Owner__c = ultimanteParent.Name;
                    newAccount.CA_Owner_ID__c = ultimanteParent.Id;
                }
                
                return;
            }
        }
    }
    
    public static String checkDeleteValidation(Account deletedAccount){
        
        Integer hasChildRecords = [SELECT COUNT() FROM Account WHERE ParentId = :deletedAccount.Id];
        
        if(hasChildRecords > 0){
            //deletedAccount.addError('You can\'t delete this record, please delete child records first.');
            return 'You can\'t delete this record, please delete child records first.';
        }
        
        return null;
    }
    
    
    /*
        Function is created when Audit Same As Parent is checked for Intermediate Certs and audit urls are blank then clear all other audit info.
    */
    public static void ClearAuditFieldsWhenAuditSameAsParent(List<Account> lstAccounts){
        String intermediateCertRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Intermediate Certificate').getRecordTypeId();
        for(Account objAcc: lstAccounts){
            if(objAcc.RecordTypeId == intermediateCertRecordTypeId){
                //it should check if only audit same as parent is checked
                if(objAcc.Audits_Same_as_Parent__c) {
                    //checks for standard audit
                    if(objAcc.Standard_Audit__c == null || string.isblank(objAcc.Standard_Audit__c)) {
                        objAcc.Standard_Audit_Type__c = null;
                        objAcc.Standard_Audit_Statement_Date__c = null;
                        objAcc.Standard_Audit_Period_Start_Date__c = null;
                        objAcc.Standard_Audit_Period_End_Date__c = null;
                    }
                    //checks for code signing audit
                    if(objAcc.Code_Signing_Audit__c == null || string.isblank(objAcc.Code_Signing_Audit__c)) {
                        objAcc.Code_Signing_Audit_Type__c = null;
                        objAcc.Code_Signing_Audit_Statement_Date__c = null;
                        objAcc.Code_Signing_Audit_Period_Start_Date__c = null;
                        objAcc.Code_Signing_Audit_Period_End_Date__c = null;
                    }
                    //checks for BR audit
                    if(objAcc.BR_Audit__c == null || string.isblank(objAcc.BR_Audit__c)) {
                        objAcc.BR_Audit_Type__c = null;
                        objAcc.BR_Audit_Statement_Date__c = null;
                        objAcc.BR_Audit_Period_Start_Date__c = null;
                        objAcc.BR_Audit_Period_End_Date__c = null;
                    }
                    //checks for BR audit
                    if(objAcc.EV_Audit__c == null || string.isblank(objAcc.EV_Audit__c)) {
                        objAcc.EV_Audit_Type__c = null;
                        objAcc.EV_Audit_Statement_Date__c = null;
                        objAcc.EV_Audit_Period_Start_Date__c = null;
                        objAcc.EV_Audit_Period_End_Date__c = null;
                    }
                }
            }
        }
    }
    
    /*
        This function is used to check if Audit URLs are same then other audit information should be same.
    */
    public static void checkAuditInfoWhenSameLink(List<Account> lstAccounts){
        String rootCertRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Root Certificate').getRecordTypeId();
        String intermediateCertRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Intermediate Certificate').getRecordTypeId();
        
        for(Account objAcc: lstAccounts){
            
            if((objAcc.RecordTypeId == rootCertRecordTypeId || objAcc.RecordTypeId == intermediateCertRecordTypeId) && 
                objAcc.Standard_Audit__c != null){
                
                //compare standard audit with Code signing audit 
                if(objAcc.Code_Signing_Audit__c != null && objAcc.Standard_Audit__c == objAcc.Code_Signing_Audit__c) {
                    if(objAcc.Standard_Audit_Statement_Date__c != objAcc.Code_Signing_Audit_Statement_Date__c) {
                        objAcc.addError('Standard Audit & Code Signing Audit are same but Audit Statement Date does not match');
                        return;
                    }
                    /*if(objAcc.Standard_Audit_Period_Start_Date__c != objAcc.Code_Signing_Audit_Period_Start_Date__c) {
                        objAcc.addError('Standard Audit & Code Signing Audit are same but Audit Period Start Date does not match');
                        return;
                    }*/
                    if(objAcc.Standard_Audit_Period_End_Date__c != objAcc.Code_Signing_Audit_Period_End_Date__c) {
                        objAcc.addError('Standard Audit & Code Signing Audit are same but Audit Period End Date does not match');
                        return;
                    }
                }
                
                //compare standard audit with BR Audit
                if(objAcc.BR_Audit__c != null && objAcc.Standard_Audit__c == objAcc.BR_Audit__c) {
                    if(objAcc.Standard_Audit_Statement_Date__c != objAcc.BR_Audit_Statement_Date__c) {
                        objAcc.addError('Standard Audit & BR Audit are same but Audit Statement Date does not match');
                        return;
                    }
                    /*if(objAcc.Standard_Audit_Period_Start_Date__c != objAcc.BR_Audit_Period_Start_Date__c) {
                        objAcc.addError('Standard Audit & BR Audit are same but Audit Period Start Date does not match');
                        return;
                    }*/
                    if(objAcc.Standard_Audit_Period_End_Date__c != objAcc.BR_Audit_Period_End_Date__c) {
                        objAcc.addError('Standard Audit & BR Audit are same but Audit Period End Date does not match');
                        return;
                    }
                }
                //compare standard audit with EV SSL Audit
                if(objAcc.EV_Audit__c != null && objAcc.Standard_Audit__c == objAcc.EV_Audit__c) {
                    if(objAcc.Standard_Audit_Statement_Date__c != objAcc.EV_Audit_Statement_Date__c) {
                        objAcc.addError('Standard Audit & EV SSL Audit are same but Audit Statement Date does not match');
                        return;
                    }
                    /*if(objAcc.Standard_Audit_Period_Start_Date__c != objAcc.EV_Audit_Period_Start_Date__c) {
                        objAcc.addError('Standard Audit & EV SSL Audit are same but Audit Period Start Date does not match');
                        return;
                    }*/
                    if(objAcc.Standard_Audit_Period_End_Date__c != objAcc.EV_Audit_Period_End_Date__c) {
                        objAcc.addError('Standard Audit & EV SSL Audit are same but Audit Period End Date does not match');
                        return;
                    }
                }
                
                //compare standard audit with EV Code Signing Audit
                if(objAcc.EV_Code_Signing_Audit__c != null && objAcc.Standard_Audit__c == objAcc.EV_Code_Signing_Audit__c) {
                    if(objAcc.Standard_Audit_Statement_Date__c != objAcc.EV_Code_Signing_Audit_Statement_Date__c) {
                        objAcc.addError('Standard Audit & EV Code Signing Audit are same but Audit Statement Date does not match');
                        return;
                    }
                    /*if(objAcc.Standard_Audit_Period_Start_Date__c != objAcc.EV_Code_Signing_Audit_Period_Start_Date__c) {
                        objAcc.addError('Standard Audit & EV Code Signing Audit are same but Audit Period Start Date does not match');
                        return;
                    }*/
                    if(objAcc.Standard_Audit_Period_End_Date__c != objAcc.EV_Code_Signing_Audit_Period_End_Date__c) {
                        objAcc.addError('Standard Audit & EV Code Signing Audit are same but Audit Period End Date does not match');
                        return;
                    }
                }
                
                //compare code signing audit with BR audit
                if(objAcc.Code_Signing_Audit__c != null && objAcc.BR_Audit__c != null && objAcc.Code_Signing_Audit__c == objAcc.BR_Audit__c) {
                    if(objAcc.Code_Signing_Audit_Statement_Date__c != objAcc.BR_Audit_Statement_Date__c) {
                        objAcc.addError('Code Signing Audit & BR Audit are same but Audit Statement Date does not match');
                        return;
                    }
                    /*if(objAcc.Code_Signing_Audit_Period_Start_Date__c != objAcc.BR_Audit_Period_Start_Date__c) {
                        objAcc.addError('Code Signing Audit & BR Audit are same but Audit Period Start Date does not match');
                        return;
                    }*/
                    if(objAcc.Code_Signing_Audit_Period_End_Date__c != objAcc.BR_Audit_Period_End_Date__c) {
                        objAcc.addError('Code Signing Audit & BR Audit are same but Audit Period End Date does not match');
                        return;
                    }
                }
                
                //compare code signing audit with EV SSL audit
                if(objAcc.Code_Signing_Audit__c != null && objAcc.EV_Audit__c != null && objAcc.Code_Signing_Audit__c == objAcc.EV_Audit__c) {
                    if(objAcc.Code_Signing_Audit_Statement_Date__c != objAcc.EV_Audit_Statement_Date__c) {
                        objAcc.addError('Code Signing Audit & EV SSL Audit are same but Audit Statement Date does not match');
                        return;
                    }
                    /*if(objAcc.Code_Signing_Audit_Period_Start_Date__c != objAcc.EV_Audit_Period_Start_Date__c) {
                        objAcc.addError('Code Signing Audit & EV SSL Audit are same but Audit Period Start Date does not match');
                        return;
                    }*/
                    if(objAcc.Code_Signing_Audit_Period_End_Date__c != objAcc.EV_Audit_Period_End_Date__c) {
                        objAcc.addError('Code Signing Audit & EV SSL Audit are same but Audit Period End Date does not match');
                        return;
                    }
                }
                
                //compare code signing audit with EV Code Signing audit
                if(objAcc.Code_Signing_Audit__c != null && objAcc.EV_Code_Signing_Audit__c != null && objAcc.Code_Signing_Audit__c == objAcc.EV_Code_Signing_Audit__c) {
                    if(objAcc.Code_Signing_Audit_Statement_Date__c != objAcc.EV_Code_Signing_Audit_Statement_Date__c) {
                        objAcc.addError('Code Signing Audit & EV Code Signing Audit are same but Audit Statement Date does not match');
                        return;
                    }
                    /*if(objAcc.Code_Signing_Audit_Period_Start_Date__c != objAcc.EV_Code_Signing_Audit_Period_Start_Date__c) {
                        objAcc.addError('Code Signing Audit & EV Code Signing Audit are same but Audit Period Start Date does not match');
                        return;
                    }*/
                    if(objAcc.Code_Signing_Audit_Period_End_Date__c != objAcc.EV_Code_Signing_Audit_Period_End_Date__c) {
                        objAcc.addError('Code Signing Audit & EV Code Signing Audit are same but Audit Period End Date does not match');
                        return;
                    }
                }
                
                //compare BR audit with EV SSL Audit
                if(objAcc.BR_Audit__c != null && objAcc.EV_Audit__c != null && objAcc.BR_Audit__c == objAcc.EV_Audit__c) {
                    if(objAcc.BR_Audit_Statement_Date__c != objAcc.EV_Audit_Statement_Date__c) {
                        objAcc.addError('BR Audit & EV SSL Audit are same but Audit Statement Date does not match');
                        return;
                    }
                    /*if(objAcc.BR_Audit_Period_Start_Date__c != objAcc.EV_Audit_Period_Start_Date__c) {
                        objAcc.addError('BR Audit & EV SSL Audit are same but Audit Period Start Date does not match');
                        return;
                    }*/
                    if(objAcc.BR_Audit_Period_End_Date__c != objAcc.EV_Audit_Period_End_Date__c) {
                        objAcc.addError('BR Audit & EV SSL Audit are same but Audit Period End Date does not match');
                        return;
                    }
                }
                
                //compare BR audit with EV Code Signing Audit
                if(objAcc.BR_Audit__c != null && objAcc.EV_Code_Signing_Audit__c != null && objAcc.BR_Audit__c == objAcc.EV_Code_Signing_Audit__c) {
                    if(objAcc.BR_Audit_Statement_Date__c != objAcc.EV_Code_Signing_Audit_Statement_Date__c) {
                        objAcc.addError('BR Audit & EV Code Signing Audit are same but Audit Statement Date does not match');
                        return;
                    }
                    /*if(objAcc.BR_Audit_Period_Start_Date__c != objAcc.EV_Code_Signing_Audit_Period_Start_Date__c) {
                        objAcc.addError('BR Audit & EV Code Signing Audit are same but Audit Period Start Date does not match');
                        return;
                    }*/
                    if(objAcc.BR_Audit_Period_End_Date__c != objAcc.EV_Code_Signing_Audit_Period_End_Date__c) {
                        objAcc.addError('BR Audit & EV Code Signing Audit are same but Audit Period End Date does not match');
                        return;
                    }
                }
                
                //compare EV SSL audit with EV Code Signing Audit
                if(objAcc.EV_Audit__c != null && objAcc.EV_Code_Signing_Audit__c != null && objAcc.EV_Audit__c == objAcc.EV_Code_Signing_Audit__c) {
                    if(objAcc.EV_Audit_Statement_Date__c != objAcc.EV_Code_Signing_Audit_Statement_Date__c) {
                        objAcc.addError('EV SSL Audit & EV Code Signing Audit are same but Audit Statement Date does not match');
                        return;
                    }
                    /*if(objAcc.EV_Audit_Period_Start_Date__c != objAcc.EV_Code_Signing_Audit_Period_Start_Date__c) {
                        objAcc.addError('EV SSL Audit & EV Code Signing Audit are same but Audit Period Start Date does not match');
                        return;
                    }*/
                    if(objAcc.EV_Audit_Period_End_Date__c != objAcc.EV_Code_Signing_Audit_Period_End_Date__c) {
                        objAcc.addError('EV SSL Audit & EV Code Signing Audit are same but Audit Period End Date does not match');
                        return;
                    }
                }
            }
        }
    }
    
    /*
        Description: Replace CPA Canada URLs
    */
    
    public static void ReplaceCPACanadaURLs(List<Account> lstAccounts){
        String intermediateCertRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Intermediate Certificate').getRecordTypeId();
        map<string, CPACanada_File__c> mapCPACanadaFiles = new map<string, CPACanada_File__c>();
        
        for(CPACanada_File__c objCC: [select Id,Name,Report_Id__c,Report_URL__c,Seal_URL__c from CPACanada_File__c]){
            mapCPACanadaFiles.put(objCC.Name, objCC);
        }
        
        for(Account objAcc: lstAccounts){
            if(objAcc.RecordTypeId == intermediateCertRecordTypeId) {
                if(string.isnotblank(objAcc.Standard_Audit__c) && (objAcc.Standard_Audit__c.contains('www.cpacanada.ca/webtrustseal?sealid') || 
                            objAcc.Standard_Audit__c.contains('cert.webtrust.org/ViewSeal?id'))){
                    if (getCPACanadaURL(mapCPACanadaFiles, objAcc.Standard_Audit__c) != '')
                        objAcc.Standard_Audit__c = getCPACanadaURL(mapCPACanadaFiles, objAcc.Standard_Audit__c);
                        objAcc.Standard_Audit_Seal_ID__c = getSealId(objAcc.Standard_Audit__c);
                }
                if(string.isnotblank(objAcc.Code_Signing_Audit__c) && (objAcc.Code_Signing_Audit__c.contains('www.cpacanada.ca/webtrustseal?sealid') ||
                            objAcc.Code_Signing_Audit__c.contains('cert.webtrust.org/ViewSeal?id'))){
                    if (getCPACanadaURL(mapCPACanadaFiles, objAcc.Code_Signing_Audit__c) != '')
                        objAcc.Code_Signing_Audit__c = getCPACanadaURL(mapCPACanadaFiles, objAcc.Code_Signing_Audit__c);
                        objAcc.Code_Signing_Audit_Seal_ID__c = getSealId(objAcc.Code_Signing_Audit__c);
                }
                if(string.isnotblank(objAcc.BR_Audit__c) && (objAcc.BR_Audit__c.contains('www.cpacanada.ca/webtrustseal?sealid') || 
                            objAcc.BR_Audit__c.contains('cert.webtrust.org/ViewSeal?id'))){
                    if (getCPACanadaURL(mapCPACanadaFiles, objAcc.BR_Audit__c) != '') {
                        objAcc.BR_Audit__c = getCPACanadaURL(mapCPACanadaFiles, objAcc.BR_Audit__c);
                        objAcc.BR_Audit_Seal_ID__c = getSealId(objAcc.BR_Audit__c);
                    }
                }
                if(string.isnotblank(objAcc.EV_Audit__c) && (objAcc.EV_Audit__c.contains('www.cpacanada.ca/webtrustseal?sealid') ||
                            objAcc.EV_Audit__c.contains('cert.webtrust.org/ViewSeal?id'))){
                    if (getCPACanadaURL(mapCPACanadaFiles, objAcc.EV_Audit__c) != '') {
                       objAcc.EV_Audit__c = getCPACanadaURL(mapCPACanadaFiles, objAcc.EV_Audit__c);
                       objAcc.EV_SSL_Audit_Seal_ID__c = getSealId(objAcc.EV_Audit__c);
                   }
                }
            }
        }
    }
    //common function to get CPA canada file url
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
    //get seal Id from url
    public static string getSealId(string strAuditURL){
        string strSealId = '';
        if((strAuditURL.contains('www.cpacanada.ca/webtrustseal?sealid') || strAuditURL.contains('cert.webtrust.org/ViewSeal?id')) 
                && strAuditURL.contains('=')){
            strSealId = strAuditURL.split('=')[1];
        }
        return strSealId;
    }
    
// UpdateDerivedTrustBits & GetDerivedTrustBits: Update Derived Trust Bits on Intermediate Cert.
// Intermediate certs must be Not be Revoked or Expired (Valid To >= Today). 
// If Extended Key Usage is populated on inter cert, then map the values for EKU and populated Derived Trust Bits.
// If Extended Key Usage is blank or (not present) then check for Parent Root Cert's Trust Bits (as in 1 & 2) and get the union.
// 1. If the Parent Root cert is Included/Change Requested in Mozilla then 
//       get the Mozilla Trust bits and map them
//   else ignore Mozilla Trust Bits
// 2. If the Parent Root cert is Included/Change Requested in Microsoft then
//       get the Microsoft Trust bits and map them
//    else ignore Microsoft Trust Bits
// Also check for other Root certs which are included and has same Subject + SPKI and get the union of 
// Trust Bits from all Root Certs for Derived Trust Bits as described above (i.e. only get the trust bits 
// from Mozilla if the root is included/change requested for Mozilla, and likewise for Microsoft).
// 
// Added new logic for intermediate certs whose parent is also an intermediate cert. 
// (certs cannot have more Derived Trust bits than the union of their parents’ Derived Trust Bits)
// Keep the above Derived Trust Bits logic as-is (List 1).
// After List 1 is created with the current logic, if the parent is an intermediate cert, create List2:
// List2 consists of the parent cert’s Derived Trust bits, unioned with the Derived Trust bits of all 
// of the parent cert’s unexpired doppelganger certs (certs with same Subject+SPKI)
// Then remove anything from List1 that is not in List2.
//
// In other words ...
// If the parent cert is an intermediate cert, then take the union of the
// Derived Trust Bits of all non-expired intermediate certs with the parent
// cert's Subject+SPKI. The cert cannot have more Derived Trust Bits than
// what is in that resulting list.
//
// The batch job which runs ALV for inter certs also uses the same methods.

    public static void UpdateDerivedTrustBits(List<Account> lstAccounts, map<Id,Account> mapOldAccounts, boolean isInsert, boolean isUpdate){

        // added new logic for intermediate certs which has parent intermediates
        Set<Id> setIntermediatesCertsParent = new Set<Id>();
        Map<Id,Account> mapIntermediatesCertsParent  = new Map<Id,Account>();

        map<Id,Account> mapAllAccounts = new map<Id, Account>();
        
        set<Id> setOfAccIds = new set<Id>();
        set<string> setOfSubjectSPKI = new set<string>();
        String intermediateCertRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Intermediate Certificate').getRecordTypeId();
        for(Account objAcc: lstAccounts) {
            if(objAcc.RecordTypeId == intermediateCertRecordTypeId && (isInsert || (isUpdate && objAcc.Extended_Key_Usage__c != mapOldAccounts.get(objAcc.Id).Extended_Key_Usage__c))){
                //check intermediate certs is not revoked and expired.
                if(objAcc.Revocation_Status__c == 'Not Revoked' && objAcc.Valid_To_GMT__c != null && objAcc.Valid_To_GMT__c >= System.Today()){
                    setOfAccIds.add(objAcc.Id);
                    if(objAcc.Subject_SPKI_SHA256__c != null) {
                        setOfSubjectSPKI.add(objAcc.Subject_SPKI_SHA256__c);
                    }
                    //added new logic for intermediate certs which has parent intermediates
                    setIntermediatesCertsParent.add(objAcc.ParentId);
                }
            }
        }
        
        //check if cert is intermediate and its parent is also intermediate
        if(setIntermediatesCertsParent.size() > 0) {
            mapIntermediatesCertsParent = new Map<Id,Account>([select Id,Derived_Trust_Bits__c,
                        Extended_Key_Usage__c, Subject_SPKI_SHA256__c from Account 
                        WHERE RecordTypeId =: intermediateCertRecordTypeId 
                        and Id in: setIntermediatesCertsParent]);
            for(Account objAcc : mapIntermediatesCertsParent.values()){
                if(objAcc.Subject_SPKI_SHA256__c != null) {
                    setOfSubjectSPKI.add(objAcc.Subject_SPKI_SHA256__c);
                }
            }
        }
        map<string, List<Account>> mapAllRootsWithSameSPKI = new map<string, List<Account>>();
        if(setOfSubjectSPKI.size() > 0){
            Date todaydt = system.today();
            //querying on root certificate to get same Subject + SPKI.
            List<Account> lstRootAccs = new List<Account>([Select Id, ParentId, RecordType.Name, Derived_Trust_Bits__c,
                            Trust_Bits__c,Microsoft_Trust_Bits__c,Status__c,Microsoft_Status__c,Subject_SPKI_SHA256__c 
                            from Account Where //RecordType.Name = 'Root Certificate' and 
                            (Status__c in ('Included','Change Requested') or Microsoft_Status__c in ('Included','Change Requested')
                            OR Valid_To_GMT__c >=: todaydt)
                            and Subject_SPKI_SHA256__c =: setOfSubjectSPKI]);
            for(Account objRoot: lstRootAccs){
                if(mapAllRootsWithSameSPKI.containskey(objRoot.Subject_SPKI_SHA256__c)){
                    mapAllRootsWithSameSPKI.get(objRoot.Subject_SPKI_SHA256__c).add(objRoot);
                } else {
                    mapAllRootsWithSameSPKI.put(objRoot.Subject_SPKI_SHA256__c, new List<Account>{objRoot});
                }
            }
        }
        //get all intermediate and root certs only if there is any account has changed extended key usagae.
        if(setOfAccIds.size() > 0){
            mapAllAccounts = new map<Id, Account>([select Id, ParentId, RecordType.Name, Derived_Trust_Bits__c,
                        Trust_Bits__c, Microsoft_Trust_Bits__c, Status__c, Microsoft_Status__c, Subject_SPKI_SHA256__c
                        from Account Where RecordType.Name != 'CA Owner']);
        }
        for(Account objAcc: lstAccounts) {
            if(setOfAccIds.contains(objAcc.Id)){
                objAcc.Derived_Trust_Bits__c = '';
                string strDerivedTrustBits = getDerivedTrustBits(objAcc, mapAllAccounts, mapAllRootsWithSameSPKI);
                if(strDerivedTrustBits != null && string.isnotblank(strDerivedTrustBits)){
                    objAcc.Derived_Trust_Bits__c = strDerivedTrustBits;
                }
            }
        }
        
        //added new logic for intermediate certs which has parent intermediates
        /*mapIntermediatesCertsParent = new Map<Id,Account>([select Id,Derived_Trust_Bits__c,Extended_Key_Usage__c,Subject_SPKI_SHA256__c from Account 
        where RecordTypeId =: intermediateCertRecordTypeId 
        and Id in:setIntermediatesCertsParent]);

        // Set<string> setOfIntermediateCertSubjectSPKI = new Set<string>();
        // for(Account objAcc : mapIntermediatesCertsParent.values()){
        //     if(objAcc.Subject_SPKI_SHA256__c != null) {
        //         setOfIntermediateCertSubjectSPKI.add(objAcc.Subject_SPKI_SHA256__c);
        //     }
        // }

        // map<string, List<Account>> mapAllIntermediateCertWithSameSPKI = new map<string, List<Account>>();
        // if(setOfIntermediateCertSubjectSPKI.size() > 0){
        //     //querying on root certificate to get same Subject + SPKI.
        //     List<Account> lstRootAccs = new List<Account>([Select Id, ParentId, RecordType.Name,
        //                     Trust_Bits__c,Microsoft_Trust_Bits__c,Status__c,Microsoft_Status__c,Subject_SPKI_SHA256__c 
        //                     from Account Where RecordType.Name = 'Root Certificate' and 
        //                     (Status__c in ('Included','Change Requested') or Microsoft_Status__c in ('Included','Change Requested'))
        //                     and Subject_SPKI_SHA256__c =: setOfIntermediateCertSubjectSPKI]);
        //     for(Account objRoot: lstRootAccs){
        //         if(mapAllIntermediateCertWithSameSPKI.containskey(objRoot.Subject_SPKI_SHA256__c)){
        //             mapAllIntermediateCertWithSameSPKI.get(objRoot.Subject_SPKI_SHA256__c).add(objRoot);
        //         } else {
        //             mapAllIntermediateCertWithSameSPKI.put(objRoot.Subject_SPKI_SHA256__c, new List<Account>{objRoot});
        //         }
        //     }
        // }

        for(Account objAcc: lstAccounts) { // existing all records List 1
            //mapIMCPVsIMC
            if(mapIntermediatesCertsParent.containsKey(objAcc.ParentId)){ // Check if parent is intermediate cert
                Account objParentAccount = mapIntermediatesCertsParent.get(objAcc.ParentId); // List 2
                
                set<string> setParent = new set<string>();
                setParent.addAll(objParentAccount.Derived_Trust_Bits__c.split(';')); // parent intermediate cert

                Set<string> setmatchparent = new Set<string>();
                objAcc.Derived_Trust_Bits1__c = objParentAccount.Derived_Trust_Bits__c;
                for(String str : objAcc.Derived_Trust_Bits__c.split(';')){ // here have doubt for comparision for list1 and list2
                    if(setParent.contains(str)){
                        setmatchparent.add(str);
                    }
                }

                List<string> tempList2 = new List<string>();
                tempList2.addall(setmatchparent);
                String strDerivedTrustBits = string.join(tempList2,';');
                if(strDerivedTrustBits != null && string.isnotblank(strDerivedTrustBits)){
                    objAcc.Derived_Trust_Bits2__c = strDerivedTrustBits;
                }
            }
        }*/

    }
    
    public static string getDerivedTrustBits(Account objAcc, map<Id,Account> mapAllAccounts, 
                map<string, List<Account>> mapAllRootsWithSameSPKI){
        string strDerivedTrustBits = '';
        try {
            map<string, string> mapofExtendedKeyUsage = new map<string, string>();
            mapofExtendedKeyUsage.put('Websites', 'Server Authentication');
            mapofExtendedKeyUsage.put('Email','Secure Email');
            mapofExtendedKeyUsage.put('ExtKeyUsageClientAuth','Client Authentication');
            mapofExtendedKeyUsage.put('ExtKeyUsageCodeSigning','Code Signing');
            mapofExtendedKeyUsage.put('1.3.6.1.4.1.311.3.10.3.12','Document Signing');
            mapofExtendedKeyUsage.put('1.3.6.1.4.1.311.10.3.4','Encrypting File System');
            mapofExtendedKeyUsage.put('ExtKeyUsageIPSECEndSystem','IP Security End System');
            mapofExtendedKeyUsage.put('1.3.6.1.5.5.8.2.2','IP Security IKE Intermediate');
            mapofExtendedKeyUsage.put('ExtKeyUsageIPSECTunnel','IP Security Tunnel Termination');
            mapofExtendedKeyUsage.put('ExtKeyUsageIPSECUser','IP Security User');
            mapofExtendedKeyUsage.put('ExtKeyUsageOCSPSigning','OCSP Signing');
            mapofExtendedKeyUsage.put('ExtKeyUsageEmailProtection','Secure Email');
            mapofExtendedKeyUsage.put('ExtKeyUsageServerAuth','Server Authentication');
            mapofExtendedKeyUsage.put('ExtKeyUsageTimeStamping','Time Stamping');
            mapofExtendedKeyUsage.put('1.3.6.1.5.5.7.3.1','Server Authentication');
            mapofExtendedKeyUsage.put('1.3.6.1.5.5.7.3.2','Client Authentication');
            mapofExtendedKeyUsage.put('1.3.6.1.5.5.7.3.4','Secure Email');
            mapofExtendedKeyUsage.put('1.3.6.1.5.5.7.3.3','Code Signing');
            mapofExtendedKeyUsage.put('1.3.6.1.5.5.7.3.8','Time Stamping');
            mapofExtendedKeyUsage.put('1.3.6.1.4.1.311.10.3.4','Encrypting File System');
            mapofExtendedKeyUsage.put('1.3.6.1.4.1.311.10.3.12','Document Signing');
            mapofExtendedKeyUsage.put('1.3.6.1.5.5.8.2.2','IP security IKE intermediate');
            mapofExtendedKeyUsage.put('1.3.6.1.5.5.7.3.6','IP security tunnel termination');
            mapofExtendedKeyUsage.put('1.3.6.1.5.5.7.3.7','IP security user');
            mapofExtendedKeyUsage.put('1.3.6.1.5.5.7.3.5','IP Security end system');
            mapofExtendedKeyUsage.put('1.3.6.1.5.5.7.3.9','OCSP Signing');
            
            //get parent root account for intermediate cert
            Account objRootAcc = GetParentRootAccount(objAcc, mapAllAccounts);
            set<string> setKeyUsageValues = new set<string>();
            set<string> setOfMozillaStatus = new set<string>{'Included','Change Requested'};
            set<string> setOfMicrosoftStatus = new set<string>{'Included','Change Requested'};
            //When EKU is populated
            if(objAcc.Extended_Key_Usage__c != null && string.isnotblank(objAcc.Extended_Key_Usage__c) && objAcc.Extended_Key_Usage__c != '(not present)'){
                //split with comma and get mapped values.
                string[] arrExtenedKeyUsage = objAcc.Extended_Key_Usage__c.split(',');
                for(string strEKU: arrExtenedKeyUsage){
                    if(mapofExtendedKeyUsage.containskey(strEKU)){
                        setKeyUsageValues.add(mapofExtendedKeyUsage.get(strEKU));
                    }
                }
            }
            //if it is included in Mozilla or Microsoft. 
            else if(objRootAcc != null && (setOfMozillaStatus.contains(objRootAcc.Status__c) || setOfMicrosoftStatus.contains(objRootAcc.Microsoft_Status__c))){
                //when EKU is blank or (not present)
                //check for microsoft status included check for trust bits.
                if(setOfMicrosoftStatus.contains(objRootAcc.Microsoft_Status__c) && objRootAcc.Microsoft_Trust_Bits__c != null){
                    string MicrosoftTrustbits = objRootAcc.Microsoft_Trust_Bits__c;
                    setKeyUsageValues.addall(MicrosoftTrustbits.split(';')); 
                } 
                
                //check for Mozilla trust bits.
                if(setOfMozillaStatus.contains(objRootAcc.Status__c) && objRootAcc.Trust_Bits__c != null) {
                    string MozillaTrustBits = objRootAcc.Trust_Bits__c;
                    for(string strTB: MozillaTrustBits.split(';')){
                        if(mapofExtendedKeyUsage.containskey(strTB)){
                            setKeyUsageValues.add(mapofExtendedKeyUsage.get(strTB));
                        }
                    }
                }
            }
            
            //check if any root is existing with same Subject+ SPKI
            if(objAcc.Subject_SPKI_SHA256__c != null && mapAllRootsWithSameSPKI.containskey(objAcc.Subject_SPKI_SHA256__c)){
                for(Account objRootSPKI: mapAllRootsWithSameSPKI.get(objAcc.Subject_SPKI_SHA256__c)){
                    if(setOfMicrosoftStatus.contains(objRootSPKI.Microsoft_Status__c) && objRootSPKI.Microsoft_Trust_Bits__c != null){
                        string MicrosoftTrustbits = objRootSPKI.Microsoft_Trust_Bits__c;
                        setKeyUsageValues.addall(MicrosoftTrustbits.split(';'));
                    } 
                    if(setOfMozillaStatus.contains(objRootSPKI.Status__c) && objRootSPKI.Trust_Bits__c != null) {
                        string MozillaTrustBits = objRootSPKI.Trust_Bits__c;
                        for(string strTB: MozillaTrustBits.split(';')){
                            if(mapofExtendedKeyUsage.containskey(strTB)){
                                setKeyUsageValues.add(mapofExtendedKeyUsage.get(strTB));
                            }
                        }
                    }
                }
            }
            
            //Logic when Parent is Intermediate certs
            set<string> setKeyUsageValuesParentIC = new set<string>();  
            Account objParentAccount = GetParentAccount(objAcc, mapAllAccounts);
            if(objParentAccount != null && objParentAccount.RecordType.Name == 'Intermediate Certificate'){
                if(objParentAccount.Subject_SPKI_SHA256__c != null && mapAllRootsWithSameSPKI.containskey(objParentAccount.Subject_SPKI_SHA256__c)){
                    for(Account objAccSPKI: mapAllRootsWithSameSPKI.get(objParentAccount.Subject_SPKI_SHA256__c)){
                        if(objAccSPKI.Derived_Trust_Bits__c != null){
                            for(String str : objAccSPKI.Derived_Trust_Bits__c.split(';')){
                                if(string.isnotblank(str)){
                                    setKeyUsageValuesParentIC.add(str.trim());
                                }
                            }
                        }
                    }
                }
            }
            //remove anything from Main List 1 that is not Parent IC List 2.
            if(setKeyUsageValuesParentIC.size() > 0) {
                for(string strKUV: setKeyUsageValues){
                    if(!setKeyUsageValuesParentIC.contains(strKUV)){
                        setKeyUsageValues.remove(strKUV);
                    }
                }
            }
            //populate dervied trust bits.
            if(setKeyUsageValues.size() > 0){
                List<string> lstEKUValues = new List<string>();
                lstEKUValues.addall(setKeyUsageValues);
                strDerivedTrustBits = string.join(lstEKUValues,';');
            }
            return strDerivedTrustBits;
        } catch (Exception ex){
            return null;
        }
    }
    
    //get parent root account for intermediate cert
    public static Account GetParentRootAccount(Account interCert, map<Id,Account> mapAllAccounts){
        boolean isFound = false;
        Id accParentId = interCert.ParentId;
        while(!isFound){
            Account objParentAccount = mapAllAccounts.containskey(accParentId) ? mapAllAccounts.get(accParentId) : null;
            if(objParentAccount != null && objParentAccount.RecordType.Name == 'Root Certificate') {
                isFound = true;
                return objParentAccount;
            } else if(objParentAccount == null) {
                isFound = true;
            }
            if(objParentAccount != null) accParentId = objParentAccount.ParentId;
        }
        return null;
    }
    
    //get parent account
    public static Account GetParentAccount(Account interCert, map<Id,Account> mapAllAccounts){
        boolean isFound = false;
        Id accParentId = interCert.ParentId;
        while(!isFound){
            Account objParentAccount = mapAllAccounts.containskey(accParentId) ? mapAllAccounts.get(accParentId) : null;
            if(objParentAccount != null) {
                isFound = true;
                return objParentAccount;
            } else if(objParentAccount == null) {
                isFound = true;
            }
            if(objParentAccount != null) accParentId = objParentAccount.ParentId;
        }
        return null;
    }
    
    /*
        Method is used to make Date ALV Processed blank whenver any audit field has changed and
        There is batch program nightly basis which Process ALV for that cert.
    */
    public static void UpdateALVDateProcessed(List<Account> lstAccUpdated, map<Id, Account> mapOfOldAccounts){
        set<Id> setofAccountIds = new set<Id>();
        for(Account objAcc: lstAccUpdated){
            if(objAcc.Auditor_New__c != mapOfOldAccounts.get(objAcc.Id).Auditor_New__c ||
                objAcc.Auditor_Location_New__c != mapOfOldAccounts.get(objAcc.Id).Auditor_Location_New__c ||
                objAcc.Standard_Audit__c != mapOfOldAccounts.get(objAcc.Id).Standard_Audit__c ||
                objAcc.Standard_Audit_Type__c != mapOfOldAccounts.get(objAcc.Id).Standard_Audit_Type__c ||
                objAcc.Standard_Audit_Statement_Date__c != mapOfOldAccounts.get(objAcc.Id).Standard_Audit_Statement_Date__c ||
                objAcc.Standard_Audit_Period_Start_Date__c != mapOfOldAccounts.get(objAcc.Id).Standard_Audit_Period_Start_Date__c ||
                objAcc.Standard_Audit_Period_End_Date__c != mapOfOldAccounts.get(objAcc.Id).Standard_Audit_Period_End_Date__c ||
                objAcc.Code_Signing_Audit__c != mapOfOldAccounts.get(objAcc.Id).Code_Signing_Audit__c ||
                objAcc.Code_Signing_Audit_Type__c != mapOfOldAccounts.get(objAcc.Id).Code_Signing_Audit_Type__c ||
                objAcc.Code_Signing_Audit_Statement_Date__c != mapOfOldAccounts.get(objAcc.Id).Code_Signing_Audit_Statement_Date__c ||
                objAcc.Code_Signing_Audit_Period_Start_Date__c != mapOfOldAccounts.get(objAcc.Id).Code_Signing_Audit_Period_Start_Date__c ||
                objAcc.Code_Signing_Audit_Period_End_Date__c != mapOfOldAccounts.get(objAcc.Id).Code_Signing_Audit_Period_End_Date__c ||
                objAcc.BR_Audit__c != mapOfOldAccounts.get(objAcc.Id).BR_Audit__c ||
                objAcc.BR_Audit_Type__c != mapOfOldAccounts.get(objAcc.Id).BR_Audit_Type__c ||
                objAcc.BR_Audit_Statement_Date__c != mapOfOldAccounts.get(objAcc.Id).BR_Audit_Statement_Date__c ||
                objAcc.BR_Audit_Period_Start_Date__c != mapOfOldAccounts.get(objAcc.Id).BR_Audit_Period_Start_Date__c ||
                objAcc.BR_Audit_Period_End_Date__c != mapOfOldAccounts.get(objAcc.Id).BR_Audit_Period_End_Date__c ||
                objAcc.EV_Audit__c != mapOfOldAccounts.get(objAcc.Id).EV_Audit__c ||
                objAcc.EV_Audit_Type__c != mapOfOldAccounts.get(objAcc.Id).EV_Audit_Type__c ||
                objAcc.EV_Audit_Statement_Date__c != mapOfOldAccounts.get(objAcc.Id).EV_Audit_Statement_Date__c ||
                objAcc.EV_Audit_Period_Start_Date__c != mapOfOldAccounts.get(objAcc.Id).EV_Audit_Period_Start_Date__c ||
                objAcc.EV_Audit_Period_End_Date__c != mapOfOldAccounts.get(objAcc.Id).EV_Audit_Period_End_Date__c){
                    setofAccountIds.add(objAcc.Id);
                    objAcc.Date_ALV_Processed__c = null;
                    objAcc.Standard_Audit_ALV_Status__c = null;
                    objAcc.Standard_Audit_ALV_Results__c = null;
                    objAcc.Standard_Audit_ALV_Comments__c = null;
                    objAcc.Code_Signing_Audit_ALV_Status__c = null;
                    objAcc.Code_Signing_Audit_ALV_Results__c = null;
                    objAcc.Code_Signing_Audit_ALV_Comments__c = null;
                    objAcc.BR_Audit_ALV_Status__c = null;
                    objAcc.BR_Audit_ALV_Results__c = null;
                    objAcc.BR_Audit_ALV_Comments__c = null;
                    objAcc.EV_SSL_Audit_ALV_Status__c = null;
                    objAcc.EV_SSL_Audit_ALV_Results__c = null;
                    objAcc.EV_SSL_Audit_ALV_Comments__c = null;
                    objAcc.ALV_Status__c = null;
                    objAcc.ALV_Results__c= null;
                    objAcc.Standard_Audit_ALV_Found_Cert__c = null;
                    objAcc.BR_Audit_ALV_Found_Cert__c = null;
            }
        }
        
        if(setofAccountIds.size() > 0){
            map<Id, List<Account>> mapInterCertAccounts = new map<Id, List<Account>>();
            
            for(Account objAcc: [select Id, ParentId, Name from Account Where RecordType.Name = 'Intermediate Certificate' 
                                    AND Audits_Same_as_Parent__c = true]){
                if(mapInterCertAccounts.containskey(objAcc.ParentId)){
                    mapInterCertAccounts.get(objAcc.ParentId).add(objAcc);
                } else {
                    mapInterCertAccounts.put(objAcc.ParentId, new List<Account>{objAcc});
                }
            }
            List<Account> lstAccToUpdate = new List<Account>();
            for(Id aid: setofAccountIds){
                set<Id> setofAccountIdsToUpdate = new set<Id>();
                set<Id> setOfIdsToCheckChild = new set<Id>();
                setOfIdsToCheckChild.add(aid);
                while(setOfIdsToCheckChild.size() > 0){
                    for(Id accId: setOfIdsToCheckChild){
                        if(mapInterCertAccounts.containskey(accId)){
                            for(Account acc: mapInterCertAccounts.get(accId)){
                                Account objAcc = new Account(Id = acc.Id);
                                objAcc.Date_ALV_Processed__c = null;
                                objAcc.Standard_Audit_ALV_Status__c = null;
                                objAcc.Standard_Audit_ALV_Results__c = null;
                                objAcc.Standard_Audit_ALV_Comments__c = null;
                                objAcc.Code_Signing_Audit_ALV_Status__c = null;
                                objAcc.Code_Signing_Audit_ALV_Results__c = null;
                                objAcc.Code_Signing_Audit_ALV_Comments__c = null;
                                objAcc.BR_Audit_ALV_Status__c = null;
                                objAcc.BR_Audit_ALV_Results__c = null;
                                objAcc.BR_Audit_ALV_Comments__c = null;
                                objAcc.EV_SSL_Audit_ALV_Status__c = null;
                                objAcc.EV_SSL_Audit_ALV_Results__c = null;
                                objAcc.EV_SSL_Audit_ALV_Comments__c = null;
                                objAcc.ALV_Status__c = null;
                                objAcc.ALV_Results__c= null;
                                objAcc.Standard_Audit_ALV_Found_Cert__c = null;
                                objAcc.BR_Audit_ALV_Found_Cert__c = null;
                                if(!setofAccountIdsToUpdate.contains(objAcc.Id)){
                                    lstAccToUpdate.add(objAcc);
                                }
                                setofAccountIdsToUpdate.add(objAcc.Id);
                                if(mapInterCertAccounts.containskey(acc.Id)){
                                    setOfIdsToCheckChild.add(acc.Id);
                                }
                            }
                        }
                        setOfIdsToCheckChild.remove(accId);
                    }
                }
            }
            //update accounts
            if(lstAccToUpdate.size() > 0){
                AccountTriggerHelper.isRecursiveUpdate = true;
                update lstAccToUpdate;
                AccountTriggerHelper.isRecursiveUpdate = false;
            }
        }
    }
    
    /*
        Method is used to populate Policy Identifier on CA Owner
    */
    public static boolean isRecursiveUpdate = false;
    public static void UpdatePolicyIdentifierOnCAOwner(List<Account> lstAccUpdated, map<Id, Account> mapOfOldAccounts){
        map<Id, set<string>> mapCAOwnerwisePolicyIdentifiers = new map<Id, set<string>>();
        for(Account objAcc: lstAccUpdated){
            if(objAcc.CA_Owner_ID__c != null && objAcc.Policy_Identifiers__c != mapOfOldAccounts.get(objAcc.Id).Policy_Identifiers__c){
                List<string> lstPolicyIdentifiers = new List<string>();
                if(objAcc.Policy_Identifiers__c.contains(';')){
                    lstPolicyIdentifiers = objAcc.Policy_Identifiers__c.split(';');
                } else if(objAcc.Policy_Identifiers__c.contains(',')){
                    lstPolicyIdentifiers = objAcc.Policy_Identifiers__c.split(',');
                } else {
                    lstPolicyIdentifiers.add(objAcc.Policy_Identifiers__c);
                }
                for(string str: lstPolicyIdentifiers){
                    if(string.isnotblank(str)){
                        if(mapCAOwnerwisePolicyIdentifiers.containskey(objAcc.CA_Owner_ID__c)){
                            mapCAOwnerwisePolicyIdentifiers.get(objAcc.CA_Owner_ID__c).add(str.trim());
                        } else {
                            mapCAOwnerwisePolicyIdentifiers.put(objAcc.CA_Owner_ID__c, new set<string>{str.trim()});
                        }
                    }
                }
            }
        }
        //check map CA owner 
        if(mapCAOwnerwisePolicyIdentifiers.size() > 0){
            List<Account> lstCAOwners = new List<Account>([Select Id, Name, Policy_Identifiers__c FROM
                            Account Where Id in: mapCAOwnerwisePolicyIdentifiers.keyset()]);
            for(Account acc: lstCAOwners){
                List<string> lstCAOwnerPolicyIdentifiers = new List<string>();
                if(acc.Policy_Identifiers__c != null) {
                    if(acc.Policy_Identifiers__c.contains(';')){
                        lstCAOwnerPolicyIdentifiers = acc.Policy_Identifiers__c.split(';');
                    } else if(acc.Policy_Identifiers__c.contains(',')){
                        lstCAOwnerPolicyIdentifiers = acc.Policy_Identifiers__c.split(',');
                    } else {
                        lstCAOwnerPolicyIdentifiers.add(acc.Policy_Identifiers__c);
                    }
                }
                for(string str: lstCAOwnerPolicyIdentifiers){
                    if(string.isnotblank(str)){
                        if(mapCAOwnerwisePolicyIdentifiers.containskey(acc.id)){
                            mapCAOwnerwisePolicyIdentifiers.get(acc.id).add(str.trim());
                        } else {
                            mapCAOwnerwisePolicyIdentifiers.put(acc.id, new set<string>{str.trim()});
                        }
                    }
                }
            }
            //update account
            if(mapCAOwnerwisePolicyIdentifiers.size() > 0){
                List<Account> lstAccToUpdate = new List<Account>();
                for(Id accid: mapCAOwnerwisePolicyIdentifiers.keyset()){
                    Account acc = new Account(Id = accId);
                    List<string> lst = new List<string>();
                    lst.addall(mapCAOwnerwisePolicyIdentifiers.get(accId));
                    lst.sort();
                    acc.Policy_Identifiers__c = string.join(lst, '; ');
                    lstAccToUpdate.add(acc);
                }
                if(lstAccToUpdate.size() > 0){
                    isRecursiveUpdate = true;
                    update lstAccToUpdate;
                    isRecursiveUpdate = false;
                }
            }
        }
        /* Roll up from all certificates to CA Owner - Commented on 15th June 2020
        set<Id> setofCAOwnerId = new set<Id>();
        for(Account objAcc: lstAccUpdated){
            if(objAcc.CA_Owner_ID__c != null && objAcc.Policy_Identifiers__c != mapOfOldAccounts.get(objAcc.Id).Policy_Identifiers__c){
                setofCAOwnerId.add(objAcc.CA_Owner_ID__c);
            }
        }
        if(setofCAOwnerId.size() > 0) {
            map<Id, set<string>> mapCAOwnerwisePolicyIdentifiers = new map<Id, set<string>>();
            List<Account> lstAllRootInterCerts = new List<Account>([select Id,Name,CA_Owner_ID__c,Policy_Identifiers__c 
                            FROM Account WHERE CA_Owner_ID__c =: setofCAOwnerId //Valid_To_GMT__c > TODAY AND Revocation_Status__c = 'Not Revoked' and 
                            AND RecordType.Name in ('Intermediate Certificate', 'Root Certificate')]);
            for(Account objAcc: lstAllRootInterCerts){
                if(objAcc.Policy_Identifiers__c != null){
                    List<string> lstPolicyIdentifiers = new List<string>();
                    if(objAcc.Policy_Identifiers__c.contains(';')){
                        lstPolicyIdentifiers = objAcc.Policy_Identifiers__c.split(';');
                    } else if(objAcc.Policy_Identifiers__c.contains(',')){
                        lstPolicyIdentifiers = objAcc.Policy_Identifiers__c.split(',');
                    } else {
                        lstPolicyIdentifiers.add(objAcc.Policy_Identifiers__c);
                    }
                    for(string str: lstPolicyIdentifiers){
                        if(string.isnotblank(str)){
                            if(mapCAOwnerwisePolicyIdentifiers.containskey(objAcc.CA_Owner_ID__c)){
                                mapCAOwnerwisePolicyIdentifiers.get(objAcc.CA_Owner_ID__c).add(str.trim());
                            } else {
                                mapCAOwnerwisePolicyIdentifiers.put(objAcc.CA_Owner_ID__c, new set<string>{str.trim()});
                            }
                        }
                    }
                }
            }
            if(mapCAOwnerwisePolicyIdentifiers.size() > 0){
                
                List<Account> lstAccToUpdate = new List<Account>();
                for(Id accid: mapCAOwnerwisePolicyIdentifiers.keyset()){
                    Account acc = new Account(Id = accId);
                    List<string> lst = new List<string>();
                    lst.addall(mapCAOwnerwisePolicyIdentifiers.get(accId));
                    lst.sort();
                    acc.Policy_Identifiers__c = string.join(lst, '; ');
                    lstAccToUpdate.add(acc);
                }
                if(lstAccToUpdate.size() > 0){
                    isRecursiveUpdate = true;
                    update lstAccToUpdate;
                    isRecursiveUpdate = false;
                }
            }
        }*/
    }
    
    /*
        Method is Update owner when accounts are created by CA
    */
    public static void UpdateOwnerWhenAccountCreatedFromCA(List<Account> lstAccountsInserted){
        set<Id> setOfCAUserIds = new set<Id>();
        for(User u: [Select Id, IsActive from User Where IsActive = TRUE and ContactId != null]){
            setOfCAUserIds.add(u.Id);
        }
        if(setOfCAUserIds.size() > 0){
            String rootCertRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Root Certificate').getRecordTypeId();
            for(Account acc: lstAccountsInserted){
                if(acc.RecordTypeId == rootCertRecordTypeId && setOfCAUserIds.contains(acc.OwnerId)){
                    CCADB_Settings__c settings = CCADB_Settings__c.getOrgDefaults();
                    if(settings.Default_Root_Cert_Owner__c != null){
                        acc.OwnerId = settings.Default_Root_Cert_Owner__c;
                    }
                }
            }
        }
    }
    
    
    /*
        Method is reset Revocation Verification when necessary fields has changed
    */
    public static void UpdateRevocationVerification(List<Account> lstAccountUpdated, map<Id, Account> mapOldAccounts){
        for(Account objAcc: lstAccountUpdated){
            if(objAcc.Revocation_Status__c != mapOldAccounts.get(objAcc.Id).Revocation_Status__c ||
                objAcc.Date_of_Revocation__c != mapOldAccounts.get(objAcc.Id).Date_of_Revocation__c ||
                objAcc.RFC_5280_Revocation_Reason_Code__c != mapOldAccounts.get(objAcc.Id).RFC_5280_Revocation_Reason_Code__c ||
                objAcc.Alternate_CRL__c != mapOldAccounts.get(objAcc.Id).Alternate_CRL__c){
                objAcc.Revocation_Verification__c = '';
            }
        }
    }
    
}
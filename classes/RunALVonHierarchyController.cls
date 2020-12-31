/*******************************************************************************************************
 Name: RunALVonHierarchyController

 Dependencies: RunALVonHierarchyController controller class, RunALVonHierarchy vf page, 
 RunALVonHierarchyControllerTest

 Description: This class is created to clear the ALV fields and run ALV on hierarchy from
 a button on root cert for all intermediate certs which have Audits Same As Parent set 
 to True. "Run ALV on Hierarchy" button on root cert page allows root store operators to
 rerun ALV for the certs which are in the hierarchy. One inter cert is sent to ALV for 
 processing at a time. It calls common methods from RunALVForInterCertsBatch.
 
 There is another process that is related to ALV processing on inter certs. When a user makes 
 changes to auditor or audit fields on root or intermediate certificate records, the account 
 trigger (UpdateALVDateProcessed method) will traverse down the hierarchy to clear all of the ALV 
 fields for child (grandchild, etc) records that have "Audits Same as Parent" (includes 
 expired and revoked). There are 3 ways ALV can be rerun for these certs:
 1. A nightly scheduled batch job "ALV Batch for Inter Certs" will automatically pick these
 inter certs and rerun ALV.
 2. A system admin can initiate "ALV Batch for Inter Certs" batch process anytime from 
 "Batch Processes" custom tab.
 3. "Use this "Run ALV on Hierarchy" process from a button on the root cert.

 Instructions: 

 *******************************************************************************************************
 Revision History:
 
     10/26/2019 - Created new 

 ******************************************************************************************************/
public with sharing class RunALVonHierarchyController {
    
    public boolean isRunALV {get; set;}
    public Id accid;
    
    public RunALVonHierarchyController(Apexpages.standardcontroller controller){
        isRunALV = false;
        accId = controller.getId();
    }
    
    public PageReference RunALVForChildAccounts(){
        try {
            isRunALV = true;
            List<string> lstInterCertId = new List<string>();
            if(accId != null){
            
                //query on all intermediate certs which has audits same parent is checked and 
                // fill map with key as parent id.
                
                map<Id, List<Account>> mapInterCertAccounts = new map<Id, List<Account>>();
                for(Account objAcc: [select Id, ParentId,Parent.Name, Name from Account Where RecordType.Name = 'Intermediate Certificate' 
                                        AND Audits_Same_as_Parent__c = true]){
                    if(mapInterCertAccounts.containskey(objAcc.ParentId)){
                        mapInterCertAccounts.get(objAcc.ParentId).add(objAcc);
                    } else {
                        mapInterCertAccounts.put(objAcc.ParentId, new List<Account>{objAcc});
                    }
                }
                
                List<Account> lstAccToUpdate = new List<Account>();
                set<Id> setofAccountIdsToUpdate = new set<Id>();
                set<Id> setOfIdsToCheckChild = new set<Id>();
                setOfIdsToCheckChild.add(accId);
                
                //do while loop to get child and grand childs (n level) with audit same as parent is 
                // checked and clears ALV fields and add in list to update
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
                                    lstInterCertId.add('\''+objAcc.Id+'\'');
                                    lstAccToUpdate.add(objAcc);
                                }
                                setofAccountIdsToUpdate.add(objAcc.Id);
                                if(mapInterCertAccounts.containskey(acc.Id)){
                                    setOfIdsToCheckChild.add(acc.Id);
                                    // system.debug('acc.ParentName ::: '+acc.Name);
                                }
                            }
                        }
                        setOfIdsToCheckChild.remove(accId);
                    }
                    // system.debug('setOfIdsToCheckChild ::: '+setOfIdsToCheckChild);
                }
                if(lstAccToUpdate.size() > 0){
                    AccountTriggerHelper.isRecursiveUpdate = true;
                    
                    // update accounts to clear ALV fields.
                    update lstAccToUpdate;
                    AccountTriggerHelper.isRecursiveUpdate = false;
                    
                    // create query to Run ALV only for intermediate certs which are  
                    // not revoked and not expired and child of this root certificate
                    
                    string allIds = '(' + string.join(lstInterCertId, ',') + ')';
                    string FinalQuery = 'SELECT Id, CA_Owner_Certificate_No__c, Name, CA_Owner__c, Subordinate_CA_Owner__c, ' +
                           'Auditor_New__r.Name, Auditor_New__r.Alternate_Auditor_Name_s__c,Date_ALV_Processed__c, ' +
                           'SHA_1_Fingerprint__c, SHA_256_Fingerprint__c, ParentId, ' +
                           'Audits_Same_as_Parent__c,Subject_SPKI_SHA256__c,Extended_Key_Usage__c, ' +
                           'Standard_Audit__c, Standard_Audit_Type__c, Standard_Audit_Statement_Date__c, ' +  
                           'Standard_Audit_Period_Start_Date__c,Standard_Audit_Period_End_Date__c, ' +             
                           'Code_Signing_Audit__c, Code_Signing_Audit_Type__c, Code_Signing_Audit_Statement_Date__c, ' +
                           'Code_Signing_Audit_Period_Start_Date__c, Code_Signing_Audit_Period_End_Date__c, ' +
                           'BR_Audit__c, BR_Audit_Type__c,BR_Audit_Statement_Date__c, ' +
                           'BR_Audit_Period_Start_Date__c,BR_Audit_Period_End_Date__c, ' +
                           'EV_Audit__c, EV_Audit_Type__c, EV_Audit_Statement_Date__c, ' +
                           'EV_Audit_Period_Start_Date__c, EV_Audit_Period_End_Date__c, ' +
                           'EV_Code_Signing_Audit__c, EV_Code_Signing_Audit_Type__c, EV_Code_Signing_Audit_Statement_Date__c, ' +
                           'EV_Code_Signing_Audit_Period_Start_Date__c, EV_Code_Signing_Audit_Period_End_Date__c, ' +
                           'Standard_Audit_ALV_Status__c, Standard_Audit_ALV_Results__c, ' +
                           'BR_Audit_ALV_Status__c, BR_Audit_ALV_Results__c, ' +
                           'Code_Signing_Audit_ALV_Status__c, Code_Signing_Audit_ALV_Results__c, ' +
                           'EV_SSL_Audit_ALV_Status__c, EV_SSL_Audit_ALV_Results__c,Derived_Trust_Bits__c, ' +
                           'Root_Cert_Id__c,Root_Cert_Id__r.Microsoft_Trust_Bits__c,Root_Cert_Id__r.Microsoft_EV_Enabled__c ' +
                           'FROM Account ' +
                           'WHERE RecordType.Name = \'Intermediate Certificate\' ' +
                           'AND Valid_To_GMT__c > '+system.now().format('YYYY-MM-dd')+' AND Revocation_Status__c = \'Not Revoked\' ' +
                           'AND Id in '+ allIds;
                    
                    // pass this query to batch program which process intermediate certs (one at a time) for ALV processing      
                    RunALVForInterCertsBatch batch = new RunALVForInterCertsBatch(FinalQuery);
                    Database.executeBatch(batch,1);
                    
                    ApexPages.addMessage(new Apexpages.Message(ApexPages.Severity.Confirm,'Batch job initiated, please check for ALV results after some time. The batch job can take more than an hour to complete.'));
                } else {
                    ApexPages.addMessage(new Apexpages.Message(ApexPages.Severity.Error,'There are no intermediate cert records with "Audits Same As Parent" to process.'));    
                }
                //PageReference pg = new PageReference('/'+accId);
                //return pg;
            }
        } catch (Exception ex){
            Apexpages.addMessages(ex);
        }
        return null;
    }
}
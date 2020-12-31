/*
    Batch Program is created to run ALV for Intermediate certs.
    
    //WHAT DO
    -> When batch runs, check for all Intermediate certs where subordinate ca owner is not blank, Audit same as Parent not checked, not revoked, not expired. 
    -> It also check if all audits populated and Date ALV Processed is blank or lesser than Audit 
     statement then it runs ALV for that intermediate certs.
    
    //TO RUN THIS BATCH
    RunALVForInterCertsBatch batch = new RunALVForInterCertsBatch('');
    Database.executeBatch(batch,1);
*/
global class RunALVForInterCertsBatch implements Database.Batchable<Sobject>, Database.AllowsCallouts {
    static Date dttoday = system.today(); 
    global final String Query;
    
    global RunALVForInterCertsBatch (String q){
        if(string.isnotblank(q)){
            Query = q;
        } else {
            Query = 'SELECT Id, CA_Owner_Certificate_No__c, Name, CA_Owner__c, Subordinate_CA_Owner__c, ' +
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
               'WHERE RecordType.Name = \'Intermediate Certificate\' ' + //Subordinate_CA_Owner__c != null AND Audits_Same_as_Parent__c = false
               'AND Valid_To_GMT__c >: dttoday AND Revocation_Status__c = \'Not Revoked\'';
               //' AND CA_Owner_ID__c = \'0015600000EEeoRAAT\'';//for Testing purpose
        }
        //system.debug('Query  ::: '+Query );
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC){
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext BC, List<Account> lstAccounts){
        if(lstAccounts.size() == 1) {
            Account objAcc = lstAccounts[0];
            boolean isRunALV = false;
            if(!objAcc.Audits_Same_as_Parent__c && objAcc.Subordinate_CA_Owner__c != null && (string.isnotblank(objAcc.Standard_Audit__c) || string.isnotblank(objAcc.BR_Audit__c) || 
                    string.isnotblank(objAcc.Code_Signing_Audit__c) || string.isnotblank(objAcc.EV_Audit__c)) && objAcc.Date_ALV_Processed__c == null){
                isRunALV = true;
            } else if(!objAcc.Audits_Same_as_Parent__c && objAcc.Subordinate_CA_Owner__c != null && objAcc.Date_ALV_Processed__c != null && 
                            ((objAcc.Standard_Audit_Statement_Date__c != null && objAcc.Date_ALV_Processed__c < objAcc.Standard_Audit_Statement_Date__c) || 
                            (objAcc.BR_Audit_Statement_Date__c != null && objAcc.Date_ALV_Processed__c < objAcc.BR_Audit_Statement_Date__c) ||
                            (objAcc.Code_Signing_Audit_Statement_Date__c != null && objAcc.Date_ALV_Processed__c < objAcc.Code_Signing_Audit_Statement_Date__c) ||
                            (objAcc.EV_Audit_Statement_Date__c != null && objAcc.Date_ALV_Processed__c < objAcc.EV_Audit_Statement_Date__c))){
                isRunALV = true;
            } else if(objAcc.Audits_Same_as_Parent__c){
                if(objAcc.Date_ALV_Processed__c == null){
                    isRunALV = true;
                } else if(objAcc.Date_ALV_Processed__c != null){
                    boolean isFound = false;
                    Id accParentId = objAcc.ParentId;
                    Account objParentAccount;
                    while(!isFound){
                        objParentAccount = GetParentAccount(accParentId);
                        if(objParentAccount != null && !objParentAccount.Audits_Same_as_Parent__c) {
                            isFound = true;
                        } else if(objParentAccount == null) {
                            isFound = true;
                        }
                        if(objParentAccount != null) accParentId = objParentAccount.ParentId;
                    }
                    if((objParentAccount.Standard_Audit_Statement_Date__c != null && objAcc.Date_ALV_Processed__c < objParentAccount.Standard_Audit_Statement_Date__c) || 
                        (objParentAccount.BR_Audit_Statement_Date__c != null && objAcc.Date_ALV_Processed__c < objParentAccount.BR_Audit_Statement_Date__c) ||
                        (objParentAccount.Code_Signing_Audit_Statement_Date__c != null && objAcc.Date_ALV_Processed__c < objParentAccount.Code_Signing_Audit_Statement_Date__c) ||
                        (objParentAccount.EV_Audit_Statement_Date__c != null && objAcc.Date_ALV_Processed__c < objParentAccount.EV_Audit_Statement_Date__c)){
                        isRunALV = true;
                    }
                }
            }
            if(isRunALV){
                JixiServiceInterCertsController jixicontroller = new JixiServiceInterCertsController(new Apexpages.standardcontroller(lstAccounts[0]));
                jixicontroller.prepareRequest();
                jixicontroller.doCallOut();
                jixicontroller.postCallActions();
            }
        }
    }
    
    global void finish(Database.BatchableContext BC){
    
    }
    
    public static Account GetParentAccount(string accId){
        List<Account> lstAcc = new List<Account>([select Id, ParentId, RecordType.Name,
                        Certificate_Policy_CP__c, Certification_Practice_Statement_CPS__c,
                        Parent.Certificate_Policy_CP__c, Parent.Certification_Practice_Statement_CPS__c,
                        Standard_Audit__c, Parent.Standard_Audit__c, Code_Signing_Audit__c, Parent.Code_Signing_Audit__c,
                        BR_Audit__c, Parent.BR_Audit__c, EV_Audit__c, Parent.EV_Audit__c, 
                        Audits_Same_as_Parent__c, Parent.Audits_Same_as_Parent__c,
                        CP_CPS_Same_as_Parent__c, Parent.CP_CPS_Same_as_Parent__c,
                        Code_Signing_Audit_Statement_Date__c,EV_Audit_Statement_Date__c,Standard_Audit_Statement_Date__c,BR_Audit_Statement_Date__c
                        from Account Where Id =: accId]);
        if(lstAcc.size() > 0){
            return lstAcc[0];
        }
        return null;
    }
}
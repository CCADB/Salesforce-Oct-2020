/*
    Description: Class is created for report "Intermediate Certs - Failed ALV Results"
*/
public with sharing class ICFailedALVResultsController {
    
    public List<Account> lstAccountsFailedALVResults {get; set;}
    
    public ICFailedALVResultsController(){
        lstAccountsFailedALVResults = new List<Account>();
        List<Account> lstAcc = new List<Account>([select Id, ParentId, Name, Parent.Name,CA_Owner_Name__c ,
                        Mozilla_Root_Status__c, Microsoft_Root_Status__c, OneCRL_Status__c, Standard_Audit_ALV_Found_Cert__c,
                        Standard_Audit_ALV_Comments__c, BR_Audit_ALV_Found_Cert__c, BR_Audit_ALV_Comments__c, Audits_Same_as_Parent__c, 
                        Standard_Audit_Statement_Date__c, CA_Owner__c, CA_Owner_ID__c
                        from Account Where RecordType.Name = 'Intermediate Certificate' AND
                        Valid_To_GMT__c > TODAY AND
                        Name != '<Fill in Cert Name>' AND Revocation_Status__c = 'Not Revoked'
                        AND (Standard_Audit_ALV_Found_Cert__c = 'FAIL' OR BR_Audit_ALV_Found_Cert__c = 'FAIL')
                        AND ( Mozilla_Root_Status__c In ('Included','Change Requested') OR Microsoft_Root_Status__c In ('Included','Change Requested'))
                        AND Technically_Constrained__c = FALSE
                        ORDER BY CA_Owner__c, Name]);
        map<Id, Account> mapofAllAccounts = new map<Id,Account>([select Id, Name, ParentId, 
                        Audits_Same_as_Parent__c, Standard_Audit_Statement_Date__c, RecordType.Name
                        from Account]);
        for(Account acc: lstAcc){
            if(acc.Audits_Same_as_Parent__c){
                Id accParentId = acc.ParentId;
                boolean isFound = false;
                while(!isFound){
                    Account objParentAccount = GetParentAccount(accParentId, mapofAllAccounts);
                    if(objParentAccount != null && (objParentAccount.RecordType.Name == 'Root Certificate' || !objParentAccount.Audits_Same_as_Parent__c)) {
                        isFound = true;
                        acc.Standard_Audit_Statement_Date__c = objParentAccount.Standard_Audit_Statement_Date__c;
                    } else if(objParentAccount == null) {
                        isFound = true;
                    }
                    if(objParentAccount != null) accParentId = objParentAccount.ParentId;
                }
            }
            lstAccountsFailedALVResults.add(acc);
        }
    }
    
    String CurrentDate = ' ';
    // Get current Datetime in long date format   
    public String getCurrentDate() {
        Datetime cDT = System.now();
        CurrentDate = cDT.format('MMMM d, yyyy');
        return CurrentDate;
    }
    
    public Account GetParentAccount(string accId, map<Id,Account> mapOfAllAccs){
        if(mapOfAllAccs.size() > 0 && mapOfAllAccs.containskey(accId)){
            return mapOfAllAccs.get(accId);
        }
        return null;
    }
}
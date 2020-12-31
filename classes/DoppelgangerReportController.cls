/*******************************************************************************************************
 Name: DoppelgangerReportController

 Dependencies: DoppelgangerReportController controller class, DoppelgangerReport vf page, 
 DoppelgangerReportControllerTest test class

 Description: This controller class finds Intermediate certificates that have the same Subject+SPKI, 
 some are technically-constrained (via EKU and domain name) and others are not. Only the inter
 certs that chain upto Mozilla or Microsoft (Included, Change Requested) are processed.
 
 Instructions: None
 *******************************************************************************************************
 Revision History:
 
     09/09/2019 - Created new class
     10/15/2019 - Added filter condtions for Mozilla Root Status and Microsoft Root Status = Included or 
                  Change Requested
     10/29/2019 - Added new columns to the report             
 ******************************************************************************************************/

public with sharing class DoppelgangerReportController {
    
    public List<WrapperDoppelgangerAccounts> lstWrapDopAccounts {get; set;}
    
    public DoppelgangerReportController(){
        lstWrapDopAccounts = new List<WrapperDoppelgangerAccounts>();
        
        List<Account> lstAccounts = new List<Account>([SELECT Id, Name, CA_Owner__c, 
               Subject_SPKI_SHA256__c, Certificate_Serial_number__c,
               Mozilla_Root_Status__c, Microsoft_Root_Status__c, Derived_Trust_Bits__c,
               Has_Non_constrained_Doppelganger__c, Technically_Constrained__c,
               Standard_Audit_ALV_Found_Cert__c, BR_Audit_ALV_Found_Cert__c
               FROM Account 
               WHERE RecordType.Name = 'Intermediate Certificate' 
               AND (Mozilla_Root_Status__c IN ('Included','Change Requested') OR Microsoft_Root_Status__c IN  ('Included','Change Requested'))
               AND Subject_SPKI_SHA256__c != null 
               AND Technically_Constrained__c = TRUE  
               AND Valid_To_GMT__c > TODAY 
               AND Revocation_Status__c = 'Not Revoked']);
        
        if(lstAccounts.size() > 0){
            map<string, Account> mapOfSubjectSPKIWiseAccount = new map<string, Account>();
            map<string, List<Account>> mapOfSubjectSPKIWiseAllAccounts = new map<string, List<Account>>();
            for(Account objAcc: lstAccounts){
                mapOfSubjectSPKIWiseAccount.put(objAcc.Subject_SPKI_SHA256__c, objAcc);
                if(mapOfSubjectSPKIWiseAllAccounts.containskey(objAcc.Subject_SPKI_SHA256__c)){
                    mapOfSubjectSPKIWiseAllAccounts.get(objAcc.Subject_SPKI_SHA256__c).add(objAcc);
                } else {
                    mapOfSubjectSPKIWiseAllAccounts.put(objAcc.Subject_SPKI_SHA256__c, new List<Account>{objAcc});
                }
            }
            map<string, List<Account>> mapOfSameSubjectSPKIAccounts = new map<string, List<Account>>();
            List<Account> lstSameSubjectSPKI = new List<Account>([SELECT Name, CA_Owner__c, 
                    Subject_SPKI_SHA256__c, Certificate_Serial_number__c,
                    Mozilla_Root_Status__c, Microsoft_Root_Status__c, Derived_Trust_Bits__c, 
                    Has_Non_constrained_Doppelganger__c,Technically_Constrained__c,  
                    Standard_Audit_ALV_Found_Cert__c, BR_Audit_ALV_Found_Cert__c
                    FROM Account 
                    WHERE Subject_SPKI_SHA256__c =: mapOfSubjectSPKIWiseAccount.keyset() 
                    AND RecordType.Name = 'Intermediate Certificate' 
                    AND (Mozilla_Root_Status__c IN ('Included','Change Requested') OR Microsoft_Root_Status__c IN  ('Included','Change Requested'))
                    AND Revocation_Status__c = 'Not Revoked' 
                    AND Valid_To_GMT__c > TODAY 
                    AND Technically_Constrained__c = FALSE]);
                    //Has_Non_constrained_Doppelganger__c = FALSE]);
            for(Account acc: lstSameSubjectSPKI){
                if(mapOfSameSubjectSPKIAccounts.containskey(acc.Subject_SPKI_SHA256__c)){
                    mapOfSameSubjectSPKIAccounts.get(acc.Subject_SPKI_SHA256__c).add(acc);
                } else {
                    mapOfSameSubjectSPKIAccounts.put(acc.Subject_SPKI_SHA256__c, new List<Account>{acc});
                }
            }
            
            if(mapOfSameSubjectSPKIAccounts.size() > 0) {
                for(string SubjectSPKI: mapOfSameSubjectSPKIAccounts.keyset()){
                    if(mapOfSubjectSPKIWiseAccount.containskey(SubjectSPKI)){
                        Account objAccount = mapOfSubjectSPKIWiseAccount.get(SubjectSPKI);
                        List<Account> lstAccountsAll = mapOfSameSubjectSPKIAccounts.get(SubjectSPKI);
                        if(mapOfSubjectSPKIWiseAllAccounts.containskey(SubjectSPKI)) {
                            for(Account acc: mapOfSubjectSPKIWiseAllAccounts.get(SubjectSPKI)){
                                if(acc.Id != objAccount.Id){
                                    lstAccountsAll.add(acc);
                                }
                            }
                        }
                        lstWrapDopAccounts.add(new WrapperDoppelgangerAccounts(objAccount, lstAccountsAll));
                    }
                }
            }
        }
    }
    
    public class WrapperDoppelgangerAccounts {
        public Account objAcc {get; set;}
        public List<Account> lstAccounts {get; set;}
        public WrapperDoppelgangerAccounts(Account acc, List<Account> accounts){
            this.objAcc = acc;
            this.lstAccounts = accounts;
        }
    }
}
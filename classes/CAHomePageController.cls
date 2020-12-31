/*******************************************************************************************************
 Name: CAHomePageController

 Dependencies: CAHomePageController controller class, CAHomePage vf page, 
 CAHomePageControllerTest test class

 Description: This is a controller class for CA's Task List (added to home page). It generates
 various reports and a summary wih record count for the CA Owner to which the logged in user is 
 associated. Detail report is only displayed when the record count is greater than 1.
 
 Root Certs with Outdated Audit Statements
 Intermediate Certs with Outdated Audit Statements
 Intermediate Certs with no audit information provided
 Intermediate Certs with no CP/CPS information provided
 Intermediate Certs with ALV Results.
 Contacts who may be obsolete
 
 Instructions: Add the VF page to CA's home page
 *******************************************************************************************************
 Revision History:
 
     5/31/2019 - Created new class
     8/13/2019 - Added Externally Operated Intermediate Certs missing Owner or Auditor Info
     8/13/2019 - Updated Where condition for Externally Operated Intermediate certs Missing Info.
     9/22/2019 - Added a new section for Intermediate Certs with ALV Results
    10/07/2019 - Changed in condition for ALV results and added Found Cert = FAIL condition.
    12/16/2019 - Updated columns "Check failed Audit Letter Validation (ALV) results"
    08/03/2020 - For outdated root certs added filter for Valid_To > TODAY
 ******************************************************************************************************/
 
public without sharing class CAHomePageController {
    
    public List<User> lstUsersNotUsed {get; set;}
    public List<Account> lstOutDatedRootCerts {get; set;}
    public List<Account> lstOutDatedIntermediateCerts {get; set;}
    public List<Account> lstIntermediateCertsNoAudits {get; set;}
    public List<Account> lstIntermediateCertsNoCPCPS {get; set;}
    public List<Account> lstIntermediateCertsMissingInfo {get; set;}
    public List<Account> lstIntermediateCertsALVResults {get; set;}
    public string strMissingCAOwnerInfo {get; set;}
    public string strCAOwnerName {get; set;}
    public CAHomePageController(){
        strMissingCAOwnerInfo = '';
        Id userId = UserInfo.getUserId();
        List<User> lstLoggedUser = new List<User>([select Id,Name,AccountId, Account.Name,ContactId from User Where Id =: userId]);
        if(lstLoggedUser.size() > 0 && lstLoggedUser[0].AccountId != null){
            strCAOwnerName = lstLoggedUser[0].Account.Name;
            //check for missing CA Information.
            /*List<Account> lstCAOwnerMF = new List<Account>([select Id,Name,Recognized_CAA_Domains__c,Problem_Reporting_Mechanism__c,
                                BillingStreet, BillingCity, BillingState, BillingCountry, BillingPostalCode,Status__c,Microsoft_Status__c
                                from Account Where RecordType.Name = 'CA Owner' and
                                Id =: lstLoggedUser[0].AccountId]);
            for(Account objAcc: lstCAOwnerMF){
                if(string.isblank(objAcc.BillingStreet)){
                    strMissingCAOwnerInfo += 'Street not provided.<br/>';
                } 
                if(string.isblank(objAcc.BillingCity)){
                    strMissingCAOwnerInfo += 'City not provided.<br/>';
                }
                if(string.isblank(objAcc.BillingState)){
                    strMissingCAOwnerInfo += 'State not provided.<br/>';
                }
                if(string.isblank(objAcc.BillingCountry)){ 
                    strMissingCAOwnerInfo += 'Country not provided.<br/>';
                }
                if(string.isblank(objAcc.BillingPostalCode)){
                    strMissingCAOwnerInfo += 'Postal code not provided.<br/>';
                } 
                if(string.isblank(objAcc.Recognized_CAA_Domains__c)){
                    strMissingCAOwnerInfo += 'Recognized CAA Domains not provided.<br/>';
                }
                if(string.isblank(objAcc.Problem_Reporting_Mechanism__c)){
                    strMissingCAOwnerInfo += 'Problem Reporting Mechanism not provided.<br/>';
                }
            }*/
            
            //checking for outdated root certs.
            lstOutDatedRootCerts = new List<Account>();
            lstOutDatedRootCerts = [SELECT Name, CA_Owner__c, Standard_Audit_Period_End_Date__c,
                            BR_Audit_Period_End_Date__c, Code_Signing_Audit_Period_End_Date__c, 
                            EV_Code_Signing_Audit_Period_End_Date__c, EV_Audit_Period_End_Date__c
                            FROM Account 
                            WHERE Name != '<Fill in Cert Name>'
                            AND Record_Type_Name__c = 'Root Certificate'                           
                            AND (Standard_Audit_Period_End_Date__c < LAST_N_DAYS:396 OR BR_Audit_Period_End_Date__c < LAST_N_DAYS:396 OR
                                Code_Signing_Audit_Period_End_Date__c < LAST_N_DAYS:396 OR EV_Code_Signing_Audit_Period_End_Date__c < LAST_N_DAYS:396 OR
                                EV_Audit_Period_End_Date__c < LAST_N_DAYS:396)
                            AND (Status__c IN  ('Included','Change Requested') OR Microsoft_Status__c IN ('Included','Change Requested')) 
                            AND Valid_To_GMT__c > TODAY   
                            AND CA_Owner_ID__c =: lstLoggedUser[0].AccountId
                            ORDER BY Name]; 
            
            //chekcing for outdated intermediate certs.
            lstOutDatedIntermediateCerts = new List<Account>();
            lstOutDatedIntermediateCerts = [SELECT Name, CA_Owner__c, Standard_Audit_Period_End_Date__c,
                            BR_Audit_Period_End_Date__c, Code_Signing_Audit_Period_End_Date__c, 
                            EV_Code_Signing_Audit_Period_End_Date__c, EV_Audit_Period_End_Date__c                                                               
                            FROM Account 
                            WHERE Name != '<Fill in Cert Name>'
                            AND Record_Type_Name__c = 'Intermediate Certificate'
                            AND Revocation_Status__c NOT IN ('Revoked', 'Parent Cert Revoked')
                            AND Valid_To_GMT__c > TODAY   
                            AND (Standard_Audit_Period_End_Date__c < LAST_N_DAYS:396 OR BR_Audit_Period_End_Date__c < LAST_N_DAYS:396 OR
                                Code_Signing_Audit_Period_End_Date__c < LAST_N_DAYS:396 OR EV_Code_Signing_Audit_Period_End_Date__c < LAST_N_DAYS:396 OR
                                EV_Audit_Period_End_Date__c < LAST_N_DAYS:396)
                            AND Root_Status__c IN  ('Included','Change Requested') AND CA_Owner_ID__c =: lstLoggedUser[0].AccountId
                            ORDER BY Name]; 
            
            //checking if No audits are provided on intermediate certs
            lstIntermediateCertsNoAudits = new List<Account>();
            lstIntermediateCertsNoAudits = [SELECT Id, Name 
                            FROM Account 
                            WHERE Name != '<Fill in Cert Name>'
                            AND Record_Type_Name__c = 'Intermediate Certificate' 
                            AND Revocation_Status__c NOT IN ('Revoked', 'Parent Cert Revoked')
                            AND Valid_To_GMT__c > TODAY  
                            AND Technically_Constrained__c = false 
                            AND Audits_Same_as_Parent__c = false
                            AND Standard_Audit__c = null AND Code_Signing_Audit__c = null AND BR_Audit__c = null AND
                            EV_Audit__c = null AND EV_Code_Signing_Audit__c = null
                            AND CA_Owner_ID__c =: lstLoggedUser[0].AccountId
                            ORDER BY Name]; 
                            
            //checking if No CP/CPS are provided on intermediate certs
            lstIntermediateCertsNoCPCPS = new List<Account>();
            for(Account acc: [SELECT Id, Name,Certificate_Policy_CP__c,Certification_Practice_Statement_CPS__c  
                              FROM Account 
                              WHERE Name != '<Fill in Cert Name>'
                              AND Record_Type_Name__c = 'Intermediate Certificate' 
                              AND Revocation_Status__c NOT IN ('Revoked', 'Parent Cert Revoked')
                              AND Valid_To_GMT__c > TODAY   
                              AND Technically_Constrained__c = false
                              AND CP_CPS_Same_as_Parent__c = false
                              AND CA_Owner_ID__c =: lstLoggedUser[0].AccountId
                              ORDER BY Name]){
                if(string.isblank(acc.Certificate_Policy_CP__c) && string.isblank(acc.Certification_Practice_Statement_CPS__c)){
                    lstIntermediateCertsNoCPCPS.add(acc); 
                }
            }
            
            //Externally Operated Intermediate Certs missing Owner or Auditor Info
            lstIntermediateCertsMissingInfo = new List<Account>();
            lstIntermediateCertsMissingInfo = new List<Account>([SELECT Id,Name,CA_Owner__c,Certificate_Name__c,Valid_From_GMT__c,Revocation_Status__c ,
                        Valid_To_GMT__c,Subordinate_CA_Owner__c,Auditor_New__c,Auditor_New__r.Name,Audits_Same_as_Parent__c 
                        FROM Account 
                        WHERE RecordType.Name = 'Intermediate Certificate' 
                        AND Revocation_Status__c = 'Not Revoked' 
                        AND OneCRL_Status__c != 'Added to OneCRL'
                        AND Valid_To_GMT__c > TODAY 
                        AND CA_Owner_ID__c =: lstLoggedUser[0].AccountId
                        AND Audits_Same_as_Parent__c = FALSE AND (Subordinate_CA_Owner__c = null OR Auditor_New__c = null)
                        AND Root_Cert_Id__r.Status__c In ('Included','Change Requested') 
                        AND Technically_Constrained__c = FALSE
                        Order by Name,CA_Owner__c]);
            
            
            //Intermediate certs with ALV Results
            lstIntermediateCertsALVResults = new List<Account>([SELECT Id,Name,Audits_Same_as_Parent__c,Valid_To_GMT__c,
                        OneCRL_Status__c, Root_Cert_Id__r.Status__c, Root_Cert_Id__r.Microsoft_Status__c,
                        SHA_256_Fingerprint__c, Standard_Audit_ALV_Found_Cert__c,Standard_Audit_ALV_Comments__c,
                        BR_Audit_ALV_Found_Cert__c,BR_Audit_ALV_Comments__c,Date_ALV_Processed__c, Technically_Constrained__c
                        FROM Account
                        WHERE RecordType.Name = 'Intermediate Certificate' 
                        AND Revocation_Status__c = 'Not Revoked' 
                        AND OneCRL_Status__c != 'Added to OneCRL'
                        AND Valid_To_GMT__c > TODAY 
                        AND Technically_Constrained__c = False
                        AND CA_Owner_ID__c =: lstLoggedUser[0].AccountId 
                        AND (Root_Cert_Id__r.Status__c In ('Included','Change Requested') OR Root_Cert_Id__r.Microsoft_Status__c in ('Included','Change Requested')) 
                        AND (Standard_Audit_ALV_Found_Cert__c = 'FAIL' OR BR_Audit_ALV_Found_Cert__c = 'FAIL')]);
                        
                        /*AND (ALV_Status__c = 'FAIL' OR Standard_Audit_ALV_Status__c = 'FAIL' OR
                        BR_Audit_ALV_Status__c = 'FAIL')]);*/
            
            //checking for CA's Contact whoes dont logged more than 1.5 year.
            Date dtPast18Months = system.today().addMonths(-18); 
            
            //if it is CA user
            lstUsersNotUsed = new List<User>();
            if(lstLoggedUser[0].AccountId != null){
                lstUsersNotUsed = new List<User>([select Id, Name, Email, LastLoginDate, ContactId, Contact.Type__c 
                            FROM User 
                            Where IsActive = true 
                            AND (LastLoginDate = null or LastLoginDate <=: dtPast18Months)
                            AND AccountId =: lstLoggedUser[0].AccountId
                            ORDER BY Name]);
            }   
        }
    }
}
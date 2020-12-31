/*******************************************************************************************************
 Name: RSHomePageController

 Dependencies: RSHomePageController controller class, RSHomePage vf page, RSHomePageControllerTest test class

 Description: This is Mozilla's Root Store's Task List report (added to home page). It generates
 various reports wih record count. Detail report is only displayed when the 
 record count is greater than 1.
    
    Report sections showing the following ...
    
    1) Open Leads 
    2) Open Audit Cases assigned to Mozilla which are updated by CA 
    3) Open Root Inclusion Cases which are updated by CA 
    4) Audit Data Integrity (which linked to vf page)
    5) Verify Updated Audits
    6) Verify Revoked Certs 
    7) Externally Operated Intermediate Certs missing Owner or Auditor Info
    8) Expired Root Certificates
    9) CAs Missing Email Alias 
   10) Ready to Add to OneCRL
   11) Deltas between "Mozilla EV Policy OID(s)" and "ExtendedValidation.cpp OIDs"
   12) Revoked Certs with Failed Revocation Verification
   13) Root Certs with Distrust After
   14) Unconstrained SubCAs Report
    
 Instructions: Add the VF page to Root Store's home page
 *******************************************************************************************************
 Revision History:
 
     7/2/2019 - Created new class.
     7/12/2019 - Adding new section Externally Operated Intermediate Certs missing Owner or Auditor Info.
     8/5/2019  - Added custom sort for CRL URL column and other minor additions.
     8/13/2019 - Updated Where condition for Externally Intermediate certs Missing Info.
     8/29/2019 - Added filter for "Denied" records; IsConverted check was not sufficient.
     9/10/2019 - Found that using wrong status 'Changed Requested', so updated to 'Change Requested'
     9/23/2019 - Added a new section 'CAs Missing Emails'
     10/26/2019 - Replaced Revocation Verification field on page in Verify Revoked Cert section and added a new section Ready to Add to OneCRL.
     11/12/2019 - Adding a new section which shows deltas between "Mozilla EV Policy OID(s)" and "ExtendedValidation.cpp OIDs"
     02/06/2020 - Added a new section which shows Root Certs with Distrust After
     02/08/2020 - Adding Unconstrained SubCA Status
     05/08/2020 - Added a condition for Verify Revoked certs that display certs only if Derived Trust bits doesn't have Server Authentication.
     09/30/2020 - Updated filter for 'Verify Revoked Certs'
 ******************************************************************************************************/
 
public with sharing class RSHomePageController {
    
    public List<Lead> lstOpenLeads {get; set;}
    public List<Case> lstAuditCases {get; set;}
    public List<Case> lstInclusionCases {get; set;}   
    public List<Account> lstVerifyUpdatedAudits {get; set;}
    public List<Account> lstVerifyRevokedCerts {get; set;}
    public List<Account> lstIntermediateCertsMissingInfo {get; set;}
    public List<Account> lstExpiredRootCertificates {get; set;}
    public List<Account> lstCAsMissingEmails {get; set;}
    public List<Account> lstReadytoAddtoOneCRL {get; set;}
    public List<Account> lstDeltasEVOIDs {get; set;}
    public List<Account> lstRevokedFailedRevocationCerts {get; set;}
    public List<Account> lstAccountsDistrust {get; set;}
    public List<Account> lstUnconstrainedSubCA {get; set;}
    
    public RSHomePageController(){
    
        lstOpenLeads = new List<Lead>([select Id, Name, Website, Company, Organization_Type__c, CP_CPS_document_URLs__c, Sponsored_By__c 
                                       from Lead where Status != 'Denied' and IsConverted = false Order by Sponsored_By__c desc]);

        List<User> lstCAUsers = new List<User>([select Id from User Where ContactID != null]);
                 
        lstAuditCases = new List<Case>([select ID, CaseNumber, AccountId, Account.Name, Case_Progress__c, Request_Status__c,Latest_Case_Comment__c,
                        Case_Assigned_To__c, Case_Assigned_To__r.Name, Subject, LastModifiedDate, LastModifiedById, LastModifiedBy.Name
                        From Case Where RecordType.Name = 'CA Audit Update Request' AND Request_Status__c != 'Complete'
                        And Case_Assigned_To__r.Name In ('Kathleen Wilson', 'Ben Wilson')
                        Order by LastModifiedDate]); 
        
        set<string> setOfRequestStatuses = new set<string>();
        setOfRequestStatuses.add('Initial Request Received');
        setOfRequestStatuses.add('Information Verification in Process');
        setOfRequestStatuses.add('In Detailed CP/CPS Review');
        setOfRequestStatuses.add('In Public Discussion');
        setOfRequestStatuses.add('Pending Approval');
        setOfRequestStatuses.add('Approved, Pending Inclusion');
        setOfRequestStatuses.add('Approved, Pending Inclusion and EV');
        setOfRequestStatuses.add('Included, Pending EV');                         
        lstInclusionCases = new List<Case>([select ID,CaseNumber,AccountId, Account.Name,Status_Summary__c,Request_Status__c,
                        Case_Assigned_To__c,Case_Assigned_To__r.Name, Subject, LastModifiedDate, LastModifiedById, LastModifiedBy.Name,
                        Latest_Case_Comment__c
                        From Case Where RecordType.Name = 'CA Root Inclusion Request' AND Request_Status__c =: setOfRequestStatuses 
                        Order by Request_Status__c, LastModifiedDate]);
        
        lstVerifyUpdatedAudits = new List<Account>([select Id,Name,Standard_Audit_Statement_Date__c,Mozilla_Verified_Audit_Date__c,
                        Removal_Bug_No_or_Date__c, Comments__c, LastModifiedDate, LastModifiedBy.Name                      
                        From Account 
                        Where RecordType.Name = 'Root Certificate' 
                        AND Status__c in ('Included','Change Requested') 
                        AND Audit_Date_Same__c = false
                        Order by Name]);
        
        //verify revoked certs.
        List<wrapperRevokedCerts> lstWrapperRevokedCerts = new List<wrapperRevokedCerts>();
        List<Account> lstVerifyRevokedCertsTemp = new List<Account>([select Id,Name,ParentId,Parent.Name,Certificate_Name__c,Valid_From_GMT__c,
                        Valid_To_GMT__c,Comments__c,CRL_URL_s__c,Certificate_Serial_Number__c,SHA_256_Fingerprint__c,Derived_Trust_Bits__c,
                        OneCRL_Status__c,Date_of_Revocation__c,RFC_5280_Revocation_Reason_Code__c,Revocation_Verification__c  from Account Where 
                        RecordType.Name = 'Intermediate Certificate' AND 
                        Revocation_Status__c = 'Revoked' AND OneCRL_Status__c not in ('Ready to Add','Added to OneCRL','Cert Expired','Not Applicable')                    
                        AND Mozilla_Root_Status__c in ('Included','Change Requested')
                        Order by Name]);
        for(Account objAcc: lstVerifyRevokedCertsTemp){
            if(objAcc.Derived_Trust_Bits__c != null && objAcc.Derived_Trust_Bits__c.contains('Server Authentication')){
                lstWrapperRevokedCerts.add(new wrapperRevokedCerts(objAcc.CRL_URL_s__c, objAcc));
            }
        }
        lstWrapperRevokedCerts.sort();
        lstVerifyRevokedCerts = new List<Account>();
        for(wrapperRevokedCerts revoked: lstWrapperRevokedCerts){
            lstVerifyRevokedCerts.add(revoked.objAcc);
        }
        
        lstIntermediateCertsMissingInfo = new List<Account>([select Id,Name,CA_Owner__c,Certificate_Name__c,Valid_From_GMT__c,Revocation_Status__c ,
                        Valid_To_GMT__c,Subordinate_CA_Owner__c,Auditor_New__c,Auditor_New__r.Name,Audits_Same_as_Parent__c from Account Where 
                        RecordType.Name = 'Intermediate Certificate' 
                        AND Revocation_Status__c = 'Not Revoked' 
                        AND OneCRL_Status__c != 'Added to OneCRL'
                        AND Valid_To_GMT__c > TODAY 
                        AND Audits_Same_as_Parent__c = FALSE 
                        AND (Subordinate_CA_Owner__c = null OR Auditor_New__c = null)
                        AND Root_Cert_Id__r.Status__c In ('Included','Change Requested') 
                        AND Technically_Constrained__c = FALSE
                        Order by Name,CA_Owner__c]);
        
        lstExpiredRootCertificates = new List<Account>([select Id,Name,ParentId, Parent.Name, Valid_From_GMT__c, Valid_To_GMT__c, 
                        Trust_Bits__c, Removal_Bug_No_or_Date__c from Account 
                        WHERE RecordType.Name = 'Root Certificate' 
                        AND Status__c in ('Included','Change Requested') 
                        AND Valid_To_GMT__c < TODAY Order by Parent.Name,Name]);
                        
        lstCAsMissingEmails = new List<Account>([select Id,Name,Status__c from Account 
                        WHERE RecordType.Name = 'CA Owner'
                        AND Status__c in ('Included','Change Requested') 
                        AND CA_Email_Alias_1__c = null 
                        AND CA_Email_Alias_2__c = null
                        Order by Name]);
        
        lstReadytoAddtoOneCRL = new List<Account>([select Id, Name,ParentId, Parent.Name, 
                        Certificate_Serial_Number__c,Revocation_Status__c, Comments__c,
                        Valid_To_GMT__c,OneCRL_Bug_Number__c,OneCRL_Status__c,Revocation_Verification__c FROM Account
                        WHERE RecordType.Name = 'Intermediate Certificate' 
                        AND OneCRL_Status__c = 'Ready to Add'
                        AND Mozilla_Root_Status__c in ('Change Requested', 'Included') Order by Name]);
                        
        lstDeltasEVOIDs = new List<Account>();
        List<Account> lstRootAccs = new List<Account>([select Id,Name,EV_Policy_OID_s__c,ExtendedValidation_cpp_OIDs__c,Status__c,
                            Valid_To_GMT__c
                            FROM Account Where RecordType.Name = 'Root Certificate' 
                            AND EV_Policy_OID_s__c != null 
                            AND ExtendedValidation_cpp_OIDs__c != null 
                            ORDER BY Name]);
        for(Account objAcc: lstRootAccs){
            if(objAcc.EV_Policy_OID_s__c == 'Not EV' && objAcc.ExtendedValidation_cpp_OIDs__c == ''){
                continue;
            } else if(objAcc.EV_Policy_OID_s__c != '' && objAcc.ExtendedValidation_cpp_OIDs__c != ''){
                string[] EVPolicyOIDs = objAcc.EV_Policy_OID_s__c.split(',');
                string[] EVPolicyOIDsCPP = objAcc.ExtendedValidation_cpp_OIDs__c.split(';');
                boolean isDeltaFound = false;
                for(string evoid: EVPolicyOIDs){
                    boolean isMatch = false;
                    for(string evoidcpp: EVPolicyOIDsCPP){
                        if(evoid.trim().tolowercase() == evoidcpp.trim().tolowercase()){
                            isMatch = true;
                        }
                    }
                    if(!isMatch){
                        isDeltaFound = true;
                        lstDeltasEVOIDs.add(objAcc);
                    }
                }
                if(!isDeltaFound){
                    for(string evoidcpp: EVPolicyOIDsCPP){
                        boolean isMatch = false;
                        for(string evoid: EVPolicyOIDs){
                            if(evoidcpp.trim().tolowercase() == evoid.trim().tolowercase()){
                                isMatch = true;
                            }
                        }
                        if(!isMatch){
                            isDeltaFound = true;
                            lstDeltasEVOIDs.add(objAcc);
                        }
                    }
                }
            }
        }
        
        lstRevokedFailedRevocationCerts = new List<Account>([select Id, Name,ParentId, Parent.Name, 
                        Certificate_Serial_Number__c, Revocation_Status__c, Comments__c,
                        Valid_To_GMT__c,OneCRL_Bug_Number__c,OneCRL_Status__c,Revocation_Verification__c FROM Account
                        Where RecordType.Name = 'Intermediate Certificate' 
                        AND Revocation_Status__c = 'Revoked'
                        AND Valid_To_GMT__c >= TODAY
                        AND OneCRL_Status__c in ('Ready to Add','Added to OneCRL')
                        AND (NOT Revocation_Verification__c like '%Revocation automatically verified%') 
                        Order by OneCRL_Status__c desc]);
        
        lstAccountsDistrust = new List<Account>([select Id, Name, CA_Owner__c, Valid_To_GMT__c, Trust_Bits__c,
                        Distrust_for_TLS_After_Date__c, Bug_for_Distrust_for_TLS_After__c, Distrust_for_SMIME_After_Date__c,
                        Bug_for_Distrust_for_S_MIME_After__c, Comments_by_Mozilla_on_Root__c
                        From Account 
                        Where RecordType.Name = 'Root Certificate' 
                        AND Status__c in ('Included','Change Requested') 
                        AND (Distrust_for_TLS_After_Date__c != null OR Distrust_for_SMIME_After_Date__c != null)
                        Order by CA_Owner__c, Name]); 
                        
        Date this2020Year = Date.NewInstance(2020,1,1);
        lstUnconstrainedSubCA = new List<Account>([select Id,Name,CA_Owner__c,Certificate_Name__c,Valid_From_GMT__c,Revocation_Status__c ,
                        Valid_To_GMT__c,Subordinate_CA_Owner__c,Auditor_New__c,Auditor_New__r.Name,Audits_Same_as_Parent__c, 
                        Unconstrained_SubCA_Status__c, Unconstrained_SubCA_Discussion__c from Account Where 
                        RecordType.Name = 'Intermediate Certificate' 
                        AND Root_Cert_Id__r.Status__c In ('Included','Change Requested')
                        AND Valid_From_GMT__c >=: this2020Year
                        AND Valid_To_GMT__c > TODAY
                        AND Technically_Constrained__c = FALSE
                        AND OneCRL_Status__c != 'Added to OneCRL'
                        AND Audits_Same_as_Parent__c = FALSE
                        AND Unconstrained_SubCA_Status__c not in ('Approved','Previously Approved') 
                        Order by CA_Owner__c,Name]);
    }
    
    //wrapper class for Revoked Certs to Sort by CRLURL long text area field.
    public class wrapperRevokedCerts implements Comparable {
        public string CRLURL;
        public Account objAcc;
        public wrapperRevokedCerts (string crl, Account acc){
            this.CRLURL = crl != null ? crl : '';
            this.objAcc = acc;
        }
        public Integer compareTo(Object obj) {
            wrapperRevokedCerts revokedCert = (wrapperRevokedCerts)(obj);
            if (this.CRLURL > revokedCert.CRLURL) {
                return 1;
            }
            if (this.CRLURL == revokedCert.CRLURL) {
                return 0;
            }

            return -1;
        }
    }
}
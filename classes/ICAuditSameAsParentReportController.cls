/*
    Description: Class is created for ICAuditSameAsParentReport page
    
    Report shows Intermediate certs which has same logic (inline message vf page) for Audit Same As Parent.
*/
public with sharing class ICAuditSameAsParentReportController {
    
    public transient List<wrapIntermediateCerts> lstWrapIntermediateCerts {get; set;}
    
    public ICAuditSameAsParentReportController(){
        
        lstWrapIntermediateCerts = new List<wrapIntermediateCerts>();
        
        List<Account> lstAcc = new List<Account>([select Id, ParentId, Name, Parent.Name,CA_Owner_Name__c ,
                        Certificate_Policy_CP__c, Certification_Practice_Statement_CPS__c,CA_Owner__c,
                        Parent.Certificate_Policy_CP__c, Parent.Certification_Practice_Statement_CPS__c,
                        Standard_Audit__c, Parent.Standard_Audit__c, Code_Signing_Audit__c, Parent.Code_Signing_Audit__c,
                        BR_Audit__c, Parent.BR_Audit__c, EV_Audit__c, Parent.EV_Audit__c, 
                        Audits_Same_as_Parent__c, Parent.Audits_Same_as_Parent__c,
                        CP_CPS_Same_as_Parent__c, Parent.CP_CPS_Same_as_Parent__c
                        from Account Where RecordType.Name = 'Intermediate Certificate' AND
                        Name != '<Fill in Cert Name>' AND
                        Root_Cert_Id__r.Status__c In ('Included','Change Requested') AND
                        Valid_To_GMT__c > TODAY AND
                        Technically_Constrained__c = FALSE AND
                        Revocation_Status__c not in ('Revoked','Parent Cert Revoked')
                        order by CA_Owner__c]);
                        
        map<Id, Account> mapofAllAccounts = new map<Id,Account>([select Id, Name, ParentId, RecordType.Name, Parent.Name,
                        Certificate_Policy_CP__c, Certification_Practice_Statement_CPS__c,CA_Owner_Name__c,
                        Parent.Certificate_Policy_CP__c, Parent.Certification_Practice_Statement_CPS__c,
                        Standard_Audit__c, Parent.Standard_Audit__c, Code_Signing_Audit__c, Parent.Code_Signing_Audit__c,
                        BR_Audit__c, Parent.BR_Audit__c, EV_Audit__c, Parent.EV_Audit__c, 
                        Audits_Same_as_Parent__c, Parent.Audits_Same_as_Parent__c,
                        CP_CPS_Same_as_Parent__c, Parent.CP_CPS_Same_as_Parent__c
                        from Account]);
        if(lstAcc.size() > 0){
            for(Account objAcc: lstAcc) {
                string strAuditSameAsParent = '';
                string strCPCPSSameAsParent = '';
                
                //if cp/cps are blank then it should check cp/cps same as parent
                if(string.isblank(objAcc.Certificate_Policy_CP__c) && string.isblank(objAcc.Certification_Practice_Statement_CPS__c) && !objAcc.CP_CPS_Same_as_Parent__c){
                    strCPCPSSameAsParent = 'Please fill in Policies and Practices Information section or mark the checkbox "CP/CPS Same as Parent"';
                }
                //check if cp/cps are same as parent and parent cert cp/cps is not same as parent
                if((string.isnotblank(objAcc.Certificate_Policy_CP__c) || string.isnotblank(objAcc.Certification_Practice_Statement_CPS__c)) && 
                    !objAcc.CP_CPS_Same_as_Parent__c && !objAcc.Parent.CP_CPS_Same_as_Parent__c && (string.isblank(objAcc.Certificate_Policy_CP__c) || 
                    (string.isnotblank(objAcc.Certificate_Policy_CP__c) && objAcc.Certificate_Policy_CP__c == objAcc.Parent.Certificate_Policy_CP__c)) &&
                    (string.isblank(objAcc.Certification_Practice_Statement_CPS__c) || (string.isnotblank(objAcc.Certification_Practice_Statement_CPS__c) && 
                    objAcc.Certification_Practice_Statement_CPS__c == objAcc.Parent.Certification_Practice_Statement_CPS__c))){
                    strCPCPSSameAsParent = 'Policies and Practices Information fields are same as parent. Please clear the fields and check "CP/CPS Same as Parent".';
                }
                
                //check if cp/cps are populate and parent intermediate is also same as parent
                if((string.isnotblank(objAcc.Certificate_Policy_CP__c) || string.isnotblank(objAcc.Certification_Practice_Statement_CPS__c)) 
                    && !objAcc.CP_CPS_Same_as_Parent__c && objAcc.Parent.CP_CPS_Same_as_Parent__c){
                    boolean isFound = false;
                    Id accParentId = objAcc.ParentId;
                    while(!isFound){
                        Account objParentAccount = GetParentAccount(accParentId, mapofAllAccounts);
                        if(objParentAccount != null && (objParentAccount.RecordType.Name == 'Root Certificate' || !objParentAccount.CP_CPS_Same_as_Parent__c)) {
                            isFound = true;
                            if((string.isblank(objAcc.Certificate_Policy_CP__c) || 
                                (string.isnotblank(objAcc.Certificate_Policy_CP__c) && objAcc.Certificate_Policy_CP__c == objParentAccount.Certificate_Policy_CP__c)) &&
                                (string.isblank(objAcc.Certification_Practice_Statement_CPS__c) || (string.isnotblank(objAcc.Certification_Practice_Statement_CPS__c) && 
                                objAcc.Certification_Practice_Statement_CPS__c == objParentAccount.Certification_Practice_Statement_CPS__c))){
                                strCPCPSSameAsParent = 'Policies and Practices Information fields are same as parent. Please clear the fields and check "CP/CPS Same as Parent".';
                            }  
                        } else if(objParentAccount == null) {
                            isFound = true;
                        }
                        if(objParentAccount != null) accParentId = objParentAccount.ParentId;
                    }
                }
                
                //if audits are blank then check Audit Same as Parent
                if(string.isblank(objAcc.Standard_Audit__c) && string.isblank(objAcc.Code_Signing_Audit__c) && string.isblank(objAcc.BR_Audit__c) &&
                    string.isblank(objAcc.EV_Audit__c) && !objAcc.Audits_Same_as_Parent__c){
                    strAuditSameAsParent = 'Please fill in Audit Information section or mark the checkbox "Audits Same as Parent"';    
                }
                //check if audits are same as parent and parent intermediate is not same as parent
                if((string.isnotblank(objAcc.Standard_Audit__c) || string.isnotblank(objAcc.Code_Signing_Audit__c) || 
                    string.isnotblank(objAcc.BR_Audit__c) || string.isnotblank(objAcc.EV_Audit__c)) && !objAcc.Audits_Same_as_Parent__c &&
                    !objAcc.Parent.Audits_Same_as_Parent__c && 
                    (string.isblank(objAcc.Standard_Audit__c) || (string.isnotblank(objAcc.Standard_Audit__c) && objAcc.Standard_Audit__c == objAcc.Parent.Standard_Audit__c)) &&
                    (string.isblank(objAcc.Code_Signing_Audit__c) || (string.isnotblank(objAcc.Code_Signing_Audit__c) && objAcc.Code_Signing_Audit__c == objAcc.Parent.Code_Signing_Audit__c)) &&
                    (string.isblank(objAcc.BR_Audit__c) || (string.isnotblank(objAcc.BR_Audit__c) && objAcc.BR_Audit__c == objAcc.Parent.BR_Audit__c)) &&
                    (string.isblank(objAcc.EV_Audit__c) || (string.isnotblank(objAcc.EV_Audit__c) && objAcc.EV_Audit__c == objAcc.Parent.EV_Audit__c))){
                    strAuditSameAsParent = 'All provided Audits are same as parent. Please clear the Audit fields and check "Audits Same as Parent".';
                }
                
                //check if audits are populated and parent intermediate is also same as parent
                if((string.isnotblank(objAcc.Standard_Audit__c) || string.isnotblank(objAcc.Code_Signing_Audit__c) || string.isnotblank(objAcc.BR_Audit__c) || 
                    string.isnotblank(objAcc.EV_Audit__c)) && !objAcc.Audits_Same_as_Parent__c && objAcc.Parent.Audits_Same_as_Parent__c){
                    boolean isFound = false;
                    Id accParentId = objAcc.ParentId;
                    while(!isFound){
                        Account objParentAccount = GetParentAccount(accParentId, mapofAllAccounts);
                        if(objParentAccount != null && (objParentAccount.RecordType.Name == 'Root Certificate' || !objParentAccount.Audits_Same_as_Parent__c)) {
                            isFound = true;
                            if((string.isblank(objAcc.Standard_Audit__c) || (string.isnotblank(objAcc.Standard_Audit__c) && objAcc.Standard_Audit__c == objParentAccount.Standard_Audit__c)) &&
                                (string.isblank(objAcc.Code_Signing_Audit__c) || (string.isnotblank(objAcc.Code_Signing_Audit__c) && objAcc.Code_Signing_Audit__c == objParentAccount.Code_Signing_Audit__c)) &&
                                (string.isblank(objAcc.BR_Audit__c) || (string.isnotblank(objAcc.BR_Audit__c) && objAcc.BR_Audit__c == objParentAccount.BR_Audit__c)) &&
                                (string.isblank(objAcc.EV_Audit__c) || (string.isnotblank(objAcc.EV_Audit__c) && objAcc.EV_Audit__c == objParentAccount.EV_Audit__c))){
                                strAuditSameAsParent = 'All provided Audits are same as parent. Please clear the Audit fields and check "Audits Same as Parent".';
                            }
                        } else if(objParentAccount == null) {
                            isFound = true;
                        }
                        if(objParentAccount != null) accParentId = objParentAccount.ParentId;
                    }
                }
                if(string.isnotblank(strAuditSameAsParent) || string.isnotblank(strCPCPSSameAsParent)){
                    wrapIntermediateCerts objwrap = new wrapIntermediateCerts();
                    objwrap.objIC = objAcc;
                    objwrap.strAuditSameAsParent = strAuditSameAsParent;
                    objwrap.strCPCPSSameAsParent = strCPCPSSameAsParent;
                    lstWrapIntermediateCerts.add(objwrap);
                }
            }
        }
    }
    
    public Account GetParentAccount(string accId, map<Id,Account> mapOfAllAccs){
        /*List<Account> lstAcc = new List<Account>([select Id, ParentId, RecordType.Name,
                        Certificate_Policy_CP__c, Certification_Practice_Statement_CPS__c,
                        Parent.Certificate_Policy_CP__c, Parent.Certification_Practice_Statement_CPS__c,
                        Standard_Audit__c, Parent.Standard_Audit__c, Code_Signing_Audit__c, Parent.Code_Signing_Audit__c,
                        BR_Audit__c, Parent.BR_Audit__c, EV_Audit__c, Parent.EV_Audit__c, 
                        Audits_Same_as_Parent__c, Parent.Audits_Same_as_Parent__c,
                        CP_CPS_Same_as_Parent__c, Parent.CP_CPS_Same_as_Parent__c
                        from Account Where Id =: accId]);*/
        if(mapOfAllAccs.size() > 0 && mapOfAllAccs.containskey(accId)){
            return mapOfAllAccs.get(accId);
        }
        return null;
    }
    
    String CurrentDate = ' ';
    // Get current Datetime in long date format   
    public String getCurrentDate() {
        Datetime cDT = System.now();
        CurrentDate = cDT.format('MMMM d, yyyy');
        return CurrentDate;
    }
    
    public class wrapIntermediateCerts {
        public Account objIC {get; set;}
        public string strAuditSameAsParent {get; set;}
        public string strCPCPSSameAsParent {get; set;}
        public wrapIntermediateCerts(){
            objIC = new Account();
            strAuditSameAsParent = '';
            strCPCPSSameAsParent = '';
        }
    }
}
/*
    Description: This class is basically used to save One time Apex script and we can run it whenever we want.
*/
public with sharing class OneTimeUseScripts {
    
    public OneTimeUseScripts(){}
    
    /*
        Below script will update Document Repositary and Document Repository Description field on CA Owner from 
        reading CA Document Repository and Policy Documentation from all Root Certificates
    */
    
    /*
        List<Account> lstAccountsToUpdate = new List<Account>();
        For(Account acc: [Select Id, Document_Repository__c, Document_Repository_Description__c,
                          (Select Id, CA_Document_Repository__c, Policy_Documentation__c from ChildAccounts
                          Where RecordType.Name = 'Root Certificate') FROM Account Where 
                          RecordType.Name = 'CA Owner']){
            set<string> setOfDocRep = new set<string>();
            set<string> setOfPD = new set<string>();
            for(Account childacc: acc.ChildAccounts){
                if(childacc.CA_Document_Repository__c != null){
                    setOfDocRep.add(childacc.CA_Document_Repository__c);
                }
                if(childacc.Policy_Documentation__c != null){
                    setOfPD.add(childacc.Policy_Documentation__c);
                }
            }
            string strDocRep = '';
            if(setOfDocRep.size() > 0){
                List<string> lstDocRep = new List<string>(setOfDocRep);
                strDocRep = string.join(lstDocRep, '; ');
            }
            string strPD = '';
            if(setOfPD.size() > 0){
                List<string> lstPD = new List<string>(setOfPD);
                strPD = string.join(lstPD, '; ');
            }
            Account objNewAcc = new Account(Id = acc.Id);
            if(string.isnotblank(strDocRep) || string.isnotblank(strPD)){
                if(string.isnotblank(strDocRep)){
                    objNewAcc.Document_Repository__c = strDocRep;
                }
                if(string.isnotblank(strPD)){
                    objNewAcc.Document_Repository_Description__c = strPD;
                }
                lstAccountsToUpdate.add(objNewAcc);
            }
        }
        if(lstAccountsToUpdate.size() > 0){
            update lstAccountsToUpdate;
        }
    */
    
    /*
        Create a Policy Documents and its association records for Root Certificates.
    */
    /*public static void CreatePolicyDocumentCertificates(){
        map<string, Policy_Document_On_Certificate__c> mapPDLinkWise = new map<string, Policy_Document_On_Certificate__c>();
        map<string, set<Id>> mpaPDAssociationLinkWise = new map<string, set<Id>>();
        map<string, set<string>> mpaPDTrustBitsLinkWise = new map<string, set<string>>();
        map<string, set<string>> mpaPDPolicyIdentifiersLinkWise = new map<string, set<string>>();
        map<Id, set<string>> mapRootWisePolicyIdentifiers = new map<Id, set<string>>();
        for(Account interacc: [SELECT ID, Root_Cert_Id__c, Policy_Identifiers__c from Account Where RecordType.Name = 'Intermediate Certificate' 
                    AND Root_Cert_Id__c != null]){
            if(interacc.Policy_Identifiers__c != null) {
                set<string> setofPI = new set<string>();
                if(mapRootWisePolicyIdentifiers.containskey(interacc.Root_Cert_Id__c)){
                    setofPI = mapRootWisePolicyIdentifiers.get(interacc.Root_Cert_Id__c);
                }
                List<string> lstPIs = interacc.Policy_Identifiers__c.split(';');
                for(string PI: lstPIs){
                    if(string.isnotblank(PI)){
                        setofPI.add(PI.trim());
                    }
                }
                mapRootWisePolicyIdentifiers.put(interacc.Root_Cert_Id__c, setofPI);
            }
        }
        for(Account acc: [SELECT Id,Name, CA_Document_Repository__c, Policy_Documentation__c, Trust_Bits__c, Microsoft_Trust_Bits__c,
                          Certificate_Policy_CP__c, Certification_Practice_Statement_CPS__c, CP_CPS_Last_Updated_Date__c
                          FROM ACCOUNT WHERE RecordType.Name = 'Root Certificate'
                          ]){//AND CP_CPS_Last_Updated_Date__c != null
            set<string> setofTrustBits = new set<string>();
            if((acc.Trust_Bits__c != null && acc.Trust_Bits__c.contains('Websites')) || 
                (acc.Microsoft_Trust_Bits__c != null && acc.Microsoft_Trust_Bits__c.contains('Server Authentication'))){
                setofTrustBits.add('Server Authentication');
            }
            if((acc.Trust_Bits__c != null && acc.Trust_Bits__c.contains('Email')) || 
                (acc.Microsoft_Trust_Bits__c != null && acc.Microsoft_Trust_Bits__c.contains('Secure Email'))){
                setofTrustBits.add('Secure Email');
            }
            if(acc.Microsoft_Trust_Bits__c != null && acc.Microsoft_Trust_Bits__c.contains('Code Signing')){
                setofTrustBits.add('Code Signing');
            }
            set<string> setofPIs = new set<string>();
            if(mapRootWisePolicyIdentifiers.containskey(acc.Id) && mapRootWisePolicyIdentifiers.get(acc.Id).size() > 0){
                setofPIs = mapRootWisePolicyIdentifiers.get(acc.Id);
            } 
            
            //CP
            if(acc.Certificate_Policy_CP__c != null){
                Policy_Document_On_Certificate__c PDC = new Policy_Document_On_Certificate__c();
                Set<Id> setOfRootCertIds = new set<Id>();
                if(mapPDLinkWise.containskey(acc.Certificate_Policy_CP__c.tolowercase())){
                    PDC = mapPDLinkWise.get(acc.Certificate_Policy_CP__c.tolowercase());
                    if(PDC.Document_Type__c != null){
                        if(PDC.Document_Type__c.contains('CPS'))
                            PDC.Document_Type__c = 'CP/CPS';
                        else 
                            PDC.Document_Type__c = 'CP';
                    }
                } else {
                    if(acc.Certificate_Policy_CP__c == acc.Certification_Practice_Statement_CPS__c){
                        PDC.Document_Type__c = 'CP/CPS';
                    } else {
                        PDC.Document_Type__c = 'CP';
                    }
                    PDC.Document_Link__c = acc.Certificate_Policy_CP__c;
                    PDC.Document_Last_Updated_Date__c = acc.CP_CPS_Last_Updated_Date__c;
                }
                mapPDLinkWise.put(acc.Certificate_Policy_CP__c.tolowercase(), PDC);
                
                if(mpaPDAssociationLinkWise.containskey(acc.Certificate_Policy_CP__c.tolowercase())){
                    setOfRootCertIds = mpaPDAssociationLinkWise.get(acc.Certificate_Policy_CP__c.tolowercase());
                }
                setOfRootCertIds.add(acc.Id);
                mpaPDAssociationLinkWise.put(acc.Certificate_Policy_CP__c.tolowercase(), setOfRootCertIds);
                if(mpaPDTrustBitsLinkWise.containskey(acc.Certificate_Policy_CP__c.tolowercase())){
                    mpaPDTrustBitsLinkWise.get(acc.Certificate_Policy_CP__c.tolowercase()).addall(setofTrustBits);
                } else {
                    mpaPDTrustBitsLinkWise.put(acc.Certificate_Policy_CP__c.tolowercase(), setofTrustBits);
                }
                if(mpaPDPolicyIdentifiersLinkWise.containskey(acc.Certificate_Policy_CP__c.tolowercase())){
                    mpaPDPolicyIdentifiersLinkWise.get(acc.Certificate_Policy_CP__c.tolowercase()).addall(setofPIs);
                } else {
                    mpaPDPolicyIdentifiersLinkWise.put(acc.Certificate_Policy_CP__c.tolowercase(), setofPIs);
                }
            } 
            //CPS
            if(acc.Certification_Practice_Statement_CPS__c != null && acc.Certificate_Policy_CP__c != acc.Certification_Practice_Statement_CPS__c){
                Policy_Document_On_Certificate__c PDC = new Policy_Document_On_Certificate__c();
                Set<Id> setOfRootCertIds = new set<Id>();
                if(mapPDLinkWise.containskey(acc.Certification_Practice_Statement_CPS__c.tolowercase())){
                    PDC = mapPDLinkWise.get(acc.Certification_Practice_Statement_CPS__c.tolowercase());
                    if(PDC.Document_Type__c != null){
                        if(!PDC.Document_Type__c.contains('CPS'))
                            PDC.Document_Type__c = 'CP/CPS';
                        else 
                            PDC.Document_Type__c = 'CPS';
                    }
                } else {
                    PDC.Document_Type__c = 'CPS';
                    PDC.Document_Link__c = acc.Certification_Practice_Statement_CPS__c;
                    PDC.Document_Last_Updated_Date__c = acc.CP_CPS_Last_Updated_Date__c;
                }
                mapPDLinkWise.put(acc.Certification_Practice_Statement_CPS__c.tolowercase(), PDC);
                
                if(mpaPDAssociationLinkWise.containskey(acc.Certification_Practice_Statement_CPS__c.tolowercase())){
                    setOfRootCertIds = mpaPDAssociationLinkWise.get(acc.Certification_Practice_Statement_CPS__c.tolowercase());
                }
                setOfRootCertIds.add(acc.Id);
                mpaPDAssociationLinkWise.put(acc.Certification_Practice_Statement_CPS__c.tolowercase(), setOfRootCertIds);
                if(mpaPDTrustBitsLinkWise.containskey(acc.Certification_Practice_Statement_CPS__c.tolowercase())){
                    mpaPDTrustBitsLinkWise.get(acc.Certification_Practice_Statement_CPS__c.tolowercase()).addall(setofTrustBits);
                } else {
                    mpaPDTrustBitsLinkWise.put(acc.Certification_Practice_Statement_CPS__c.tolowercase(), setofTrustBits);
                }
                if(mpaPDPolicyIdentifiersLinkWise.containskey(acc.Certification_Practice_Statement_CPS__c.tolowercase())){
                    mpaPDPolicyIdentifiersLinkWise.get(acc.Certification_Practice_Statement_CPS__c.tolowercase()).addall(setofPIs);
                } else {
                    mpaPDPolicyIdentifiersLinkWise.put(acc.Certification_Practice_Statement_CPS__c.tolowercase(), setofPIs);
                }
            } 
        }
        if(mapPDLinkWise.size() > 0){
            for(string dlink: mapPDLinkWise.keyset()){
                if(mpaPDTrustBitsLinkWise.containskey(dlink)){
                    List<string> lstAT = new List<string>(mpaPDTrustBitsLinkWise.get(dlink));
                    lstAT.sort();
                    string AssociatedTrustBits = string.join(lstAT,'; ');
                    mapPDLinkWise.get(dlink).Associated_Trust_Bits__c = AssociatedTrustBits;
                }
                if(mpaPDPolicyIdentifiersLinkWise.containskey(dlink)){
                    List<string> lstPIs = new List<string>(mpaPDPolicyIdentifiersLinkWise.get(dlink));
                    lstPIs.sort();
                    //temp added
                    string PI = string.join(lstPIs ,'; ');
                    mapPDLinkWise.get(dlink).Policy_Identifiers__c = PI;
                }
            }  
            insert mapPDLinkWise.values();
        }
        if(mpaPDAssociationLinkWise.size() > 0){
            List<PolicyDocumentAssociation_On_Certificate__c> lstAssociationToInsert = new List<PolicyDocumentAssociation_On_Certificate__c>();
            for(string link: mpaPDAssociationLinkWise.keyset()){
                if(mapPDLinkWise.containskey(link) && mapPDLinkWise.get(link).Id != null){
                    for(Id assid: mpaPDAssociationLinkWise.get(link)){
                        PolicyDocumentAssociation_On_Certificate__c PDAC = new PolicyDocumentAssociation_On_Certificate__c();
                        PDAC.Policy_Document__c = mapPDLinkWise.get(link).Id;
                        PDAC.Certificate_Name__c = assId;
                        lstAssociationToInsert.add(PDAC);
                    }
                }
            }
            if(lstAssociationToInsert.size() > 0){
                insert lstAssociationToInsert;
            }
        }
    }*/
    
    /*
        Create a Policy Documents and its association records for cases.
    */
    /*public static void CreatePolicyDocumentForCases(){
        map<string, Policy_Document_On_Case__c> mapPDCaseLinkWise = new map<string, Policy_Document_On_Case__c>();
        map<string, set<Id>> mpaPDAssociationCaseLinkWise = new map<string, set<Id>>();
        map<Id, set<string>> mapRootWisePolicyIdentifiers = new map<Id, set<string>>();
        map<Id, set<string>> mapRootWiseAssociatedTrustBits = new map<Id, set<string>>();
        for(Account interacc: [SELECT ID, Root_Cert_Id__c, Policy_Identifiers__c from Account Where RecordType.Name = 'Intermediate Certificate' 
                    AND Root_Cert_Id__c != null]){
            if(interacc.Policy_Identifiers__c != null) {
                set<string> setofPI = new set<string>();
                if(mapRootWisePolicyIdentifiers.containskey(interacc.Root_Cert_Id__c)){
                    setofPI = mapRootWisePolicyIdentifiers.get(interacc.Root_Cert_Id__c);
                }
                List<string> lstPIs = interacc.Policy_Identifiers__c.split(';');
                for(string PI: lstPIs){
                    if(string.isnotblank(PI)){
                        setofPI.add(PI.trim());
                    }
                }
                mapRootWisePolicyIdentifiers.put(interacc.Root_Cert_Id__c, setofPI);
            }
        }
        for(Account acc: [SELECT Id,Name, Trust_Bits__c, Microsoft_Trust_Bits__c
                          FROM ACCOUNT WHERE RecordType.Name = 'Root Certificate']){
            set<string> setofTrustBits = new set<string>();
            if((acc.Trust_Bits__c != null && acc.Trust_Bits__c.contains('Websites')) || 
                (acc.Microsoft_Trust_Bits__c != null && acc.Microsoft_Trust_Bits__c.contains('Server Authentication'))){
                setofTrustBits.add('Server Authentication');
            }
            if((acc.Trust_Bits__c != null && acc.Trust_Bits__c.contains('Email')) || 
                (acc.Microsoft_Trust_Bits__c != null && acc.Microsoft_Trust_Bits__c.contains('Secure Email'))){
                setofTrustBits.add('Secure Email');
            }
            if(acc.Microsoft_Trust_Bits__c != null && acc.Microsoft_Trust_Bits__c.contains('Code Signing')){
                setofTrustBits.add('Code Signing');
            }
            mapRootWiseAssociatedTrustBits.put(acc.Id, setofTrustBits);
        }
        //loop on all cases
        for(Case cs: [SELECT Id,CaseNumber, Certificate_Policy_Link__c, Certification_Practice_Statement_Link__c, CP_CPS_Last_Updated_Date__c,
                        CP_CPS_Links_Verified__c, (Select Id, Root_Certificate_Name_Existing__c from Root_Cases__r)
                          FROM Case]){
            set<string> setofPIs = new set<string>();
            Set<Id> setOfRootCertIds = new set<Id>();
            set<string> setofAssTrustBits = new set<string>();
            for(Root_Case__c RC: cs.Root_Cases__r){
                setOfRootCertIds.add(RC.Root_Certificate_Name_Existing__c);
                if(mapRootWiseAssociatedTrustBits.containskey(RC.Root_Certificate_Name_Existing__c)){
                    setofAssTrustBits.addall(mapRootWiseAssociatedTrustBits.get(RC.Root_Certificate_Name_Existing__c));
                }
                if(mapRootWisePolicyIdentifiers.containskey(RC.Root_Certificate_Name_Existing__c)){
                    setofPIs.addall(mapRootWisePolicyIdentifiers.get(RC.Root_Certificate_Name_Existing__c));
                }
            }
            //CP
            if(cs.Certificate_Policy_Link__c != null){
                Policy_Document_On_Case__c PDC = new Policy_Document_On_Case__c(Case__c = cs.Id, Action__c = 'Create');
                if(cs.Certificate_Policy_Link__c == cs.Certification_Practice_Statement_Link__c){
                    PDC.Document_Type__c = 'CP/CPS';
                } else {
                    PDC.Document_Type__c = 'CP';
                }
                PDC.Document_Link__c = cs.Certificate_Policy_Link__c;
                PDC.Document_Last_Updated_Date__c = cs.CP_CPS_Last_Updated_Date__c;
                if(setofPIs.size() > 0){
                    PDC.Policy_Identifiers__c = string.join(new List<string>(setofPIs), '; ');
                }
                if(setofAssTrustBits.size() > 0){
                    PDC.Associated_Trust_Bits__c = string.join(new List<string>(setofAssTrustBits), '; ');
                }
                string key = cs.Id + '#' +cs.Certificate_Policy_Link__c.tolowercase();
                if(cs.CP_CPS_Links_Verified__c == 'Data Verified'){
                    PDC.Document_Verified__c = 'Data Verified';
                }
                mapPDCaseLinkWise.put(key, PDC);
                mpaPDAssociationCaseLinkWise.put(key, setOfRootCertIds);
            } 
            //CPS
            if(cs.Certification_Practice_Statement_Link__c != null && cs.Certificate_Policy_Link__c != cs.Certification_Practice_Statement_Link__c){
                Policy_Document_On_Case__c PDC = new Policy_Document_On_Case__c(Case__c = cs.Id, Action__c = 'Create');
                PDC.Document_Type__c = 'CPS';
                PDC.Document_Link__c = cs.Certification_Practice_Statement_Link__c;
                PDC.Document_Last_Updated_Date__c = cs.CP_CPS_Last_Updated_Date__c;
                if(setofPIs.size() > 0){
                    PDC.Policy_Identifiers__c = string.join(new List<string>(setofPIs), '; ');
                }
                if(setofAssTrustBits.size() > 0){
                    PDC.Associated_Trust_Bits__c = string.join(new List<string>(setofAssTrustBits), '; ');
                }
                string key = cs.Id + '#' +cs.Certification_Practice_Statement_Link__c.tolowercase();
                if(cs.CP_CPS_Links_Verified__c == 'Data Verified'){
                    PDC.Document_Verified__c = 'Data Verified';
                }
                mapPDCaseLinkWise.put(key, PDC);
                mpaPDAssociationCaseLinkWise.put(key, setOfRootCertIds);    
            }
        }
        
        //create policy documents for cases
        if(mapPDCaseLinkWise.size() > 0){
            insert mapPDCaseLinkWise.values();
        }
        if(mpaPDAssociationCaseLinkWise.size() > 0){
            List<Policy_Document_Association_On_Case__c> lstPDAssCase = new List<Policy_Document_Association_On_Case__c>();
            for(string key: mpaPDAssociationCaseLinkWise.keyset()){
                Id caseId = key.split('#')[0];
                for(Id rcid: mpaPDAssociationCaseLinkWise.get(key)){
                    Policy_Document_Association_On_Case__c PDAC = new Policy_Document_Association_On_Case__c(Action__c = 'Create');
                    PDAC.Case__c = caseId;
                    PDAC.Certificate_Name__c = rcId;
                    if(mapPDCaseLinkWise.containskey(key)){
                        PDAC.Policy_Document__c = mapPDCaseLinkWise.get(key).Id;
                    }
                    lstPDAssCase.add(PDAC);
                }
            }
            if(lstPDAssCase.size() > 0){
                insert lstPDAssCase;
            }
        }
    }*/
    
    /*
        TO Update Derived Trust bits for all users
        
        IT WILL NOW ALLOW YOU TO UPDATE ALL INTERMEDIATE CERTS TO YOU HAVE TO UPDATE IN DIFFERENT CHUNKS VIA USING LASTMODIFIEDDATE.
        
        
        map<string, List<Account>> mapAllRootsWithSameSPKI = new map<string, List<Account>>();
        map<Id,Account> mapAllAccounts = new map<Id, Account>();
        Date todaydt = system.today();
        List<Account> lstRootAccs = new List<Account>([Select Id, ParentId, RecordType.Name, Derived_Trust_Bits__c,
                                                       Trust_Bits__c,Microsoft_Trust_Bits__c,Status__c,Microsoft_Status__c,Subject_SPKI_SHA256__c 
                                                       from Account Where Subject_SPKI_SHA256__c != null
                                                      AND Valid_To_GMT__c >=: todaydt]);
        for(Account objRoot: lstRootAccs){
            if(mapAllRootsWithSameSPKI.containskey(objRoot.Subject_SPKI_SHA256__c)){
                mapAllRootsWithSameSPKI.get(objRoot.Subject_SPKI_SHA256__c).add(objRoot);
            } else {
                mapAllRootsWithSameSPKI.put(objRoot.Subject_SPKI_SHA256__c, new List<Account>{objRoot});
            }
        }
        mapAllAccounts = new map<Id, Account>([select Id, ParentId, RecordType.Name, Derived_Trust_Bits__c,
                                Trust_Bits__c, Microsoft_Trust_Bits__c, Status__c, Microsoft_Status__c, Subject_SPKI_SHA256__c
                                from Account Where RecordType.Name != 'CA Owner']);
        List<Account> lstAccounts = new List<Account>([Select Id, Name, ParentId,RecordType.Name,
                                                       Extended_Key_Usage__c , Status__c, Microsoft_Status__c,
                                                       Trust_Bits__c, Microsoft_Trust_Bits__c, Subject_SPKI_SHA256__c 
                                                       from Account Where RecordType.Name = 'Intermediate Certificate' 
                                                       AND Parent.RecordType.Name = 'Intermediate Certificate']);
        for(Account objAcc: lstAccounts) {
            objAcc.Derived_Trust_Bits__c = '';
            string strDerivedTrustBits = AccountTriggerHelper.getDerivedTrustBits(objAcc, mapAllAccounts, mapAllRootsWithSameSPKI);
            if(strDerivedTrustBits != null && string.isnotblank(strDerivedTrustBits)){
                objAcc.Derived_Trust_Bits__c = strDerivedTrustBits;
            }
        }
        AccountTriggerHelper.isRecursiveUpdate = true;
        update lstAccounts;
    */
    
    /*
        To Populate Policy Identifer from PEM Extraction results.
        We have more than 5000+ Root and Intermediate Certs, we can't update all certs in One update so we have to set Limit.
        we can only update 1000 in single time, in code there is condition if Policy Identifier is blank and Extraction results is populated.
    */
    /*List<Account> lstAccounts = new List<Account>([SELECT Id,Extraction_Results__c,Policy_Identifiers__c 
                                               FROM Account 
                                               WHERE
                                               RecordType.Name in ('Intermediate Certificate','Root Certificate')
                                               Order by LastModifiedDate Limit 1000 
                                              ]);
    List<Account> lstAccToUpdate = new List<Account>();
    for(Account acc: lstAccounts){
        if(acc.Extraction_Results__c != null && string.isblank(acc.Policy_Identifiers__c)){
            try {
                PEMParserClass pemclass = PEMParserClass.parse(acc.Extraction_Results__c);
                //policy indentifier
                if(pemclass != null && pemclass.x509v3Extensions.policyIdentifiers != null && pemclass.x509v3Extensions.policyIdentifiers.size() > 0){
                    Account objAcc = new Account(Id = acc.Id);
                    objAcc.Policy_Identifiers__c = string.join(pemclass.x509v3Extensions.policyIdentifiers,'; ');
                    lstAccToUpdate.add(objAcc);
                }
            } Catch (Exception ex){
                system.debug(acc.Id);
            }
        }
    }
    if(lstAccToUpdate.size() > 0){
        database.update(lstAccToUpdate);
    }*/
    
    
    /*
        To Populate Policy Identifier on CA Owner from all root and intermedaite certs
    */
    /*
        set<Id> setofCAOwnerId = new set<Id>();
        List<Account> lstAllCAOwner = new List<Account>([select Id,Name from Account Where RecordType.Name = 'CA Owner']);
        for(Account objAcc: lstAllCAOwner){
            setofCAOwnerId.add(objAcc.Id);
        }
       
        if(setofCAOwnerId.size() > 0) {
            map<Id, set<string>> mapCAOwnerwisePolicyIdentifiers = new map<Id, set<string>>();
            List<Account> lstAllRootInterCerts = new List<Account>([select Id,Name,CA_Owner_ID__c,Policy_Identifiers__c 
                            from Account Where Valid_To_GMT__c > TODAY AND (RecordType.Name = 'Root Certificate' OR 
                            (RecordType.Name = 'Intermediate Certificate' AND Revocation_Status__c = 'Not Revoked')) 
                            AND CA_Owner_ID__c =: setofCAOwnerId]);
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
                    acc.Policy_Identifiers__c = '';
                    acc.Policy_Identifiers__c = string.join(lst, '; ');
                    lstAccToUpdate.add(acc);
                }
                if(lstAccToUpdate.size() > 0){
                    AccountTriggerHelper.isRecursiveUpdate = true;
                    update lstAccToUpdate;
                    AccountTriggerHelper.isRecursiveUpdate = false;
                }
            }
        }
    */
}
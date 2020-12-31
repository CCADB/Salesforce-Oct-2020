/*******************************************************************************************************
 Name: CrossSignedRemovedRootsController

 Dependencies: CrossSignedRemovedRootsController controller class, CrossSignedRemovedRootsControllerTest 
 test class, CrossSignedRemovedRootsReport vf page

 Description: This is a controller for a report to display 'Cross-Signed Removed Roots'. Report lists
 removed Root Certs followed by cross signed Intermediate Certs. Only the inter certs which are not 
 expired and their Revocation Status is not ‘Revoked’ or ‘Parent Cert Revoked’ are listed in the report.
 
 Instructions: None   
 *******************************************************************************************************
 Revision History:
 
     6/5/2018 - Created new class
 ******************************************************************************************************/
 
public with sharing class CrossSignedRemovedRootsController {

    //list that has audit integrity report - Inter certs
    public transient List<wrapRootAccounts> lstWrapCerts {get; set;}
    
    public CrossSignedRemovedRootsController(){
    
        lstWrapCerts = new List<wrapRootAccounts>();
        map<string, Account> mapofSubjectSPKIRoots = new map<string, Account>();
        
        //query and get all removed root certificate
        for(Account acc: [select Id, Name, RecordType.Name, ParentId, Parent.Name, Valid_From_GMT__c, Valid_To_GMT__c, Subject_SPKI_SHA256__c,
                SHA_1_Fingerprint__c from Account Where RecordType.Name = 'Root Certificate' AND Status__c = 'Removed']){
            mapofSubjectSPKIRoots.put(acc.Subject_SPKI_SHA256__c, acc);
        }
        
        //get all intermediates certs which has same Subject + SPKI
        if(mapofSubjectSPKIRoots.size() > 0) {
            List<Account> lstIntermediateCerts = new List<Account>([SELECT Id, Name, ParentId, Parent.Name, RecordType.Name,
                                                                           Valid_From_GMT__c, Valid_To_GMT__c, 
                                                                           SHA_1_Fingerprint__c, Subject_SPKI_SHA256__c FROM Account 
                                                                    WHERE RecordType.Name = 'Intermediate Certificate' 
                                                                    AND Subject_SPKI_SHA256__c in: mapofSubjectSPKIRoots.keyset()
                                                                    AND Valid_To_GMT__c > TODAY 
                                                                    AND Revocation_Status__c = 'Not Revoked'
                                                                    AND Root_Cert_Id__r.Status__c In ('Included', 'Change Requested')]);
            
            map<string, List<Account>> mapofIntermediateCerts = new map<string, List<Account>>();
            
            for(Account acc: lstIntermediateCerts){
                if(mapofIntermediateCerts.containskey(acc.Subject_SPKI_SHA256__c)){
                    mapofIntermediateCerts.get(acc.Subject_SPKI_SHA256__c).add(acc);
                } else {
                    mapofIntermediateCerts.put(acc.Subject_SPKI_SHA256__c, new List<Account>{acc});
                }
            }
            
            for(string subjectspki: mapofSubjectSPKIRoots.keyset()){
                if(mapofIntermediateCerts.containskey(subjectspki)){
                    wrapRootAccounts wra = new wrapRootAccounts();
                    wra.rootCertificate = mapofSubjectSPKIRoots.get(subjectspki);
                    wra.lstIntermediateCerts = mapofIntermediateCerts.get(subjectspki);
                    lstWrapCerts.add(wra);
                }
            }
        }
    }
    
    public class wrapRootAccounts {
        public Account rootCertificate {get; set;}
        public List<Account> lstIntermediateCerts {get; set;}
        public wrapRootAccounts(){
            rootCertificate = new Account();
            lstIntermediateCerts = new List<Account>();
        }
    }
}
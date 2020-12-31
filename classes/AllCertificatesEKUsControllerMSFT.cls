/*******************************************************************************************************
 Name: AllCertificatesEKUsControllerMSFT

 Dependencies: AllCertificatesEKUsMSFTCSV VF page, AllCertificatesEKUsControllerMSFTTest class

 Description: This report lists all root and inter certs included in Microsoft pgm. Each root cert row is 
 folloowed by it's intermediate. Root Cert record shows Microsoft EKUs and Intermediate cert record shows
 Extended Key Usage data from their respective records.
 
 Instructions:    
 *******************************************************************************************************
 Revision History:
 
       4/12/2019 - Created new
 ******************************************************************************************************/



public class AllCertificatesEKUsControllerMSFT {

    public transient List<Account> lstAllCertificates {get;set;}
 
    // constructor method for standard controller
    public AllCertificatesEKUsControllerMSFT() {   
        lstAllCertificates = new List<Account>();
                               
        //get root certificates                      
        map<Id, Account> mapRootCertificates =  new map<Id,Account>([SELECT Name, CA_Owner__c, Root_Cert_Id__c, Root_Cert_Id__r.Name,
                               Extended_Key_Usage__c, Microsoft_EKU__c, Microsoft_Status__c, Status__c, 
                               RecordType.Name from Account 
                               WHERE RecordType.Name = 'Root Certificate' AND Microsoft_Status__c in ('Included','Change Requested')
                               AND Name != '<Fill in Cert Name>'
                               ORDER BY CA_Owner__c,Name]); 
        
        //get intermediate certificates.
        map<Id, Account> mapIntermediateCertificates =  new map<Id,Account>([SELECT Name, CA_Owner__c, Root_Cert_Id__c, Root_Cert_Id__r.Name,
                               Extended_Key_Usage__c, Microsoft_EKU__c, Microsoft_Status__c, Status__c, 
                               RecordType.Name from Account 
                               WHERE RecordType.Name = 'Intermediate Certificate' AND Root_Cert_Id__c in: mapRootCertificates.keyset()
                               AND Name != '<Fill in Cert Name>'
                               ORDER BY CA_Owner__c,Name]);
        
        //fill map to key as root certificate id and value as list of intermediate certs
        map<string, List<Account>> mapIntermediateCertsbyRoot = new map<string, List<Account>>();
        
        
        for(Account intermediatecert: mapIntermediateCertificates.values()){
            if(intermediatecert.Name !=null && intermediatecert.Name.length() > 0) 
                intermediatecert.Name = intermediatecert.Name.replace('"',''); 
            if(intermediatecert.CA_Owner__c !=null && intermediatecert.CA_Owner__c.length() > 0) 
                intermediatecert.CA_Owner__c = intermediatecert.CA_Owner__c.replace('"','');          
            if(intermediatecert.Root_Cert_Id__c !=null && intermediatecert.Root_Cert_Id__r.Name.length() > 0) 
                intermediatecert.Root_Cert_Id__r.Name = intermediatecert.Root_Cert_Id__r.Name.replace('"',''); 
            if(intermediatecert.Microsoft_EKU__c !=null && intermediatecert.Microsoft_EKU__c.length() > 0) 
                intermediatecert.Microsoft_EKU__c = intermediatecert.Microsoft_EKU__c.replace('"','');
            if(intermediatecert.Extended_Key_Usage__c !=null && intermediatecert.Extended_Key_Usage__c.length() > 0) 
                intermediatecert.Extended_Key_Usage__c = intermediatecert.Extended_Key_Usage__c.replace('"','');
            if(mapIntermediateCertsbyRoot.containskey(intermediatecert.Root_Cert_Id__c)){
                mapIntermediateCertsbyRoot.get(intermediatecert.Root_Cert_Id__c).add(intermediatecert);
            } else {
                mapIntermediateCertsbyRoot.put(intermediatecert.Root_Cert_Id__c, new List<Account>{intermediatecert});
            }
        }
        //fill list by root certificates.
        for(Account rootAccount: mapRootCertificates.values()){
            if(rootAccount.Name !=null && rootAccount.Name.length() > 0) 
                rootAccount.Name = rootAccount.Name.replace('"',''); 
            if(rootAccount.CA_Owner__c !=null && rootAccount.CA_Owner__c.length() > 0) 
                rootAccount.CA_Owner__c = rootAccount.CA_Owner__c.replace('"','');          
            if(rootAccount.Root_Cert_Id__c !=null && rootAccount.Root_Cert_Id__r.Name.length() > 0) 
                rootAccount.Root_Cert_Id__r.Name = rootAccount.Root_Cert_Id__r.Name.replace('"',''); 
            if(rootAccount.Microsoft_EKU__c !=null && rootAccount.Microsoft_EKU__c.length() > 0) 
                rootAccount.Microsoft_EKU__c = rootAccount.Microsoft_EKU__c.replace('"','');
            if(rootAccount.Extended_Key_Usage__c !=null && rootAccount.Extended_Key_Usage__c.length() > 0) 
                rootAccount.Extended_Key_Usage__c = rootAccount.Extended_Key_Usage__c.replace('"','');
            lstAllCertificates.add(rootAccount);
            if(mapIntermediateCertsbyRoot.containskey(rootAccount.Id)){
                lstAllCertificates.addall(mapIntermediateCertsbyRoot.get(rootAccount.Id));
            }                                
        }
        system.debug('lstAllCertificates ::: '+lstAllCertificates.size());
    } 
}
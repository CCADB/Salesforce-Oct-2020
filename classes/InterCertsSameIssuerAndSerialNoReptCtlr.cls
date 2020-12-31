/*

Intermediate Certificates with same Issuer & Serial Number
the intermediate certs for which the following fields are the same:

Certificate Issuer Common Name
Certificate Issuer Organization
Certificate Issuer Organizational Unit
Certificate Serial Number

These certs should be deleted.

*/
public class InterCertsSameIssuerAndSerialNoReptCtlr {
 
    public transient Map<String, List<Account>> mapDuplicateAccounts{get; set;}
    
    public InterCertsSameIssuerAndSerialNoReptCtlr(){
        
        this.mapDuplicateAccounts = new Map<String, List<Account>>();
        
        Map<String, List<String>> mapDups = new Map<String, List<String>>();
        List<String> lstKey = new List<String>();
        
        String recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Intermediate Certificate').getRecordTypeId();

        for(Account acc : [SELECT CA_Owner__c, Name,
                            Certificate_Issuer_Common_Name__c,
                            Certificate_Issuer_Organization__c,
                            Certificate_Issuer_Organizational_Unit__c,
                            Certificate_Serial_Number__c,
                            SHA_256_Fingerprint__c 
                            FROM Account
                            WHERE RecordTypeId = :recordTypeId
                            ORDER BY CA_Owner__c, Name]){
            
            String key = acc.Certificate_Issuer_Common_Name__c + acc.Certificate_Issuer_Organization__c + 
                         acc.Certificate_Issuer_Organizational_Unit__c + acc.Certificate_Serial_Number__c;
            
            lstKey.add(key);
            if(mapDuplicateAccounts.containsKey(key)){
                List<Account> lstTemp = mapDuplicateAccounts.get(key);
                lstTemp.add(acc);
            }else{
                mapDuplicateAccounts.put(key, new List<Account>{acc});
            }                                
        }
        
        for(String key : lstKey){
            List<Account> lstTemp = mapDuplicateAccounts.get(key);
            if(lstTemp.size() < 2){
                mapDuplicateAccounts.remove(key);
            }
        }
        
        system.debug(JSON.serialize(mapDuplicateAccounts));
        
    }
    
    public String getCurrentDate() {
      
      return System.now().format('MMMM d, yyyy');
   }  
}
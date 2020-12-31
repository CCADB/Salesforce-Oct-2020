/**

 This is the helper class for the PublicIntermediateCertsBatch class. It finds the parent root cert for 
 a given intermediate cert and populates the record id of that root on the inter cert records.
 
 To run the batch job for all inter certs use Developer Console and execute the lines below:
 PublicAllIntermediateCertsBatch b1 = new PublicAllIntermediateCertsBatch();
 ID batchprocessid = Database.executeBatch(b1,1);   
 
 To run the program for one inter certs use Developer Console and execute the lines below (Id should be intermediate cert id):
 List<Account> lstAcc = [select Microsoft_CA_Owner_Status__c,Mozilla_CA_Owner_Status__c,Root_Cert_Id__c,Root_Cert_Id__r.Parentid,Root_Cert_Id__r.Parent.Status__c, Root_Cert_Id__r.Parent.Microsoft_Status__c,Mozilla_Root_Status__c,Microsoft_Root_Status__c,CA_Owner_ID__c, parentid From Account Where Id = '0015600000EEegq'];
 PublicAllIntermediateCertsBatchHelper.processInterCerts(lstAcc);
  

 04/10/2019 - Updated program to update Root and CA Owner status for Mozilla and Microsoft.

**/
public class PublicAllIntermediateCertsBatchHelper {


// this method processes each intermediate cert and populates the record id of that root on the inter cert record.
// if the intermediate cert record already has the root cert id populated then it is updated only if the new root cert id 
// is different than the root cert id on the record.

 public static Integer processInterCerts(List<Account> accountSolst) {

    Set<Id> ownerIdSet = New Set<ID>();
    
    Integer numOfRecords = 0;

    // iterate over each intermediate cert and create a set of owner ids
    for(Account accountSo: accountSoLst){
        if(accountSo.ca_owner_id__c !=null ) {
         ownerIdSet.add(accountSo.ca_owner_id__c);
        }
    }
 
    if(ownerIdSet.size() > 0) {
  
      
     // get all the owner account details using the owner set
    String queryStr = 'select  Microsoft_CA_Owner_Status__c,Mozilla_CA_Owner_Status__c,Mozilla_Root_Status__c,Microsoft_Root_Status__c,Root_Cert_Id__c, record_type_name__c, parentid, ca_owner_id__c,Status__c,Microsoft_Status__c From Account where Id in :ownerIdSet OR ca_owner_id__c in :ownerIdSet order by name  ';                    
    
    List<Account> allAccountSoLst = Database.query(queryStr);
    
    // also get all the account records whose parent is ownerid this would give us the root certs
    //String queryStr2 = 'select Root_Cert_Id__c ,record_type_name__c, parentid, ca_owner_id__c,Status__c,Microsoft_Status__c  From Account where ca_owner_id__c in :ownerIdSet order by name  ';                    
    
    //List<Account> allAccountSoLst2 = Database.query(queryStr2);
    
    // add them all to a common list
    //allAccountSoLst.addAll(allAccountSoLst2);
     
    // iterate over all these accounts and find the root record
    for(Account accountSo: accountSoLst) {
        // pass the intermediate cert and all the rest of the accounts fetched above
        numOfRecords  = numOfRecords  + findRoot(accountSo,null, allAccountSoLst);
     }
  }

 return numOfRecords ;

}

 // this method recursively finds out the root belonging to current intermediate cert
 private static Integer findRoot(Account origAccountSo, Account newAccountSo, List<Account> accountSoLst) {
 
     Boolean isUpdated = false;
     
     List<Account> toBeUpdatedInterCertsLst = New List<Account>();
     Map<Id,Account> toBeUpdatedMap = New Map<Id,Account>();
     
     for(Account childAccountSo : accountSoLst){

     
     if(newAccountSo==null) {
        if(origAccountSo.parentid == childAccountSo.id  ) {
        if(childAccountSo.record_type_name__c !='Root Certificate') {
           findRoot(origAccountSo, childAccountSo, accountSoLst);
            }
            else
            {
             // isUpdated = true; origAccountSo.Root_Cert_Id__c = childAccountSo.id;       toBeUpdatedMap.put(origAccountSo.id, origAccountSo); break;
             isUpdated = true; if (origAccountSo.Root_Cert_Id__c <> childAccountSo.id || origAccountSo.Mozilla_Root_Status__c != childAccountSo.Status__c ||
                                    origAccountSo.Microsoft_Root_Status__c != childAccountSo.Microsoft_Status__c ||
                                    origAccountSo.Mozilla_CA_Owner_Status__c != origAccountSo.Root_Cert_Id__r.Parent.Status__c ||
                                    origAccountSo.Microsoft_CA_Owner_Status__c != origAccountSo.Root_Cert_Id__r.Parent.Microsoft_Status__c) {
                                   origAccountSo.Root_Cert_Id__c = childAccountSo.id; 
                                   origAccountSo.Mozilla_Root_Status__c =   childAccountSo.Status__c;
                                   origAccountSo.Microsoft_Root_Status__c =   childAccountSo.Microsoft_Status__c;
                                   origAccountSo.Mozilla_CA_Owner_Status__c = origAccountSo.Root_Cert_Id__r.Parent.Status__c;
                                   origAccountSo.Microsoft_CA_Owner_Status__c = origAccountSo.Root_Cert_Id__r.Parent.Microsoft_Status__c;
                                   toBeUpdatedMap.put(origAccountSo.id, origAccountSo); break;
                               }
            }
        }
       
    }
    else {
    
    if(newAccountSo.parentid == childAccountSo.id ) {
        if(childAccountSo.record_type_name__c !='Root Certificate'){
     
             findRoot(origAccountSo, childAccountSo, accountSoLst);
        }
        else{
    
              // isUpdated = true; origAccountSo.Root_Cert_Id__c = childAccountSo.id;       toBeUpdatedMap.put(origAccountSo.id, origAccountSo); break;              
              isUpdated = true; if (origAccountSo.Root_Cert_Id__c <> childAccountSo.id || origAccountSo.Mozilla_Root_Status__c != childAccountSo.Status__c ||
                                    origAccountSo.Microsoft_Root_Status__c != childAccountSo.Microsoft_Status__c ||
                                    origAccountSo.Mozilla_CA_Owner_Status__c != origAccountSo.Root_Cert_Id__r.Parent.Status__c ||
                                    origAccountSo.Microsoft_CA_Owner_Status__c != origAccountSo.Root_Cert_Id__r.Parent.Microsoft_Status__c) {
                                    origAccountSo.Root_Cert_Id__c = childAccountSo.id;  
                                    origAccountSo.Mozilla_Root_Status__c =   childAccountSo.Status__c;
                                    origAccountSo.Microsoft_Root_Status__c =   childAccountSo.Microsoft_Status__c;
                                    origAccountSo.Mozilla_CA_Owner_Status__c = origAccountSo.Root_Cert_Id__r.Parent.Status__c;
                                    origAccountSo.Microsoft_CA_Owner_Status__c = origAccountSo.Root_Cert_Id__r.Parent.Microsoft_Status__c;
                                    toBeUpdatedMap.put(origAccountSo.id, origAccountSo); break;
                                }
        }
    }
    
         
   }
         
               
     }
    
    
    if(toBeUpdatedMap.size() > 0)
    {
    toBeUpdatedInterCertsLst = toBeUpdatedMap.values();
   
      update toBeUpdatedInterCertsLst;
    }
    
    return toBeUpdatedInterCertsLst.size();
 
 }
 
}
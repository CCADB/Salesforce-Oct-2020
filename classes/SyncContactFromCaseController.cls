/**

This is the controller class for the SyncContactFromCase VF page.
Here the user has two options: 
1. Either to update the displayed fields from the custom contact fields on the case object to the contact that is associated with the case
   a. if the contact record is not found (We do the lookup using the contact name) then we create a new contact
   b. if the contact  record is found then it is updated.
2. Do not perform any update and go back to the Root Case record (the record from where the button was clicked)
**/

global with sharing class SyncContactFromCaseController{

    // flag that indicates whether the record was updated. 
    // the next actions that a user could perform are presented on the screen based on the value of this flag1
    Boolean isRecordUpdated = false;

    // flag that indicates whether the user rejected to update the parent account
    // the next actions that a user could perform are presented on the screen based on the value of this flag
    Boolean isUpdateCancelled = false;
    
    // flag that indicates if the related contact exists
    Boolean relatedContactExists { get; set;}
    
    // flag that indicates whether the new contact details are available on the case record
    public Boolean isNewContactDetailMissing {get;set;}
    
    // object that holds all the details which are fetched using SOQL
    Case rootCaseDetailsSo  { get; set;} 
    
    // the related contact object 
    Contact relatedContactSo { get; set;}
   
    // constructor method for standard controller       
    public SyncContactFromCaseController(ApexPages.StandardController stdController) {
        
        relatedContactExists = true;
        
        // query all the details for this record
        rootCaseDetailsSo = [SELECT AccountId, CaseNumber,
                             Contact.Name, Contact.Type__c, Contact.Phone, Contact.Email, Contact.Department, Contact.Title, New_Contact_Name__c, New_Contact_Type__c, New_Contact_Phone__c, New_Contact_Email__c, New_Contact_Department__c, New_Contact_Title__c
                             FROM Case 
                             WHERE id = :stdController.getId() LIMIT 1];
         
        if(rootCaseDetailsSo.New_Contact_Email__c !=null){
            try{
                relatedContactSo = [SELECT name, type__c, email, phone, department, title FROM Contact WHERE name =:rootCaseDetailsSo.New_Contact_Name__c AND accountId = :rootCaseDetailsSo.accountid LIMIT 1];
            }
            catch(Exception ex){
              // if no such contact record found then create a new contact
            createNewContactSoInstance();
            }
        }else {
            isNewContactDetailMissing = true;
        }
    }
    
    
    public void createNewContactSoInstance() {
            relatedContactExists = false;
    }
    
    public PageReference syncAccount() {
        
        if(!relatedContactExists) {
          relatedContactSo= new Contact();
        }  
            
        // to create a new contact we need to populate the first name and last name
        // to do that we split the contact_name__c with a space
        if(rootCaseDetailsSo.new_contact_name__c != null 
           && rootCaseDetailsSo.new_contact_name__c.length() > 0 
           && rootCaseDetailsSo.new_contact_name__c.contains(' ')) {            
           
            List<String> nameLst = rootCaseDetailsSo.new_contact_name__c.split(' ');
        
            if(nameLst != null && nameLst.size() > 0){
               
                relatedContactSo.firstname = nameLst[0];
                for (Integer i = 1 ; i < nameLst.size(); i++){ 
                    if (i == 1) {
                        relatedContactSo.lastname = nameLst[1]; 
                    }else {
                        relatedContactSo.lastname += ' ' +  nameLst[i] ;
                    }
                }
           }
        } else {
            relatedContactSo.firstName = rootCaseDetailsSo.new_contact_name__c;
            relatedContactSo.lastname = 'Unknown';
        }
            
        relatedContactSo.accountId  = rootCaseDetailsSo.accountId;
        relatedContactSo.type__c    = rootCaseDetailsSo.new_contact_type__c;
        relatedContactSo.email      = rootCaseDetailsSo.new_contact_email__c;
        relatedContactSo.phone      = rootCaseDetailsSo.new_contact_phone__c; 
        relatedContactSo.department = rootCaseDetailsSo.new_contact_department__c; 
        relatedContactSo.title      = rootCaseDetailsSo.new_contact_title__c;            
        relatedContactSo.Last_Sync_Case_No__c   = rootCaseDetailsSo.CaseNumber;
        relatedContactSo.Last_Sync_Date_Time__c = System.now();

        upsert relatedContactSo;
        
        this.isRecordUpdated = true;
        return null;
    }
    
    // when the user does not want to create/update root account, redirect to same page with a flag that indicates that 
    // the user cancelled the operation. this flag is used by the VF page to display the corresponding acknowledgement message.
    public PageReference cancelSyncAccount(){
        isUpdateCancelled = true;
        return null;
    }
    
    // eventually take the user back the root case record
    public PageReference redirectToRootCase() {
         PageReference rootCaseDetailsSoPageRef = new PageReference('/' +this.rootCaseDetailsSo.id);
         rootCaseDetailsSoPageRef.setRedirect(true);
         return rootCaseDetailsSoPageRef;        
    } 
    
   public Case getRootCase()     { return this.rootCaseDetailsSo;  }
    
   public Contact getRelatedContact()  {   return this.relatedContactSo;  }
  
   public Boolean getRelatedContactExists()  {   return this.relatedContactExists;   }
    
   public Boolean getIsUpdateCancelled()   {    return this.isUpdateCancelled;  }
           
   public Boolean getIsRecordUpdated()   {  return this.isRecordUpdated;  }
}
/*
* This is the controller class for the SyncRootAccountFromCase VF page. The user gets redirected to this page after
* fields displayed on the SyncParentAccountFromCase VF Page are synced(or may not be) with the parent account.
* Here the user has two options: 
* 1. Either update the displayed fields from the Root Certificate from Root Case (source) to the 
*    Root Certificate from Account (target) or insert new Root Certificate in Account 
*    a. if the root certificate on account is not found (We do the lookup using the Case.AccountId and PEM Info) 
*       then we create a new root case account.
*    b. if the root certificate on account record is found then it is updated.
* 2. Do not perform any update and go through the next root case 
* 3. if the user has reviewed all the root cases then redirect the user to sync contact details page. 
*
*/

global with sharing class SyncRootAccountFromCaseController {

    // flag for exception handling
    Public Boolean hasError{get; set;}  
    
    // the root account object whose name is same as the root case name.
    public Account rootAccountSO { get; set;}
    public Root_Case__c rootCaseSO { get; set;}
    
    // this variable holds the count of total number of root cases. this is displayed on the page
    Integer totalRootCaseCount;
    
    // this variable holds the sequence number of the current account ex: 2 of 4 
    Integer currentRecordCount;
    
    private List<Root_Case__c> lstRootCases;
    
    Map<Id, Root_Case__c> mapRootCases = new Map<Id, Root_Case__c>();
    
    List<Account> lstAccounts;
    
    Boolean rootAccountExists;
    
    public Boolean isRecordUpdated {get; private set;}
    public Boolean isUpdateCancelled {get; private set;}
    String caseId;
    
    // if field is blank
    // public boolean isPEMInfoBlank {get; set;}
    public boolean isFieldBlank {get; set;}
    public String fieldBlankError {get; set;}
    
    // constructor method for standard controller    
    public SyncRootAccountFromCaseController(ApexPages.StandardController stdController) {
         
        // get the record id on which the button was clicked
        caseId = stdController.getId();
         
        // query all the details for this record
        Set<String> accountIds = new Set<String>();
        this.lstRootCases = new List<Root_Case__c>();
        this.currentRecordCount = 0;
        this.lstAccounts = new List<Account>();
        this.isRecordUpdated = false;
        this.isUpdateCancelled = false;
        this.hasError = false;
        this.isFieldBlank = false;
        
        for(Root_Case__c rootCase : [select name, case_no__c, case_no__r.accountid, case_no__r.Link_to_Bugzilla_Bug__c, 
                Root_Certificate_Name__c, Certificate_Issuer_Common_Name__c, O_From_Issuer_Field__c, OU_From_Issuer_Field__c, 
                SHA_1_Fingerprint__c, SHA_256_Fingerprint__c, 
                valid_from__c, valid_to__c, Certificate_Serial_Number__c, 
                Subject__c, Signature_Hash_Algorithm__c, Public_Key_Algorithm__c, 
                Test_Website_Expired__c, Test_Website_Revoked__c, Test_Website_Valid__c, 
                Trust_Bits__c, EV_Policy_OID_s__c, Mozilla_Applied_Constraints__c, 
                Issuer__c,OU_From_Subject_Field__c,O_From_Subject_Field__c,
                Subject_SPKI_SHA256__c,SPKI_SHA256__c,
                NSS_Release_When_First_Included__c, Firefox_Release_When_First_Included__c , 
                X_509_Certificate_PEM__c, Extraction_Results__c
                FROM Root_Case__c where Case_No__c = :caseId]){
            
            mapRootCases.put(rootCase.Id, rootCase);
            accountIds.add(rootCase.Case_no__r.AccountId);
        }
        
        lstRootCases.addAll(mapRootCases.values());
        this.totalRootCaseCount = lstRootCases.size();
        this.lstAccounts = [SELECT Id, Name, Parentid, Type, 
                                   Certificate_Issuer_Common_Name__c, Certificate_Issuer_Organization__c, 
                                   Certificate_Issuer_Organizational_Unit__c,
                                   Approval_Bug__c, 
                                   SHA_1_Fingerprint__c, SHA_256_Fingerprint__c, Certificate_Version__c,
                                   Valid_from_GMT__c, Valid_to_GMT__c, Certificate_Serial_Number__c, Subject__c,
                                   Signature_Hash_Algorithm__c, Public_Key_Algorithm__c,
                                   Test_Website_Expired__c, Test_Website_Revoked__c, Test_Website_Valid__c,
                                   CRL_URL_s__c,Issuer__c,Certificate_Subject_Organization__c ,Certificate_Subject_Organization_Unit__c ,
                                   Subject_SPKI_SHA256__c,SPKI_SHA256__c,
                                   Trust_Bits__c, EV_Policy_OID_s__c, Mozilla_Applied_Constraints__c,
                                   Standard_Audit__c, Standard_Audit_Type__c, Standard_Audit_Statement_Date__c,
                                   Standard_Audit_Period_Start_Date__c, Standard_Audit_Period_End_Date__c,
                                   Code_Signing_Audit__c, Code_Signing_Audit_Type__c, Code_Signing_Audit_Statement_Date__c, 
                                   Code_Signing_Audit_Period_Start_Date__c, Code_Signing_Audit_Period_End_Date__c,
                                   BR_Audit__c, BR_Audit_Type__c, BR_Audit_Statement_Date__c, 
                                   BR_Audit_Period_Start_Date__c, BR_Audit_Period_End_Date__c,
                                   EV_Audit__c, EV_Audit_Type__c, EV_Audit_Statement_Date__c,
                                   EV_Audit_Period_Start_Date__c, EV_Audit_Period_End_Date__c,
                                   Auditor_New__c, Auditor_New__r.Name, Auditor_Location_New__c, Auditor_Location_New__r.Name,     
                                   Policy_Documentation__c, CA_Document_Repository__c, Certificate_Policy_CP__c, 
                                   Certification_Practice_Statement_CPS__c, 
                                   NSS_Release_When_First_Included__c, Firefox_Release_When_First_Included__c,
                                   X_509_Certificate_PEM__c                                   
                                   FROM Account 
                                   WHERE ParentId IN :accountIds
                                   AND Type = 'Root'
                                   AND Name <> '<Fill in Cert Name>'];
        getRecordsForComparison();
        
    }//end of constructor
    
    private void getRecordsForComparison(){
        
        this.rootAccountSO = null;
        this.isRecordUpdated = false;
        this.isUpdateCancelled = false;
        this.hasError = false;
        this.isFieldBlank = false;
        fieldBlankError = '';
        
        if(!lstRootCases.isEmpty() && this.currentRecordCount < this.totalRootCaseCount){
            this.rootCaseSO = lstRootCases[this.currentRecordCount];
            
            // do not allow user to sync if the fields are blank
            /*if (this.rootCaseSO.Standard_Audit_Period_Start_Date__c == null) {                
                fieldBlankError += ' "Standard Audit Period Start Date"';
                isFieldBlank = true;
                hasError = true;
            }
                       
            if (this.rootCaseSO.Standard_Audit_Period_End_Date__c == null) {                
                fieldBlankError += ' "Standard Audit Period End Date"';
                isFieldBlank = true;
                hasError = true;
            }*/
                                    
            /*if (this.rootCaseSO.BR_Audit__c != null && this.rootCaseSO.BR_Audit_Period_Start_Date__c == null) {               
                fieldBlankError += ' "BR Audit Period Start Date"';
                isFieldBlank = true;
                hasError = true;
            }
            
            if (this.rootCaseSO.BR_Audit__c != null && this.rootCaseSO.BR_Audit_Period_End_Date__c == null) {               
                fieldBlankError += ' "BR Audit Period End Date"';
                isFieldBlank = true;
                hasError = true;
            }
            
            if (this.rootCaseSO.EV_Audit__c != null && this.rootCaseSO.EV_SSL_Audit_Period_Start_Date__c == null) {               
                fieldBlankError += ' "EV SSL Audit Period Start Date"';
                isFieldBlank = true;
                hasError = true;
            }
            
            if (this.rootCaseSO.EV_Audit__c != null && this.rootCaseSO.EV_SSL_Audit_Period_End_Date__c == null) {               
                fieldBlankError += ' "EV SSL Audit Period End Date"';
                isFieldBlank = true;
                hasError = true;
            }*/
            
            /*if (this.rootCaseSO.Management_Assertions_By__c == null) {               
                fieldBlankError += ' "Management Assertions By"';
                isFieldBlank = true;
                hasError = true;
            }  */         

            /*if (this.rootCaseSO.Auditor_New__c == null) {                
                fieldBlankError += ' "Auditor"';
                isFieldBlank = true;
                hasError = true;
            }
            
            if (this.rootCaseSO.Auditor_Location_New__c == null) {                
                fieldBlankError += ' "Auditor Location"';
                isFieldBlank = true;
                hasError = true;
            }  */                     
            
            String str2;
            if (this.rootCaseSO.X_509_Certificate_PEM__c == null) { 
                fieldBlankError += ' "PEM Info"';
                isFieldBlank = true;
                hasError = true;
            } else {              
               // remove carriage return and newline characters before comparing PEM info
               str2 = this.rootCaseSO.X_509_Certificate_PEM__c.trim().replaceall('\r','');
               str2 = str2.replaceall('\n','').replaceall(' ','');
            } 
            
            for(Account acc : this.lstAccounts){
                if(acc.X_509_Certificate_PEM__c != null){
                    // remove carriage return and newline characters before comparing PEM info
                    String str1 = acc.X_509_Certificate_PEM__c.trim().replaceall('\r','');
                    str1 = str1.replaceall('\n','').replaceall(' ','');
                    //for(Root_Case__c rootCase : mapRootCases.values()){
                        if(acc.ParentId == this.rootCaseSO.Case_no__r.AccountId){
                            if(str1 == str2){
                                this.rootAccountSO = acc;
                                rootAccountExists  = true;
                                break;
                            }
                        }
                    //}
                }
            }
            
            if(this.rootAccountSO == null){
                this.rootAccountSO = createNewAccountSoInstance(this.rootCaseSO.Root_Certificate_Name__c, this.rootCaseSO.Case_No__r.AccountId);
                rootAccountExists = false;
            }
        }
    }
    
    // this method is invoked when the root case contains the account name which does not exists
    // in that case we need to create a new root account
    public Account createNewAccountSoInstance(String accName, String acParentId){
        Account rootAccountSo = new Account(Name = accName, ParentId = acParentId);
        rootAccountSo.RecordTypeID = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Root Certificate').getRecordTypeID();
        return rootAccountSo;
    }
    
  
    // update the root cert in account and redirect the user to the same page but this time append a flag which indicates that the 
    // record was updated. This flag will be used by the VF page to determine if the acknowledgement message needs to be displayed    
    public PageReference syncAccount(){
         
         this.rootAccountSo.type= 'Root';
         this.rootAccountSo.Certificate_Issuer_Common_Name__c = this.rootCaseSO.Certificate_Issuer_Common_Name__c;
         this.rootAccountSo.Certificate_Issuer_Organization__c = this.rootCaseSO.O_From_Issuer_Field__c;
         this.rootAccountSo.Certificate_Issuer_Organizational_Unit__c = this.rootCaseSO.OU_From_Issuer_Field__c;
         this.rootAccountSo.valid_from_GMT__c= this.rootCaseSO.valid_from__c;
         this.rootAccountSo.valid_to_GMT__c= this.rootCaseSO.valid_to__c; 
         this.rootAccountSo.Certificate_Serial_Number__c= this.rootCaseSO.Certificate_Serial_Number__c; 
         this.rootAccountSo.Subject__c = this.rootCaseSO.Subject__c; 
         this.rootAccountSo.Signature_Hash_Algorithm__c= this.rootCaseSO.Signature_Hash_Algorithm__c; 
         this.rootAccountSo.Public_Key_Algorithm__c= this.rootCaseSO.Public_Key_Algorithm__c;        
         this.rootAccountSo.SHA_1_Fingerprint__c= this.rootCaseSO.SHA_1_Fingerprint__c; 
         this.rootAccountSo.SHA_256_Fingerprint__c= this.rootCaseSO.SHA_256_Fingerprint__c;  
         // this.rootAccountSo.Certificate_ID__c = this.rootCaseSO.Certificate_Fingerprint__c;  
         //this.rootAccountSo.Certificate_Version__c = this.rootCaseSO.Certificate_Version__c;
         
         //new fields sync
         this.rootAccountSo.Issuer__c = this.rootCaseSO.Issuer__c;
         this.rootAccountSo.Certificate_Subject_Organization_Unit__c = this.rootCaseSO.OU_From_Subject_Field__c;
         this.rootAccountSo.Certificate_Subject_Organization__c = this.rootCaseSO.O_From_Subject_Field__c;
         this.rootAccountSo.Subject_SPKI_SHA256__c  = this.rootCaseSO.Subject_SPKI_SHA256__c ;
         this.rootAccountSo.SPKI_SHA256__c  = this.rootCaseSO.SPKI_SHA256__c ;
         // this.rootAccountSo.Key_Usage__c  = this.rootCaseSO.Key_Usage__c;
         // this.rootAccountSo.Extended_Key_Usage__c  = this.rootCaseSO.Extended_Key_Usage__c ;                    
         
         // copy test website only if null or url   
         if(this.rootCaseSO.Test_Website_Valid__c == null || 
           (this.rootCaseSO.Test_Website_Valid__c != null && 
           (this.rootCaseSO.Test_Website_Valid__c.startsWithIgnoreCase('https://')))) {
             this.rootAccountSo.Test_Website_Valid__c = this.rootCaseSO.Test_Website_Valid__c; 
         } 
         if(this.rootCaseSO.Test_Website_Revoked__c == null || 
           (this.rootCaseSO.Test_Website_Revoked__c != null && 
           (this.rootCaseSO.Test_Website_Revoked__c.startsWithIgnoreCase('https://')))) {
             this.rootAccountSo.Test_Website_Revoked__c = this.rootCaseSO.Test_Website_Revoked__c; 
         } 
         if(this.rootCaseSO.Test_Website_Expired__c == null || 
           (this.rootCaseSO.Test_Website_Expired__c != null && 
           (this.rootCaseSO.Test_Website_Expired__c.startsWithIgnoreCase('https://')))) {
             this.rootAccountSo.Test_Website_Expired__c = this.rootCaseSO.Test_Website_Expired__c; 
         }
                       
         //this.rootAccountSo.CRL_URL_s__c= this.rootCaseSO.CRL_URL_s__c; 
         //*not used on root certificate page
         // this.rootAccountSo.OCSP_URL_s__c= this.rootCaseSO.OCSP_URL_s__c; *not used on root certificate page
         
         // this.rootAccountSo.Root_Certificate_Download_URL__c= this.rootCaseSO.Root_Certificate_Download_URL__c;
         this.rootAccountSo.Trust_Bits__c= this.rootCaseSO.Trust_Bits__c; 
         this.rootAccountSo.EV_Policy_OID_s__c= this.rootCaseSO.EV_Policy_OID_s__c;              
         this.rootAccountSo.Mozilla_Applied_Constraints__c= this.rootCaseSO.Mozilla_Applied_Constraints__c; 
         
         /*if(this.rootCaseSO.Standard_Audit__c != null && this.rootCaseSO.Standard_Audit__c.startswith('http')) {
             this.rootAccountSo.Standard_Audit__c= this.rootCaseSO.Standard_Audit__c; 
         }
         this.rootAccountSo.Standard_Audit_Type__c= this.rootCaseSO.Standard_Audit_Type__c; 
         this.rootAccountSo.Standard_Audit_Statement_Date__c= this.rootCaseSO.Standard_Audit_Statement_Date__c;
         this.rootAccountSo.Standard_Audit_Period_Start_Date__c = this.rootCaseSO.Standard_Audit_Period_Start_Date__c;
         this.rootAccountSo.Standard_Audit_Period_End_Date__c = this.rootCaseSO.Standard_Audit_Period_End_Date__c; 
 
         if(this.rootCaseSO.BR_Audit__c != null && this.rootCaseSO.BR_Audit__c.startswith('http')) {
             this.rootAccountSo.BR_Audit__c= this.rootCaseSO.BR_Audit__c; 
         }
         this.rootAccountSo.BR_Audit_Type__c= this.rootCaseSO.BR_Audit_Type__c; 
         this.rootAccountSo.BR_Audit_Statement_Date__c= this.rootCaseSO.BR_Audit_Statement_Date__c; 
         this.rootAccountSo.BR_Audit_Period_Start_Date__c = this.rootCaseSO.BR_Audit_Period_Start_Date__c;
         this.rootAccountSo.BR_Audit_Period_End_Date__c = this.rootCaseSO.BR_Audit_Period_End_Date__c;
 
         if(this.rootCaseSO.EV_Audit__c != null && this.rootCaseSO.EV_Audit__c.startswith('http')) {
             this.rootAccountSo.EV_Audit__c= this.rootCaseSO.EV_Audit__c; 
         }
         this.rootAccountSo.EV_Audit_Type__c= this.rootCaseSO.EV_Audit_Type__c;
         this.rootAccountSo.EV_Audit_Statement_Date__c= this.rootCaseSO.EV_Audit_Statement_Date__c;
         this.rootAccountSo.EV_Audit_Period_Start_Date__c = this.rootCaseSO.EV_SSL_Audit_Period_Start_Date__c;
         this.rootAccountSo.EV_Audit_Period_End_Date__c = this.rootCaseSO.EV_SSL_Audit_Period_End_Date__c;*/

         // this.rootAccountSo.Management_Assertions_By__c = this.rootCaseSO.Management_Assertions_By__c;
         
         //this.rootAccountSo.Auditor_New__c= this.rootCaseSO.Auditor_New__c;
         //this.rootAccountSo.Auditor_Location_New__c= this.rootCaseSO.Auditor_Location_New__c;
                  
         //this.rootAccountSo.Policy_Documentation__c= this.rootCaseSO.Policy_Documentation__c;
         //this.rootAccountSo.CA_Document_Repository__c= this.rootCaseSO.CA_Document_Repository__c;
         //this.rootAccountSo.Certificate_Policy_CP__c= this.rootCaseSO.CP__c;
         //this.rootAccountSo.Certification_Practice_Statement_CPS__c= this.rootCaseSO.CPS__c;
         //this.rootAccountSo.Publicly_Disclosed_and_Audited_subCAs__c= this.rootCaseSO.Publicly_Disclosed_and_Audited_subCAs__c;
         this.rootAccountSo.NSS_Release_When_First_Included__c = this.rootCaseSO.NSS_Release_When_First_Included__c;
         this.rootAccountSo.Firefox_Release_When_First_Included__c = this.rootCaseSO.Firefox_Release_When_First_Included__c;
         this.rootAccountSo.Approval_Bug__c = this.rootCaseSO.case_no__r.Link_to_Bugzilla_Bug__c;
         
         this.rootAccountSo.X_509_Certificate_PEM__c = this.rootCaseSO.X_509_Certificate_PEM__c;
         this.rootAccountSo.Extraction_Results__c = this.rootCaseSO.Extraction_Results__c;
         
         this.rootAccountSo.Last_Sync_Case_No__c = this.rootCaseSO.Name;
         this.rootAccountSo.Last_Sync_Date_Time__c = System.now();
         this.rootAccountSo.Status__c ='Included'; 
         
        try{
            upsert rootAccountSo;  
            
            //re-query and get udpated values
            rootAccountSo = [SELECT Id, Name, Parentid, Type, 
                                   Certificate_Issuer_Common_Name__c, Certificate_Issuer_Organization__c, 
                                   Certificate_Issuer_Organizational_Unit__c,
                                   Approval_Bug__c, 
                                   SHA_1_Fingerprint__c, SHA_256_Fingerprint__c, Certificate_Version__c,
                                   Valid_from_GMT__c, Valid_to_GMT__c, Certificate_Serial_Number__c, Subject__c,
                                   Signature_Hash_Algorithm__c, Public_Key_Algorithm__c,
                                   Test_Website_Expired__c, Test_Website_Revoked__c, Test_Website_Valid__c,
                                   CRL_URL_s__c,
                                   Trust_Bits__c, EV_Policy_OID_s__c, Mozilla_Applied_Constraints__c,
                                   Standard_Audit__c, Standard_Audit_Type__c, Standard_Audit_Statement_Date__c,
                                   Standard_Audit_Period_Start_Date__c, Standard_Audit_Period_End_Date__c,
                                   BR_Audit__c, BR_Audit_Type__c, BR_Audit_Statement_Date__c, 
                                   BR_Audit_Period_Start_Date__c, BR_Audit_Period_End_Date__c,
                                   EV_Audit__c, EV_Audit_Type__c, EV_Audit_Statement_Date__c,
                                   EV_Audit_Period_Start_Date__c, EV_Audit_Period_End_Date__c,
                                   Issuer__c,Certificate_Subject_Organization__c ,Certificate_Subject_Organization_Unit__c ,
                                   Subject_SPKI_SHA256__c,SPKI_SHA256__c,
                                   Auditor_New__c, Auditor_New__r.Name, Auditor_Location_New__c, Auditor_Location_New__r.Name,     
                                   Policy_Documentation__c, CA_Document_Repository__c, Certificate_Policy_CP__c, 
                                   Certification_Practice_Statement_CPS__c, 
                                   NSS_Release_When_First_Included__c, Firefox_Release_When_First_Included__c,
                                   X_509_Certificate_PEM__c                                   
                                   FROM Account 
                                   WHERE Id = :rootAccountSo.Id
                                   AND Type = 'Root'
                                   AND Name <> '<Fill in Cert Name>'];
                               
            // Lastly, update the hidden fields and set Sync execution date/time on Root Case record
            this.rootCaseSO.CA_Owner_Name_Existing__c = rootAccountSo.parentid;  
            this.rootCaseSO.Root_Certificate_Name_Existing__c = rootAccountSo.id;
            this.rootCaseSO.Last_Sync_Date_Time__c = System.now();
        
            try { 
                update rootCaseSO;  
                  
            } catch(Exception ex) {
            
               isRecordUpdated= false;
               this.hasError = true;
               ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
               return null;
            }   
           
        } catch(Exception ex) {
           
            isRecordUpdated= false;
            this.hasError = true;
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
            return null;  
        }

        // ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM, 'Record Updated Successfully'));
        this.isRecordUpdated= true; 
        this.isUpdateCancelled = false;    
        return null;
    }
   
   // before redirecting the user to syncContact page check if there are more root cases to be reviewed
   // if there are more root cases then present the next root case to the user
   public PageReference redirectToSyncContact(){
        PageReference rootCaseSoPageRef = new PageReference('/apex/SyncContactFromCase?id='+caseId);
        return rootCaseSoPageRef;
    }
     
   // when the user does not want to create/update root account, redirect to same page with a flag that indicates that 
   // the user cancelled the operation. this flag is used by the VF page to display the corresponding acknowledgement message.
   // also the user is redirect to the next root case
   
   public PageReference next(){
       
       this.isRecordUpdated = false;
       this.isUpdateCancelled = false;
       this.hasError = false;
       // this.isPEMInfoBlank = false;
       this.isFieldBlank = false;
       return cancelSyncAccount();
   }
   
   public PageReference cancelSyncAccount(){
        this.currentRecordCount++;
        //this.isUpdateCancelled = true;
        //this.isRecordUpdated = false;
        if(this.currentRecordCount == this.totalRootCaseCount){
            return redirectToSyncContact();
        }
        getRecordsForComparison();
        return null;
    }
    
  // eventually take the user back the root case record
   public PageReference redirectToRootCase() {
         
         PageReference rootCaseSoPageRef = new PageReference('/' +this.rootCaseSo.id);
         rootCaseSoPageRef.setRedirect(true);
         return rootCaseSoPageRef;        
    }
    
   
   public Root_Case__c getRootCase()  { return this.rootCaseSO;  }
    
   public Account getParentAccount()     { return this.rootAccountSo;  }
  
   public Integer getTotalRootCaseCount() {   return this.totalRootCaseCount;  }
   
   public Integer getCurrentRecordCount()  {   return this.currentRecordCount+1;  }

   public Boolean getRootAccountExists() { return this.rootAccountExists;  }
 
}
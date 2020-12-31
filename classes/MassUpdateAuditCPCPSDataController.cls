/**
This is the controller class for the MassUpdateAuditCPPSData VF page.
When the "Mass Update Audit/CP/CPS Data" button is clicked from any Root Certificate  
the user is redirected to  MassUpdateAuditCPPSData VF page. 

When the "Mass Update Audit/CP/CPS Data" button is clicked from any Intermediate Certificate  
the user is redirected to  MassUpdateAuditCPPSDataLandingPage VF page. 

This controller iterates through all records related to the Parent Account and updates
the Audit, CP/CPS fields upon users response.

If the source  record is 'Removed' user will not be allowed to proceed with mass update.
If the source and target fields match then the record is not selected for mass update.

Mass update is separated into four sections  'Standard Audit & Auditor
Fields', 'BR Audit Fields', 'EV Audit Fields' (same as EV SSL Audit), 'EV Code Signing Audit' 
and 'Verified Audit Date'.

Users with 'Standard User - Mozilla' profile, will only see Mozilla fields in 'Verified Audit
Date' section.

Users with 'Standard User - Microsoft' profile, will only see Microsoft fields in 'Verified Audit
Date' section.

Users with other profiles will not see 'Verified Audit Date' section at all.

11th May 2020 - COMMENTED code for CP/CPS fields sync. - Uncommented as this is also used for Intermediate certs.

**/

global with sharing class MassUpdateAuditCPCPSDataController {

    public Account sourceAccountSo{get; set;}
    public Account targetAccountSo{get; set;}
    List<Account> lstSiblingAccounts;   
    public Integer recordIndex{get; set;}
    public Integer totaltargetAccountCount {get; set;}
    public Boolean showConfirmation{get; set;}
    public Boolean showMessage{get; set;}
    public Boolean hasError{get; set;}
    public Boolean isValidPortalUser{get; set;}
    public Boolean isMozillaProfile{get;set;}
    public Boolean isMicrosoftProfile{get;set;}
    public Boolean isRootCert {get; set;}
    //no more records
    public Boolean isMoreRecordFound {get; set;}   
    public Boolean isIntermediateCert {get; set;}   
    public Boolean showAuditorNewFieldsConfirmation{get;set;}
    public Boolean showStdAuditFieldsConfirmation{get;set;}
    public Boolean showCodeSigningAuditFieldsConfirmation {get; set;}
    public Boolean showBRAuditFieldsConfirmation{get;set;}
    public Boolean showEVSSLAuditFieldsConfirmation{get;set;}
    public Boolean showEVCodeSigningAuditFieldsConfirmation{get;set;}
    public Boolean showPolicyFieldsConfirmation {get;set;}
    public Boolean showMozillaFieldsConfirmation {get;set;}
    public Boolean showMicrosoftFieldsConfirmation {get;set;}         

    public String  title{get; set;}  
  
    // List of fields on which source and target certificates are compared
    static List<String> fields = new List<String>();
    static{
        fields.add('Auditor_New__c');            
        fields.add('Auditor_Location_New__c');    
        fields.add('Audits_Same_as_Parent__c');
        fields.add('Standard_Audit__c');
        fields.add('Standard_Audit_Type__c');
        fields.add('Standard_Audit_Statement_Date__c'); 
        fields.add('Standard_Audit_Period_Start_Date__c');
        fields.add('Standard_Audit_Period_End_Date__c');      
        
        fields.add('Code_Signing_Audit__c');
        fields.add('Code_Signing_Audit_Type__c');
        fields.add('Code_Signing_Audit_Statement_Date__c');
        fields.add('Code_Signing_Audit_Period_Start_Date__c');
        fields.add('Code_Signing_Audit_Period_End_Date__c');
        
        fields.add('BR_Audit__c');
        fields.add('BR_Audit_Type__c');
        fields.add('BR_Audit_Statement_Date__c');
        fields.add('BR_Audit_Period_Start_Date__c');
        fields.add('BR_Audit_Period_End_Date__c'); 
        fields.add('EV_Audit__c');
        fields.add('EV_Audit_Type__c');
        fields.add('EV_Audit_Statement_Date__c');
        fields.add('EV_Audit_Period_Start_Date__c');
        fields.add('EV_Audit_Period_End_Date__c'); 
        fields.add('EV_Code_Signing_Audit__c');
        fields.add('EV_Code_Signing_Audit_Type__c');
        fields.add('EV_Code_Signing_Audit_Statement_Date__c');
        fields.add('EV_Code_Signing_Audit_Period_Start_Date__c');
        fields.add('EV_Code_Signing_Audit_Period_End_Date__c');        
        //fields.add('Management_Assertions_By__c');
        fields.add('CP_CPS_Same_as_Parent__c');
        fields.add('Policy_Documentation__c');
        fields.add('CA_Document_Repository__c');
        fields.add('Certificate_Policy_CP__c');
        fields.add('Certification_Practice_Statement_CPS__c');
        fields.add('CP_CPS_Last_Updated_Date__c');
        // fields.add('Mozilla_Verified_Audit_Date__c');
        // fields.add('Microsoft_Verified_Audit_Date__c');
        // fields.add('Auditor__c'); deprecated
        // fields.add('Auditor_Website__c'); deprecated
        // fields.add('Auditor_Qualifications__c'); deprecated
    }

    // constructor method for standard controller
    public MassUpdateAuditCPCPSDataController(ApexPages.StandardController stdController) {
                
         // get the record id on which the button was clicked
         this.sourceAccountSo = (Account)stdController.getRecord();      
         lstSiblingAccounts = new List<Account>();
         this.recordIndex = 0;
         this.isMoreRecordFound = true;
         this.showConfirmation = true;
         this.showMessage = false;
         this.hasError = false;
         this.title = 'No more certificates to update';
         this.isValidPortalUser = true;
         this.isMozillaProfile = false;
         this.isMicrosoftProfile = false;
         this.isRootCert = false;
         this.isIntermediateCert = false;
         this.showAuditorNewFieldsConfirmation = true;
         this.showStdAuditFieldsConfirmation = true;
         this.showCodeSigningAuditFieldsConfirmation  = true;
         this.showBRAuditFieldsConfirmation = true;
         this.showEVSSLAuditFieldsConfirmation = true;
         this.showEVCodeSigningAuditFieldsConfirmation = true;
         this.showPolicyFieldsConfirmation = true;
         this.showMozillaFieldsConfirmation = true;
         this.showMicrosoftFieldsConfirmation = true;     
         
         if(getCurrentProfileName()!=null && getCurrentProfileName().length() > 0 && getCurrentProfileName().equalsIgnorecase('Standard User - Mozilla'))
         {
          this.isMozillaProfile=true;
         }
         if(getCurrentProfileName()!=null && getCurrentProfileName().length() > 0 && getCurrentProfileName().equalsIgnorecase('Standard User - Microsoft'))
         {
          this.isMicrosoftProfile =true;
         }
         
         try{
        
             // get (one) source certificate root cert or intermediate cert
             this.sourceAccountSo = [select Id, Name, ParentId, Parent.Name, Friendly_Name__c, Type, 
                                       SHA_1_Fingerprint__c, SHA_256__c,
                                       Trust_bits__c, Microsoft_Trust_Bits__c,
                                       Revocation_Status__c, Date_of_Revocation__c, RFC_5280_Revocation_Reason_Code__c,
                                       Audits_Same_as_Parent__c, Standard_Audit__c, 
                                       Standard_Audit_Type__c, Standard_Audit_Statement_Date__c,
                                       Standard_Audit_Period_Start_Date__c, Standard_Audit_Period_End_Date__c,
                                       Code_Signing_Audit__c, Code_Signing_Audit_Type__c, Code_Signing_Audit_Statement_Date__c,
                                       Code_Signing_Audit_Period_Start_Date__c, Code_Signing_Audit_Period_End_Date__c,
                                       BR_Audit__c, BR_Audit_Type__c, BR_Audit_Statement_Date__c,
                                       BR_Audit_Period_Start_Date__c, BR_Audit_Period_End_Date__c,
                                       EV_Audit__c, EV_Audit_Type__c, EV_Audit_Statement_Date__c,
                                       EV_Audit_Period_Start_Date__c, EV_Audit_Period_End_Date__c,
                                       EV_Code_Signing_Audit__c, EV_Code_Signing_Audit_Type__c, EV_Code_Signing_Audit_Statement_Date__c,
                                       EV_Code_Signing_Audit_Period_Start_Date__c, EV_Code_Signing_Audit_Period_End_Date__c,
                                       Auditor_New__c, Auditor_New__r.Name, Auditor_Location_New__c, Auditor_Location_New__r.Name,
                                       Auditor__c, Auditor_Website__c, Auditor_Qualifications__c,
                                       CP_CPS_Same_as_Parent__c, Policy_Documentation__c, CA_Document_Repository__c,
                                       Certificate_Policy_CP__c, Certification_Practice_Statement_CPS__c, CP_CPS_Last_Updated_Date__c,
                                       Mozilla_Verified_Audit_Date__c, Microsoft_Verified_Audit_Date__c,
                                       EV_Policy_OID_s__c, Microsoft_EV_Enabled__c,
                                       Do_NOT_Send_Audit_Reminder__c, Microsoft_Do_NOT_Send_Audit_Reminder__c,                                  
                                       Status__c, Microsoft_Status__c,Removal_Bug_No_or_Date__c, RecordType.Name
                                       from Account 
                                       where id = :this.sourceAccountSo.id 
                                       limit 1];   
                                       
            if (this.sourceAccountSo.Type == 'Root'){ 
                 this.isRootCert = true;
            }
            
            if (this.sourceAccountSo.Type == 'Intermediate Certificate'){ 
                 this.isIntermediateCert = true;
            }
            
             // if Mozilla user, then check for Mozilla Status
            if(this.isMozillaProfile == True && this.sourceAccountSo.Status__c == 'Removed'){
                this.title = 'Source Certificate has been removed (Mozilla Status = Removed). You cannot run mass update.';
                this.showMessage = true;
                this.hasError = true;
                return;
                //ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'This certificate had been removed. You cannot run mass update.'));
            }
            
            // if Microsoft user, then check for Microsoft Status
            if(this.isMicrosoftProfile == True && this.sourceAccountSo.Microsoft_Status__c == 'Removed'){
                this.title = 'Source Certificate has been removed (Microsoft Status = Removed). You cannot run mass update.';
                this.showMessage = true;
                this.hasError = true;
                return;
            }
            
            if(this.sourceAccountSo.Audits_Same_As_Parent__c == true && this.sourceAccountSo.CP_CPS_Same_As_Parent__c == true) {
                this.title = 'Cannot continue with Mass Update when \'Audits Same as Parent\' & \'CP/CPS Same as Parent\' are true.';
                this.showMessage = true;
                this.hasError = true;
                return;
            }
            
            // Auditor (New) fields must be filled before starting mass update process 
            if(this.sourceAccountSo.Audits_Same_As_Parent__c == false &&
               (this.sourceAccountSo.Auditor_New__c == null ||  
                this.sourceAccountSo.Auditor_Location_New__c == null)){
                
                this.title = 'Fill in Auditor and Auditor Location fields before proceeding with mass update.';
                this.showMessage = true;
                this.hasError = true;
                return;
            }
          
            // Deprecated fields - Auditor fields must be filled before starting mass update process 
            // if(this.sourceAccountSo.Audits_Same_As_Parent__c == false &&
            //   (this.sourceAccountSo.Auditor__c == null || 
            //    this.sourceAccountSo.Auditor_Website__c == null || 
            //    this.sourceAccountSo.Auditor_Qualifications__c == null)){
            //    this.title = 'Fill in Auditor, Auditor Website, and Auditor Qualifications fields before proceeding with mass update.';
            //    this.showMessage = true;
            //    this.hasError = true;
            //    return;
            // }
       
            // For source cert ALL Standard Audit fields should be populated or null 
            // If one or more standard audit fields are populated then other fields cannot left blank
            if ((this.sourceAccountSo.Standard_Audit__c == null ||
                this.sourceAccountSo.Standard_Audit_Type__c == null ||
                this.sourceAccountSo.Standard_Audit_Statement_Date__c == null) && 
                (!(this.sourceAccountSo.Standard_Audit__c == null &&
                   this.sourceAccountSo.Standard_Audit_Type__c == null &&
                   this.sourceAccountSo.Standard_Audit_Statement_Date__c == null))) {
                
                this.title = 'Fill in data for blank Standard Audit fields before proceeding with mass update: Standard Audit, Standard Audit Type, and Standard Audit Statement Date ';
                this.showMessage = true;
                this.hasError = true;
                return;
            }
            
            // For source cert ALL Code signing Audit fields should be populated or null 
             // If one or more Code Signing audit fields are populated then other fields cannot left blank
            if ((this.sourceAccountSo.Code_Signing_Audit__c == null ||
                this.sourceAccountSo.Code_Signing_Audit_Type__c == null ||
                this.sourceAccountSo.Code_Signing_Audit_Statement_Date__c == null) && 
                (!(this.sourceAccountSo.Code_Signing_Audit__c == null &&
                   this.sourceAccountSo.Code_Signing_Audit_Type__c == null &&
                   this.sourceAccountSo.Code_Signing_Audit_Statement_Date__c == null))) {
                
                this.title = 'Fill in data for blank Code Signing Audit fields before proceeding with mass update: Code Signing Audit, Code Signing Audit Type, and Code Signing Audit Statement Date';
                this.showMessage = true;
                this.hasError = true;
                return;
            }
          
             // For source cert ALL BR Audit fields should be populated or null 
             // If one or more BR audit fields are populated then other fields cannot left blank
            if ((this.sourceAccountSo.BR_Audit__c == null ||
                this.sourceAccountSo.BR_Audit_Type__c == null ||
                this.sourceAccountSo.BR_Audit_Statement_Date__c == null) && 
                (!(this.sourceAccountSo.BR_Audit__c == null &&
                   this.sourceAccountSo.BR_Audit_Type__c == null &&
                   this.sourceAccountSo.BR_Audit_Statement_Date__c == null))) {
                
                this.title = 'Fill in data for blank BR Audit fields before proceeding with mass update: BR Audit, BR Audit Type, and BR Audit Statement Date ';
                this.showMessage = true;
                this.hasError = true;
                return;
            }
            
          
             // For source cert ALL EV SSL Audit fields should populated or null 
             // If one or more EV SSL Audit fields are populated then other fields cannot left blank
            if ((this.sourceAccountSo.EV_Audit__c == null ||
                this.sourceAccountSo.EV_Audit_Type__c == null ||
                this.sourceAccountSo.EV_Audit_Statement_Date__c == null) && 
                (!(this.sourceAccountSo.EV_Audit__c == null &&
                   this.sourceAccountSo.EV_Audit_Type__c == null &&
                   this.sourceAccountSo.EV_Audit_Statement_Date__c == null))) {
                
                this.title = 'Fill in data for blank EV SSL Audit fields before proceeding with mass update: EV SSL Audit, EV SSL Audit Type, and EV SSL Audit Statement Date ';
                this.showMessage = true;
                this.hasError = true;
                return;
            }
            
             // For source cert ALL EV Code Signing Audit fields should populated or null 
             // If one or more EV Code Signing Audit fields are populated then other fields cannot left blank
            if ((this.sourceAccountSo.EV_Code_Signing_Audit__c == null ||
                this.sourceAccountSo.EV_Code_Signing_Audit_Type__c == null ||
                this.sourceAccountSo.EV_Code_Signing_Audit_Statement_Date__c == null) && 
                (!(this.sourceAccountSo.EV_Code_Signing_Audit__c == null &&
                   this.sourceAccountSo.EV_Code_Signing_Audit_Type__c == null &&
                   this.sourceAccountSo.EV_Code_Signing_Audit_Statement_Date__c == null))) {
                
                this.title = 'Fill in data for blank EV Code Signing Audit fields before proceeding with mass update: EV Code Signing Audit, EV Code Signing Audit Type, and EV Code Signing Audit Statement Date ';
                this.showMessage = true;
                this.hasError = true;
                return;
            }
            
            GetAllCertificates();
            
        }catch(Exception exp){
             this.hasError = true;
             this.showMessage = true;
             this.title = 'Unexpected Error Occurred, Please contact your administrator.';
        }         
    }
    
    public void GetAllCertificates() {
        try {
            //this.title = '';
            this.hasError = false;
            this.showMessage = false;
            // get target certificate root cert or intermediate cert - all certificates with same parent
            for(Account targertAcc : [select Id, ParentId, Name, Friendly_Name__c, Type,
                                    SHA_1_Fingerprint__c, SHA_256__c,
                                    Trust_bits__c, Microsoft_Trust_Bits__c,
                                    Revocation_Status__c, Date_of_Revocation__c, RFC_5280_Revocation_Reason_Code__c,
                                    Audits_Same_as_Parent__c, Standard_Audit__c, 
                                    Standard_Audit_Type__c, Standard_Audit_Statement_Date__c, 
                                    Standard_Audit_Period_Start_Date__c, Standard_Audit_Period_End_Date__c,
                                    Code_Signing_Audit__c, Code_Signing_Audit_Type__c, Code_Signing_Audit_Statement_Date__c,
                                    Code_Signing_Audit_Period_Start_Date__c, Code_Signing_Audit_Period_End_Date__c,
                                    BR_Audit__c, BR_Audit_Type__c, BR_Audit_Statement_Date__c, 
                                    BR_Audit_Period_Start_Date__c, BR_Audit_Period_End_Date__c,
                                    EV_Audit__c, EV_Audit_Type__c, EV_Audit_Statement_Date__c, 
                                    EV_Audit_Period_Start_Date__c, EV_Audit_Period_End_Date__c,
                                    EV_Code_Signing_Audit__c, EV_Code_Signing_Audit_Type__c, EV_Code_Signing_Audit_Statement_Date__c,
                                    EV_Code_Signing_Audit_Period_Start_Date__c, EV_Code_Signing_Audit_Period_End_Date__c,  
                                    Auditor_New__c, Auditor_New__r.Name, Auditor_Location_New__c, Auditor_Location_New__r.Name,                            
                                    Auditor__c, Auditor_Website__c, Auditor_Qualifications__c,
                                    CP_CPS_Same_as_Parent__c, Policy_Documentation__c, CA_Document_Repository__c,                                   
                                    Certificate_Policy_CP__c, Certification_Practice_Statement_CPS__c, CP_CPS_Last_Updated_Date__c,                               
                                    Mozilla_Verified_Audit_Date__c, Microsoft_Verified_Audit_Date__c,
                                    EV_Policy_OID_s__c, Microsoft_EV_Enabled__c,
                                    Do_NOT_Send_Audit_Reminder__c, Microsoft_Do_NOT_Send_Audit_Reminder__c,
                                    Status__c, Microsoft_Status__c , Removal_Bug_No_or_Date__c
                                    from Account
                                    where ParentId = :sourceAccountSo.ParentId AND Id != :sourceAccountSo.Id]){
                                            
                                 
                 if(isDiffAccount(sourceAccountSo, targertAcc)){
                     continue; // ignore certificates which have matching fields
                 }
              
              // if source fields and target fields do not match add to the list
              lstSiblingAccounts.add(targertAcc); 
            }             
         }catch(Exception exp){
             this.hasError = true;
             this.showMessage = true;
             this.title = 'Unexpected Error Occurred, Please contact your administrator.';
             
             // system.debug('cause = ' + exp.getCause());
             // system.debug('LineNumber = ' + exp.getLineNumber());
             // system.debug('Message = ' + exp.getMessage());
             // system.debug('StractTrace = ' + exp.getStackTraceString());            
             // ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Unexpected Error Occurred, Please contact your administrator.'));
         }                     
                              
        if(lstSiblingAccounts != null && lstSiblingAccounts.size() > 0){
            this.totaltargetAccountCount = lstSiblingAccounts.size();
            this.targetAccountSo = lstSiblingAccounts[recordIndex];
            // recordIndex++; commented by Poonam
        }else{
            this.hasError = true;
            this.targetAccountSo = new Account();
            this.showMessage = true;
            this.title = 'No certs to update.';
            // ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ''));
        }  
    }

    // Portal users can run mass update on the intermediate certs which are associate with their CA Owner
    public void checkPortalUserValidation(){
        
        CreateIntermediateCertController objToCheckUserValidation = new CreateIntermediateCertController(new ApexPages.standardController(this.sourceAccountSo));
        if(!objToCheckUserValidation.isValidPortalUser()){
            this.hasError = true;
            this.isValidPortalUser = false;
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Please select a Root Cert or Intermediate Cert owned by ' + objToCheckUserValidation.userAccountName));    
        }
        
    }
    
    // return false if the source fields and target fields do not match
    private Boolean isDiffAccount(sObject source, sObject target){
    
        for(String fieldApi : fields){
        
            // System.debug('source: '+source.get(fieldApi)+' --> target: '+target.get(fieldApi));
 

            if(source.get(fieldApi) != target.get(fieldApi)){                          
                return False;
            }          
            // for users with Mozilla profile show certs which do not match on Verified Date
            if (this.isMozillaProfile &&  (source.get('Mozilla_Verified_Audit_Date__c') != target.get('Mozilla_Verified_Audit_Date__c'))) {
                return False;             
            } 
            // for users with Microsoft profile show certs which do not match on Verified Date
            if (this.isMicrosoftProfile  &&  (source.get('Microsoft_Verified_Audit_Date__c') != target.get('Microsoft_Verified_Audit_Date__c'))) {
                return False;
            } 
        }
        
        return true;
    }
    
    /* redirect to source Cert */
    public pagereference redirectToAccount(){
        return new PageReference('/'+this.sourceAccountSo.Id);
    }
    
    /******* syncAccout() is NOT USED. Sync fields are split into separate sections. ******
    
    // update the target account and redirect to same page showing that the record got updated successfully
    public void syncAccount() {
         
         this.showConfirmation = false;
         
         // Audit fields
         this.targetAccountSo.Audits_Same_as_Parent__c                = this.sourceAccountSo.Audits_Same_as_Parent__c;
         this.targetAccountSo.Standard_Audit__c                       = this.sourceAccountSo.Standard_Audit__c;
         this.targetAccountSo.Standard_Audit_Type__c                  = this.sourceAccountSo.Standard_Audit_Type__c;   
         this.targetAccountSo.Standard_Audit_Statement_Date__c        = this.sourceAccountSo.Standard_Audit_Statement_Date__c;
         this.targetAccountSo.BR_Audit__c                             = this.sourceAccountSo.BR_Audit__c;
         this.targetAccountSo.BR_Audit_Type__c                        = this.sourceAccountSo.BR_Audit_Type__c;   
         this.targetAccountSo.BR_Audit_Statement_Date__c              = this.sourceAccountSo.BR_Audit_Statement_Date__c;
         this.targetAccountSo.EV_Audit__c                             = this.sourceAccountSo.EV_Audit__c;
         this.targetAccountSo.EV_Audit_Type__c                        = this.sourceAccountSo.EV_Audit_Type__c;   
         this.targetAccountSo.EV_Audit_Statement_Date__c              = this.sourceAccountSo.EV_Audit_Statement_Date__c;
         // this.targetAccountSo.Auditor__c                           = this.sourceAccountSo.Auditor__c;
         // this.targetAccountSo.Auditor_Website__c                   = this.sourceAccountSo.Auditor_Website__c;
         // this.targetAccountSo.Auditor_Qualifications__c            = this.sourceAccountSo.Auditor_Qualifications__c; 
         this.targetAccountSo.Management_Assertions_By__c             = this.sourceAccountSo.Management_Assertions_By__c;  
         
         // Policy Fields
         this.targetAccountSo.CP_CPS_Same_as_Parent__c                = this.sourceAccountSo.CP_CPS_Same_as_Parent__c;
         this.targetAccountSo.Policy_Documentation__c                 = this.sourceAccountSo.Policy_Documentation__c;
         this.targetAccountSo.CA_Document_Repository__c               = this.sourceAccountSo.CA_Document_Repository__c;
         this.targetAccountSo.Certificate_Policy_CP__c                = this.sourceAccountSo.Certificate_Policy_CP__c;
         this.targetAccountSo.Certification_Practice_Statement_CPS__c = this.sourceAccountSo.Certification_Practice_Statement_CPS__c;
         
         // Verified Audti Date Field, to be updated by users with profile 'Standard User - Mozilla'only
         this.targetAccountSo.Mozilla_Verified_Audit_Date__c = this.sourceAccountSo.Mozilla_Verified_Audit_Date__c; 
         
         // Verified Audti Date Field, to be updated by users with profile 'Standard User - Microsoft' only
         this.targetAccountSo.Microsoft_Verified_Audit_Date__c = this.sourceAccountSo.Microsoft_Verified_Audit_Date__c;
        
         // System.debug('DEBUGSOURCE: '+sourceAccountSo);
         // System.debug('DEBUGSOURCE: '+targetAccountSo);
                 
        try{
            update targetAccountSo;
        }catch(Exception exp){
            this.hasError = true;
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Error Occurred while updating the account.'));
        }
    } **************/
    
   // update the target account and redirect to same page showing that the record got updated successfully
   public void syncAuditorNewFieldsOnTargetAccount() {
         
         this.showAuditorNewFieldsConfirmation= false;
         
         // Auditor (New) fields
         this.targetAccountSo.Auditor_New__c                = this.sourceAccountSo.Auditor_New__c;
         this.targetAccountSo.Auditor_Location_New__c       = this.sourceAccountSo.Auditor_Location_New__c;
                   
        try{
            update targetAccountSo;
            //query added by Sunil
            this.targetAccountSo = [select Id, ParentId, Name, Friendly_Name__c, Type,
                                    SHA_1_Fingerprint__c, SHA_256__c,
                                    Trust_bits__c, Microsoft_Trust_Bits__c,
                                    Revocation_Status__c, Date_of_Revocation__c, RFC_5280_Revocation_Reason_Code__c,
                                    Audits_Same_as_Parent__c, Standard_Audit__c, 
                                    Standard_Audit_Type__c, Standard_Audit_Statement_Date__c, 
                                    Standard_Audit_Period_Start_Date__c, Standard_Audit_Period_End_Date__c,
                                    Code_Signing_Audit__c, Code_Signing_Audit_Type__c, Code_Signing_Audit_Statement_Date__c,
                                    Code_Signing_Audit_Period_Start_Date__c, Code_Signing_Audit_Period_End_Date__c,
                                    BR_Audit__c, BR_Audit_Type__c, BR_Audit_Statement_Date__c, 
                                    BR_Audit_Period_Start_Date__c, BR_Audit_Period_End_Date__c,
                                    EV_Audit__c, EV_Audit_Type__c, EV_Audit_Statement_Date__c, 
                                    EV_Audit_Period_Start_Date__c, EV_Audit_Period_End_Date__c,
                                    EV_Code_Signing_Audit__c, EV_Code_Signing_Audit_Type__c, EV_Code_Signing_Audit_Statement_Date__c,
                                    EV_Code_Signing_Audit_Period_Start_Date__c, EV_Code_Signing_Audit_Period_End_Date__c,  
                                    Auditor_New__c, Auditor_New__r.Name, Auditor_Location_New__c, Auditor_Location_New__r.Name,                            
                                    Auditor__c, Auditor_Website__c, Auditor_Qualifications__c,
                                    CP_CPS_Same_as_Parent__c, Policy_Documentation__c, CA_Document_Repository__c,                                   
                                    Certificate_Policy_CP__c, Certification_Practice_Statement_CPS__c, CP_CPS_Last_Updated_Date__c,                               
                                    Mozilla_Verified_Audit_Date__c, Microsoft_Verified_Audit_Date__c,
                                    EV_Policy_OID_s__c, Microsoft_EV_Enabled__c,
                                    Do_NOT_Send_Audit_Reminder__c, Microsoft_Do_NOT_Send_Audit_Reminder__c,
                                    Status__c, Microsoft_Status__c , Removal_Bug_No_or_Date__c
                                    from Account
                                    where Id =: targetAccountSo.Id];
        }catch(Exception exp){
            this.hasError = true;
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Error Occurred while updating Auditor fields on the account.'));
        }
    }
       
   // update the target account and redirect to same page showing that the record got updated successfully
   public void syncStdAuditFieldsOnTargetAccount() {
         
         this.showStdAuditFieldsConfirmation= false;
         
         // Auditor fields
         // this.targetAccountSo.Auditor__c                = this.sourceAccountSo.Auditor__c;
         // this.targetAccountSo.Auditor_Website__c        = this.sourceAccountSo.Auditor_Website__c;
         // this.targetAccountSo.Auditor_Qualifications__c = this.sourceAccountSo.Auditor_Qualifications__c; 
         //this.targetAccountSo.Management_Assertions_By__c  = this.sourceAccountSo.Management_Assertions_By__c;          
            
         // Audit fields
         this.targetAccountSo.Audits_Same_as_Parent__c                = this.sourceAccountSo.Audits_Same_as_Parent__c;
         this.targetAccountSo.Standard_Audit__c                       = this.sourceAccountSo.Standard_Audit__c;
         this.targetAccountSo.Standard_Audit_Type__c                  = this.sourceAccountSo.Standard_Audit_Type__c;   
         this.targetAccountSo.Standard_Audit_Statement_Date__c        = this.sourceAccountSo.Standard_Audit_Statement_Date__c;
         this.targetAccountSo.Standard_Audit_Period_Start_Date__c     = this.sourceAccountSo.Standard_Audit_Period_Start_Date__c;
         this.targetAccountSo.Standard_Audit_Period_End_Date__c       = this.sourceAccountSo.Standard_Audit_Period_End_Date__c;

                 
        try{
            update targetAccountSo;
        }catch(Exception exp){
            this.hasError = true;
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Error Occurred while updating Audit fields on the account.'));
        }
    }
    
    // update the code signing on target account and redirect to same page showing that the record got updated successfully
   public void syncCodeSigningAuditFieldsOnTargetAccount() {
         
         this.showCodeSigningAuditFieldsConfirmation= false;
         
         // BR Audit fields
         this.targetAccountSo.Code_Signing_Audit__c         = this.sourceAccountSo.Code_Signing_Audit__c;
         this.targetAccountSo.Code_Signing_Audit_Type__c    = this.sourceAccountSo.Code_Signing_Audit_Type__c;   
         this.targetAccountSo.Code_Signing_Audit_Statement_Date__c   = this.sourceAccountSo.Code_Signing_Audit_Statement_Date__c;
         this.targetAccountSo.Code_Signing_Audit_Period_Start_Date__c = this.sourceAccountSo.Code_Signing_Audit_Period_Start_Date__c;
         this.targetAccountSo.Code_Signing_Audit_Period_End_Date__c   = this.sourceAccountSo.Code_Signing_Audit_Period_End_Date__c;
                   
        try{
            update targetAccountSo;
        }catch(Exception exp){
            this.hasError = true;
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Error Occurred while updating BR Audit fields on the account.'));
        }
    }
    
  // update the target account and redirect to same page showing that the record got updated successfully
   public void syncBRAuditFieldsOnTargetAccount() {
         
         this.showBRAuditFieldsConfirmation= false;
         
         // BR Audit fields
         this.targetAccountSo.BR_Audit__c                   = this.sourceAccountSo.BR_Audit__c;
         this.targetAccountSo.BR_Audit_Type__c              = this.sourceAccountSo.BR_Audit_Type__c;   
         this.targetAccountSo.BR_Audit_Statement_Date__c    = this.sourceAccountSo.BR_Audit_Statement_Date__c;
         this.targetAccountSo.BR_Audit_Period_Start_Date__c = this.sourceAccountSo.BR_Audit_Period_Start_Date__c;
         this.targetAccountSo.BR_Audit_Period_End_Date__c   = this.sourceAccountSo.BR_Audit_Period_End_Date__c;
                   
        try{
            update targetAccountSo;
        }catch(Exception exp){
            this.hasError = true;
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Error Occurred while updating BR Audit fields on the account.'));
        }
    }
    
   // update the target account and redirect to same page showing that the record got updated successfully
   public void syncEVSSLAuditFieldsOnTargetAccount() {
         
         this.showEVSSLAuditFieldsConfirmation= false;
         
         // EV SSL Audit fields
         this.targetAccountSo.EV_Audit__c                   = this.sourceAccountSo.EV_Audit__c;
         this.targetAccountSo.EV_Audit_Type__c              = this.sourceAccountSo.EV_Audit_Type__c;   
         this.targetAccountSo.EV_Audit_Statement_Date__c    = this.sourceAccountSo.EV_Audit_Statement_Date__c;
         this.targetAccountSo.EV_Audit_Period_Start_Date__c = this.sourceAccountSo.EV_Audit_Period_Start_Date__c;
         this.targetAccountSo.EV_Audit_Period_End_Date__c   = this.sourceAccountSo.EV_Audit_Period_End_Date__c;
                   
        try{
            update targetAccountSo;
        }catch(Exception exp){
            this.hasError = true;
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Error Occurred while updating EV SSL Audit fields on the account.'));
        }
    }
 
  // update the target account and redirect to same page showing that the record got updated successfully
   public void syncEVCodeSigningAuditFieldsOnTargetAccount() {
         
         this.showEVCodeSigningAuditFieldsConfirmation= false;
         
         // EV Code Signing Audit fields
         this.targetAccountSo.EV_Code_Signing_Audit__c                   = this.sourceAccountSo.EV_Code_Signing_Audit__c;
         this.targetAccountSo.EV_Code_Signing_Audit_Type__c              = this.sourceAccountSo.EV_Code_Signing_Audit_Type__c;   
         this.targetAccountSo.EV_Code_Signing_Audit_Statement_Date__c    = this.sourceAccountSo.EV_Code_Signing_Audit_Statement_Date__c;
         this.targetAccountSo.EV_Code_Signing_Audit_Period_Start_Date__c = this.sourceAccountSo.EV_Code_Signing_Audit_Period_Start_Date__c;
         this.targetAccountSo.EV_Code_Signing_Audit_Period_End_Date__c   = this.sourceAccountSo.EV_Code_Signing_Audit_Period_End_Date__c;
                   
        try{
            update targetAccountSo;
        }catch(Exception exp){
            this.hasError = true;
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Error Occurred while updating EV Code Signing Audit fields on the account.'));
        }
    }
              
 
   public void syncPolicyFieldsOnTargetAccount() {
         this.showPolicyFieldsConfirmation= false;
         
         // Policy Fields
         this.targetAccountSo.CP_CPS_Same_as_Parent__c                = this.sourceAccountSo.CP_CPS_Same_as_Parent__c;
         this.targetAccountSo.Policy_Documentation__c                 = this.sourceAccountSo.Policy_Documentation__c;
         this.targetAccountSo.CA_Document_Repository__c               = this.sourceAccountSo.CA_Document_Repository__c;
         this.targetAccountSo.Certificate_Policy_CP__c                = this.sourceAccountSo.Certificate_Policy_CP__c;
         this.targetAccountSo.Certification_Practice_Statement_CPS__c = this.sourceAccountSo.Certification_Practice_Statement_CPS__c;
         this.targetAccountSo.CP_CPS_Last_Updated_Date__c             = this.sourceAccountSo.CP_CPS_Last_Updated_Date__c;
         
        try{
            update targetAccountSo;
        }catch(Exception exp){
            this.hasError = true;
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Error Occurred while updating policy fields on target record.'));
        }
    }

 
  public void syncMozillaFieldsOnTargetAccount() {
         
         this.showMozillaFieldsConfirmation= false;
         
         // Verified Audti Date Field, to be updated by users with profile 'Standard User - Mozilla'only
         this.targetAccountSo.Mozilla_Verified_Audit_Date__c = this.sourceAccountSo.Mozilla_Verified_Audit_Date__c; 
         
         
        try{
            update targetAccountSo;
        }catch(Exception exp){
            this.hasError = true;
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Error Occurred while updating Mozilla Verified Audit Date on target record.'));
        }
    }

    
    public void syncMicrosoftFieldsOnTargetAccount() {
         
         this.showMicrosoftFieldsConfirmation= false;
         
         // Verified Audti Date Field, to be updated by users with profile 'Standard User - Microsoft' only
         this.targetAccountSo.Microsoft_Verified_Audit_Date__c = this.sourceAccountSo.Microsoft_Verified_Audit_Date__c;
                         
        try{
            update targetAccountSo;
        }catch(Exception exp){
            this.hasError = true;
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Error Occurred while updating Microsoft Verified Audit Date the target record.'));
        }
    }

 
    public void redirectToNextAccount(){
        nextAccount();
        this.showConfirmation = true;
    }
    
    public Pagereference redirectFromLandingPage()
    
    {
     return new PageReference('/apex/MassUpdateAuditCPCPSData?id='+this.sourceAccountSo.Id);
    }
    
    public PageReference redirectTosourceAccount(){
        return new PageReference('/'+this.sourceAccountSo.Id);
    }
    
    public void nextAccount(){
        
        recordIndex = recordIndex + 1;
        // system.debug('record Index: '+recordIndex+' -> size: '+this.lstSiblingAccounts.size());
        system.debug('recordIndex ::: '+recordIndex);
        if(recordIndex < this.lstSiblingAccounts.size()){ 
             this.targetAccountSo = this.lstSiblingAccounts[recordIndex];
        }
        else{
            this.title = 'No more certificates to update';
            this.showMessage = true;
            //set false when no more record found
            this.isMoreRecordFound = false;
            recordIndex--;
            // this.recordIndex = this.lstSiblingAccounts.size();
        }  
        
         this.showAuditorNewFieldsConfirmation = true;
         this.showStdAuditFieldsConfirmation = true;
         this.showCodeSigningAuditFieldsConfirmation = true;
         this.showBRAuditFieldsConfirmation = true;
         this.showEVSSLAuditFieldsConfirmation = true;
         this.showEVCodeSigningAuditFieldsConfirmation = true;
         this.showPolicyFieldsConfirmation = true;
         this.showMozillaFieldsConfirmation = true;
         this.showMicrosoftFieldsConfirmation = true;

    }
    

    // get user's profile name
    private String getCurrentProfileName() {
     Id profileId=userinfo.getProfileId();
      return [Select Id,Name from Profile where Id=:profileId].Name;  
    }
}
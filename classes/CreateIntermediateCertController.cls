/****

*** THIS PROGRAM HAS BEEN OBSOLETED on 2/19/2020 *** 
*** Another program CreateCertUsingPEMCtrl is being used which is a one-step process ***

 Description: Controller class for the CreateIntermediateCert VF page. 
 
 This page is invoked when the user clicks on the "Create Intermediate Cert" & "Add/Update PEM Info" buttons from
 the intermediate cert records. The page would prompt the user to enter the PEM info. If the PEM info is provided, 
 cert checker webservice is invoked and new intermediate cert is populated with response details.
 The 'Clone' button also uses this controller.
 
 Update Log:
 02/13/2018 - Commented code in createintermediatecert for redirect to add/update pem info page. Called that page from Add/Update PEM info button.
 
 **THIS PROGRAM IS NOT USING ANYWHERE** As we recreated a program to create Intermediate cert using PEM this program is not useful.
***/

global with sharing class CreateIntermediateCertController{

    // var which holds the PEM info entered by the user
    public String pemInfoStr {get;set;}
    
    // extraction results returned after processing pem info
    public String extractionResultsStr {get;set;}
    
    // the reference of the record from which the button was clicked
    public Account currentAccountRecordSo {get;set;}
    
    // the record id from which the create intermediate cert button was clicked
    // this would be set as the parent of the intermediate cert
    public Id parentAccountId {get;set;}
    
    public Boolean showBackButton {get;set;}
    
    public Boolean isUpdatePEMInfoFlow {get;set;}
    
    Account intermediateCertSO;
    
    public Boolean isCertCheckSuccessful {get;set;}
    
    private Account accountRecordSo;
    
    private boolean isPEMOverlong;
    
    public boolean isProceedAnywaySameExtraction;
    
    // holds the user's.contact.account.name
    public String userAccountName; //axay: made it public because 'MassUpdateAuditCPCPCDataController' uses isValidPortalUser method
    
    private Boolean isPortalUser;
    
    public Boolean showCPSOverwriteMessage {get;set;}
    
    //property used to enable/disble update button
    public Boolean disableUpdateButton{get; set;}
    
    // constructor
    public CreateIntermediateCertController(ApexPages.StandardController stdController) {
    
        // get the parentId from the URL param
        parentAccountId= ApexPages.currentPage().getParameters().get('id');
        
        showBackButton = false;
        this.disableUpdateButton = false;
        isPortalUser = false; 
        isPEMOverlong = false;
        showCPSOverwriteMessage= false;
        isProceedAnywaySameExtraction = false;
        
        this.currentAccountRecordSo = (Account)stdController.getRecord();
        
        accountRecordSo = [select name, parentid, recordTypeId, 
                    Standard_Audit__c,Standard_Audit_Type__c,Standard_Audit_Statement_Date__c,
                    Code_Signing_Audit__c,Code_Signing_Audit_Type__c,Code_Signing_Audit_Statement_Date__c, 
                    BR_Audit__c, BR_Audit_Type__c, BR_Audit_Statement_Date__c, 
                    EV_Audit__c,EV_Audit_Type__c, EV_Audit_Statement_Date__c, 
                    Auditor__c, Auditor_Website__c, Auditor_Qualifications__c, 
                    Policy_Documentation__c, CA_Document_Repository__c, 
                    Certificate_Policy_CP__c, Certification_Practice_Statement_CPS__c,
                    Comments__c
                    from Account 
                    where id =:currentAccountRecordSo.id limit 1];
        
        String isUpdatePEMInfoFlowParam =    ApexPages.currentPage().getParameters().get('updatePEMInfo');
        if(isUpdatePEMInfoFlowParam!=null && isUpdatePEMInfoFlowParam.length() > 0 && isUpdatePEMInfoFlowParam.equals('true'))
        { 
            isUpdatePEMInfoFlow = true;  
        }
        else
        {
            isUpdatePEMInfoFlow = false;   
        }
    
    } 
    
    
    public PageReference updateIntermediateCert() {
    
        // if certChecker returns '<Fill in Cert Name>' then keep the current account name
        if (intermediateCertSo.name == '<Fill in Cert Name>') { 
            intermediateCertSo.name = accountRecordSo.name;
        } 
        
        intermediateCertSo.id = parentAccountId;
        
        // do not save PEM Info if longer than 10000 chars; Add Comments 
        if(isPEMOverlong) {   
            intermediateCertSo.X_509_Certificate_PEM__c = '';
            intermediateCertSo.Comments__c = 'PEM too large to save directly in CCADB.';
        }  else {
            intermediateCertSo.X_509_Certificate_PEM__c = pemInfoStr;
        }
        
        intermediateCertSO.Display_PEM_Info_Warning_Message__c=false; 
        
        try{
        
        // Updating the intermediate record only if the extraction resuts are different
        //changed logic proceed anyways when same extraction results.
        List<Account> lstAccount = new List<Account>([Select Id,Extraction_Results__c from Account Where Id =: parentAccountId]);
        if(!isProceedAnywaySameExtraction && lstAccount.size() > 0 && lstAccount[0].Extraction_Results__c == intermediateCertSo.Extraction_Results__c){
            string errorMessage = 'This PEM data has produced the same \'Extraction Results\' as earlier. Hit \'Update Cert\' again to proceed anyways. <br/>';
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, errorMessage));
            isProceedAnywaySameExtraction = true; 
            //this.disableUpdateButton = true;
            return null;
        } else {
            update intermediateCertSo; 
        }         
        
        }catch(Exception ex){
            this.disableUpdateButton = true;
            
            String errorMessage;
            if (ex.getDmlType(0) == StatusCode.DUPLICATES_DETECTED) {
                errorMessage = 'Update Failed. Update would result in a duplicate Intermediate Certificate. Please use the existing record ' + intermediateCertSo.name; 
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, errorMessage));   
            }
            // else if (ex.getDmlType(0) == StatusCode.FIELD_CUSTOM_VALIDATION_EXCEPTION) {
            //   errorMessage = 'This PEM data has produced the same \'Extraction Results\' as earlier, so no updates are necessary. Hit \'Cancel\' to return. <br/>';
            //   ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, errorMessage));
            // }
            else {
                errorMessage = 'Error processing!! Please contact your administrator.<br/>' + ex.getMessage();
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, errorMessage));  
            }
            
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, errorMessage));
            showBackButton=true;
            return null;
        }     
    
        // PageReference interCertRecordEditModePage= isPortalUser == true ? new PageReference('/CACommunity/' + intermediateCertSo.id) : new PageReference('/' + intermediateCertSo.id);
        PageReference interCertRecordEditModePage= new PageReference('/' + intermediateCertSo.id);
        interCertRecordEditModePage.setRedirect(true);
        
        return interCertRecordEditModePage;
    }
    
    public PageReference createIntermediateCert() {
        if(!isValidPortalUser())
        {
            ApexPages.Message apexMessage = new ApexPages.Message(ApexPages.Severity.Error, 'Please select a Root Cert or Intermediate Cert owned by ' + userAccountName);
            ApexPages.addMessage(apexMessage);
            showBackButton=true;
            return null;
        }
        
        /*if(isUpdatePEMInfoFlow)
        {
        // system.debug('##IsPortalUser='+isPortalUser);
        // PageReference interCertRecordEditModePage= isPortalUser == true ?  new PageReference('/CACommunity/apex/UpdatePemInfoOnInterCert?id=' + parentAccountId + '&updatePEMInfo=true') : new PageReference('/apex/UpdatePemInfoOnInterCert?id=' + parentAccountId + '&updatePEMInfo=true');
        PageReference interCertRecordEditModePage= new PageReference('/apex/UpdatePemInfoOnInterCert?id=' + parentAccountId + '&updatePEMInfo=true');
        
        interCertRecordEditModePage.setRedirect(true);
        return interCertRecordEditModePage;       
        }
        else
        {*/
        
        isCertCheckSuccessful=false; 
        
        intermediateCertSO = New Account(); 
        
        // set the parentid
        intermediateCertSO.parentId = parentAccountId;
        //intermediateCertSO.name = [select id,name from account where id = :parentAccountId limit 1].name;
        intermediateCertSo.name = '<Fill in Cert Name>';
        intermediateCertSO.Display_PEM_Info_Warning_Message__c=true;
        // set the record type as intermediate cert
        intermediateCertSo.recordTypeId= Schema.SObjectType.Account.getRecordTypeInfosByName().get('Intermediate Certificate').getRecordTypeId();
        
        // set the pem info provided by the user
        // intermediateCertSo.X_509_Certificate_PEM__c = pemInfoStr;
        try
        {
            // create the intermediate cert record
            insert intermediateCertSo;
        }
        catch(Exception ex) {
            String errorMessage = ex.getDmlType(0) == StatusCode.DUPLICATES_DETECTED ? 'You are trying to create a duplicate Intermediate Certificate. Please use the existing record ' + intermediateCertSo.name : '';
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, errorMessage));
            showBackButton =true;
            return null;
        }
        // redirect the user to the inter cert record in edit mode
        // to redirect on standard layout just remove the e from below url 
        // PageReference interCertRecordEditModePage= isPortalUser == true ? new PageReference('/CACommunity/' + intermediateCertSo.id) : new PageReference('/' + intermediateCertSo.id);
        PageReference interCertRecordEditModePage= new PageReference('/' + intermediateCertSo.id);
        interCertRecordEditModePage.setRedirect(true);
        return interCertRecordEditModePage;
        //}
    }
    
    // method executed on the click on validate pem info
    // this method invokes the rest api and validates the pem info 
    // provided by the user and shows the corresponding success/error message on the page
    public PageReference submit() {
        try {
        
            if(!isValidPortalUser())
            {
                ApexPages.Message apexMessage = new ApexPages.Message(ApexPages.Severity.Error, 'Please select a Root Cert or Intermediate Cert owned by ' + userAccountName);
                ApexPages.addMessage(apexMessage);
                showBackButton=true;
                return null;
            }
            
            // throw an error if the pem info is not provided by the user
            if(pemInfoStr == null || pemInfoStr.length() == 0)
            {
                ApexPages.Message apexMessage = new ApexPages.Message(ApexPages.Severity.Error, 'Please provide PEM info else click the Cancel button.');
                ApexPages.addMessage(apexMessage);
                return null;
            } 
            
            // throw an error if the pem info is exceeding the field length 
            if(string.isnotblank(pemInfoStr) && pemInfoStr.length() >= 10000)
            {
                //added flag to check string length
                isPEMOverlong = true; 
                ApexPages.Message apexMessage = new ApexPages.Message(ApexPages.Severity.Warning, 'PEM is larger than 10,000 characters, so the PEM itself will not be saved. However, the fields that are extracted from the PEM will be updated.');
                ApexPages.addMessage(apexMessage);
                //return null;
            } 
            
            // throw an error if the pem info is missing "BEGIN CERTIFICATE" or "END CERTIFICATE" tags
            if(pemInfoStr.countmatches('BEGIN CERTIFICATE') == 0 || pemInfoStr.countmatches('END CERTIFICATE') == 0)
            {
                ApexPages.Message apexMessage = new ApexPages.Message(ApexPages.Severity.Error, 'PEM info does not have proper BEGIN CERTIFICATE/END CERTIFICATE format. Please re-enter PEM info.');
                ApexPages.addMessage(apexMessage);
                return null;    
            } 
            
            // throw an error if the pem info has more than one instance of "BEGIN CERTIFICATE" or "END CERTIFICATE"
            if(pemInfoStr.countmatches('BEGIN CERTIFICATE') > 1 && pemInfoStr.countmatches('END CERTIFICATE') > 1)
            {
                ApexPages.Message apexMessage = new ApexPages.Message(ApexPages.Severity.Error, 'Multiple occurance of "BEGIN CERTIFICATE" or "END CERTIFICATE" found in PEM info. Please re-enter PEM info.');
                ApexPages.addMessage(apexMessage);
                return null;
            } 
            
            // throw an error if the pem info does not have proper format for BEGIN/END tags 
            if(pemInfoStr.countmatches('-----BEGIN CERTIFICATE-----') != 1 || pemInfoStr.countmatches('-----END CERTIFICATE-----') != 1)
            {
                ApexPages.Message apexMessage = new ApexPages.Message(ApexPages.Severity.Error, 'PEM info does not have proper format for BEGIN/END tags. Please re-enter PEM info.');
                ApexPages.addMessage(apexMessage);
                return null;
            }
            
            // throw an error if the pem info has extra characters before '-----BEGIN CERTIFICATE-----' or after '-----END CERTIFICATE-----'
            if(!pemInfoStr.startsWith('-----BEGIN CERTIFICATE-----') || !pemInfoStr.endsWith('-----END CERTIFICATE-----')) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, 'PEM info has extra characters before "-----BEGIN CERTIFICATE-----" or after "-----END CERTIFICATE-----". Please re-enter PEM info.'));
                return null;
            } 
            
            // throw an error if the pem info has blank lines
            if(pemInfoStr.countmatches('\r\n\r\n') > 0) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, 'PEM info has extra blank lines. Please re-enter PEM info.'));
                return null;
            } 
            
            // invoke the cert checker webservice and get the response
            intermediateCertSO = X509CertificateCheckerUtility.x509CertChecker(pemInfoStr);
            
            // set extractionResultsStr with the value returned by the utility; used by VF page
            extractionResultsStr = intermediateCertSo.Extraction_Results__c;
            
            //show the error message if the webservice was not available
            if(intermediateCertSo.Display_Webservice_Not_Available__c)
            {      
                ApexPages.Message apexMessage = new ApexPages.Message(ApexPages.Severity.Error, 'The webservice for parsing cert data is unavailable at the current moment. Please try again later.');
                ApexPages.addMessage(apexMessage);
                return null;
            }
            
            // show the error message if there were errors parsing the pem info
            if(intermediateCertSo.Display_Webservice_Failed_Message__c)
            {      
                ApexPages.Message apexMessage = new ApexPages.Message(ApexPages.Severity.Error, 'Parsing of cert data has failed with errors. Please provide correct PEM format for the Intermediate cert.');
                ApexPages.addMessage(apexMessage);
                return null;
            }
            
            // show the error message if the extraction results do not have fields
            if(intermediateCertSo.Extraction_Results__c == '{}')
            {      
                ApexPages.Message apexMessage = new ApexPages.Message(ApexPages.Severity.Error, 'Parsing of cert data has failed. Please provide correct PEM format for the Intermediate cert.' + ' Extraction Results: ' + intermediateCertSo.Extraction_Results__c);
                ApexPages.addMessage(apexMessage);
                return null;
            }
            
            // show the error message if the extraction results does not look right
            if(!intermediateCertSo.Extraction_Results__c.contains('issuerCN'))
            {      
                ApexPages.Message apexMessage = new ApexPages.Message(ApexPages.Severity.Error, 'Parsing of cert data has failed. Please provide correct PEM format for the Intermediate cert.' + ' Extraction Results: ' + intermediateCertSo.Extraction_Results__c);
                ApexPages.addMessage(apexMessage);
                return null;
            }
            
            // Only allow Root certs and Inter certs to be added - in other word only allow certs that are capable of issuing certs;
            // Do not allow End Entities that is not capable of issuing certificates; End Entities are certs with "basicConstraints":"cA: false"
            // One of the following must be true, in order for the PEM to succeed:
            // 1) "basicConstraints":"cA: true"
            // 2) "keyUsage" contains "keyCertSign"
            
            /*if(!(intermediateCertSo.Basic_Constraints__c.equals('cA: true') || intermediateCertSo.Key_Usage__c.contains('keyCertSign')))
            {      
                ApexPages.Message apexMessage = new ApexPages.Message(ApexPages.Severity.Error, '<br />Only certificates that have Basic Constraints: CA=TRUE or the Key Usage keyCertSign bit set may be uploaded to the CCADB. Please enter different PEM data for issuing intermediate certificates or click on the Cancel button to go back.' + '<br /><br />Extraction Results:<br />' + intermediateCertSo.Extraction_Results__c.replace('\r\n','<br />')+ '<br />');  
                ApexPages.addMessage(apexMessage);
                return null;
            }  */
            
            // if certificate is technically constrained, show error message.
            if(intermediateCertSo.Technically_Constrained__c){
                this.isCertCheckSuccessful = true;
                this.disableUpdateButton = true;
                ApexPages.Message apexMessage = new ApexPages.Message(ApexPages.Severity.WARNING, '<br/><font color="red">This certificate is considered to be technically-constrained. All data that you enter into the CCADB will be publicly available, so please make sure you do not enter sensitive information that should not be published.</font><br/><br/><input type="checkbox" onclick="showUpdateButton();" />&nbsp;&nbsp;&nbsp;&nbsp;I understand, proceed anyways.');
                ApexPages.addMessage(apexMessage);
                return null;
            }          
            
            // show success message if there were no errors
            ApexPages.addMessage(
            new ApexPages.Message(ApexPages.Severity.Confirm,'Cert Check is successful. Please proceed by clicking on the \'Update Intermediate Cert\' button.'));
            
            // set the boolean flag to show/hide buttons accordingly     
            isCertCheckSuccessful=true;
            
            return null; 
        }
        catch (Exception ex) {
            // throw exception messages
            ApexPages.addMessages(ex);
        
        }
        return null;  
    
    }
    
    // when the user does not provide any pem info 
    // simply create the inter cert record and set the name and parentid
    public PageReference skip() {
    
        Account intermediateCertSO = new Account();
        intermediateCertSO.parentId = parentAccountId;
        intermediateCertSO.name = [select id,name from account where id = :parentAccountId limit 1].name;
        intermediateCertSo.recordTypeId= Schema.SObjectType.Account.getRecordTypeInfosByName().get('Intermediate Certificate').getRecordTypeId();
        
        try{
            insert intermediateCertSo;
        } catch(DmlException ex){
            String errorMessage = ex.getDmlType(0) == StatusCode.DUPLICATES_DETECTED ? 'You are trying to create a duplicate Intermediate Certificate. Please use the existing record ' + intermediateCertSo.name : '';
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, errorMessage));
            showBackButton=true;
            return null;
        }
        
        // PageReference interCertRecordEditModePage= isPortalUser == true ? new PageReference('/CACommunity/' + intermediateCertSo.id+'/e') : new PageReference('/' + intermediateCertSo.id+'/e');
        PageReference interCertRecordEditModePage= new PageReference('/' + intermediateCertSo.id+'/e');
        interCertRecordEditModePage.setRedirect(true);
        return interCertRecordEditModePage;
    
    }
    
    public PageReference overwriteParentAuditData() {
    
        Account parentAccountSo = [select Type, Standard_Audit__c,Standard_Audit_Type__c,Standard_Audit_Statement_Date__c,
                    Code_Signing_Audit__c,Code_Signing_Audit_Type__c,Code_Signing_Audit_Statement_Date__c,  
                    BR_Audit__c, BR_Audit_Type__c, BR_Audit_Statement_Date__c, EV_Audit__c,EV_Audit_Type__c, 
                    EV_Audit_Statement_Date__c, Auditor__c, Auditor_Website__c, Auditor_Qualifications__c,
                    Policy_Documentation__c, CA_Document_Repository__c, Certificate_Policy_CP__c,
                    Certification_Practice_Statement_CPS__c, Audits_Same_as_Parent__c, CP_CPS_Same_as_Parent__c
                    from Account where id =:accountRecordSo.parentId limit 1];
        
        // Copy Audits_Same_as_Parent and CP_CPS_Same_as_Parent fields only if parent record is intermediate cert  
        // Root Certificates do not use these fields, so it is irrelevant 
        if (parentAccountSo.Type == 'Intermediate Certificate') {
            accountRecordSo.Audits_Same_as_Parent__c = parentAccountSo.Audits_Same_as_Parent__c;    
            accountRecordSo.CP_CPS_Same_as_Parent__c = parentAccountSo.CP_CPS_Same_as_Parent__c; 
        }
        else
        {
            accountRecordSo.Audits_Same_as_Parent__c = false;    
            accountRecordSo.CP_CPS_Same_as_Parent__c = false; 
        }
        accountRecordSo.Standard_Audit__c = parentAccountSo.Standard_Audit__c;  
        accountRecordSo.Standard_Audit_Type__c = parentAccountSo.Standard_Audit_Type__c;  
        accountRecordSo.Standard_Audit_Statement_Date__c = parentAccountSo.Standard_Audit_Statement_Date__c; 
        accountRecordSo.Code_Signing_Audit__c = parentAccountSo.Code_Signing_Audit__c;  
        accountRecordSo.Code_Signing_Audit_Type__c = parentAccountSo.Code_Signing_Audit_Type__c; 
        accountRecordSo.Code_Signing_Audit_Statement_Date__c = parentAccountSo.Code_Signing_Audit_Statement_Date__c;
        accountRecordSo.BR_Audit__c = parentAccountSo.BR_Audit__c;  
        accountRecordSo.BR_Audit_Type__c = parentAccountSo.BR_Audit_Type__c; 
        accountRecordSo.BR_Audit_Statement_Date__c = parentAccountSo.BR_Audit_Statement_Date__c; 
        accountRecordSo.EV_Audit__c = parentAccountSo.EV_Audit__c; 
        accountRecordSo.EV_Audit_Type__c = parentAccountSo.EV_Audit_Type__c; 
        accountRecordSo.EV_Audit_Statement_Date__c = parentAccountSo.EV_Audit_Statement_Date__c;
        accountRecordSo.Auditor__c = parentAccountSo.Auditor__c; 
        accountRecordSo.Auditor_Website__c = parentAccountSo.Auditor_Website__c;
        accountRecordSo.Auditor_Qualifications__c = parentAccountSo.Auditor_Qualifications__c; 
        accountRecordSo.Policy_Documentation__c = parentAccountSo.Policy_Documentation__c;  
        accountRecordSo.CA_Document_Repository__c = parentAccountSo.CA_Document_Repository__c;  
        accountRecordSo.Certificate_Policy_CP__c = parentAccountSo.Certificate_Policy_CP__c;  
        accountRecordSo.Certification_Practice_Statement_CPS__c = parentAccountSo.Certification_Practice_Statement_CPS__c;
        
        
        try{
            update accountRecordSo;
        }catch(Exception exp){
            ApexPages.Message apexMessage = new ApexPages.Message(ApexPages.Severity.Error, exp.getMessage());
            ApexPages.addMessage(apexMessage);
            return null;
        }
        
        // PageReference interCertRecordPage= isPortalUser == true ? new PageReference('/CACommunity/' + accountRecordSo.id) : new PageReference('/' + accountRecordSo.id);
        PageReference interCertRecordPage= new PageReference('/' + accountRecordSo.id);
        interCertRecordPage.setRedirect(true);
        return interCertRecordPage;
    
    }
    
    
    //Copy audit fields
    public PageReference copyParentAuditData() {
    
        if(!isValidPortalUser())
        {
            ApexPages.Message apexMessage = new ApexPages.Message(ApexPages.Severity.Error, 'Please select a Intermediate Cert owned by ' + userAccountName);
            ApexPages.addMessage(apexMessage);
            showBackButton=true;
            return null;
        }
        
        if(accountRecordSo.parentId== null)
        {
            ApexPages.Message apexMessage = new ApexPages.Message(ApexPages.Severity.Error, 'Please click this button after populating the "Parent CA Owner/Certificate" field on the record.');
            ApexPages.addMessage(apexMessage);
            showBackButton=true;
            return null;
        } 
        
        else
        {
        
            if(accountRecordSo.Standard_Audit__c !=null ||  accountRecordSo.Standard_Audit_Type__c!=null || accountRecordSo.Standard_Audit_Statement_Date__c!=null || 
               accountRecordSo.Code_Signing_Audit__c!=null || accountRecordSo.Code_Signing_Audit_Type__c!=null || accountRecordSo.Code_Signing_Audit_Statement_Date__c!=null ||
               accountRecordSo.BR_Audit__c!=null || accountRecordSo.BR_Audit_Type__c!=null || accountRecordSo.BR_Audit_Statement_Date__c!=null || 
               accountRecordSo.EV_Audit__c!=null || accountRecordSo.EV_Audit_Type__c!=null || accountRecordSo.EV_Audit_Statement_Date__c!=null || 
               accountRecordSo.Auditor__c!=null || accountRecordSo.Auditor_Website__c!=null || accountRecordSo.Auditor_Qualifications__c!=null || 
               accountRecordSo.Policy_Documentation__c!=null || accountRecordSo.CA_Document_Repository__c!=null || 
               accountRecordSo.Certificate_Policy_CP__c!=null || accountRecordSo.Certification_Practice_Statement_CPS__c!=null)
            {
                ApexPages.Message apexMessage = new ApexPages.Message(ApexPages.Severity.Warning, 'Audit/CP/CPS data fields are already populated. Do you wish to overwrite these fields?');
                ApexPages.addMessage(apexMessage);
                showCPSOverwriteMessage =true; 
                return null;
            }
            return  overwriteParentAuditData();
        }
    }
    
    
    //clone the intermediate cert record and clear all the pem info field
    public PageReference cloneIntermediateCert() {
    
    if(!isValidPortalUser())
    {
    ApexPages.Message apexMessage = new ApexPages.Message(ApexPages.Severity.Error, 'Please select a Root Cert or Intermediate Cert owned by ' + userAccountName);
    ApexPages.addMessage(apexMessage);
    showBackButton=true;
    return null;
    }
    
    
    if(accountRecordSo.name == '<Fill in Cert Name>')
    {
    ApexPages.Message apexMessage = new ApexPages.Message(ApexPages.Severity.Error, 'Please make sure all the details are populated in the record before cloning it.');
    ApexPages.addMessage(apexMessage);
    showBackButton=true;
    return null;
    } 
    
    sObject originalSObject = (sObject) currentAccountRecordSo;
    
    List<sObject> originalSObjects = new List<sObject>{originalSObject};
    
    List<sObject> clonedSObjects = SObjectAllFieldCloner.cloneObjects(
    originalSobjects,
    originalSobject.getsObjectType());
    
    Account tempAccountSo= (Account)clonedSObjects.get(0);
    
    // do not clone PEM info
    tempAccountSo.name='<Fill in Cert Name>';
    tempAccountSo.Status__c='Provided by CA';  
    tempAccountSo.Certificate_Issuer_Common_Name__c = null;
    tempAccountSo.Certificate_Issuer_Organizational_Unit__c = null;
    tempAccountSo.Certificate_Issuer_Organization__c = null;
    tempAccountSo.Certificate_Subject_Common_Name__c = null;
    tempAccountSo.Certificate_Subject_Organization_Unit__c = null;
    tempAccountSo.Certificate_Subject_Organization__c =null; 
    tempAccountSo.OneCRL_Status__c = null;   
    tempAccountSo.SHA_1_Fingerprint__c =  null;
    tempAccountSo.SHA_256_Fingerprint__c = null;
    //tempAccountSo.Certificate_ID__c = null;
    tempAccountSo.Valid_From_GMT__c =  null;
    tempAccountSo.Valid_To_GMT__c =  null;  
    tempAccountSo.Certificate_Serial_Number__c = null;
    // tempAccountSo.Signature_Algorithm__c = null; replaced with Signature Hash Algorithm
    tempAccountSo.Signature_Hash_Algorithm__c = null;
    tempAccountSo.Public_Key_Algorithm__c = null;
    // tempAccountSo.Signing_Key_Parameters__c = null; replaced with Public Key Algorithm
    //tempAccountSo.Basic_Constraints__c =null;
    tempAccountSo.Key_Usage__c = null;
    tempAccountSo.Extended_Key_Usage__c = null;
    //tempAccountSo.OCSP_URL_s__c = null;
    tempAccountSo.CRL_URL_s__c = null;
    tempAccountSo.X_509_Certificate_PEM__c  =  null;
    tempAccountSo.Extraction_Results__c  =  null;
    tempAccountSo.technically_constrained__c = false;
    // do not clone Revocation info
    tempAccountSo.Revocation_Status__c = null;
    tempAccountSo.Date_of_Revocation__c = null;
    tempAccountSo.RFC_5280_Revocation_Reason_Code__c = null;
    // do not clone desc and Comments__c
    tempAccountSo.Comments__c = null;
    tempAccountSo.Comments_by_Mozilla_on_Intermediate__c = null;
    //do not copy audit internal links and status and messages
    tempAccountSo.Standard_Audit_Statement_Internal_Link__c = null;
    tempAccountSo.Standard_Audit_Update_Status__c = 'Not Processed';
    tempAccountSo.Standard_Audit_Update_Message__c = null;
    
    tempAccountSo.Code_Signing_Statement_Internal_Link__c = null;
    tempAccountSo.Code_Signing_Audit_Update_Status__c = 'Not Processed';
    tempAccountSo.Code_Signing_Audit_Update_Message__c = null;
    
    tempAccountSo.BR_Audit_Statement_Internal_Link__c = null;
    tempAccountSo.BR_Audit_Update_Status__c = 'Not Processed';
    tempAccountSo.BR_Audit_Update_Message__c = null;
    
    tempAccountSo.EV_Audit_Statement_Internal_Link__c = null;
    tempAccountSo.EV_Audit_Update_Status__c  = 'Not Processed';
    tempAccountSo.EV_Audit_Update_Message__c = null;
    
    tempAccountSo.EV_Code_Signing_Audit_Stmt_Int_Link__c = null;
    tempAccountSo.EV_Code_Signing_Audit_Update_Status__c = 'Not Processed';
    tempAccountSo.EV_Code_Signing_Audit_Update_Message__c = null;
    
    //do not copy test websites
    tempAccountSo.Test_Website_Expired__c = null;
    tempAccountSo.Test_Website_Revoked__c = null;
    tempAccountSo.Test_Website_Valid__c = null;
    
    //insert tempAccountSo;
    
    try{
    insert tempAccountSo;
    }catch(DmlException ex){
    String errorMessage = ex.getDmlType(0) == StatusCode.DUPLICATES_DETECTED ? 'You are trying to create a duplicate Intermediate Certificate. Please use the existing record ' + tempAccountSo.name : '';
    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, errorMessage));
    showBackButton=true;
    return null;
    }
    
    
    // PageReference parentRecordPage= isPortalUser == true ? new PageReference('/CACommunity/' + tempAccountSo.id): new PageReference('/' + tempAccountSo.id);
    PageReference parentRecordPage= new PageReference('/' + tempAccountSo.id);
    parentRecordPage.setRedirect(true);
    return parentRecordPage;
    
    
    
    }
    
    
    // user wants to abort the operation, redirect them to the record
    // from which they landed on this page
    public PageReference cancel() {
        Account intermediateCertSO = new Account();
        
        // PageReference parentRecordPage = isPortalUser == true ? new PageReference('/CACommunity/' + parentAccountId) : new PageReference('/' + parentAccountId);
        PageReference parentRecordPage = new PageReference('/' + parentAccountId);
        parentRecordPage.setRedirect(true);
        return parentRecordPage;
    
    }
    
    public boolean isValidPortalUser()
    { 
    
        // get the record type ID of the intermediate CA records
        Id intermediateCARecTypeId= Schema.SObjectType.Account.getRecordTypeInfosByName().get('Intermediate Certificate').getRecordTypeId();
        
        // get the record type ID of the root certificate records 
        Id rootCARecTypeId= Schema.SObjectType.Account.getRecordTypeInfosByName().get('Root Certificate').getRecordTypeId();
        
        // get the record type ID of the root certificate records 
        Id ownerCARecTypeId= Schema.SObjectType.Account.getRecordTypeInfosByName().get('CA Owner').getRecordTypeId();
        
        // get the ID of the current user
        Id currentUserId =    UserInfo.getUserId();
        
        // query the user details and check if it is a portal user and get the Owner account ID for that user
        List<User> userSoLst = [select IsPortalEnabled,contact.account.id,contact.account.name from user where id = :currentUserId];
        
        // intermediate cert can have only root/inter certs as their parents. this 
        // validation is done only for portal users
        if(userSoLst!=null && userSoLst.size() > 0 && userSoLst[0].isPortalEnabled)
        {
            // set which holds list of all valid parentIDs 
            Set<Id> rootCAIDSet = New Set<Id>();
            isPortalUser = true;
            List<Account> rootAccountSOLst = New List<Account>();
            
            // special case to handle the exceptional scenario for Symantec Accounts
            // When a portal user for any of Symantec Accounts (symantec or sy-geotrust or sy-verisign) 
            // logs in and creates an intermediate CA, they should be able to select the root certificate of any of these owner accounts
            Map<Id,Account> symantecAccountMap ;
            List<ID> currentParent      = new List<ID>{};
            // check if the portal user is associated with any of the symantec accounts
            if(userSoLst[0].contact!=null && userSoLst[0].contact.account.name.startsWith('Symantec'))
            {
                // get all the symantec owner accounts
                symantecAccountMap = New Map<Id,Account>([select id from account where name like 'Symantec%' and recordTypeId=:ownerCARecTypeId]);
                
                
                // get all the root CAs for these owner accounts
                rootAccountSOLst  = [select name from Account where parentId in :symantecAccountMap.keySet() and (recordTypeId=:rootCARecTypeId or recordTypeId = :intermediateCARecTypeId)  ];
                for(Id accountId : symantecAccountMap.keySet())
                {
                currentParent.add(accountId );      
                }
            }
            else
            {
                // non-symantec accounts 
                rootAccountSoLst = [select name from Account where parentId = :userSoLst[0].contact.accountid  and (recordTypeId=:rootCARecTypeId   or recordTypeId = :intermediateCARecTypeId )];
                currentParent.add(userSoLst[0].contact.accountid );
            }
            Boolean endOfStructure = false;
            
            List<Account> al            = new List<Account>{};
            Set<Id> recordIdSet= new Set<Id>(currentParent);
            while ( !endOfStructure ){
            
            
                al = [ SELECT id FROM Account a WHERE a.ParentID IN : CurrentParent ORDER BY a.Name ];            
                
                if( al.size() == 0 ){
                    endOfStructure = true;
                }
                else{
                    currentParent.clear();
                    for ( Integer i = 0 ; i < al.size(); i++ ){
                        //Change below
                        Account a = al[i];
                        currentParent.add( a.id );
                        recordIdSet.add(a.id);
                    }
                }
            }  
            // for each intermediate CA record if the parentId does not exist in the map of valid rootCA then throw an error.
            // if(accountSo.recordTypeId == intermediateCARecTypeId && (!rootCAIdSet.contains(accountSo.ParentId) || (Trigger.isUpdate && accountSo.parentId == accountso.id)))
            if((accountRecordSo.recordTypeId == intermediateCARecTypeId && !recordIdSet.contains(accountRecordSo.ParentId)) || Test.IsRunningTest())
            {
                userAccountName=userSoLst[0].contact.account.name;
                return false; 
            }
        }
        return true; 
    }
    
    // function used by javascript to re-render the buttons on the user acceptance of the technical constrained flag - this will toggle the button to enable/disable.
    public void showUpdateButton(){
    
        this.disableUpdateButton = !this.disableUpdateButton;
    }
 
}
/*******************************************************************************************************
 Name: CreateCertUsingPEMCtrl

 Dependencies: CreateCertUsingPEMCtrl class, CreateCertUsingPEM vf page,
 CreateCertUsingPEMCtrlTest test class

 Description: The controller class CreateCertUsingPEMCtrl and VF page CreateCertUingPEM programs are being 
 used to create root or intermediate cert using PEM. This process is invoked by standard buttons:
 
 'NewRootCertForThisOwner' on CA Owner page allows user to enter PEM for a root certificate.
 
 'NewIntermediateCert' on Root Certificate records allows user to enter PEM for an intermediate certificate.
 
 The PEM info is validated and parsed. If there are no errors in parsing, user is allowed to add new 
 root/intermediate certificate record.
  
 It button passes Account Parent Id and Record Type under which the new recordis created.
 
 Instructions:  A cert checker webservice is invoked from here to parse PEM Info PEMParserController.parsePEM(pemInfoStr);

 *******************************************************************************************************
 Revision History:
 
     12/31/2019 - Created new class
      
 ******************************************************************************************************/


global with sharing class CreateCertUsingPEMCtrl {

    // var which holds the PEM info entered by the user
    public String pemInfoStr {get;set;}
    
    // extraction results returned after processing pem info
    public String extractionResultsStr {get;set;}
    
    // this would be set as certificate id
    public Id certificateId;
    
    Account certificateSO;
    
    public Boolean isCertCheckSuccessful {get;set;}
    
    //property used to enable/disble update button
    public Boolean disableUpdateButton{get; set;}
     
    public string strRecordType {get; set;}
     
    // constructor
    public CreateCertUsingPEMCtrl(ApexPages.StandardController stdController) {
         // get the parentId from the URL param
        certificateId= ApexPages.currentPage().getParameters().get('id');
        this.disableUpdateButton = false;
        strRecordType = ApexPages.currentPage().getParameters().get('recordtype');
    } 
    
    public PageReference CreateCert() {
        try {
            if(certificateSO == null) certificateSO = new Account();
            
            certificateSO.ParentId = certificateId;
            if(string.isnotblank(strRecordType) && strRecordType == 'Root'){
                certificateSO.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Root Certificate').getRecordTypeId();
            }
            if(string.isnotblank(strRecordType) && strRecordType == 'Intermediate'){
                certificateSO.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Intermediate Certificate').getRecordTypeId();
            }
            certificateSO.Id = null;
            // do not save PEM Info if longer than 10000 chars; Add Comments 
            // change length to 15000 on 31st July 2020
            if(pemInfoStr != null && pemInfoStr.length() > 15000) {   
                certificateSO.X_509_Certificate_PEM__c = '';
                certificateSO.Comments__c = 'PEM too large to save directly in CCADB.';
            }  else {
                certificateSO.X_509_Certificate_PEM__c = pemInfoStr;
            }
            
            certificateSO.Display_PEM_Info_Warning_Message__c=false; 
            
            insert certificateSO; 
        }catch(Exception ex){
            this.disableUpdateButton = true;
            String errorMessage = 'Error processing!! Please contact your administrator.<br/>' + ex.getMessage();
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, errorMessage));
            return null;
        }     
    
        PageReference pgredirect = new PageReference('/' + certificateSO.id);
        pgredirect.setRedirect(true);
        return pgredirect;
    }
    
    // method executed on the click on validate pem info
    // this method invokes the rest api and validates the pem info 
    // provided by the user and shows the corresponding success/error message on the page
    public PageReference submit() {
        try {
            if(CommonMethods.validatePEMInfo(pemInfoStr)){
                
                // invoke the cert checker webservice and get the response
                certificateSO = PEMParserController.parsePEM(pemInfoStr);
                
                if(certificateSO != null) {
                
                    // set extractionResultsStr with the value returned by the utility; used by VF page
                    extractionResultsStr = certificateSO.Extraction_Results__c;
                    
                    //commented because we need to show error in new extraction results.
                    //show the error message if the webservice was not available
                    if(certificateSO.Display_Webservice_Not_Available__c) {      
                        //ApexPages.Message apexMessage = new ApexPages.Message(ApexPages.Severity.Error, 'The webservice for parsing cert data is unavailable at the current moment. Please try again later.');
                        string strErrorMessage = extractionResultsStr + ' <br/>Please contact your root store manager at support@ccadb.org.';
                        ApexPages.Message apexMessage = new ApexPages.Message(ApexPages.Severity.Error, strErrorMessage);
                        ApexPages.addMessage(apexMessage);
                        return null;
                    }
                    
                    // show the error message if there were errors parsing the pem info
                    /*if(certificateSO.Display_Webservice_Failed_Message__c) {      
                        ApexPages.Message apexMessage = new ApexPages.Message(ApexPages.Severity.Error, 'Parsing of cert data has failed with errors. Please provide correct PEM format for the cert.');
                        ApexPages.addMessage(apexMessage);
                        return null;
                    }*/
                    
                    // show the error message if the extraction results do not have fields
                    if(certificateSO.Extraction_Results__c == '{}') {      
                        ApexPages.Message apexMessage = new ApexPages.Message(ApexPages.Severity.Error, 'Parsing of cert data has failed. Please provide correct PEM format for the cert.' + ' Extraction Results: ' + certificateSO.Extraction_Results__c);
                        ApexPages.addMessage(apexMessage);
                        return null;
                    }
                    
                    // if certificate is technically constrained, show error message.
                    if(certificateSO.Technically_Constrained__c){
                        this.isCertCheckSuccessful = true;
                        this.disableUpdateButton = true;
                        ApexPages.Message apexMessage = new ApexPages.Message(ApexPages.Severity.WARNING, '<br/><font color="red">This certificate is considered to be technically-constrained. All data that you enter into the CCADB will be publicly available, so please make sure you do not enter sensitive information that should not be published.</font><br/><br/><input type="checkbox" onclick="showUpdateButton();" />&nbsp;&nbsp;&nbsp;&nbsp;I understand, proceed anyways.');
                        ApexPages.addMessage(apexMessage);
                        return null;
                    }          
                    
                    // show success message if there were no errors
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Confirm,'Cert Check is successful. Please proceed by clicking on the \'Create Cert\' button.'));
                    
                    // set the boolean flag to show/hide buttons accordingly     
                    isCertCheckSuccessful=true;
                }
            }
            return null; 
        }
        catch (Exception ex) {
            // throw exception messages
            ApexPages.addMessages(ex);
        }
        return null; 
    }
    
    
    // user wants to abort the operation, redirect them to the record
    // from which they landed on this page
    public PageReference cancel() {
        PageReference parentRecordPage = new PageReference('/' + certificateId);
        parentRecordPage.setRedirect(true);
        return parentRecordPage;
    }
    
    // function used by javascript to re-render the buttons on the user acceptance of the technical constrained flag - this will toggle the button to enable/disable.
    public void showUpdateButton(){
        this.disableUpdateButton = !this.disableUpdateButton;
    }
 
}
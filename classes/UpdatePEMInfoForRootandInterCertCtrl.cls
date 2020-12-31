/****
 Description: 
 Controller is created to parse PEM Info for Root and Intermediate certs.
 
 To test the service first create the pem file
 curl https://letsencrypt.org/certs/isrgrootx1.pem > /tmp/certificate.pem
 curl https://tls-observatory.stage.mozaws.net/api/v1/certificate -Fcertificate=@/tmp/certificate.pem

***/

global with sharing class UpdatePEMInfoForRootandInterCertCtrl {

    // var which holds the PEM info entered by the user
    public String pemInfoStr {get;set;}
    
    // extraction results returned after processing pem info
    public String extractionResultsStr {get;set;}
    
    // this would be set as certificate id
    public Id certificateId;
    
    Account certificateSO;
    
    public Boolean isCertCheckSuccessful {get;set;}
    
    public boolean isProceedAnywaySameExtraction;
    
    //property used to enable/disble update button
    public Boolean disableUpdateButton{get; set;}
     
    // constructor
    public UpdatePEMInfoForRootandInterCertCtrl (ApexPages.StandardController stdController) {
         // get the parentId from the URL param
        certificateId= ApexPages.currentPage().getParameters().get('id');
        this.disableUpdateButton = false;
        isProceedAnywaySameExtraction = false;
        
    } 
    
    public PageReference updateCert() {
        try {
            if(certificateSO == null) certificateSO = new Account();
            
            certificateSO.id = certificateId;
            
            // do not save PEM Info if longer than 10000 chars; Add Comments 
            // change length to 15000 on 31st July 2020
            if(pemInfoStr != null && pemInfoStr.length() > 15000) {   
                certificateSO.X_509_Certificate_PEM__c = '';
                certificateSO.Comments__c = 'PEM too large to save directly in CCADB.';
            }  else {
                certificateSO.X_509_Certificate_PEM__c = pemInfoStr;
            }
            
            certificateSO.Display_PEM_Info_Warning_Message__c=false; 
            
            
            // Updating the certificate record only if the extraction resuts are different
            //changed logic proceed anyways when same extraction results.
            List<Account> lstAccount = new List<Account>([Select Id,Extraction_Results__c from Account Where Id =: certificateId]);
            if(!isProceedAnywaySameExtraction && lstAccount.size() > 0 && lstAccount[0].Extraction_Results__c == certificateSO.Extraction_Results__c){
                string errorMessage = 'This PEM data has produced the same \'Extraction Results\' as earlier. Hit \'Update Cert\' again to proceed anyways. <br/>';
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, errorMessage)); 
                isProceedAnywaySameExtraction = true;
                //this.disableUpdateButton = true;
                return null;
            } else {
                update certificateSO; 
            }  
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
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Confirm,'Cert Check is successful. Please proceed by clicking on the \'Update Cert\' button.'));
                    
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
/*******************************************************************************************************
 Name: AccessRequestFormController

 Dependencies: AccessRequestFormController controller class, AccessRequestForm vf page, 
 AccessRequestFormController test class

 Description: This is a controller class for public form. CAs can use this form to 
 request access to CCADB. The form has field level validations and reCaptch (from Google) logic. 
 'Submit' button create Lead record in Salesforce. Lead is assigned to Microsoft (org-wide email) 
 if 'Sponsered By' is Microsoft all others are assigned to Mozilla (org-wide email). Email templates 
 for lead assignment are "Lead Assignment To Mozilla For CCADB Access Form" and
 "Lead Assignment To Microsoft For CCADB Access Form".
 
 Instructions: The form uses Google webservice reCaptch v2 to detect spam traffic without user interaction.
 Remote site setting must have active entry for https://www.google.com and register site with Goggle 
 recaptcha at https://www.google.com/recaptcha/admin
 *******************************************************************************************************
 Revision History:
 
     3/18/2019 - Created new class
     6/15/2020 - Updated class to access OrgWideEmailAddress due to security related release Summer'20 
 ******************************************************************************************************/
 
public without sharing class AccessRequestFormController {
    
    private static String baseUrl = 'https://www.google.com/recaptcha/api/siteverify'; 
    private static String secret = System.Label.Google_Captcha_SecretKey;
    public String sitekey {get; set;}
    public string strConfirmEmail {get; set;}
    
    public boolean isLeadCreated {get; set;}
    
    private Lead objLead;
    
    public String response  { get { return ApexPages.currentPage().getParameters().get('g-recaptcha-response'); } }
    public AccessRequestFormController (Apexpages.standardcontroller controller){
        isLeadCreated = false;
        sitekey = System.Label.Google_Captcha_SiteKey;
        objLead = (Lead)controller.getRecord();
        strConfirmEmail = '';
    }
    
    public void doVerify () { 
        //system.debug('response::: '+response);
        String responseBody = makeRequest(baseUrl,'secret=' + secret +'&response='+ response); 
        //system.debug('responseBody  ::: '+responseBody);
        if(string.isblank(objLead.FirstName)){
            ApexPages.Message errorMsg = new ApexPages.Message(ApexPages.Severity.Error, 'Please enter First Name.'); 
            ApexPages.addMessage(errorMsg);
            return;
        } 
        if(string.isblank(objLead.Email)){
            ApexPages.Message errorMsg = new ApexPages.Message(ApexPages.Severity.Error, 'Please enter Email address.'); 
            ApexPages.addMessage(errorMsg);
            return;
        } 
        if(string.isblank(objLead.Salesforce_Terms_of_Service__c)){
            ApexPages.Message errorMsg = new ApexPages.Message(ApexPages.Severity.Error, 'Please select Salesforce Terms of Services.'); 
            ApexPages.addMessage(errorMsg);
            return;
        } 
        if((string.isnotblank(objLead.Website) && !objLead.Website.startswith('https'))){
            ApexPages.Message errorMsg = new ApexPages.Message(ApexPages.Severity.Error, 'Please enter "URL to Company or CA Website" beginning with https://.'); 
            ApexPages.addMessage(errorMsg);
            return;
        }
        if((string.isnotblank(objLead.CP_CPS_document_URLs__c) && !objLead.CP_CPS_document_URLs__c.startswith('https'))){
            ApexPages.Message errorMsg = new ApexPages.Message(ApexPages.Severity.Error, 'Please enter "URLs to the CA\'s CP/CPS documents" beginning with https://.'); 
            ApexPages.addMessage(errorMsg);
            return;
        }
        if(objLead.Email != null && objLead.Email != '') {
            if(string.isblank(strConfirmEmail)){
                ApexPages.Message errorMsg = new ApexPages.Message(ApexPages.Severity.Error, 'Please enter Confirmation Email address.'); 
                ApexPages.addMessage(errorMsg);
                return;
            } else if(string.isnotblank(strConfirmEmail) && objLead.Email != strConfirmEmail){
                ApexPages.Message errorMsg = new ApexPages.Message(ApexPages.Severity.Error, 'Email and Confirmation Email do not match.'); 
                ApexPages.addMessage(errorMsg);
                return;
            }
        }
        String success = getValueFromJson(responseBody, 'success'); 
        if(success.equalsIgnoreCase('true') || Test.IsRunningTest()) { 
            try {
                objLead.LeadSource = 'Auto Created by Web Form';
                insert objLead; 
                isLeadCreated = true;
                List<OrgWideEmailAddress> lstOWEA;
                List<EmailTemplate> templateId;
                List<Messaging.SingleEmailMessage> allmsg = new List<Messaging.SingleEmailMessage>();
                if(objLead.Sponsored_By__c == 'Microsoft'){
                    lstOWEA = [select id, DisplayName, Address from OrgWideEmailAddress Where DisplayName in ('CCADB Support','Microsoft CA Program Manager')];
                    templateId = [Select id from EmailTemplate where DeveloperName = 'LeadAssignmentToMicrosoftForCCADBAccessForm' and IsActive = true];
                } else {
                    lstOWEA = [select id, DisplayName, Address from OrgWideEmailAddress Where DisplayName in ('CCADB Support','Mozilla CA Program Manager')];
                    templateId = [Select id from EmailTemplate where DeveloperName = 'LeadAssignmentToMozillaForCCADBAccessForm' and IsActive = true];
                }
                if(templateId.size() > 0) {
                    Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                    mail.setTargetObjectId(objLead.Id);
                    mail.setTreatTargetObjectAsRecipient(false);
                    mail.setTemplateID(templateId[0].Id);
                    //mail.setWhatId(objLead.Id);
                    for(OrgWideEmailAddress owd: lstOWEA){
                        if(owd.DisplayName == 'CCADB Support'){
                            mail.setOrgWideEmailAddressId(owd.Id);
                        } else {
                            mail.setToAddresses(new List<string>{owd.Address});
                        }
                    }
                    allmsg.add(mail);
                    Messaging.sendEmail(allmsg,false);
                }
                ApexPages.Message errorMsg = new ApexPages.Message(ApexPages.Severity.CONFIRM, 'Thank you for submitting your request.'); 
                ApexPages.addMessage(errorMsg);
                return;
            } catch(exception e) { 
                isLeadCreated = false;
                ApexPages.Message errorMsg = new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()); 
                ApexPages.addMessage(errorMsg);
                return; 
            } 
        } else { 
            ApexPages.Message errorMsg = new ApexPages.Message(ApexPages.Severity.ERROR, 'Please check the box for reCAPTCHA'); 
            ApexPages.addMessage(errorMsg); 
            return; 
        }
    } 
    private static String makeRequest(string url, string body) { 
        HttpResponse response = null; 
        HttpRequest req = new HttpRequest(); 
        req.setEndpoint(url); 
        req.setMethod('POST'); 
        req.setBody(body); 
        try { 
            Http http = new Http(); 
            if(!Test.IsRunningTest()){
                response = http.send(req); 
                return response.getBody();
            } 
        } catch(System.Exception e) { 
            //System.debug('ERROR: ' + e); 
        } return '{"success":false}'; 
    } 
    public static string getValueFromJson ( String strJson, String field ) { 
        JSONParser parser = JSON.createParser(strJson); 
        while (parser.nextToken() != null) { 
            if ((parser.getCurrentToken() == JSONToken.FIELD_NAME)) { 
                if(parser.getText() == field){ 
                    //Get the value.
                    parser.nextToken(); 
                    return parser.getText(); 
                } 
            } 
        } 
        return null; 
    }
}
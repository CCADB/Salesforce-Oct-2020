/*******************************************************************************************************
 Name: LeadActionController

 Dependencies: LeadActionController controller class, LeadAction VF page, LeadActionTest class

 Description: Controller is created for LeadAction class. Once the Lead is converted, email is sent
  the CA (Lead Convert email template). Another email is sent to admin@ccadb.org to issue license (no 
 template used). Lead conversion creates CA Owner and a Contact records.
 
 Instructions: Lead standard fields are automatically mapped by the lead conversion process.
 *******************************************************************************************************
 Revision History:
 
     4/30/2019 - Created new class
 ******************************************************************************************************/

public with sharing class LeadActionController {
    
    public string strError {get; set;}
    public Lead objLead {get; set;}
    public string strType {get; set;}
    string leadId;
    
    public LeadActionController(Apexpages.standardcontroller controller){
        strError = '';
        strType = '';
        leadId = '';
        if(controller != null) {
            leadId = controller.getId();
            objLead = new Lead(Id = leadId);
            if(Apexpages.currentPage().getParameters().get('type') != null){
                strType = string.valueof(Apexpages.currentPage().getParameters().get('type'));
            }
            if(strType == 'close'){
                objLead.Denied_on_Date__c = system.Today();
            }
        }
    }
    
    public PageReference CloseLeadWOConvert(){
        Savepoint sp = Database.setSavepoint();
        try {
            if(string.isblank(objLead.Reason_for_Denial__c)){
                strError = 'Reason for Denial is required.';
                return null;
            }
            objLead.Status = 'Denied';
            update objLead;
            PageReference pg = new PageReference('/'+objLead.Id);
            return pg;
        } catch (Exception ex){
            strError = 'Error occured: ' + ex.getMessage() + ' at Line Number '+ ex.getLineNumber();
            Database.rollback(sp);
            return null;
        }
    }
    
    public PageReference BackToRecord(){
        Savepoint sp = Database.setSavepoint();
        if(string.isnotblank(leadid)){
            List<Lead> lstLead = new List<Lead>([select Id, Name, Company, Email, Alternate_CA_Name_s__c, Status,
                                                     CP_CPS_document_URLs__c, Describe_Company_CA_Organization__c, Website
                                                     from Lead Where Id =: leadid]);
            if(lstLead.size() > 0 && lstLead[0].Status == 'Denied'){
                strError = 'Lead is Denied. You can\'t take any further action.';
                return null;
            }
            if(lstLead.size() > 0 && lstLead[0].Status == 'Converted'){
                strError = 'Lead is Converted. You can\'t take any further action.';
                return null;
            }
            if(strType == 'close'){
                //Lead lead = new Lead(Id = leadid, Status = 'Denied');
                //update lead;
                //PageReference pg = new PageReference('/'+lead.Id);
                //return pg;
            } else if(strType == 'convert'){
                
                if(lstLead.size() > 0) {
                    string strCompanyName = lstLead[0].Company;
                    List<Account> lstCAOwner = new List<Account>([select Id from Account Where Name =: strCompanyName and RecordType.Name = 'CA Owner']);
                    List<Contact> lstExistContact = new List<Contact>([select Id,AccountId from Contact Where Email != null and Email != '' and Email =: lstLead[0].Email]);
                    
                    if(lstCAOwner.size() > 0){
                        strError = 'CA Owner already exists with this name. You cannot convert Lead.';
                        return null;
                    }
                    
                    if(lstExistContact.size() > 0) {
                        strError = 'Contact already exists with same email. You cannot convert Lead.';
                        return null;
                    }
                    
                    LeadStatus convertStatus = [SELECT Id, MasterLabel FROM LeadStatus WHERE IsConverted=true LIMIT 1];
                    
                    Database.LeadConvert lc = new Database.LeadConvert();
                    lc.setLeadId(lstLead[0].id);
                    lc.setOwnerId(UserInfo.getUserId());
                    lc.setConvertedStatus(convertStatus.MasterLabel);
                    lc.setDoNotCreateOpportunity(true);
                    if(lstCAOwner.size() > 0){
                        lc.setAccountId(lstCAOwner[0].Id);
                    }
                    try {
                        Database.LeadConvertResult lcr = Database.convertLead(lc);
                        if(lcr.isSuccess()){
                            string strAccId = lcr.getAccountId();
                            //update Legal Name and CP/CPS document urls on newly created Account record
                            if(lstLead[0].Alternate_CA_Name_s__c != null || 
                               lstLead[0].CP_CPS_document_URLs__c != null ||
                               lstLead[0].Describe_Company_CA_Organization__c != null || lstLead[0].Website != null) {
                                Account objAcc = new Account(Id = strAccId);
                                string strDescription = '';
                                if(lstLead[0].Alternate_CA_Name_s__c != null && lstLead[0].Alternate_CA_Name_s__c.length() > 0) {
                                    strDescription = 'Alternate CA Name(s): '+lstLead[0].Alternate_CA_Name_s__c;
                                }
                                if(lstLead[0].CP_CPS_document_URLs__c != null && lstLead[0].CP_CPS_document_URLs__c.length() > 0) {
                                    if(strDescription.length() > 0) strDescription += '\n';
                                    strDescription += 'URLs to the CA’s CP/CPS documents: '+lstLead[0].CP_CPS_document_URLs__c;
                                }
                                if(lstLead[0].Describe_Company_CA_Organization__c != null && lstLead[0].Describe_Company_CA_Organization__c.length() > 0) {
                                    strDescription = 'Describe Company/CA Organization: '+lstLead[0].Describe_Company_CA_Organization__c;
                                }
                                if(string.isnotblank(strDescription) || lstLead[0].Website != null){
                                    objAcc.Description = strDescription;
                                    objAcc.Company_Website__c = lstLead[0].Website;
                                    update objAcc;
                                }
                            }
                            //set Type as Primary POC on newly created contact
                            string strContactId = lcr.getContactId();
                            if(string.isnotblank(strContactId)){
                                Contact objCon = new Contact(Id = strContactId, Type__c = 'Primary POC');
                                update objCon;
                            }
                            
                            List<OrgWideEmailAddress> lstOWEA = [select id, DisplayName, Address from OrgWideEmailAddress Where DisplayName = 'CCADB Support'];
                            List<EmailTemplate> templateId = [Select id from EmailTemplate where DeveloperName = 'Lead_Convert' and IsActive = true];
                            List<Messaging.SingleEmailMessage> allmsg = new List<Messaging.SingleEmailMessage>();
                            
                            //mail send to Newly created CA Owner.
                            if(templateId.size() > 0) {
                                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                                mail.setTargetObjectId(strContactId);
                                mail.setSaveAsActivity(true);
                                mail.setTemplateID(templateId[0].Id);
                                mail.setWhatId(strAccId);
                                mail.setOrgWideEmailAddressId(lstOWEA[0].Id);
                                allmsg.add(mail);
                            }
                            
                            //mail send to CCADB Support
                            Messaging.SingleEmailMessage mailToAdmin = new Messaging.SingleEmailMessage();
                            mailToAdmin.toAddresses = new String[] {'admin@ccadb.org'};
                            mailToAdmin.setOrgWideEmailAddressId(lstOWEA[0].Id);
                            mailToAdmin.subject = 'New CA Owner Added - Provide access to CCADB';
                            string strBody = 'Please issue Salesforce Community License to the following CA:<br/><br/>';
                            List<Contact> lstContact = new List<Contact>([select Id,Name,Account.Name,Email from Contact Where Id =: strContactId]);
                            if(lstContact.size() > 0) {
                                strBody += 'CA Name: '+lstContact[0].Account.Name + '<br/>';
                                strBody += 'Email: '+lstContact[0].Email + '<br/>';
                                strBody += 'Contact: <a href="'+URL.getSalesforceBaseUrl().toExternalForm()+ '/' +lstContact[0].Id+'" target="_blank">'+lstContact[0].Name+'</a><br/>';
                            }
                            mailToAdmin.HTMLBody = strBody;
                            allmsg.add(mailToAdmin);
                            
                            Messaging.sendEmail(allmsg,false);
                            PageReference pg = new PageReference('/'+strAccId);
                            return pg;
                        } else {
                            strError = string.join(lcr.getErrors(),'.');
                            return null;
                        }
                    } catch(Exception ex){
                        strError = 'Error occured: ' + ex.getMessage() + ' at Line Number '+ ex.getLineNumber();
                        Database.rollback(sp);
                        return null;
                    }
                }
            }
        } else {
            strError = 'Lead not found.';
        }
        return null;
    }
}
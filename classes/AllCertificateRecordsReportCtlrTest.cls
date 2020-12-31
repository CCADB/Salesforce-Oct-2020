/*******************************************************************************************************
 Name: AllCertificateRecordsReportCtlrTest

 Dependencies: AllCertificateRecordsReportController, AllCertificateRecordsCSVFormat, 
 AllCertificateRecordsReportCtlrTest
 
 Description: This is a controller class for AllCertificateRecordsReportController.
 The report generates list of all root and intermediate certs.

 Instructions: None

 *******************************************************************************************************
 Revision History:
 
     06/24/2017 - Created new
     11/20/2019 - Added Subordinate CA Owner field to the report
     05/26/2020 - Changed for CP/CPS fields and display links for Policy documents
 ******************************************************************************************************/
 

@isTest 
public class AllCertificateRecordsReportCtlrTest{

    static testMethod void validateTest() {
        Account parentAccount = new Account();
        parentAccount.recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('CA Owner').getRecordTypeID();
        parentAccount.name = 'ParentAccount';
        parentAccount.type = 'Owner';
        parentAccount.status__c= 'Included';
        parentAccount.Revocation_Status__c = 'Included';
        parentAccount.phone='2128425500';
        parentAccount.website  = 'https//www.test.com';
        parentAccount.valid_From_GMT__c= date.today()+1;
        parentAccount.valid_to_GMT__c= date.today()+10;
        parentAccount.company_website__c=  'https//www.test.com';
        parentAccount.organizational_type__c=  'Organizational Type';
        parentAccount.geographic_focus__c=  'Geographic focus';
        parentAccount.primary_market_customer_base__c = 'Primary Market';
        insert parentAccount;
        
        Account childAccount = new Account();
        childAccount.recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Root Certificate').getRecordTypeID();
        childAccount.name = 'ChildAccount';
        childAccount.type = 'Root';
        childAccount.phone='2128425500';
        childAccount.Revocation_Status__c = 'Not Revoked';
        childAccount.website  = 'https//www.test.com';
        childAccount.valid_From_GMT__c= date.today()+1;
        childAccount.valid_to_GMT__c= date.today()+10;
        childAccount.Standard_Audit_Period_Start_Date__c = system.today();
        childAccount.Standard_Audit_Period_End_Date__c = system.today().addDays(3);
        childAccount.BR_Audit_Period_Start_Date__c = system.today();
        childAccount.BR_Audit_Period_End_Date__c = system.today().addDays(3);
        childAccount.EV_Audit_Period_Start_Date__c = system.today();
        childAccount.EV_Audit_Period_End_Date__c = system.today().addDays(3);
        childAccount.EV_Code_Signing_Audit_Period_Start_Date__c = system.today();
        childAccount.EV_Code_Signing_Audit_Period_End_Date__c = system.today().addDays(3);
        childAccount.CP_CPS_Last_Updated_Date__c = system.today()+2;
        
        childAccount.company_website__c=  'https//www.test.com';
        childAccount.SHA_1_Fingerprint__c= '12:34:56:78:90:12:34:56:78:90:12:34:56:78:90:12:34:56:78:90';
        childAccount.parentid = parentAccount.Id;
        
        insert childAccount;
        
        Policy_Document_On_Certificate__c PDC = new Policy_Document_On_Certificate__c(Document_Link__c = 'https://CPCPS.com', Document_Type__c = 'CP/CPS');
        insert PDC;
        
        PolicyDocumentAssociation_On_Certificate__c PDAC = new PolicyDocumentAssociation_On_Certificate__c(Policy_Document__c = PDC.Id, Certificate_Name__c = childAccount.Id);
        insert PDAC;

        PageReference pg = Page.AllCertificateRecordsCSVFormat;
        Test.setCurrentPage(pg);
        AllCertificateRecordsReportController pacrc = new AllCertificateRecordsReportController();
    }
    
}
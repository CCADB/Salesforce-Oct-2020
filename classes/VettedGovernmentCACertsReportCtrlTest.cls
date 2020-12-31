/*******************************************************************************************************
 Name: VettedGovernmentCACertsReportCtrlTest

 Dependencies:  VettedGovernmentCACertsReportController controller class, VettedGovernmentCACertsReportCtrlTest, 
 VettedGovernmentCACertsReport, VettedGovernmentCACertsCSV vf pages

 Description: This report lists root certificates for which 'Vetted Government CA' is checked.
 
 Instructions:  None

 *******************************************************************************************************
 Revision History:
 
     7/10/2020 - Created new

 ******************************************************************************************************/

@isTest 
public class VettedGovernmentCACertsReportCtrlTest {

    static testMethod void validateTest() {
        Account parentAccount = TestUtils.getCAOwner();
        insert parentAccount;
        
        Account childAccount = TestUtils.getRootCertificate(parentAccount.Id);
        childAccount.Status__c = 'Included';
        childAccount.Vetted_Government_CA__c = true;
        childAccount.X_509_Certificate_PEM__c = 'Test';
        insert childAccount;
        
        
        /*Policy_Document_On_Certificate__c PDC = new Policy_Document_On_Certificate__c(Document_Link__c = 'https://CPCPS.com', Document_Type__c = 'CP/CPS');
        insert PDC;
        
        PolicyDocumentAssociation_On_Certificate__c PDAC = new PolicyDocumentAssociation_On_Certificate__c(Policy_Document__c = PDC.Id, Certificate_Name__c = childAccount.Id);
        insert PDAC;*/
        
        VettedGovernmentCACertsReportController pacrc = new VettedGovernmentCACertsReportController();
        pacrc.getCurrentDate();
    }

}
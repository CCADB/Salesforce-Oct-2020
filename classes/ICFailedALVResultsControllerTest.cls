/*******************************************************************************************************
 Name: ICFailedALVResultsControllerTest

 Dependencies: ICFailedALVResultsController class, ICFailedALVResultsControllerTest
 test class, AllCAAIdentifiersReportController vf page

 Description: This is a test class for ICFailedALVResultsController. Report lists 
 Failed ALV Intermediate certs.
 
 Instructions: None   
 *******************************************************************************************************
 Revision History:
 
     5/22/2020- Created new class
 ******************************************************************************************************/     

@isTest 
public class ICFailedALVResultsControllerTest {

    static testMethod void validateTest() {
        
        Account caOwner = TestUtils.getCAOwner();
        insert caOwner;
        
        Account rootCert = TestUtils.getRootCertificate(caOwner.Id);
        rootCert.Status__c = 'Included';
        insert rootCert;
        
        Account interCert = TestUtils.getIntermediateCertificate(rootCert.Id);
        interCert.Revocation_Status__c = 'Not Revoked';
        interCert.Standard_Audit_ALV_Found_Cert__c = 'FAIL';
        interCert.Technically_Constrained__c = FALSE;
        interCert.Mozilla_Root_Status__c = 'Included';
        insert interCert;
        
        Account interCert1 = TestUtils.getIntermediateCertificate(interCert.Id);
        interCert1.Revocation_Status__c = 'Not Revoked';
        interCert1.Standard_Audit_ALV_Found_Cert__c = 'FAIL';
        interCert1.Technically_Constrained__c = FALSE;
        interCert1.Audits_Same_as_Parent__c = true;
        interCert1.Mozilla_Root_Status__c = 'Included';
        insert interCert1;
        
        ICFailedALVResultsController controller = new ICFailedALVResultsController();
        controller.getCurrentDate();
    }
}
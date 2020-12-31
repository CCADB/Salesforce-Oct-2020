/*******************************************************************************************************
 Name: IntermediateCertsSeparateAuditsCtrlTest
 
 Dependencies: IntermediateCertsSeparateAudits VF page, IntermediateCertsSeparateAuditsCSV VF page, 
 IntermediateCertsSeparateAuditsCtrl 
 
 Description: 'Intermediate Certs's Separate Audits' reports on Intermediate certs which have their own audits.
 
              Filtered By:    

              CA Owner/Certificate Record Type equals Intermediate Certificate
              AND CA Owner/Certificate Owner not equal to <Fill in Cert Name>
              AND Revocation Status equals 'Not Revoked'
              AND OneCRL_Status__c not equals 'Added to OneCRL'
              AND Mozilla Status for the root cert equals Included,Change Requested
              AND Audits Same as Parent equals False
              AND Valid To (GMT) greater than TODAY
              AND Technically Constrained equals False

              Columns: CA Owner, Parent Certificate Name, Certificate Name, SHA-256 Fingerprint, 
                       Valid From [GMT], Valid To [GMT], Standard Audit, Standard Audit Period End Date, 
                       BR Audit, BR Audit Period End Date

              Columns For the non-CSV version, SHA-256 fingerprints links to 
                      https://crt.sh/?q=<SHA256-Fingerprint>
 Instructions: None
   
 *******************************************************************************************************
 Revision History:
 
     3/7/2019 - Created new
     7/9/2019 - Added "Comments" field
 ******************************************************************************************************/
@isTest
public with sharing class IntermediateCertsSeparateAuditsCtrlTest {

    static testmethod void TestICSeperateAudits(){
        Account caOwnerAccount = TestUtils.getCAOwner();
        caOwnerAccount.Status__c = 'Change Requested';
        insert caOwnerAccount;
        
        Account rootAccount = TestUtils.getRootCertificate(caOwnerAccount.Id);
        rootAccount.Status__c = 'Change Requested';
        rootAccount.Standard_Audit__c = 'https://cert.webtrust.org/SealFile?seal=1987&file=pdf';
        rootAccount.Standard_Audit_Type__c = 'WebTrust';
        rootAccount.Standard_Audit_Statement_Date__c = system.today().addDays(10);
        rootAccount.Standard_Audit_Period_Start_Date__c = system.today().addDays(2);
        rootAccount.Standard_Audit_Period_End_Date__c = system.today().addDays(5);
        rootAccount.Code_Signing_Audit__c = 'https://cert.webtrust.org/SealFile?seal=1990&file=pdf';
        rootAccount.Code_Signing_Audit_Type__c = 'WebTrust';
        rootAccount.Code_Signing_Audit_Statement_Date__c = system.today().addDays(10);
        rootAccount.Code_Signing_Audit_Period_Start_Date__c = system.today().addDays(2);
        rootAccount.Code_Signing_Audit_Period_End_Date__c = system.today().addDays(5);
        rootAccount.BR_Audit__c = 'https://cert.webtrust.org/SealFile?seal=1988&file=pdf';
        rootAccount.BR_Audit_Type__c = 'WebTrust';
        rootAccount.BR_Audit_Statement_Date__c = system.today().addDays(10);
        rootAccount.BR_Audit_Period_Start_Date__c = system.today().addDays(2);
        rootAccount.BR_Audit_Period_End_Date__c = system.today().addDays(5);
        rootAccount.EV_Audit__c = 'https://cert.webtrust.org/SealFile?seal=1989&file=pdf';
        rootAccount.EV_Audit_Type__c = 'WebTrust';
        rootAccount.EV_Audit_Statement_Date__c = system.today().addDays(10);
        rootAccount.EV_Audit_Period_Start_Date__c = system.today().addDays(2);
        rootAccount.EV_Audit_Period_End_Date__c = system.today().addDays(5);
        rootAccount.EV_Code_Signing_Audit__c = 'https://cert.webtrust.org/SealFile?seal=1989&file=pdf';
        rootAccount.EV_Code_Signing_Audit_Type__c= 'WebTrust';
        rootAccount.EV_Code_Signing_Audit_Statement_Date__c = system.today().addDays(10);
        rootAccount.EV_Code_Signing_Audit_Period_Start_Date__c = system.today().addDays(2);
        rootAccount.EV_Code_Signing_Audit_Period_End_Date__c = system.today().addDays(5);
        rootAccount.Comments__c = 'Comments';
        insert rootAccount;
        
        Account interCertsAccount = TestUtils.getIntermediateCertificate(rootAccount.Id);
        interCertsAccount.Status__c = 'Change Requested';
        interCertsAccount.Standard_Audit__c = 'https://cert.webtrust.org/SealFile?seal=1987&file=pdf';
        interCertsAccount.Standard_Audit_Type__c = 'WebTrust';
        interCertsAccount.Standard_Audit_Statement_Date__c = system.today().addDays(10);
        interCertsAccount.Standard_Audit_Period_Start_Date__c = system.today().addDays(2);
        interCertsAccount.Standard_Audit_Period_End_Date__c = system.today().addDays(5);
        interCertsAccount.Code_Signing_Audit__c = 'https://cert.webtrust.org/SealFile?seal=1990&file=pdf';
        interCertsAccount.Code_Signing_Audit_Type__c = 'WebTrust';
        interCertsAccount.Code_Signing_Audit_Statement_Date__c = system.today().addDays(10);
        interCertsAccount.Code_Signing_Audit_Period_Start_Date__c = system.today().addDays(2);
        interCertsAccount.Code_Signing_Audit_Period_End_Date__c = system.today().addDays(5);
        interCertsAccount.BR_Audit__c = 'https://cert.webtrust.org/SealFile?seal=1988&file=pdf';
        interCertsAccount.BR_Audit_Type__c = 'WebTrust';
        interCertsAccount.BR_Audit_Statement_Date__c = system.today().addDays(10);
        interCertsAccount.BR_Audit_Period_Start_Date__c = system.today().addDays(2);
        interCertsAccount.BR_Audit_Period_End_Date__c = system.today().addDays(5);
        interCertsAccount.EV_Audit__c = 'https://cert.webtrust.org/SealFile?seal=1989&file=pdf';
        interCertsAccount.EV_Audit_Type__c = 'WebTrust';
        interCertsAccount.EV_Audit_Statement_Date__c = system.today().addDays(10);
        interCertsAccount.EV_Audit_Period_Start_Date__c = system.today().addDays(2);
        interCertsAccount.EV_Audit_Period_End_Date__c = system.today().addDays(5);
        interCertsAccount.EV_Code_Signing_Audit__c = 'https://cert.webtrust.org/SealFile?seal=1989&file=pdf';
        interCertsAccount.EV_Code_Signing_Audit_Type__c= 'WebTrust';
        interCertsAccount.EV_Code_Signing_Audit_Statement_Date__c = system.today().addDays(10);
        interCertsAccount.EV_Code_Signing_Audit_Period_Start_Date__c = system.today().addDays(2);
        interCertsAccount.EV_Code_Signing_Audit_Period_End_Date__c = system.today().addDays(5);
        interCertsAccount.Revocation_Status__c = 'Not Revoked';
        interCertsAccount.Root_Cert_Id__c = rootAccount.Id;
        interCertsAccount.Comments__c = 'Comments';
        insert interCertsAccount;
        
        IntermediateCertsSeparateAuditsCtrl controller = new IntermediateCertsSeparateAuditsCtrl();
        controller.getCurrentDate();
    }
}
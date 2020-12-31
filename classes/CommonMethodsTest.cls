/*******************************************************************************************************
 Name: CommonMethodsTest

 Dependencies:  CommonMethods controller class, CommonMethodsTest

 Description: Test class for CommonMethods

 Instructions: None
    
 *******************************************************************************************************
 Revision History:
 
     6/19/2018 - Created new
  
 ******************************************************************************************************/

@isTest
public with sharing class CommonMethodsTest {

    static testmethod void TestValidatePEMInfo() {
        //cover for blank PEM Info
        CommonMethods.validatePEMInfo('');
        
        //when PEM info is greater than 10000 chars
        string strPEM10000Info = '';
        for(Integer I = 0; I < 11000; I++) {
            strPEM10000Info += 'A'+I;
        }
        CommonMethods.validatePEMInfo(strPEM10000Info);
        
        //when pem info doesn't value begin certificates
        CommonMethods.validatePEMInfo('Test');
        
        //when pem info have more than 1 BEGIN CERTIFICATE
        CommonMethods.validatePEMInfo('BEGIN CERTIFICATE BEGIN CERTIFICATE END CERTIFICATE');
        
        //when pem info have more than 1 -----BEGIN CERTIFICATE-----
        CommonMethods.validatePEMInfo('-----BEGIN CERTIFICATE----- -----END CERTIFICATE-----');
        
        //when pem info have more than 1 -----BEGIN CERTIFICATE-----
        CommonMethods.validatePEMInfo('----BEGIN CERTIFICATE-----  ---123--END CERTIFICATE-----');
        
        
        Account caOwnerAcc = TestUtils.getCAOwner();
        insert caOwnerAcc;
        
        Account rootAccount = TestUtils.getRootCertificate(caOwnerAcc.id);
        rootAccount.Name = 'child root account 1';
        rootAccount.Standard_Audit__c = 'https://std.com';
        rootAccount.Standard_Audit_Type__c = 'WebTrust';
        rootAccount.Standard_Audit_Statement_Date__c = system.today();
        rootAccount.Standard_Audit_Period_Start_Date__c = system.today();
        rootAccount.Standard_Audit_Period_End_Date__c = system.today();
        rootAccount.Certificate_Policy_CP__c = 'https://cp.com';
        rootAccount.Certification_Practice_Statement_CPS__c = 'https://cps.com';
        insert rootAccount;
        
        Account interCertAccount1 = TestUtils.getIntermediateCertificate(rootAccount.id);
        interCertAccount1.Name = 'child Intercert account 1';
        interCertAccount1.Technically_Constrained__c = false;
        interCertAccount1.Valid_To_GMT__c = System.today().addYears(1);
        interCertAccount1.Subject_SPKI_SHA256__c = 'C90FBC2664485F6D3175055A45EF10D2EB6E6C7E027DF1A1D526458C42F42696';
        interCertAccount1.Revocation_Status__c = 'Not Revoked';
        insert interCertAccount1;
        
        CommonMethods.getSameSubjectSPKIInterCerts('C90FBC2664485F6D3175055A45EF10D2EB6E6C7E027DF1A1D526458C42F42696');
    }

}
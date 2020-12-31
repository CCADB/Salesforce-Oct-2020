/*
    Description: Test class for IncorrectFormatForPEMInfoReport
*/
@isTest
public with sharing class IncorrectFormatForPEMInfoReportTest {
    
    static testmethod void testIncorrectFormatPEM(){
    
        Account accountSo = TestUtils.getCAOwner();
        insert accountSo;
        
        string incorrectformatedpem = '-----BEGIN CERTIFICATE-----' +
            'MIIGTDCCBTSgAwIBAgIBDDANBgkqhkiG9w0BAQUFADB/MQswCQYDVQQGEwJFVTEnMIIGTDCCBTSgAwIBAgIBDDANBgkqhkiG9w0BAQUFADB/MQswCQYDVQQGEwJFVTEn' +
            '-----END CERTIFICATE-----';
        
        // create a ROOT CA
        Account rootCA = TestUtils.getRootCertificate(accountSo.Id);
        rootCa.X_509_Certificate_PEM__c = incorrectformatedpem;
        insert rootCa;
        
        IncorrectFormatForPEMInfoReport objincorrect = new IncorrectFormatForPEMInfoReport();
        
    }
}
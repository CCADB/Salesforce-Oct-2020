/*******************************************************************************************************
 Name: CommonMethods

 Dependencies:  CommonMethods controller class, CommonMethodsTest

 Description: Class is created for Common Methods

 Instructions: None
    
 *******************************************************************************************************
 Revision History:
 
     6/19/2018 - Created new
     8/7/2019 - Added common logic for Doppelganger intermediate certs
     7/17/2020 - Increased PEM size from 10,000 to 15,000 characters
 ******************************************************************************************************/

public with sharing class CommonMethods {
    
    public static boolean validatePEMInfo(string strPEMInfo) {
        boolean isPEMInfoCorrect = true;
        // throw an error if the pem info is not provided by the user
        if(strPEMInfo == null || strPEMInfo.length() == 0) {
            ApexPages.Message apexMessage = new ApexPages.Message(ApexPages.Severity.Error, 'Please provide PEM info else click the Cancel button.');
            ApexPages.addMessage(apexMessage);
            isPEMInfoCorrect = false;
            return isPEMInfoCorrect;
        } 
        
        // throw an error if the pem info is exceeding the field length 
        if(strPEMInfo != null && strPEMInfo.length() >= 15000){
            ApexPages.Message apexMessage = new ApexPages.Message(ApexPages.Severity.Error, 'Error: PEM data exceeds field length limit of 15,000 characters. Please contact support@ccadb.org.');
            isPEMInfoCorrect = false;
            return isPEMInfoCorrect;
        } 
        
        // throw an error if the pem info is missing "BEGIN CERTIFICATE" or "END CERTIFICATE" tags
        if(strPEMInfo.countmatches('BEGIN CERTIFICATE') == 0 || strPEMInfo.countmatches('END CERTIFICATE') == 0) {
            ApexPages.Message apexMessage = new ApexPages.Message(ApexPages.Severity.Error, 'PEM info does not have proper BEGIN CERTIFICATE/END CERTIFICATE format. Please re-enter PEM info.');
            ApexPages.addMessage(apexMessage);
            isPEMInfoCorrect = false;
            return isPEMInfoCorrect;
        } 
        
        // throw an error if the pem info has more than one instance of "BEGIN CERTIFICATE" or "END CERTIFICATE"
        if(strPEMInfo.countmatches('BEGIN CERTIFICATE') > 1 || strPEMInfo.countmatches('END CERTIFICATE') > 1){
            ApexPages.Message apexMessage = new ApexPages.Message(ApexPages.Severity.Error, 'Multiple occurrence of "BEGIN CERTIFICATE" or "END CERTIFICATE" found in PEM info. Please re-enter PEM info.');
            ApexPages.addMessage(apexMessage);
            isPEMInfoCorrect = false;
            return isPEMInfoCorrect;
        } 
        
        // throw an error if the pem info does not have proper format for BEGIN/END tags 
        if(strPEMInfo.countmatches('-----BEGIN CERTIFICATE-----') != 1 || strPEMInfo.countmatches('-----END CERTIFICATE-----') != 1) {
            ApexPages.Message apexMessage = new ApexPages.Message(ApexPages.Severity.Error, 'PEM info does not have proper format for BEGIN/END tags. Please re-enter PEM info.');
            ApexPages.addMessage(apexMessage);
            isPEMInfoCorrect = false;
            return isPEMInfoCorrect;
        }
        
        // throw an error if the pem info has extra characters before '-----BEGIN CERTIFICATE-----' or after '-----END CERTIFICATE-----'
        if(!strPEMInfo.startsWith('-----BEGIN CERTIFICATE-----') || !strPEMInfo.endsWith('-----END CERTIFICATE-----')) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, 'PEM info has extra characters before "-----BEGIN CERTIFICATE-----" or after "-----END CERTIFICATE-----". Please re-enter PEM info.'));
            isPEMInfoCorrect = false;
            return isPEMInfoCorrect;
        } 
        
        // throw an error if the pem info has blank lines
        if(strPEMInfo.countmatches('\r\n\r\n') > 0) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, 'PEM info has extra blank lines. Please re-enter PEM info.'));
            isPEMInfoCorrect = false;
            return isPEMInfoCorrect;
        } 
        return isPEMInfoCorrect;    
    }
    
    //check if there is any Intermediate certs with Same Subject+SKPI (Doppelganger) with non expired, non revoked and non technically constrained.
    public static List<Account> getSameSubjectSPKIInterCerts(string SubjectSPKI){
        List<Account> lstSameSubjectSPKI = new List<Account>([select Id from Account Where 
                    Subject_SPKI_SHA256__c =: SubjectSPKI AND
                    RecordType.Name = 'Intermediate Certificate' AND Revocation_Status__c = 'Not Revoked' AND
                    Valid_To_GMT__c > TODAY AND Technically_Constrained__c = FALSE]);
        return lstSameSubjectSPKI;
    }
}
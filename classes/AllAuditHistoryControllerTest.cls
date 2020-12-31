/*******************************************************************************************************
 Name: AllAuditHistoryControllerTest

 Dependencies:  AllAuditHistoryController controller class, AllAuditHistoryControllerTest, AllAuditHistory vf page

 Description: This report generates data from File Archive & association records for root and
 intermeduate certs.
 
 Sort by CA Owner Name, then Audit Statement Date, then Audit ExternalLink, then certificate type

 Instructions:  None

 *******************************************************************************************************
 Revision History:
 
     6/27/202 - Created new

 ******************************************************************************************************/
@isTest
public with sharing class AllAuditHistoryControllerTest {
    static testmethod void TestAuditHistories(){
        Account caOwnerAccount = TestUtils.getCAOwner();
        insert caOwnerAccount;
        
        Account rootAccount = TestUtils.getRootCertificate(caOwnerAccount.Id);
        insert rootAccount;
        
        File_Archive__c fArc1 = new File_Archive__c(CA_Owner__c = caOwnerAccount.Id, 
        External_Link__c = 'https://cert.webtrust.org/SealFile?seal=1987&file=pdf', 
        Internal_Link__c = 'https://test.salesforce.com/servlet/servlet.FileDownload?file=00P21000000cRRiEAM',
        Document_Type__c = 'Standard Audit; BR Audit');
        insert fArc1;
        
        File_Archive_Association__c fa = new File_Archive_Association__c(File_Archive__c = fArc1.Id, Certificate_Name__c = rootAccount.id);
        insert fa;
        
        AllAuditHistoryController controller = new AllAuditHistoryController();
        
    }
}
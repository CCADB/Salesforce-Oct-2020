/*
    Description: Test class for FileArchiveAndAssociationsController
*/
@isTest
public with sharing class FileArchiveAndAssociationsControllerTest {
    public static string strOrgInstance = System.URL.getSalesforceBaseURL().toExternalForm();
    static testmethod void TestFileArchiveAndAssociations(){
        Account caOwnerAccount = TestUtils.getCAOwner();
        insert caOwnerAccount;
        
        Account rootAccount = TestUtils.getRootCertificate(caOwnerAccount.Id);
        insert rootAccount;
        
        File_Archive__c fArc1 = new File_Archive__c(CA_Owner__c = caOwnerAccount.Id, 
        External_Link__c = 'https://cert.webtrust.org/SealFile?seal=1987&file=pdf', 
        Internal_Link__c = ''+strOrgInstance+'/servlet/servlet.FileDownload?file=00P21000000cRRiEAM',
        Document_Type__c = 'Standard Audit; BR Audit');
        insert fArc1;
        
        File_Archive_Association__c fa = new File_Archive_Association__c(File_Archive__c = fArc1.Id, Certificate_Name__c = rootAccount.id);
        insert fa;
        
        FileArchiveAndAssociationsController controller = new FileArchiveAndAssociationsController();
    }
}
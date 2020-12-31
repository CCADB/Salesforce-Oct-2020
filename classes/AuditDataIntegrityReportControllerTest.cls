/*
    Description: Test class for AuditDataIntegrityReportController
*/
@isTest
public with sharing class AuditDataIntegrityReportControllerTest {
    
    public static string strOrgInstance = System.URL.getSalesforceBaseURL().toExternalForm();
    
    static testmethod void TestAuditIntegrityReport(){
    
        Account caOwnerAccount = TestUtils.getCAOwner();
        caOwnerAccount.Status__c = 'Change Requested';
        insert caOwnerAccount;
        
        File_Archive__c fArc1 = new File_Archive__c(CA_Owner__c = caOwnerAccount.Id, 
        External_Link__c = 'https://cert.webtrust.org/SealFile?seal=1987&file=pdf', 
        Internal_Link__c = ''+strOrgInstance+'/servlet/servlet.FileDownload?file=00P21000000cRRiEAM',
        Document_Type__c = 'Standard Audit');
        
        File_Archive__c fArc2 = new File_Archive__c(CA_Owner__c = caOwnerAccount.Id, 
        External_Link__c = 'https://cert.webtrust.org/SealFile?seal=1988file=pdf', 
        Internal_Link__c = ''+strOrgInstance+'/servlet/servlet.FileDownload?file=00P21000000cRRiEAM',
        Document_Type__c = 'BR Audit');
        
        File_Archive__c fArc3 = new File_Archive__c(CA_Owner__c = caOwnerAccount.Id, 
        External_Link__c = 'https://cert.webtrust.org/SealFile?seal=1989&file=pdf', 
        Internal_Link__c = ''+strOrgInstance+'/servlet/servlet.FileDownload?file=00P21000000cRRiEAM',
        Document_Type__c = 'EV Code Signing Audit;EV SSL Audit');
        
        File_Archive__c fArc4 = new File_Archive__c(CA_Owner__c = caOwnerAccount.Id, 
        External_Link__c = 'https://cert.webtrust.org/SealFile?seal=1990&file=pdf', 
        Internal_Link__c = ''+strOrgInstance+'/servlet/servlet.FileDownload?file=00P21000000cRRiEAM',
        Document_Type__c = 'Code Signing Audit;');
        
        insert new List<File_Archive__c>{fArc1, fArc2, fArc3, fArc4};
        
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
        rootAccount.Valid_To_GMT__c = system.today().addDays(1);
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
        interCertsAccount.Valid_To_GMT__c = system.today().addDays(1);
        interCertsAccount.Revocation_Status__c = 'Revoked';
        insert interCertsAccount;
        
        fArc1.Audit_Statement_Date__c = system.today().addDays(2);
        fArc1.Period_Start_Date__c = system.today().addDays(5);
        fArc1.Period_End_Date__c = system.today().addDays(2);
        
        fArc2.Audit_Statement_Date__c = system.today().addDays(2);
        fArc2.Period_Start_Date__c = system.today().addDays(5);
        fArc2.Period_End_Date__c = system.today().addDays(2);
        
        fArc3.Audit_Statement_Date__c = system.today().addDays(2);
        fArc3.Period_Start_Date__c = system.today().addDays(5);
        fArc3.Period_End_Date__c = system.today().addDays(2);
        
        fArc4.Audit_Statement_Date__c = system.today().addDays(2);
        fArc4.Period_Start_Date__c = system.today().addDays(5);
        fArc4.Period_End_Date__c = system.today().addDays(2);
        
        update new List<File_Archive__c>{fArc1, fArc2, fArc3};
        
        AuditDataIntegrityReportController auditintegrityctlr = new AuditDataIntegrityReportController();
        
        fArc1.External_Link__c = 'https://cert.webtrust.org/SealFile?seal=2001&file=pdf';
        fArc2.External_Link__c = 'https://cert.webtrust.org/SealFile?seal=2002&file=pdf';
        fArc3.External_Link__c = 'https://cert.webtrust.org/SealFile?seal=2003&file=pdf';
        fArc4.External_Link__c = 'https://cert.webtrust.org/SealFile?seal=2004&file=pdf';
        update new List<File_Archive__c>{fArc1, fArc2, fArc3, fArc4};
        
        Apexpages.currentPage().getParameters().PUT('type','mozilla');
        auditintegrityctlr = new AuditDataIntegrityReportController();
        
        Apexpages.currentPage().getParameters().PUT('type','microsoft');
        auditintegrityctlr = new AuditDataIntegrityReportController();
    }
}
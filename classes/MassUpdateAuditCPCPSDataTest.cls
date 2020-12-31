@isTest
public class MassUpdateAuditCPCPSDataTest {

    
    static testmethod void testMassUpdateAuditCPCPSData1(){
        Auditor__c auditor = new Auditor__c();
        auditor.Name = 'WebTrust';
        auditor.Auditor_Status__c = 'Confidence - High';
        auditor.Auditor_Website__c = 'http://www.google.com';
        insert auditor;
        
        Auditor_Location__c auditorlocation = new Auditor_Location__c();
        auditorlocation.Name = 'US';
        auditorlocation.Auditor__c = auditor.Id;
        auditorlocation.Auditor_Location_Status__c = 'Confidence - High';
        insert auditorlocation;
        
        Account acc = new Account(Name = 'test 1', Status__c = 'Included', Type = 'Root',
                                  SHA_1_Fingerprint__c = '12:34:56:78:90:12:34:56:78:90:12:34:56:78:90:12:34:56:78:90',
                                  Auditor__c = 'WebTrust', Auditor_Qualifications__c = 'Qualifications',
                                  Auditor_Website__c = 'www.website.com', Auditor_New__c = auditor.Id, 
                                  Auditor_Location_New__c = auditorlocation.Id,
                                  EV_Policy_OID_s__c = 'Not EV', Trust_bits__c = 'All Trust Bits Turned Off');
        
        

        Account acc1 = new Account(Name = 'test 2', Auditor__c = 'WebTrust');
        Account acc2 = new Account(Name = 'test 3', Auditor__c = 'WebTrust');
        insert new List<Account>{acc, acc1, acc2};
        
        PageReference pref = Page.MassUpdateAuditCPCPSData;
        Test.setCurrentPage(pref);
        
        ApexPages.currentPage().getParameters().put('Id', acc.Id);
        
        ApexPages.standardController stdCon = new ApexPages.standardController(acc);
        MassUpdateAuditCPCPSDataController obj = new MassUpdateAuditCPCPSDataController(stdCon);
        
        obj.redirectToAccount();
       // obj.syncAccount();
    }
    
    static testmethod void testMassUpdateAuditCPCPSData2(){
        
        Account acc = new Account(Name = 'test 1', Type = 'Intermediate Certificate', 
        SHA_1_Fingerprint__c = '12:34:56:78:90:12:34:56:78:90:12:34:56:78:90:12:34:56:78:92',
        Status__c = 'Included', Audits_Same_As_Parent__c = True);
        insert acc;
        
        Account acc1 = new Account(Name = 'test 2', ParentId = acc.Id, Type = 'Intermediate Certificate');
        Account acc2 = new Account(Name = 'test 3', ParentId = acc.Id, Type = 'Intermediate Certificate');
        insert new List<Account>{acc1, acc2};
        
        PageReference pref = Page.MassUpdateAuditCPCPSData;
        Test.setCurrentPage(pref);
        
        ApexPages.currentPage().getParameters().put('Id', acc.Id);
        
        ApexPages.standardController stdCon = new ApexPages.standardController(acc);
        MassUpdateAuditCPCPSDataController obj = new MassUpdateAuditCPCPSDataController(stdCon);
        
        obj.syncStdAuditFieldsOnTargetAccount();
        obj.syncBRAuditFieldsOnTargetAccount();
        obj.syncEVSSLAuditFieldsOnTargetAccount();
        obj.syncEVCodeSigningAuditFieldsOnTargetAccount();
        obj.syncPolicyFieldsOnTargetAccount();
        obj.syncMozillaFieldsOnTargetAccount();
        obj.syncMicrosoftFieldsOnTargetAccount();
        obj.redirectToNextAccount();
        obj.redirectTosourceAccount();
    }
    
    static testmethod void testMassUpdateAuditCPCPSData3(){
        
        Auditor__c auditor = new Auditor__c();
        auditor.Name = 'WebTrust';
        auditor.Auditor_Status__c = 'Confidence - High';
        auditor.Auditor_Website__c = 'http://www.google.com';
        insert auditor;
        
        Auditor_Location__c auditorlocation = new Auditor_Location__c();
        auditorlocation.Name = 'US';
        auditorlocation.Auditor__c = auditor.Id;
        auditorlocation.Auditor_Location_Status__c = 'Confidence - High';
        insert auditorlocation;
        
        Account parentAcc = new Account(Name = 'test 1', Type = 'Intermediate Certificate', 
        SHA_1_Fingerprint__c = '12:34:56:78:90:12:34:56:78:90:12:34:56:78:90:12:34:56:78:01',
        Auditor__c = 'Auditor', Auditor_Qualifications__c = 'Qualifications',
        Auditor_Website__c = 'www.website.com', Status__c = 'Included' );
        insert parentAcc;
        
        Account acc1 = new Account(Name = 'test 2', ParentId = parentAcc.Id, Type = 'Intermediate Certificate', 
        SHA_1_Fingerprint__c = '12:34:56:78:90:12:34:56:78:90:12:34:56:78:90:12:34:56:78:02',
        Auditor__c = 'Auditor', Auditor_Qualifications__c = 'Qualifications',
        Auditor_New__c = auditor.Id, Auditor_Location_New__c = auditorlocation.Id,
        Auditor_Website__c = 'www.website.com', Status__c = 'Included');
        
        Account acc2 = new Account(Name = 'test 3', ParentId = parentAcc.Id, Type = 'Intermediate Certificate', 
        SHA_1_Fingerprint__c = '12:34:56:78:90:12:34:56:78:90:12:34:56:78:90:12:34:56:78:03',
        Auditor__c = 'WebTrust', Auditor_Qualifications__c = 'Qualifications',
        Auditor_New__c = auditor.Id, Auditor_Location_New__c = auditorlocation.Id,
        Auditor_Website__c = 'www.website.com', Status__c = 'Included');
        insert new List<Account>{acc1, acc2};
        
        PageReference pref = Page.MassUpdateAuditCPCPSData;
        Test.setCurrentPage(pref);
        
        ApexPages.currentPage().getParameters().put('Id', acc1.Id);
        
        ApexPages.standardController stdCon = new ApexPages.standardController(acc1);
        MassUpdateAuditCPCPSDataController obj = new MassUpdateAuditCPCPSDataController(stdCon);
        //obj.GetAllCertificates(); 
        obj.syncStdAuditFieldsOnTargetAccount();
        obj.syncAuditorNewFieldsOnTargetAccount();
        obj.syncCodeSigningAuditFieldsOnTargetAccount();
        obj.syncBRAuditFieldsOnTargetAccount();
        obj.syncEVSSLAuditFieldsOnTargetAccount();
        obj.syncEVCodeSigningAuditFieldsOnTargetAccount();
        obj.syncPolicyFieldsOnTargetAccount();
        obj.syncMozillaFieldsOnTargetAccount();
        obj.syncMicrosoftFieldsOnTargetAccount();
        obj.redirectToNextAccount();
        obj.redirectTosourceAccount();
        obj.checkPortalUserValidation();
        obj.redirectFromLandingPage();
    }
    
}
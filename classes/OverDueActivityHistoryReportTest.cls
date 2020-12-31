/*
    Description: Test class for OverDueActivityHistoryReport
*/
@isTest
public class OverDueActivityHistoryReportTest {
    
    static testmethod void testOverDueActivity(){ 
        
        Account caOwnerAcc = TestUtils.getCAOwner();
        caOWnerAcc.Status__c = 'Included';
        insert caOwnerAcc;
        
        Task taskSo = new Task();
        taskSo.subject = 'Mozilla: Your root is in danger of being removed';
        taskSo.Description = 'Mozilla: Your root is in danger of being removed'; 
        taskSo.status = 'Completed';
        taskSo.OwnerId = UserInfo.getUserID(); 
        taskSo.Standard_Audit_Statement_Date__c = system.today().addDays(-450);       
        taskSo.WhatId = caOwnerAcc.Id;
        insert taskSo;
        
        caOwnerAcc = TestUtils.getCAOwner();
        caOWnerAcc.Status__c = 'Included';
        insert caOwnerAcc;
        
        taskSo = new Task();
        taskSo.subject = 'Mozilla: Overdue Audit Statements';
        taskSo.Description = 'Mozilla: Overdue Audit Statements'; 
        taskSo.status = 'Completed';
        taskSo.OwnerId = UserInfo.getUserID();        
        taskSo.WhatId = caOwnerAcc.Id;
        taskSo.Standard_Audit_Statement_Date__c = system.today().addDays(-450);
        insert taskSo;
        
        OverDueActivityHistoryReport objOverDue = new OverDueActivityHistoryReport();
        objOverDue.getCurrentDate();
    }
}
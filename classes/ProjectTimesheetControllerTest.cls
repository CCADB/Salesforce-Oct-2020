@isTest
public Class ProjectTimesheetControllerTest{
    
    public static testmethod void testTimesheet(){
        
        Project_Tracker__c project = new Project_Tracker__c(Name = 'Jixi');
        insert project;
        
        Project_Goal__c pg = new Project_Goal__c(Project_Name__c = project.Id, Status__c = 'Work In Progress', Priority__c = 1, Goal__c = 'Jixi Service', Budgeted_Hours__c = 100);
        insert pg;
        
        Project_Activity__c pa1 = new Project_Activity__c(Project_Goal__c = pg.Id, Hours__c = 2, Activity__c = 'Activity 1', Activity_Date__c = System.today().addDays(-5), Status__c = 'Not Yet Started');
        Project_Activity__c pa2 = new Project_Activity__c(Project_Goal__c = pg.Id, Hours__c = 4, Activity__c = 'Activity 2', Activity_Date__c = System.today().addDays(-5), Status__c = 'Complete');
        Project_Activity__c pa3 = new Project_Activity__c(Project_Goal__c = pg.Id, Hours__c = 6, Activity__c = 'Activity 3', Activity_Date__c = System.today(), Status__c = 'Work In Progress');
        Project_Activity__c pa4 = new Project_Activity__c(Project_Goal__c = pg.Id, Hours__c = 8, Activity__c = 'Activity 4', Activity_Date__c = System.today(), Status__c = 'Incomplete');
        Project_Activity__c pa5 = new Project_Activity__c(Project_Goal__c = pg.Id, Hours__c = 10, Activity__c = 'Activity 5', Activity_Date__c = System.today().addDays(-3), Status__c = 'Complete');
        
        insert new List<Project_Activity__c>{pa1, pa2, pa3, pa4, pa5};
        
        ProjectTimesheetController obj = new ProjectTimesheetController();
            
        System.assertEquals(obj.lstActivities.size(), 3);
    }
}
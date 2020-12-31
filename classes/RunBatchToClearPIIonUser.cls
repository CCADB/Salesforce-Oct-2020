/*******************************************************************************************************
 Name: RunaBatchToClearPIIonUser

 Dependencies: RunBatchToClearPIIonUser, RunBatchToClearPIIonUserTest,
 RunBatchProcesses, RunBatchProcessesController, RunBatchProcessesControllerTest

 Description: This batch process has been created to clear the PII information on daily basis.
 
 CompanyName
 Department
 Division
 EmployeeNumber
 Title
 Street
 City
 State
 PostalCode
 Country
 Fax
 Phone
 MobilePhone (cleared this field for Community users and inactive Standard users) 
 
 User Type = 'AutomatedProcess','Guest','CsnOnly','CloudIntegrationUser' are not updated by this program.
 
 Instructions: 
    RUN A BATCH NOW:
       Database.executeBatch(new RunBatchToClearPIIonUser ());
    SCHEDULE A CLASS:
       RunBatchToClearPIIonUser.scheduleMe('Batch to clear PII fields on User Records');
 *******************************************************************************************************
 Revision History:
 
     10/5/2020 - Created new.
     
 ******************************************************************************************************/
public class RunBatchToClearPIIonUser implements Database.Batchable<Sobject>, Schedulable {
    
    public static String sched = '0 0 2 ? * *'; // Everyday 2 AM
   
    public static String scheduleMe(String jobNameStr) {
        RunBatchToClearPIIonUser SC = new RunBatchToClearPIIonUser(); 
        return System.schedule(jobNameStr, sched, SC);
    }
    
    public void execute(SchedulableContext sc) {
        //invoke the batch class
        Database.executeBatch(new RunBatchToClearPIIonUser());
    }
    
    public Database.QueryLocator start(Database.BatchableContext BC){
        string Query = 'Select Id, IsActive, UserType, Division, EmployeeNumber, CompanyName, Department, Title, Street, City, State, PostalCode, Country, Fax, Phone, MobilePhone, ContactId from User Where UserType not in (\'AutomatedProcess\',\'Guest\',\'CsnOnly\',\'CloudIntegrationUser\')';
        if(Test.isRunningTest()){
            Query += ' Limit 10 ';
        }
        return Database.getQueryLocator(Query);
    }
    
    public void execute(Database.BatchableContext BC, List<User> lstUsers){
        List<User> lstUserToUpdate = new List<User>();
        for(User u: lstUsers){
            boolean isUserUpdate = false;
            if(u.Department != null || u.Title != null || u.Street != null || u.City != null || u.Division != null ||
                u.State != null || u.PostalCode != null || u.Country != null || u.Fax != null || u.Phone != null || u.CompanyName != null ||
                u.EmployeeNumber != null) {
                u.Department = '';
                u.Title = '';
                u.Street = '';
                u.City = '';
                u.State = '';
                u.PostalCode = '';
                u.Country = '';
                u.Fax = '';
                u.Phone = '';
                u.Division = '';
                u.CompanyName = '';
                u.EmployeeNumber = '';
                isUserUpdate = true;
            }
            if(u.UserType != 'Standard' || u.IsActive == false) {
                if(u.MobilePhone != null){
                    u.MobilePhone = '';
                    isUserUpdate = true;
                }
            }
            if(isUserUpdate){
                lstUserToUpdate.add(u);
            }
        }
        if(lstUserToUpdate.size() > 0){
            update lstUserToUpdate;
        }
    }
    
    public void finish(Database.BatchableContext BC){
    }
}
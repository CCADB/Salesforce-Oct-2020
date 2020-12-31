/*
    Description: Schedule class for Updateing Last Login to Salesforce 
*/
public class UpdateLastLoginSchedulerClass implements Schedulable{
   
    // To schedule this Apex class use the developer console and run UpdateLastLoginSchedulerClass.scheduleMe('Update Last Login');
   
    public static String sched = '0 0 4 ? * *';  // every Sunday at 6AM
   
    public static String scheduleMe(String jobNameStr) {
        UpdateLastLoginSchedulerClass  SC = new UpdateLastLoginSchedulerClass(); 
        return System.schedule(jobNameStr, sched, SC);
    }

    public void execute(SchedulableContext sc) {
        UpdateLastLoginController.UpdateContacts();
    }
}
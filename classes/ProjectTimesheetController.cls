//Controller for ProjectTimesheet
// Displays all the activities in a single day by aggregating hours and concatinating activity
public class ProjectTimesheetController {
    
    Public List<Activities> lstActivities {get; set;}
    
    public ProjectTimesheetController(){
        
        this.lstActivities = getActivities();
        //System.debug(JSON.serialize(lstActivities));
    }
    
    public List<Activities> getActivities(){
        
        Map<String, Activities> mapDateWiseActivities = new Map<String, Activities>();
         
        for(Project_Activity__c pa : [SELECT Id, Hours__c, Activity__c, Activity_Date__c
                                      FROM Project_Activity__c 
                                      WHERE Activity_Date__c <> NULL 
                                      AND Status__c != 'Not Yet Started'
                                      ORDER BY Activity_Date__c]){
            
            String formattedDate = getDateString(pa.Activity_Date__c);                         
            if(mapDateWiseActivities.containsKey(formattedDate)){
                
                Activities activity = mapDateWiseActivities.get(formattedDate);
                activity.Hours = activity.Hours + pa.Hours__c; 
                
                if(activity.Activity != null){
                    activity.Activity = activity.Activity + '; ' + pa.Activity__c;
                }else{
                    activity.Activity = pa.Activity__c;
                }
            }
            else{
                
                mapDateWiseActivities.put(formattedDate, new Activities(formattedDate, pa.Activity__c, pa.Hours__c));
            }
        }
        
        return mapDateWiseActivities.values();
    }
    
    public String getDateString(Date dateToFormat){
        
        String formattedDate = null;
        
        if(dateToFormat != null){
            formattedDate = dateToFormat.format();
        }
        
        return formattedDate;
    }
    
    public class Activities {
        
        Public String ActivityDate {get; set;}
        Public String Activity {get; set;}
        Public Decimal Hours {get; set;}
            
        public Activities(String ActivityDate, String Activity, Decimal Hours){
            
            this.ActivityDate = ActivityDate;
            this.Activity = Activity;
            this.Hours = Hours;
        }
    }
    
    
         
     String CurrentDate = ' ';
 
    // Get current Datetime in long date format   

    public String getCurrentDate() {

      Datetime cDT = System.now();
      CurrentDate = cDT.format('MMMM d, yyyy');

      return CurrentDate;

   }
}
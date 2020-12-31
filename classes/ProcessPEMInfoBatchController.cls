// this is the controller class for the ProcessPEMInfoBatch VF page. 
public class ProcessPEMInfoBatchController{

// var which holds the exception message
 public String errorText {get;set;}
 
 // method which executes the batch job
 public void startBatch()
  
  {
     errorText = ' ';
   
       Database.executeBatch(new ProcessPEMInfoBatch(),1);  
 
  }
  
}
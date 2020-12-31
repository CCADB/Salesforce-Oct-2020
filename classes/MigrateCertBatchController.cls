/*
Class        : MigrateCertBatchController
Description  : Triggers batch process to load certificates, prepares certificates for processing 
Used By      : MigrateCertBatchVF
*/

public class MigrateCertBatchController{


    // var which holds the exception message 
    public String errorText {get;set;}
 
    // var which holds radio button selection 'Root Certificates'/'Intermedite Certificates'
    //public String processSelection = null;
    private String processSelection;// {get;set;}
    
    // get method
    public String getprocessSelection() {
        return processSelection;
    }                    

    // set method
    public void setprocessSelection (String processSelection) {
        this.processSelection = processSelection;        
    }
    
    // set options for radio button           
    public List<SelectOption> getItems() {
        List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption('Root Certificates','Root Certificates'));
        options.add(new SelectOption('Intermediate Certificates','Intermediate Certificates'));
        return options;
    }
                  
 
    // method which executes the batch job  
    public void startBatch() {
         system.debug('processSelection1:'+processSelection);
          errorText = ' ';   
          Database.executeBatch(new MigrateCertsBatch(processSelection),1);   
    }
   
    // Prepares certificates for processing 
    public PageReference prepareCerts() 
    {
     
     List<Migrate_Certs__c> listOfCerts = new List<Migrate_Certs__c>();
     
     for(Migrate_Certs__c migCerts : [select Id, Name, Processing_Status__c, Certificate_Processed__c
                                     from Migrate_Certs__c 
                                     where Processing_Status__c != 'Migration Successful'
                                     AND Certificate_Processed__c = True]){
                                    
         migCerts.Certificate_Processed__c = false;
         listOfCerts.add(migCerts);     
     
     }
     
     
     if(listOfCerts.size()>0){
         upsert listOfCerts;
     }  
   
     return null;
  }
  
}
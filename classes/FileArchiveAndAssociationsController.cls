/*
    Description: Controller is created for Microsoft and give File Archive & Association records in CSV
*/
public without sharing class FileArchiveAndAssociationsController {
    
    public List<wrapFileArchiveAssoc> lstwrapAllFileArchiveAssoc {get; set;}
    
    public FileArchiveAndAssociationsController(){
        lstwrapAllFileArchiveAssoc = new List<wrapFileArchiveAssoc>();
        List<File_Archive_Association__c> lstTempFA = new List<File_Archive_Association__c>([select ID, Name,
                File_Archive__r.Name, File_Archive__r.CA_Owner__r.Name, Certificate_Name__r.RecordType.Name,
                Certificate_Name__r.Microsoft_Status__c, Certificate_Name__r.Microsoft_Root_Status__c,
                File_Archive__r.External_Link__c,File_Archive__r.Internal_Link__c,
                File_Archive__r.Document_Type__c,File_Archive__r.Audit_Statement_Date__c,File_Archive__r.Period_Start_Date__c,
                File_Archive__r.Period_End_Date__c,File_Archive__r.Auditor__c,File_Archive__r.Auditor_Location__c,
                File_Archive__r.Audit_Deviation__c, CA_Owner_Certificate_No__c, 
                Certificate_Name__r.Name, Certificate_Type__c, SHA_1_Fingerprint__c,
                CreatedDate,LastModifiedDate
                FROM File_Archive_Association__c 
                Order by File_Archive__r.CA_Owner__r.Name, File_Archive__r.Name]);
                
        for(File_Archive_Association__c FA: lstTempFA){
            if(FA.File_Archive__r.Document_Type__c != null && FA.File_Archive__r.Document_Type__c.contains(';')){
                string[] docType = FA.File_Archive__r.Document_Type__c.split(';');
                for(string dt:  docType){
                    if(string.isnotblank(dt)){
                        lstwrapAllFileArchiveAssoc.add(new wrapFileArchiveAssoc (FA, dt.trim()));
                    }
                }               
            } else {
                lstwrapAllFileArchiveAssoc.add(new wrapFileArchiveAssoc (FA, FA.File_Archive__r.Document_Type__c));
            }
        }
    }
    
    public class wrapFileArchiveAssoc {
        public File_Archive_Association__c FA {get; set;}
        public string DocumentType {get; set;}
        public wrapFileArchiveAssoc (File_Archive_Association__c f, string dt){
            this.FA = f;
            this.DocumentType = dt;
        }
    }
    
}
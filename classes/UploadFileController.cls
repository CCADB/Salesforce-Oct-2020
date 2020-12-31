/*
* Controller will invoked when user upload an audit file for Standard Audit/BR Audit or EV Audit
* A formula field with upload symbol can be configured to start the upload ...
*     IF(ISBLANK(Standard_Audit_Statement_Link__c), '<Provide link before uploading>',
*     HYPERLINK("/apex/UploadFile?id="&Id&"&documentType=Standard Audit", 
*     IMAGE("/resource/Add_Upload_File_Icon","Add/Upload File", 30, 75), "_self"))
*/
public with sharing class UploadFileController {   /***** UNUSED APEX CONTROLLER
    
    
    public String fileName{get; set;}//name of the uploaded file
    public Blob fileData {get; set;}//data of the uploaded file
    
    private String folderId;//Id of the document folder in which uploaded file is going to store
    private Case caseObj;//case object
    private String documentType;
    //constructor
    public UploadFileController(ApexPages.StandardController controller) {
        this.folderId = [SELECT Id from Folder where Name = 'Audit Files' Limit 1][0].Id;
        this.caseObj = [SELECT Id, AccountId FROM Case WHERE Id = :controller.getId()];
        this.documentType = ApexPages.currentPage().getParameters().get('documentType');
    }
    
    public PageReference uploadFile(){  
        system.debug('** '+fileName);
        
        //If file is not uploaded and user clicks on "Upload" button then display an error
        if(String.isBlank(fileName)){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Please choose a file to upload.'));
            return null;
        } 
        
        
        // Document doc = new Document(FolderId = this.folderId, Name = fileName, 
        // Body = fileData, Description = documentType + ' Document');//Prepare Document from an uploaded file
        // insert doc;
      
        
        Attachment doc = new Attachment(Name = fileName, ParentId = caseObj.Id,
        Body = fileData, Description = documentType + ' Document');//Prepare Document from an uploaded file
        insert doc;
        
        // String internalURL = System.URL.getSalesforceBaseUrl().toExternalForm() + '/' + doc.Id; // link to the document record
        String internalURL = System.URL.getSalesforceBaseUrl().toExternalForm() + '/servlet/servlet.FileDownload?file='+ doc.Id;  // link to the actual document 

        if(this.documentType == 'Standard Audit'){
            caseObj.Standard_Audit_Statement_Internal_Link__c = internalURL;//set Standard Audit internal audit link
            caseObj.Standard_Audit_Verified__c = 'Not Verified';
        }
        if(this.documentType == 'BR Audit'){
            caseObj.BR_Audit_Statement_Internal_Link__c = internalURL;//set BR Audit internal audit link
            caseObj.BR_Audit_Statement_Link_Verified__c = 'Not Verified';
        }
        if(this.documentType == 'EV Audit'){
            caseObj.EV_Audit_Statement_Internal_Link__c = internalURL;//set EV Audit internal audit link
            caseObj.EV_Audit_Statement_Link_Verified__c = 'Not Verified';
        }
        
        
        // CP and CPS documents are typically very big, hence these documents will not be uploaded by the user
        // if(this.documentType == 'CP'){
        //    caseObj.Certificate_Policy_Internal_Link__c = internalURL;//set CP internal audit link
        //    caseObj.CP_CPS_Links_Verified__c = 'Not Verified';
        // }
        // if(this.documentType == 'CPS'){
        //    caseObj.Certification_Practice_St_InternalLink__c = internalURL;//set CPS internal audit link
        //    caseObj.CP_CPS_Links_Verified__c = 'Not Verified';
        // }
        
        update caseObj;//update case record with the internal audit link
         
        return new PageReference('/'+this.caseObj.Id);//redirect back to case record.
        
       
    }   ****/

}
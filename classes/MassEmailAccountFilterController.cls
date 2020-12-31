global with sharing class MassEmailAccountFilterController extends SmartFilter.PageControllerBase {
  public List<Account> objectList{get;set;}
  public id massEmailRecordId {get;set;}
  public Mass_email__c massEmailSo {get;set;}
  public Mass_email__c massEmailParamSo {get;set;}
    public Boolean isSaved {get;set;}
    public ApexPages.StandardController stdController { get; set; }

  public MassEmailAccountFilterController(ApexPages.StandardController controller) {
        stdController = controller;
        this.massEmailParamSo = (Mass_email__c)controller.getRecord();
       massEmailRecordId= massEmailParamSo.id;
    String isSavedParam =  ApexPages.currentPage().getParameters().get('isSaved');
     if(isSavedParam!=null && isSavedParam.length() > 0)
     {
           this.isSaved = true;
     }
     else
     {
       this.isSaved = false;
        massEmailSo = [select SOQL_Filter_Conditions__c from mass_email__c where id = :massEmailRecordId limit 1];
     }
      
    }
    public MassEmailAccountFilterController(){
     objectList = new List<Account>();
     massEmailRecordId= ApexPages.currentPage().getParameters().get('id');
     String isSavedParam =  ApexPages.currentPage().getParameters().get('isSaved');
     if(isSavedParam!=null && isSavedParam.length() > 0)
     {
           this.isSaved = true;
     }
     else
     {
       this.isSaved = false;
        massEmailSo = [select SOQL_Filter_Conditions__c from mass_email__c where id = :massEmailRecordId limit 1];
     }
    
 }

   public SmartFilter.SmartFiltersComponentController myComponentController {set;
     get{ 

         if(getComponentControllerMap()!=null){
             SmartFilter.SmartFiltersComponentController mcc; mcc = (SmartFilter.SmartFiltersComponentController) getComponentControllerMap().get('Account');
             if(mcc!= null)
             return mcc;
         }
     
     return new SmartFilter.SmartFiltersComponentController();
   }
 } 

 
    public void fetchAccounts() {
    
     String predicates = myComponentController.fetchQuery();
     // System.debug('Fetch Test Query Result.............'+predicates);
     massEmailSo.SOQL_Filter_Conditions__c = predicates;
     update massEmailSo;
     this.isSaved = true;
     // PageReference parentRecordPage = new PageReference('/apex/MassEmailAccountFilter?isSaved=true');
     // parentRecordPage.setRedirect(true);
    
    
 }
    public PageReference goBackToMassEmailRecord() {
    
     PageReference parentRecordPage = new PageReference('/'+massEmailSo.id);
     parentRecordPage.setRedirect(true);
     return parentRecordPage;
    
 }
 
 
 
}
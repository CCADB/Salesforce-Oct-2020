public class CACommunicationSurveySampleController {
    
    public String selectedSurveyId{get; private set;}//selected survey id by user on page
    public List<Question> lstQuestions {get; set;}//list of Question to display on to display on VF page
    public String communicationTitle {get; private set;}//survey title on survey form page
    public String communicationMessage {get; private set;}//survey message on survey form page
    public Boolean hasError{get; private set;}//will be true in case of errors
    
    public class SurveyException extends Exception{}//exceptions
    
    public CACommunicationSurveySampleController(){
         
         this.lstQuestions = new List<Question>();
         this.hasError = true;
         this.selectedSurveyId = ApexPages.currentPage().getParameters().get('CACommunicationId');
         Id surveyId;
         
        try{
            surveyId = Id.valueOf(selectedSurveyId);
            List<CA_Communication__c> communications = [SELECT Id, Name, Message__c, Expiration_Date__c
                                                        FROM CA_Communication__c
                                                        WHERE Id = :surveyId];
             
             if(communications.size() > 0){
                 
                 communicationTitle = communications[0].Name;
                 communicationMessage = communications[0].Message__c != null ? communications[0].Message__c.replaceAll('\n', '<br/>') : null;
                 fetchReadOnlySurvey();
                 this.hasError = false;
             }else{
                 throw new SurveyException('No survey found for specified link.');
             }
             
        }catch(StringException stEx){//this exception will be thrown if the SurveyId is not valid
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, 'Invalid Survey Id.'));
        }catch(SurveyException sExp){//this exception will be thrown if the SurveyId is valid but Survey not found. may be deleted.
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, sExp.getMessage()));
        }catch(Exception exp){//any general exception will be trapped here.
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, exp.getMessage()));
        }
    }
    
    //fetch read only survey
    public void fetchReadOnlySurvey(){
        
        for(CA_Comm_Question__c que : [SELECT Id, Name, CA_Comm__r.Name, CA_Comm__r.Message__c, Required__c, Order_No__c, Question__c, 
                                        Question_Type__c, Response_Option_1__c, Response_Option_2__c, 
                                        Response_Option_3__c, Response_Option_4__c, Response_Option_5__c, Response_Option_6__c, Response_Option_7__c,
                                        Default_Text__c,
                                        Response_Option_8__c, Response_Option_9__c, Response_Option_10__c, Response_Option_11__c, Response_Option_12__c
                                        FROM CA_Comm_Question__c
                                        WHERE CA_Comm__c = :selectedSurveyId
                                        ORDER BY Order_No__c ASC]){
            
            lstQuestions.add(new Question(que));
        }
    }
    
    /** Class: question
    *  Retrieves the question information and puts it in the question object
    */      
    public class Question{
        
      public String Id {get; private set;}
      public String iQuestion {get; private set;}
      public boolean isRequired {get; private set;}//true indicates question is mandatory
      public String renderSelectRadio {get; private set;}
      public String selectedOption {get; set;}//not required I guess
      public List<SelectOption> singleOptions{get; set;}
      public String renderSelectCheckboxes {get; set;}
      public List<String> selectedOptions {get; set;}
      public List<SelectOption> multiOptions {get; set;}
      public String renderFreeText {get; private set;}
      public String choices {get; set;}
      public Date dateResonse{get; set;}
      public String renderDateType{get; set;}
      
     public Question(CA_Comm_Question__c sq) {
        
        Id = sq.Id;
        iQuestion = sq.Question__c != null ? sq.Question__c.replaceAll('\n', '<br/>') : null;
        isRequired = sq.Required__c;
        choices = sq.Default_Text__c;
        selectedOption = '';
        selectedOptions = new List<String>();
        singleOptions = new List<SelectOption>();
        multiOptions = new List<SelectOption>();
        renderDateType = 'false';
        dateResonse = null;
        
        if(sq.Question_Type__c == 'Multi Select (Check boxes)'){
                
            renderSelectCheckboxes = 'true';
            multiOptions = stringToSelectOptions(sq);
            renderSelectRadio='false';
            renderFreeText='false';
            selectedOption = '';
        }
        
        else if(sq.Question_Type__c == 'Single Select (Radio buttons)'){//radio vertical
            
            renderSelectRadio = 'true';
            singleOptions = stringToSelectOptions(sq);
            renderSelectCheckboxes='false';
            renderFreeText = 'false';
            selectedOption = '';
            selectedOptions = new List<String>();
          }
              
        else if (sq.Question_Type__c == 'Free Text (Multi line text box)'){
            
            renderFreeText = 'true';
            renderSelectRadio= 'false';
            renderSelectCheckboxes = 'false';
        }
        
        else if(sq.Question_Type__c == 'Date Type'){
            
            renderSelectRadio = 'false';
            renderSelectCheckboxes='false';
            renderFreeText = 'false';
            renderDateType = 'true';
        }
    }
    //this will prepare the list of options available to user for a particular question (passed as an argument) - there are 12 responses can be available
    public List<SelectOption> stringToSelectOptions(CA_Comm_Question__c questionSO){
        
        Integer index = 0;
        List<SelectOption> lstOptions = new List<SelectOption>();
        
        for(Integer i = 0; i < 12; i++){
            
            String fieldAPI = 'Response_Option_'+String.valueOf(i+1)+'__c';
            fieldAPI = String.valueOf(questionSO.get(fieldAPI));
            if(fieldAPI != '' && fieldAPI != null){
                lstOptions.add(new SelectOption(String.valueOf(i), fieldAPI));
                index++;
            }
        }
        
        return lstOptions;
    }
  }
}
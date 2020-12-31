public class CACommunicationSurveyController {
    
    public List<CA_Communication__c> lstSurvey{get; set;}//list of survey display on page - user will choose one of the survey
    public Map<Id, String> mapMessages{get; set;}
    public Map<Id, CA_Communication__c> mapSurvey{get; private set;}//map of survey with survey Id - used when we require survey info on qustionnarie page
    //public CA_Communication__c survey {get; private set;}
    private String contactId;//contact id of logged in user
    private String accountId;//account id of contact of logged in user
    //private String CACommunicationId;
    public Boolean thankYouRendered{get; set;}//set to true when process completes and show thank you message
    public String thankYouMessage {get; private set;}//thank you message string
    public String selectedSurveyId{get; set;}//selected survey id by user on page
    public Boolean showSurvey {get; set;}//true when to display on survey page - false for survey form page
    //public List<String> strList {get; set;} // The question's option as a list of string
    public List<CA_Comm_Question__c> surveyQuestions{get; set;}//list of questions Sobject; need to prepare Qution Wrapper data
    //public String   singleOptionsForChart  {get; set;}
    public List<Question> lstQuestions {get; set;}//list of Question to display on to display on VF page
    public String communicationTitle {get; set;}//survey title on survey form page
    public String communicationMessage {get; set;}//survey message on survey form page
    public Map<String,List<String>> surveyRespMap;//this is very important variable - this will hold the survey and its response; so when user comes back to the survey form again they can see the existing option selected.
    public Boolean isExternalUser {get; private set;}//if external user set to true
    public Boolean isError {get;set;}
    public static final Map<Integer, String> mapMonthByName;//month name from month number - used to preapre thank you message
    
    static{
        mapMonthByName = new Map<Integer, String>{1 => 'January', 2 => 'February', 3 => 'March', 4 => 'April', 5 => 'May', 6 => 'June', 7 => 'July', 
        8 => 'August', 9 => 'September', 10 => 'October', 11 => 'November', 12 => 'December'};
    }
    
    public CACommunicationSurveyController(){
try {         
         this.isError = false;
       this.lstSurvey = new List<CA_Communication__c>();
         this.mapMessages = new Map<Id, String>();
         this.mapSurvey = new Map<Id, CA_Communication__c>();
         this.surveyQuestions = new List<CA_Comm_Question__c>();
         this.showSurvey = true;
         this.lstQuestions = new List<Question>();
         this.thankYouRendered = false;
         this.isExternalUser = false;
         
         this.selectedSurveyId = ApexPages.currentPage().getParameters().get('CACommunicationId');
         this.contactId = ApexPages.currentPage().getParameters().get('ContactId');
         
         if(selectedSurveyId != null && selectedSurveyId != '' && contactId != null && contactId != ''){
              
              this.showSurvey = false;
              mapSurvey = new Map<Id, CA_Communication__c>([SELECT Id, Name, Message__c, Expiration_Date__c
                                                            FROM CA_Communication__c
                                                            WHERE Id = :selectedSurveyId]);
               
              //if the survey is opened through link then don't show survey list screen - open survey form direclty with pre-populated answers                                             
              lstSurvey = [SELECT Id, Name, Message__c, Expiration_Date__c
                             FROM CA_Communication__c
                             WHERE Id = :selectedSurveyId];
                
             communicationTitle = lstSurvey[0].Name;
             communicationMessage = lstSurvey[0].Message__c != null ? lstSurvey[0].Message__c.replaceAll('\n', '<br/>') : null;
             getUserContact();
             getQuesionnairies();
            
         }else{
          
          mapSurvey = new Map<Id, CA_Communication__c>([SELECT Id, Name, Message__c, Expiration_Date__c
                                                        FROM CA_Communication__c
                                                        ORDER BY Expiration_Date__c DESC]); 
                                                        
          lstSurvey = [SELECT Id, Name, Message__c, Expiration_Date__c
                     FROM CA_Communication__c
                     ORDER BY Expiration_Date__c DESC];
                     //WHERE Expiration_Date__c > TODAY -> Change request: remove expiration date - if expired display read only survey
         }
         
         if(lstSurvey.size() > 0){
             for(CA_Communication__c commun : lstSurvey){
                 String comm_message = commun.Message__c != null ? commun.Message__c.replaceAll('\n', '<br/>') : '';
                 mapMessages.put(commun.Id, comm_message);
             } 
         } 
                 }catch (exception ex) {
 system.debug( 'Exception: ' + ex.getTypeName() + ': ' + ex.getMessage() 
    + ' -- ' + ex.getCause()); }
 
    }
    
    //get the contact and account detail from the logged in user's id - determine the user type (internal or external)
    public void getUserContact(){
               isError=false;
        if(this.contactId != null && this.contactId != '' && this.selectedSurveyId != null && this.selectedSurveyId != ''){
            List<Contact> existingContact = [SELECT Id, AccountId FROM Contact WHERE Id = :this.contactId];
            if(existingContact.size() > 0){
                this.accountId = existingContact[0].AccountId;
            }else{
                isError=true;
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Specified Contact doesn\'t exist.'));
                return;
            }
        }else{
            
            // User userSO = [SELECT ContactId, Contact.AccountId FROM User WHERE Id = '005q00000029udB'];//:UserInfo.getUserId()
            User userSO = [SELECT ContactId, Contact.AccountId, Profile.Name, UserType FROM User WHERE Id = :UserInfo.getUserId()];
            this.contactId = userSO.ContactId;
            this.accountId = userSO.Contact.AccountId;
            if(userSO.UserType == 'PowerCustomerSuccess'){
                this.isExternalUser = true;
            }
        }
    }
    
    //upon cancel clear all the values and re-render the page
    public PageReference doCancel(){
        isError=false;
        this.lstQuestions.clear();
        this.surveyQuestions.clear();
        this.selectedSurveyId = null;
        this.showSurvey = true;
        this.thankYouRendered = false;
        this.surveyRespMap.clear();
        this.communicationTitle = '';
        this.communicationMessage = '';

       return null;
    }
    
    //save the survey - before saving the survey - delete old responses to selected survey
    // if any required survey question is blank - stop the process and inform user
    // prepare CA Comm URLs object and populate link to that
    //at the end prepare thank you message and set thankyou flag to true and re-render the page
    public PageReference submitResults() {
        isError=false;       
        List <CA_Comm_Response__c> sqrList = new List<CA_Comm_Response__c>();
        
        for (Question q : lstQuestions) {
                                     system.debug('q.date is -->' + q.datestr);
            
            CA_Comm_Response__c sqr = new CA_Comm_Response__c();
            sqr.CA_Owner__c = this.accountId;
            sqr.Contact__c = this.contactId;
            
            if (q.renderSelectRadio == 'true') {
                
                if (q.required &&  (q.selectedOption == null || q.selectedOption == '')) {
                    isError=true;

                    Apexpages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Please fill out all required fields'));
                    return null;
                }
                
                if (q.selectedOption == null || q.selectedOption == '') {
                    sqr.Response__c = '';
                }
                else {
                    
                    sqr.Response_Option_No__c = String.valueOf(Integer.valueOf(q.selectedOption) + 1);
                    sqr.Response__c = q.singleOptions.get(q.responseIndextoListIndex.get(q.selectedOption)).getLabel();
                }
                
                if(String.isBlank(sqr.Response__c) || sqr.Response__c == null){
                    continue;
                }
                
                sqr.Question_Id__c = q.Id;
                sqrList.add(sqr);
            }
            
            else if (q.renderFreeText == 'true') {
                 
                if (q.required && (q.choices == '' || q.choices == null)) {
                    isError=true;

                    Apexpages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Please fill out all required fields'));
                    return null;
                }
                
                //if user didnt fill anything in response then put default text
                sqr.Response__c = String.isBlank(q.choices) ? q.defaultText : q.choices;
                
                sqr.Question_Id__c = q.Id;
                
                if (String.isBlank(sqr.Response__c) || sqr.Response__c == null) {
                    continue;
                }
                
                sqrList.add(sqr);
            }
            
            else if (q.renderSelectCheckboxes == 'true') {
                
                if (q.required && (q.selectedOptions == null || q.selectedOptions.size() == 0)) {
                    isError=true;

                    Apexpages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Please fill out all required fields'));
                    return null;
                }
                
                for (String opt : q.selectedOptions) {
    
                    sqr = new CA_Comm_Response__c();
                    
                    if (opt == '' || opt == null) {
                        sqr.Response__c = '';
                    }               
                    else {   
                        
                        sqr.Response_Option_No__c = String.valueOf(Integer.valueOf(opt)+1);
                        sqr.Response__c = q.multiOptions.get(q.responseIndextoListIndex.get(opt)).getLabel();
                    }
                    
                    sqr.CA_Owner__c = this.accountId;
                    sqr.Contact__c = this.contactId;
                    sqr.Question_Id__c = q.Id;
                    if(String.isBlank(sqr.Response__c) || sqr.Response__c == null){
                        continue;
                    }
                    sqrList.add(sqr);
                }
            }
            
            else if (q.renderDateType == 'true') {
                
                if(q.required && (q.dateStr ==null || q.dateStr.length() ==0 || q.dateStr.trim().length() ==0))
                    {
                      q.dateResonse.Date_Type_Response__c = null;
                    Apexpages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Please fill out all required fields'));
                    return null;
                     }
                
                else {
                    if(q.dateStr ==null || q.dateStr.length() ==0 || q.dateStr.trim().length()==0)
                    {
                      q.dateResonse.Date_Type_Response__c = null;
                     }
                     else
                     { 
                        Date finaldate ;
                        q.dateStr = q.dateStr.trim();
                        string datestr = q.dateStr.substring(3,5);
                        string monthstr = q.dateStr.substring(0,2);
                        string yearStr = q.dateStr.substring(6,10);

                        try {          
                             q.dateResonse.Date_Type_Response__c = date.newInstance(Integer.valueOf(yearStr),Integer.valueOf(monthStr),Integer.valueOf(dateStr));     
                        } 
                        catch(exception ex)
                        {
                          system.debug('exception-->' + ex.getmessage());
                        }
                     }
                    sqr.Date_Type_Response__c = q.dateResonse.Date_Type_Response__c;
                    sqr.Response__c = (q.dateResonse != null && q.dateResonse.Date_Type_Response__c != null) ? q.dateResonse.Date_Type_Response__c.year() + ' ' + mapMonthByName.get(q.dateResonse.Date_Type_Response__c.month()).left(3) + ' ' + q.dateResonse.Date_Type_Response__c.day() : '';
                } 
                
                sqr.Question_Id__c = q.Id;
                sqrList.add(sqr);
            }
        }
        

                    
        
        if(sqrList.size() > 0) {
            
            List<CA_Comm_Response__c> lstOldQuestion = [SELECT Id, CA_Owner__c, Contact__c, Response__c, Response_Option_No__c, Question_Id__r.CA_Comm__c
                                                        FROM CA_Comm_Response__c 
                                                        WHERE Contact__c = :contactId 
                                                        AND CA_Owner__c = :accountId
                                                        AND Question_Id__r.CA_Comm__c = :selectedSurveyId];
            Savepoint sp = Database.setSavepoint();
            if(lstOldQuestion.size() > 0){
                delete lstOldQuestion;
            }
            
            try{
                //System.debug('Serialize: '+json.serialize(sqrList));
                insert sqrList;
            }catch(Exception exp){
                Database.rollback(sp);
                isError=true;
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, 'Contact record not found. Login as community user to respond to the survey.'));
                return null;
            }
            List<CA_Comm_URL__c> lstCommUrl = new List<CA_Comm_URL__c>();
            
            if(this.contactId != null && this.contactId != ''){
                lstCommUrl = [SELECT Id, CA_Communication_Title__c, CA_Owner__c, Contact__c, URL__c 
                              FROM CA_Comm_URL__c
                              WHERE Contact__c = :this.contactId
                              AND CA_Owner__c = :this.accountId
                              AND CA_Communication_Title__c = :this.selectedSurveyId];
                              
                  if(lstCommUrl.isEmpty()){
                    
                    String host = ApexPages.currentPage().getHeaders().get('Host');//'https://poonam-mozillacacommunity.cs21.force.com/CA_Communications_Survey';
                    if(System.Test.isRunningTest()){
                        host = 'https://poonam-mozillacacommunity.cs21.force.com/CACommunicationSurvey';
                    }
                    system.debug('HostName is ='  + System.URL.getSalesforceBaseUrl().getHost());
                    system.debug('Host is =' + host);
                    Integer forceDomain = host.indexOf('force.com');
                    host = host.substring(forceDomain - 5, forceDomain - 1);
                    String instanceName = [select InstanceName from Organization limit 1].InstanceName;
                    host = 'https://c.'+instanceName+'.visual.force.com/apex/CACommunicationSurvey?CACommunicationId='+this.selectedSurveyId+'&ContactId='+this.contactId;
                    
                    CA_Comm_URL__c cUrl = new CA_Comm_URL__c();
                    cUrl.CA_Communication_Title__c = this.selectedSurveyId;
                    cUrl.CA_Owner__c = this.accountId;
                    cUrl.Contact__c = this.contactId;
                    cUrl.URL__c = host;
                    lstCommUrl.add(cUrl);
                    system.debug('***'+host);
                  }
                 
                  upsert lstCommUrl;
            }
            
            String dateString = system.today().day() + ' ' + mapMonthByName.get(System.today().month()) + ' ' + System.today().year();
            thankYouMessage = 'Responses submitted by '+UserInfo.getName()+' on '+ dateString +'. Thank you.';
            thankYouRendered = true;
        }
        
        return null;//new PageReference('/'+selectedSurveyId);
    }
    
    //get the questionnaries for the selected survey and prepare question object wrapper
    public void getQuesionnairies(){
        
        System.debug('contactId: '+contactId+' --> '+selectedSurveyId);
        this.showSurvey = false;
        surveyRespMap = new Map<String, List<String>>();
        
        CA_Communication__c survey = mapSurvey.get(selectedSurveyId);
        if(survey.Expiration_Date__c > System.today()){
            this.isExternalUser = false;//meaning if survey is not expired then don't make it read only else make it read only if user is external
        }
        
        this.surveyQuestions = [SELECT Id, Name, CA_Comm__r.Name, CA_Comm__r.Message__c, Required__c, Order_No__c, Question__c, Question_Type__c, Response_Option_1__c, Response_Option_2__c, 
                                Response_Option_3__c, Response_Option_4__c, Response_Option_5__c, Response_Option_6__c, Response_Option_7__c,
                                Default_Text__c,
                                Response_Option_8__c, Response_Option_9__c, Response_Option_10__c, Response_Option_11__c, Response_Option_12__c,
                                (SELECT Id, CA_Owner__c, Contact__c, Response__c, Date_Type_Response__c, Response_Option_No__c
                                FROM CA_Comm_Responses__r WHERE Contact__c = :contactId)
                                FROM CA_Comm_Question__c
                                WHERE CA_Comm__c = :selectedSurveyId
                                ORDER BY Order_No__c ASC];
        
        if(surveyQuestions.isEmpty()){
            this.communicationTitle = '';
            this.communicationMessage = '';
            this.isExternalUser = true;//meaning disable submit button
            isError=true;
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, 'No questions found for this survey'));
            return;
        }
        
        this.communicationTitle = surveyQuestions[0].CA_Comm__r.Name;
        this.communicationMessage = surveyQuestions[0].CA_Comm__r.Message__c;
        
        
        if(communicationMessage != null && communicationMessage != ''){
            this.communicationMessage = communicationMessage.replaceAll('\n', '<br/>');
        }
        
        
        for(CA_Comm_Question__c que : surveyQuestions){
            
            
            List<String> tempList = new List<String>();
            
            for(CA_Comm_Response__c response : que.CA_Comm_Responses__r){
                
                if(que.Question_Type__c != 'Date Type' && response.Response__c != null && response.Response__c != ''){
                    tempList.add(response.Response__c);    
                }
                
                if(que.Question_Type__c == 'Date Type' && response.Date_Type_Response__c != null){
                    tempList.add(String.valueOf(response.Date_Type_Response__c.format()));    
                }
            }
            
            surveyRespMap.put(que.Id, tempList);
            lstQuestions.add(new Question(que,surveyRespMap));
        }
        
        //System.debug('JSON: '+lstQuestions);
    }
    
    /** Class: question
    *  Retrieves the question information and puts it in the question object
    */      
    public class Question{
        
      public String   name                   {get; set;}
      public String   id                           {get; set;}
      public String   iQuestion               {get; set;}
      public String   orderNumber            {get; set;}
      public String   choices                {get; set;}
      public String   selectedOption         {get;set;}
      public List<String> selectedOptions {get;set;}
      public List<SelectOption> singleOptions{get; set;}
      public List<SelectOption> multiOptions {get; set;}
      public Boolean  required               {get; set;}
      public String   questionType           {get; set;}    
      public String   renderFreeText             {get; set;}
      public String   renderSelectRadio      {get; set;}
      public String   renderSelectCheckboxes {get; set;} 
      public String   renderSelectRow        {get; set;}
      
      public String renderDateType {get; set;}
      //public Date dateResonse{get; set;}
      public CA_Comm_Response__c dateResonse {get; set;}
      
      public List<SelectOption> rowOptions   {get; set;}
      public boolean isRequired {get; set;}//true indicates question is mandatory
      public Map<String, Integer> responseIndextoListIndex {get; set;}//this map is used to map response number with the index of response
      public String dateStr {get;set;}
      
      public String defaultText {get; private set;} //Default text set it when submitting servery when choices are empty 
         
     public Question(CA_Comm_Question__c sq, Map<String, List<String>> surveyRespMap) {
        
        this.responseIndextoListIndex = new Map<String, Integer>();
        name = sq.Name;
        id = sq.Id;
        iQuestion = sq.Question__c;
        iQuestion = iQuestion.replaceAll('\n', '<br/>');
        isRequired = sq.Required__c;
        orderNumber = String.valueOf(sq.Order_No__c + 1);
        choices = '';
        required = sq.Required__c;
        questionType = sq.Question_Type__c;
        selectedOption = '';
        selectedOptions = new List<String>();
        Integer i = 1;
        renderDateType = 'false';
        //dateResonse = null;
        dateResonse = new CA_Comm_Response__c();
        defaultText = sq.Default_Text__c;
        
        if(sq.Question_Type__c == 'Multi Select (Check boxes)'){
                
            renderSelectCheckboxes = 'true';
            //multiOptions = stringToSelectOptions(choices);
            multiOptions = stringToSelectOptions(sq);
            Map<String,String> optionLabelValueMap = new Map<String,String>();
            
            for(SelectOption sOption : multiOptions) {
               
               String optionStr = sOption.getLabel();
               optionLabelValueMap.put(optionStr,sOption.getvalue());
            }
            
            renderSelectRadio='false';
            renderFreeText='false';
            renderSelectRow = 'false';
            
          if(surveyRespMap !=null && surveyRespMap.get(sq.Id) != null) {
               
            List<String> tempList = surveyRespMap.get(sq.Id);
            List<String> setSelectedOption = new List<String>();
           
           for(String optionVal: tempList) {
               
                if(optionLabelValueMap.containsKey(optionVal)) {
                       selectedOption = optionLabelValueMap.get(optionVal);
                       setSelectedOption.add(selectedOption);
                    }
                }
                
                selectedOptions = setSelectedOption;
            }
            
            else {
                selectedOptions = new List<String>();
            }
                  
            selectedOption = '';
            
        }
        
        else if(sq.Question_Type__c == 'Single Select (Radio buttons)'){//radio vertical
            
            renderSelectRadio = 'true';
            //singleOptions = stringToSelectOptions(choices);
            singleOptions = stringToSelectOptions(sq);
            Map<String,String> optionLabelValueMap = new Map<String,String>();
            
            for(SelectOption sOption : singleOptions) {
                
                String optionStr = sOption.getLabel();
                optionLabelValueMap.put(optionStr,sOption.getvalue());
                     
            }
            
            renderSelectCheckboxes='false';
            renderFreeText = 'false';
            renderSelectRow = 'false';
            
            if(surveyRespMap!=null && surveyRespMap.get(sq.Id) != null) {
               selectedOption = surveyRespMap.get(sq.Id).size() > 0 ? optionLabelValueMap.get( surveyRespMap.get(sq.Id)[0]) : '';
            }
            else {
                            
               selectedOption = '';
            }
            
            selectedOptions = new List<String>();                               
          }
              
        else if (sq.Question_Type__c == 'Free Text (Multi line text box)'){
            
            renderFreeText = 'true';
            renderSelectRadio= 'false';
            renderSelectCheckboxes = 'false';
            renderSelectRow = 'false';
            choices = sq.Default_Text__c;
                
                if(surveyRespMap != null && surveyRespMap.get(sq.Id) != null) {
                       choices = surveyRespMap.get(sq.Id).size() > 0 ? surveyRespMap.get(sq.Id)[0] : sq.Default_Text__c;
                }
            }
        
         else if(sq.Question_Type__c == 'Date Type'){
             
             renderSelectRow = 'false';
             renderDateType = 'true';
             renderFreeText = 'false';
             renderSelectCheckboxes = 'false';
             renderSelectRadio = 'false';
             try{
             if(surveyRespMap != null && surveyRespMap.get(sq.Id) != null) {
               if(surveyRespMap.get(sq.Id).size() > 0)
               {
               Date dateResonseText = surveyRespMap.get(sq.Id).size() > 0 ? Date.parse(surveyRespMap.get(sq.Id)[0]) : null;
               
               dateResonse.Date_Type_Response__c = dateResonseText;
               datetime dt = datetime.newInstance(dateResonseText.year(), dateResonseText.month(),dateResonseText.day());
               dateStr = dt.format('MM/dd/yyyy');
               }
            }
               }catch (exception ex) {
 system.debug( 'Exception: ' + ex.getTypeName() + ': ' + ex.getMessage() 
    + ' -- ' + ex.getLineNumber()); } 
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
                    this.responseIndextoListIndex.put(String.valueOf(i), index);
                    index++;
                }
            }
            
            return lstOptions;
        }
    }
}
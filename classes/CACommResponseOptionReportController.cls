/** 
This is the class for CACommResponseOptionReport VF page 

**/

public class CACommResponseOptionReportController{

  private String communicationId;
  
  private string questionParamStr;
  
  private Id reportQuestionId;
  
  private String questionIdParam;
  
  private String questionIdForTextParam;
  
  private String questionIdForText;
  
  public String surveyNameStr {get;set;}
  
  public String questionStr {get;set;}
  
  private Boolean hasErrors = false; 
   
  public List<String> optionStrLst{get;set;}
  
  public Map<String,List<String>> answerMap {get;set;}
  
  public Map<String,List<Boolean>> responseMap {get;set;}
  
  public  List<String>  reponseOwnerLst {get;set;}
  
  public List<Integer> responseCountLst {get;set;}
  
  public String textInputNameStr {get;set;}
  
  public   Map<String,String> textInputRespMap {get;set;}
  
  // constructor which intializes the data that is displayed on the page
  public CACommResponseOptionReportController() {
    try {
     // get the parameters from the url and throw error if the param is not available
     if(ApexPages.currentPage().getParameters().get('CommunicationId')!=null)
     {
            communicationId = ApexPages.currentPage().getParameters().get('CommunicationId');     
            system.debug('commid='+communicationId );
     }
     else
     {
       hasErrors=true;
       ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.Error,'Please provide a valid communication id.'));
     }
     
     
     
      if(ApexPages.currentPage().getParameters().get('QuestionId')!=null)
     {
            questionIdParam= ApexPages.currentPage().getParameters().get('QuestionId');
                        system.debug('questionIdParam='+questionIdParam);
            if(questionIdParam.length() == 0)
            {
               hasErrors=true;
               ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.Error,'QuestionId URL param is blank. Please provide a valid Question Id.'));     
            }     
     }
     else
     {
       hasErrors=true;
       ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.Error,'QuestionId URL param is null. Please provide a valid Question Id.'));
     }
     
      if(ApexPages.currentPage().getParameters().get('QuestionIdForText')!=null)
     {
            questionIdForTextParam= ApexPages.currentPage().getParameters().get('QuestionIdForText');     
          system.debug('questionIdForTextParam='+questionIdForTextParam);
            if(questionIdForTextParam.length() == 0)
            {
               hasErrors=true;
               ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.Error,'QuestionIdForText  URL param is blank. Please provide a valid Question Id for text.'));     
            }     

     }
     else
     {
       hasErrors=true;
       ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.Error,'QuestionIdForText URL param is null. Please provide a valid Question Id for text.'));
     }

   
    Map<Id,CA_Comm_Question__c> questionSoMap = New Map<Id,CA_Comm_Question__c>([select id,name,Question__c,CA_Comm__r.name,
    Response_Option_1__c, Response_Option_2__c, Response_Option_3__c, Response_Option_4__c, Response_Option_5__c, Response_Option_6__c, 
    Response_Option_7__c, Response_Option_8__c, Response_Option_9__c, Response_Option_10__c, Response_Option_11__c, Response_Option_12__c,Count_of_Responses__c
      from  CA_Comm_Question__c where CA_Comm__c = :communicationid and name in ( :questionIdParam, :questionIdForTextParam) ]);                                                

    // this field will hold the ID of the text input question
    Id textInputQuestionId;
    
    // if there are one or more questions
    if(questionSoMap!=null && questionSoMap.size() > 0)
    {
      
      for(Id questionId : questionSoMap.keyset())
      {
         // get the question id as we would need to fetch all the answers for this question
         if(questionSoMap.get(questionId).name == questionIdParam)
         {
          reportQuestionId = questionId;
          
          // get the question string
          questionStr = questionSoMap.get(questionId).question__c;
         
         }
          
         if(questionSoMap.get(questionId).name == questionIdForTextParam)
         {
          questionIdForText= questionId;
         }
        
       // get the survey name only once, this is displayed on the top of the page
       if(surveyNameStr==null)
       {
        surveyNameStr =  questionSoMap.get(questionId).CA_Comm__r.name;
       }
       
      }
      
    }
    else
    {
        hasErrors=true; 
        ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.Error,'Survey does not have any questions or Question not found. Make sure you have provided a valid Question Id in the QuestionId URL parameter.'));
    }
    
     // get all the responses for the text input question
     List<CA_Comm_Response__c> textInputRespLst=  [select CA_Owner__r.name, Response__c 
                                                   from   CA_Comm_Response__c 
                                                   where  Question_Id__c = :questionIdForText
                                                   order  by Question_Id__r.Order_No__c  ];
     

     // this map holds the text input response provided by each owner
     textInputRespMap = New Map<String,String>();

     if(textInputRespLst!=null && textInputRespLst.size() > 0)  
     { 
       // loop over all the responses and populate the map
       // this map is used on the VF page to display the responses
       for(CA_Comm_Response__c sqrSo: textInputRespLst) {
        textInputRespMap.put(sqrSo.CA_Owner__r.name,sqrSo.Response__c);
       }
     }
     
     else
     {
       hasErrors=true;
       ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.Error,'No records found for the given QuestionIdForText URL param. Please provide a valid Question Id for text.'));     
     }
     
     if(reportQuestionId==null)
     {
       hasErrors=true;
       ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.Error,'No records found for the given QuestionId URL param. Please provide a valid Question Id.'));     
     }
    
    if(!hasErrors)
    {
    
     List<CA_Comm_Response__c> surveyQuestionRespLst= [select CA_Owner__r.name, Response__c 
                                                       from   CA_Comm_Response__c 
                                                       where  Question_Id__c = :reportQuestionId 
                                                       order  by Question_Id__r.Order_No__c  ];
     
     // list which will hold all the valid answers for the question                                                         
     optionStrLst = New List<String>();
     
    CA_Comm_Question__c commQuestionSo = questionSoMap.get(reportQuestionId); 

    for(integer i=1;i<=12;i++)
    {
     String responseStr =(String)commQuestionSo.get('Response_Option_'+i+'__c');
     
     if(responseStr!=null && responseStr.length() > 0 )
      { 
        optionStrLst.add(responseStr); 
      }
     else
      {
        break;
      }
    }

  
    Map<String,Integer> optionMap = New Map<String,Integer>();
    
    Integer optionVal=0;
    
    // loop over all the option and get rid of all the new line characters or whitespaces
    // as this can create an issue while doing exact match
    for(String optionStr : optionStrLst)
    {

       optionMap.put(optionStr,optionVal++);
    }
    
    
    // list to display the owner names on the page
    reponseOwnerLst = New List<String>();
   
    // list which will hold the response of each owner for each question
    responseMap = New Map<String,List<Boolean>>();
     
     if(surveyQuestionRespLst!=null && surveyQuestionRespLst.size() > 0)  
     { 
        // the total response count for each answer
        Integer responseCount=0;
        responseCountLst = New List<Integer>();
        
        // loop over all the valid answers
        for(String responseStr: optionStrLst){
         
         // reset the count for each new answer
         responseCount=0;
            
            // loop over all the owner reponses that we had queried earlier
            for(CA_Comm_Response__c sqrSo : surveyQuestionRespLst) 
                {
                    // eliminate new line chars and whitespaces
                    String optionStr = sqrSo.response__c;
                    
                    // increment the count if the answer matches
                    if(responseStr!=null && responseStr.length() > 0 && responseStr.equalsIgnoreCase(optionStr))
                        {
                          responseCount++;
                        }
                }

        // add the count in the list , this list is used on the vf page
        responseCountLst.add(responseCount);   

      }
      
      // loop over each response
      for(CA_Comm_Response__c  sqrSo : surveyQuestionRespLst)
      {
        String optionStr = sqrSo.response__c;
        // get the number from the map
        Integer responseVal = optionMap.get(optionStr);
        List<Boolean> tempList; 
        Boolean isNewLst=false,isMapLst=false;
         
        // this is for the case where there could be multiple answer for each question
        if(responseMap.containsKey(sqrSo.CA_Owner__r.name))
          {
           tempList = responseMap.get(sqrSo.CA_Owner__r.name); 
           isMapLst=true;
          }
         else
          { 
            // if a new list is created then we need to create its size equal to the 
            // number of valid answers and reset each answer to false.
            tempList = New List<Boolean>();
            isNewLst  = true;
            for(Integer i=0;i<optionStrLst.size();i++)
            {
             tempList.add(false);
            } 
              
          }
        
        // loop over each answer
        for(Integer i=0;i<optionStrLst.size();i++)
        {
          
          // check at which position a valid answer is found
          if(i==responseVal) 
          {  
             // remove the false flag and set the true flag at that location in the list
             tempList.remove(i);
             if(i == optionStrLst.size() - 1)
             {
              tempList.add(true);
             }
             else
             {
              tempList.add(i,true);
             }
           }
      

        }
       
        // put the list in the map against each owner, this list gives the right/wrong matrix on the page
        responseMap.put(sqrSo.CA_Owner__r.name,tempList);
        
        if(textInputRespMap.get(sqrSo.CA_Owner__r.name)==null)
        {
         textInputRespMap.put(sqrSo.CA_Owner__r.name,' ');
        }
      }
      
      // the keys from the map are all valid owners 
      reponseOwnerLst.addAll(responseMap.keySet());
     }
    
    }
    

    } 
    catch(Exception ex)
    {
      system.debug( 'Exception: ' + ex.getTypeName() + ': ' + ex.getMessage() 
    + ' -- ' + ex.getCause() + ' -- ' + ex.getLineNumber() );
    }
  
  }
}
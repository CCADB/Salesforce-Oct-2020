/**
This is the class for the CACommSummaryReport VF page.  

**/
global without sharing class CACommSummaryReportController{

 public String communicationId;
 
 public String surveyName {get;set;}
 
 public     Map<String,Map<String,MAp<Id,QnA>>> resultMap {get;set;}
 public     Map<String,Map<String,List<QnA>>> resultMap2 {get;set;}

  // constructor method for standard controller
    public CACommSummaryReportController() {
    
     // get the survey id from the url parameter and throw an error if the parameter is missing
     if(ApexPages.currentPage().getParameters().get('CommunicationId')!=null)
     {
            communicationId = ApexPages.currentPage().getParameters().get('CommunicationId');     
     }
     else
     {
       ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.Error,'Please provide a valid communication id.'));
     }
     
     // get all the responses for this survey
     List<CA_Comm_Response__c> allResponseLst =  [select id, Question_Id__r.CA_Comm__r.name,CA_Owner__r.name,Contact__r.name,Question_Id__r.Question__c, 
                                                         Question_Id__r.Question_Type__c,Response__c  
                                                  from   CA_Comm_Response__c 
                                                  where  Question_Id__r.CA_Comm__r.id = :communicationId and CA_Owner__c <> '' 
                                                  order by CA_Owner__c, Contact__c, Question_Id__r.Order_No__c];

   Map<Id, QnA> qnAMap = New Map<Id, QnA>();

   
   // iterate over each reponse and generate the data for the report 
   for(CA_Comm_Response__c responseSO : allResponseLst )
    {
      surveyName = responseSo.Question_Id__r.CA_Comm__r.name;
     
      // if the response for this owner is already processed once 

      if(resultMap!=null && resultMap.size() > 0 && resultMap.containsKey(responseSo.CA_Owner__r.name))
      {
         
         Map<String,Map<Id,QnA>> tempMap= resultMap.get(responseSo.CA_Owner__r.name);
                  Map<String,List<QnA>> tempMap2= resultMap2.get(responseSo.CA_Owner__r.name);

         Map<Id,QnA> answerLst;
         
         // check if this contact has already responded once 
         if(tempMap.containsKey(responseSo.Contact__r.name))
         {
           answerLst =tempMap.get(responseSo.Contact__r.name);
         }
         else
         {
           answerLst =New Map<Id,QnA>();         
         }
         
          QnA qnAWrapper = New QnA(); 
          qnAWrapper.question=responseSo.Question_Id__r.Question__c;
          qnAWrapper.answer = responseSo.Response__c;
          
          if(answerLst!=null && answerLst.size() > 0 && answerLst.get(responseSo.Question_Id__c)!=null)
          {
             qnAWrapper.answer = answerLst.get(responseSo.Question_Id__c).answer +  '\n' +  responseSo.Response__c;
          }
         
           qnaWrapper.questionId = responseSo.Question_Id__c;
           answerLst.put(responseSo.Question_Id__c,qnAWrapper);        

           List<QnA> qnALst = New List<QnA>();
           if(answerLst.size() > 1)
           {
             qnALst = answerLst.values();
             answerLst.clear();
             for(QnA tempQnA : qnALst)
               {
                 answerLst.put(tempQnA.questionId,tempQna);
               }   
           } 
          
          tempMap.put(responseSo.Contact__r.name,answerLst);
          resultMap.put(responseSo.CA_Owner__r.name,tempMap);
          
          tempMap2.put(responseSo.Contact__r.name,qnaLst);
          resultMap2.put(responseSo.CA_Owner__r.name,tempMap2);
          
      }
      else
      {
         List<QnA > answerLst = New List<QnA >();
         QnA qnAWrapper = New QnA(); 
         qnAMap = New Map<Id, QnA>();
         qnAWrapper.question=responseSo.Question_Id__r.Question__c;
         qnAWrapper.answer = responseSo.Response__c;
          
       
         if(qnaMap!=null && qnaMap.size() > 0 && qnaMap.get(responseSo.Question_Id__c)!=null)
          {
             qnAWrapper.answer = qnaMap.get(responseSo.Question_Id__c).answer + '\n' +  responseSo.Response__c;
          }
         qnaWrapper.questionId = responseSo.Question_Id__c;
         qnAMap.put(responseSo.Question_Id__c,qnAWrapper);
         
        
         Map<String,Map<Id,QnA>>     tempMap = New Map<String,Map<Id,QnA>>();
         Map<String,List<QnA>>     tempMap2 = New Map<String,List<QnA>>();         
       
         tempMap.put(responseSo.Contact__r.name,qnAMap);
         tempMap2.put(responseSo.Contact__r.name,qnAMap.values());
       
         if(resultMap==null)
         {
         resultMap = New Map<String,Map<String,Map<Id,QnA>>>();
         resultMap2 = New Map<String,Map<String,List<QnA>>>();         
         }
         
         resultMap.put(responseSo.CA_Owner__r.name,tempMap); 
         resultMap2.put(responseSo.CA_Owner__r.name,tempMap2); 
      }
    }
        
  }
  
   // wrapper class used on VF page to display the data in expected format.
   class QnA
  {
   public String question {get;set;}
    public String answer {get;set;}
    public id questionId {get;set;}
  
  }

}
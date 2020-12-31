/*******************************************************************************************************
 Name: CACommResponsesOnlyReportController

 Dependencies: CACommResponsesOnlyReportController class, CACommResponsesOnlyReportControllerTest Test class,
 CACommResponsesOnlyReportController VF page
 
 Description: This custom report lists responses of all CA Owners for the specific action item(s). 

 A CommunicationId and one/two/three QuestionIds are passed as parameters:
 CommunicationId=<Record id of CA Communication record> 
 QuestionId=<Question Id,Question Id, Question Id> 

 Example: https://ccadb-public.secure.force.com/mozillacommunications/CACommResponsesOnlyReport?CommunicationId=a051J00003waNOW&QuestionId=Q00084,Q00085,Q00098

 Instructions: None
 
 *******************************************************************************************************
 Revision History:
 
     01/21/2020 - Created new class
                
 ******************************************************************************************************/

public class CACommResponsesOnlyReportController {

    private String communicationId;
    
    private string questionParamStr;
    
    private Id reportQuestionId;
    
    private Id reportQuestionId2;
    
    private Id reportQuestionId3;
    
    private String questionIdParam;
    
    private String questionId2Param;
    
    private String questionId3Param;
    
    private List<Id> reportQuestionIdLst;
    
    private List<String> questionIdLst;
    
    public String surveyNameStr {get;set;}
    
    public String questionStr {get;set;}
    
    public String questionStr2 {get;set;}
    
    public String questionStr3 {get;set;}
    
    private Boolean hasErrors = false; 
    
    public Map<String,List<String>> responseSoMap {get;set;}
    
    public Map<String,Map<String,String>> responseMap {get;set;}
    
    public  List<String>  reponseOwnerLst {get;set;}
    
    public  List<String>  reponseLst {get;set;}
    
    public Boolean displaySecondQuestionResponse {get;set;}  
    
    // constructor which intializes the data that is displayed on the page
    public CACommResponsesOnlyReportController() {
        try {
            displaySecondQuestionResponse  = false;
            // get the parameters from the url and throw error if the param is not available
            if(ApexPages.currentPage().getParameters().get('CommunicationId')!=null) {
                communicationId = ApexPages.currentPage().getParameters().get('CommunicationId');     
            } else {
                hasErrors=true;
                ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.Error,'Please provide a valid communication id.'));
            }

            questionIdLst = New List<String>();          
            if(ApexPages.currentPage().getParameters().get('QuestionId')!=null) {
                questionIdParam = ApexPages.currentPage().getParameters().get('QuestionId');
                
                if(questionIdParam.length() == 0){
                    hasErrors=true;
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.Error,'QuestionId URL param is blank. Please provide a valid Question Id.'));     
                }
                
                questionIdLst.add(questionidParam);
                if(questionIdParam.contains(',')){
                    questionIdLst.clear();
                    questionIdLst.addAll(questionIdParam.split(','));
                    questionIdParam = questionIdLst[0];
                    questionId2Param= questionIdLst[1];
                    if(questionIdLst.size() > 2){
                        questionId3Param = questionIdLst[2];
                    }
                    if(questionId2Param==null || questionId2Param.length() ==0){
                        hasErrors=true;
                        ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.Error,'The second question id param is null. Please provide a valid Question Id.'));        
                    }
                    displaySecondQuestionResponse  = true;
                }     
            } else {
                hasErrors=true;
                ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.Error,'QuestionId URL param is null. Please provide a valid Question Id.'));
            }
            
            Map<Id,CA_Comm_Question__c> questionSoMap = New Map<Id,CA_Comm_Question__c>([select id,name,Question__c,CA_Comm__r.name,
            Response_Option_1__c, Response_Option_2__c, Response_Option_3__c, Response_Option_4__c, Response_Option_5__c, Response_Option_6__c, 
            Response_Option_7__c, Response_Option_8__c, Response_Option_9__c, Response_Option_10__c, Response_Option_11__c, Response_Option_12__c,Count_of_Responses__c
            from  CA_Comm_Question__c where CA_Comm__c = :communicationid and name in :questionIdLst ]);                                                
            
            
            // if there are one or more questions
            if(questionSoMap!=null && questionSoMap.size() > 0)
            {
            
                for(Id questionId : questionSoMap.keyset())
                {
                    // get the question id as we would need to fetch all the answers for this question
                    if(questionSoMap.get(questionId).name == questionIdParam) {
                        reportQuestionId = questionId;
                        // get the question string
                        questionStr = questionSoMap.get(questionId).question__c;
                    }
                    
                    // get the question id as we would need to fetch all the answers for this question
                    if(questionSoMap.get(questionId).name == questionId2Param) {
                        reportQuestionId2 = questionId;
                        // get the question string
                        questionStr2 = questionSoMap.get(questionId).question__c;
                        
                    } 
                    
                    // get the question id as we would need to fetch all the answers for this question
                    if(questionSoMap.get(questionId).name == questionId3Param) {
                        reportQuestionId3 = questionId;
                        // get the question string
                        questionStr3 = questionSoMap.get(questionId).question__c;
                        
                    }         
                    
                    // get the survey name only once, this is displayed on the top of the page
                    if(surveyNameStr==null){
                        surveyNameStr =  questionSoMap.get(questionId).CA_Comm__r.name;
                    }
                
                }
                
            } else {
                hasErrors=true; 
                ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.Error,'Survey does not have any questions or Question not found. Make sure you have provided a valid Question Id in the QuestionId URL parameters. For example CACommResponsesOnlyReport?CommunicationId=a051J00003walOW&QuestionId=Q00084,Q00085,Q00098'));
            }
            
            if(reportQuestionId==null) {
                hasErrors=true;
                ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.Error,'No records found for the given QuestionId URL param. Please provide a valid Question Id.'));     
            }
            
            if(!hasErrors) {
            
                reportQuestionIdLst = New List<Id> ();
                reportQuestionIdLst.add(reportQuestionId);
                reportQuestionIdLst.add(reportQuestionId2); 
                if(reportQuestionId3 != null && string.isnotblank(reportQuestionId3)) {
                    reportQuestionIdLst.add(reportQuestionId3); 
                }
                
                List<CA_Comm_Response__c> surveyQuestionRespLst= [select CA_Owner__r.name, Response__c, Question_Id__c, 
                    Question_Id__r.Default_Text__c, Question_Id__r.Question_Type__c from   CA_Comm_Response__c 
                    where  Question_Id__c in :reportQuestionIdLst 
                    order  by Question_Id__r.Order_No__c  ];
                
                // list to display the owner names on the page
                reponseOwnerLst = New List<String>();
                
                Map<String,map<string, string>> responseSoMapQuestionWise = New Map<String,map<string,string>>(); 
                if(surveyQuestionRespLst != null && surveyQuestionRespLst.size() > 0)  { 
                
                    // loop over each response
                    for(CA_Comm_Response__c  sqrSo : surveyQuestionRespLst) {
                        String displayStr = '';
                        map<string,string> maptempLst = new map<string,string>();
                        
                        if(sqrSo.Question_Id__c == reportQuestionId) {
                            //check if response has same default text, if yes then continue loop
                            if(sqrSo.Question_Id__c != null && string.isnotblank(sqrSo.Question_Id__r.Default_Text__c) && sqrSo.Question_Id__r.Question_Type__c == 'Free Text (Multi line text box)' && sqrSo.response__c != null) {
                                // remove carriage return and newline characters before comparing responses
                                String str1 = sqrSo.Question_Id__r.Default_Text__c.replaceall('\r','');
                                str1 = str1.replaceall('\n','');           
                                String str2 = sqrSo.response__c.replaceall('\r','');
                                str2 = str2.replaceall('\n','');
                                if (str1 == str2){
                                    continue;
                                }
                            }
                            // this is for the case where there could be multiple answer for each question
                            if(responseSoMapQuestionWise.containsKey(sqrSo.CA_Owner__r.name)) {
                                maptempLst = responseSoMapQuestionWise.get(sqrSo.CA_Owner__r.name);
                                if(maptempLst.containskey(reportQuestionId)){
                                    displayStr = maptempLst.get(reportQuestionId);
                                    displayStr  = displayStr  + '<br>' +  sqrSo.response__c;
                                    maptempLst.put(reportQuestionId,displayStr);
                                } else {
                                    maptempLst.put(reportQuestionId,sqrSo.response__c);
                                }
                            } else { 
                                maptempLst.put(reportQuestionId,sqrSo.response__c);
                            }
                            responseSoMapQuestionWise.put(sqrSo.CA_Owner__r.name,maptempLst);
                        }
                        if(sqrSo.Question_Id__c == reportQuestionId2){
                            //check if response has same default text, if yes then continue loop
                            if(sqrSo.Question_Id__c != null && string.isnotblank(sqrSo.Question_Id__r.Default_Text__c) 
                                    && sqrSo.Question_Id__r.Question_Type__c == 'Free Text (Multi line text box)' 
                                    && sqrSo.response__c != null) {   
                                // remove carriage return and newline characters before comparing responses
                                String str1 = sqrSo.Question_Id__r.Default_Text__c.replaceall('\r','');
                                str1 = str1.replaceall('\n','');           
                                String str2 = sqrSo.response__c.replaceall('\r','');
                                str2 = str2.replaceall('\n','');
                                if (str1 == str2){
                                    continue;
                                }
                            }
                            // this is for the case where there could be multiple answer for each question
                            if(responseSoMapQuestionWise.containsKey(sqrSo.CA_Owner__r.name)){
                                maptempLst = responseSoMapQuestionWise.get(sqrSo.CA_Owner__r.name);
                                if(maptempLst.containskey(reportQuestionId2)){
                                    displayStr = maptempLst.get(reportQuestionId2);
                                    displayStr  = displayStr  + '<br>' +  sqrSo.response__c;
                                    maptempLst.put(reportQuestionId2,displayStr);
                                } else {
                                    maptempLst.put(reportQuestionId2,sqrSo.response__c);
                                }
                            } else { 
                                maptempLst.put(reportQuestionId2,sqrSo.response__c);
                            }
                            responseSoMapQuestionWise.put(sqrSo.CA_Owner__r.name,maptempLst);
                        }
                        
                        if(sqrSo.Question_Id__c == reportQuestionId3) {
                            //check if response has same default text, if yes then continue loop
                            if(sqrSo.Question_Id__c != null && string.isnotblank(sqrSo.Question_Id__r.Default_Text__c) && sqrSo.Question_Id__r.Question_Type__c == 'Free Text (Multi line text box)' && sqrSo.response__c != null) {
                                // remove carriage return and newline characters before comparing responses
                                String str1 = sqrSo.Question_Id__r.Default_Text__c.replaceall('\r','');
                                str1 = str1.replaceall('\n','');           
                                String str2 = sqrSo.response__c.replaceall('\r','');
                                str2 = str2.replaceall('\n','');
                                if (str1 == str2){
                                    continue;
                                }
                            }
                            // this is for the case where there could be multiple answer for each question
                            if(responseSoMapQuestionWise.containsKey(sqrSo.CA_Owner__r.name)) {
                                maptempLst = responseSoMapQuestionWise.get(sqrSo.CA_Owner__r.name);
                                if(maptempLst.containskey(reportQuestionId3)){
                                    displayStr = maptempLst.get(reportQuestionId3);
                                    displayStr  = displayStr  + '<br>' +  sqrSo.response__c;
                                    maptempLst.put(reportQuestionId3,displayStr);
                                } else {
                                    maptempLst.put(reportQuestionId3,sqrSo.response__c);
                                }
                            } else { 
                                maptempLst.put(reportQuestionId3,sqrSo.response__c);
                            }
                            responseSoMapQuestionWise.put(sqrSo.CA_Owner__r.name,maptempLst);
                        }
                    }
                    
                    // the keys from the map are all valid owners 
                    reponseOwnerLst.addAll(responseSoMapQuestionWise.keySet());
                
                    if(reponseOwnerLst!= null && reponseOwnerLst.size() > 0){
                        reponseOwnerLst.sort();
                    }
                    
                    responseSoMap = New Map<String,List<String>>(); 
                    // added this block of code to handle the scenario wherein there is no response for few of the questions.
                    if(responseSoMapQuestionWise !=null && responseSoMapQuestionWise.size() > 0){
                        for(string ownerStr: responseSoMapQuestionWise.keyset()) {
                            map<string, string> maptempLst = responseSoMapQuestionWise.get(ownerStr);
                            List<String> tempLst = new List<string>();
                            if(maptempLst.containskey(reportQuestionId)){
                                tempLst.add(maptempLst.get(reportQuestionId));
                            } else {
                                tempLst.add('');
                            }
                            if(displaySecondQuestionResponse) {
                                if(string.isnotblank(reportQuestionId2) && maptempLst.containskey(reportQuestionId2)){
                                    tempLst.add(maptempLst.get(reportQuestionId2));
                                } else {
                                    tempLst.add('');
                                } 
                            }
                            if(string.isnotblank(reportQuestionId3)) {
                                if(string.isnotblank(reportQuestionId3) && maptempLst.containskey(reportQuestionId3)){
                                    tempLst.add(maptempLst.get(reportQuestionId3));
                                } else {
                                    tempLst.add('');
                                } 
                            }
                            responseSoMap.put(ownerStr,tempLst);
                        }
                    }
                    System.debug('reponseOwnerLst ::: '+reponseOwnerLst);
                    System.debug('responseSoMap ::: '+responseSoMap);
                    for(String ownerStr : responseSoMap.keySet()){
                        List<String> temp = new List<String>();
                        for(String tempStr : responseSoMap.get(ownerStr)){
                            if(tempStr == null){
                                tempStr = ' ';
                            }
                            temp.add(tempStr);  
                        }
                        responseSoMap.put(ownerStr, temp);
                    }
                }
            }
        } 
        catch(Exception ex){
            system.debug( 'Exception: ' + ex.getTypeName() + ': ' + ex.getMessage() 
            + ' -- ' + ex.getCause() + ' -- ' + ex.getLineNumber() );
        }
    }
}
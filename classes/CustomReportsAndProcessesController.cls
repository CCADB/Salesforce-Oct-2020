/*
    Description: Shows all Documentation 
    
    Allow to filter with Used By, Type, Lightning Enabled, Deprecated, 
    
    Note: Only System Administrator and Standard User - Mozilla profiles users can edit Documentation from page.
*/
public with sharing class CustomReportsAndProcessesController {
    
    public List<Custom_Reports_and_Processes__c> lstDocumentation {get; set;}
    
    public Custom_Reports_and_Processes__c objDocumentFilter {get; set;}
    public List<SelectOption> lstUsedBy {get; set;}
    public string strUsedBy {get; set;}
    public boolean isEditAllow {get; set;}
    public boolean isEditDocument {get; set;}
    public Custom_Reports_and_Processes__c objEditDocument {get; set;}
    
    public CustomReportsAndProcessesController(){
        objDocumentFilter = new Custom_Reports_and_Processes__c();
        
        isEditAllow = false;
        List<Profile> lstProfiles = new List<Profile>([select Id,Name from Profile Where Name in ('System Administrator - Mozilla','Standard User - Mozilla') 
                                                        and Id =: UserInfo.getProfileId()]);
        if(lstProfiles.size() > 0) {
            isEditAllow = true;
        }
        lstUsedBy = new List<SelectOption>();
        lstUsedBy.add(new SelectOption('All', 'All'));
        lstUsedBy.add(new SelectOption('Mozilla Internal', 'Mozilla Internal'));
        lstUsedBy.add(new SelectOption('Microsoft Internal', 'Microsoft Internal'));
        lstUsedBy.add(new SelectOption('Mozilla Public', 'Mozilla Public'));
        lstUsedBy.add(new SelectOption('Microsoft Public', 'Microsoft Public'));
        filterDocumentation();
    }
    
    public void filterDocumentation(){
        if(objDocumentFilter != null || string.isnotblank(strUsedBy)){
            string strQuery = 'select Id,Name,Description__c,Name__c,URL__c,Used_By__c, Lightning_Enabled__c,Type__c,Deprecated__c from Custom_Reports_and_Processes__c Where ';
            boolean deprecated = objDocumentFilter.Deprecated__c;
            strQuery += ' Deprecated__c =: deprecated ';
            if(string.isnotblank(strUsedBy) && strUsedBy != 'All'){
                strQuery += ' AND Used_By__c INCLUDES (\'' + strUsedBy +  '\') ';
            }
            if(objDocumentFilter.Type__c != null){
                string type = objDocumentFilter.Type__c;
                strQuery += ' AND Type__c =: type ';
            }
            if(objDocumentFilter.Lightning_Enabled__c != null){
                string strLightningEnabled = objDocumentFilter.Lightning_Enabled__c;
                strQuery += ' AND Lightning_Enabled__c =: strLightningEnabled ';
            }
            system.debug('strQuery  ::: '+strQuery );
            lstDocumentation = new List<Custom_Reports_and_Processes__c>();
            lstDocumentation = Database.Query(strQuery);
        }
    }
    
    public void EditDocument(){
        if(Apexpages.currentpage().getparameters().get('index') != null) {
            Integer index = Integer.valueof(Apexpages.currentpage().getparameters().get('index'));
            if(lstDocumentation.size() > 0) {
                isEditDocument = true;
                objEditDocument = lstDocumentation[index];
            }
        }
    }
    
    public void SaveDocument() {
        try {
            update objEditDocument;
            isEditDocument = false;
            filterDocumentation();
        } catch(Exception ex) {
            Apexpages.addMessages(ex);
        }
    }
    
    public void CancelDocument(){
        isEditDocument = false;
        filterDocumentation();
    }
    
    String CurrentDate = ' ';
    // Get current Datetime in long date format   
    public String getCurrentDate() {
        Datetime cDT = System.now();
        CurrentDate = cDT.format('MMMM d, yyyy');
        return CurrentDate;
    }
}
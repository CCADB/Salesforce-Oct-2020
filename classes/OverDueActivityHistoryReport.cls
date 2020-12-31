/*
    Description: Class is created for History of OverDue Activity
*/
public class OverDueActivityHistoryReport {
    
    //public List<wrapperActivityGroupByCAOwner> lstActivities {get; set;}
    
    //public List<Task> lstAllTasks {get; set;}
    
    public transient List<wrapperActivity> lstAllActivities {get; set;}
    
    public OverDueActivityHistoryReport(){
    
        string strAuditAlert = apexpages.currentPage().getParameters().get('AuditAlert');
        
        set<string> setOfSubjects = new set<string>();
        
        setOfSubjects.add('Mozilla: Overdue Audit Statements');
        setOfSubjects.add('Mozilla: Your root is in danger of being removed');
        
        set<Id> setOfCertificateIds = new set<Id>();
        
        string strQuery = 'SELECT Id, Subject, WhatId, What.Name, CreatedDate FROM Task Where Subject in: setOfSubjects';
        string strWhereClause = '';
        if(string.isnotblank(strAuditAlert)){
            if(strAuditAlert.tolowercase() == 'within31days'){
                strWhereClause += ' AND CreatedDate = LAST_N_DAYS:31 ';
            } else if(strAuditAlert.tolowercase() == 'olderthan31days'){
                strWhereClause += ' AND CreatedDate < LAST_N_DAYS:31 ';
            }
        }
        if(string.isnotblank(strWhereClause)){
            strQuery += strWhereClause;
        }
        strQuery += ' Order By WhatId,CreatedDate desc ALL ROWS ';
        for(Task objTask: Database.Query(strQuery)){
            setOfCertificateIds.add(objTask.WhatId);
        }
        if(setOfCertificateIds.size() > 0) {
            set<Id> setOfCertIdsWithStatus = new set<Id>();
            
            for(Account objAcc: [select Id from Account Where Id in: setOfCertificateIds and Status__c in ('Included', 'Change Requested')]){
                setOfCertIdsWithStatus.add(objAcc.Id);
            }
            
            if(setOfCertIdsWithStatus.size() > 0) {
                string strName = '';
                boolean blnAlterNative = true;
                map<string, wrapperActivity> mapAllActivitiesByOwner = new map<string, wrapperActivity>();
                strQuery = '';
                strQuery += 'SELECT Id, Subject, WhatId, What.Name, CreatedDate, Standard_Audit_Statement_Date__c FROM Task Where Subject in: setOfSubjects AND WhatId in: setOfCertIdsWithStatus ';
                if(string.isnotblank(strWhereClause)){
                    strQuery += strWhereClause;
                }    
                strQuery += 'Order By What.Name,CreatedDate desc ALL ROWS';
                for(Task objTask: Database.Query(strQuery)){
                    if(strName == '') {
                        strName = objTask.What.Name;
                    }
                    string strKey = objTask.What.Name + '#' + objTask.Subject + '#' + objTask.CreatedDate.Year();
                    if(!mapAllActivitiesByOwner.containskey(strKey)){
                        if(objTask.Standard_Audit_Statement_Date__c != null) {
                            Date dtCreatedDate = Date.newInstance(objTask.CreatedDate.year(), objTask.CreatedDate.month(), objTask.CreatedDate.day());
                            Integer noofdaysoverdue = objTask.Standard_Audit_Statement_Date__c.addDays(365).DaysBetween(dtCreatedDate);
                            if(noofdaysoverdue > 0) {
                                if(strName != objTask.What.Name){
                                    if(blnAlterNative) {
                                        blnAlterNative = false;
                                    } else {
                                        blnAlterNative = true;
                                    }
                                    strName = objTask.What.Name;
                                }
                                mapAllActivitiesByOwner.put(strKey, new wrapperActivity(blnAlterNative, noofdaysoverdue, objTask));
                            }    
                        }
                    }
                }
                //lstAllTasks = new List<Task>();
                lstAllActivities = new List<wrapperActivity>();
                if(mapAllActivitiesByOwner.size() > 0) {
                    //lstAllTasks.addall(mapAllActivitiesByOwner.values());
                    lstAllActivities.addall(mapAllActivitiesByOwner.values());
                }
            }
        }
        
        /*lstAllTasks = new List<Task>([SELECT Id, Subject, WhatId, What.Name, CreatedDate FROM Task Where Status = 'Completed' AND 
                Subject in: setOfSubjects Order By WhatId,CreatedDate desc ALL ROWS]);*/
    }
    
    public class wrapperActivity {
        public string rowColor {get; set;}
        public Integer NoOfDaysOverDue {get; set;}
        public Task objActivity {get; set;}
        
        public wrapperActivity(boolean isBln, integer noofdays, Task objAct){
            if(isBln) {
                this.rowColor = '#c9ecf7';
            } else {
                this.rowColor = '#e8f6fa';
            }
            this.NoOfDaysOverDue = noofdays;
            this.objActivity = objAct;
        }
    }
    
    //Get current Datetime in long date format   
    public String getCurrentDate() {
        Datetime cDT = System.now();
        string CurrentDate = cDT.format('MMMM d, yyyy');
        return CurrentDate;
    }
}
global class MassEmailBatch implements Database.Batchable<sObject>, Database.stateful {

    global String massEmailRecordId = '';
    
    global Mass_Email__c massEmailSo = null;
    global Map<Id,Set<String>>  toEmailAddressMap;
    global Map<Id,Set<String>>  ccEmailAddressMap;
    
    public MassEmailBatch (String massEmailRecordIdParam,   Map<Id,Set<String>> toMap ,   Map<Id,Set<String>> ccMap) {
        massEmailRecordId = massEmailRecordIdParam;
        toEmailAddressMap  = toMap;
        ccEmailAddressMap = ccMap;
        massEmailSo = [select Id,From__c,SOQL_Filter_Conditions__c, OwnerId, Name, No_of_Emails_Sent__c, No_of_Emails_Failed__c,
                Error_Message__c, Subject__c, Reply_To__c, Message__c, Send_To__c, CC_To__c from Mass_Email__c where id =:massEmailRecordId];
        massEmailSo.Error_Message__c = '';
        massEmailSo.No_of_Emails_Sent__c = 0;
        massEmailSo.No_of_Emails_Failed__c = 0;
    }

    global Database.QueryLocator start(Database.BatchableContext BC){
        String query = '';
        set<Id> setCAOwnerIds = new set<Id>();
        if(toEmailAddressMap.size() > 0){
            setCAOwnerIds.addall(toEmailAddressMap.keyset());
        }
        if(ccEmailAddressMap.size() > 0){
            setCAOwnerIds.addall(ccEmailAddressMap.keyset());
        }
        query = 'select id, name, CA_Owner_ID__c, CA_Email_Alias_1__c , CA_Email_Alias_2__c from account where id in :setCAOwnerIds';
        /*Commented because I don't think we need to query it again
        Boolean fetchOwnerAccounts = false;
        List<Account> accountSoLst; 
        String query = 'select id, CA_Owner_ID__c, CA_Email_Alias_1__c , CA_Email_Alias_2__c from account ';
        if(massEmailSo.SOQL_Filter_Conditions__c!=null && massEmailSo.SOQL_Filter_Conditions__c.length() > 0)  { 
        query = query + ' where ' + massEmailSo.SOQL_Filter_Conditions__c;
        accountSoLst = Database.query(query);
        String rootCertFilter = 'Record_Type_Name__c=RootCertificate';
          String interCertFilter = 'Record_Type_Name__c=IntermediateCertificate';
          String filterConditions = massEmailSo.SOQL_Filter_Conditions__c;
          
            filterConditions= filterConditions.trim();
            
            filterConditions= filterConditions.replaceAll('(\\s+)', '');
            filterConditions= filterConditions.replaceAll('\'', '');

              if( filterConditions.contains(rootCertFilter) || filterConditions.contains(interCertFilter))
              {
                fetchOwnerAccounts = true;
              }
        }
        
        if(fetchOwnerAccounts && accountSoLst!=null && accountSoLst.size() > 0)
        {
          Set<String> ownerAccountIdSet = New Set<String>();
          
          for(Account accountSo : accountSoLst)
          {
            ownerAccountIdSet.add(accountSo.ca_owner_id__c);
          }
          // system.debug('OwnerSet==' + ownerAccountIdSet);
          query = 'select id, name, CA_Owner_ID__c, CA_Email_Alias_1__c , CA_Email_Alias_2__c from account where id in :ownerAccountIdSet';
          return Database.getQueryLocator(query);
        }*/
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext BC, List<Account> scope){
        MassEmailBatchHelper batchHelper = new MassEmailBatchHelper ();
        massEmailSo = batchHelper.processOwnerRecords(scope, massEmailSo, toEmailAddressMap, ccEmailAddressMap);
    }
    
    global void finish(Database.BatchableContext BC)  { 
        if(string.isblank(massEmailSo.Error_Message__c)){
            massEmailSo.Batch_Status__c = 'Completed';
        } else {
            massEmailSo.Batch_Status__c = 'Failed';
        }
        update massEmailSo;
    }
}
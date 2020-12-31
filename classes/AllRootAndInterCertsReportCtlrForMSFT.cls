/*******************************************************************************************************
 Name: AllRootAndInterCertsReportCtlrForMSFT

 Dependencies: AllRootAndInterCertsReportCtlrForMSFT controller class, 
 AllRootAndInterCertsReportCtlrForMSFT vf page, AllRootAndInterCertsRepCtlrForMSFTTest test class

 Description: This is a controller class for a report which lists all Root and Intermediate Certs in
 CCADB.
 
 Instructions:    
 *******************************************************************************************************
 Revision History:
 
     3/1/2017 - Created new class
 ******************************************************************************************************/
public class AllRootAndInterCertsReportCtlrForMSFT {

    public transient List<Account> accountSoLst {get;set;}
 
    //constructor method for standard controller
    public AllRootAndInterCertsReportCtlrForMSFT() {   
                                          
           accountSoLst =  [select  Name, 
                                    Type,                                    
                                    CA_Owner__c, 
                                    Friendly_Name__c, 
                                    SHA_1_Fingerprint__c, 
                                    SHA_256_Fingerprint__c,
                                    Valid_From_YYYY_MMM_DD__c, 
                                    Valid_To_YYYY_MMM_DD__c, 
                                    Microsoft_Status__c,  
                                    Revocation_Status__c,
                                    Parent.Name, 
                                    Parent.SHA_1_Fingerprint__c,
                                    Parent.SHA_256_Fingerprint__c
                            from  Account
                            where 
                            RecordType.Name In ('Root Certificate','Intermediate Certificate')
                            order by CA_Owner__c, Type, Name];
 
      /***                                
       // if we are generating a CSV file then we need to replace the double quotes in all text fields with null
       if(ApexPages.currentPage().getUrl().contains('CSV') && accountSoLst !=null && accountSoLst.size() > 0)
       {
          for(Account accountSo : accountSoLst)
          {
             if(accountSo.name !=null && accountSo.name.length() > 0) 
                   accountSo.name = accountSo.name.replace('"',''); 
              if(accountSo.parent.name !=null && accountSo.parent.name.length() > 0) 
                   accountSo.parent.name = accountSo.parent.name.replace('"',''); 
              if(accountSo.Friendly_Name__c !=null && accountSo.Friendly_Name__c.length() > 0) 
                   accountSo.Friendly_Name__c = accountSo.Friendly_Name__c.replace('"','');            
          }
       } ***/
     }
     
     String CurrentDate = ' ';
 
    // Get current Datetime in long date format   

    public String getCurrentDate() {

      Datetime cDT = System.now();
      CurrentDate = cDT.format('MMMM d, yyyy');

      return CurrentDate;

   }

     
  }
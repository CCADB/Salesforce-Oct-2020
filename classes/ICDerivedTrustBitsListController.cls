/*******************************************************************************************************
 Name: ICDerivedTrustBitsListController

 Dependencies: ICDerivedTrustBitsListController controller class, ICDerivedTrustBitsList vf page, 
 ICDerivedTrustBitsListControllerTest test class

 Description: Displays all Intermediate Certs with Dervied Trust Bits. It was created for data verification
 purpose. The main logic for Derived Trust Bits is in UpdateDerivedTrustBits & GetDerivedTrustBits method in
 AccountTriggerHelper.
 
 Instructions: None
 *******************************************************************************************************
 Revision History:
 
     09/21/2020 - Created new class
     
 ******************************************************************************************************/ 

public class ICDerivedTrustBitsListController {

    public transient List<Account> lstAccounts {get; set;}
 
    //constructor method for standard controller
    public ICDerivedTrustBitsListController() {  
        lstAccounts =  [select Name,CA_Owner__c,CA_Owner_ID__c,Extended_Key_Usage__c, Derived_Trust_Bits__c,ParentId,
                                Parent.Name, Parent.RecordType.Name, Parent.Derived_Trust_Bits__c,
                                Parent.Trust_Bits__c, Parent.Microsoft_Trust_Bits__c, Parent.Status_Summary__c,
                                Parent.Revocation_Status__c, Parent.Valid_To_GMT__c
                                FROM Account
                                WHERE ( Mozilla_Root_Status__c In ('Included','Change Requested') OR
                                Microsoft_Root_Status__c In ('Included','Change Requested')) 
                                and RecordType.Name In ('Intermediate Certificate') and Valid_To_GMT__c > TODAY
                                Order by CA_Owner__c,Parent.Name, Name];
    }
  
     
    String CurrentDate = ' ';
 
    // Get current Datetime in long date format   
    public String getCurrentDate() {
        Datetime cDT = System.now();
        CurrentDate = cDT.format('MMMM d, yyyy');
        return CurrentDate;
    }
    
}
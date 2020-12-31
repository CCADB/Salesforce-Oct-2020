/*******************************************************************************************************
 Name: MyCATabControllerTest

 Dependencies: MyCATabController controller class, MyCATab vf page, MyCATabControllerTest test class

 Description: Allows CA's (community users) get to their CA Owner record in one click.
    
 Instructions: This is used by community users from custom VF page tab named "My CA" 
 *******************************************************************************************************
 Revision History:
 
     06/14/2020 - Created new class
     
 ******************************************************************************************************/
 
@isTest
public class MyCATabControllerTest{

 @isTest
  static void validateMyCATabController() {
      Id p = [select id from profile where name='Customer Community Plus Login User - CAs'].id;
      
      Account ac = new Account(name ='Grazitti') ;
        insert ac; 
       
        Contact con = new Contact(LastName ='testCon',AccountId = ac.Id);
        insert con;  
        
         User user = new User(alias = 'test123', email='test123@noemail.com',
                emailencodingkey='UTF-8', lastname='Testing', languagelocalekey='en_US',
                localesidkey='en_US', profileid = p, country='United States',IsActive =true,
                ContactId = con.Id,
                timezonesidkey='America/Los_Angeles', username='tester@noemail.com');
       
        insert user;
        
        system.runAs(user) {
            Test.StartTest();
            MyCATabController objmyca = new MyCATabController();
            Test.StopTest();

        }
  }

}
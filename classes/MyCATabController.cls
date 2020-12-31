/*******************************************************************************************************
 Name: MyCATabController

 Dependencies: MyCATabController controller class, MyCATab vf page, MyCATabControllerTest test class

 Description: Allows CA's (community users) get to their CA Owner record in one click.
    
 Instructions: This is used by community users from custom VF page tab named "My CA" 
 *******************************************************************************************************
 Revision History:
 
     06/14/2020 - Created new class
     
 ******************************************************************************************************/
 
 Public without sharing class MyCATabController{
    public Id accountId{get;set;}
    public MyCATabController(){
        List<User> lstUser = new List<User>([select id,contactid,contact.accountid from user where id=: UserInfo.getUserId()]);
        if(lstUser.size()>0 && lstUser.get(0).contactid != null){
            accountId = lstUser.get(0).contact.accountid;
        }
        //accountid = '0011k00000UtS7P';
    }
}
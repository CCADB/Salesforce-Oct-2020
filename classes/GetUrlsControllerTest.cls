@isTest
public class GetUrlsControllerTest{
    
    @isTest static void test1(){
        
        Account acc = new Account(Name = 'test account');
        insert acc;
        
        PageReference pref = Page.GetUrls;
        Test.setCurrentPage(pref);
        
        ApexPages.currentPage().getParameters().put('id', acc.Id);
        GetUrlsController obj = new GetUrlsController();
        
        obj.goBack();
        
    }
}
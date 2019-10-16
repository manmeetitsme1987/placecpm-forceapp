@isTest
public class QuotaTriggerHandlerTest {
    static GL_Code__c glaccount;
    static Employee__c emp;
    static void testRevenueInsertion(){
        Assumption__c ass = TestUtility.createAssumption(24, true);
        P_L_Category__c plCategory = TestUtility.createPlCategory('General and Admin','Revenue',True);
        glaccount = TestUtility.createGLCode('Advertising',600,plCategory.id,True);
        ass.Average_License_Price__c = 345;
        ass.Contract_Period__c = 12;
        ass.Forecasting_Quota__c = 56;
        ass.Revenue_GL_Account__c = glaccount.id;
        update ass;
        Organisation__c organisation = TestUtility.createOrganisation('Place Technology', true);
        Department__c department = TestUtility.createDepartment('SFDC', organisation.Id, glaccount.Id, true);  
        Role__c role = TestUtility.createRole('Tester', department.Id ,true);
        
        Employee__c emp = TestUtility.createEmployee('TestEmployee',role.Id,System.today(),'Austin','Salaried Employee',CONSTANT.EMPLOYEE_SALES_RT,true);
        Test.startTest();
        Quota_Schedule__c qs = new Quota_Schedule__c();
        qs.Type__c = '3';
        insert qs;
        Quota__c quota = TestUtility.createQuota(emp.Id , 100 , System.today() , System.today().addDays(365) , glaccount.Id , true);
        quota.Monthly_Quota_Amount__c = 200;
        update quota;
        Test.stopTest();
        System.assert(True,[select id from Revenue_Account__c where Quota__c =: quota.Id].size() > 0);
    }
}
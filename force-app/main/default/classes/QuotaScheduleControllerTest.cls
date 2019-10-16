@isTest
private class QuotaScheduleControllerTest {
    private static GL_Code__c glaccount;
    private static Employee__c emp;
    private static Quota_Schedule__c quotaSchedule;
    
    private static void createTestData(){
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
        quotaSchedule = new Quota_Schedule__c();
        quotaSchedule.Type__c = '3';
        quotaSchedule.Range_Start__c = 10;
        quotaSchedule.Quota_Amount__c = 500;
        insert quotaSchedule;
        Quota__c quota = TestUtility.createQuota(emp.Id , 100 , System.today() , System.today().addDays(365) , glaccount.Id , true);
        
    }
    
    static testMethod void testRevenueInsertion(){
        Test.startTest();
        createTestData();
        PlaceCPM_Utility.assumptionRevenueGLAccount = glaccount.id;
        QuotaScheduleController.fetchAllData();
        QuotaScheduleController.addQuotaSchedule(new List<Quota_Schedule__c>{quotaSchedule});
        QuotaScheduleController.createQuotaSchedule(new List<Quota_Schedule__c>{quotaSchedule}, '3');
        
        Test.stopTest();
        System.assert(True,[select id from Quota_Schedule__c LIMIT 1].size()  > 0);
    }
}
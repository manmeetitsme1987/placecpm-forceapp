/*
Description : Test class for QuotaScheduleTrigger
Date Created : 2nd July 2019
Change 1 :  PCPM-235 | Namita | 12 July
*/
@isTest
public class QuotaScheduleTriggerHandlerTest {
    static List<Quota_Schedule__c> quotaScheduleList;
    //PCPM-235
    static Organisation__c organisation;
    static GL_Code__c glaccount;
    static Role__c role;
    
    static void testSetup(){
        Assumption__c assumption = TestUtility.createAssumption(24 , false);
        assumption.Forecasting_Quota__c = 80;
        assumption.Average_License_Price__c = 105;
        assumption.Contract_Period__c = 12;
        insert assumption;
        
        P_L_Category__c plCategory = TestUtility.createPlCategory('Revenue','Revenue',True);
        glaccount = TestUtility.createGLCode('Recurring',600,plCategory.id,True);
        assumption.Revenue_GL_Account__c = glaccount.Id;
        update assumption;
        
        //PCPM-235
        organisation = TestUtility.createOrganisation('Place Technology', true); 
        Department__c department = TestUtility.createDepartment('SFDC', organisation.Id, glaccount.Id, true);  
        role = TestUtility.createRole('Tester', department.Id ,false);
        role.Is_Quota_Applicable__c = true;
        insert role;
        
        PlaceCPM_Utility.getAssumption();
        //PCPM-235
        Employee__c emp = TestUtility.createEmployee('TestEmployee',role.Id , System.today() ,'Austin','Salaried Employee',CONSTANT.EMPLOYEE_SALES_RT,True);
        
        quotaScheduleList = new List<Quota_Schedule__c>();
        Quota_Schedule__c qs = new Quota_Schedule__c();
        qs.Range_Start__c = 1;
        qs.Range_End__c = 2;
        qs.Quota_Amount__c = 100000;
        qs.type__c = String.valueOf(3);
        quotaScheduleList.add(qs);
        qs = new Quota_Schedule__c();
        qs.Range_Start__c = 2;
        qs.Range_End__c = 3;
        qs.Quota_Amount__c = 150000;
        qs.type__c = String.valueOf(3);
        quotaScheduleList.add(qs);
        qs = new Quota_Schedule__c();
        qs.Range_Start__c = 3;
        qs.Range_End__c = 5;
        qs.Quota_Amount__c = 200000;
        qs.type__c = String.valueOf(3);
        quotaScheduleList.add(qs);
        qs = new Quota_Schedule__c();
        qs.Range_Start__c = 5;
        qs.Quota_Amount__c = 250000;
        quotaScheduleList.add(qs);
        qs.type__c = String.valueOf(3);
        insert quotaScheduleList;
    }

    //  Method to test quota schdeule creation                
    //  @param 
    //  @return void
    static testMethod void testQuotaScheduleCreation(){
        testSetup();
        List<quota__c> quotas = [SELECT id FROM quota__c];
        System.assertEquals(quotas.size() , 8);
        quotaScheduleList[1].Quota_Amount__c = 175000;
        update quotaScheduleList[1];
        List<Quota_Schedule__c> qsList = [SELECT id  , Monthly_Amount__c FROM Quota_Schedule__c WHERE Range_Start__c = 2];
        //PCPM-235
        System.assertEquals(qsList[0].Monthly_Amount__c , [SELECT id , Monthly_Quota_Amount__c FROM quota__c where Quota_Schedule__c =: qsList[0].Id][0].Monthly_Quota_Amount__c);
        delete quotaScheduleList;
    }
}
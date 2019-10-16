@isTest 
public class EmployeeTriggerHandlerTest {
    static testmethod void testQuotaMethod(){
        Account acc = TestUtility.createAccount('TestAccount',True);
        P_L_Category__c plCategory = TestUtility.createPlCategory('General and Admin','Revenue',True);
        GL_Code__c glaccount = TestUtility.createGLCode('Recurring',600,plCategory.id,True);
        
        
        Assumption__c ass = TestUtility.createAssumption(24, true);
        ass.Average_License_Price__c = 345;
        ass.Contract_Period__c = 12;
        ass.Forecasting_Quota__c = 56;
        ass.Revenue_GL_Account__c = glaccount.id;
        update ass;
        
 		Quota_Schedule__c qs = new Quota_Schedule__c();
        qs.Type__c = '3';
        qs.Range_End__c = 1;
        qs.Range_Start__c = 1;
        insert qs;
        
        Organisation__c organisation = TestUtility.createOrganisation('Place Technology', true); 
        Department__c department = TestUtility.createDepartment('SFDC', organisation.Id, glaccount.Id, true);  
        Role__c role = TestUtility.createRole('Tester', department.Id ,true);
        Employee__c emp = TestUtility.createEmployee('TestEmployee',role.Id,System.today(),'Austin','Salaried Employee',CONSTANT.EMPLOYEE_SALES_RT,true);
       
        Quota__c quotaRec = TestUtility.createQuota(emp.Id , 100 , System.today() , System.today().addDays(365) , glaccount.Id , true);
		
        System.assert([select id from Quota__c].size()  > 0);
        
        emp.Employee_Status__c = 'Terminated';
        update emp;
        delete emp;       
    }
    static testmethod void testEmployeeMethod(){
        Account acc = TestUtility.createAccount('TestAccount',True);
        P_L_Category__c plCategory = TestUtility.createPlCategory('General and Admin','Expense',True);
        GL_Code__c glaccount = TestUtility.createGLCode('Advertising',600,plCategory.id,True);
        Organisation__c organisation = TestUtility.createOrganisation('Place Technology', true); 
        Department__c department = TestUtility.createDepartment('SFDC', organisation.Id, glaccount.Id, true);  
        Role__c role = TestUtility.createRole('Tester', department.Id ,false);
        role.Is_Quota_Applicable__c = true;
        insert role;
        Quota_Schedule__c quotaScheduleRec = new Quota_Schedule__c();
        quotaScheduleRec.Type__c = '1'; 
        quotaScheduleRec.Range_Start__c = 1; 
        quotaScheduleRec.Range_End__c = 2;
        insert quotaScheduleRec;
        
        Expense_Account__c expenseAcc = TestUtility.createExpenseAccount(acc.Id, glaccount.Id,'1', true);
        Expense_Detail__C expDetail = TestUtility.createExpenseDetail(expenseAcc.Id, System.Today().addDays(50), System.Today().addDays(300), System.Today().addDays(50),  100.00, '0', true);
        
        Expense_Allocation__c expenseAlloc = TestUtility.createExpenseAllocation(expenseAcc.Id, false);
        expenseAlloc.Role__c  = role.Id;
        expenseAlloc.Department__c = department.Id; 
        expenseAlloc.Organisation__c = organisation.Id;
        insert expenseAlloc;  
        
        Test.startTest();
        Employee__c emp = TestUtility.createEmployee('TestEmployee',role.Id, date.newinstance(2019, 6, 1),'Austin','Salaried Employee',CONSTANT.EMPLOYEE_SALES_RT,true);
        System.assert(true,[Select Id from Quota__c where Employee__c  =: emp.Id].size() > 0);
        emp.Employee_Start_Date__c = emp.Employee_Start_Date__c.addDays(1);
        emp.Expense_Account__c = expenseAcc.Id;
        emp.Employee_Status__c = 'Active';
        emp.Name = 'Test Employee 1';
        update emp;
        Compensation__c com = TestUtility.createCompensation(date.newinstance(2019, 6, 3),date.newinstance(2019, 6, 30),emp.id, 10,'Monthly', null,False);
        com.RecordTypeId = PlaceCPM_Utility.getRecordTypeIdbyDeveloperName('Compensation__c','Sales_Employee_Compensation');
        insert com;
        Wages__c wage = TestUtility.createWages(date.newinstance(2019, 6, 13), date.newinstance(2019, 6, 15), emp.Id, 1200 ,com.Id , 1300, 13000, false);
        wage.Employee_Number__c = emp.Id;
        insert wage;
        
        Test.stopTest();
     }
     static testMethod void testEmployeeUpdate(){
        P_L_Category__c plCategory = TestUtility.createPlCategory('General and Admin','Expense',True);
        GL_Code__c glaccount = TestUtility.createGLCode('Advertising',600,plCategory.id,True);
        Organisation__c organisation = TestUtility.createOrganisation('Place Technology', true); 
        Department__c department = TestUtility.createDepartment('SFDC', organisation.Id, glaccount.Id, true);  
        Role__c role = TestUtility.createRole('Tester', department.Id ,false);
        role.Is_Quota_Applicable__c = true;
        insert role;
        Id comSalesRecordTypeId = PlaceCPM_Utility.getRecordTypeIdbyDeveloperName('Compensation__c','Sales_Employee_Compensation');
        Employee__c employeeRec = TestUtility.createEmployee('TestEmployee',role.Id,date.newinstance(2019, 6, 1),'Austin','Salaried Employee',CONSTANT.EMPLOYEE_SALES_RT,true);
        Compensation__c com = TestUtility.createCompensation(date.newinstance(2019, 6, 1),date.newinstance(2019, 6, 30),employeeRec.id, 10,'Monthly', null,False);
        com.RecordTypeId = comSalesRecordTypeId;
        insert com;
        employeeRec.Employee_Status__c = 'Terminated';
        update employeeRec; 
        
        System.assertEquals(System.today(), [Select End_Date__c  from Compensation__c where Employee__c  =: employeeRec.Id].End_Date__c);
    }    
    
}
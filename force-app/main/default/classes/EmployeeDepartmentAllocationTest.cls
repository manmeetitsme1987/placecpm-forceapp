/*
Description : This class will be used to cover EmployeeDepartmentAllocationHandler class.
Date Created : 13th June 2019
Change 1 : Namita Choudhary | 24 June 19 | PCPM - 184
Change 2 : PCPM-235 | Namita | 11 July
*/
@isTest 
public class EmployeeDepartmentAllocationTest {
	static Account a;
    static P_L_Category__c plCat;
    static GL_Code__c glCode;
    public static Organisation__c organisation;
    public static Role__c role;

    static testMethod void testExpenseDetail(){
        createData();
        Test.startTest();
        Payment_Account__c pa = TestUtility.createPaymentAccount('testPaymentAccount',true);
        Expense_Account__c expA = TestUtility.createExpenseAccount(a.Id, glCode.Id, '3', false);
        expA.Payment_Account__c = pa.id;
        insert expA;
        Expense_Detail__c expDt = TestUtility.createExpenseDetail(expA.Id, System.Today(), System.Today().addDays(40),System.Today().addDays(20), 1000.00, '15', True);
        expDt.Expense_Amount__c = 1200;
        Update expDt;
        
        Employee__c employee1 = TestUtility.createEmployee('Test Emp 1',role.Id, system.today(), 'Jaipur', 'Salaried Employee',CONSTANT.EMPLOYEE_SALES_RT, true);   
        Employee_Department_Allocation__c deptAlloc1 = TestUtility.createExpenseDepartmentAllocation(20, 'Sales ', false);
        deptAlloc1.Employee__c = employee1.Id; 
        try{
           insert deptAlloc1;
        }catch(Exception ex){
           system.debug(ex.getStackTraceString() +'=='+ex.getMessage()); 
        }
        Employee_Department_Allocation__c deptAlloc2 = TestUtility.createExpenseDepartmentAllocation(100, 'Sales ', true);
        //deptAlloc2.Allocation_percentage__c = 80;
        //update deptAlloc2;
        try{
           delete deptAlloc2;
        }catch(Exception ex){
           system.debug(ex.getStackTraceString() +'=='+ex.getMessage()); 
        }
        System.assertEquals(1200, [Select Id,Expense_Amount__c from Expense_Detail__c].Expense_Amount__c);
        Test.stopTest();
    }

    static void createData(){
        Assumption__c aa = TestUtility.createAssumption(24,True);
        a = TestUtility.createAccount('Text vendor1', true);
        plCat=  TestUtility.createPlCategory('COGS','Expense',True);
        glCode = TestUtility.createGLCode('Advertising', 200, plCat.Id ,True);
        organisation = TestUtility.createOrganisation('Place Technology', true); 
        Department__c department = TestUtility.createDepartment('SFDC', organisation.Id, glCode.Id, true);  
        role = TestUtility.createRole('Tester', department.Id ,true);
    }
}
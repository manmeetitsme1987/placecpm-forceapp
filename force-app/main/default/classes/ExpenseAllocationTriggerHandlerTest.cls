/*
 * Class : ExpenseAllocationTriggerHandlerTest
 * Date  : 12 July 2019
 * Description - Test Class for ExpenseAllocationTriggerHandler | PCPM-235 | Namita | 12 July
 * 
 * Change 1 : Namita  | PCPM-322 | 23 July 19
 * Change 2 : Namita  | PCPM-329 | 25 July 19
 */

@isTest 
public class ExpenseAllocationTriggerHandlerTest {
    public static GL_Code__c glaccount;
    public static Organisation__c organisation;
    public static Department__c department;
    public static Role__c role;
    public static Expense_Account__c expenseAccount;
    public static Employee__c emp; //PCPM-322
    
    @isTest
    public static void testExpenseAllocationTriggerHandler1(){
        createData();
        Test.startTest();
            Expense_Allocation__c  expenseAlloc1 = TestUtility.createExpenseAllocation(expenseAccount.Id, false);
            expenseAlloc1.Organisation__c = organisation.Id; 
            expenseAlloc1.Department__c = department.Id; 
            expenseAlloc1.Role__c = role.Id; 
            insert expenseAlloc1;
        
            //PCPM-322
            List<Employee_Expense_Allocation__c> empExpenseAllocList = [SELECT Id, Employee__c FROM Employee_Expense_Allocation__c WHERE Employee__c=: emp.id];
            System.assertEquals(1, empExpenseAllocList.size());
        Test.stopTest();
    }
    
    @isTest
    public static void testExpenseAllocationTriggerHandler2(){
        createData();
        Test.startTest();
            Expense_Allocation__c  expenseAlloc1 = TestUtility.createExpenseAllocation(expenseAccount.Id, false);
            expenseAlloc1.Organisation__c = organisation.Id; 
            expenseAlloc1.Department__c = department.Id; 
            insert expenseAlloc1;
            List<Employee_Expense_Allocation__c> empExpenseAllocList = [SELECT Id, Employee__c FROM Employee_Expense_Allocation__c WHERE Employee__c=: emp.id];
            System.assertEquals(1, empExpenseAllocList.size());
       Test.stopTest(); 
    }
    
    @isTest
    public static void testExpenseAllocationTriggerHandler3(){
        createData();
        Test.startTest();
            Expense_Allocation__c  expenseAlloc1 = TestUtility.createExpenseAllocation(expenseAccount.Id, false);
            expenseAlloc1.Department__c = department.Id; 
            expenseAlloc1.Role__c = role.Id; 
            insert expenseAlloc1;
            List<Employee_Expense_Allocation__c> empExpenseAllocList = [SELECT Id, Employee__c FROM Employee_Expense_Allocation__c WHERE Employee__c=: emp.id];
            System.assertEquals(1, empExpenseAllocList.size());
       Test.stopTest(); 
    }
    
    @isTest
    public static void testExpenseAllocationTriggerHandler5(){
        createData();
        Test.startTest();
            Expense_Allocation__c  expenseAlloc1 = TestUtility.createExpenseAllocation(expenseAccount.Id, false);
            expenseAlloc1.Department__c = department.Id;
            insert expenseAlloc1;
            List<Employee_Expense_Allocation__c> empExpenseAllocList = [SELECT Id, Employee__c FROM Employee_Expense_Allocation__c WHERE Employee__c=: emp.id];
            System.assertEquals(1, empExpenseAllocList.size());
       Test.stopTest(); 
    }
    
    @isTest
    public static void testExpenseAllocationTriggerHandler6(){
        createData();
        Test.startTest();
            Expense_Allocation__c  expenseAlloc1 = TestUtility.createExpenseAllocation(expenseAccount.Id, false);
            expenseAlloc1.Organisation__c = organisation.Id; 
            insert expenseAlloc1;
            List<Employee_Expense_Allocation__c> empExpenseAllocList = [SELECT Id, Employee__c FROM Employee_Expense_Allocation__c WHERE Employee__c=: emp.id];
            System.assertEquals(1, empExpenseAllocList.size());
       Test.stopTest(); 
    }
    
    public static void createData(){
        Account acc = TestUtility.createAccount('TestAccount',true);
        
        P_L_Category__c plCategory = TestUtility.createPlCategory('General and Admin','Expense',true);
        glaccount = TestUtility.createGLCode('Recurring',600,plCategory.id,true);
        
        organisation = TestUtility.createOrganisation('Place Technology', true);
        department = TestUtility.createDepartment('SFDC', organisation.Id, glaccount.Id, true);  
        role = TestUtility.createRole('Tester', department.Id ,true);
        
        expenseAccount = TestUtility.createExpenseAccount(acc.Id, glaccount.Id, '1', true);
        //PCPM-322
        Expense_Detail__c expenseDetail = TestUtility.createExpenseDetail(expenseAccount.Id,System.today().addDays(-2) , System.today().addDays(60), System.today().addDays(10),2000 ,'30', true);
        emp = TestUtility.createEmployee('TestEmployee',role.Id, System.today(),'Austin','Salaried Employee',CONSTANT.EMPLOYEE_SALES_RT,true);
        System.assert(plCategory != null);            
    }
}
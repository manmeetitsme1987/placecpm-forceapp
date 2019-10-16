@isTest 
public class EmployeeExpenseAllocationTrgHndlTest {
    static testMethod void employeeExpenseAllocationTest(){
      
        Assumption__c assumptionRec = TestUtility.createAssumption(1,True);
       
        P_L_Category__c plCategory = TestUtility.createPlCategory('General and Admin','Expense',True);
               
        GL_Code__c glaccount = TestUtility.createGLCode('Advertising',600,plCategory.id,True);
        
        Organisation__c organisation = TestUtility.createOrganisation('Place Technology', true); 
        Department__c department = TestUtility.createDepartment('SFDC', organisation.Id, glaccount.Id, true);  
        Role__c role = TestUtility.createRole('Tester', department.Id ,true);
        
        Employee__c employeeRec = TestUtility.createEmployee('TestEmployee',role.Id, System.today(),'Austin','Salaried Employee',CONSTANT.EMPLOYEE_OPERATIONS_RT,True);
        
        Account acc = TestUtility.createAccount('TestAccount',True); 
        Payment_Account__c pa = TestUtility.createPaymentAccount('testPaymentAccount',true);
        Expense_Account__c expenseAccountRec = TestUtility.createExpenseAccount(acc.Id, glaccount.Id,'3', false);
        expenseAccountRec.Payment_Account__c = pa.id;
        insert expenseAccountRec;
        Expense_Detail__c expDt = TestUtility.createExpenseDetail(expenseAccountRec.Id, System.Today(), System.Today().addDays(300),System.Today().addDays(20), 1000.00, '15', True);
        
        Test.startTest();

        Employee_Expense_Allocation__c employeeExAlloctionRec = new Employee_Expense_Allocation__c (Employee__c = employeeRec.Id,Start_Date__c =System.Today(), Expense_Account__c = expenseAccountRec.Id);
        insert employeeExAlloctionRec;

        
        employeeExAlloctionRec.Start_Date__c = System.Today().addDays(31);
        update employeeExAlloctionRec;

        //assert
        System.assertEquals(true, [Select Id,Start_Date__c from Employee_Expense_Allocation__c where Expense_Account__c =:expenseAccountRec.Id].Start_Date__c >= System.today());

        delete employeeExAlloctionRec;

        Test.stopTest();
      }      
}
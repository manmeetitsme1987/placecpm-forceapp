@isTest
public class ExpensePLAllocationTriggerTest {
    static testMethod void checkRecordForAssumption(){ 
        Test.StartTest();
        TestUtility.createAssumption(24,true);
        Profit_Loss__c pl = TestUtility.createPL('Test', Date.today(), date.today(), true);
        P_L_Category__c plCategory = TestUtility.createPlCategory('Test','Expense', true);
        GL_Code__c glCode = TestUtility.createGLCode('Test', 500, plCategory.Id, true);
        
        Account account1 = TestUtility.createAccount('Test vendor1', true);
        Payment_Account__c pa = TestUtility.createPaymentAccount('testPaymentAccount',true);
        
        Expense_Account__c expAcc = TestUtility.createExpenseAccount(account1.Id, glCode.Id, '3', false);
        expAcc.Name = 'D-Link';
        expAcc.Payment_Account__c = pa.id;
        insert expAcc;
        
        Expense_Detail__c expDt = TestUtility.createExpenseDetail(expAcc.Id, System.today().addDays(200), System.Today().addDays(300), System.Today().addDays(200) , 1000.00, '0', True);
        Expense_PL_Allocation__c expense = TestUtility.createExpensePlAllocation(glCode.Id, pl.Id, true);   
        System.assert([Select id from P_L_Statement__c].size() > 0 , '');
        Test.stopTest();
        
        expense.Forecast_Amount__c = 200;
        expense.Expense_Account__c = expAcc.id;
        expense.Expense_Detail__c = expDt.id;
        update expense;
        
        delete expense;     
    }
    
}
@isTest
private class ExpenseCashAllocationTriggerHandlerTest {
    
    @testSetup
    static void createTestData(){
        Assumption__c aa = TestUtility.createAssumption(24,True);
        P_L_Category__c plCat=  TestUtility.createPlCategory('COGS','Expense',True);
        GL_Code__c glCode = TestUtility.createGLCode('Advertising', 200, plCat.Id ,True);
        Account a = TestUtility.createAccount('Text vendor1', true);
        Payment_Account__c pa = TestUtility.createPaymentAccount('testPaymentAccount',true);
        Expense_Account__c expA = TestUtility.createExpenseAccount(a.Id, glCode.Id, '3', false);
        expA.Payment_Account__c = pa.id;
        insert expA;
        Expense_Detail__c expDt = TestUtility.createExpenseDetail(expA.Id, System.Today(), System.Today().addDays(40),System.Today(), 1000.00, '15', True);
    }

    @isTest
    static void testMethod1(){
        Test.startTest();
        List<Expense_Cash_Allocation__c> expCashList = new List<Expense_Cash_Allocation__c>();
        for(Expense_Cash_Allocation__c expCash : [SELECT Id, Payment_Account_Id__c, Actual_Amount__c, Forecast_Amount__c FROM Expense_Cash_Allocation__c LIMIT 5]){
			Expense_Cash_Allocation__c exToUpdate = new Expense_Cash_Allocation__c();
            exToUpdate.Id = expCash.Id;
            exToUpdate.Forecast_Amount__c = 10;
            expCashList.add(expCash);
        }
        if(expCashList.size()>0){
            update expCashList;
        }
        Test.stopTest();
        List<P_L_Statement__c> plsList = [SELECT Id FROM P_L_Statement__c WHERE Parent_Bank_Account__c = :expCashList[0].Payment_Account_Id__c ];
        System.assert(plsList.size() > 0);
    }
}
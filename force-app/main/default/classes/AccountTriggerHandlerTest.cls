/*
Description : Test Class for AccountTriggerHandler
Date Created : 18 July 2019 | PCPM-304
Change 1 :  
*/

@isTest
public class AccountTriggerHandlerTest {
	static Account account1;
    static Expense_Account__c expAcc;
    static P_L_Category__c plCat;
    static GL_Code__c glCode;
    
    @isTest
    public static void testAccountTriggerHandler(){
        createData();
        Test.startTest();
            Expense_Account__c expAcc2 = [SELECT Id, Name,Vendor__c,Vendor__r.Name FROM Expense_Account__c WHERE Id = :expAcc.Id];
            account1.Name = 'Test vendor - N';
            update account1;
        
            List<Expense_Account__c> expenseAccList = [SELECT Id, Name, Vendor__c,Vendor__r.Name FROM Expense_Account__c WHERE Id =: expAcc.Id]; 
            system.assert(expenseAccList[0].Name == 'Test vendor - N - D-Link');
        Test.stopTest();
    }
    
    static void createData(){
        Assumption__c aa = TestUtility.createAssumption(24,True);
        account1 = TestUtility.createAccount('Test vendor1', true);
        plCat=  TestUtility.createPlCategory('COGS','Expense',True);
        glCode = TestUtility.createGLCode('Advertising', 200, plCat.Id ,True);

        Payment_Account__c pa = TestUtility.createPaymentAccount('testPaymentAccount',true);
        expAcc = TestUtility.createExpenseAccount(account1.Id, glCode.Id, '3', false);
        expAcc.Name = 'D-Link';
        expAcc.Payment_Account__c = pa.id;
        insert expAcc;
    }
}
/*
Description : Test Class for ExpenseDetailTriggerHandler and ExpenseAccountDetailTriggerHandler.
Date Created : 
Change 1 :  Namita | PCPM-299 | 16 JULY 19
Change 2 :  Namita | PCPM-304 | 18 JULY 19
*/
@isTest 
public class ExpenseAccountDetailTriggerTest {
    static Account account1;
    static Account account2;
    static P_L_Category__c plCat;
    static GL_Code__c glCode;
    static P_L_Category__c plCat1;
    static GL_Code__c glCode1;
    static List<Expense_Detail__c> expDtList;
    static Expense_Account__c expAcc;

    static testMethod void testExpenseDetail(){
        createData();
        Test.startTest();
            Expense_Detail__c expDt = TestUtility.createExpenseDetail(expAcc.Id, System.today().addDays(200), System.Today().addDays(300), System.Today().addDays(200) , 1000.00, '0', True);
            List<Expense_PL_Allocation__c> plsList = [Select id, P_L__r.Period_Start_Date__c, P_L__r.Period_End_Date__c, Expense_Detail__c from Expense_PL_Allocation__c where Expense_Detail__c =: expDt.id order by P_L__r.Period_Start_Date__c asc];
            List<Expense_Cash_Allocation__c> cshList = [Select id, cash_date__c,  Expense_Detail__c from Expense_Cash_Allocation__c where Expense_Detail__c =: expDt.id order by  cash_date__c asc ];
            System.assert(plsList.size() > 0);
            System.assert(cshList.size() > 0);
        Test.stopTest();
    }
    
    static testMethod void testExpenseDetailUpdate(){
        createData();
        Test.startTest();
            //PCPM-304
            Expense_Account__c expAcc2 = [SELECT Id, Name,Vendor__c,Vendor__r.Name FROM Expense_Account__c WHERE Id = :expAcc.Id];
            System.assert(expAcc2.Name == 'Test vendor1 - D-Link');
            expAcc2.Vendor__c = account2.Id;
            update expAcc2;
            List<Expense_Account__c> expenseAccList = [SELECT Id, Name, Vendor__c,Vendor__r.Name FROM Expense_Account__c WHERE Id =: expAcc.Id]; 
            System.assert(expenseAccList[0].Name == 'Test vendor2 - D-Link');

            Expense_Detail__c expDt = TestUtility.createExpenseDetail(expAcc.Id, System.today().addDays(200), System.Today().addDays(325), System.Today().addDays(200) , 1000.00, '0', True);
            expDt.Expense_Amount__c = 1200;
            List<Expense_PL_Allocation__c> plsList = [Select id, P_L__r.Period_Start_Date__c, P_L__r.Period_End_Date__c, Expense_Detail__c from Expense_PL_Allocation__c where Expense_Detail__c =: expDt.id order by P_L__r.Period_Start_Date__c asc];
            
            Update expDt;
            
            expDt.end_Date__c = System.Today().addDays(275);
        	update expDt;
        
            List<Expense_PL_Allocation__c> plsList1 = [Select id, P_L__r.Period_Start_Date__c, P_L__r.Period_End_Date__c, Expense_Detail__c from Expense_PL_Allocation__c where Expense_Detail__c =: expDt.id order by P_L__r.Period_Start_Date__c asc];
            List<Expense_Cash_Allocation__c> cshList1 = [Select id, cash_date__c,  Expense_Detail__c from Expense_Cash_Allocation__c where Expense_Detail__c =: expDt.id order by  cash_date__c asc ];
            System.assert(plsList.size() > plsList1.size());
        Test.stopTest();
    }
    
    static testMethod void testExpenseDetailDelete(){
        createData();
        Test.startTest();
            Expense_Detail__c expDt = TestUtility.createExpenseDetail(expAcc.Id, System.today().addDays(200), System.Today().addDays(300), System.Today().addDays(200) , 1000.00, '0', True);
            String expDetId = expDt.id;
            delete expDt;
            List<Expense_PL_Allocation__c> plsList = [Select id, P_L__r.Period_Start_Date__c, P_L__r.Period_End_Date__c, Expense_Detail__c from Expense_PL_Allocation__c where Expense_Detail__c =: expDt.id order by P_L__r.Period_Start_Date__c asc];
            List<Expense_Cash_Allocation__c> cshList = [Select id, cash_date__c,  Expense_Detail__c from Expense_Cash_Allocation__c where Expense_Detail__c =: expDt.id order by  cash_date__c asc ];
            System.assert(plsList.size() == 0);
            System.assert(cshList.size() == 0);
            delete expAcc;
        Test.stopTest();
    }
    
    static void createData(){
        Assumption__c aa = TestUtility.createAssumption(24,True);
        account1 = TestUtility.createAccount('Test vendor1', true);
        account2 = TestUtility.createAccount('Test vendor2', true);
        plCat=  TestUtility.createPlCategory('COGS','Expense',True);
        glCode = TestUtility.createGLCode('Advertising', 200, plCat.Id ,True);

        Payment_Account__c pa = TestUtility.createPaymentAccount('testPaymentAccount',true);
        expAcc = TestUtility.createExpenseAccount(account1.Id, glCode.Id, '3', false);
        expAcc.Name = 'D-Link';
        expAcc.Payment_Account__c = pa.id;
        insert expAcc;

        expDtList = new List<Expense_Detail__c>();
        expDtList.add(TestUtility.createExpenseDetail(expAcc.Id, System.Today().addDays(50), System.Today().addDays(300), System.Today().addDays(50),  100.00, '0', false));
        expDtList.add(TestUtility.createExpenseDetail(expAcc.Id, System.Today().addDays(100), System.Today().addDays(350),System.Today().addDays(100), 200.00, '0', false));
        expDtList.add(TestUtility.createExpenseDetail(expAcc.Id, System.Today().addDays(150), System.Today().addDays(400),System.Today().addDays(150), 300.00, '15', false));
        TestUtility.createExpenseDetailList(expDtList, true);
    }

    @isTest
    static void testRecurringRevenue(){
        createData();
        String expDelRevenueRecurringRtId = PlaceCPM_Utility.getRecordTypeIdbyDeveloperName('Expense_Detail__c', CONSTANT.EXPENSE_DETAIL_REVENUE_RECURRING_RT);
        plCat1=  TestUtility.createPlCategory('REVENUE','Revenue',false);
        plCat1.Sequence__c =2;
        insert plCat1;
        glCode1 = TestUtility.createGLCode('Travel', 300, plCat1.Id ,false);
        glCode1.Sequence__c =2;
        insert glCode1;
        Payment_Account__c pa = TestUtility.createPaymentAccount('testPaymentAccount1',true);
        expAcc = TestUtility.createExpenseAccount(account1.Id, glCode.Id, '3', false);
        expAcc.Name = 'D-Link';
        expAcc.Payment_Account__c = pa.id;
        expAcc.GL_Account_Revenue__c = glCode1.id;
        insert expAcc;

         expDtList = new List<Expense_Detail__c>();
        expDtList.add(TestUtility.createExpenseDetail(expAcc.Id, System.Today().addMonths(2), System.Today().addMonths(10), System.Today().addMonths(2),  100.00, '0', false));

        for(Expense_Detail__c expDel : expDtList){
            expDel.Amount_of_Revenue__c = 10;
            expDel.RecordTypeId = expDelRevenueRecurringRtId;
        }
        Test.startTest();
        if(expDtList.size()>0){
            insert expDtList;
        }

         Test.stopTest();
        List<Expense_PL_Allocation__c> plsList = [Select id, P_L__r.Period_Start_Date__c,GL_Code__r.Name, P_L__r.Period_End_Date__c, Expense_Detail__c from Expense_PL_Allocation__c where Expense_Detail__c =: expDtList[0].id order by P_L__r.Period_Start_Date__c asc];
        System.assertEquals('Advertising', plsList[0].GL_Code__r.Name);
     }
}
/*
Description  : Test Class for placeCPM_CreatePLAndCashRecords
Date Created : 12 JULY 19
Change 1 :  Namita | PCPM-299 | 16 JULY 19
*/
@isTest
public class placeCPM_CreatePLAndCashRecordsTest {
   static Assumption__c assumptionRec;
   static Account acc;
   static List<Profit_Loss__c> listPL;
   static List<Cash_Forecast__c> listCashForecast;
   static Payment_Account__c paymentAcc;
    
    static void createtestData(){
         assumptionRec = TestUtility.createAssumption(1, true); 
         system.debug('assumptionRec=='+assumptionRec);
         acc = TestUtility.createAccount('TestAccount1',True);
         listPL = new List<Profit_Loss__c>();
         listCashForecast = new List<Cash_Forecast__c>();
         Map<Integer,String> mapMonthYear = new Map<Integer,String>();
         mapMonthYear.put(3,'March 2020');
         mapMonthYear.put(4,'April 2020');
         mapMonthYear.put(5,'May 2020');
         mapMonthYear.put(6,'June 2020');
         //mapMonthYear.put(7,'July 2020');
         //mapMonthYear.put(8,'August 2020');
         for(Integer i = 3; i < 7 ; i++){
           Profit_Loss__c pl = TestUtility.createPL(mapMonthYear.get(i),date.newinstance(2020, i, 1),date.newinstance(2020, i, Date.daysInMonth(2020,i)),false);
           Cash_Forecast__c cashForcast = TestUtility.createCashForecast(mapMonthYear.get(i),date.newinstance(2020, i, 1),date.newinstance(2020, i, Date.daysInMonth(2020,i)),false);
           listPL.add(pl);
           listCashForecast.add(cashForcast);
         }
         if(listPL.size()>0){
            insert listPL;
         }
         if(listCashForecast.size() > 0){
            insert listCashForecast;
         }
         paymentAcc = TestUtility.createPaymentAccount('HDFC Bank',true);
    }
    
    @isTest
    public static void testCreatePLAndCashRecords(){
        createtestData();
        P_L_Category__c plCategoryExp = TestUtility.createPlCategory('General and Admin','Expense',true);
        GL_Code__c glaccountExp = TestUtility.createGLCode('Recurring',600,plCategoryExp.id,true);
        Expense_Account__c expenseAcc = TestUtility.createExpenseAccount(acc.Id, glaccountExp.Id, '1', false);
        expenseAcc.Payment_Account__c = paymentAcc.Id;
        insert expenseAcc;
        Expense_Detail__c expenseDetail = TestUtility.createExpenseDetail(expenseAcc.Id, date.newinstance(2020, 7, 1), date.newinstance(2020, 7, 11),date.newinstance(2020, 9, 11), 45000, '30', false);
        expenseDetail.Auto_Renew__c = true;
        insert expenseDetail;
        Expense_PL_Allocation__c expensePLAlloc = new Expense_PL_Allocation__c(Expense_Account__c = expenseAcc.Id,
                                                                               Expense_Detail__c= expenseDetail.Id,
                                                                               GL_Code__c= glaccountExp.Id,
                                                                               P_L__c = listPL[0].Id);
        insert expensePLAlloc;
        Expense_Cash_Allocation__c expenseCashAlloc = new Expense_Cash_Allocation__c(Expense_Account__c = expenseAcc.Id,
                                                                                     Expense_Detail__c= expenseDetail.Id, 
                                                                                     Cash_Forecast__c = listCashForecast[0].Id,
                                                                                     Cash_Date__c = date.newinstance(2020, 7, 21),
                                                                                     Forecast_Amount__c =2000);
        insert expenseCashAlloc;
        
        Test.startTest();
            placeCPM_CreatePLAndCashRecords obj = new placeCPM_CreatePLAndCashRecords();
            Database.executeBatch(obj);
            List<Expense_PL_Allocation__c> expensePLAllocList = [SELECT id, Expense_Account__c,P_L__c FROM Expense_PL_Allocation__c WHERE Expense_Account__c =: expenseAcc.Id];
            List<Expense_Cash_Allocation__c> expenseCashAllocList = [SELECT id, Expense_Account__c FROM Expense_Cash_Allocation__c WHERE Expense_Account__c =: expenseAcc.Id];
            system.assert(expensePLAllocList.size() > 0);
            system.assert(expenseCashAllocList.size() > 0);
        Test.stopTest();
    }
    
    @isTest
    public static void testCreatePLAndCashRecords2(){
        createtestData();
        P_L_Category__c plCategory = TestUtility.createPlCategory('General and Admin','Revenue',true);
        GL_Code__c glaccount = TestUtility.createGLCode('Recurring',600,plCategory.id,true);
        Revenue_Account__c revenueAccount = TestUtility.createRevenueAccount(acc.Id, glaccount.Id, paymentAcc.Id ,'1',false);
        insert revenueAccount;
        Revenue_Contract__c revenueContract = TestUtility.createRevenueContract(revenueAccount.Id, date.newinstance(2020, 7, 1),
                                                            date.newinstance(2020, 8, 31), '30',
                                                            date.newinstance(2020, 7, 11), false);
        revenueContract.Live_Renewed_Date__c = date.newinstance(2020, 8, 21);
        revenueContract.Auto_Renew__c = true;
        insert revenueContract;
        Product__c pdt1 = TestUtility.createProduct('Product 1','Product', 1400,'License',true); 
        Revenue_P_L_Allocation__c  revenuePLAlloc = new Revenue_P_L_Allocation__c (P_L__c = listPL[0].Id, Revenue_Account__c =revenueAccount.Id, Revenue_Contract__c =revenueContract.id, GL_Code__c=glaccount.Id);
        insert revenuePLAlloc;
        Contract_Line_Items__c cli1 = TestUtility.createContractLineItem('CLI 1' ,revenueContract.Id, 1,pdt1.Id, false);
        cli1.Total_Amount__c  = 100;
        insert cli1;
        Revenue_Cash_Allocation__c revenueCashAlloc = new Revenue_Cash_Allocation__c(Revenue_Account__c =revenueAccount.Id,
                                                                                     Revenue_Contract__c =revenueContract.Id,
                                                                                     Cash_Forecast__c = listCashForecast[0].Id,
                                                                                     Cash_Date__c = date.newinstance(2020, 7, 21),
                                                                                     Forecast_Amount__c =2000 );
        
        insert revenueCashAlloc;
        Test.startTest();
            placeCPM_CreatePLAndCashRecords obj = new placeCPM_CreatePLAndCashRecords();
            Database.executeBatch(obj);
            List<Revenue_P_L_Allocation__c> revenuePLAllocList = [SELECT id, Revenue_Account__c,P_L__c FROM Revenue_P_L_Allocation__c WHERE Revenue_Account__c =: revenueAccount.Id];
            List<Revenue_Cash_Allocation__c> revenueCashAllocList = [SELECT id, Revenue_Account__c FROM Revenue_Cash_Allocation__c WHERE Revenue_Account__c =: revenueAccount.Id];
            system.assert(revenuePLAllocList.size() > 0);
            system.assert(revenueCashAllocList.size() > 0);
        Test.stopTest();
    }
}
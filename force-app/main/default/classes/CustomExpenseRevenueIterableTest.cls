@isTest
public class CustomExpenseRevenueIterableTest {
   static Assumption__c assumptionRec;
   static Account acc;
   static List<Profit_Loss__c> listPL;
   static List<Cash_Forecast__c> listCashForecast;
    
    static void createtestData(){
         assumptionRec = TestUtility.createAssumption(1, true);
         acc = TestUtility.createAccount('TestAccount1',True);
         listPL = new List<Profit_Loss__c>();
         listCashForecast = new List<Cash_Forecast__c>();
         Map<Integer,String> mapMonthYear = new Map<Integer,String>();
         mapMonthYear.put(3,'March 2020');
         mapMonthYear.put(4,'April 2020');
         mapMonthYear.put(5,'May 2020');
         mapMonthYear.put(6,'June 2020');
         mapMonthYear.put(7,'July 2020');
         mapMonthYear.put(8,'August 2020');
         for(Integer i = 3; i < 9 ; i++){
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
    }
    
    @isTest
    public static void testCreatePLAndCashRecords(){
        createtestData();
        P_L_Category__c plCategoryExp = TestUtility.createPlCategory('General and Admin','Expense',true);
        GL_Code__c glaccountExp = TestUtility.createGLCode('Recurring',600,plCategoryExp.id,true);
        Expense_Account__c expenseAcc = TestUtility.createExpenseAccount(acc.Id, glaccountExp.Id, '1', true);
        Expense_Detail__c expenseDetail = TestUtility.createExpenseDetail(expenseAcc.Id, date.newinstance(2020, 7, 1), date.newinstance(2020, 7, 11),date.newinstance(2020, 9, 11), 45000, '30', true);
            
        Test.startTest();
        placeCPM_CustomExpenseRevenueIterable obj = new placeCPM_CustomExpenseRevenueIterable();
        boolean hasNext = obj.hasNext();
        SObject next = obj.next();
        System.assertEquals(true,hasNext);
        Test.stopTest();
    }
    
    @isTest
    public static void testCreatePLAndCashRecords2(){
        createtestData();
        P_L_Category__c plCategory = TestUtility.createPlCategory('General and Admin','Revenue',true);
        GL_Code__c glaccount = TestUtility.createGLCode('Recurring',600,plCategory.id,true);
        Payment_Account__c paymentAccount = TestUtility.createPaymentAccount('Test P1',true);
        Revenue_Account__c revenueAccount = TestUtility.createRevenueAccount(acc.Id, glaccount.Id,paymentAccount.Id ,null,true);
        
        Revenue_Contract__c revenueContract = TestUtility.createRevenueContract(revenueAccount.Id, date.newinstance(2020, 7, 1),
                                                            date.newinstance(2020, 8, 31), '30',
                                                            date.newinstance(2020, 7, 11), false);
        //revenueContract.Auto_Renew__c = true;
        insert revenueContract;
        
        Product__c pdt1 = TestUtility.createProduct('Product 1','Product', 1400,'License',true); 
        //Revenue_P_L_Allocation__c  revenuePLAlloc = new Revenue_P_L_Allocation__c (P_L__c = listPL[0].Id, Revenue_Account__c =revenueAccount.Id, Revenue_Contract__c =revenueContract.id);
        //insert revenuePLAlloc;
        Contract_Line_Items__c cli1 = TestUtility.createContractLineItem('CLI 1' ,revenueContract.Id, 1,pdt1.Id, false);
        cli1.Total_Amount__c  = 100;
        insert cli1;
       
        Test.startTest();
        placeCPM_CustomExpenseRevenueIterable obj = new placeCPM_CustomExpenseRevenueIterable();
        System.assertEquals(1, [Select Id from Revenue_Contract__c where Revenue_Account__c =: revenueAccount.Id].size());
        Test.stopTest();
    }
}
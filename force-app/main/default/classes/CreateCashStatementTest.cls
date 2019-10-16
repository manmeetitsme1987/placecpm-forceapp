@isTest 
public class CreateCashStatementTest {
    static GL_Code__c glCode;
    static GL_Code__c glCode1;
    static Expense_Account__c expAcc;
    static Account account1;
    static List<Profit_Loss__c> listPL;
    static List<Cash_Forecast__c> listCashForecast;
    static GL_Code__c glaccountRevenueNew;

    static void createTestData(){
        TestUtility.createAssumption(24,true);
        Profit_Loss__c pl = TestUtility.createPL('Test', Date.today(), date.today(), true);
        P_L_Category__c plCategory = TestUtility.createPlCategory('Test','Expense', true);
        glCode = TestUtility.createGLCode('Test', 500, plCategory.Id, true);
        glCode1 = TestUtility.createGLCode('Test1', 300, plCategory.Id, true);
        account1 = TestUtility.createAccount('Test vendor1', true);
        Payment_Account__c pa = TestUtility.createPaymentAccount('testPaymentAccount',true);
        
        expAcc = TestUtility.createExpenseAccount(account1.Id, glCode.Id, '3', false);
        expAcc.Name = 'D-Link';
        expAcc.Payment_Account__c = pa.id;
        insert expAcc;
        
        Expense_Detail__c expDt = TestUtility.createExpenseDetail(expAcc.Id,  date.newInstance(2019,01,01) ,  date.newInstance(2019,12,31) , date.newInstance(2019,01,01) , 1000.00, '0', True);
        Expense_PL_Allocation__c expense = TestUtility.createExpensePlAllocation(glCode.Id, pl.Id, true);   
    
    }
    
    static testMethod void createTestDataRevenue(){
        TestUtility.createAssumption(24,true);
        account1 = TestUtility.createAccount('Test vendor1', true);
        P_L_Category__c plCategoryRevenue = TestUtility.createPlCategory('General and Admin','Revenue',true);
        GL_Code__c glaccountRevenue = TestUtility.createGLCode('Recurring',600,plCategoryRevenue.id,true);
        glaccountRevenueNew = TestUtility.createGLCode('RecurringNew',700,plCategoryRevenue.id,true);
        listPL = new List<Profit_Loss__c>();
        listCashForecast = new List<Cash_Forecast__c>();
        Map<Integer,String> mapMonthYear = new Map<Integer,String>();
        mapMonthYear.put(3,'March 2020');
        mapMonthYear.put(4,'April 2020');
        mapMonthYear.put(5,'May 2020');
        mapMonthYear.put(6,'June 2020');
        for(Integer i = 3; i < 7 ; i++){
           Profit_Loss__c pls = TestUtility.createPL(mapMonthYear.get(i),date.newinstance(2020, i, 1),date.newinstance(2020, i, Date.daysInMonth(2020,i)),false);
           Cash_Forecast__c cashForcast = TestUtility.createCashForecast(mapMonthYear.get(i),date.newinstance(2020, i, 1),date.newinstance(2020, i, Date.daysInMonth(2020,i)),false);
           listPL.add(pls);
           listCashForecast.add(cashForcast);
         }
         insert listCashForecast;
         if(listPL.size()>0){
            insert listPL;
         }
        Payment_Account__c paymentAcc = TestUtility.createPaymentAccount('HDFC Bank',true);
        Revenue_Account__c revenueAccount = TestUtility.createRevenueAccount(account1.Id, glaccountRevenue.Id, paymentAcc.Id ,'1',false);
        insert revenueAccount;
        Revenue_Contract__c revenueContract = TestUtility.createRevenueContract(revenueAccount.Id, date.newinstance(2020, 7, 1),
                                                            date.newinstance(2020, 8, 31), '30',
                                                            date.newinstance(2020, 7, 11), false);
        revenueContract.Live_Renewed_Date__c = date.newinstance(2020, 8, 21);
        revenueContract.Auto_Renew__c = true;
        insert revenueContract;
        Product__c pdt1 = TestUtility.createProduct('Product 1','Product', 1400,'License',true); 
        Revenue_Cash_Allocation__c   revenuePLAlloc = new Revenue_Cash_Allocation__c  (Cash_Forecast__c  = listCashForecast[0].Id, Revenue_Account__c =revenueAccount.Id, Revenue_Contract__c =revenueContract.id, GL_Code__c=glaccountRevenue.Id , Cash_Date__c = system.today() , Forecast_Amount__c = 100.00);
        insert revenuePLAlloc;
        revenuePLAlloc.Forecast_Amount__c = 200.00;
        revenuePLAlloc.Actual_Amount__c = 100;
        update revenuePLAlloc;
        delete revenuePLAlloc;
        System.assert([select id from P_L_Statement__c].size() > 0 , 'Pl statement inserted');
    }
    
    static testMethod void testExpensePlUpdate(){
        createTestData();
        Map<id , Expense_PL_Allocation__c> expl = new Map<id , Expense_PL_Allocation__c>([select id , GL_Code__c  , PLCategory__c , PL_Year__c , PL_Month__c , GL_Code_Sequence__c , PL_Sequence__c , Forecast_Amount__c , Actual_Amount__c from Expense_PL_Allocation__c]);
        CreatePLStatements.createCategoryStatements(expl.values() , null);
        List<Expense_PL_Allocation__c> explListNew = new List<Expense_PL_Allocation__c>();
        for(Expense_PL_Allocation__c exp : expl.values()){
            exp.GL_Code__c = glCode1.Id;
            exp.Forecast_Amount__c = 100;
            exp.Actual_Amount__c = 100;
            explListNew.add(exp);
        }
        upsert explListNew;
        System.assert([select id from P_L_Statement__c].size() > 0 , 'Pl statement inserted');
        delete explListNew;
    }
}
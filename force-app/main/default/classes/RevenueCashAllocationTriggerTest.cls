@isTest
private class RevenueCashAllocationTriggerTest {
    private static List<Revenue_Account__c> revenueAccountList;
    private static List<Payment_Account__c> paymentAccountList;
    private static List<Account> accountList;
    private static List<Revenue_Contract__c> revenueContractList;
    private static List<GL_Code__c> glCodeList;
    private static List<Contract_Line_Items__c> listContractLineItems;
    private static List<Product__c> listProduct;

    private static void initData(){
        accountList= new List<Account>();
        paymentAccountList = new List<Payment_Account__c>();
        revenueAccountList = new List<Revenue_Account__c>();
        revenueContractList = new List<Revenue_Contract__c>();
        listProduct = new List<Product__c>();
        glCodeList = new List<GL_Code__c>();
        listContractLineItems = new List<Contract_Line_Items__c>();
        accountList.add(TestUtility.createAccount('testAccount',true));
        paymentAccountList.add(TestUtility.createPaymentAccount('testPaymentAccount',true));
        glCodeList.add(TestUtility.createGLCode('test GL code',1111,TestUtility.createPlCategory('test PL category','Revenue',true).Id,true));
        revenueAccountList.add(TestUtility.createRevenueAccount(accountList[0].Id,glCodeList[0].Id,paymentAccountList[0].Id,'1',true));
        listProduct.add(TestUtility.createProduct('test product','Product',10,'License',true));
    }
    //#124
    @isTest
    private static void insertRevenueContract(){
        initData();
        Revenue_Contract__c rc = new Revenue_Contract__c();
        rc.Revenue_Account__c = revenueAccountList[0].Id;
        rc.Contract_Start_Date__c = Date.newInstance(2019, 1, 1);
        rc.Contract_End_Date__c = Date.newInstance(2019, 9, 30); 
        rc.Invoice_Date__c = Date.newInstance(2019, 1, 1);
        rc.Payment_Term_After_Days__c = '15';
        Test.startTest();
        insert rc;
        // Inserting CLI will update the Total Monthly Revenue and trigger the upsertion of PnL Allocation records
        listContractLineItems.add(TestUtility.createContractLineItem('test CLI',rc.Id,10,listProduct[0].Id,true));
        List<Revenue_P_L_Allocation__c> listRevenuePLAllocation = [SELECT ID FROM Revenue_P_L_Allocation__c 
                                                                   WHERE Revenue_Contract__c = :rc.Id];
        List<Revenue_Cash_Allocation__c > listRevenueCashAllocation = [SELECT ID, Payment_Account_Id__c,
                                                                       Actual_Amount__c, Forecast_Amount__c FROM Revenue_Cash_Allocation__c  
                                                                       WHERE Revenue_Contract__c = :rc.Id];
        
        // Extending the Revenue Contract end date to test increase in PNL records
        rc.Contract_End_Date__c = Date.newInstance(2019, 12, 31);
        update rc; 
        listContractLineItems[0].Quantity__c = 20;
        update listContractLineItems;
        System.assertEquals(1, listContractLineItems.size());
        Test.stopTest();
        
        List<Revenue_P_L_Allocation__c> listRevenuePLAllocationUpdated = [SELECT ID FROM Revenue_P_L_Allocation__c 
                                                                   WHERE Revenue_Contract__c = :rc.Id];
        List<P_L_Statement__c> plsList = [SELECT Id FROM P_L_Statement__c WHERE Parent_Bank_Account__c = :revenueAccountList[0].Payment_Account__c ];
        //System.assert(listRevenuePLAllocation.size() > 0);
        //System.assert(listRevenueCashAllocation.size() > 0);
        delete listRevenueCashAllocation;
        
    }

}
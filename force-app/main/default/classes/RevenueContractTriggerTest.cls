@isTest
public class RevenueContractTriggerTest {
    public static List<Revenue_Account__c> revenueAccountList;
    public static List<Payment_Account__c> paymentAccountList;
    public static List<Account> accountList;
    public static List<Revenue_Contract__c> revenueContractList;
    public static List<GL_Code__c> glCodeList;
    public static List<Contract_Line_Items__c> listContractLineItems;
    public static List<Product__c> listProduct;
    private static void initData(){
        TestUtility.createAssumption(24,true);
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
    public static void insertRevenueContract(){
        initData();
        Revenue_Contract__c rc = new Revenue_Contract__c();
        //PCPM-315 
        rc.recordTypeId = Schema.SObjectType.Revenue_Contract__c.getRecordTypeInfosByName().get(CONSTANT.RECURRING_RECORD_TYPE_RC).getRecordTypeId();
        rc.Contract_Start_Date__c = Date.newInstance(2020, 1, 1); 
        rc.Revenue_Account__c = revenueAccountList[0].Id;       
        rc.Live_Renewed_Date__c = Date.newInstance(2020, 1, 4);//PCPM-315 
        rc.Contract_Start_Date__c = Date.newInstance(2020, 1, 4);//PCPM-315 
        rc.Contract_End_Date__c = Date.newInstance(2020, 9, 30);//PCPM-315  
        rc.Invoice_Date__c = Date.newInstance(2020, 1, 10);//PCPM-315 
        rc.Payment_Term_After_Days__c = '15';
        rc.Auto_Renew__c = true;
        
        Test.startTest();
        insert rc;
        // Inserting CLI will update the Total Monthly Revenue and trigger the upsertion of PnL Allocation records
        listContractLineItems.add(TestUtility.createContractLineItem('test CLI',rc.Id,10,listProduct[0].Id,true));
		List<Revenue_P_L_Allocation__c> listRevenuePLAllocation = [SELECT ID FROM Revenue_P_L_Allocation__c 
                                                                   WHERE Revenue_Contract__c = :rc.Id];
        List<Revenue_Cash_Allocation__c > listRevenueCashAllocation = [SELECT ID FROM Revenue_Cash_Allocation__c  
                                                                   WHERE Revenue_Contract__c = :rc.Id];
        
        // Extending the Revenue Contract end date to test increase in PNL records
        rc.Contract_End_Date__c = Date.newInstance(2020, 12, 31);
        update rc; 
        listContractLineItems[0].Quantity__c = 20;
        update listContractLineItems;
        //#133
        listContractLineItems[0].Start_Date__c  = Date.newInstance(2020, 2, 1);
        listContractLineItems[0].End_Date__c  = Date.newInstance(2020, 4, 31);
        update listContractLineItems;
        Test.stopTest();
        
        List<Revenue_P_L_Allocation__c> listRevenuePLAllocationUpdated = [SELECT ID FROM Revenue_P_L_Allocation__c 
                                                                   WHERE Revenue_Contract__c = :rc.Id];
        System.assert(listRevenuePLAllocation.size() > 0);
        System.assert(listRevenueCashAllocation.size() > 0);
        System.AssertEquals(listRevenuePLAllocation.size(), 22); //PCPM-315 | 411
        System.debug('SOW record type'+rc.RecordTypeId);
        
		//Deleting the Revenue Contract
		delete rc;
        //Not required.Written to cover RevenueAccountTrigger
        revenueAccountList[0].Billing_Cycle__c = '6';
        update revenueAccountList;
        delete revenueAccountList;
        
    }
    //#33
    @isTest
    public static void insertSOW(){
        initData();
        revenueAccountList[0].recordTypeId = Schema.SObjectType.Revenue_Account__c.getRecordTypeInfosByName().get(CONSTANT.REVENUE_RECORD_TYPE_TnM).getRecordTypeId();
		update revenueAccountList;
        Revenue_Contract__c rc = new Revenue_Contract__c();
        rc.recordTypeId = Schema.SObjectType.Revenue_Contract__c.getRecordTypeInfosByName().get(CONSTANT.REVENUE_CONTRACT_RECORD_TYPE_SOW).getRecordTypeId();
        rc.Revenue_Account__c = revenueAccountList[0].Id;
        rc.Live_Renewed_Date__c = Date.newInstance(2020, 1, 1);
        rc.Contract_Start_Date__c = Date.newInstance(2020, 1, 1);
        rc.Contract_End_Date__c = Date.newInstance(2020, 9, 30); 
        rc.Invoice_Date__c = Date.newInstance(2020, 1, 1);
        rc.Payment_Term_After_Days__c = '15';
        rc.Total_Amount__c=1000.0;
        
        Test.startTest();
        insert rc;
        Test.stopTest();
        SOW_Line_Item__c sowli=TestUtility.createSOWLineItem(rc.Id,'March','2020',100,true);
        TestUtility.createSOWLineItem(rc.Id,'April','2020',100,true);
        
        List<Revenue_P_L_Allocation__c> listRevenuePLAllocation = [SELECT ID FROM Revenue_P_L_Allocation__c 
                                                                   WHERE Revenue_Contract__c = :rc.Id];
        System.assertEquals(2, listRevenuePLAllocation.size());
    }

}

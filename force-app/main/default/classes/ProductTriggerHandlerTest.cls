/*
Class Name   : ProductTriggerHandlerTest
Description  : This class will cover funactionality related to Product__c object.
Date         : 1 Sept 2019

Change 1 :   
*/
@isTest
public class ProductTriggerHandlerTest {
    static Product__c prdt1;
    static Product__c prdt2;
    
    //@Description - Test delete functionality of ProductTriggerHandler
    @isTest
    public static void testProductTriggerHandler(){
        createTestData();
        Test.startTest();
            try{
               delete prdt1;
            }catch(Exception ex){
                System.debug('Exception-Product Already in Use : '+ ex.getMessage());
            }
            prdt2.Unit_Price__c =1500;
            update prdt2;
            delete prdt2;
            List<Product__c> prdtList = [SELECT Id FROM Product__c];
            System.assertEquals(1, prdtList.size());
        Test.stopTest(); 
    }
    
    //@Description - Test Data Creation
    public static void createTestData(){
        Account testAccount = TestUtility.createAccount('Google',true);
        GL_Code__c testGLCode = TestUtility.createGLCode('Advertising',1111,TestUtility.createPlCategory('Other Revenue','Revenue',true).Id,true);
        Payment_Account__c testPaymentAccount = TestUtility.createPaymentAccount('HDFC',true);
        Revenue_Account__c testRevenueAccount = TestUtility.createRevenueAccount(testAccount.Id, testGLCode.Id, testPaymentAccount.Id,'1',false);
        insert testRevenueAccount;
        Revenue_Contract__c testRevenueContract = TestUtility.createRevenueContract(testRevenueAccount.Id, Date.newInstance(2020, 1, 1), Date.newInstance(2020, 1, 10),'15',Date.newInstance(2020, 9, 30),false);
        testRevenueContract.Live_Renewed_Date__c = Date.newInstance(2020, 1, 4);
        testRevenueContract.RecordTypeId = Schema.SObjectType.Revenue_Contract__c.getRecordTypeInfosByName().get(CONSTANT.RECURRING_RECORD_TYPE_RC).getRecordTypeId();
        insert testRevenueContract;
        
        prdt1 = TestUtility.createProduct('Laptop','Product', 120000,'License', true);
        prdt2 = TestUtility.createProduct('Mouse','Add On', 2000,'License', true);
        Contract_Line_Items__c cli = TestUtility.createContractLineItem('Test CLI' ,testRevenueContract.Id,1,prdt1.Id, true); 
        
        //assert
        System.assertEquals(1, [Select Id from Contract_Line_Items__c where Revenue_Contract_Details__c  =: testRevenueContract.Id].size());
    }
}
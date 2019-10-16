@isTest
public class CashForecastPAFilterControllerTest {
    static void createTestData(){
        Payment_Account__c pa = TestUtility.createPaymentAccount('testPaymentAccount', false);
        pa.isActive__c = true;
        pa.Balance__c = 0.0;
        insert pa;
    }
    static testMethod void testPaymentAccount(){
        createTestData();
        System.assert(CashForecastPAFilterController.getPaymentAccounts().size() > 0 , 'Payment Account Fetched');
    }
}
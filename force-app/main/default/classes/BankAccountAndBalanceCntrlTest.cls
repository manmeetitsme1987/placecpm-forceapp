@isTest
public class BankAccountAndBalanceCntrlTest {
    static void createTestData(){
        Payment_Account__c pa = TestUtility.createPaymentAccount('testPaymentAccount', false);
        pa.Balance__c = 0.0;
        insert pa;
    }
    static testMethod void testPaymentAccount(){
        createTestData();
        System.assert(BankAccountAndBalanceCntrl.fetchAccountAndBalance().size() > 0 , 'Payment Account Fetched');
        BankAccountAndBalanceCntrl.savePaymentAccount(JSON.serialize(BankAccountAndBalanceCntrl.fetchAccountAndBalance()));
    }
}
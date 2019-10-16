public with sharing class CashForecastPAFilterController {
	@AuraEnabled
    public static List<Payment_Account__c> getPaymentAccounts(){
        return [SELECT id,Name FROM Payment_Account__c WHERE isActive__c = true];
    }
}
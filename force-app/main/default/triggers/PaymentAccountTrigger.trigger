trigger PaymentAccountTrigger on Payment_Account__c (after insert, after update, before update, before insert, before delete , after delete) {
	TriggerDispatcher.Run(new PaymentAccountTriggerHandler());
	
}
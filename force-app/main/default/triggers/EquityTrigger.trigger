trigger EquityTrigger on Equity__c (after insert, after update, before delete) {
	TriggerDispatcher.Run(new EquityTriggerHandler());
}
trigger LocationTrigger on Location__c (after update) {
	TriggerDispatcher.Run(new LocationTriggerHandler());
}
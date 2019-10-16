trigger RevenueCashAllocationTrigger on Revenue_Cash_Allocation__c (after insert , after update , before delete) {
	TriggerDispatcher.Run(new RevenueCashAllocationTriggerHandler()); 
}
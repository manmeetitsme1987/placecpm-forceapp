trigger AssumptionTrigger on Assumption__c (after insert, after update, before update, before insert, before delete) {
    TriggerDispatcher.Run(new AssumptionTriggerHandler()); 
}
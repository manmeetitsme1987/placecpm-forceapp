trigger CompensationTrigger on Compensation__c (before insert, before update, after insert, after update, after delete, before delete) {
    TriggerDispatcher.Run(new CompensationTriggerHandler()); 
}
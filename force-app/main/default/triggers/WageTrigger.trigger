trigger WageTrigger on Wages__c (after insert, after update, before update, before insert , before delete , after delete) {
    TriggerDispatcher.Run(new WageTriggerHandler()); 
}
trigger QuotaTrigger on Quota__c (after insert, after update, before update, before insert, before delete) {
    TriggerDispatcher.Run(new QuotaTriggerHandler()); 
}
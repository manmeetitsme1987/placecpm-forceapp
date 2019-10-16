trigger QuotaScheduleTrigger on Quota_Schedule__c (after insert, after update, before update, before insert, before delete , after delete) {
    TriggerDispatcher.Run(new QuotaScheduleTriggerHandler()); 
}
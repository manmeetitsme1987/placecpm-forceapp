trigger RevenueAccountTrigger on Revenue_Account__c (before insert, before update, after insert, after update, before delete, after delete) { //PCPM-316 | added before update parameter
    TriggerDispatcher.Run(new RevenueAccountTriggerHandler()); 
}
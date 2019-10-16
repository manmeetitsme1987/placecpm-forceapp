trigger PLCategoryTrigger on P_L_Category__c (after insert, after update, before update, before insert, before delete , after delete) {
    TriggerDispatcher.Run(new PLCategoryTriggerHandler()); 
}
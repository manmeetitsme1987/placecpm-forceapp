trigger RevenuePLAllocationTrigger on Revenue_P_L_Allocation__c (after insert , after update , after delete , before delete) {
    TriggerDispatcher.Run(new RevenuePLAllocationTriggerHandler()); 
}
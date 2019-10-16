trigger ExpensePLAllocationTrigger on Expense_PL_Allocation__c (after insert , after update , after delete , before delete) {
    TriggerDispatcher.Run(new ExpensePLAllocationTriggerHandler()); 
}
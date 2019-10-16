trigger ExpenseAllocationTrigger on Expense_Allocation__c (before insert, before update, after insert, after update) {
	TriggerDispatcher.Run(new ExpenseAllocationTriggerHandler()); 
}
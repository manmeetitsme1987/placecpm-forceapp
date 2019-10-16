trigger ExpenseCashAllocationTrigger on Expense_Cash_Allocation__c (before insert, before update, before delete, after insert, after update, after delete) {
	TriggerDispatcher.Run(new ExpenseCashAllocationTriggerHandler());
}
trigger ExpenseDetailTrigger on Expense_Detail__c (before insert, before update, after insert, after update, before Delete, after delete) {
    TriggerDispatcher.Run(new ExpenseDetailTriggerHandler()); 
}
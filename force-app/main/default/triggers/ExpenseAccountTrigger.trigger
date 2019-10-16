trigger ExpenseAccountTrigger on Expense_Account__c (before insert, before update, before delete,  after insert, after update, after delete) {
    TriggerDispatcher.Run(new ExpenseAccountTriggerHandler()); 
}
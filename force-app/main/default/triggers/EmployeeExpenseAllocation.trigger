trigger EmployeeExpenseAllocation on Employee_Expense_Allocation__c (before insert, before update, after insert, after update, before delete) {//555
    TriggerDispatcher.Run(new EmployeeExpenseAllocationTriggerHandler()); 
}
trigger EmployeeTrigger on Employee__c (before insert, before update, before delete,after insert, after update, after delete) {
    TriggerDispatcher.Run(new EmployeeTriggerHandler()); 
}
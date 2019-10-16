trigger RevenueContractTrigger on Revenue_Contract__c (before insert, after insert,before update, after update,before delete,after delete) {
    TriggerDispatcher.Run(new RevenueContractTriggerHandler()); 
}
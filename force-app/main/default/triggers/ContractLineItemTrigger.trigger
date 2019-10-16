trigger ContractLineItemTrigger on Contract_Line_Items__c (after insert, after update, before update, before insert) {
        TriggerDispatcher.Run(new ContractLineItemTriggerHandler()); 
}
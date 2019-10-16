trigger SOWLineItemTrigger on SOW_Line_Item__c (after insert, after update, before update, before insert) {
        TriggerDispatcher.Run(new SOWLineItemTriggerHandler()); 
}
trigger GLAccountTrigger on GL_Code__c (after insert, after update, before update, before insert, before delete , after delete) {
    TriggerDispatcher.Run(new GLAccountTriggerHandler()); 
}
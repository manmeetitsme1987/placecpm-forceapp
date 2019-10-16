//
//
// Apex Class Name: placeCRE_CommonTriggerHandler
// Description: The interface dictates which methods every trigger handler must implement,
//              even if these methods have no code in them. By implementing the methods in this class,
//              the placeCRE_TriggerDispatcher can be confident that the trigger handler has a method for each of these events:
//   Before/After Insert
//   Before/After Update
//   Before/After Delete
//   After Undelete
//   IsDisabled
//

public interface CommonTriggerHandler 
{
    void BeforeInsert(List<SObject> newItems);
 
    void BeforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems);
 
    void BeforeDelete(Map<Id, SObject> oldItems);
 
    void AfterInsert(Map<Id, SObject> newItems);
 
    void AfterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems);
 
    void AfterDelete(Map<Id, SObject> oldItems);
 
    void AfterUndelete(Map<Id, SObject> oldItems);
 
    Boolean IsDisabled();

}
/*
Description : This class will be as helper class for RevenuePLAllocationTrigger
Date Created : 21st June 2019
*/
public class RevenuePLAllocationTriggerHandler implements CommonTriggerHandler{
    public void BeforeInsert(List<SObject> newItems){
        
    }
    
    public void BeforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems){
        
    }
    
    public void BeforeDelete(Map<Id, SObject> oldItems){
        CreatePLStatements.createCategoryStatements(null , oldItems);
    }
    
    public void AfterInsert(Map<Id, SObject> newItems){
        CreatePLStatements.createCategoryStatements(newItems.values() , null);
    }
    
    public void AfterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems){
        CreatePLStatements.createCategoryStatements(newItems.values() , oldItems);
    }
    
    public void AfterDelete(Map<Id, SObject> oldItems){
        
    }
    
    public void AfterUndelete(Map<Id, SObject> oldItems){
      
    }
    
    public Boolean IsDisabled(){
        return false;
    }
}
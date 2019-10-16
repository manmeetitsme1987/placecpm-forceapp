/*
Description : This class will be as helper class for ExpenseCashAllocationTrigger
Date Created : 4th July 2019
*/
public class ExpenseCashAllocationTriggerHandler implements CommonTriggerHandler{
    public static boolean dontRunTrigger = false;
    public void BeforeInsert(List<SObject> newItems){
        
    }
    
    public void BeforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems){
        
    }
    
    public void BeforeDelete(Map<Id, SObject> oldItems){
        CreateCashStatements.createCategoryStatements(null, oldItems);
    }
    
    public void AfterInsert(Map<Id, SObject> newItems){
        CreateCashStatements.createCategoryStatements(newItems.values(), null);
    }
    
    public void AfterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems){
        CreateCashStatements.createCategoryStatements(newItems.values(), oldItems);
    }
    
    public void AfterDelete(Map<Id, SObject> oldItems){
    }
    
    public void AfterUndelete(Map<Id, SObject> oldItems){
        
    }
    
    public Boolean IsDisabled(){
        return false;
    }
    
    
}
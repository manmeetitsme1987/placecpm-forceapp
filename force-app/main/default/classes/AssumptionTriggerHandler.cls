public class AssumptionTriggerHandler implements CommonTriggerHandler{
    public void BeforeInsert(List<SObject> newItems){
        
    }
    
    public void BeforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems){
        
    }
    
    public void BeforeDelete(Map<Id, SObject> oldItems){
        
    }
    
    public void AfterInsert(Map<Id, SObject> newItems){
        
    }
    
    public void AfterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems){
      
    }
    
    public void AfterDelete(Map<Id, SObject> oldItems){
       
    }
    
    public void AfterUndelete(Map<Id, SObject> oldItems){
      
    }
    
    public Boolean IsDisabled(){
        return false;
    }
    
    public void checkDuplicateRecordForAssumption(List<Assumption__c> assumptions){
        list<Assumption__c> existingAssumptions	= [Select Id, Name From Assumption__c];
        For(Assumption__c assumption : assumptions){
            if(assumptions != null && assumptions.size()>0){
                assumption.addError(System.Label.Assumption_OneRecordAllowed); //PCPM-520
            }  
        }
    }
    
    public void checkAtleastOneRecordForAssumption(List<Assumption__c> assumptions){
        list<Assumption__c> existingAssumptions = [Select Id, Name From Assumption__c];
        For(Assumption__c assumption : assumptions){
            if(existingAssumptions != null && existingAssumptions.size()==1){
                assumption.addError(Label.Assumption_AtleastOneRecordShouldExist); //PCPM-520
            }  
        }
    }
}
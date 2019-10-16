/*
 * Handler Class for LocationTrigger
 * createdOn 8August 2019
 */
public with sharing class LocationTriggerHandler implements CommonTriggerHandler{
	public static boolean dontRunTrigger = false;
    public void BeforeInsert(List<SObject> newItems){
        
    }
    
    public void BeforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems){
        
    }
    
    public void BeforeDelete(Map<Id, SObject> oldItems){

    }
    
    public void AfterInsert(Map<Id, SObject> newItems){
        
    }
    
    public void AfterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems){
        updateTaxPLs((List<Location__c>)newItems.values(),(Map<Id,Location__c>)oldItems);
    }
    
    public void AfterDelete(Map<Id, SObject> oldItems){
        
    }
    
    public void AfterUndelete(Map<Id, SObject> oldItems){
        
    }
    
    public Boolean IsDisabled(){
        return false;
    }
    
    public static void updateTaxPLs(List<Location__c> newItems, Map<Id,Location__c> oldItems){
        Set<String> locationIdSet = new Set<String>();
        Map<String,Decimal> locationIdSetForTaxChange = new Map<String,Decimal>();
        for(Location__c loc: newItems){
            if(loc.tax__c != null && (loc.Tax__c != oldItems.get(loc.Id).Tax__C || loc.GL_Code__c != oldItems.get(loc.Id).GL_Code__c	)){
                locationIdSet.add(loc.Id);
                if(loc.Tax__c != oldItems.get(loc.Id).Tax__C){
                    locationIdSetForTaxChange.put(loc.id,loc.Tax__c);
                }
            }
        }
        
        if(locationIdSetForTaxChange.size()>0){
            List<Wages__c> wagesToUpdate = new List<Wages__c>();
            Boolean isEmployeeTax = false;
            if(Schema.sObjectType.Wages__c.fields.Employer_Tax__c.isUpdateable()){
                isEmployeeTax = true;
            }
            
            if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.WAGES_OBJECT,'Id,P_L_Date__c,Cash_Date__c,Employee_Number__c, Employer_Tax_Amount__c,Compensation__c',Constant.ACTION_TYPE_ACCESS) &&
			   PlaceCPM_Utility.checkAccessiblityOfFields(Constant.COMPENSATION_OBJECT,'Employee__c',Constant.ACTION_TYPE_ACCESS) && 
               PlaceCPM_Utility.checkAccessiblityOfFields(Constant.EMPLOYEE_OBJECT,'location__c',Constant.ACTION_TYPE_ACCESS)){
                for(Wages__c wage : [SELECT Id,P_L_Date__c,Cash_Date__c,Employee_Number__c, Employer_Tax_Amount__c,Compensation__r.Employee__r.location__c   FROM wages__c WHERE Employee_Number__c IN (SELECT Id FROM employee__c WHERE location__c IN :locationIdSetForTaxChange.keySet()) AND Cash_Date__c >= TODAY]){
                    if(isEmployeeTax){
                        wage.Employer_Tax__c = locationIdSetForTaxChange.get(wage.Compensation__r.Employee__r.location__c);
                    }
                    wagesToUpdate.add(wage);
                }
        	}
            try{
                PlaceCPM_Utility.updateRecords(wagesToUpdate, CONSTANT.WAGES_OBJECT, false); //520
            }
            catch(Exception ex){
                PlaceCPM_Utility.debugLog(ex.getMessage() + ' at line number ' + ex.getLineNumber());
            }
            
        }
        if(locationIdSet.size()>0){
            
            List<Wages__c> wageList;
            if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.WAGES_OBJECT,'Id,P_L_Date__c,Cash_Date__c,Employee_Number__c, Employer_Tax_Amount__c',Constant.ACTION_TYPE_ACCESS)){
            	wageList = [SELECT Id,P_L_Date__c,Cash_Date__c,Employee_Number__c, Employer_Tax_Amount__c   FROM wages__c WHERE Employee_Number__c IN (SELECT Id FROM employee__c WHERE location__c IN :locationIdSet) AND Cash_Date__c >= TODAY];
        	}
            Set<Id> wageIdSet = new Set<Id>();
            for(Wages__c wage : wageList){
                wageIdSet.add(wage.Id);
            }
            WageTriggerHandler.deletePLAndCash(wageIdSet, true);
            WageTriggerHandler.createPL(wageList,true);
        }
    }
}
/*
Description : This class will be as helper for PAndL PLCategoryTrigger.
Date Created : 21th June 2019
*/
public with sharing class PLCategoryTriggerHandler implements CommonTriggerHandler{
    public void BeforeInsert(List<SObject> newItems){
        
    }
    
    public void BeforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems){
        
    }
    
    public void BeforeDelete(Map<Id, SObject> oldItems){
        deleteAllRelatedRecods((Map<Id, P_L_Category__c>)oldItems);
    }
    
    public void AfterInsert(Map<Id, SObject> newItems){
    }
    
    public void AfterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems){
        updatePLRecords((Map<Id, P_L_Category__c>)newItems , (Map<Id, P_L_Category__c>)oldItems);
    }
    
    public void AfterDelete(Map<Id, SObject> oldItems){
        
    }
    
    public void AfterUndelete(Map<Id, SObject> oldItems){
      
    }
    
    public Boolean IsDisabled(){
        return false;
    }

    //  Method to cover delete scenerio and deletes all related pl record and employee profile record.
    //  @param oldGLMap of P_L_Category__c
    //  @return void
    void deleteAllRelatedRecods(Map<Id , P_L_Category__c> oldGLMap){
        List<P_L_Statement__c> relatedPLStatements = new List<P_L_Statement__c>();
        Map<Id , GL_Code__c> glCodes = new Map<Id , GL_Code__c>();
        For(P_L_Statement__c pls : [SELECT id FROM P_L_Statement__c WHERE P_L_Category__c IN : oldGLMap.keySet()]){
            relatedPLStatements.add(pls);
        }
        if(relatedPLStatements.size() > 0){
            try{
                PlaceCPM_Utility.deleteRecords(relatedPLStatements, CONSTANT.P_L_STATEMENT_OBJECT, false);//520
            }
            catch(Exception ex){
                PlaceCPM_Utility.debugLog('Exception : == ' + ex.getMessage() + ' at line number ' + ex.getLineNumber());
            }
        }
        //PCPM-235
        /*
        For(GL_Code__c glc : [SELECT id , Name , Sequence__c FROM GL_Code__c WHERE PL_Category__c IN : oldGLMap.keySet()]){
            glCodes.add(glc);
        }
        For(Employee_Role_Profile__c empr : [SELECT id FROM Employee_Role_Profile__c WHERE GL_Account__c IN : glCodes]){
            employeeRoleProfiles.add(empr);
        }
        if(employeeRoleProfiles.size() > 0){
            try{
                PlaceCPM_Utility.deleteRecords(employeeRoleProfiles, 'Employee_Role_Profile__c', false);
            }
            catch(Exception ex){
                PlaceCPM_Utility.debugLog('Exception : == ' + ex.getMessage() + ' at line number ' + ex.getLineNumber());
            }
        }*/
    }
    
    //  Method to covers  sequence update scenerio and updates all related pls records sequence
    //  @param newPlcMap and oldPlcMap of P_L_Category__c
    //  @return void
    void updatePLRecords(Map<Id, P_L_Category__c> newPlcMap, Map<Id, P_L_Category__c> oldPlcMap){
        List<P_L_Statement__c> plsStatementListToUpdate = new List<P_L_Statement__c>();
        List<P_L_Category__c> plCategoryToHandle = new List<P_L_Category__c>();
        Map<String , Decimal> glCodeMap = new Map<String , Decimal>();
        P_L_Category__c oldplc;
        P_L_Category__c newplc;
        
        Boolean isSequence = false;
        if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.PL_STATEMENT_OBJECT,'Sequence__c',Constant.ACTION_TYPE_UPDATE)){
        	isSequence = true;
        }
        
        For(P_L_Category__c plc : newPlcMap.values()){
            oldplc = oldPlcMap.get(plc.Id);
            if(plc.Sequence__c != oldplc.Sequence__c){
                plCategoryToHandle.add(oldplc);
            }
        }
        
        if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.GL_CODE_OBJECT,'Sequence__c',Constant.ACTION_TYPE_ACCESS)){
            For(GL_Code__c glc : [SELECT id ,Name, Sequence__c FROM GL_Code__c WHERE PL_Category__c IN : plCategoryToHandle]){
                glCodeMap.put(glc.Name , glc.Sequence__c);
            }
    	}
        
        if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.PL_STATEMENT_OBJECT,'Sequence__c , P_L_Category__c',Constant.ACTION_TYPE_ACCESS)){
            For(P_L_Statement__c pls : [SELECT id , Sequence__c , P_L_Category__c , GL_Code__r.name FROM P_L_Statement__c WHERE P_L_Category__c IN : plCategoryToHandle and GL_Code__c != null]){
                newplc = newPlcMap.get(pls.P_L_Category__c);
                if(newplc.Sequence__c != Null && glCodeMap.containskey(pls.GL_Code__r.name) && glCodeMap.get(pls.GL_Code__r.name) != Null
                && isSequence){
                    pls.Sequence__c =  newplc.Sequence__c + glCodeMap.get(pls.GL_Code__r.name)/100;
                    plsStatementListToUpdate.add(pls);
                }
            }
    	}
        if(plsStatementListToUpdate.size() > 0 ){
            try{
                PlaceCPM_Utility.updateRecords(plsStatementListToUpdate, CONSTANT.P_L_STATEMENT_OBJECT, false);//520
                plsStatementListToUpdate.clear();
            }
            catch(Exception ex){
                PlaceCPM_Utility.debugLog('Exception : == ' + ex.getMessage() + ' at line number ' + ex.getLineNumber());
            }
        }
        plsStatementListToUpdate = new List<P_L_Statement__c>(PlaceCPM_Utility.createTotalAndFormulaPlStatement());
        if(plsStatementListToUpdate.size() > 0){
            try{
                PlaceCPM_Utility.insertRecords(plsStatementListToUpdate, CONSTANT.P_L_STATEMENT_OBJECT, false);//520
            }
            catch(Exception ex){
                PlaceCPM_Utility.debugLog('Exception : == ' + ex.getMessage() + ' at line number ' + ex.getLineNumber());
            }
        }
    }
}
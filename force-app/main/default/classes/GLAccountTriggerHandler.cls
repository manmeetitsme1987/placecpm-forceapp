/*
Description : This class will be as used as handler for GLAccountTriggerHandler.
Date Created : 21th June 2019
*/
public with sharing class GLAccountTriggerHandler implements CommonTriggerHandler{
    public void BeforeInsert(List<SObject> newItems){

    }
    
    public void BeforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems){
        
    }
    
    public void BeforeDelete(Map<Id, SObject> oldItems){
        deleteAllRelatedRecods((Map<Id, GL_Code__c>)oldItems);
    }
    
    public void AfterInsert(Map<Id, SObject> newItems){
        CreatePLStatementRecords((List<GL_Code__c>)newItems.values());
    }
    
    public void AfterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems){
        handleGlUpdate((Map<Id, GL_Code__c>)newItems , (Map<Id, GL_Code__c>)oldItems);
    }
    
    public void AfterDelete(Map<Id, SObject> oldItems){
        
    }
    
    public void AfterUndelete(Map<Id, SObject> oldItems){
      
    }
    
    public Boolean IsDisabled(){
        return false;
    }

    //  Method to create pl statement records with 0 values.
    //  @param newGlCodeList new list containing GL_Code__c
    //  @return void
    public void CreatePLStatementRecords(List<GL_Code__c> newGlCodeList){ //667 public
        Integer noOfYears = 0;
        Boolean isGLCode = false, isYear = false, isPLCategory = false, isType = false, isSequence = false;
        Boolean isJan = false, isFeb = false, isMar = false, isApr = false, isMay = false, isJun = false, isJul = false; 
        Boolean isAug = false, isSep = false, isOct = false, isNov = false, isDec = false;
        Boolean isJanActual = false, isFebActual = false, isMarActual = false, isAprActual = false, isMayActual = false, iJunActual = false, isJulActual = false;
        Boolean isAugActual = false, isSepActual = false, isOctActual = false, isNovActual = false, isDecActual = false;
        if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.PL_STATEMENT_OBJECT,'GL_Code__c',Constant.ACTION_TYPE_INSERT)){
            isGLCode = true;
        }
        if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.PL_STATEMENT_OBJECT,'Year__c',Constant.ACTION_TYPE_INSERT)){
            isYear = true;
        }
        if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.PL_STATEMENT_OBJECT,'P_L_Category__c',Constant.ACTION_TYPE_INSERT)){
            isPLCategory = true;
        }
        if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.PL_STATEMENT_OBJECT,'Type__c',Constant.ACTION_TYPE_INSERT)){
            isType = true;
        }
        if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.PL_STATEMENT_OBJECT,'Sequence__c',Constant.ACTION_TYPE_INSERT)){
            isSequence = true;
        }
        if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.PL_STATEMENT_OBJECT,'January__c',Constant.ACTION_TYPE_INSERT)){
            isJan = true;
        }
        if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.PL_STATEMENT_OBJECT,'February__c',Constant.ACTION_TYPE_INSERT)){
            isFeb = true;
        }
        if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.PL_STATEMENT_OBJECT,'March__c',Constant.ACTION_TYPE_INSERT)){
            isMar = true;
        }
        if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.PL_STATEMENT_OBJECT,'April__c',Constant.ACTION_TYPE_INSERT)){
            isApr = true;
        }
        if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.PL_STATEMENT_OBJECT,'May__c',Constant.ACTION_TYPE_INSERT)){
            isMay = true;
        }
        if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.PL_STATEMENT_OBJECT,'June__c',Constant.ACTION_TYPE_INSERT)){
            isJun = true;
        }
        if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.PL_STATEMENT_OBJECT,'July__c',Constant.ACTION_TYPE_INSERT)){
            isJul = true;
        }
        if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.PL_STATEMENT_OBJECT,'August__c',Constant.ACTION_TYPE_INSERT)){
            isAug = true;
        }
        if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.PL_STATEMENT_OBJECT,'September__c',Constant.ACTION_TYPE_INSERT)){
            isSep = true;
        }
        if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.PL_STATEMENT_OBJECT,'October__c',Constant.ACTION_TYPE_INSERT)){
             isOct = true;
        }
        if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.PL_STATEMENT_OBJECT,'November__c',Constant.ACTION_TYPE_INSERT)){
            isNov = true;
        }
        if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.PL_STATEMENT_OBJECT,'December__c',Constant.ACTION_TYPE_INSERT)){
            isDec = true;
        }
        if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.PL_STATEMENT_OBJECT,'January_Actual__c',Constant.ACTION_TYPE_INSERT)){
            isJanActual = true;
        }
        if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.PL_STATEMENT_OBJECT,'February_Actual__c',Constant.ACTION_TYPE_INSERT)){
            isFebActual = true;
        }
        if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.PL_STATEMENT_OBJECT,'March_Actual__c',Constant.ACTION_TYPE_INSERT)){
            isMarActual = true;
        }
        if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.PL_STATEMENT_OBJECT,'April_Actual__c',Constant.ACTION_TYPE_INSERT)){
            isAprActual = true;
        }
        if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.PL_STATEMENT_OBJECT,'May_Actual__c',Constant.ACTION_TYPE_INSERT)){
            isMayActual = true;
        }
        if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.PL_STATEMENT_OBJECT,'June_Actual__c',Constant.ACTION_TYPE_INSERT)){
            iJunActual = true;
        }
        if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.PL_STATEMENT_OBJECT,'July_Actual__c',Constant.ACTION_TYPE_INSERT)){
            isJulActual = true;
        }
        if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.PL_STATEMENT_OBJECT,'August_Acutal__c',Constant.ACTION_TYPE_INSERT)){
            isAugActual = true;
        }
        if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.PL_STATEMENT_OBJECT,'September_Acutal__c',Constant.ACTION_TYPE_INSERT)){
            isSepActual= true;
        }
        if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.PL_STATEMENT_OBJECT,'October_Actual__c',Constant.ACTION_TYPE_INSERT)){
            isOctActual = true;
        }
        if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.PL_STATEMENT_OBJECT,'November_Actual__c',Constant.ACTION_TYPE_INSERT)){
            isNovActual = true;
        }
        if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.PL_STATEMENT_OBJECT,'December_Actual__c',Constant.ACTION_TYPE_INSERT)){
            isDecActual = true;
        }
        if(PlaceCPM_Utility.assumptionForecastDuration > 0){
            Date dateAfterAssumptionDuration = System.today().addMonths(PlaceCPM_Utility.assumptionForecastDuration);
            noOfYears = dateAfterAssumptionDuration.year();
        }
        List<P_L_Statement__c> plStatement = new List<P_L_Statement__c>();
        if(noOfYears > 0){
            P_L_Statement__c pls;
            List<Payment_Account__c> paymentAccountList = new List<Payment_Account__c>();
            //667
            if(PlaceCPM_Utility.checkAccessiblityOfFields('Payment_Account__c','Name',CONSTANT.ACTION_TYPE_ACCESS) &&
               PlaceCPM_Utility.checkAccessiblityOfFields('Payment_Account__c','isActive__c',CONSTANT.ACTION_TYPE_ACCESS) ){
                   for(Payment_Account__c paymentAcc : [SELECT id , Name, isActive__c  FROM Payment_Account__c WHERE isActive__c = true]){
                       paymentAccountList.add(paymentAcc);
                   } 
               }
            Boolean hasAccessToFields = PlaceCPM_Utility.checkAccessiblityOfFields('P_L_Statement__c','GL_Code__c,Year__c,P_L_Category__c,Type__c,Sequence__c,January__c,February__c,'+
                                                                                   'March__c,April__c,May__c,June__c,July__c,August__c,September__c,October__c,November__c,December__c,'+
                                                                                   'January_Actual__c,February_Actual__c,March_Actual__c,April_Actual__c,May_Actual__c,June_Actual__c,July_Actual__c,'+
                                                                                   'August_Acutal__c,September_Acutal__c,October_Actual__c,November_Actual__c,December_Actual__c',CONSTANT.ACTION_TYPE_INSERT);
            if(hasAccessToFields){
                For(GL_Code__c glcode : newGlCodeList){
                    For(Integer i= System.today().year() - 1 ; i<=noOfYears ; i++){
                        pls = createPLStatement(glcode, i);
                        plStatement.add(pls);
                        if(paymentAccountList.size() > 0){
                            for(Payment_Account__c payAcc : paymentAccountList){
                                pls = createPLStatement(glcode, i);
                                if(PlaceCPM_Utility.checkAccessiblityOfFields('P_L_Statement__c','Statement_Type__c',CONSTANT.ACTION_TYPE_INSERT)){
                                    pls.Statement_Type__c  = CONSTANT.EXPCASHTYPE;
                                }
                                
                                if(PlaceCPM_Utility.checkAccessiblityOfFields('P_L_Statement__c','Parent_Bank_Account__c',CONSTANT.ACTION_TYPE_INSERT)){
                                    pls.Parent_Bank_Account__c = payAcc.Id;
                                }
                                plStatement.add(pls);
                            }
                        }
                    } //end of for 2
                } //end of for 1
            }
        } //end of if
        PlaceCPM_Utility.insertRecords(plStatement, CONSTANT.P_L_STATEMENT_OBJECT, false); //520 
        List<P_L_Statement__c> plslist = new List<P_L_Statement__c>(PlaceCPM_Utility.createTotalAndFormulaPlStatement());
        PlaceCPM_Utility.insertRecords(plslist,  CONSTANT.P_L_STATEMENT_OBJECT, false); //520 
    }
    
    //667
    //  Method to create related pl statement for all the payment accounts related to GL
    //  @param1 glcode - GL_Code__c of PLS
    //  @param2 yearVal PLS year 
    //  @param3 plsStatementType - type of pls statement - PL/Cash
    //  @return P_L_Statement__c
    private static P_L_Statement__c createPLStatement(GL_Code__c glcode, Integer yearVal){
        P_L_Statement__c pls = new P_L_Statement__c();
        
        pls.GL_Code__c = glcode.Id;
        pls.Year__c = String.valueOf(yearVal);
        pls.P_L_Category__c = glcode.PL_Category__c;
        pls.Type__c = CONSTANT.PL_STATEMENT_TYPE_CATEGORY;
        if(glcode.P_L_Category_Sequence__c != null){
            if(glcode.Sequence__c == null){
                pls.Sequence__c =  glcode.P_L_Category_Sequence__c ;
            }
            else{
                pls.Sequence__c =  glcode.P_L_Category_Sequence__c + glcode.Sequence__c/100;
            }
            
        }
        pls.January__c = 0.0;
        pls.February__c = 0.0;
        pls.March__c = 0.0;
        pls.April__c = 0.0;
        pls.May__c = 0.0;
        pls.June__c = 0.0;
        pls.July__c = 0.0;
        pls.August__c = 0.0;
        pls.September__c = 0.0;
        pls.October__c = 0.0;
        pls.November__c = 0.0;
        pls.December__c = 0.0;
        pls.January_Actual__c= 0.0;
        pls.February_Actual__c= 0.0;
        pls.March_Actual__c= 0.0;
        pls.April_Actual__c= 0.0;
        pls.May_Actual__c= 0.0;
        pls.June_Actual__c= 0.0;
        pls.July_Actual__c= 0.0;
        pls.August_Acutal__c= 0.0;
        pls.September_Acutal__c= 0.0;
        pls.October_Actual__c= 0.0;
        pls.November_Actual__c= 0.0;
        pls.December_Actual__c = 0.0;
        
        return pls;
    }

    //  Method to delete related pl statement and employee role profiles
    //  @param newGlCodeList new list containing GL_Code__c
    //  @return void
    public static void deleteAllRelatedRecods(Map<Id , GL_Code__c> oldGLMap){
        List<P_L_Statement__c> relatedPLStatements = new List<P_L_Statement__c>();
        For(P_L_Statement__c pls : [SELECT id FROM P_L_Statement__c WHERE GL_Code__c IN : oldGLMap.keySet()]){
            relatedPLStatements.add(pls);
        }
        if(relatedPLStatements.size() > 0){
            try{
                PlaceCPM_Utility.deleteRecords(relatedPLStatements,  CONSTANT.P_L_STATEMENT_OBJECT, false); //520 
            }
            catch(Exception ex){
                PlaceCPM_Utility.debugLog('Exception : == ' + ex.getMessage() + ' at line number ' + ex.getLineNumber());
            }
        }
        
    }

    //  Method to update sequence on all related pl statement
    //  @param new map and old map of GL_Code__c
    //  @return void
    void handleGlUpdate(Map<Id, GL_Code__c> newGlCodeMap, Map<Id, GL_Code__c> oldGLMap){
        List<GL_Code__c> glAccountToHandle = new List<GL_Code__c>();
        List<P_L_Statement__c> plsStatementListToUpdate = new List<P_L_Statement__c>();
        GL_Code__c oldGL;
        GL_Code__c newGL;
        For(GL_Code__c glc : newGlCodeMap.values()){
            oldGL = oldGLMap.get(glc.Id);
            if(glc.Sequence__c != oldGL.Sequence__c || glc.P_L_Category_Sequence__c != oldGL.P_L_Category_Sequence__c || glc.PL_Category__c != oldGL.PL_Category__c){
                glAccountToHandle.add(oldGL);
            }
        }
        if(glAccountToHandle.size() > 0){
            if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.PL_STATEMENT_OBJECT,'GL_Code__c',Constant.ACTION_TYPE_ACCESS)){
                For(P_L_Statement__c pls : [SELECT id  ,GL_Code__c FROM P_L_Statement__c WHERE GL_Code__c IN : glAccountToHandle]){
                    newGL = newGlCodeMap.get(pls.GL_Code__c);
                    if(Schema.sObjectType.P_L_Statement__c.fields.P_L_Category__c.isUpdateable()){
                        pls.P_L_Category__c = newGL.PL_Category__c;
                    }
                    if(newGL.P_L_Category_Sequence__c != Null && newGL.Sequence__c != Null)
                    if(Schema.sObjectType.P_L_Statement__c.fields.Sequence__c.isUpdateable()){
                        pls.Sequence__c =  newGL.P_L_Category_Sequence__c+newGL.Sequence__c/100;
                    }
                    plsStatementListToUpdate.add(pls);
                }
        	} 
        }
        if(plsStatementListToUpdate.size() > 0){
            try{
                PlaceCPM_Utility.updateRecords(plsStatementListToUpdate, CONSTANT.P_L_STATEMENT_OBJECT, false); //520 
                plsStatementListToUpdate.clear();
                plsStatementListToUpdate = new List<P_L_Statement__c>(PlaceCPM_Utility.createTotalAndFormulaPlStatement());
                PlaceCPM_Utility.insertRecords(plsStatementListToUpdate, CONSTANT.P_L_STATEMENT_OBJECT, false); //520 
            }
            catch(Exception ex){
                PlaceCPM_Utility.debugLog('Exception : == ' + ex.getMessage() + ' at line number ' + ex.getLineNumber());
            }
        }
    }
}
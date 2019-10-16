public with sharing class PaymentAccountTriggerHandler implements CommonTriggerHandler{
	public void BeforeInsert(List<SObject> newItems){

    }
    
    public void BeforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems){
        
    }
    
    public void BeforeDelete(Map<Id, SObject> oldItems){
        deletePaymentStatementRecods((Map<Id, Payment_Account__c>) oldItems);
    }
    
    public void AfterInsert(Map<Id, SObject> newItems){
        createBlankStatementRecords((List<Payment_Account__c>)newItems.values());
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
    
    public static void createBlankStatementRecords(List<Payment_Account__c> newItems){
        Integer noOfYears = 0;
        if(PlaceCPM_Utility.assumptionForecastDuration > 0){
            Date dateAfterAssumptionDuration = System.today().addMonths(PlaceCPM_Utility.assumptionForecastDuration);
            noOfYears = dateAfterAssumptionDuration.year();
        }
        P_L_Statement__c pls;
        List<P_L_Statement__c> plStatement = new List<P_L_Statement__c>();
        List<GL_Code__c> glcodeList = new List<GL_Code__c>();
        //Poornima
        if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.GL_CODE_OBJECT,'Id , PL_Category__c , P_L_Category_Sequence__c , Sequence__c',Constant.ACTION_TYPE_ACCESS)){
        	glcodeList = [SELECT id , PL_Category__c , P_L_Category_Sequence__c , Sequence__c FROM GL_Code__c where PL_Category__c != null];
    	}
        
        Boolean isAccessible = false;
        String fieldsToCheck = 'GL_Code__c, Year__c, P_L_Category__c, Type__c, Sequence__c, January__c, February__c,' +
            				   'March__c, April__c, May__c, June__c, July__c, August__c, September__c, October__c,' +
            					'November__c, December__c, January_Actual__c, February_Actual__c, March_Actual__c,' +
            					'April_Actual__c, May_Actual__c, June_Actual__c, July_Actual__c, August_Acutal__c,' +
            					'September_Acutal__c, October_Actual__c, November_Actual__c, December_Actual__c';
        isAccessible = PlaceCPM_Utility.checkAccessiblityOfFields(Constant.PL_STATEMENT_OBJECT,fieldsToCheck,Constant.ACTION_TYPE_INSERT);
        if(isAccessible){
            for(Integer i= System.today().year() - 1 ; i<=noOfYears ; i++){
                for(Payment_Account__c pa : newItems){
                    for(GL_Code__c glc : glcodeList){
                        pls = new P_L_Statement__c();
                        pls.Statement_Type__c = CONSTANT.EXPCASHTYPE;
                        pls.Parent_Bank_Account__c = pa.Id;
                            pls.GL_Code__c = glc.Id;
                            pls.Year__c = String.valueOf(i);
                            pls.P_L_Category__c = glc.PL_Category__c;
                            pls.Type__c = CONSTANT.PL_STATEMENT_TYPE_CATEGORY;
                        if(glc.P_L_Category_Sequence__c != Null && glc.Sequence__c != Null){
                                pls.Sequence__c =  glc.P_L_Category_Sequence__c + glc.Sequence__c/100;
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
                        plStatement.add(pls);
                    }
                }
            }
        }
        PlaceCPM_Utility.insertRecords(plStatement, CONSTANT.PL_STATEMENT_OBJECT , false);
    }
    
    public void deletePaymentStatementRecods(Map<Id, Payment_Account__c> oldItems){
        List<P_L_Statement__c> plsListToDelete = new List<P_L_Statement__c>();
        for(P_L_Statement__c pls : [SELECT ID FROM P_L_Statement__c WHERE Statement_Type__c =: CONSTANT.EXPCASHTYPE AND Parent_Bank_Account__c IN : oldItems.keySet()]){
            plsListToDelete.add(pls);
        }
        PlaceCPM_Utility.deleteRecords(plsListToDelete, CONSTANT.PL_STATEMENT_OBJECT, false);
    }
}
/*
Description : This class will be as Handler for ExpensePLAllocationTrigger
Date Created : 17th June 2019
*/
public with sharing class ExpensePLAllocationTriggerHandler implements CommonTriggerHandler{
    public static boolean dontRunTrigger = false;
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
        updateCashAllocationData((Map<Id, Expense_PL_Allocation__c>)newItems , (Map<Id, Expense_PL_Allocation__c>)oldItems);
    }
    
    public void AfterDelete(Map<Id, SObject> oldItems){
    }
    
    public void AfterUndelete(Map<Id, SObject> oldItems){
    }
    
    public Boolean IsDisabled(){
        return false;
    }

    //  Method to update cash allocation related to pl allocation record.
    //  @param newItems new map containing Expense_PL_Allocation__c, oldItems items before changes containing Expense_PL_Allocation__c
    //  @return void
    public void updateCashAllocationData(Map<Id, Expense_PL_Allocation__c> newItems, Map<Id, Expense_PL_Allocation__c> oldItems) {
        Set<String> expenseAccountId = new Set<String>();
        Set<String> expenseDetailId = new Set<String>();
        Map<String, Expense_Cash_Allocation__c> expenseCashMap = new Map<String, Expense_Cash_Allocation__c>();
        for(Expense_PL_Allocation__c expensePL : newItems.values()) {
            expenseAccountId.add(expensePL.Expense_Account__c);
            expenseDetailId.add(expensePL.Expense_Detail__c);
        }
        
        if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.EXPENSE_DETAIL_OBJECT,'Id, Expense_Account__c,Monthly_Expense_Amount__c, Payment_Frequency__c,Invoice_Date__c,Auto_Renew__c,Payment_Term_After_Days__c,Start_Date__c',Constant.ACTION_TYPE_ACCESS) && 
           PlaceCPM_Utility.checkAccessiblityOfFields(Constant.EXPENSE_CASG_ALLOCATION_OBJECT,'Id, Cash_Forecast__c,Cash_Date__c, Forecast_Amount__c',Constant.ACTION_TYPE_ACCESS) && 
           PlaceCPM_Utility.checkAccessiblityOfFields(Constant.EXPENSE_PL_ALLOCATION_OBJECT,'Id, PlMonthStartDate__c,Forecast_Amount__c, Actual_Amount__c',Constant.ACTION_TYPE_ACCESS)){
        for(Expense_Detail__c ed : [Select Id, Expense_Account__c, 
                                    Monthly_Expense_Amount__c, Payment_Frequency__c,
                                    Invoice_Date__c,Auto_Renew__c,
                                    Payment_Term_After_Days__c,Start_Date__c ,
                                    (Select Id, Cash_Forecast__c, 
                                     Cash_Date__c, Forecast_Amount__c,
                                     Cash_Forecast__r.Name
                                     From Expense_Cash_Allocations__r),
                                    (Select Id, PlMonthStartDate__c,Forecast_Amount__c, Actual_Amount__c
                                     From Expense_P_L_Allocations__r Order by PlMonthStartDate__c)
                                    From Expense_Detail__c
                                    Where Id in : expenseDetailId]) {
                                        //expenseCashMap = new Map<String, Expense_Cash_Allocation__c>(); //562
                                        Integer expenseMonths = ed.Expense_P_L_Allocations__r.size();
                                        for(Expense_Cash_Allocation__c cash : ed.Expense_Cash_Allocations__r){
                                            expenseCashMap.put(String.valueOf(cash.Cash_Date__c), cash);
                                        }
                                        if(ed.Start_Date__c != null && expenseMonths > 0 && ed.Payment_Frequency__c != null){
                                            if(ed.Payment_Term_After_Days__c != null){
                                                Integer totalCashAllocationRecords = Integer.valueOf(expenseMonths)/Integer.valueOf(ed.Payment_Frequency__c);
                                                Integer lastyearMonths = math.mod(Integer.valueOf(expenseMonths), Integer.valueOf(ed.Payment_Frequency__c));
                                                if(lastyearMonths!=0){
                                                    totalCashAllocationRecords=totalCashAllocationRecords+1;
                                                }
                                                Date cashDate = ed.Invoice_Date__c .addDays(ed.Payment_Term_After_Days__c !=null ? Integer.valueOf(ed.Payment_Term_After_Days__c): 0);
                                                Date futureDate;
												Date plDate = ed.Expense_P_L_Allocations__r[0].PlMonthStartDate__c;
                                                Date endDate = plDate.addMonths(Integer.valueOf(ed.Payment_Frequency__c));
                                                for(Integer i=0; i<totalCashAllocationRecords; i++){
                                                    futureDate = cashDate.addMonths((i*Integer.valueOf(ed.Payment_Frequency__c)));
                                                    if(expenseCashMap.containsKey(String.valueOf(futureDate))) {
                                                        Expense_Cash_Allocation__c eca = expenseCashMap.get(String.valueOf(futureDate));
                                                        eca.Forecast_Amount__c = 0;
                                                        eca.Actual_Amount__c = 0;
                                                        for(Expense_PL_Allocation__c expensePL : ed.Expense_P_L_Allocations__r) { 
                                                            if(expensePL.PlMonthStartDate__c >= plDate && expensePL.PlMonthStartDate__c < endDate) {
                                                                eca.Forecast_Amount__c += expensePL.Forecast_Amount__c;
                                                                if(expensePL.Actual_Amount__c != null){
                                                                    eca.Actual_Amount__c += expensePL.Actual_Amount__c;
                                                                }
                                                                plDate = expensePL.PlMonthStartDate__c.addDays(1);
                                                            }
                                                        }
                                                        endDate = plDate.addMonths(Integer.valueOf(ed.Payment_Frequency__c));
                                                        expenseCashMap.put(String.valueOf(eca.Cash_Date__c), eca);
                                                    }
                                                }
                                            }
                                        }
                                    }
    	}
        PlaceCPM_Utility.updateRecords(expenseCashMap.values(), CONSTANT.EXPENSE_CASG_ALLOCATION_OBJECT, false); //520                                    
    }
}
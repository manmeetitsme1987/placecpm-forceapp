/*
 * Description  : This class updates number of employees and Expense Allocation Amount on P&L Allocation
                  and updates Cash allocation amount on Expense Cash Allocation
 * Date Created : 7th May 2019
*/
public with sharing class EmployeeExpenseAllocationTriggerHandler implements CommonTriggerHandler{
        
    public void BeforeInsert(List<SObject> newItems){
    
    }
    
    public void BeforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems){
    }
    
    public void BeforeDelete(Map<Id, SObject> oldItems){
        handleBeforeDelete((Map<Id,Employee_Expense_Allocation__c>) oldItems);
    }
    
    public void AfterInsert(Map<Id, SObject> newItems){
        updatePLandCashAllocation((List<Employee_Expense_Allocation__c>)newItems.values(), CONSTANT.EMPLOYEE_EXPENSE_ALLOCATION_INSERT, null);
    }
    
    public void AfterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems){
        updatePLandCashAllocation((List<Employee_Expense_Allocation__c>) newItems.values(),CONSTANT.EMPLOYEE_EXPENSE_ALLOCATION_UPDATE, (Map<Id,Employee_Expense_Allocation__c>) oldItems);
    }
    
    public void AfterDelete(Map<Id, SObject> oldItems){
       
    }
    
    public void AfterUndelete(Map<Id, SObject> oldItems){
      
    }
    
    public Boolean IsDisabled(){
        return false;
    }
    
  /*
    * This method recalculate number of employees on expense Pl allocation and forecast amount
    * @parameter oldMap, Map of EmployeeExpenseAllocation Id and EmployeeExpenseAcclocation list
    * @returns void
    */
    public static void handleBeforeDelete(Map<Id,Employee_Expense_Allocation__c> oldMap){
        updatePLandCashAllocation(oldMap.Values(), CONSTANT.EMPLOYEE_EXPENSE_ALLOCATION_DELETE, null);
    }    
   
   public static void updatePLandCashAllocation(list< Employee_Expense_Allocation__c> newEmployeeExpenseAllocationList, String isInsertOrIsDelete, Map<Id,Employee_Expense_Allocation__c> oldMap ){
        
        Set<String> eaIdList = new Set<String>();
        Map<id,List<Employee_Expense_Allocation__c>> eaIdEeaMap = new Map<id,List<Employee_Expense_Allocation__c>>();
        Map<Expense_Account__c,Expense_Detail__c> eaIdEdMap = new Map<Expense_Account__c,Expense_Detail__c>();

        List<Expense_PL_Allocation__c> expPLAllocations = new List<Expense_PL_Allocation__c>(); 
        for(Employee_Expense_Allocation__c eea : newEmployeeExpenseAllocationList){
            if(eea.Expense_Account__c != NULL){ 
                eaIdList.add(eea.Expense_Account__c);
            }
            if(!eaIdEeaMap.containsKey(eea.Expense_Account__c)){
                eaIdEeaMap.put(eea.Expense_Account__c, new List<Employee_Expense_Allocation__c>());
            }
            eaIdEeaMap.get(eea.Expense_Account__c).add(eea);
        }
        
        if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.EXPENSE_PL_ALLOCATION_OBJECT,'id, Expense_Account__c, Number_of_Employee__c, Forecast_Amount__c',Constant.ACTION_TYPE_ACCESS) &&
           PlaceCPM_Utility.checkAccessiblityOfFields(Constant.EXPENSE_DETAIL_OBJECT,'Monthly_Expense_Amount__c, Start_Date__c',Constant.ACTION_TYPE_ACCESS)){
            for(Expense_PL_Allocation__c ePL : [Select id, P_L__r.name, Expense_Account__c, Number_of_Employee__c, Forecast_Amount__c, Expense_Detail__r.Monthly_Expense_Amount__c, 
                                            Expense_Detail__r.Start_Date__c from Expense_PL_Allocation__c where Expense_Account__c IN: eaIdList ORDER BY Name ASC]) {
                                                expPLAllocations.add(ePL);
            }
   		}
        updateEmployeesAndAmountOnPL(eaIdEeaMap,isInsertOrIsDelete,oldMap, expPLAllocations);
    }
    
     /*
     * This method will update Number of employees and Expense Allocation Amount on Expense P&L Allocation
     * @parameter expPLAllocations, List of Expense PL Allocation
     * @parameter eaIdEeaMap, Map of Expense Account Id and List of Employee Expense Allocation
     * @returns void
    */
    public static void updateEmployeesAndAmountOnPL(Map<Id,List<Employee_Expense_Allocation__c>> eaIdEeaMap, 
                                                    String isInsertOrIsDelete, 
                                                    Map<Id,Employee_Expense_Allocation__c> oldMap, 
                                                    List<Expense_PL_Allocation__c> expPLAllocations){
        
        List<Expense_PL_Allocation__c> plList = new List<Expense_PL_Allocation__c>(); 
        Boolean isNumberOfEmployees = false, isForecastAmount = false;
		if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.EXPENSE_PL_ALLOCATION_OBJECT,'Number_of_Employee__c',Constant.ACTION_TYPE_UPDATE)){
            isNumberOfEmployees = true;
        }  
        if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.EXPENSE_PL_ALLOCATION_OBJECT,'Forecast_Amount__c',Constant.ACTION_TYPE_UPDATE)){
            isForecastAmount = true;
        }                                                	  
        if(!expPLAllocations.isEmpty() != null){

            for(Expense_PL_Allocation__c pl : expPLAllocations){
                String[] parts = pl.P_L__r.name.split(' ');
                String month=parts[0];
                Integer mon=PlaceCPM_Utility.getMonthInNumber(month);
                Integer year=Integer.valueOf(parts[1]);
                
            
                if(eaIdEeaMap.containsKey(pl.Expense_Account__c) && eaIdEeaMap.get(pl.Expense_Account__c) != null ){
					
                    if(isNumberOfEmployees){
                        if(pl.Number_of_Employee__c == null ){
                            pl.Number_of_Employee__c = 0;
                        }
                        for(Employee_Expense_Allocation__c eea : eaIdEeaMap.get(pl.Expense_Account__c)){
                             //555
                            Date plStartDate = date.newinstance(year,mon, eea.Start_Date__c.day());
                            Date plEndDate; 
                            if(eea.End_Date__c != null){
                                plEndDate = date.newinstance(year,mon, eea.End_Date__c.day());
                            }
                            //579
                            /*if(eea.Start_Date__c < pl.Expense_Detail__r.Start_Date__c){
                                eea.addError(System.Label.Employee_Expense_Allocation_Start_Date_cannot_be_less_than_Expense_Detail_Start);
                            }else*/
                            
                            if(eea.Start_Date__c <= plStartDate && (plEndDate == null || (plEndDate != null && plEndDate <= eea.End_Date__c)) && isInsertOrIsDelete == CONSTANT.EMPLOYEE_EXPENSE_ALLOCATION_INSERT && isNumberOfEmployees){////555
                                pl.Number_of_Employee__c = pl.Number_of_Employee__c + 1;
                            }else if(eea.Start_Date__c <= plStartDate && isInsertOrIsDelete == CONSTANT.EMPLOYEE_EXPENSE_ALLOCATION_DELETE && isNumberOfEmployees){
                                pl.Number_of_Employee__c = pl.Number_of_Employee__c - 1;
                            }else if(eea.Start_Date__c > plStartDate && isInsertOrIsDelete == CONSTANT.EMPLOYEE_EXPENSE_ALLOCATION_UPDATE && pl.Number_of_Employee__c > 0  && (oldMap.get(eea.Id).Start_Date__c <= plStartDate) && isNumberOfEmployees){
                                pl.Number_of_Employee__c = pl.Number_of_Employee__c - 1;
                            }else if(eea.Start_Date__c <= plStartDate && isInsertOrIsDelete == CONSTANT.EMPLOYEE_EXPENSE_ALLOCATION_UPDATE && plStartDate < oldMap.get(eea.Id).Start_Date__c && isNumberOfEmployees){
                                pl.Number_of_Employee__c = pl.Number_of_Employee__c + 1;
                            }
                        }
                    }
                    
                    if(pl.Expense_Detail__r.Monthly_Expense_Amount__c != Null && isForecastAmount){
                        pl.Forecast_Amount__c = pl.Number_of_Employee__c * pl.Expense_Detail__r.Monthly_Expense_Amount__c;
                    }
                    plList.add(pl); //562
                }
            }
        try{
            PlaceCPM_Utility.updateRecords(plList, CONSTANT.EXPENSE_PL_ALLOCATION_OBJECT, false); //520
        }catch(Exception ex){
            PlaceCPM_Utility.debugLog(ex.getMessage() + ' at line number ' + ex.getLineNumber());
        }
    }
    
    }
}
/*
Description : This class will be used for writing all the functionalities related to Employee_Department_Allocation__c object.
Date Created : 13th June 2019
Change 1 : Namita Choudhary | 24 June 19 | PCPM - 184
*/
public with sharing class EmployeeDepartmentAllocationHandler implements CommonTriggerHandler{
    
    public void BeforeInsert(List<SObject> newItems){
        //PCPM - 184 | Namita
        addErrorsOnEmpDeptAllocationInsertion((List<Employee_Department_Allocation__c>)newItems);
    }
    
    public void BeforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems){
         
    }
    
    public void BeforeDelete(Map<Id, SObject> oldItems){
        //PCPM - 184 | Namita
        addErrorsOnEmpDeptAllocationDeletion((List<Employee_Department_Allocation__c>)oldItems.values());
    }
    
    public void AfterInsert(Map<Id, SObject> newItems){
        reallocatePLAndCash((Map<Id, Employee_Department_Allocation__c>) newItems, null);
    }
    
    public void AfterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems){
        reallocatePLAndCash((Map<Id, Employee_Department_Allocation__c>) newItems, (Map<Id, Employee_Department_Allocation__c>) oldItems);
    }
    
    public void AfterDelete(Map<Id, SObject> oldItems){
    
    }
    
    public void AfterUndelete(Map<Id, SObject> oldItems){
    
    }
    
    public Boolean IsDisabled(){
    return false;
    }
    /* This method is to delete existing P&L allocation and cash allocation and create new P&L allocation and cash allocation 
        newItems : map of Employee_Department_Allocation__c record to its id after changes
        oldItems : map of Employee_Department_Allocation__c record to its id before changes
        @return null
     */

    public static void reallocatePLAndCash(Map<Id, Employee_Department_Allocation__c> newItems, Map<Id, Employee_Department_Allocation__c> oldItems) {
        Boolean isInsert =  oldItems == null;
        List<Wages__c> wageList = new List<Wages__c>();
        List<Expense_PL_Allocation__c> plAllocation = new List<Expense_PL_Allocation__c>();
        List<Expense_Cash_Allocation__c> cashAllocation = new List<Expense_Cash_Allocation__c>();
        Set<String> employeeIdSet = new Set<String>();

        for(Employee_Department_Allocation__c eda : newItems.values()) {
            if(isInsert ||  (eda.Allocation_percentage__c != null && eda.Allocation_percentage__c != oldItems.get(eda.Id).Allocation_percentage__c)) {
                employeeIdSet.add(eda.Employee__c);
            }
        }
        
        if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.WAGES_OBJECT,'Id, P_L_Date__c,Cash_Date__c,Employee_Number__c,Wage_Amount__c ,Bonus_Amount__c ,'+
        	'Bonus_GL_Account__c , Bonus_Per_Wage__c ,Compensation__c , Employee_Name__c , Employer_Tax__c ,Employer_Tax_Amount__c , Expense_Account__c',Constant.ACTION_TYPE_ACCESS)){
                for(Wages__c wg : [Select Id, P_L_Date__c, 
                                   Cash_Date__c,Employee_Number__c,
                                   Wage_Amount__c ,Bonus_Amount__c ,
                                   Bonus_GL_Account__c , Bonus_Per_Wage__c ,
                                   Compensation__c , Employee_Name__c , Employer_Tax__c ,
                                   Employer_Tax_Amount__c , Expense_Account__c,
                                   (Select Id From Wage_Expense_Allocations__r),
                                   (Select Id From Expense_Cash_Alllocations__r )
                                   From Wages__c
                                   where Employee_Number__c  In: employeeIdSet 
                                   AND P_L_Date__c  >: date.today()]){
                                       wageList.add(wg);
                                       plAllocation.addAll(wg.Wage_Expense_Allocations__r);
                                       cashAllocation.addAll(wg.Expense_Cash_Alllocations__r);
                                   }
        }        
        PlaceCPM_Utility.deleteRecords(plAllocation, CONSTANT.EXPENSE_PL_ALLOCATION_OBJECT, false); //520
        PlaceCPM_Utility.deleteRecords(cashAllocation, CONSTANT.EXPENSE_CASG_ALLOCATION_OBJECT, false); //520
        
        if(wageList != null && wageList.size() > 0) {
            WageTriggerHandler.createPL(wageList,false);
        }
    }
    
    /*
     * Method for before insert event
     * @param : newEmpDeptAlloc - list of new Employee_Department_Allocation__c records
     * return null
     */
    public static void addErrorsOnEmpDeptAllocationInsertion(List<Employee_Department_Allocation__c> newEmpDeptAlloc){
        //PCPM-184
        Map<String, List<String>> mapEmpAndRoleProfile = new Map<String, List<String>>(); 
       	Map<String, Decimal> mapEmpAllocations = new Map<String, Decimal>();        
        
        for(Employee_Department_Allocation__c eda: newEmpDeptAlloc){
            //If(eda.Allocation_Percentage__c != null && eda.Allocation_Percentage__c > 0){ //PCPM-184
            	mapEmpAllocations.put(eda.Employee__c, 0);
            	mapEmpAndRoleProfile.put(eda.Employee__c, new List<String>()); //PCPM-184
        	//}
           
            If(eda.Allocation_Percentage__c == null || eda.Allocation_Percentage__c <= 0){
            	eda.addError(System.Label.EmployeeAllocationErrorLessThan0);
        	} 
        }
        
        if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.EMPLOYEE_DEPARTMENT_ALLOCATION_OBJECT,'id, Employee__c, Allocation_Percentage__c, Role__c',Constant.ACTION_TYPE_ACCESS)){
            for(Employee_Department_Allocation__c eda: [SELECT id, Employee__c, Allocation_Percentage__c, Role__c 
                                                        FROM Employee_Department_Allocation__c 
                                                        WHERE Employee__c IN: mapEmpAllocations.keySet()]){			
                //PCPM - 184 
                if(eda.Allocation_Percentage__c != null && eda.Allocation_Percentage__c > 0){
                    mapEmpAllocations.put(eda.Employee__c, mapEmpAllocations.get(eda.Employee__c) + eda.Allocation_Percentage__c);
                }
                if(eda.Role__c != null){
                   mapEmpAndRoleProfile.get(eda.Employee__c).add(eda.Role__c);                                            
                }                                           
            }
    	}
        for(Employee_Department_Allocation__c eda: newEmpDeptAlloc){
           if(mapEmpAllocations.containsKey(eda.Employee__c) && mapEmpAllocations.get(eda.Employee__c) + eda.Allocation_Percentage__c > 100){
               eda.addError(System.Label.TotalAllocationPercentageError); //PCPM - 184
           }
            //PCPM - 184
           if(mapEmpAndRoleProfile.containsKey(eda.Employee__c) && eda.Role__c != null && mapEmpAndRoleProfile.get(eda.Employee__c).contains(eda.Role__c)){
               eda.addError(System.Label.EmpRoleProfileError); 
           }
        }
    }
    
    /* PCPM - 184
     * Method for before delete event
     * @param : empDeptAllocList - list of to be deleted Employee_Department_Allocation__c records
     * return null
     */
    public static void addErrorsOnEmpDeptAllocationDeletion(List<Employee_Department_Allocation__c> empDeptAllocList){
        Map<String, Integer> mapEmpAndDeptAllocations = new Map<String, Integer>();
        for(Employee_Department_Allocation__c eda: empDeptAllocList){
            mapEmpAndDeptAllocations.put(eda.Employee__c, 0);
        }
        if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.EMPLOYEE_DEPARTMENT_ALLOCATION_OBJECT,'id, Employee__c, Allocation_Percentage__c',Constant.ACTION_TYPE_ACCESS)){
            for(Employee_Department_Allocation__c eda: [Select id, Employee__c, Allocation_Percentage__c from Employee_Department_Allocation__c where Employee__c IN: mapEmpAndDeptAllocations.keySet()]){	
                mapEmpAndDeptAllocations.put(eda.Employee__c, mapEmpAndDeptAllocations.get(eda.Employee__c)+1);
            }
    	}
        for(Employee_Department_Allocation__c eda : empDeptAllocList){
            if(eda.Employee__c != Null && mapEmpAndDeptAllocations.containsKey(eda.Employee__c) && mapEmpAndDeptAllocations.get(eda.Employee__c) == 1){
               eda.addError(System.Label.AtleastOneEmpDeptAllocOnEmployee ); 
           }
        }
    }
}
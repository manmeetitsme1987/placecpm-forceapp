//Namita Choudhary | 10 July 19 | PCPM-235 |Replaced Employee_Role_Profile__c to Role__c
public with sharing class WageTriggerHandler implements CommonTriggerHandler{
    Static String plNetWageRTId;
    Static String cashNetWageRTId;
    Static Map<Date , String> plsWithStartDate = new Map<Date , String>();
    Static Map<Date , String> cashWithStartDate = new Map<Date , String>();

    Static{
        plNetWageRTId = PlaceCPM_Utility.getRecordTypeIdbyDeveloperName(PlaceCPM_Utility.getCustomObjOrFieldName(CONSTANT.EXPENSE_PL_ALLOCATION_OBJECT) , CONSTANT.PL_WAGE_RDT_NET_WAGE);
        cashNetWageRTId = PlaceCPM_Utility.getRecordTypeIdbyDeveloperName(PlaceCPM_Utility.getCustomObjOrFieldName(CONSTANT.EXPENSE_CASG_ALLOCATION_OBJECT) , CONSTANT.CASH_WAGE_RDT_NET_WAGE);
        if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.PROFIT_LOSS_OBJECT,'id , Period_Start_Date__c',Constant.ACTION_TYPE_ACCESS)){
            For(Profit_Loss__c pl : [SELECT id , Period_Start_Date__c FROM Profit_Loss__c WHERE Period_Start_Date__c != null]){
                plsWithStartDate.put(pl.Period_Start_Date__c , pl.Id);
            }
    	}
        if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.CASH_FORECAST_OBJECT,'id , Period_Start_Date__c',Constant.ACTION_TYPE_ACCESS)){
            For(Cash_Forecast__c cash : [SELECT id , Period_Start_Date__c FROM Cash_Forecast__c WHERE Period_Start_Date__c != null]){
                cashWithStartDate.put(cash.Period_Start_Date__c , cash.Id);
            }
    	}
    }
    
    public void BeforeInsert(List<SObject> newItems){
        
    }
    
    public void BeforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems){
        
    }
    
    public void BeforeDelete(Map<Id, SObject> oldItems){
        deletePLAndCash(oldItems.keySet(),false);
    }
    
    public void AfterInsert(Map<Id, SObject> newItems){
        createPL((List<Wages__c>)newItems.values(),false);
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
    public static void createPL(List<Wages__c> wageList,Boolean isLocationTrigger){
        Map<String , List<Wages__c>> employeedIDAndStartDateAndWage = new Map<String , List<Wages__c>>(); 
        String key;
        List<String> employeeId = new List<String>();
        List<Date> plNeeded = new List<Date>();
        List<Date> cashNeeded = new List<Date>();
        For(Wages__c wage : wageList){
            if(wage.P_L_Date__c != null && wage.Cash_Date__c != null && wage.Employee_Number__c != null){
                key = wage.Employee_Number__c + ':' + wage.P_L_Date__c.toStartOfMonth();
                if(!employeedIDAndStartDateAndWage.containsKey(key)){
                    employeedIDAndStartDateAndWage.put(key , new List<Wages__c>());
                }
                employeedIDAndStartDateAndWage.get(key).add(wage);
                employeeId.add(wage.Employee_Number__c);
                if(!isLocationTrigger){
                    if(!plsWithStartDate.containsKey(wage.P_L_Date__c.toStartOfMonth())){
                        plNeeded.add(wage.P_L_Date__c.toStartOfMonth());
                    }
                    if(!cashWithStartDate.containsKey(wage.Cash_Date__c.toStartOfMonth())){
                        cashNeeded.add(wage.Cash_Date__c.toStartOfMonth());
                    }
                }
            }
        }
        if(plNeeded.size() > 0){
           PlaceCPM_Utility.createPL(plNeeded , true);
        }
        if(cashNeeded.size() > 0){
            PlaceCPM_Utility.createCash(cashNeeded , true);
        }
        if(plNeeded.size() > 0 || cashNeeded.size() > 0){
            if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.PROFIT_LOSS_OBJECT,'id , Period_Start_Date__c',Constant.ACTION_TYPE_ACCESS)){
                For(Profit_Loss__c pl : [SELECT id , Period_Start_Date__c FROM Profit_Loss__c WHERE Period_Start_Date__c IN :plNeeded]){
                    plsWithStartDate.put(pl.Period_Start_Date__c , pl.Id);
                }
        	}
            if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.CASH_FORECAST_OBJECT,'id , Period_Start_Date__c',Constant.ACTION_TYPE_ACCESS)){
                For(Cash_Forecast__c cash : [SELECT id , Period_Start_Date__c FROM Cash_Forecast__c WHERE Period_Start_Date__c IN :cashNeeded]){
                    cashWithStartDate.put(cash.Period_Start_Date__c , cash.Id);
                }
            }    
        }
        Map<String , Employee__c> employeeAndAllocation;
        if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.EMPLOYEE_OBJECT,'id',Constant.ACTION_TYPE_ACCESS) &&
           PlaceCPM_Utility.checkAccessiblityOfFields(Constant.EMPLOYEE_DEPARTMENT_ALLOCATION_OBJECT,'id , Allocation_percentage__c',Constant.ACTION_TYPE_ACCESS) && 
           PlaceCPM_Utility.checkAccessiblityOfFields(Constant.COMPENSATION_OBJECT,'id , Bonus_Pay_Schedule__c,Start_Date__c , End_Date__c',Constant.ACTION_TYPE_ACCESS) &&
           PlaceCPM_Utility.checkAccessiblityOfFields(Constant.DEPARTMENT_OBJECT,'GL_Account__c',Constant.ACTION_TYPE_ACCESS) &&
           PlaceCPM_Utility.checkAccessiblityOfFields(Constant.ROLE_OBJECT,'Department__c',Constant.ACTION_TYPE_ACCESS) &&
           PlaceCPM_Utility.checkAccessiblityOfFields(Constant.LOCATION_OBJECT,'GL_Code__c',Constant.ACTION_TYPE_ACCESS)){ 
            employeeAndAllocation = new Map<String , Employee__c>([SELECT id , Role__r.Department__r.GL_Account__c ,
                                                                                        Location__r.GL_Code__c ,
                                                                                        (SELECT id , Allocation_percentage__c , 
                                                                                        Role__r.Department__r.GL_Account__c From
                                                                                        Employee_Department_Allocations__r) , 
                                                                                        (SELECT id , Bonus_Pay_Schedule__c  ,
                                                                                        Start_Date__c , End_Date__c FROM Compensations__r)
                                                                                        FROM Employee__c WHERE Id IN : employeeId]);
        }    
        
        List<Expense_PL_Allocation__c> expenseAllocationToUpsert = new List<Expense_PL_Allocation__c>();
        List<Expense_Cash_Allocation__c> cashAllocationToUpsert = new List<Expense_Cash_Allocation__c>();
        Date wageMonthStartDatePL;
        Date wageMonthStartDateCash;
        Expense_PL_Allocation__c expensePlRecord;
        Expense_Cash_Allocation__c expenseCash;
        Decimal Amount = 0;
        Wages__c commonWage;
        String empoyeeAndMonthStartKey;
        List<Compensation__c> compensationList;
        Boolean isCashForecast = false, isForecastAmount = false, isWage = false, isCashDate = false, isGLCode = false, isRecordTypeId = false, isType = false;
        Boolean isExpensePL = false, isPLWage = false, isPLType = false, isPLGLCode= false, isPLForecastAmount = false, isPLRecordTypeId = false;
        if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.EXPENSE_CASG_ALLOCATION_OBJECT,'Cash_Forecast__c',Constant.ACTION_TYPE_INSERT)){
            isCashForecast = true;
        }
        if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.EXPENSE_CASG_ALLOCATION_OBJECT,'Forecast_Amount__c',Constant.ACTION_TYPE_INSERT)){
            isForecastAmount = true;
        }
        if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.EXPENSE_CASG_ALLOCATION_OBJECT,'Wage__c',Constant.ACTION_TYPE_INSERT)){
            isWage = true;
        }
        if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.EXPENSE_CASG_ALLOCATION_OBJECT,'Cash_Date__c',Constant.ACTION_TYPE_INSERT)){
            isCashDate = true;
        }
        if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.EXPENSE_CASG_ALLOCATION_OBJECT,'GL_Code__c',Constant.ACTION_TYPE_INSERT)){
            isGLCode = true;
        }
        if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.EXPENSE_CASG_ALLOCATION_OBJECT,'recordTypeId',Constant.ACTION_TYPE_INSERT)){
            isRecordTypeId = true;
        }
        if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.EXPENSE_CASG_ALLOCATION_OBJECT,'Type__c',Constant.ACTION_TYPE_INSERT)){
            isType = true;
        }
        
        if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.EXPENSE_PL_ALLOCATION_OBJECT,'P_L__c',Constant.ACTION_TYPE_INSERT)){
            isExpensePL = true;
        }
        if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.EXPENSE_PL_ALLOCATION_OBJECT,'Wage__c',Constant.ACTION_TYPE_INSERT)){
            isPLWage = true; 
        }
        if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.EXPENSE_PL_ALLOCATION_OBJECT,'Type__c',Constant.ACTION_TYPE_INSERT)){
            isPLType = true;
        }
        if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.EXPENSE_PL_ALLOCATION_OBJECT,'GL_Code__c',Constant.ACTION_TYPE_INSERT)){
            isPLGLCode = true;
        }
        if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.EXPENSE_PL_ALLOCATION_OBJECT,'Forecast_Amount__c',Constant.ACTION_TYPE_INSERT)){
            isPLForecastAmount = true;
        }
        if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.EXPENSE_PL_ALLOCATION_OBJECT,'recordTypeId',Constant.ACTION_TYPE_INSERT)){
            isPLRecordTypeId = true;
        }
        
        For(String employeeAndMonthStartDate : employeedIDAndStartDateAndWage.keySet()){
            For(Wages__c wage : employeedIDAndStartDateAndWage.get(employeeAndMonthStartDate)){
                wageMonthStartDateCash = wage.Cash_Date__c.toStartOfMonth();
                wageMonthStartDatePL = wage.P_L_Date__c.toStartOfMonth();
                    if(employeeAndAllocation.containsKey(wage.Employee_Number__c) && employeeAndAllocation.get(wage.Employee_Number__c).Employee_Department_Allocations__r != null){
                        if(!isLocationTrigger){
                            For(Employee_Department_Allocation__c allocation : employeeAndAllocation.get(wage.Employee_Number__c).Employee_Department_Allocations__r){
                                if(cashWithStartDate.containsKey(wageMonthStartDateCash) && plsWithStartDate.containsKey(wageMonthStartDatePL)){
                                    expenseCash = new Expense_Cash_Allocation__c();
                                    if(isCashForecast){
                                        expenseCash.Cash_Forecast__c = cashWithStartDate.get(wageMonthStartDateCash);
                                    }
                                    if(isForecastAmount){
                                        expenseCash.Forecast_Amount__c = (wage.Wage_Amount__c * allocation.Allocation_percentage__c)/100;
                                    }
                                    if(isWage){
                                        expenseCash.Wage__c = wage.Id;
                                    }
                                    if(isCashDate){
                                        expenseCash.Cash_Date__c = wage.Cash_Date__c;
                                    }
                                    if(isGLCode){
                                        expenseCash.GL_Code__c = allocation.Role__c != null ? allocation.Role__r.Department__r.GL_Account__c : null;
                                    }
                                    if(isRecordTypeId){
                                        expenseCash.recordTypeId = cashNetWageRTId;
                                    }
                                    if(isType){
                                        expenseCash.Type__c = CONSTANT.CASH_AND_PL_TYPE_WAGE;
                                    }
                                    cashAllocationToUpsert.add(expenseCash);
                                    if(wage.Bonus_Amount__c != null && wage.Bonus_Amount__c != 0){
                                        expenseCash = new Expense_Cash_Allocation__c();
                                        if(isCashForecast){
                                            expenseCash.Cash_Forecast__c = cashWithStartDate.get(wageMonthStartDateCash);
                                        }
                                        if(isWage){
                                            expenseCash.Wage__c = wage.Id;
                                        }
                                        if(isCashDate){
                                            expenseCash.Cash_Date__c = wage.Cash_Date__c;
                                        }
                                        if(isGLCode){
                                            expenseCash.GL_Code__c = allocation.Role__c != null ? allocation.Role__r.Department__r.GL_Account__c : null;
                                        }
                                        if(isType){
                                            expenseCash.Type__c = CONSTANT.CASH_AND_PL_TYPE_BONUS;
                                        }
                                        if(isRecordTypeId){
                                            expenseCash.recordTypeId = cashNetWageRTId;
                                        }
                                        if(isForecastAmount){
                                            expenseCash.Forecast_Amount__c = (wage.Bonus_Amount__c * allocation.Allocation_percentage__c)/100;
                                        }
                                        cashAllocationToUpsert.add(expenseCash);
                                    }

                                    expensePlRecord = new Expense_PL_Allocation__c();
                                    if(isExpensePL){
                                        expensePlRecord.P_L__c = plsWithStartDate.get(wageMonthStartDatePL);
                                    }
                                    if(isPLWage){
                                        expensePlRecord.Wage__c = wage.Id;
                                    }
                                    if(isPLType){
                                        expensePlRecord.Type__c = CONSTANT.CASH_AND_PL_TYPE_WAGE;
                                    }
                                    if(isPLGLCode){
                                        expensePlRecord.GL_Code__c = allocation.Role__c != null ? allocation.Role__r.Department__r.GL_Account__c : null;
                                    }
                                    if(isPLForecastAmount){
                                        expensePlRecord.Forecast_Amount__c = (wage.Wage_Amount__c * allocation.Allocation_percentage__c)/100;
                                    }
                                    if(isPLRecordTypeId){
                                        expensePlRecord.recordTypeId = plNetWageRTId;
                                    }
                                    expenseAllocationToUpsert.add(expensePlRecord);
                                    compensationList = employeeAndAllocation.containsKey(wage.Employee_Number__c) && employeeAndAllocation.get(wage.Employee_Number__c).Compensations__r != Null ? employeeAndAllocation.get(wage.Employee_Number__c).Compensations__r : Null;
                                    if(wage.Bonus_Per_Wage__c != Null && wage.Bonus_Per_Wage__c != 0 && wage.Bonus_GL_Account__c != Null){
                                        expenseAllocationToUpsert.add(createPLForBonus((wage.Bonus_Per_Wage__c * allocation.Allocation_percentage__c)/100 , wage , employeeAndAllocation , wage.Bonus_GL_Account__c));
                                    }
                                }
                            }
                        }
                        if(employeeAndAllocation.get(wage.Employee_Number__c).Location__r.GL_Code__c != Null){
                            if(wage.Employer_Tax_Amount__c != Null && wage.Employer_Tax_Amount__c > 0){
                                expenseCash = new Expense_Cash_Allocation__c();
                                if(isCashForecast){
                                    expenseCash.Cash_Forecast__c = cashWithStartDate.get(wageMonthStartDateCash);
                                }
                                if(isWage){
                                    expenseCash.Wage__c = wage.Id;
                                }
                                if(isCashDate){
                                    expenseCash.Cash_Date__c = wage.Cash_Date__c;
                                }
                                if(isType){
                                    expenseCash.Type__c = CONSTANT.CASH_AND_PL_TYPE_PAYROLL_TAX;
                                }
                                if(isGLCode){
                                    expenseCash.GL_Code__c = employeeAndAllocation.get(wage.Employee_Number__c).Location__r.GL_Code__c;
                                }
                                if(isForecastAmount){
                                    expenseCash.Forecast_Amount__c = wage.Employer_Tax_Amount__c;
                                }
                                if(isRecordTypeId){
                                    expenseCash.recordTypeId = cashNetWageRTId;
                                }
                                cashAllocationToUpsert.add(expenseCash);
                                expenseAllocationToUpsert.add(createPLForTaxAmount(wage.Employer_Tax_Amount__c , wage , employeeAndAllocation , employeeAndAllocation.get(wage.Employee_Number__c).Location__r.GL_Code__c));
                            } 
                        }
                    }
                }
            }
        
        try{
            PlaceCPM_Utility.insertRecords(expenseAllocationToUpsert, CONSTANT.EXPENSE_PL_ALLOCATION_OBJECT, false);//520
        }
        catch(Exception ex){
            PlaceCPM_Utility.debugLog(ex.getMessage() + ' at line number ' + ex.getLineNumber());
        }
        
        try{
            PlaceCPM_Utility.insertRecords(cashAllocationToUpsert, CONSTANT.EXPENSE_CASG_ALLOCATION_OBJECT, false);//520
        }
        catch(Exception ex){
            PlaceCPM_Utility.debugLog(ex.getMessage() + ' at line number ' + ex.getLineNumber());
        }
            
        
    }
    static Expense_PL_Allocation__c createPLForBonus(Decimal Amount ,  Wages__c wage , Map<String , Employee__c> employeeAndAllocation , String glcode){
        Date startDate = wage.P_L_Date__c.toStartOfMonth();
        Expense_PL_Allocation__c expensePlRecord;
        Employee__c empployee;
        empployee = employeeAndAllocation.containsKey(wage.Employee_Number__c) ? employeeAndAllocation.get(wage.Employee_Number__c) : Null;
        expensePlRecord = new Expense_PL_Allocation__c();
        if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.EXPENSE_PL_ALLOCATION_OBJECT,'Type__c',Constant.ACTION_TYPE_INSERT)){
        	expensePlRecord.Type__c = CONSTANT.CASH_AND_PL_TYPE_BONUS;
        }  
        if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.EXPENSE_PL_ALLOCATION_OBJECT,'Wage__c',Constant.ACTION_TYPE_INSERT)){
        	expensePlRecord.Wage__c = wage.Id;
        }  
        if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.EXPENSE_PL_ALLOCATION_OBJECT,'P_L__c',Constant.ACTION_TYPE_INSERT)){
        	expensePlRecord.P_L__c = plsWithStartDate.containsKey(startDate.toStartOfMonth()) ? plsWithStartDate.get(startDate.toStartOfMonth()) : Null;
        }
        if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.EXPENSE_PL_ALLOCATION_OBJECT,'GL_Code__c',Constant.ACTION_TYPE_INSERT)){
        	expensePlRecord.GL_Code__c = glcode;
        }
        if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.EXPENSE_PL_ALLOCATION_OBJECT,'Forecast_Amount__c',Constant.ACTION_TYPE_INSERT)){    
        	expensePlRecord.Forecast_Amount__c = Amount; 
        }
        if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.EXPENSE_PL_ALLOCATION_OBJECT,'recordTypeId',Constant.ACTION_TYPE_INSERT)){
        	expensePlRecord.recordTypeId = plNetWageRTId;
        }    
        return expensePlRecord;
    }
    
    public static void deletePLAndCash(Set<Id> wagesDeleted, Boolean isLocationTrigger){
        List<Expense_PL_Allocation__c> plRelatedToWage = new List<Expense_PL_Allocation__c>();
        List<Expense_Cash_Allocation__c> cashRelatedToWage = new List<Expense_Cash_Allocation__c>();
        if(isLocationTrigger){
            plRelatedToWage = [SELECT id FROM Expense_PL_Allocation__c WHERE Wage__c IN : wagesDeleted AND Type__c =: CONSTANT.CASH_AND_PL_TYPE_PAYROLL_TAX];
            cashRelatedToWage = [SELECT id FROM Expense_Cash_Allocation__c WHERE Wage__c IN : wagesDeleted AND Type__c =: CONSTANT.CASH_AND_PL_TYPE_PAYROLL_TAX];
        }
        else{
            plRelatedToWage = [SELECT id FROM Expense_PL_Allocation__c WHERE Wage__c IN : wagesDeleted ];
            cashRelatedToWage = [SELECT id FROM Expense_Cash_Allocation__c WHERE Wage__c IN : wagesDeleted ];
        }
        
        PlaceCPM_Utility.deleteRecords(plRelatedToWage, CONSTANT.EXPENSE_PL_ALLOCATION_OBJECT, false);//520
        PlaceCPM_Utility.deleteRecords(cashRelatedToWage, CONSTANT.EXPENSE_CASG_ALLOCATION_OBJECT, false);//520
    }
    
    public static Expense_PL_Allocation__c createPLForTaxAmount(Decimal Amount ,  Wages__c wage , Map<String , Employee__c> employeeAndAllocation , String glcode){
        Date startDate = wage.P_L_Date__c.toStartOfMonth();
        Expense_PL_Allocation__c expensePlRecord;
        Employee__c empployee;
        empployee = employeeAndAllocation.containsKey(wage.Employee_Number__c) ? employeeAndAllocation.get(wage.Employee_Number__c) : Null;
            expensePlRecord = new Expense_PL_Allocation__c();
        	if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.EXPENSE_PL_ALLOCATION_OBJECT,'Wage__c',Constant.ACTION_TYPE_INSERT)){
            	expensePlRecord.Wage__c = wage.Id;
            }  
            if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.EXPENSE_PL_ALLOCATION_OBJECT,'P_L__c',Constant.ACTION_TYPE_INSERT)){
            	expensePlRecord.P_L__c = plsWithStartDate.containsKey(startDate.toStartOfMonth()) ? plsWithStartDate.get(startDate.toStartOfMonth()) : Null;
            }
            if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.EXPENSE_PL_ALLOCATION_OBJECT,'GL_Code__c',Constant.ACTION_TYPE_INSERT)){
            	expensePlRecord.GL_Code__c = glcode;
            }
        	if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.EXPENSE_PL_ALLOCATION_OBJECT,'Type__c',Constant.ACTION_TYPE_INSERT)){
            	expensePlRecord.Type__c = CONSTANT.CASH_AND_PL_TYPE_PAYROLL_TAX;
            }
            if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.EXPENSE_PL_ALLOCATION_OBJECT,'Forecast_Amount__c',Constant.ACTION_TYPE_INSERT)){
            	expensePlRecord.Forecast_Amount__c = Amount;
            }
         	if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.EXPENSE_PL_ALLOCATION_OBJECT,'recordTypeId',Constant.ACTION_TYPE_INSERT)){
            	expensePlRecord.recordTypeId = plNetWageRTId;
            }    
            return expensePlRecord;
    }
}
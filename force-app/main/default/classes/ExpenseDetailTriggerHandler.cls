/*
Description : This class will be used for writing all the functionalities of Different Trigger Events related to Expense_Detail__c object.
Date Created : 10 June 2019
Functionality Included: Validate New Expense Details Records and Add Error, 
                        Update Previous Expense Details related to Expense Accpount.
                        Create/Update Expense P&L Allocstion and Expense Cash Alloction Records.
*/

public with sharing class ExpenseDetailTriggerHandler implements CommonTriggerHandler{

    public void BeforeInsert(List<SObject> newItems){
        validateExpenseDetail((List<Expense_Detail__c>)newItems, false);
         //system.debug(' validate called --- '+newItems);
    }
    
    public void BeforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems){
       //validateExpenseDetail((List<Expense_Detail__c>)newItems.values(), true);
       validateUpdate((List<Expense_Detail__c>)newItems.values(), (Map<Id, Expense_Detail__c>)oldItems);

    }
    
    public void BeforeDelete(Map<Id, SObject> oldItems){
        handleBeforeDelete((Map<Id, Expense_Detail__c>)oldItems);
    }
    
    public void AfterInsert(Map<Id, SObject> newItems){
        handleAfterInsert((List<Expense_Detail__c>)newItems.values());
    }
    
    public void AfterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems){
        handleAfterUpdate((Map<Id, Expense_Detail__c>)newItems , (Map<Id, Expense_Detail__c>)oldItems);
        updateCompensationPaymentDate((List<Expense_Detail__c>) newItems.values(),(Map<Id,Expense_Detail__c>) oldItems);
    }
    
    public void AfterDelete(Map<Id, SObject> oldItems){
        handleAfterDelete((Map<Id, Expense_Detail__c>)oldItems);
    }
    
    public void AfterUndelete(Map<Id, SObject> oldItems){
      
    }
    
    public Boolean IsDisabled(){
        return false;
    }

    public static void handleBeforeDelete(Map<Id, Expense_Detail__c> oldMap){
        Set<String> ifHasError = new Set<String>();

        list<Expense_PL_Allocation__c> expensePnlAllocationsToBeDeleted = new list<Expense_PL_Allocation__c>();
        list<Expense_Cash_Allocation__c> expenseCashAllocationsToBeDeleted = new list<Expense_Cash_Allocation__c>();
        Map<String, List<Expense_PL_Allocation__c>> mapPnls = new Map<String, List<Expense_PL_Allocation__c>>();
        Map<String, List<Expense_Cash_Allocation__c>> mapCash = new Map<String, List<Expense_Cash_Allocation__c>>();
		if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.EXPENSE_PL_ALLOCATION_OBJECT,'id,Expense_Detail__c',Constant.ACTION_TYPE_ACCESS) &&
           PlaceCPM_Utility.checkAccessiblityOfFields(Constant.EXPENSE_CASG_ALLOCATION_OBJECT,'id, Cash_Date__c, Expense_Detail__c',Constant.ACTION_TYPE_ACCESS) &&
		   PlaceCPM_Utility.checkAccessiblityOfFields(Constant.PL_OBJECT,'Period_Start_Date__c,Period_End_Date__c',Constant.ACTION_TYPE_ACCESS) &&
           PlaceCPM_Utility.checkAccessiblityOfFields(Constant.CASH_FORECAST_OBJECT,'Period_Start_Date__c,Period_End_Date__c',Constant.ACTION_TYPE_ACCESS)
          ){
            for(Expense_Detail__c expDet: [Select id, 
                                            (Select id, P_L__r.Period_Start_Date__c, P_L__r.Period_End_Date__c, Expense_Detail__c from Expense_P_L_Allocations__r ) , 
                                            (Select id, Cash_Date__c, Cash_Forecast__r.Period_Start_Date__c, Cash_Forecast__r.Period_End_Date__c, Expense_Detail__c from Expense_Cash_Allocations__r ) from Expense_Detail__c where id IN: oldMap.keySet()]){
                for(Expense_PL_Allocation__c ePl: expDet.Expense_P_L_Allocations__r){
    
                    if(!mapPnls.containskey(ePl.Expense_Detail__c)){
                        mapPnls.put(ePl.Expense_Detail__c, new List<Expense_PL_Allocation__c>());
                    }
                    mapPnls.get(ePl.Expense_Detail__c).add(ePl);
    
                    if(ePl.P_L__r.Period_Start_Date__c < system.today()){
                        oldMap.get(ePl.Expense_Detail__c).addError(System.Label.ExpenseDetails_Delete_P_L);
                        ifHasError.add(ePl.Expense_Detail__c);
                    }
                }
                for(Expense_Cash_Allocation__c eCash: expDet.Expense_Cash_Allocations__r){
                
                    if(!mapCash.containskey(eCash.Expense_Detail__c)){
                        mapCash.put(eCash.Expense_Detail__c, new List<Expense_Cash_Allocation__c>());
                    }
                    mapCash.get(eCash.Expense_Detail__c).add(eCash);
    
                    if(eCash.Cash_Date__c != null && eCash.Cash_Date__c < system.today()){
                        oldMap.get(eCash.Expense_Detail__c).addError(System.Label.ExpenseDetails_Delete_Cash);
                        ifHasError.add(eCash.Expense_Detail__c);
                    }
                }
            }
    	}
        if(oldMap.keySet() != null && !oldMap.keySet().isEmpty()){
            for(String str: oldMap.keySet()){
                if(!ifHasError.contains(str) && str != null){
                    if(mapPnls.containsKey(str)) {
                        expensePnlAllocationsToBeDeleted.addAll(mapPnls.get(str));
                    }
                    if(mapCash.containsKey(str)) {
                        expenseCashAllocationsToBeDeleted.addAll(mapCash.get(str));
                    }
                }
            }
        }

        PlaceCPM_Utility.deleteRecords(expensePnlAllocationsToBeDeleted, CONSTANT.EXPENSE_PL_ALLOCATION_OBJECT, false); //520
        PlaceCPM_Utility.deleteRecords(expenseCashAllocationsToBeDeleted, CONSTANT.EXPENSE_CASG_ALLOCATION_OBJECT, false); //520
    }

    public static void handleAfterInsert(list<Expense_Detail__c> newExpenseDetailsList){
       if(!newExpenseDetailsList.isEmpty()) {
            createPnlAndCashAllocations(newExpenseDetailsList);
            createExpensePLAndCashFromGLAccount(newExpenseDetailsList);
            updateCompensationPaymentDate(newExpenseDetailsList,Null);
        }
    }

    public static void handleAfterUpdate(map<Id, Expense_Detail__c> newExpenseAccounts, map<Id, Expense_Detail__c> oldExpenseAccounts){
        List<Expense_Detail__c> newExpAccounts = new List<Expense_Detail__c>();
        if(newExpenseAccounts != null && newExpenseAccounts.size()>0){
            set<String> expenseAccountIdsForPL = new set<String>();
            set<String> expenseDetailsDeleteOnly= new set<String>();
            Map<String, Date> mapExpDetailEndDate = new Map<String, Date>();

            for(Expense_Detail__c ea: newExpenseAccounts.values()){


                if(ea.Start_Date__c != null &&  ea.Invoice_Date__c != null && (ea.Expense_Amount__c !=null || ea.Amount_of_Revenue__c != null) && ea.Payment_Term_After_Days__c != null){

                    if((ea.End_Date__c != null && ea.End_Date__c != oldExpenseAccounts.get(ea.Id).End_Date__c && (ea.End_Date__c < oldExpenseAccounts.get(ea.Id).End_Date__c|| oldExpenseAccounts.get(ea.Id).End_Date__c == null))
                        && (ea.Start_Date__c == oldExpenseAccounts.get(ea.Id).Start_Date__c)
                        && (ea.Invoice_Date__c == oldExpenseAccounts.get(ea.Id).Invoice_Date__c)
                        && (ea.Expense_Amount__c == oldExpenseAccounts.get(ea.Id).Expense_Amount__c)
                        && (ea.Payment_Term_After_Days__c == oldExpenseAccounts.get(ea.Id).Payment_Term_After_Days__c)  
                        )
                        {
                            mapExpDetailEndDate.put(ea.Id, ea.End_Date__c);
                    }
                    else {
						if(oldExpenseAccounts.get(ea.Id).End_Date__c != null 
                        && ea.End_Date__c != oldExpenseAccounts.get(ea.Id).End_Date__c 
                        && ea.Start_Date__c == oldExpenseAccounts.get(ea.Id).Start_Date__c && ea.Start_Date__c < system.today()
                        && ea.End_Date__c > oldExpenseAccounts.get(ea.Id).End_Date__c
                        && ea.End_Date__c != null ){
                            Expense_Detail__c ed = new Expense_Detail__c();
                            ed = ea.clone();
                            ed.Id = ea.Id;
                            ed.Start_Date__c = oldExpenseAccounts.get(ea.Id).End_Date__c.addMonths(1).toStartOfMonth();
                            Date newInvoiceDate = Date.newInstance(ed.Start_Date__c.year(), ed.Start_Date__c.month(), ea.Invoice_Date__c.day());
                            //Integer months = oldExpenseAccounts.get(ea.Id).End_Date__c.addMonths(1).toStartOfMonth().monthsBetween(ea.End_Date__c);
                            ed.Invoice_Date__c = newInvoiceDate;
                            newExpAccounts.add(ed);
                        }
                        else if(
                            ea.End_Date__c != oldExpenseAccounts.get(ea.Id).End_Date__c
                            || (ea.Start_Date__c != oldExpenseAccounts.get(ea.Id).Start_Date__c) 
                            || (ea.Invoice_Date__c != oldExpenseAccounts.get(ea.Id).Invoice_Date__c)
                            || (ea.Expense_Amount__c != oldExpenseAccounts.get(ea.Id).Expense_Amount__c)
                            || (ea.Payment_Term_After_Days__c != oldExpenseAccounts.get(ea.Id).Payment_Term_After_Days__c)
                            ){
                                expenseAccountIdsForPL.add(ea.Id);
                                newExpAccounts.add(ea);
                        }
                    }
                }
            }

            if(mapExpDetailEndDate !=null && !mapExpDetailEndDate.keySet().isEmpty()){
                list<Expense_PL_Allocation__c> delPLAllocation = new list<Expense_PL_Allocation__c>();
                list<Expense_Cash_Allocation__c> delCashAllocation = new list<Expense_Cash_Allocation__c>();

                 for(Expense_PL_Allocation__c expPLAll: getExpDetailPL(mapExpDetailEndDate.keySet())){
                
                    if(expPLAll.P_L__r.Period_Start_Date__c > mapExpDetailEndDate.get(expPLAll.Expense_Detail__c)){
                        delPLAllocation.add(expPLAll);
                    }
                }

                for(Expense_Cash_Allocation__c expCashAll: getExpDetailCash(mapExpDetailEndDate.keySet())){
                    if(expCashAll.Cash_Forecast__r.Period_Start_Date__c > mapExpDetailEndDate.get(expCashAll.Expense_Detail__c)){
                        delCashAllocation.add(expCashAll);
                    }
                }

                PlaceCPM_Utility.deleteRecords(delPLAllocation, CONSTANT.EXPENSE_PL_ALLOCATION_OBJECT, false); //520
				PlaceCPM_Utility.deleteRecords(delCashAllocation, CONSTANT.EXPENSE_CASG_ALLOCATION_OBJECT, false);//520
                return;
            }

            if(expenseAccountIdsForPL != null && expenseAccountIdsForPL.size()>0){
                List<Expense_PL_Allocation__c> delPLAllocation = getExpDetailPL(expenseAccountIdsForPL);
                PlaceCPM_Utility.deleteRecords(delPLAllocation, CONSTANT.EXPENSE_PL_ALLOCATION_OBJECT, false); //520

                List<Expense_Cash_Allocation__c> delCashAllocation = getExpDetailCash(expenseAccountIdsForPL);
                PlaceCPM_Utility.deleteRecords(delCashAllocation, CONSTANT.EXPENSE_CASG_ALLOCATION_OBJECT, false);//520

            }

            if(!newExpAccounts.isEmpty()) {
                createPnlAndCashAllocations(newExpAccounts);
            }
        }
    }

    public static void updateCompensationPaymentDate(list<Expense_Detail__c> newExpenseDetail,map<Id, Expense_Detail__c> oldMap){
        
        Map<Expense_Detail__c, String> mapExpenseDetailExpenseAccount = new Map<Expense_Detail__c, String>(); 
        Map<String, List<Employee__c>> mapExpenseAccountEmployee = new Map<String, List<Employee__c>>(); 
        Map<String, List<Compensation__c>> mapEmployeeCompensation = new Map<String, List<Compensation__c>>();
        Set<String> setEmployeeIds = new Set<String>();
        Set<String> expenseAccountId = new Set<String>();
        List<Compensation__c> listCompensationToBeUpdated = new List<Compensation__c>();
        List<Employee__c> listEmployee = new List<Employee__c>();
        
        for(Expense_Detail__c ed : newExpenseDetail){
            expenseAccountId.add(ed.Expense_Account__c);
        }
        if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.EMPLOYEE_OBJECT,'Expense_Account__c, Id, Employee_Type__c',Constant.ACTION_TYPE_ACCESS) &&
           PlaceCPM_Utility.checkAccessiblityOfFields(Constant.EXPENSE_DETAIL_OBJECT,'Id, Invoice_Date__c, Payment_Term_After_Days__c, Expense_Account__c',Constant.ACTION_TYPE_ACCESS)){
            for(Expense_Account__c ea : [Select Id, (Select Expense_Account__c, Id, Employee_Type__c from employees__r),
                                        (Select Id, Invoice_Date__c, Payment_Term_After_Days__c, Expense_Account__c from Expense_Details__r ORDER BY Start_Date__c DESC LIMIT 1)
                                        from Expense_Account__c where Id IN : expenseAccountId]){
                for(Employee__c emp :  ea.Employees__r){
                   setEmployeeIds.add(emp.id);
                   if(!mapExpenseAccountEmployee.containskey(ea.Id)){
                        mapExpenseAccountEmployee.put(ea.Id, new List<Employee__c>());
                    }
                    mapExpenseAccountEmployee.get(ea.Id).add(emp);
                }
                for(Expense_Detail__c ed : ea.Expense_Details__r){
                    mapExpenseDetailExpenseAccount.put(ed,ea.Id);
                }
              } 
        }
        if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.EMPLOYEE_OBJECT,'Id,Employee_Type__c',Constant.ACTION_TYPE_ACCESS) &&
           PlaceCPM_Utility.checkAccessiblityOfFields(Constant.COMPENSATION_OBJECT,'Id,Payment_Date__c,Employee__c',Constant.ACTION_TYPE_ACCESS)){
            for(Employee__c emp : [Select Id,Employee_Type__c, 
                                    (Select Id,Payment_Date__c,Employee__c from Compensations__r) 
                                    from Employee__c where Id IN : setEmployeeIds]){
                                        
               mapEmployeeCompensation.put(emp.id, emp.Compensations__r);
            }
    	}
            for(Expense_Detail__c ed : mapExpenseDetailExpenseAccount.keyset()){
              if(mapExpenseAccountEmployee.containsKey(ed.Expense_Account__c)){
                  for(Employee__c emp : mapExpenseAccountEmployee.get(ed.Expense_Account__c)){
                      if(mapEmployeeCompensation.containsKey(emp.id)){
                          for(Compensation__c com : mapEmployeeCompensation.get(emp.Id)){
                              if(emp.Employee_Type__c != Null && emp.Employee_Type__c == CONSTANT.EMPLOYEE_TYPE_HOURLY_CONTRACTORS && 
                                ((oldMap != Null && (ed.Invoice_Date__c != oldMap.get(ed.Id).Invoice_Date__c || 
                                    ed.Payment_Term_After_Days__c != oldMap.get(ed.Id).Payment_Term_After_Days__c)) || oldMap == Null)
                                    && Schema.sObjectType.Compensation__c.fields.Payment_Date__c.isUpdateable()){
                                   com.Payment_Date__c = ed.Invoice_Date__c.addDays(Integer.valueOf(ed.Payment_Term_After_Days__c));
                                   listCompensationToBeUpdated.add(com);
                              }  
                            }
                         }
                      }
                   }
             }
        try{ 
            PlaceCPM_Utility.updateRecords(listCompensationToBeUpdated, CONSTANT.COMPENSATION_OBJECT, false);//520
        }catch(Exception ex){
            PlaceCPM_Utility.debugLog(ex.getMessage() + ' at line number ' + ex.getLineNumber());
        }
    }

    public static list<Expense_PL_Allocation__c> getExpDetailPL(Set<String> expDetIds){
        list<Expense_PL_Allocation__c> listPLAllocation = new list<Expense_PL_Allocation__c>();
        if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.EXPENSE_PL_ALLOCATION_OBJECT,'Id, Name, P_L__c,Expense_Detail__c',Constant.ACTION_TYPE_ACCESS) &&
          PlaceCPM_Utility.checkAccessiblityOfFields(Constant.PL_OBJECT,'Period_Start_Date__c, Period_End_Date__c',Constant.ACTION_TYPE_ACCESS)){
            for(Expense_PL_Allocation__c expPLAll: [Select Id, Name, P_L__c, P_L__r.Period_Start_Date__c, P_L__r.Period_End_Date__c, Expense_Detail__c
                                                                      From Expense_PL_Allocation__c
                                                                      Where Expense_Detail__c IN: expDetIds]){
            	listPLAllocation.add(expPLAll);
            }
   		}
        return listPLAllocation;
    }

    public static list<Expense_Cash_Allocation__c> getExpDetailCash(Set<String> expDetIds){
        list<Expense_Cash_Allocation__c> listCashAllocation = new list<Expense_Cash_Allocation__c>();
        if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.EXPENSE_CASG_ALLOCATION_OBJECT,'Id, Name, Cash_Forecast__c, Expense_Detail__c',Constant.ACTION_TYPE_ACCESS) &&
           PlaceCPM_Utility.checkAccessiblityOfFields(Constant.CASH_FORECAST_OBJECT,'Period_Start_Date__c, Period_End_Date__c',Constant.ACTION_TYPE_ACCESS)){
            for(Expense_Cash_Allocation__c expCashAll: [Select Id, Name, Cash_Forecast__c, Cash_Forecast__r.Period_Start_Date__c, 
                                                                          Cash_Forecast__r.Period_End_Date__c, Expense_Detail__c
                                                                          From Expense_Cash_Allocation__c
                                                                          Where Expense_Detail__c IN: expDetIds]){
                        
                listCashAllocation.add(expCashAll);
            }
    	}
        return listCashAllocation;
    }

    public static void handleAfterDelete(Map<Id, Expense_Detail__c> oldMap){
        //Delete Related Expense P&L Allocations and Cash Allocationss
        list<Expense_PL_Allocation__c> expensePnlAllocationsToBeDeleted = new list<Expense_PL_Allocation__c>();
        list<Expense_Cash_Allocation__c> expenseCashAllocationsToBeDeleted = new list<Expense_Cash_Allocation__c>();
        for(Expense_PL_Allocation__c ePl: [Select id from Expense_PL_Allocation__c where Expense_Detail__c IN: oldMap.keySet()]){
            expensePnlAllocationsToBeDeleted.add(ePl);
        }
        for(Expense_Cash_Allocation__c eCash: [Select id from Expense_Cash_Allocation__c where Expense_Detail__c IN: oldMap.keySet()]){
            expenseCashAllocationsToBeDeleted.add(eCash);
        }
        PlaceCPM_Utility.deleteRecords(expensePnlAllocationsToBeDeleted, CONSTANT.EXPENSE_PL_ALLOCATION_OBJECT, false); //520
        PlaceCPM_Utility.deleteRecords(expenseCashAllocationsToBeDeleted, CONSTANT.EXPENSE_CASG_ALLOCATION_OBJECT, false); //520
    }

    public static void createPnlAndCashAllocations(List<Expense_Detail__c> newExpenseDetails){
        String plNonWageRecTypeId = Schema.SObjectType.Expense_PL_Allocation__c .getRecordTypeInfosByName().get(CONSTANT.NON_WAGE_RECORD_TYPE_EPLA).getRecordTypeId(); //520
        String cashNonWageRecTypeId = Schema.SObjectType.Expense_Cash_Allocation__c.getRecordTypeInfosByName().get(CONSTANT.NON_WAGE_RECORD_TYPE_ECHA).getRecordTypeId(); //520
        
        Map<String, Integer> mapExpDetailsMonths = new Map<String, Integer>();
        Map<String, Expense_Account__c> mapEmpExpAllocation = new Map<String, Expense_Account__c>();
        String recurringRecTypeId = Schema.SObjectType.Expense_Detail__c.getRecordTypeInfosByName().get(CONSTANT.RECURRING_RECORD_TYPE_ED).getRecordTypeId(); //520
        String nonRecurringRecTypeId = Schema.SObjectType.Expense_Detail__c.getRecordTypeInfosByName().get(CONSTANT.NON_RECURRING_RECORD_TYPE_ED).getRecordTypeId(); //520

        list<Expense_PL_Allocation__c> expensePnlAllocations = new list<Expense_PL_Allocation__c>();
        list<Expense_Cash_Allocation__c> expenseCashAllocations = new list<Expense_Cash_Allocation__c>();
        map<String, Profit_Loss__c> pnlMap = new map<String, Profit_Loss__c>(); 
        map<String, Cash_Forecast__c> cashForecastMap = new map<String, Cash_Forecast__c>();
		Boolean isVendor = false, isNumberOfEmployee = false, isForecastAmount = false, isGLCode = false;
        Boolean isECAForecastAmount = false, isECAGLCode = false;
        if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.EXPENSE_PL_ALLOCATION_OBJECT,'Vendor__c',Constant.ACTION_TYPE_INSERT)){
            isVendor = true;
        }
        if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.EXPENSE_PL_ALLOCATION_OBJECT,'Number_of_Employee__c',Constant.ACTION_TYPE_INSERT)){
            isNumberOfEmployee = true;
        }
        if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.EXPENSE_PL_ALLOCATION_OBJECT,'Forecast_Amount__c',Constant.ACTION_TYPE_INSERT)){
            isForecastAmount = true;
        }
        if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.EXPENSE_PL_ALLOCATION_OBJECT,'GL_Code__c',Constant.ACTION_TYPE_INSERT)){
            isGLCode = true;
        }
        if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.EXPENSE_CASG_ALLOCATION_OBJECT,'Forecast_Amount__c',Constant.ACTION_TYPE_INSERT)){
            isECAForecastAmount = true;
        }
        if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.EXPENSE_CASG_ALLOCATION_OBJECT,'GL_Code__c',Constant.ACTION_TYPE_INSERT)){
            isECAGLCode = true;
        }
        if(newExpenseDetails != null && newExpenseDetails.size()>0){
            for(Expense_Detail__c expDets: newExpenseDetails ){
                if(expDets.Expense_Account__c != null && expDets.Expense_Amount__c > 0){
                    if(!mapEmpExpAllocation.containsKey(expDets.Expense_Account__c)){
                        mapEmpExpAllocation.put(expDets.Expense_Account__c, new Expense_Account__c());
                    }
                }
                mapExpDetailsMonths.put(expDets.Id, PlaceCPM_Utility.getTotalMonths(expDets.Start_Date__c, expDets.End_Date__c, system.today(), expDets.Auto_Renew__c));
            }
            if(!mapEmpExpAllocation.keySet().isEmpty()){
                mapEmpExpAllocation = getEmployeeExpenseAllocationCount(mapEmpExpAllocation);
            }
            map<String, SObject> sobjMap = new map<String, SObject>(); 
            
            sobjMap = getMonthsForAllocation(newExpenseDetails, CONSTANT.EXPPLTYPE);

            for(String mpPl: sobjMap.keySet()){
                pnlMap.put(mpPl, (Profit_Loss__c)sobjMap.get(mpPl));
            }
            sobjMap = getMonthsForAllocation(newExpenseDetails, CONSTANT.EXPCASHTYPE);

            for(String mpCh: sobjMap.keySet()){
                cashForecastMap.put(mpCh, (Cash_Forecast__c)sobjMap.get(mpCh));
            }
            //map<String, Cash_Forecast__c> cashForecastMap = (map<String, Cash_Forecast__c>) getMonthsForAllocation(newExpenseDetails, CONSTANT.EXPCASHTYPE);
                      
            for(Expense_Detail__c ea: newExpenseDetails){
                if(ea.Expense_Amount__c > 0){
                    Integer expenseMonths = PlaceCPM_Utility.getTotalMonths(ea.Start_Date__c, ea.End_Date__c, system.today(), ea.Auto_Renew__c);

                    //system.debug(' test --- '+ expenseMonths + ' --- '  + ea.Start_Date__c  + ' --- '  + ea.End_Date__c);
                    if(ea.Start_Date__c != null && expenseMonths > 0){
                        // Logic for Expense P&L Allocation
                        for(Integer i=0; i< expenseMonths; i++){
                            if((i==0 && ea.RecordTypeId == nonRecurringRecTypeId)
                                    || ea.RecordTypeId == recurringRecTypeId){
                            Date futureDatesforPL=ea.Start_Date__c.addMonths(i);
                            String monthStr = PlaceCPM_Utility.getMonthString(futureDatesforPL.month());
                            Profit_Loss__c pnlRec = pnlMap.get(monthStr+' '+futureDatesforPL.year());
                            Expense_PL_Allocation__c epla = new Expense_PL_Allocation__c(P_L__c=pnlRec.Id, Expense_Account__c=ea.Expense_Account__c, Expense_Detail__c = ea.Id, RecordTypeId = plNonWageRecTypeId, Type__c = CONSTANT.CASH_AND_PL_TYPE_EXPENSE_ACCOUNT);
                            if(ea.Vendor_Id__c != null && isVendor){
                                epla.Vendor__c=ea.Vendor_Id__c;
                            }
                            if(isNumberOfEmployee){
                                epla.Number_of_Employee__c = (mapEmpExpAllocation.get(ea.Expense_Account__c).Employee_Expense_Allocations__r !=null ? mapEmpExpAllocation.get(ea.Expense_Account__c).Employee_Expense_Allocations__r.size() : 0);
                            }
                            //PCPM-296
                            //if(mapEmpExpAllocation.get(ea.Expense_Account__c).Employee_Role_Profile__c != null ){
                            if(epla.Number_of_Employee__c != 0 && isForecastAmount){
                                epla.Forecast_Amount__c = ea.Monthly_Expense_Amount__c * epla.Number_of_Employee__c;
                            }
                            else {
                                if(isForecastAmount){
                                    epla.Forecast_Amount__c = ea.Monthly_Expense_Amount__c;
                                }
                            }
                            //epla.Forecast_Amount__c = ea.Monthly_Expense_Amount__c * epla.Number_of_Employee__c;
                            if(isGLCode){
                                epla.GL_Code__c = ea.GL_Account_Id__c;
                            }
                            expensePnlAllocations.add(epla);
                        }}
                        }
                
                    if(ea.Start_Date__c != null && expenseMonths > 0 && ea.Payment_Frequency__c != null){
                        if(ea.Payment_Term_After_Days__c != null){
                            
                            Integer totalCashAllocationRecords=Integer.valueOf(expenseMonths)/Integer.valueOf(ea.Payment_Frequency__c);
                            Integer lastyearMonths=math.mod(Integer.valueOf(expenseMonths), Integer.valueOf(ea.Payment_Frequency__c));
                            if(lastyearMonths!=0){
                                totalCashAllocationRecords=totalCashAllocationRecords+1;
                            }
                            Date cashDate = ea.Invoice_Date__c .addDays(ea.Payment_Term_After_Days__c !=null ? Integer.valueOf(ea.Payment_Term_After_Days__c): 0);

                            for(Integer i=0; i<totalCashAllocationRecords; i++){
                                if((i==0 && ea.RecordTypeId == nonRecurringRecTypeId)
                                    || ea.RecordTypeId == recurringRecTypeId){
                                Decimal cashAmount = 0;
                                cashAmount= ea.RecordTypeId == nonRecurringRecTypeId ? ea.Monthly_Expense_Amount__c : ea.Monthly_Expense_Amount__c*Integer.valueOf(ea.Payment_Frequency__c);// PCPM-491
                                Date futureDatesforCash=cashDate.addMonths((i*Integer.valueOf(ea.Payment_Frequency__c)));
                                String monthStr = PlaceCPM_Utility.getMonthString(futureDatesforCash.month());
                                Cash_Forecast__c cashRec = cashForecastMap.get(monthStr+' '+futureDatesforCash.year());
                                Expense_Cash_Allocation__c eca = new Expense_Cash_Allocation__c(RecordTypeId = cashNonWageRecTypeId, 
                                                                                                Expense_Detail__c = ea.Id, 
                                                                                                Cash_Forecast__c=cashRec.Id, 
                                                                                                Expense_Account__c=ea.Expense_Account__c, 
                                                                                                Cash_Date__c=futureDatesforCash,
                                                                                                Type__c = CONSTANT.CASH_AND_PL_TYPE_EXPENSE_ACCOUNT
                                                                                                );

                                //PCPM-296
                                //if(mapEmpExpAllocation.get(ea.Expense_Account__c).Employee_Role_Profile__c != null ){
                                Integer noOfEmpExpAllocs =  (mapEmpExpAllocation.get(ea.Expense_Account__c).Employee_Expense_Allocations__r !=null ? mapEmpExpAllocation.get(ea.Expense_Account__c).Employee_Expense_Allocations__r.size(): 0 );   
                                if(noOfEmpExpAllocs != 0 && isECAForecastAmount){
                                    eca.Forecast_Amount__c = cashAmount * noOfEmpExpAllocs;
                                }
                                else {
                                    if(isECAForecastAmount){
                                        eca.Forecast_Amount__c = cashAmount;
                                    }
                                }
                                if(isECAGLCode){
                                    eca.GL_Code__c = ea.GL_Account_Id__c;
                                }
                                expenseCashAllocations.add(eca);
                            }}
                            }
                        }
                    }
                }
            
            PlaceCPM_Utility.insertRecords(expensePnlAllocations, CONSTANT.expenseAccountObject, false); //520
            PlaceCPM_Utility.insertRecords(expenseCashAllocations, CONSTANT.EXPENSE_CASG_ALLOCATION_OBJECT, false); //520
        }
    }

    //  Method to validated get total number of Employee Expense Allocations records related to Expense Account
    //  @param mapExpAllocationNumbers is the map of Map<String, Integer>
    //  @return Map<String, Integer>
    public static Map<String, Expense_Account__c> getEmployeeExpenseAllocationCount(Map<String, Expense_Account__c> mapExpAllocationNumbers){
        /*Map<String, Integer> mapExpAllocationNumbers = new Map<String, Integer>();
        for(Expense_Detail__c expDet: newExpenseDetails){
            if(expDet.Expense_Account__c != null){
                if(!mapExpAllocationNumbers.containsKey(expDet.Expense_Account__c)){
                    mapExpAllocationNumbers.put(expDet.Expense_Account__c, 0);
                }
            }
        }*/
        //PCPM-296
		if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.EMPLOYEE_EXPENSE_ALLOCATION_OBJECT,'id, Expense_Account__c',Constant.ACTION_TYPE_ACCESS)){
            for(Expense_Account__c empEA: [Select id,(Select id, Expense_Account__c from Employee_Expense_Allocations__r) from Expense_Account__c where Id IN: mapExpAllocationNumbers.keySet()]){
                if(mapExpAllocationNumbers.containsKey(empEA.Id)){
                    mapExpAllocationNumbers.put(empEA.Id, empEA);
                }
            }
    	}
        return mapExpAllocationNumbers;
    }

    //  Method to validateUpdate new/Updated Expense Details Records
    //  @param newExpenseDetails is the list of Expense_Detail__c which is going to create
    //  @return void
    public static void validateUpdate(List<Expense_Detail__c> newExpenseDetails, Map<Id, Expense_Detail__c> oldExpenseDetails){
        for(Expense_Detail__c ea: newExpenseDetails){
            
            if(oldExpenseDetails.get(ea.Id).Start_Date__c < system.today() && ea.End_Date__c == oldExpenseDetails.get(ea.Id).End_Date__c){
                ea.addError(System.Label.Expense_Past_Data_Error);
            }
            else if(oldExpenseDetails.get(ea.Id).Start_Date__c < system.today() && 
            ( ea.Invoice_Date__c != oldExpenseDetails.get(ea.Id).Invoice_Date__c 
            || ea.Expense_Amount__c != oldExpenseDetails.get(ea.Id).Expense_Amount__c
            || ea.Payment_Term_After_Days__c != oldExpenseDetails.get(ea.Id).Payment_Term_After_Days__c
            || ea.Start_Date__c != oldExpenseDetails.get(ea.Id).Start_Date__c)
            ){
                ea.addError(System.Label.Expense_Past_Data_Error);
            }

            /*if(
            (ea.End_Date__c != null && ea.End_Date__c != oldExpenseDetails.get(ea.Id).End_Date__c && ea.End_Date__c < system.today())
            || (ea.Start_Date__c != null && ea.Start_Date__c != oldExpenseDetails.get(ea.Id).Start_Date__c && ea.Start_Date__c < system.today())
            || (ea.Invoice_Date__c != null && ea.Invoice_Date__c != oldExpenseDetails.get(ea.Id).Invoice_Date__c && ea.Invoice_Date__c < system.today())
            || (oldExpenseDetails.get(ea.Id).Start_Date__c < system.today() && 
            (
                (ea.Expense_Amount__c !=null && ea.Expense_Amount__c != oldExpenseDetails.get(ea.Id).Expense_Amount__c)
                || (ea.Payment_Term_After_Days__c !=null && ea.Payment_Term_After_Days__c != oldExpenseDetails.get(ea.Id).Payment_Term_After_Days__c)
                || (ea.Start_Date__c != null && ea.Start_Date__c != oldExpenseDetails.get(ea.Id).Start_Date__c)
            ))
            ){
                ea.addError(System.Label.Expense_Past_Data_Error);
            }*/
        }
    }
    //  Method to validated new Expense Details Records
    //  @param newExpenseDetails is the list of Expense_Detail__c which is going to create
    //  @return void
    public static void validateExpenseDetail(List<Expense_Detail__c> newExpenseDetails, Boolean isUpdate){
        Map<Id, List<ExpenseDetailWrapper>> mapExpWithNewDetails = new Map<Id, List<ExpenseDetailWrapper>>();
        Map<Id, List<Expense_Detail__c>> mapExpWithExistingDetails = new Map<Id, List<Expense_Detail__c>>();
        List<Expense_Detail__c> expDetailsToBeUpdated = new List<Expense_Detail__c>();
        String recurringRecTypeId = Schema.SObjectType.Expense_Detail__c.getRecordTypeInfosByName().get(CONSTANT.RECURRING_RECORD_TYPE_RC).getRecordTypeId();//520
        String expDelRevenueRecurringRtId = PlaceCPM_Utility.getRecordTypeIdbyDeveloperName(PlaceCPM_Utility.getCustomObjOrFieldName(CONSTANT.EXPENSE_DETAIL_OBJECT), CONSTANT.EXPENSE_DETAIL_REVENUE_RECURRING_RT); //520
        Boolean isEndDate = false;
        if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.EXPENSE_DETAIL_OBJECT,'End_Date__c',Constant.ACTION_TYPE_UPDATE)){
              isEndDate = true; 
        }
        for(Expense_Detail__c expD: newExpenseDetails){
            if(expD.recordTypeId == recurringRecTypeId || expD.RecordTypeId == expDelRevenueRecurringRtId){

            
            if(!mapExpWithNewDetails.containsKey(expD.Expense_Account__c)){
                mapExpWithNewDetails.put(expD.Expense_Account__c, new List<ExpenseDetailWrapper>());
            }
            mapExpWithNewDetails.get(expD.Expense_Account__c).add(new ExpenseDetailWrapper(expD));
        }        
        }
        if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.EXPENSE_DETAIL_OBJECT,'id, Name,  Start_Date__c, End_Date__c, Expense_Account__c',Constant.ACTION_TYPE_ACCESS)){
            for(Expense_Detail__c expDet: [Select id, Name,  Start_Date__c, End_Date__c, Expense_Account__c from Expense_Detail__c where Expense_Account__c IN : mapExpWithNewDetails.keySet() and Id not IN: newExpenseDetails and recordTypeId = :recurringRecTypeId order by Start_Date__c Desc limit 1]){
                if(!mapExpWithExistingDetails.containsKey(expDet.Expense_Account__c)){
                    mapExpWithExistingDetails.put(expDet.Expense_Account__c, new List<Expense_Detail__c>());
                }
                mapExpWithExistingDetails.get(expDet.Expense_Account__c).add(expDet);
            }
    	}
        for(String expId: mapExpWithNewDetails.keySet()){
            List<ExpenseDetailWrapper> expDetWrapList = mapExpWithNewDetails.get(expId);
            expDetWrapList.sort();
            for(Integer i = 0 ; i < expDetWrapList.size() ; i++){
                if(i==0){
                    if(mapExpWithExistingDetails.containsKey(expId) && !mapExpWithExistingDetails.get(expId).isEmpty()){
                        Expense_Detail__c expDetails = mapExpWithExistingDetails.get(expId)[0];
                        If(expDetWrapList[0].expDet.Start_Date__c <= expDetails.Start_Date__c /*|| expDetWrapList[0].expDet.End_Date__c <= expDetails.End_Date__c*/){
                            expDetWrapList[0].expDet.addError(System.Label.ExpenseDetails_Invalid_Date+(expDetWrapList[0].expDet.Name !=null? ' - '+expDetWrapList[0].expDet.Name : ''));
                            return;
                        }
                        if((expDetails.End_Date__c == null || expDetails.End_Date__c  > expDetWrapList[0].expDet.Start_Date__c)
                        && isEndDate){
                            expDetails.End_Date__c = expDetWrapList[0].expDet.Start_Date__c.toStartOfMonth().addDays(-1);
                            //#325
                            if(expDetails.End_Date__c < expDetails.Start_Date__c){
                                expDetWrapList[0].expDet.addError(System.Label.ExpenseDetails_Invalid_Date);
                            }else{
                            expDetailsToBeUpdated.add(expDetails);
                        }
                    }
                }
                }
                else if(expDetWrapList[i].expDet.Start_Date__c < expDetWrapList[i-1].expDet.End_Date__c){
                    Date endDate = expDetWrapList[i].expDet.Start_Date__c.toStartOfMonth().addDays(-1);
                    //#325
                    if(endDate <  expDetWrapList[i-1].expDet.Start_Date__c){
                        expDetWrapList[i-1].expDet.addError(System.Label.ExpenseDetails_Invalid_Date);
                    }else{
                    expDetWrapList[i-1].expDet.End_Date__c = endDate;
                    }
                    //expDetWrapList[i].expDet.addError(System.Label.ExpenseDetails_Invalid_Date);
                    //return;
                }
            }

        }
        PlaceCPM_Utility.updateRecords(expDetailsToBeUpdated, CONSTANT.EXPENSE_DETAIL_OBJECT, false); //520
    }

    public static Map<String, SObject> getMonthsForAllocation(list<Expense_Detail__c> eaList, String objectTypeStr){
        
        Map<String, SObject> mapPLCashRecords = new Map<String, SObject>();
        set<String> monthsForAllocations = new set<String>();

        for(Expense_Detail__c ea: eaList){
            if(ea.Start_Date__c != null){
                Integer expenseMonths = PlaceCPM_Utility.getTotalMonths(ea.Start_Date__c, ea.End_Date__c, system.today(), ea.Auto_Renew__c);
                Integer totalCashAllocationRecords = 0;
                Date cashDate = null;
                // Logic for Cash Allocation
                if(objectTypeStr == CONSTANT.EXPCASHTYPE){
                    totalCashAllocationRecords=expenseMonths/Integer.valueOf(ea.Payment_Frequency__c);
                    Integer lastyearMonths=math.mod(expenseMonths, Integer.valueOf(ea.Payment_Frequency__c));
                    if(lastyearMonths!=0){
                        expenseMonths=totalCashAllocationRecords+1;
                    }
                    cashDate = ea.Invoice_Date__c.addDays(ea.Payment_Term_After_Days__c !=null ? Integer.valueOf(ea.Payment_Term_After_Days__c) : 0); 
                } 
                for(Integer i=0; i<expenseMonths; i++){ 
                    Date futureDate= null;
                    if(objectTypeStr == CONSTANT.EXPPLTYPE){
                        futureDate=ea.Start_Date__c.addMonths(i);
                    }
                    if(objectTypeStr == CONSTANT.EXPCASHTYPE){
                        futureDate=cashDate.addMonths((i*Integer.valueOf(ea.Payment_Frequency__c)));
                    }
                    String monthStr = PlaceCPM_Utility.getMonthString(futureDate.month());
                    monthsForAllocations.add(monthStr+' '+futureDate.year());
                }
            }
        }

        if(monthsForAllocations != null && monthsForAllocations.size() > 0){
            if(objectTypeStr == CONSTANT.EXPPLTYPE){
                mapPLCashRecords = PlaceCPM_Utility.getPLRecords(monthsForAllocations);
            }
            else if(objectTypeStr == CONSTANT.EXPCASHTYPE){
                mapPLCashRecords = PlaceCPM_Utility.getCashForecastRecords(monthsForAllocations);
            }
            if(mapPLCashRecords == null){
                mapPLCashRecords = new Map<String, SObject>();
            }
            list<SObject> newListSobjects = new list<SObject>();  
            for(String str: monthsForAllocations){
                if(!mapPLCashRecords.containsKey(str)){
                    list<String> monthyear = str.split(' ');
                    Integer year = Integer.valueOf(monthyear[1]);
                    Integer month = PlaceCPM_Utility.getMonthInNumber(monthyear[0]);
                    Integer dim = date.daysInMonth(year, month);
                    date lastDOM = date.newInstance(year, month, dim);
                    date firstDOM = lastDOM.toStartOfMonth();
                    if(objectTypeStr == CONSTANT.EXPPLTYPE){
                        newListSobjects.add(new Profit_Loss__c(Name=str, Period_Start_Date__c=firstDOM, Period_End_Date__c=lastDOM));
                    }
                    if(objectTypeStr == CONSTANT.EXPCASHTYPE){
                        newListSobjects.add(new Cash_Forecast__c(Name=str, Period_Start_Date__c=firstDOM, Period_End_Date__c=lastDOM));

                    }
                }
            }
            if(!newListSobjects.isEmpty()){
                insert newListSobjects;
                for(SObject cf: newListSobjects){
                    if(objectTypeStr == CONSTANT.EXPPLTYPE){
                        Profit_Loss__c pl = (Profit_Loss__c)cf;
                        mapPLCashRecords.put(pl.Name, pl);
                    }
                    if(objectTypeStr == CONSTANT.EXPCASHTYPE){
                        Cash_Forecast__c cashF = (Cash_Forecast__c)cf;
                        mapPLCashRecords.put(cashF.Name, cashF);
                    }
                }
            }
        }
        return mapPLCashRecords;
    }

    //This class is used to create PL and cash allocation from GL Account selected on revenu expense detail
    //@param new List  of Expense Detail
    public static void createExpensePLAndCashFromGLAccount(List<Expense_Detail__c> newExpenseDetailsList){
        String plNonWageRecTypeId = Schema.SObjectType.Expense_PL_Allocation__c .getRecordTypeInfosByName().get(CONSTANT.NON_WAGE_RECORD_TYPE_EPLA).getRecordTypeId(); //520
        String cashNonWageRecTypeId = Schema.SObjectType.Expense_Cash_Allocation__c.getRecordTypeInfosByName().get(CONSTANT.NON_WAGE_RECORD_TYPE_ECHA).getRecordTypeId(); //520
        String expDelRevenueRecurringRtId = PlaceCPM_Utility.getRecordTypeIdbyDeveloperName(PlaceCPM_Utility.getCustomObjOrFieldName(CONSTANT.EXPENSE_DETAIL_OBJECT), CONSTANT.EXPENSE_DETAIL_REVENUE_RECURRING_RT); //520
        
        Map<String,String> expDelIdTOGLAccId = new Map<String,String>();
        Set<String> yearSet = new Set<String>();
        Map<String,Expense_Detail__c> expDelIdToExpDelMap = new Map<String,Expense_Detail__c>();
        List<Expense_PL_Allocation__c> explToInsert = new List<Expense_PL_Allocation__c>();
        List<Expense_Cash_Allocation__c> expcashToInsert = new List<Expense_Cash_Allocation__c>();
        Map<String,List<P_L_Statement__c>> glCodeToPLStatementListMap = new Map<String,List<P_L_Statement__c>>();
        Map<String,String> plNameToIdMap = new Map<String,String>();
        Map<String,String> cfNameToIdMap = new Map<String,String>();
        Boolean isRecordTypeId = false, isExpenseDetail = false, isCashForecast = false, isExpenseAccount = false, isCashDate = false, isType = false, isForecastAmount = false, isGLCode = false;
        if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.EXPENSE_CASG_ALLOCATION_OBJECT,'RecordTypeId',Constant.ACTION_TYPE_INSERT)){
            isRecordTypeId = true;
        }
        if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.EXPENSE_CASG_ALLOCATION_OBJECT,'Expense_Detail__c',Constant.ACTION_TYPE_INSERT)){
            isExpenseDetail = true;
        }
        if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.EXPENSE_CASG_ALLOCATION_OBJECT,'Cash_Forecast__c',Constant.ACTION_TYPE_INSERT)){
            isCashForecast = true;
        }
        if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.EXPENSE_CASG_ALLOCATION_OBJECT,'Expense_Account__c',Constant.ACTION_TYPE_INSERT)){
            isExpenseAccount = true;
        }
        if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.EXPENSE_CASG_ALLOCATION_OBJECT,'Cash_Date__c',Constant.ACTION_TYPE_INSERT)){
            isCashDate = true;
        }
        if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.EXPENSE_CASG_ALLOCATION_OBJECT,'Type__c',Constant.ACTION_TYPE_INSERT)){
            isType = true;
        }
        if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.EXPENSE_CASG_ALLOCATION_OBJECT,'Forecast_Amount__c',Constant.ACTION_TYPE_INSERT)){
            isForecastAmount = true;
        }
        if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.EXPENSE_CASG_ALLOCATION_OBJECT,'GL_Code__c',Constant.ACTION_TYPE_INSERT)){
            isGLCode = true;
        }
        for(Expense_Detail__c expDel : newExpenseDetailsList){
            if(expDel.Amount_of_Revenue__c != null && expDel.Revenue_GL_Account__c != null && expDel.RecordTypeId == expDelRevenueRecurringRtId ){
                expDelIdTOGLAccId.put(expDel.Id,expDel.Revenue_GL_Account__c);
                expDelIdToExpDelMap.put(expDel.Id,expDel);
                yearSet.add(String.valueOf(expDel.Start_Date__c.year()));
            }
        }
        if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.P_L_STATEMENT_OBJECT,'id , Year__c , January__c , February__c , March__c , April__c ,May__c , June__c , July__c , August__c , September__c , October__c ,November__c , December__c , GL_Code__c',Constant.ACTION_TYPE_ACCESS)){
            for(P_L_Statement__c pls : [SELECT id , Year__c , January__c , February__c , March__c , April__c ,
                                        May__c , June__c , July__c , August__c , September__c , October__c ,
                                        November__c , December__c , GL_Code__c 
                                        FROM P_L_Statement__c 
                                        WHERE GL_Code__c IN : expDelIdTOGLAccId.values()]){
                                            yearSet.add('%'+pls.Year__c);
                                            if(!glCodeToPLStatementListMap.containsKey(pls.GL_Code__c)){
                                                glCodeToPLStatementListMap.put(pls.GL_Code__c,new List<P_L_Statement__c>());
                                            }
                                            glCodeToPLStatementListMap.get(pls.GL_Code__c).add(pls);
                                        }
    	}
        if(yearSet.size()>0){
            for(Profit_Loss__c pl : [SELECT Id,Name FROM Profit_Loss__c  WHERE Name LIKE : yearSet]){
                plNameToIdMap.put(pl.Name,pl.Id);
            }
            for(Cash_Forecast__c cf : [SELECT Id,Name FROM Cash_Forecast__c  WHERE Name LIKE : yearSet]){
                cfNameToIdMap.put(cf.Name,cf.Id);
            }
        }
        for(Id expDelId : expDelIdTOGLAccId.keySet()){
            Integer numberOfMonths = PlaceCPM_Utility.getTotalMonths(expDelIdToExpDelMap.get(expDelId).Start_Date__c, expDelIdToExpDelMap.get(expDelId).End_Date__c, system.today(), expDelIdToExpDelMap.get(expDelId).Auto_Renew__c);
            if(glCodeToPLStatementListMap.containsKey(expDelIdTOGLAccId.get(expDelId))){
                
                Date startDate = expDelIdToExpDelMap.get(expDelId).Start_Date__c;
                Date endDate = expDelIdToExpDelMap.get(expDelId).Start_Date__c.addMonths(numberOfMonths);
                Map<Integer,List<Integer>> monthYearSet = new Map<Integer,List<Integer>>();
                while(startDate < endDate){
                    if(!monthYearSet.containsKey(startDate.Year())){
                        monthYearSet.put(startDate.Year(), new List<Integer>());
                    }
                    monthYearSet.get(startDate.Year()).add(startDate.Month());
                    startDate = startDate.AddMonths(1);
                }
                for(P_L_Statement__c pls : glCodeToPLStatementListMap.get(expDelIdTOGLAccId.get(expDelId))){
                    if(Integer.valueOf(pls.Year__c) >= expDelIdToExpDelMap.get(expDelId).Start_Date__c.year() && Integer.valueOf(pls.Year__c) <= endDate.year()){
                        
                        if(monthYearSet.containsKey(Integer.valueOf(pls.Year__c))){
                            for(Integer months : monthYearSet.get(Integer.valueOf(pls.Year__c))){
                                switch on months {
                                    when 1 {
                                        Decimal forecastCalc = (pls.January__c * expDelIdToExpDelMap.get(expDelId).Amount_of_Revenue__c)/100;
                                        explToInsert.add(createPandLAllocation(expDelIdToExpDelMap.get(expDelId).Expense_Account__c,expDelId,expDelIdToExpDelMap.get(expDelId).GL_Account_Id__c ,forecastCalc,plNameToIdMap.get('January '+pls.Year__c)));
                                    }   
                                    when 2 {
                                        Decimal forecastCalc = (pls.February__c * expDelIdToExpDelMap.get(expDelId).Amount_of_Revenue__c)/100;
                                        explToInsert.add(createPandLAllocation(expDelIdToExpDelMap.get(expDelId).Expense_Account__c,expDelId,expDelIdToExpDelMap.get(expDelId).GL_Account_Id__c,forecastCalc,plNameToIdMap.get('February '+pls.Year__c)));
                                    }
                                    when 3 {
                                        Decimal forecastCalc = (pls.March__c * expDelIdToExpDelMap.get(expDelId).Amount_of_Revenue__c)/100;
                                        explToInsert.add(createPandLAllocation(expDelIdToExpDelMap.get(expDelId).Expense_Account__c,expDelId,expDelIdToExpDelMap.get(expDelId).GL_Account_Id__c,forecastCalc,plNameToIdMap.get('March '+pls.Year__c)));
                                    }
                                    when 4 {
                                        Decimal forecastCalc = (pls.April__c * expDelIdToExpDelMap.get(expDelId).Amount_of_Revenue__c)/100;
                                        explToInsert.add(createPandLAllocation(expDelIdToExpDelMap.get(expDelId).Expense_Account__c,expDelId,expDelIdToExpDelMap.get(expDelId).GL_Account_Id__c,forecastCalc,plNameToIdMap.get('April '+pls.Year__c)));
                                    }
                                    when 5 {
                                        Decimal forecastCalc = (pls.May__c * expDelIdToExpDelMap.get(expDelId).Amount_of_Revenue__c)/100;
                                        explToInsert.add(createPandLAllocation(expDelIdToExpDelMap.get(expDelId).Expense_Account__c,expDelId,expDelIdToExpDelMap.get(expDelId).GL_Account_Id__c,forecastCalc,plNameToIdMap.get('May '+pls.Year__c)));
                                    }
                                    when 6 {
                                        Decimal forecastCalc = (pls.June__c * expDelIdToExpDelMap.get(expDelId).Amount_of_Revenue__c)/100;
                                        explToInsert.add(createPandLAllocation(expDelIdToExpDelMap.get(expDelId).Expense_Account__c,expDelId,expDelIdToExpDelMap.get(expDelId).GL_Account_Id__c,forecastCalc,plNameToIdMap.get('June '+pls.Year__c)));
                                    }
                                    when 7 {
                                        Decimal forecastCalc = (pls.July__c * expDelIdToExpDelMap.get(expDelId).Amount_of_Revenue__c)/100;
                                        explToInsert.add(createPandLAllocation(expDelIdToExpDelMap.get(expDelId).Expense_Account__c,expDelId,expDelIdToExpDelMap.get(expDelId).GL_Account_Id__c,forecastCalc,plNameToIdMap.get('July '+pls.Year__c)));
                                    }
                                    when 8 {
                                        Decimal forecastCalc = (pls.August__c * expDelIdToExpDelMap.get(expDelId).Amount_of_Revenue__c)/100;
                                        explToInsert.add(createPandLAllocation(expDelIdToExpDelMap.get(expDelId).Expense_Account__c,expDelId,expDelIdToExpDelMap.get(expDelId).GL_Account_Id__c,forecastCalc,plNameToIdMap.get('August '+pls.Year__c)));
                                    }
                                    when 9 {
                                        Decimal forecastCalc = (pls.September__c * expDelIdToExpDelMap.get(expDelId).Amount_of_Revenue__c)/100;
                                        explToInsert.add(createPandLAllocation(expDelIdToExpDelMap.get(expDelId).Expense_Account__c,expDelId,expDelIdToExpDelMap.get(expDelId).GL_Account_Id__c,forecastCalc,plNameToIdMap.get('September '+pls.Year__c)));
                                    }
                                    when 10 {
                                        Decimal forecastCalc = (pls.October__c * expDelIdToExpDelMap.get(expDelId).Amount_of_Revenue__c)/100;
                                        explToInsert.add(createPandLAllocation(expDelIdToExpDelMap.get(expDelId).Expense_Account__c,expDelId,expDelIdToExpDelMap.get(expDelId).GL_Account_Id__c,forecastCalc,plNameToIdMap.get('October '+pls.Year__c)));
                                    }
                                    when 11 {
                                        Decimal forecastCalc = (pls.November__c * expDelIdToExpDelMap.get(expDelId).Amount_of_Revenue__c)/100;
                                        explToInsert.add(createPandLAllocation(expDelIdToExpDelMap.get(expDelId).Expense_Account__c,expDelId,expDelIdToExpDelMap.get(expDelId).GL_Account_Id__c,forecastCalc,plNameToIdMap.get('November '+pls.Year__c)));
                                    }
                                    when 12 {
                                        Decimal forecastCalc = (pls.December__c * expDelIdToExpDelMap.get(expDelId).Amount_of_Revenue__c)/100;
                                        explToInsert.add(createPandLAllocation(expDelIdToExpDelMap.get(expDelId).Expense_Account__c,expDelId,expDelIdToExpDelMap.get(expDelId).GL_Account_Id__c,forecastCalc,plNameToIdMap.get('December '+pls.Year__c)));
                                    }
                                }
                            }
                        }
                    }
                }
            }
            Expense_Detail__c ea = expDelIdToExpDelMap.get(expDelId);
            if(ea.Start_Date__c != null && numberOfMonths > 0 && ea.Payment_Frequency__c != null){
                if(ea.Payment_Term_After_Days__c != null){
                    Integer totalCashAllocationRecords=Integer.valueOf(numberOfMonths)/Integer.valueOf(ea.Payment_Frequency__c);
                    Integer lastyearMonths=math.mod(Integer.valueOf(numberOfMonths), Integer.valueOf(ea.Payment_Frequency__c));
                    if(lastyearMonths!=0){
                        totalCashAllocationRecords=totalCashAllocationRecords+1;
                    }
                    Date cashDate = ea.Invoice_Date__c .addDays(ea.Payment_Term_After_Days__c !=null ? Integer.valueOf(ea.Payment_Term_After_Days__c): 0);
                    Integer ls =0;
                    for(Integer i=0; i<totalCashAllocationRecords; i++){
                        Decimal cashAmount = 0;
                        Integer x = 1;
                        while(x <=Integer.valueOf(ea.Payment_Frequency__c)){
                            if(ls<explToInsert.size()){
                                cashAmount = cashAmount + explToInsert[ls].Forecast_Amount__c;
                            }
                            ls++;
                            if(x == Integer.valueOf(ea.Payment_Frequency__c)){
                                break;
                            }
                            else{
                                x++;
                            }
                        }
                        Date futureDatesforCash=cashDate.addMonths((i*Integer.valueOf(ea.Payment_Frequency__c)));
                        String monthStr = PlaceCPM_Utility.getMonthString(futureDatesforCash.month());
                        String cashRecId = cfNameToIdMap.get(monthStr+' '+futureDatesforCash.year());
                        Expense_Cash_Allocation__c eca = new Expense_Cash_Allocation__c();
                        if(isRecordTypeId){
                            eca.RecordTypeId = cashNonWageRecTypeId;
                        }
                        if(isExpenseDetail){
                            eca.Expense_Detail__c = ea.Id;
                        }
                        if(isCashForecast){
                            eca.Cash_Forecast__c=cashRecId;
                        }
                        if(isExpenseAccount){
                            eca.Expense_Account__c=ea.Expense_Account__c;
                        }
                        if(isCashDate){
                            eca.Cash_Date__c=futureDatesforCash;
                        }
                        if(isType){
                            eca.Type__c = CONSTANT.CASH_AND_PL_TYPE_EXPENSE_ACCOUNT;
                        }
                        if(isForecastAmount){
                            eca.Forecast_Amount__c = cashAmount;
                        }
                        if(isGLCode){
                            eca.GL_Code__c = ea.GL_Account_Id__c;
                        }
                        expcashToInsert.add(eca);
                    }
                }
            }
        }
        
        if(explToInsert.size()>0 && Schema.sObjectType.Expense_PL_Allocation__c.isCreateable()){
            insert explToInsert;
        }
        if(expcashToInsert.size()>0 && Schema.sObjectType.Expense_Cash_Allocation__c.isCreateable()){
            insert expcashToInsert;
        }
    }
    
    private static Expense_PL_Allocation__c createPandLAllocation(String expAccId,String expDelId, String GLCode, Decimal forecastAmt, String PLId){
        Expense_PL_Allocation__c expl = new Expense_PL_Allocation__c();
        if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.EXPENSE_PL_ALLOCATION_OBJECT,'Expense_Account__c',Constant.ACTION_TYPE_INSERT)){
            expl.Expense_Account__c = expAccId;
        }
        if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.EXPENSE_PL_ALLOCATION_OBJECT,'Expense_Detail__c',Constant.ACTION_TYPE_INSERT)){
            expl.Expense_Detail__c = expDelId;
        }
        if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.EXPENSE_PL_ALLOCATION_OBJECT,'GL_Code__c',Constant.ACTION_TYPE_INSERT)){
            expl.GL_Code__c = GLCode;
        }
        if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.EXPENSE_PL_ALLOCATION_OBJECT,'Forecast_Amount__c',Constant.ACTION_TYPE_INSERT)){
            expl.Forecast_Amount__c = forecastAmt;
        }
        if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.EXPENSE_PL_ALLOCATION_OBJECT,'P_L__c',Constant.ACTION_TYPE_INSERT)){
            expl.P_L__c = PLId;
        }
        return expl;
    }


    public Class ExpenseDetailWrapper implements Comparable {
        public Expense_Detail__c expDet; 
        public ExpenseDetailWrapper(Expense_Detail__c newExp){
            expDet = newExp;
        }
        public Integer compareTo(Object compareTo) {
            ExpenseDetailWrapper compareToCompensation = (ExpenseDetailWrapper)compareTo;
            if (expDet.Start_Date__c == compareToCompensation.expDet.Start_Date__c) return 0;
            if (expDet.Start_Date__c > compareToCompensation.expDet.Start_Date__c) return 1;
            return -1;        
        }
    }
}
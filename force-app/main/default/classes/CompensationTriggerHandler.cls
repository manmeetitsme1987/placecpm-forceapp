/*
* Description  : Whenever a compensation is created this class creates wages as per the base pay schedule
* Date Created : 10th May 2019
* Change 1 : 1 July 19 | Namita | PCPM-184		
  Change 2 : 4 July | Namita |  PCPM-247		
*/

public with sharing class CompensationTriggerHandler implements CommonTriggerHandler{

    static Decimal previousWageAmount, previousBonusAmount=0, daysForPreviousSalary, bonusAmountValue = 0, bonusValue=0, wageAmount ;
    static Boolean payBonus, firstWage, runOnceOnly = True, addPreBonusAmount = False, runOnce = True, runUpdate = True;
    static Date cashdate, previousCashDate;
    static Integer bonusCount=0;
    public static Map<String,Compensation__c> mapEmployeeLastCompensation = new Map<String,Compensation__c>();
    public static Map<String,Compensation__c> mapEmployeeIdLatestCompensation = new Map<String,Compensation__c>();
    public static Map<String,List<Quota__c>> mapEmployeeQuota = new Map<String,List<Quota__c>>();
    public static Map<String,Compensation__c> mapCompensationWithRelationshipData = new Map<String,Compensation__c>();
    public static Map<String,Bonus_Plan__c> mapBonusIdBonusPlan = new Map<String,Bonus_Plan__c>();
    static Integer forecastMonth = PlaceCPM_Utility.assumptionForecastDuration;
    
    static Decimal quotaPercentage = PlaceCPM_Utility.assumptionForecastQuota;
    static Integer hoursPerDayAssumption = PlaceCPM_Utility.assumptionHoursPerDay;
	public static Boolean isWagesFields = false, isExpenseAccount = false;
    static{
        if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.WAGES_OBJECT,'Compensation__c, Employer_Tax__c, Bonus_Per_Wage__c, P_L_Date__c, Cash_Date__c, Employee_Number__c, Wage_Amount__c, Bonus_Amount__c',Constant.ACTION_TYPE_INSERT)){
            isWagesFields = true;
        }
        if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.WAGES_OBJECT,'Expense_Account__c',Constant.ACTION_TYPE_INSERT)){
            isExpenseAccount = true;
        }
    }
    
    public void BeforeInsert(List<SObject> newItems){
        runUpdate = True;
        manageCompensation((List<Compensation__c>)newItems, null);
        checkCommissionPlanForEmployee((List<Compensation__c>)newItems);
        checkStartDateAndEndDate((List<Compensation__c>)newItems);
        
    }

    public void BeforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems){
        
    }

    public void BeforeDelete(Map<Id, SObject> oldItems){
        deleteWageOnCompensationDeletion((Map<Id,Compensation__c>) oldItems);
        checkStartDateAndEndDateOnDelete((Map<Id,Compensation__c>) oldItems);
    }

    public void AfterInsert(Map<Id, SObject> newItems){
        prepareMapCompensationWithRelationshipData((List<Compensation__c>)newItems.values());
        aterInsertcalculateWagesAndBonus((List<Compensation__c>)newItems.values());
        autoPopulatePaymentDate((List<Compensation__c>)newItems.values());
    }

    public void afterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems){
            if(runUpdate){
            prepareMapCompensationWithRelationshipData((List<Compensation__c>) newItems.values());
            updateCompensation((List<Compensation__c>) newItems.values(),(Map<Id,Compensation__c>) oldItems, (Map<String,Compensation__c>) mapEmployeeIdLatestCompensation);
            }
        }
        
    public void AfterDelete(Map<Id, SObject> oldItems){
        
    }

    public void AfterUndelete(Map<Id, SObject> oldItems){
        
    }

    public Boolean IsDisabled(){
        return False;
    }

    /*
        * This method will check whether there is any quota associated to compensation employee when bonus plan is Accelerator Bonus
        * @parameter newCompensationList, List of new Compensation which are getting inserted
        * @returns Void
    */
        public static void checkCommissionPlanForEmployee(list<Compensation__c> newCompensationList){
        Set<String> setBonusPlanId = new Set<String>();
        for(Compensation__c com : newCompensationList){
                setBonusPlanId.add(com.Bonus_Plan__c);
        }
        if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.BONUS_PLAN_OBJECT,'Base_Amount__c',Constant.ACTION_TYPE_ACCESS)){    
            for(Bonus_Plan__c bonusPlan : [Select RecordType.DeveloperName,Base_Amount__c from Bonus_Plan__c where Id IN : setBonusPlanId]){
                    mapBonusIdBonusPlan.put(bonusPlan.Id, bonusPlan);
            }
        }    
        for(Compensation__c com : newCompensationList){
            if((!mapBonusIdBonusPlan.isEmpty()) &&  mapBonusIdBonusPlan.get(com.Bonus_Plan__c).recordType.DeveloperName == CONSTANT.BONUS_PLAN_ACCELERATOR_BONUS_RT  && mapEmployeeQuota.isEmpty()){
                com.addError(System.Label.No_commission_plan_is_asscoiated_with_this_compensation);
            }
        }
    }

    /*
        * This method will prepare a map which contains all the information of Compensation and its parent information
        * @parameter newCompensationList, List of new Compensation which are getting inserted
        * @returns Void
    */
    public static void prepareMapCompensationWithRelationshipData(list<Compensation__c> newCompensationList){
        
        if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.COMPENSATION_OBJECT,'Start_Date__c, End_Date__c,'+
                                        'Employee__c, Base_Pay_Schedule__c, Bonus_Plan__c,Hourly_Rate__c,Hours_Per_day__c,'+
                                        'Monthly_Base_Salary__c, Bonus_Percentage__c,Tax_Percentage_on_Location__c,'+ 
                                        'Bonus_Pay_Schedule__c',Constant.ACTION_TYPE_ACCESS) &&
           PlaceCPM_Utility.checkAccessiblityOfFields(Constant.LOCATION_OBJECT,'tax__c,',Constant.ACTION_TYPE_ACCESS) &&
           PlaceCPM_Utility.checkAccessiblityOfFields(Constant.EMPLOYEE_OBJECT,'Employee_End_Date__c,Expense_Account__c,Employee_Type__c',Constant.ACTION_TYPE_ACCESS)
          ){
            for(Compensation__c com : [Select Start_Date__c, End_Date__c,
                                        Employee__r.location__r.tax__c,RecordType.DeveloperName,Employee__r.Employee_End_Date__c,Employee__r.RecordType.DeveloperName,
                                        Employee__c, Base_Pay_Schedule__c, Bonus_Plan__c,Employee__r.Expense_Account__c,Hourly_Rate__c,Hours_Per_day__c,
                                        Monthly_Base_Salary__c, Bonus_Percentage__c,Tax_Percentage_on_Location__c,Employee__r.Employee_Type__c, 
                                        Bonus_Pay_Schedule__c from Compensation__c where Id IN :newCompensationList]){
                    mapCompensationWithRelationshipData.put(com.Id, com); 
            }
        }    
    }

    /*
        * This method will prepare a map which contains all the information of Compensation and its parent information
        * @parameter newCompensationList, List of new Compensation which are getting inserted
        * @parameter oldItems, List of Compensation Id and old Compensation Record
        * @returns Void
    */
    public static void autoPopulatePaymentDate(list<Compensation__c> newCompensationList){
        List<Compensation__c> listComToBeUpdated = new List<Compensation__c>();
        Set<Compensation__c> setCompensation = new Set<Compensation__c>();
        Map<Compensation__c, String> mapCompensationExpenseAccount = new Map<Compensation__c, String>();
        Map<String, Expense_Detail__c> mapExpenseAccountExpenseDetail = new Map<String, Expense_Detail__c>();
        
        for(Compensation__c com : mapCompensationWithRelationshipData.values()){
            mapCompensationExpenseAccount.put(com, com.Employee__r.Expense_Account__c);
        }
        
        if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.EXPENSE_DETAIL_OBJECT,'Id, Invoice_Date__c, Payment_Term_After_Days__c',Constant.ACTION_TYPE_ACCESS)){
            for(Expense_Account__c ea : [Select Id, (Select Id, Invoice_Date__c, Payment_Term_After_Days__c 
                                                from expense_details__r 
                                                ORDER BY Start_Date__c DESC LIMIT 1) 
                                                from Expense_Account__c 
                                                where id IN : mapCompensationExpenseAccount.values()]){
                for(Expense_Detail__c ed : ea.expense_details__r){
                    mapExpenseAccountExpenseDetail.put(ea.id, ed);
                }
            }
        }
        Boolean isPaymentDate = false;
        if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.COMPENSATION_OBJECT,'Payment_Date__c',Constant.ACTION_TYPE_UPDATE)){
            isPaymentDate = true;
        }
        for(Compensation__c com : mapCompensationExpenseAccount.keyset()){
            String ea = mapCompensationExpenseAccount.get(com);
                if(com.Employee__r.Employee_Type__c != Null && com.Employee__r.Employee_Type__c == CONSTANT.EMPLOYEE_TYPE_HOURLY_CONTRACTORS && com.Employee__r.Expense_Account__c != Null){
                    
                    if(isPaymentDate){
                        com.Payment_Date__c = mapExpenseAccountExpenseDetail.get(ea).Invoice_Date__c.addDays(Integer.valueOf(mapExpenseAccountExpenseDetail.get(ea).Payment_Term_After_Days__c));
                        setCompensation.add(com);
                    }
                }
                //PCPM-576
               /* if(com.Employee__r.Employee_End_Date__c != Null && com.End_Date__c == Null){
                    if(Schema.sObjectType.Compensation__c.fields.End_Date__c.isUpdateable()){
                        com.End_Date__c = com.Employee__r.Employee_End_Date__c;
                        setCompensation.add(com);
                    }
                }*/
           }
        
        listComToBeUpdated.addAll(setCompensation);
        runUpdate = False ;
        PlaceCPM_Utility.updateRecords(listComToBeUpdated, CONSTANT.COMPENSATION_OBJECT, false); //PCPM-520
    }

    /*
        * This method will calculate the bonus of employee and also calculate when the bonus has to be paid
        * @parameter bonusCountVal, this value indicates after how many wages the bonus has to be paid
        * @parameter bonusPercentage, the percentage of bonus on Bonus Plan Field
        * @parameter endDate, end date of compensation
        * @returns Void
    */
    public static void calculateBonusCount(Integer bonusCountVal,Decimal bonusPercentage, Date endDate, Date cashDateValue, String bonusPayScheduleValue, String basePayScheduleValue){
        
        bonusValue = (bonusPercentage * wageAmount);
        bonusAmountValue = bonusAmountValue + bonusValue;
        bonusCount = bonusCount + 1;
        payBonus = False;
        
        if(basePayScheduleValue == CONSTANT.BASE_PAY_SCHEDULE_WEEKLY || basePayScheduleValue == CONSTANT.BASE_PAY_SCHEDULE_BI_WEEKLY){ //520
            if(bonusCount == bonusCountVal || cashDate >= endDate){
                payBonus = True;
            }
        }
        
        if(bonusPayScheduleValue == '1'){
            if(basePayScheduleValue == CONSTANT.BASE_PAY_SCHEDULE_MONTHLY){//PCPM-520
                payBonus = True;
            }else if(basePayScheduleValue == CONSTANT.BASE_PAY_SCHEDULE_SEMI_MONTHLY){//PCPM-520
                if(cashDateValue.day() > 16 || cashDate >= endDate){
                    payBonus = True;
                }
            }
        }
        else if(bonusPayScheduleValue == '3' && (cashDateValue.month() == 3 || cashDateValue.month() == 6 || cashDateValue.month() == 9 || cashDateValue.month() == 12)){
            if(basePayScheduleValue == CONSTANT.BASE_PAY_SCHEDULE_MONTHLY){//PCPM-520
                payBonus = True;
            }else if(basePayScheduleValue == CONSTANT.BASE_PAY_SCHEDULE_SEMI_MONTHLY){//PCPM-520
                if(cashDateValue.day() > 16 || cashDate >= endDate){
                    payBonus = True;
                }
            }
        }else if(bonusPayScheduleValue == '6' && (cashDateValue.month() == 6 || cashDateValue.month() == 12)){
               if(basePayScheduleValue == CONSTANT.BASE_PAY_SCHEDULE_MONTHLY){//PCPM-520
                payBonus = True;
            }else if(basePayScheduleValue == CONSTANT.BASE_PAY_SCHEDULE_SEMI_MONTHLY){//PCPM-520
                if(cashDateValue.day() > 16 || cashDate >= endDate){
                    payBonus = True;
                }
            }
        }else if(bonusPayScheduleValue == '12' && cashDateValue.month() == 12){
                if(basePayScheduleValue == CONSTANT.BASE_PAY_SCHEDULE_MONTHLY){//PCPM-520
                payBonus = True;
            }else if(basePayScheduleValue == CONSTANT.BASE_PAY_SCHEDULE_SEMI_MONTHLY){//PCPM-520
                if(cashDateValue.day() > 16 || cashDate >= endDate){
                    payBonus = True;
                }
            }
        }
    }

    /*
        * This method will delete wages(if required) and then call wageAndBonusCalculation method to create new wage record(if required)
        * @parameter newCompensationList, List of Compensation
        * @parameter oldMap, map of Compensation Id and old data (Data before update)
        * @parameter mapEmployeeIdLatestCompensation, Map of Compensation Id and latest compensation
        * @returns map Employee Wrapper which contains last wage of compensation and pre bonus value
    */
    public static Map<String, EmployeeWrapper> updateCompensation(list<Compensation__c> newCompensationList,
                                        Map<Id, Compensation__c> oldMap, Map<String, Compensation__c> mapEmployeeIdLatestCompensation){
        Boolean enterUpdateCom = True;                                    
        if(forecastMonth == 0){
            enterUpdateCom = False;
            }   
        if(enterUpdateCom){ 
        Map<String, EmployeeWrapper> mapEmpoyeeWrapper = new Map<String,EmployeeWrapper>();  
        List<Wages__c> wageListToBeInserted = new List<Wages__c>();                                   
        Boolean isInsert = oldMap == null;
        Boolean putNull = True;
        Map<String, List<Wages__c>> mapEmployeeIdWagesList = new Map<String, List<Wages__c>>();
        Map<String, List<Compensation__c>> mapEmployeeIdListCompensation = new Map<String, List<Compensation__c>>();
        Map<String, List<Wages__c>> mapCompIdListWages = new Map<String, List<Wages__c>>();
        List<Wages__c> wageToBeDeleted = new List<Wages__c>();
        List<Wages__c> wagePreBonusUpdate = new List<Wages__c>();
        for(Compensation__c com : newCompensationList){
            if(!mapEmployeeIdListCompensation.containskey(com.Employee__c)){
                mapEmployeeIdListCompensation.put(com.Employee__c, new List<Compensation__c>());
            }
            mapEmployeeIdListCompensation.get(com.Employee__c).add(com);
        }
        //fetching all the wages
        
        if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.WAGES_OBJECT,'Id,Employee_Number__c,Cash_Date__c,Bonus_Per_Wage__c,Bonus_Amount__c, Compensation__c',Constant.ACTION_TYPE_ACCESS)){
            for(Wages__c wage : [Select Id,Employee_Number__c,Cash_Date__c,Bonus_Per_Wage__c,Bonus_Amount__c, Compensation__c  
                                from Wages__c 
                                where Employee_Number__c IN: mapEmployeeIdListCompensation.keySet() 
                                Order by Cash_Date__c DESC]){
                if(!mapCompIdListWages.containskey(wage.Compensation__c)){
                    mapCompIdListWages.put(wage.Compensation__c, new List<Wages__c>());
                }
                mapCompIdListWages.get(wage.Compensation__c).add(wage);
            }
        }    
        if(runOnce){
            runOnce = False;
            for(String employeeId : mapEmployeeIdListCompensation.keySet()){
                mapEmployeeIdWagesList.put(employeeId, new List<Wages__c>());
                Compensation__c comp = mapEmployeeIdLatestCompensation.get(employeeId);
                for(Compensation__c com : mapEmployeeIdListCompensation.get(employeeId)){
                    if(mapCompIdListWages.containsKey(com.id) && mapCompIdListWages.get(com.id).size() > 0){
                        for(Wages__c wageRec : mapCompIdListWages.get(com.id)){
                            if(com.Start_Date__c >= wageRec.Cash_Date__c && wageRec.Cash_Date__c <= System.today()){
                                com.addError(System.Label.You_cannot_set_start_date_greater_than_wage_payout_date);
                            }
                            else if(com.End_Date__c <= wageRec.Cash_Date__c && wageRec.Cash_Date__c <= System.today()){
                                com.addError(System.Label.You_cannot_set_End_Date_greater_wage_payout_date);
                            }
                            //all wages of a compensation
                            if(forecastMonth == null) {
                                forecastMonth = 0;
                            }
                            //all wages of a comp
                            if((!isInsert && (com.Monthly_Base_Salary__c != oldmap.get(com.id).Monthly_Base_Salary__c || 
                                com.Base_Pay_Schedule__c != oldmap.get(com.id).Base_Pay_Schedule__c && wageRec.Cash_Date__c >= System.today() || 
                                com.Bonus_Percentage__c != oldmap.get(com.id).Bonus_Percentage__c && wageRec.Cash_Date__c >= System.today() || 
                                (com.Start_Date__c != oldmap.get(com.id).Start_Date__c && wageRec.Cash_Date__c >= System.today()) ||
                                (com.Bonus_Pay_Schedule__c != oldmap.get(com.id).Bonus_Pay_Schedule__c && wageRec.Cash_Date__c >= System.today())||              
                                (com.End_Date__c != oldmap.get(com.id).End_Date__c && (com.End_Date__c != null && wageRec.Cash_Date__c > com.End_Date__c || wageRec.Cash_Date__c > com.Start_Date__c.addMonths(forecastMonth - 1)))
                                )) || ( isInsert && wageRec.Cash_Date__c >= comp.Start_Date__c)){
                                    wageToBeDeleted.add(wageRec);
                            }else{
                                putnull = False;
                                mapEmployeeIdWagesList.get(employeeId).add(wageRec); 
                            }
                        }
                        if(putnull){
                            mapEmployeeIdWagesList.put(employeeId, null);
                        }
                    }
                }
            }
        }
        // PCPM-570
        //PlaceCPM_Utility.deleteRecords(wageToBeDeleted, CONSTANT.WAGES_OBJECT, false); //PCPM-520
        //Left this intentionally because we are not giving delete permission to cpm users
        if(wageToBeDeleted.size() > 0){
            delete wageToBeDeleted;
        }
        
        if(!mapEmployeeIdWagesList.isEmpty()){
            for(String employeeId : mapEmployeeIdWagesList.keyset()){
                if(mapEmployeeIdWagesList.get(employeeId) != null){
                    Double preBonus = 0;
                    mapEmpoyeeWrapper.put(employeeId,new EmployeeWrapper());
                    Integer countRecord = 0;
                    for(Wages__c wage : mapEmployeeIdWagesList.get(employeeId)){
                        if(countRecord == 0){
                            mapEmpoyeeWrapper.get(employeeId).lastWageRecord = wage;
                        }
                        countRecord++;
                        if(wage.Bonus_Amount__c == 0){
                            preBonus += wage.Bonus_Per_Wage__c;
                        }else{
                            break;
                        }
                    }
                    mapEmpoyeeWrapper.get(employeeId).preBonus = preBonus;
                    mapEmpoyeeWrapper.get(employeeId).lastWageRecord.Bonus_Amount__c = preBonus;
                }
                }
            }
        for(String employeeId : mapEmpoyeeWrapper.keyset()){
            if(mapEmpoyeeWrapper.get(employeeId).preBonus != 0){
                wagePreBonusUpdate.add(mapEmpoyeeWrapper.get(employeeId).lastWageRecord);
            }
        }
        
        PlaceCPM_Utility.updateRecords(wagePreBonusUpdate, CONSTANT.WAGES_OBJECT, false); //PCPM-520
        if(oldMap != null){
            manageCompensation(newCompensationList, mapEmployeeIdListCompensation.keySet());
            for(Compensation__c com: newCompensationList){
                
                Wages__c wageRecord;
                if(!mapEmpoyeeWrapper.isEmpty()){
                        wageRecord = mapEmpoyeeWrapper.get(com.Employee__c).lastWageRecord;
                }
                
                if(com.End_Date__c == Null && forecastMonth == NUll){
                        com.addError(System.Label.Please_provide_Forecasted_Duration_value_in_Assumption);
                        continue;
                }
                
                if(com.Start_Date__c != oldmap.get(com.id).Start_Date__c){
                    wageListToBeInserted.addAll(wageAndBonusCalculation(com, com.Start_Date__c, mapEmpoyeeWrapper));
                }else if(com.End_Date__c != oldmap.get(com.id).End_Date__c){
                    
                    /*if(oldMap.get(com.Id).End_Date__c < com.End_Date__c){
                        wageListToBeInserted.addAll(wageAndBonusCalculation(com, (oldMap.get(com.Id).End_Date__c).addDays(1), mapEmpoyeeWrapper));
                    }
                    else{ */
                        if(wageRecord == Null){
                            wageListToBeInserted.addAll(wageAndBonusCalculation(com, com.Start_Date__c, mapEmpoyeeWrapper));
                        }else{
                            wageListToBeInserted.addAll(wageAndBonusCalculation(com,wageRecord.Cash_Date__c.addDays(1), mapEmpoyeeWrapper));
                        }
                    //}
                }else if(com.Base_Pay_Schedule__c != oldmap.get(com.id).Base_Pay_Schedule__c || com.Bonus_Pay_Schedule__c != oldmap.get(com.id).Bonus_Pay_Schedule__c || com.Monthly_Base_Salary__c != oldmap.get(com.id).Monthly_Base_Salary__c ){ 
                    if(putnull){
                        wageListToBeInserted.addAll(wageAndBonusCalculation(com, com.Start_Date__c, mapEmpoyeeWrapper));
                    }else{
                        wageListToBeInserted.addAll(wageAndBonusCalculation(com, wageRecord.Cash_Date__c.addDays(1), mapEmpoyeeWrapper));
                    }
                    
                }
            }
            //PCPM-570
            //PlaceCPM_Utility.upsertRecords(wageListToBeInserted, CONSTANT.WAGES_OBJECT, false); //PCPM-520
            PlaceCPM_Utility.insertRecords(wageListToBeInserted, CONSTANT.WAGES_OBJECT, false);
        } 
        return mapEmpoyeeWrapper;
        }
        return null;
    }

    /*
        * This method will insert wages after the compensation has inserted
        * @parameter newCompensationList, List of new Compensation which are getting inserted
        * @returns Void
    */
    public static void aterInsertcalculateWagesAndBonus(list<Compensation__c> newCompensationList){
        Boolean enterBlock = True;
        
        Map<Id,Schema.RecordTypeInfo> rtMapById = Schema.SObjectType.Compensation__c.getRecordTypeInfosById();
        
        if(forecastMonth == 0){
            enterBlock = False;
            }  
        Set<String> setComId = new Set<String>();
        List<Compensation__c> toBeUpdatedList = new List<Compensation__c>();
        List<Wages__c> wageListToBeInserted = new List<Wages__c>();
        Map<String, EmployeeWrapper> employeeWrapper = new Map<String, EmployeeWrapper>();
        for(Compensation__c com : newCompensationList){
            Schema.RecordTypeInfo rtById = rtMapById.get(com.recordTypeId);
            if(com.End_Date__c == NUll && forecastMonth == Null){
                    setComId.add(com.Id);
                    com.addError(System.Label.Please_provide_Forecasted_Duration_value_in_Assumption);
                    continue;
            }
            if(!mapEmployeeLastCompensation.isEmpty() && mapEmployeeLastCompensation.containsKey(com.Employee__c) && 
                                                        mapEmployeeLastCompensation.get(com.Employee__c).End_Date__c >= com.Start_Date__c &&
                                                        ((com.Monthly_Base_Salary__c != 0 && rtById.getDeveloperName() == CONSTANT.COMPENSATION_RECORD_TYPE_SALES_EMPLOYEE) || 
                                                        (rtById.getDeveloperName() == CONSTANT.COMPENSATION_RECORD_TYPE_OPS_EMPLOYEE && 
                                                        ((com.Hourly_Rate__c != Null || com.Monthly_Base_Salary__c != Null) && 
                                                        (com.Hourly_Rate__c != 0 || com.Monthly_Base_Salary__c != 0))))){
                toBeUpdatedList.add(mapEmployeeLastCompensation.get(com.Employee__c));
            }
            mapEmployeeIdLatestCompensation.put(com.Employee__c, com);
        }
        if(toBeUpdatedList.size() > 0){
            employeeWrapper = updateCompensation(toBeUpdatedList, null, mapEmployeeIdLatestCompensation);
        }
        
        for(Compensation__c com : newCompensationList){
            Schema.RecordTypeInfo rtById = rtMapById.get(com.recordTypeId);
            if((!setComId.contains(com.Id)) && ((com.Monthly_Base_Salary__c != 0 && rtById.getDeveloperName() == CONSTANT.COMPENSATION_RECORD_TYPE_SALES_EMPLOYEE) || 
                                                        (rtById.getDeveloperName() == CONSTANT.COMPENSATION_RECORD_TYPE_OPS_EMPLOYEE && 
                                                        ((com.Hourly_Rate__c != Null || com.Monthly_Base_Salary__c != Null) && 
                                                        (com.Hourly_Rate__c != 0 || com.Monthly_Base_Salary__c != 0)))) && enterBlock){
                wageListToBeInserted.addAll(wageAndBonusCalculation(com, com.Start_Date__c, employeeWrapper)); 
            }
        }
        //PCPM-570
        //PlaceCPM_Utility.upsertRecords(wageListToBeInserted, CONSTANT.WAGES_OBJECT, false); //PCPM-520
        PlaceCPM_Utility.insertRecords(wageListToBeInserted, CONSTANT.WAGES_OBJECT, false);
    } 

    /*
        * This method will calculate Wages and Bonus of employee
        * @parameter compen, List of new Compensation
        * @parameter startDateVal, Start Date for wage creation 
        * @parameter employeeWrapper, map which gives previous bonus (if any) and last wage record of compensation
        * @returns List of Wages
    */
    public static List<Wages__c> wageAndBonusCalculation(Compensation__c compen,
                                                Date startDateVal,
                                                Map<String, EmployeeWrapper> employeeWrapper){
        Map<Id,Schema.RecordTypeInfo> rtMapById = Schema.SObjectType.Compensation__c.getRecordTypeInfosById();
        Schema.RecordTypeInfo rtById = rtMapById.get(compen.recordTypeId);
        List<Wages__c> wagesList = new List<Wages__c>();                                            
        Compensation__c lastCompensation = (mapEmployeeLastCompensation != NULL && mapEmployeeLastCompensation.containskey(compen.Employee__c)) ? 
                                            mapEmployeeLastCompensation.get(compen.Employee__c) : null;
        Decimal hoursPerDay, grossWageAmount, lastCompHoursPerDay;
        Integer payDays;
        previousCashDate = null;
        Boolean previousWageCalculate = True, flagVal;
        Wages__c wageRec;
        Date lastDayOfMonth;
        compen = mapCompensationWithRelationshipData.get(compen.id);
        firstWage = False;
        hoursPerDay = (compen.Hours_Per_day__c == Null) ? hoursPerDayAssumption : compen.Hours_Per_day__c;
        if(runOnceOnly){
        if(lastCompensation != Null){
            runOnceOnly = False;
            lastCompHoursPerDay = (lastCompensation.Hours_Per_day__c == Null) ? hoursPerDayAssumption : lastCompensation.Hours_Per_day__c;
            if(lastCompensation.End_Date__c >= startDateVal && (!employeeWrapper.isEmpty() && employeeWrapper.containsKey(compen.Employee__c))){
                daysForPreviousSalary  = (lastCompensation.Base_Pay_Schedule__c == CONSTANT.BASE_PAY_SCHEDULE_WEEKLY) ? (employeeWrapper.get(compen.Employee__c).lastWageRecord.Cash_Date__c.daysBetween(startDateVal)) : (employeeWrapper.get(compen.Employee__c).lastWageRecord.Cash_Date__c.daysBetween(startDateVal)-1);
            }else if(lastCompensation.End_Date__c >= startDateVal && employeeWrapper.isEmpty()){
                daysForPreviousSalary = (lastCompensation.Base_Pay_Schedule__c == CONSTANT.BASE_PAY_SCHEDULE_WEEKLY) ? ((lastCompensation.Start_Date__c).daysBetween(startDateVal))+1 : ((lastCompensation.Start_Date__c).daysBetween(startDateVal));
            }
            }
        }
        //PCPM-566
        Date endDateValToPassVal = Date.newInstance(System.today().year(),System.today().month(),compen.Start_Date__c.day());
        Date endDateVal;
        Date endDateValToPass;
        if(compen.End_Date__c != null) {
            if(compen.End_Date__c > System.today().addMonths(forecastMonth-1)){
                if(compen.Start_Date__c.month() > System.today().month()){
                    endDateVal = compen.Start_Date__c.addMonths(forecastMonth);
                    endDateValToPass = compen.Start_Date__c.addMonths(forecastMonth - 1);
                }else{
                    endDateVal = endDateValToPassVal.addMonths(forecastMonth);
                	endDateValToPass = endDateValToPassVal.addMonths(forecastMonth - 1);
                }
            }else{
                endDateVal = compen.End_Date__c;
                endDateValToPass = compen.End_Date__c;
            }
                                                  		
        }else if(compen.End_Date__c == null){
            if(compen.Start_Date__c.month() > System.today().month()){
                endDateVal = compen.Start_Date__c.addMonths(forecastMonth);
                endDateValToPass = compen.Start_Date__c.addMonths(forecastMonth - 1);
            }else{
                endDateVal = endDateValToPassVal.addMonths(forecastMonth);
                endDateValToPass = endDateValToPassVal.addMonths(forecastMonth - 1);
            }
        }
        
        String bonusPayScheduleVal = compen.Bonus_Pay_Schedule__c;
        if(compen.Base_Pay_Schedule__c == CONSTANT.BASE_PAY_SCHEDULE_WEEKLY || compen.Base_Pay_Schedule__c == CONSTANT.BASE_PAY_SCHEDULE_BI_WEEKLY){
            endDateValToPass =   endDateVal;
        }
        //Calculation of numnber of wage record to be created
        Integer totalSalaryAllocationRecords = totalNumberOfWagesToBeCreated(compen.Base_Pay_Schedule__c, startDateVal, endDateValToPass);
        for(Integer i = 0;i < totalSalaryAllocationRecords;i++){
            if(compen.Base_Pay_Schedule__c == CONSTANT.BASE_PAY_SCHEDULE_WEEKLY){
                calculateCashDateAndPreBonusAmount(7, compen, lastCompensation);
            }
            if(compen.Base_Pay_Schedule__c == CONSTANT.BASE_PAY_SCHEDULE_BI_WEEKLY){
                calculateCashDateAndPreBonusAmount(14, compen, lastCompensation);
            }
            if(compen.Base_Pay_Schedule__c == CONSTANT.BASE_PAY_SCHEDULE_MONTHLY){
                
                Decimal perDayWage;
                if(firstWage == False){
                    Integer numberOfDays = Date.daysInMonth(startDateVal.year(), startDateVal.month());
                    lastDayOfMonth = Date.newInstance(startDateVal.year(), startDateVal.month(), numberOfDays);
                    cashDate = lastDayOfMonth;
                    firstWage = True; 
                    payDays = startDateVal.daysBetween(lastDayOfMonth)+1;
                    if(cashDate  >= endDateVal){
                        previousCashDate = startDateVal;
                        payDays = startDateVal.daysBetween(endDateVal)+1;
                    }else{
                        previousCashDate = cashDate;
                    }
                }       
                else{
                    Integer yeaval = cashDate.addMonths(1).year();
                    Integer numberOfDays = Date.daysInMonth(cashDate.addMonths(1).year(), cashDate.addMonths(1).month());
                    lastDayOfMonth = Date.newInstance(yeaVal,cashDate.addMonths(1).month(), numberOfDays);
                    cashDate = lastDayOfMonth;
                    Integer noOfDaysInMonth = Date.daysInMonth(cashDate.year(), cashDate.month());
                    payDays =  noOfDaysInMonth;
                    if(cashDate  > endDateVal){
                        payDays = previousCashDate.daysBetween(endDateVal);
                    }
                }    
                Integer noOfDaysInMonth = Date.daysInMonth(cashDate.year(), cashDate.month());
                if(compen.Monthly_Base_Salary__c != NUll){
                    perDayWage = compen.Monthly_Base_Salary__c/noOfDaysInMonth;
                }
                if(daysForPreviousSalary != null){
                    Decimal perDayPreviousWage;
                    if(lastCompensation.Monthly_Base_Salary__c != null){
                        perDayPreviousWage = lastCompensation.Monthly_Base_Salary__c/noOfDaysInMonth;
                    }
                    previousWageAmount = (rtById.getDeveloperName() == CONSTANT.COMPENSATION_RECORD_TYPE_OPS_EMPLOYEE && (compen.Employee__r.Employee_Type__c == CONSTANT.EMPLOYEE_TYPE_HOURLY_EMPLOYEE || compen.Employee__r.Employee_Type__c == CONSTANT.EMPLOYEE_TYPE_HOURLY_CONTRACTORS)) ? daysForPreviousSalary * (lastCompensation.Hourly_Rate__c * lastCompHoursPerDay) : (daysForPreviousSalary * perDayPreviousWage);
                    if(lastCompensation.Bonus_Percentage__c != null && previousWageAmount != null){
                        previousBonusAmount = lastCompensation.Bonus_Percentage__c * previousWageAmount;
                    }
                }
                wageAmount = (rtById.getDeveloperName() == CONSTANT.COMPENSATION_RECORD_TYPE_OPS_EMPLOYEE && (compen.Employee__r.Employee_Type__c == CONSTANT.EMPLOYEE_TYPE_HOURLY_EMPLOYEE || compen.Employee__r.Employee_Type__c == CONSTANT.EMPLOYEE_TYPE_HOURLY_CONTRACTORS)) ? payDays * (compen.Hourly_Rate__c * hoursPerDay) : payDays * perDayWage;
                if(previousCashDate == endDateVal){
                    wageAmount = (rtById.getDeveloperName() == CONSTANT.COMPENSATION_RECORD_TYPE_OPS_EMPLOYEE && (compen.Employee__r.Employee_Type__c == CONSTANT.EMPLOYEE_TYPE_HOURLY_EMPLOYEE || compen.Employee__r.Employee_Type__c == CONSTANT.EMPLOYEE_TYPE_HOURLY_CONTRACTORS)) ? (1 * (compen.Hourly_Rate__c * hoursPerDay)) : ( 1 * perDayWage);
                }
                previousCashDate = cashDate;
                if(compen.Bonus_Percentage__c != NULL && bonusPayScheduleVal != null){
                    If(previousBonusAmount != null && previousBonusAmount != 0){
                        bonusAmountValue = previousBonusAmount;
                    }
                    addPreBonusAmount = False;
                    calculateBonusCount(Integer.valueOf(bonusPayScheduleVal),compen.Bonus_Percentage__c,endDateVal, cashDate, compen.Bonus_Pay_Schedule__c, compen.Base_Pay_Schedule__c);
                }else{
                    bonusValue = 0;
                }
            } 
            if(compen.Base_Pay_Schedule__c == CONSTANT.BASE_PAY_SCHEDULE_SEMI_MONTHLY){
                
                Decimal perDayWage;
                Decimal semiMonthlyWage;
                if(firstWage == False){
                    flagVal = True;
                    Integer day = startDateVal.day();
                    if(day <= 15){
                        Date tempcashDate = date.newinstance(startDateVal.year(), startDateVal.month(), 15);
                        payDays = startDateVal.daysBetween(tempcashDate)+1;
                        Date myDate = date.newinstance(startDateVal.year(), startDateVal.month(), 15);
                        cashDate = myDate;
                        firstWage = True;
                        previousCashDate = (cashDate  >= endDateVal) ? startDateVal : cashDate.addDays(1);
                    }else {
                        Integer numberOfDays = Date.daysInMonth(startDateVal.year(), startDateVal.month());
                        Date tempcashDate = date.newinstance(startDateVal.year(), startDateVal.month(), numberOfDays);
                        payDays = startDateVal.daysBetween(tempcashDate)+1;
                        lastDayOfMonth = Date.newInstance(startDateVal.year(), startDateVal.month(), numberOfDays);
                        cashDate = lastDayOfMonth;
                        firstWage = True;
                        previousCashDate = (cashDate >= endDateVal) ? startDateVal : cashDate;
                    }
                }else{
                    if(previousCashDate.day() > 15 && previousCashDate.month() == 2 ){
                        Integer numberOfDays = Date.daysInMonth(previousCashDate.year(), previousCashDate.month());
                        cashDate = date.newinstance(previousCashDate.year(), previousCashDate.month(), numberOfDays);
                    }
                    else{
                        Date cashDateTemp = cashDate.addDays(15);
                        Integer day = cashDateTemp.day();
                        if(day <= 16){
                            Date myDate = date.newinstance(cashDateTemp.year(), cashDateTemp.month(), 15);
                            cashDate = myDate;
                        }else{
                            Integer numberOfDays = Date.daysInMonth(cashDateTemp.year(), cashDateTemp.month());
                            lastDayOfMonth = Date.newInstance(cashDateTemp.year(), cashDateTemp.month(), numberOfDays);
                            cashDate = lastDayOfMonth;
                        }
                        payDays = previousCashDate.daysBetween(cashDate)+1;
                    }
                }
                Integer noOfDaysInMonth = Date.daysInMonth(cashDate.year(), cashDate.month());
                Integer NumebrOfDayInYear =  Date.isLeapYear(compen.Start_Date__c.year())? 366 : 365;
                if(compen.Monthly_Base_Salary__c != Null){
                    perDayWage = (compen.Monthly_Base_Salary__c * 12) / NumebrOfDayInYear;
                    semiMonthlyWage = compen.Monthly_Base_Salary__c/2;
                    
                }
                
                wageAmount = (rtById.getDeveloperName() == CONSTANT.COMPENSATION_RECORD_TYPE_OPS_EMPLOYEE && (compen.Employee__r.Employee_Type__c == CONSTANT.EMPLOYEE_TYPE_HOURLY_EMPLOYEE || compen.Employee__r.Employee_Type__c == CONSTANT.EMPLOYEE_TYPE_HOURLY_CONTRACTORS)) ? (payDays * (compen.Hourly_Rate__c * hoursPerDay)) : ((payDays == 15 || payDays == 16) ? semiMonthlyWage : (perDayWage * payDays));
                
                if(daysForPreviousSalary != Null){
                    Decimal perDayPreviousWage;
                    if(lastCompensation.Monthly_Base_Salary__c != Null){
                        perDayPreviousWage = lastCompensation.Monthly_Base_Salary__c/noOfDaysInMonth;
                    }
                    previousWageAmount = (rtById.getDeveloperName() == CONSTANT.COMPENSATION_RECORD_TYPE_OPS_EMPLOYEE && (compen.Employee__r.Employee_Type__c == CONSTANT.EMPLOYEE_TYPE_HOURLY_EMPLOYEE || compen.Employee__r.Employee_Type__c == CONSTANT.EMPLOYEE_TYPE_HOURLY_CONTRACTORS)) ? daysForPreviousSalary * (lastCompensation.Hourly_Rate__c * lastCompHoursPerDay) : daysForPreviousSalary * perDayPreviousWage;
                    if(lastCompensation.Bonus_Percentage__c != null && previousWageAmount != null){
                        previousBonusAmount = lastCompensation.Bonus_Percentage__c * previousWageAmount;
                    }
                }
                if(flagVal == True){
                    wageAmount = (rtById.getDeveloperName() == CONSTANT.COMPENSATION_RECORD_TYPE_OPS_EMPLOYEE && (compen.Employee__r.Employee_Type__c == CONSTANT.EMPLOYEE_TYPE_HOURLY_EMPLOYEE || compen.Employee__r.Employee_Type__c == CONSTANT.EMPLOYEE_TYPE_HOURLY_CONTRACTORS)) ? payDays * (compen.Hourly_Rate__c * hoursPerDay) : ((payDays == 15 || payDays == 16) ? semiMonthlyWage : (perDayWage * payDays));
                    flagVal = False;
                }
                if(cashDate  >= endDateVal){
                    payDays = (previousCashDate.daysBetween(endDateVal)+1);
                    wageAmount = (rtById.getDeveloperName() == CONSTANT.COMPENSATION_RECORD_TYPE_OPS_EMPLOYEE && (compen.Employee__r.Employee_Type__c == CONSTANT.EMPLOYEE_TYPE_HOURLY_EMPLOYEE || compen.Employee__r.Employee_Type__c == CONSTANT.EMPLOYEE_TYPE_HOURLY_CONTRACTORS)) ? (payDays * (compen.Hourly_Rate__c * hoursPerDay)) : ((payDays == 15 || payDays == 16) ? semiMonthlyWage : (perDayWage * payDays));
                }

                previousCashDate = cashDate.addDays(1);
                if(compen.Bonus_Percentage__c != NULL && bonusPayScheduleVal != null){
                    If(previousBonusAmount != null && previousBonusAmount != 0){
                        bonusAmountValue = previousBonusAmount;
                    }
                    addPreBonusAmount = False;
                    calculateBonusCount(CONSTANT.mapMonthsCountBiWeekly.get(compen.Bonus_Pay_Schedule__c),compen.Bonus_Percentage__c,endDateVal, cashDate, compen.Bonus_Pay_Schedule__c, compen.Base_Pay_Schedule__c );
                }else{
                    bonusValue = 0;
                }
            } 
            
            if(previousWageCalculate == True && previousWageAmount != null){
                // PCPM-247
                //wageAmount = (previousWageAmount-previousBonusAmount) + wageAmount;
                wageAmount = previousWageAmount + wageAmount;
            }
            if(!mapBonusIdBonusPlan.isEmpty() && mapBonusIdBonusPlan.get(compen.Bonus_Plan__c).recordType.DeveloperName == CONSTANT.BONUS_PLAN_ACCELERATOR_BONUS_RT){
                grossWageAmount = wageAmount; // PCPM-247 | - ((quotaPercentage)/ (mapBonusIdBonusPlan.get(compen.Bonus_Plan__c).Base_Amount__c))*100;
            }
            Integer  numberOfDaysInCashDate = Date.daysInMonth(cashDate.year(), cashDate.month());
            Date PLDate = Date.newInstance(cashDate.year(), cashDate.month(), numberOfDaysInCashDate);
            //PCPM-520 - CONSTANT.EMPLOYEE_TYPE_SALARIED_EMPLOYEE ,CONSTANT.EMPLOYEE_RECORD_TYPE_SALES_EMPLOYEE
            String salesEmployeeRT = PlaceCPM_Utility.getCustomObjOrFieldName(CONSTANT.EMPLOYEE_RECORD_TYPE_SALES_EMPLOYEE);
            if(payBonus == True){
                if(isWagesFields){
                    if(!mapBonusIdBonusPlan.isEmpty() && mapBonusIdBonusPlan.get(compen.Bonus_Plan__c).recordType.DeveloperName == CONSTANT.BONUS_PLAN_ACCELERATOR_BONUS_RT){
                        if(compen.Employee__r.Expense_Account__c != Null && isExpenseAccount){
                            wageRec= new Wages__c(Compensation__c=compen.Id, Employer_Tax__c = (compen.Employee__r.Employee_Type__c == CONSTANT.EMPLOYEE_TYPE_SALARIED_EMPLOYEE || compen.Employee__r.RecordType.DeveloperName == salesEmployeeRT) ? compen.Employee__r.Location__r.Tax__c : 0 ,  Bonus_Per_Wage__c=bonusValue, P_L_Date__c =PLDate, Cash_Date__c= cashDate,Employee_Number__c = compen.Employee__c,Wage_Amount__c = grossWageAmount, Bonus_Amount__c = ((quotaPercentage)/ (mapBonusIdBonusPlan.get(compen.Bonus_Plan__c).Base_Amount__c))*100, Expense_Account__c = compen.Employee__r.Expense_Account__c);
                        }else{
                            wageRec= new Wages__c(Compensation__c=compen.Id, Employer_Tax__c = (compen.Employee__r.Employee_Type__c == CONSTANT.EMPLOYEE_TYPE_SALARIED_EMPLOYEE || compen.Employee__r.RecordType.DeveloperName == salesEmployeeRT) ? compen.Employee__r.Location__r.Tax__c : 0 , Bonus_Per_Wage__c=bonusValue, P_L_Date__c =PLDate, Cash_Date__c= cashDate,Employee_Number__c = compen.Employee__c,Wage_Amount__c = grossWageAmount, Bonus_Amount__c = ((quotaPercentage)/ (mapBonusIdBonusPlan.get(compen.Bonus_Plan__c).Base_Amount__c))*100);
                        }
                    }else{
                        if(compen.Employee__r.Expense_Account__c != Null && isExpenseAccount){
                            wageRec= new Wages__c(Compensation__c=compen.id , Employer_Tax__c = (compen.Employee__r.Employee_Type__c == CONSTANT.EMPLOYEE_TYPE_SALARIED_EMPLOYEE || compen.Employee__r.RecordType.DeveloperName == salesEmployeeRT) ? compen.Employee__r.Location__r.Tax__c : 0 , Bonus_Per_Wage__c = bonusValue ,P_L_Date__c =PLDate, Cash_Date__c= cashDate,Employee_Number__c = compen.Employee__c,Wage_Amount__c = wageAmount, Bonus_Amount__c = bonusAmountValue, Expense_Account__c = compen.Employee__r.Expense_Account__c);  // PCPM-247 | Wage_Amount__c = wageAmount - bonusValue
                        }else{
                            wageRec= new Wages__c(Compensation__c=compen.id , Employer_Tax__c = (compen.Employee__r.Employee_Type__c == CONSTANT.EMPLOYEE_TYPE_SALARIED_EMPLOYEE || compen.Employee__r.RecordType.DeveloperName == salesEmployeeRT) ? compen.Employee__r.Location__r.Tax__c : 0 , Bonus_Per_Wage__c = bonusValue ,P_L_Date__c =PLDate, Cash_Date__c= cashDate,Employee_Number__c = compen.Employee__c,Wage_Amount__c = wageAmount, Bonus_Amount__c = bonusAmountValue); // PCPM-247 | Wage_Amount__c = wageAmount - bonusValue
                        }
                    }
            	}
                bonusAmountValue = 0;
                bonusCount = 0;
                previousWageCalculate = False;
                previousWageAmount = 0;
                previousBonusAmount = 0;
                daysForPreviousSalary = null;
            }else{
                if(isWagesFields){
                    if(!mapBonusIdBonusPlan.isEmpty() && mapBonusIdBonusPlan.get(compen.Bonus_Plan__c).recordType.DeveloperName == CONSTANT.BONUS_PLAN_ACCELERATOR_BONUS_RT){
                        if(compen.Employee__r.Expense_Account__c != Null && isExpenseAccount){
                            wageRec= new Wages__c(Compensation__c=compen.id,Employer_Tax__c = (compen.Employee__r.Employee_Type__c == CONSTANT.EMPLOYEE_TYPE_SALARIED_EMPLOYEE || compen.Employee__r.RecordType.DeveloperName == salesEmployeeRT) ? compen.Employee__r.Location__r.Tax__c : 0 , Bonus_Per_Wage__c=bonusValue, P_L_Date__c =PLDate, Cash_Date__c= cashDate,Employee_Number__c = compen.Employee__c,Wage_Amount__c = grossWageAmount, Bonus_Amount__c = (mapBonusIdBonusPlan.get(compen.Bonus_Plan__c).Base_Amount__c)*(quotaPercentage/100), Expense_Account__c = compen.Employee__r.Expense_Account__c);
                        }else{
                            wageRec= new Wages__c(Compensation__c=compen.id,Employer_Tax__c = (compen.Employee__r.Employee_Type__c == CONSTANT.EMPLOYEE_TYPE_SALARIED_EMPLOYEE|| compen.Employee__r.RecordType.DeveloperName == salesEmployeeRT) ? compen.Employee__r.Location__r.Tax__c : 0 , Bonus_Per_Wage__c=bonusValue, P_L_Date__c =PLDate, Cash_Date__c= cashDate,Employee_Number__c = compen.Employee__c,Wage_Amount__c = grossWageAmount, Bonus_Amount__c = (mapBonusIdBonusPlan.get(compen.Bonus_Plan__c).Base_Amount__c)*(quotaPercentage/100));
                        }    
                    }else{
                        if(compen.Employee__r.Expense_Account__c != Null && isExpenseAccount){
                            wageRec= new Wages__c(Compensation__c=compen.id,Employer_Tax__c = (compen.Employee__r.Employee_Type__c == CONSTANT.EMPLOYEE_TYPE_SALARIED_EMPLOYEE || compen.Employee__r.RecordType.DeveloperName == salesEmployeeRT) ? compen.Employee__r.Location__r.Tax__c : 0 , Bonus_Per_Wage__c=bonusValue, P_L_Date__c =PLDate, Cash_Date__c= cashDate,Employee_Number__c = compen.Employee__c,Wage_Amount__c = wageAmount, Bonus_Amount__c = 0, Expense_Account__c = compen.Employee__r.Expense_Account__c);  // PCPM-247 | Wage_Amount__c = wageAmount - bonusValue
                        }
                        else{
                            wageRec= new Wages__c(Compensation__c=compen.id,Employer_Tax__c = (compen.Employee__r.Employee_Type__c == CONSTANT.EMPLOYEE_TYPE_SALARIED_EMPLOYEE|| compen.Employee__r.RecordType.DeveloperName == salesEmployeeRT) ? compen.Employee__r.Location__r.Tax__c : 0 , Bonus_Per_Wage__c=bonusValue, P_L_Date__c =PLDate, Cash_Date__c= cashDate,Employee_Number__c = compen.Employee__c,Wage_Amount__c = wageAmount, Bonus_Amount__c = 0);  // PCPM-247 | Wage_Amount__c = wageAmount - bonusValue
    
                        }
                    }
            	}
                previousWageCalculate = False;
                previousWageAmount = 0;
                daysForPreviousSalary = null;
            }
            wagesList.add(wageRec);
        }
        return wagesList;
    }

    /*
        * This method will create two maps, mapEmployeeLastCompensation(Employee Id with last Compensation) and mapEmployeeQuota(Employee Id with related quotas)
        * @parameter newCompensationList, List of Compensation
        * @parameter employeeIds, Employee Id related to Compensation
        * @returns Void
    */
    public static void manageCompensation(list<Compensation__c> newCompensationList, Set<String> employeeIds){
        if(employeeIds == null){
            employeeIds = new Set<String>();
            for(Compensation__c com : newCompensationList){
                employeeIds.add(com.Employee__c);
            }
        }
        
        if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.COMPENSATION_OBJECT,'Id, Employee__c,End_Date__c,Start_Date__c,Base_Pay_Schedule__c,Bonus_Percentage__c ,Monthly_Base_Salary__c,Hours_Per_day__c,Hourly_Rate__c',Constant.ACTION_TYPE_ACCESS)){
            for(Employee__c employee : [Select Id, (Select Id, Employee__c,End_Date__c,Start_Date__c,Base_Pay_Schedule__c,Bonus_Percentage__c ,Monthly_Base_Salary__c,Hours_Per_day__c,Hourly_Rate__c
                                                    from Compensations__r
                                                    order by End_Date__c),
                                        (Select Id from Quota__r)            
                                        from Employee__c where Id IN : employeeIds]){
                if((employee.Compensations__r).size() > 0){                            
                    mapEmployeeLastCompensation.put(employee.Id, (employee.Compensations__r)[0]);
                }
                if((employee.Quota__r).size() > 0){
                    mapEmployeeQuota.put(employee.Id, employee.Quota__r);
                }
            }
    	}
    }

    /*
        * This method will delete Wages when Compensation gets deleted
        * @parameter oldItemMap, map of Compensation Id and Old Data (before update)
        * @returns Void
    */ 
    public static void deleteWageOnCompensationDeletion(Map<Id,Compensation__c> oldItemMap){
        Set<Id> wagesIdSet = new Set<Id>();
        map<String,List<Wages__c>> mapCompIdListWage = new map<String,List<Wages__c>>();
        
        if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.WAGES_OBJECT,'id,Cash_Date__c,Compensation__c',Constant.ACTION_TYPE_ACCESS)){
            for(Wages__c wage : [SELECT id,Cash_Date__c,Compensation__c 
                                    FROM Wages__c 
                                    WHERE Compensation__c IN : oldItemMap.keySet()]){
                                        if(!mapCompIdListWage.containskey(wage.Compensation__c)){
                                            mapCompIdListWage.put(wage.Compensation__c, new List<Wages__c>());
                                        }
                                        mapCompIdListWage.get(wage.Compensation__c).add(wage);
                                    }
    	}
        for(String comId : mapCompIdListWage.keyset()){
            for(Wages__c wage : mapCompIdListWage.get(comId)){
                if(wage.Cash_Date__c <= System.today()){
                    oldItemMap.get(comId).addError(System.Label.This_Compensation_record_can_be_deleted_as_some_wages_are_paid_Update_End_Date);
                }
                else{
                    wagesIdSet.add(wage.Id);
                }
            }
        }
        List<Expense_PL_Allocation__c> plRelatedToWage = new List<Expense_PL_Allocation__c>();
        for(Expense_PL_Allocation__c epa : [SELECT id FROM Expense_PL_Allocation__c WHERE Wage__c IN : wagesIdSet ]){
            plRelatedToWage.add(epa);
        }
        
        PlaceCPM_Utility.deleteRecords(plRelatedToWage, CONSTANT.EXPENSE_PL_ALLOCATION_OBJECT, false); //PCPM-520
        
        List<Expense_Cash_Allocation__c> cashRelatedToWage = new List<Expense_Cash_Allocation__c>();
        for(Expense_Cash_Allocation__c eca : [SELECT id FROM Expense_Cash_Allocation__c WHERE Wage__c IN : wagesIdSet ]){
            cashRelatedToWage.add(eca);
        }
        
        PlaceCPM_Utility.deleteRecords(cashRelatedToWage, CONSTANT.EXPENSE_CASG_ALLOCATION_OBJECT, false);  //PCPM-520
    }

    /*
        * This method will calculate previous bonus, new bonus and wage amount
        * @parameter Days, Number of days for which wage and bonus has to be calculated
        * @parameter compen, Compensation record
        * @parameter lastCompensation, last compensation of employee
        * @returns Void
    */ 
    public static void calculateCashDateAndPreBonusAmount(Integer Days, Compensation__c compen,Compensation__c lastCompensation){
        Map<Id,Schema.RecordTypeInfo> rtMapById = Schema.SObjectType.Compensation__c.getRecordTypeInfosById();
        Schema.RecordTypeInfo rtById = rtMapById.get(compen.recordTypeId);
        Integer payDays;
        Date endDateVal;
        Decimal perDayWage;
        Decimal hoursPerDay,lastCompHoursPerDay;
        if(lastCompensation != Null){
            lastCompHoursPerDay = (lastCompensation.Hours_Per_day__c == null) ? hoursPerDayAssumption : lastCompensation.Hours_Per_day__c;
        }
        hoursPerDay = (compen.Hours_Per_day__c == null) ? hoursPerDayAssumption : compen.Hours_Per_day__c;

        //PCPM-566
        if(compen.End_Date__c != null) {
            if(compen.End_Date__c > System.today().addMonths(forecastMonth)){
                if(compen.Start_Date__c.month() > System.today().month()){
                    endDateVal = compen.Start_Date__c.addMonths(forecastMonth);
                }else{
                    endDateVal = System.today().addMonths(forecastMonth);
                }
            }else{
                endDateVal = compen.End_Date__c;
            }
                                                  		
        }else if(compen.End_Date__c == null){
            if(compen.Start_Date__c.month() > System.today().month()){
                endDateVal = compen.Start_Date__c.addMonths(forecastMonth);
            }else{
                endDateVal = System.today().addMonths(forecastMonth);
            }
        }
        
        if(firstWage == False){
                    cashdate = compen.Start_Date__c;
                    cashDate = cashDate.addDays(Days);
                    firstWage = True;
                    previousCashDate = (cashDate  >= endDateVal) ? compen.Start_Date__c : cashDate;
                }else {
                    cashDate = cashDate.addDays(Days);
                }
                Integer noOfDaysInMonth = Date.daysInMonth(cashDate.year(), cashDate.month());
                Integer NumebrOfDayInYear =  Date.isLeapYear(compen.Start_Date__c.year())? 366 : 365;
                if(compen.Monthly_Base_Salary__c != Null){
                    perDayWage = (compen.Monthly_Base_Salary__c * 12) / NumebrOfDayInYear;
                }
                if(daysForPreviousSalary != Null){
                    Decimal perDayPreviousWage;
                    if(lastCompensation.Monthly_Base_Salary__c != Null){
                        perDayPreviousWage = lastCompensation.Monthly_Base_Salary__c/noOfDaysInMonth;
                    }
                    previousWageAmount = (rtById.getDeveloperName() == CONSTANT.COMPENSATION_RECORD_TYPE_OPS_EMPLOYEE && (compen.Employee__r.Employee_Type__c == CONSTANT.EMPLOYEE_TYPE_HOURLY_EMPLOYEE || compen.Employee__r.Employee_Type__c == CONSTANT.EMPLOYEE_TYPE_HOURLY_CONTRACTORS)) ? (daysForPreviousSalary * (lastCompensation.Hourly_Rate__c * lastCompHoursPerDay)) : daysForPreviousSalary * perDayPreviousWage;
                    if(lastCompensation.Bonus_Percentage__c != null && previousWageAmount != null){
                        previousBonusAmount = lastCompensation.Bonus_Percentage__c * previousWageAmount;
                    }
                }
                wageAmount = (rtById.getDeveloperName() == CONSTANT.COMPENSATION_RECORD_TYPE_OPS_EMPLOYEE && (compen.Employee__r.Employee_Type__c == CONSTANT.EMPLOYEE_TYPE_HOURLY_EMPLOYEE || compen.Employee__r.Employee_Type__c == CONSTANT.EMPLOYEE_TYPE_HOURLY_CONTRACTORS)) ? ((compen.Hourly_Rate__c * hoursPerDay) * Days) : (Days * perDayWage);
                if(cashDate  >= endDateVal){
                    payDays = previousCashDate.daysBetween(endDateVal)+1;
                    wageAmount = (rtById.getDeveloperName() == CONSTANT.COMPENSATION_RECORD_TYPE_OPS_EMPLOYEE && (compen.Employee__r.Employee_Type__c == CONSTANT.EMPLOYEE_TYPE_HOURLY_EMPLOYEE || compen.Employee__r.Employee_Type__c == CONSTANT.EMPLOYEE_TYPE_HOURLY_CONTRACTORS)) ? (payDays * (compen.Hourly_Rate__c * hoursPerDay)) : (payDays * perDayWage);
                }
                previousCashDate = cashDate;
                if(compen.Bonus_Percentage__c != NULL){
                    if(addPreBonusAmount == True && previousBonusAmount != null){  
                        bonusAmountValue = previousBonusAmount;
                        addPreBonusAmount = False;
                    }
                    if(compen.Bonus_Pay_Schedule__c != null){
                        if(compen.Base_Pay_Schedule__c == CONSTANT.BASE_PAY_SCHEDULE_WEEKLY){
                            if(CONSTANT.mapMonthsCountWeekly.containsKey(compen.Bonus_Pay_Schedule__c)){ 
                                calculateBonusCount(CONSTANT.mapMonthsCountWeekly.get(compen.Bonus_Pay_Schedule__c),compen.Bonus_Percentage__c,endDateVal, cashDate, compen.Bonus_Pay_Schedule__c, compen.Base_Pay_Schedule__c);
                                }
                        }else{
                            if(CONSTANT.mapMonthsCountBiWeekly.containsKey(compen.Bonus_Pay_Schedule__c)){ 
                                calculateBonusCount(CONSTANT.mapMonthsCountBiWeekly.get(compen.Bonus_Pay_Schedule__c),compen.Bonus_Percentage__c,endDateVal, cashDate, compen.Bonus_Pay_Schedule__c, compen.Base_Pay_Schedule__c );
                                }
                            }
                    }else{
                        bonusValue = 0;
                    }
                }else{
                    bonusValue = 0;
                }
    }

    /*
        * This method will calculate the number of wages to be created
        * @parameter basePayScheduleVal, Frequency of Salary(Wage)
        * @parameter startDateVal, Start date of wage calculation
        * @parameter endDateVal, End date of wage calculation
        * @returns Number of wages to be created
    */ 
    public static Integer totalNumberOfWagesToBeCreated(String basePayScheduleVal, Date startDateVal, Date endDateVal){
        Integer totalSalaryAllocationRecords = 0;
        Integer lastWeek;
        if(basePayScheduleVal == CONSTANT.BASE_PAY_SCHEDULE_WEEKLY || basePayScheduleVal == CONSTANT.BASE_PAY_SCHEDULE_BI_WEEKLY){
            totalSalaryAllocationRecords = (startDateVal == endDateVal) ? 1 : startDateVal.daysBetween(endDateVal)/7;
            lastWeek = math.mod(startDateVal.daysBetween(endDateVal), 7);
            if(lastWeek != 0){
                totalSalaryAllocationRecords = totalSalaryAllocationRecords + 1;
            }
            if(basePayScheduleVal == CONSTANT.BASE_PAY_SCHEDULE_BI_WEEKLY){
                totalSalaryAllocationRecords = (math.mod(totalSalaryAllocationRecords,2)!=0) ? (totalSalaryAllocationRecords/2) + 1 : totalSalaryAllocationRecords/2;
            }
        }else if(basePayScheduleVal == CONSTANT.BASE_PAY_SCHEDULE_SEMI_MONTHLY){
            
            Integer numberOfMonths = (startDateVal.monthsBetween(endDateVal)) + 1;
            totalSalaryAllocationRecords = numberOfMonths * 2;
            if(startDateVal.day() > 15 && endDateVal.day() > 15){
                totalSalaryAllocationRecords = totalSalaryAllocationRecords - 1;
            }
            else if(startDateVal.day() > 15 && endDateVal.day() <= 15){
                totalSalaryAllocationRecords = totalSalaryAllocationRecords - 2;
            }
            else if(startDateVal.day() <= 15 && endDateVal.day() > 15){
                totalSalaryAllocationRecords = totalSalaryAllocationRecords;
            }
            else if(startDateVal.day() <= 15 && endDateVal.day() <= 15 && endDateVal.day() <= 15 && startDateVal.month() < endDateVal.month()){
                totalSalaryAllocationRecords = totalSalaryAllocationRecords - 1;
            }
            
        }else if(basePayScheduleVal == CONSTANT.BASE_PAY_SCHEDULE_MONTHLY){
            totalSalaryAllocationRecords = startDateVal.monthsBetween(endDateVal)+1;
        } 
        return totalSalaryAllocationRecords;
    }

    /*
        * This method will check overlaping of compensation
        * @parameter newCompensationList, List of new Compensation which are getting inserted
        * @returns void
    */ 
    public static void checkStartDateAndEndDate(List<Compensation__c> newCompensationList){
        Set<id> employeeIdList = new Set<id>();
        Map<Id , List<CompensationWrapper>> employeeAnditsCompensation = new  Map<Id , List<CompensationWrapper>>();
        Map<Id , Compensation__c> compensationMap = new  Map<Id , Compensation__c>();
        List<Compensation__c> compensationTobeUpdated = new List<Compensation__c>();
        for(Compensation__c com : newCompensationList){
            if(com.Start_Date__c  < com.End_Date__c || com.End_Date__c == Null){
                employeeIdList.add(com.Employee__c);
                if(!employeeAnditsCompensation.containsKey(com.Employee__c)){
                    employeeAnditsCompensation.put(com.Employee__c , new List<CompensationWrapper>());
                }
                CompensationWrapper cw = new CompensationWrapper();
                cw.id = com.id;
                cw.startDate = com.Start_Date__c;
                cw.endDate = com.End_Date__c;
                employeeAnditsCompensation.get(com.Employee__c).add(cw);
                compensationMap.put(com.Id , com);
            }
            else if(com.End_Date__c != Null && com.End_Date__c < com.Start_Date__c){
                com.addError(System.Label.End_Date_Should_be_greater_then_Start_Date);
            }
        }
        Map<Id , Employee__c> employeeAndCompensationExisting = new Map<Id , Employee__c>([Select id , (Select id , Start_Date__c , End_Date__c 
                                                                                                        from Compensations__r order by Start_Date__c desc limit 1) From Employee__c where id in : employeeIdList]);
        List<CompensationWrapper> tempCompList;
        Date tempStartDate;
        Date tempEndDate;
        Compensation__c tempComp;
        Boolean isEndDate = false;
        if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.COMPENSATION_OBJECT,'End_Date__c',Constant.ACTION_TYPE_UPDATE)){
            isEndDate = true;
        }
        For(Id employeeId : employeeAnditsCompensation.keyset()){
            tempCompList = employeeAnditsCompensation.get(employeeId);
            tempCompList.sort();
            For(Integer i = 0 ; i < tempCompList.size() ; i++){
                if(i==0){
                    if(employeeAndCompensationExisting.containsKey(employeeId) && employeeAndCompensationExisting.get(employeeId).Compensations__r.size() > 0){
                        tempComp = employeeAndCompensationExisting.get(employeeId).Compensations__r[0];
                        tempEndDate = tempComp.End_Date__c;
                        if(tempCompList[0].startDate <= tempComp.Start_Date__c){
                            compensationMap.get(tempCompList[0].id).addError(System.Label.Compensation_StartDate_CannotBeLessThan_PrevCompStartDate);//557
                        }
                        if(tempEndDate == Null || tempEndDate > tempCompList[0].startDate){
                            
                            if(isEndDate){
                                tempComp.End_Date__c = tempCompList[0].startDate.addDays(-1);
                                compensationTobeUpdated.add(tempComp);
                            }
                        }
                    }
                }
                else if(tempCompList[i].startDate < tempCompList[i-1].endDate){
                    compensationMap.get(tempCompList[i].id).addError(System.Label.Invalid_Start_Date);
                }
                else{
                    tempCompList[i-1].endDate = tempCompList[i].startDate.addDays(-1);
                }
            }
        }
        
        //runUpdate = False ;
         //557
        Database.SaveResult[] results = PlaceCPM_Utility.updateRecordsWithSaveResult(compensationTobeUpdated, CONSTANT.COMPENSATION_OBJECT, false); //PCPM-520
    }

    //this method is used to update the end date of pre decessor compensation record with startdate-1 of successor of deleted compensation
    public static void checkStartDateAndEndDateOnDelete(Map<Id,Compensation__c> oldItemMap){
        Set<String> employeeIdSet = new Set<String>();
        List<Compensation__c> newCompList = new List<Compensation__c>();
        for(Compensation__c comp : oldItemMap.values()){
            if(comp.Employee__c != null){
                employeeIdSet.add(comp.Employee__c);
            }
        }
        if(employeeIdSet.size()>0){
            
            if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.COMPENSATION_OBJECT,'id , Start_Date__c , End_Date__c',Constant.ACTION_TYPE_ACCESS)){
                for(Employee__c emp : [SELECT id , (SELECT id , Start_Date__c , End_Date__c FROM Compensations__r ORDER BY Start_Date__c) FROM Employee__c WHERE id IN : employeeIdSet]){
                    if(emp.Compensations__r.size()>1){
                        List<Compensation__c> childCompList = emp.Compensations__r;
                        for(Integer i = 1; i< childCompList.size(); i++){
                            if(oldItemMap.containsKey(childCompList[i].Id) && !oldItemMap.containsKey(childCompList[childCompList.size()-1].Id)){
                                Compensation__c newComp = new Compensation__c();
                                newComp.Id = childCompList[i-1].Id;
                                newComp.End_Date__c = childCompList[i+1].Start_Date__c.addDays(-1);
                                newCompList.add(newComp);
                            }
                        }
                    }
                }
        	}
            PlaceCPM_Utility.updateRecords(newCompList, CONSTANT.COMPENSATION_OBJECT, false); //PCPM-520
        }
    }

    public Class CompensationWrapper implements Comparable {
        public Id id;
        public Date startDate;
        public Date endDate;
        public Integer compareTo(Object compareTo) {
            CompensationWrapper compareToCompensation = (CompensationWrapper)compareTo;
            if (startDate == compareToCompensation.startDate) return 0;
            if (startDate > compareToCompensation.startDate) return 1;
            return -1;        
        }
    }

    public Class EmployeeWrapper{
        public Decimal preBonus;
        public Wages__c lastWageRecord;
    } 
}
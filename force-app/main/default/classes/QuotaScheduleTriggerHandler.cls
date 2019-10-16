/*
Description : This class will be as used as handler for QuotaScheduleTrigger
Date Created : 24th June 2019
*/
public with sharing class QuotaScheduleTriggerHandler implements CommonTriggerHandler{

    public static List<employee__c> employeeList;
    
    public void BeforeInsert(List<SObject> newItems){
        
    }
    
    public void BeforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems){
        
    }
    
    public void BeforeDelete(Map<Id, SObject> oldItems){
        deleteAllQuotasAndRevenueAccounts((List<Quota_Schedule__c>)oldItems.values());
    }
    
    public void AfterInsert(Map<Id, SObject> newItems){
        createEmployeeQuotaRecords((Map<Id, Quota_Schedule__c>)newItems);
    }
    
    public void AfterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems){
        updtaEmployeeQuotaRecords((Map<Id, Quota_Schedule__c>)newItems , (Map<Id, Quota_Schedule__c>)oldItems);
    }
    
    public void AfterDelete(Map<Id, SObject> oldItems){
        
    }
    
    public void AfterUndelete(Map<Id, SObject> oldItems){
      
    }
    
    public Boolean IsDisabled(){
        return false;
    }
    
    //  Method to create createEmployeeQuotaRecords.
    //  @param Map<Id, Quota_Schedule__c> newItems)
    //  @return void
    private static List<Quota__c> createEmployeeQuotaRecords(Map<Id, Quota_Schedule__c> newItems){
        List<Quota__c> quotaToCreate = new  List<Quota__c>();
        QuotaScheduleTriggerHandler.fetchEmpoyeeAndQuota(false);
        List<Quota_Schedule__c> quotaScheduleList = new List<Quota_Schedule__c>();
        
        if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.QUOTA_SCHEDULE_OBJECT,'id , Range_Start__c, Range_End__c, Quota_Amount__c,type__c, Monthly_Amount__c',Constant.ACTION_TYPE_ACCESS)){
            For(Quota_Schedule__c qs : [Select id , Range_Start__c , Range_End__c , Quota_Amount__c , 
                                        type__c , Monthly_Amount__c  
                                        From Quota_Schedule__c 
                                        where Id In : newItems.values()]){
                if(qs.Range_Start__c != null && qs.Type__c != null){
                    quotaScheduleList.add(qs);
                }
            }
        }
        if(quotaScheduleList.size() > 0 && PlaceCPM_Utility.assumptionRevenueGLAccount != null){
            quotaToCreate = createQuotaRecord(quotaScheduleList);
            try{
                PlaceCPM_Utility.insertRecords(quotaToCreate, CONSTANT.QUOTA_OBJECT, false); //520
            }catch(Exception ex){
                PlaceCPM_Utility.debugLog(ex.getMessage() + ' at line number ' + ex.getLineNumber());
            }
            
        }
        return quotaToCreate;
    }
    
    //  Method to update future quota records.
    //  @param Map<Id, Quota_Schedule__c> newItems , Map<Id, Quota_Schedule__c> oldItems
    //  @return void
    void updtaEmployeeQuotaRecords(Map<Id, Quota_Schedule__c> newItems , Map<Id, Quota_Schedule__c> oldItems){
        Quota_Schedule__c oldQuotaSchdeudle;
        List<Quota_Schedule__c> quotaScheduleUpdated;        
        List<Quota__c> quotasTobeUpdated  = new List<Quota__c>();
        List<Quota_Schedule__c> quotaScheduleList = new List<Quota_Schedule__c>();
        List<Quota__c> quotasToBeInserted = new List<Quota__c>();
        Integer rangestart = CONSTANT.INTEGER_MAX_VALUE;
        For(Quota_Schedule__c qs : newItems.values()){
            oldQuotaSchdeudle = oldItems.get(qs.Id);
            if(qs.Monthly_Amount__c != oldQuotaSchdeudle.Monthly_Amount__c 
                || qs.Range_End__c != oldQuotaSchdeudle.Range_End__c
                || qs.Range_Start__c != oldQuotaSchdeudle.Range_Start__c
                || qs.Type__c != oldQuotaSchdeudle.Type__c){
                if(rangestart > Integer.valueOf(qs.Range_Start__c)){
                    rangestart = Integer.valueOf(qs.Range_Start__c);
                }
            }
        }
        
        if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.QUOTA_SCHEDULE_OBJECT,'id , Range_Start__c , Range_End__c , Monthly_Amount__c , Quota_Amount__c , Type__c',Constant.ACTION_TYPE_ACCESS)){
            For(Quota_Schedule__c qs : [SELECT id , Range_Start__c , Range_End__c , Monthly_Amount__c , Quota_Amount__c , Type__c ,
                                            (SELECT id FROM Quota__r WHERE Quota_Start_Date__c >=: System.today())
                                            FROM Quota_Schedule__c WHERE Range_Start__c >=: rangestart ORDER BY Range_Start__c ]){
                quotaScheduleList.add(qs);
                For(Quota__c quota : qs.Quota__r){
                    quotasTobeUpdated.add(quota);
                }
            }
        }
        SavePoint sp = Database.setSavepoint();
        try{
            PlaceCPM_Utility.deleteRecords(quotasTobeUpdated, CONSTANT.QUOTA_OBJECT, false); //520
            fetchEmpoyeeAndQuota(true);
            quotasToBeInserted = createQuotaRecord(quotaScheduleList);
            PlaceCPM_Utility.insertRecords(quotasToBeInserted, CONSTANT.QUOTA_OBJECT, false); //520
        
        }catch(Exception ex){
            PlaceCPM_Utility.debugLog('Exception : == ' + ex.getMessage() + ' at line number ' + ex.getLineNumber());
            Database.rollback(sp);
        }
    }
	
    //  Method to create createQuotaRecord upto forecast duration.
    //  @param List<Quota_Schedule__c> quotaScheduleList
    //  @return void
    public static  List<Quota__c> createQuotaRecord(List<Quota_Schedule__c> quotaScheduleList){
        List<Quota__c> quotasToBeInserted = new List<Quota__c>();
        Date tempDate;
        Integer monthPassed;
        Integer noOfQuotaForSameSchedule;
        Quota__c quota ;
        Quota__c oldQuota;
        Boolean isEmployee = false, isMonthlyQuotaAmount = false, isQuotaStartDate = false, isQuotaEndDate = false, isGLAccount = false, isQuotaSchedule = false;
        
        if(Schema.sObjectType.Quota__c.fields.Employee__c.isCreateable()){
            isEmployee = true;
        }
        if(Schema.sObjectType.Quota__c.fields.Monthly_Quota_Amount__c.isCreateable()){
            
            isMonthlyQuotaAmount = true;
        }
        if(Schema.sObjectType.Quota__c.fields.Quota_Start_Date__c.isCreateable()){
            
            isQuotaStartDate = true;
        }

        if(Schema.sObjectType.Quota__c.fields.Quota_End_Date__c.isCreateable()){
            
            isQuotaEndDate = true;
        }
        
		if(Schema.sObjectType.Quota__c.fields.Revenue_GL_Account__c.isCreateable()){
            
            isGLAccount = true;
        }
        
        if(Schema.sObjectType.Quota__c.fields.Quota_Schedule__c.isCreateable()){
            
            isQuotaSchedule = true;
        }
        

        For(Employee__c emp : employeeList){
            if(emp.quota__r != Null && emp.quota__r.size() > 0){
                oldQuota = emp.quota__r[0];
                tempDate = oldQuota.Quota_End_Date__c.addDays(1);
                if(oldQuota.Quota_End_Date__c!= Null){
                    monthPassed = emp.Employee_Start_Date__c.monthsBetween(oldQuota.Quota_End_Date__c);
                    if (oldQuota.Quota_End_Date__c.day() > emp.Employee_Start_Date__c.day()) monthPassed++;
                }
                else{
                    monthPassed = 0;
                }
            }
            else{
                tempDate = emp.Employee_Start_Date__c;
                monthPassed = 0;
            }
            For(Quota_Schedule__c qs : quotaScheduleList){
                if(qs.Range_Start__c != 1 && qs.Range_Start__c > 1 && tempDate == emp.Employee_Start_Date__c){
                    tempDate = emp.Employee_Start_Date__c.addMonths((Integer)(Integer.valueOf(qs.Type__c) * (qs.Range_Start__c - 1)));
                    monthPassed = (Integer)(Integer.valueOf(qs.Type__c) * (qs.Range_Start__c - 1));
                }
                if(qs.Range_End__c != Null){
                    noOfQuotaForSameSchedule = Integer.valueOf(qs.Range_End__c) - Integer.valueOf(qs.Range_Start__c) + 1;
                }
                else if(qs.Range_End__c == Null){
                    noOfQuotaForSameSchedule = (PlaceCPM_Utility.assumptionForecastDuration - monthPassed)/Integer.valueOf(qs.Type__c);
                }
                For(Integer i = 0 ; i < noOfQuotaForSameSchedule ; i++ ){
                    if(qs.Range_End__c == Null || qs.Range_End__c * Integer.valueOf(qs.Type__c) > monthPassed){
                        quota = new Quota__c();
                        
                        if(isEmployee){
                        
                            quota.Employee__c = emp.Id;
                            
                        }
                        
                        if(isMonthlyQuotaAmount){
                            quota.Monthly_Quota_Amount__c = qs.Monthly_Amount__c;
                        }
                        
                        if(isQuotaStartDate){
                            quota.Quota_Start_Date__c = tempDate;
                        }
                        
                        if(isQuotaEndDate){
                            quota.Quota_End_Date__c = tempDate.addMonths(Integer.valueOf(qs.Type__c)).addDays(-1);
                        }
                        
                        if(isGLAccount){
                            quota.Revenue_GL_Account__c = PlaceCPM_Utility.assumptionRevenueGLAccount;
                        }
                        
                        if(isQuotaSchedule){
                            quota.Quota_Schedule__c = qs.Id;
                        }
                        tempDate = quota.Quota_End_Date__c.addDays(1);
                        monthPassed = monthPassed + Integer.valueOf(qs.Type__c);
                        quotasToBeInserted.add(quota);
                    }
                }
            }
        }
        return quotasToBeInserted;
    }
    
    //  Method to delete quota records.
    //  @param List<Quota_Schedule__c> quotaSchedule
    //  @return void
   private void deleteAllQuotasAndRevenueAccounts(List<Quota_Schedule__c> quotaSchedule){
        List<Quota__c> quotasToBeDeleted = new List<Quota__c>();
       For(Quota__c quota : [SELECT id FROM Quota__c WHERE Quota_Schedule__c IN : quotaSchedule]){
           quotasToBeDeleted.add(quota);
       }
        if(quotasToBeDeleted.size() > 0){
            try{
                PlaceCPM_Utility.deleteRecords(quotasToBeDeleted, CONSTANT.QUOTA_OBJECT, false); //520
            }
            catch(Exception ex){
                PlaceCPM_Utility.debugLog('Exception : == ' + ex.getMessage() + ' at line number ' + ex.getLineNumber());
            }
        }
    }

    //  Method to fetch employee with sales department and account excetive role profile.
    //  @param boolean refresh to refresh employee list
    //  @return void
    public static void fetchEmpoyeeAndQuota(boolean refresh){
        if(employeeList == null || refresh){
            employeeList = new List<employee__c>();
            // PCPM-235
            
            if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.EMPLOYEE_OBJECT,'id ,Role__c, Employee_Start_Date__c',Constant.ACTION_TYPE_ACCESS) && 
               PlaceCPM_Utility.checkAccessiblityOfFields(Constant.QUOTA_OBJECT,'id , Quota_Start_Date__c, Quota_End_Date__c',Constant.ACTION_TYPE_ACCESS) &&
               PlaceCPM_Utility.checkAccessiblityOfFields(Constant.ROLE_OBJECT,'Is_Quota_Applicable__c',Constant.ACTION_TYPE_ACCESS) &&
               PlaceCPM_Utility.checkAccessiblityOfFields(Constant.QUOTA_SCHEDULE_OBJECT,'type__c, Range_End__c',Constant.ACTION_TYPE_ACCESS)){
                For(employee__c emp : [SELECT id ,Role__c,Role__r.Is_Quota_Applicable__c, Employee_Start_Date__c ,
                                        (SELECT id , Quota_Start_Date__c , Quota_End_Date__c , Quota_Schedule__r.type__c , 
                                        Quota_Schedule__r.Range_End__c FROM quota__r ORDER BY Quota_Start_Date__c desc LIMIT 1) 
                                       FROM employee__c 
                                       WHERE Role__c != null 
                                       AND Role__r.Is_Quota_Applicable__c = true]){
                    employeeList.add(emp);
                }
            }
        }
    }
}
/*
 Created Date :  19 June 2019
 Class Name   :  placeCPM_CreatePLAndCashRecords
 Description  :  PCPM-67 & 72 | Batch class to generate Expense and Revenue P&L and Cash Forcast Record for forcasting 

 Change 1     :
 */
public class placeCPM_CreatePLAndCashRecords implements Database.Batchable<sObject>, Database.Stateful{
    
    public Iterable<Sobject> start(Database.BatchableContext bc) {
        placeCPM_CustomExpenseRevenueIterable obj = new placeCPM_CustomExpenseRevenueIterable();
        Iterable<SObject> myIter = (Iterable<SObject>)obj.sobjs;
        return myIter;     
    }
    
    public void execute(Database.BatchableContext bc, List<sObject> scope){
        List<Expense_Account__c> expenseAccountList = new List<Expense_Account__c>();
        List<Revenue_Account__c> revenueAccountList = new List<Revenue_Account__c>();
       
        for(sObject sobj : scope){
            if(sobj instanceof Expense_Account__c){
                Expense_Account__c expenseDetail = (Expense_Account__c)sobj;
                expenseAccountList.add(expenseDetail);
            }
            if(sobj instanceof Revenue_Account__c){
                Revenue_Account__c revenueAccount = (Revenue_Account__c)sobj;
                revenueAccountList.add(revenueAccount);
            }
        }
        if(expenseAccountList.size() > 0){
            createExpensePLAndCashAllocations(expenseAccountList);
        }
        if(revenueAccountList.size() > 0){
            createRevenuePLAndCashAllocations(revenueAccountList);
        }
    }    

    public void finish(Database.BatchableContext bc){
       
    }
    
    // Method to create P&L and Cash Forcast if not for that period and Expense P&L Allocation and Expense Cash Forcast
    private void createExpensePLAndCashAllocations(List<Expense_Account__c> expenseAccountList){
        List<Expense_PL_Allocation__c> expensePnlAllocations = new list<Expense_PL_Allocation__c>();
        List<Expense_Cash_Allocation__c> expenseCashAllocations = new list<Expense_Cash_Allocation__c>();
        
        for(Expense_Account__c expenseAccount : (List<Expense_Account__c>)expenseAccountList){
            if(expenseAccount.Expense_Details__r.size() > 0){
                Expense_Detail__c expenseDetail = expenseAccount.Expense_Details__r[0];
                // Expense PLA Logic
                Date lastPLDate = expenseAccount.Wage_Expense_Allocations__r[0].P_L__r.Period_Start_Date__c;
                Date nextPLDate = lastPLDate.addMonths(1);
                String nextPLMonthStr = placeCPM_Utility.getMonthString(nextPLDate.month());
                String nextPLName = nextPLMonthStr+' '+nextPLDate.year();
               
                Profit_Loss__c newPLRecord;
                Map<String, Profit_Loss__c> profitLossRecordsMap = PlaceCPM_Utility.getPLRecords(new Set<String>{nextPLName});
                if(profitLossRecordsMap != null){
                    newPLRecord = profitLossRecordsMap.get(nextPLName);
                }else{
                    Integer dim = date.daysInMonth(nextPLDate.year(), nextPLDate.month());
                    date lastDOM = date.newInstance(nextPLDate.year(), nextPLDate.month(), dim);
                    date firstDOM = lastDOM.toStartOfMonth();
                    newPLRecord = new Profit_Loss__c(Name=nextPLName, Period_Start_Date__c=firstDOM, Period_End_Date__c=lastDOM);
                    PlaceCPM_Utility.insertRecords(new List<Profit_Loss__c>{newPLRecord}, CONSTANT.PROFIT_LOSS_OBJECT, false); //520
                }
                
                //creating P&L & Expense P&L Allocations
                if(expenseAccount.Wage_Expense_Allocations__r.size() > 0){
                    Expense_PL_Allocation__c epla = expenseAccount.Wage_Expense_Allocations__r[0].clone(); 
                    
                    if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.EXPENSE_PL_ALLOCATION_OBJECT,'P_L__c',Constant.ACTION_TYPE_INSERT)){
                        epla.P_L__c = newPLRecord.Id;
                    }
                    
                    if(expenseDetail.Vendor_Id__c != null && PlaceCPM_Utility.checkAccessiblityOfFields(Constant.EXPENSE_PL_ALLOCATION_OBJECT,'Vendor__c',Constant.ACTION_TYPE_INSERT)){
                        epla.Vendor__c = expenseDetail.Vendor_Id__c;
                    }
                    
                    if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.EXPENSE_PL_ALLOCATION_OBJECT,'Forecast_Amount__c',Constant.ACTION_TYPE_INSERT)){
                	    epla.Forecast_Amount__c = expenseDetail.Monthly_Expense_Amount__c;
                    }
                    
                    if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.EXPENSE_PL_ALLOCATION_OBJECT,'GL_Code__c',Constant.ACTION_TYPE_INSERT)){
                	    epla.GL_Code__c = expenseDetail.GL_Account_Id__c; 
                    }
                    expensePnlAllocations.add(epla);     
                }
                
                //Expense Cash Forcast Logic
                if(expenseDetail.Invoice_Date__c != null && expenseDetail.Payment_Frequency__c != null){
                   Integer expenseMonths = expenseDetail.Start_Date__c.monthsBetween(nextPLDate)+1 ;
                   Boolean isCreateCF = math.mod(Integer.valueOf(expenseMonths), Integer.valueOf(expenseAccount.Payment_Frequency__c)) == 0 ? true : false ;
                   if(isCreateCF){
                       Integer paymentTermDays = expenseDetail.Payment_Term_After_Days__c !=null 
                                                 ? Integer.valueOf(expenseDetail.Payment_Term_After_Days__c) 
                                                 : 0 ;
                       Date cashDate = expenseDetail.Invoice_Date__c.addDays(paymentTermDays); 
                       cashDate = cashDate.addMonths((Integer.valueOf(expenseDetail.Payment_Frequency__c))+expenseMonths);
                       String nextCFMonthStr = placeCPM_Utility.getMonthString(cashDate.month());
                       String nextCFName = nextCFMonthStr+' '+cashDate.year();
                       
                       //creating Cash Forcast & Expense Cash Forcast Allocations
                       Cash_Forecast__c newCashForcast;
                       Map<String, Cash_Forecast__c> cashForcastRecordsMap = PlaceCPM_Utility.getCashForecastRecords(new set<String>{nextCFName});
                       if(cashForcastRecordsMap != null){
                           newCashForcast = cashForcastRecordsMap.get(nextCFName);
                       }else{
                           Integer dim = date.daysInMonth(cashDate.year(), cashDate.month());
                           date lastDOM = date.newInstance(cashDate.year(), cashDate.month(), dim);
                           date firstDOM = lastDOM.toStartOfMonth();
                           newCashForcast = new Cash_Forecast__c(Name=nextCFName, Period_Start_Date__c=firstDOM, Period_End_Date__c=lastDOM);
                           PlaceCPM_Utility.insertRecords(new List<Cash_Forecast__c>{newCashForcast}, CONSTANT.CASH_FORECAST_OBJECT, false); //520
                       }    
                       Decimal cashAmount = expenseDetail.Monthly_Expense_Amount__c * Integer.valueOf(expenseDetail.Payment_Frequency__c);
                       Expense_Cash_Allocation__c eca = new Expense_Cash_Allocation__c(Expense_Detail__c = expenseDetail.Id, 
                                                                                       Cash_Forecast__c = newCashForcast.Id,
                                                                                       Expense_Account__c = expenseAccount.Id, Cash_Date__c = cashDate, 
                                                                                       Forecast_Amount__c = cashAmount);
                      
                       expenseCashAllocations.add(eca);
                   }
                } 
            }
        }

        //ExpensePLAllocationTriggerHandler.dontRunTrigger = true;
        try{
            PlaceCPM_Utility.insertRecords(expensePnlAllocations, CONSTANT.EXPENSE_PL_ALLOCATION_OBJECT, false); //520
            PlaceCPM_Utility.insertRecords(expenseCashAllocations, CONSTANT.EXPENSE_CASG_ALLOCATION_OBJECT, false); //520
        }catch(Exception ex){
            PlaceCPM_Utility.debugLog(ex.getMessage() + ' at line number ' + ex.getLineNumber());
        }
        
    }//end of createExpensePLAndCashAllocations method
    
    // Method to create P&L and Cash Forcast if not for that period and Revenue P&L Allocation and Revenue Cash Forcast
    private void createRevenuePLAndCashAllocations(List<Revenue_Account__c> revenueAccountList){
        List<Revenue_P_L_Allocation__c> revenuePnlAllocations = new list<Revenue_P_L_Allocation__c>();
        List<Revenue_Cash_Allocation__c> revenueCashAllocations = new list<Revenue_Cash_Allocation__c>();
        
        for(Revenue_Account__c revenueAccount : revenueAccountList){
            if(revenueAccount.Revenue_Contracts__r.size() > 0){
                Revenue_Contract__c revenueContract = revenueAccount.Revenue_Contracts__r[0];
                //Revenue PLA Logic
                Date lastPLDate = revenueAccount.Revenue_P_L_Allocations_del__r[0].Period_Start_Date__c;
                Date nextPLDate = lastPLDate.addMonths(1);
                String nextPLMonthStr = placeCPM_Utility.getMonthString(nextPLDate.month());
                String nextPLName = nextPLMonthStr+' '+nextPLDate.year();
               
                Profit_Loss__c newPLRecord;
                Map<String, Profit_Loss__c> profitLossRecordsMap = PlaceCPM_Utility.getPLRecords(new Set<String>{nextPLName});
                if(profitLossRecordsMap != null){
                    newPLRecord = profitLossRecordsMap.get(nextPLName);
                }else{
                    Integer dim = date.daysInMonth(nextPLDate.year(), nextPLDate.month());
                    date lastDOM = date.newInstance(nextPLDate.year(), nextPLDate.month(), dim);
                    date firstDOM = lastDOM.toStartOfMonth();
                    newPLRecord = new Profit_Loss__c(Name=nextPLName, Period_Start_Date__c=firstDOM, Period_End_Date__c=lastDOM);
                    PlaceCPM_Utility.insertRecords(new List<Profit_Loss__c>{newPLRecord}, CONSTANT.PROFIT_LOSS_OBJECT, false); //520
                }
                
                //creating P&L & Revenue P&L Allocations
                Decimal forecastedQuota = PlaceCPM_Utility.assumptionForecastQuota != null ? PlaceCPM_Utility.assumptionForecastQuota : 100;
                if(revenueAccount.Revenue_P_L_Allocations_del__r.size() > 0){
                    Revenue_P_L_Allocation__c rpla = new Revenue_P_L_Allocation__c();
                    
                    if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.REVENUE_PL_ALLOCATION_OBJECT,'P_L__c',Constant.ACTION_TYPE_INSERT)){
                        rpla.P_L__c = newPLRecord.Id; 
                    }
                    
                    if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.REVENUE_PL_ALLOCATION_OBJECT,'Revenue_Account__c',Constant.ACTION_TYPE_INSERT)){
                        rpla.Revenue_Account__c = revenueAccount.Id;
                    }
                    
                    if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.REVENUE_PL_ALLOCATION_OBJECT,'Revenue_Contract__c',Constant.ACTION_TYPE_INSERT)){
                        rpla.Revenue_Contract__c = revenueContract.Id;
                    }
                    
                    if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.REVENUE_PL_ALLOCATION_OBJECT,'GL_Code__c',Constant.ACTION_TYPE_INSERT)){
                        rpla.GL_Code__c = revenueAccount.GL_Code__c;
                    }
                    
                    if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.REVENUE_PL_ALLOCATION_OBJECT,'Forecast_Amount__c',Constant.ACTION_TYPE_INSERT)){
                        rpla.Forecast_Amount__c = revenueContract.Total_Monthly_Revenue__c;
                    }
                    
                    if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.REVENUE_PL_ALLOCATION_OBJECT,'Quota_Amount__c',Constant.ACTION_TYPE_INSERT)){
                        rpla.Quota_Amount__c = revenueContract.Total_Monthly_Revenue__c*forecastedQuota /100;
                    }
                    revenuePnlAllocations.add(rpla);     
                }
                
                //Revenue Cash Forcast Logic
                if(revenueContract.Invoice_Date__c != null && revenueAccount.Billing_Cycle__c != null){
                   Integer revenueMonths = revenueContract.Contract_Start_Date__c.monthsBetween(nextPLDate)+1 ;
                   Boolean isCreateCF = math.mod(Integer.valueOf(revenueMonths), Integer.valueOf(revenueAccount.Billing_Cycle__c )) == 0 ? true : false ;
                   if(isCreateCF){
                       Integer paymentTermDays = revenueContract.Payment_Term_After_Days__c !=null 
                                                 ? Integer.valueOf(revenueContract.Payment_Term_After_Days__c) 
                                                 : 0 ;
                       Date cashDate = revenueContract.Invoice_Date__c.addDays(paymentTermDays); 
                       cashDate = cashDate.addMonths((Integer.valueOf(revenueAccount.Billing_Cycle__c)) + revenueMonths);
                       String nextCFMonthStr = placeCPM_Utility.getMonthString(cashDate.month());
                       String nextCFName = nextCFMonthStr+' '+cashDate.year();
                       
                       //creating Cash Forcast & Revenue Cash Forcast Allocations
                       Cash_Forecast__c newCashForcast;
                       Map<String, Cash_Forecast__c> cashForcastRecordsMap = PlaceCPM_Utility.getCashForecastRecords(new set<String>{nextCFName});
                       if(cashForcastRecordsMap != null){
                           newCashForcast = cashForcastRecordsMap.get(nextCFName);
                       }else{
                           Integer dim = date.daysInMonth(cashDate.year(), cashDate.month());
                           date lastDOM = date.newInstance(cashDate.year(), cashDate.month(), dim);
                           date firstDOM = lastDOM.toStartOfMonth();
                           if(Schema.sObjectType.Cash_Forecast__c.isCreateable()){
                                newCashForcast = new Cash_Forecast__c(Name=nextCFName, Period_Start_Date__c=firstDOM, Period_End_Date__c=lastDOM);
                                PlaceCPM_Utility.insertRecords(new List<Cash_Forecast__c>{newCashForcast}, CONSTANT.CASH_FORECAST_OBJECT, false); //520
                           }
                       }
                       
                       Decimal cashAmount = revenueContract.Total_Monthly_Revenue__c * Integer.valueOf(revenueAccount.Billing_Cycle__c);
                       Revenue_Cash_Allocation__c eca = new Revenue_Cash_Allocation__c(Revenue_Contract__c = revenueContract.Id,
                                                                                       Cash_Forecast__c = newCashForcast.Id, 
                                                                                       Revenue_Account__c = revenueAccount.Id, 
                                                                                       Cash_Date__c = cashDate, 
                                                                                       Forecast_Amount__c = cashAmount,
                                                                                       Quota_Amount__c=(cashAmount*forecastedQuota)/100);
                       revenueCashAllocations.add(eca);
                   }
                } 
            }
        }
        try{
           PlaceCPM_Utility.insertRecords(revenuePnlAllocations, CONSTANT.REVENUE_PL_ALLOCATION_OBJECT, false); //520
           PlaceCPM_Utility.insertRecords(revenueCashAllocations, CONSTANT.REVENUE_CASH_ALLOCATION_OBJECT, false); //520
        }catch(Exception ex){
            PlaceCPM_Utility.debugLog(ex.getMessage() + ' at line number ' + ex.getLineNumber());
        }
        
        
    }//end of createRevenuePLAndCashAllocations method
}
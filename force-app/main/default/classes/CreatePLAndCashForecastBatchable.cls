/*
Description : This batch class is used for creating the Pl and Cash Allocations.
Date Created : 21st May 2019
Change : 
*/

public with sharing class CreatePLAndCashForecastBatchable implements Database.Batchable<sObject>{
    
    public static boolean recursive = false;
    //Start method
    public Database.QueryLocator start(Database.BatchableContext BC){
        
      String query;
      if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.REVENUE_CONTRACT_OBJECT,'Revenue_Account__c ,Contract_Months__c, Payment_Term_After_Days__c ,'+
                        ' Invoice_Date__c,  Contract_End_Date__c, Total_Monthly_Revenue__c, Auto_renew__c, '+
                        ' Live_Renewed_Date__c',Constant.ACTION_TYPE_ACCESS)){  
          query = 'Select Id, Revenue_Account__c ,Contract_Months__c, Payment_Term_After_Days__c ,'+
                        ' Invoice_Date__c,  Contract_End_Date__c, Total_Monthly_Revenue__c, Auto_renew__c, '+
                        ' Live_Renewed_Date__c from Revenue_Contract__c where Batch_Process_Execution__c = True';
      }    
      return Database.getQueryLocator(query);
    }

    //Execute
    public void execute(Database.BatchableContext bc, List<sObject> scope){
        createUpdateRevenueContractPnLAndCashAllocations((List<Revenue_Contract__c>)scope);
    }
    
    //Finish
    public void finish(Database.BatchableContext bc){
        if(!recursive) {
            recursive = true;
            Boolean runAgain = true;
            For(AsyncApexJob aaj : [SELECT Id, Status  , ExtendedStatus FROM AsyncApexJob WHERE Id =: bc.getJobId()]){
                if(aaj.ExtendedStatus != Null){
                    runAgain = false;
                } 
            }
            if(runAgain && [Select Id from Revenue_Contract__c where Batch_Process_Execution__c = True limit 1].size() > 0){
                Database.executeBatch(new CreatePLAndCashForecastBatchable(), 50);
            }
        }
    }
    
    // @param listRevenueContracts is the list of Revenue_Contract__c which are created
    // @return null
    
    public static void createUpdateRevenueContractPnLAndCashAllocations(List<Revenue_Contract__c> listRevenueContracts){
        
        Map<String,Revenue_Cash_Allocation__c> mapRCA = new Map<String,Revenue_Cash_Allocation__c> ();
        List<String> listUpdatedRCAId = new List<String> ();
        List<Revenue_Cash_Allocation__c> listRCATobeDeleted = new  List<Revenue_Cash_Allocation__c>();
        List<Revenue_P_L_Allocation__c> listRPLATobeDeleted = new List<Revenue_P_L_Allocation__c>();
        List<String> listRevenueAccountId = new List<String>();
        Map<String,List<Contract_Line_Items__c>> mapRCToCLI = new Map<String,List<Contract_Line_Items__c>>();
        List<Revenue_P_L_Allocation__c> revenuePnlAllocations = new List<Revenue_P_L_Allocation__c>();
        List<Revenue_Cash_Allocation__c> revenueCashAllocations = new List<Revenue_Cash_Allocation__c>();
        Map<String, Revenue_Cash_Allocation__c> existingCashAllocationMap = new Map<String, Revenue_Cash_Allocation__c>();
        Map<String, Revenue_P_L_Allocation__c> existingPLAllocationMap = new Map<String, Revenue_P_L_Allocation__c>();
        List<Revenue_Contract__c> listRevenueContractsTobeUpdated = new List<Revenue_Contract__c>();
        Set<String> monthsForPL = new Set<String>();
        Date minStartDate;
        
        try{
            for(Revenue_Contract__c rc: listRevenueContracts){
                listRevenueAccountId.add(rc.Revenue_Account__c);
                listRevenueContractsTobeUpdated.add(new Revenue_Contract__c(Id = rc.id, Batch_Process_Execution__c = false));
                
                //getting the minimum date
                if(minStartDate == null || rc.Live_Renewed_Date__c < minStartDate){
                    minStartDate = rc.Live_Renewed_Date__c;
                }
            }
            
            //preparting map of all the months from minimum start date to assumption date
            Integer forecastDuration = PlaceCPM_Utility.assumptionForecastDuration;
            Integer revenueMonthsTemp = minStartDate.monthsBetween(System.Today()) + forecastDuration;
            if(System.Today() < minStartDate){
            	revenueMonthsTemp = System.Today().monthsBetween(minStartDate) + forecastDuration;
            }
            Date endDate = minStartDate.addMonths(revenueMonthsTemp);
            //System.assert(false, minStartDate + '====' + endDate);
            for(Date iDate = minStartDate; iDate <= endDate; iDate = iDate.addMonths(1)){
                monthsForPL.add(PlaceCPM_Utility.getMonthString(iDate.month())+' '+iDate.year());
            }
            
            Map<String,Revenue_Account__c> listRevenueAccount;
            if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.revenueAccountObject,'Id,GL_Code__c, Billing_Cycle__c',Constant.ACTION_TYPE_ACCESS)){
                listRevenueAccount = new Map<String,Revenue_Account__c>(
                                                                [SELECT Id,GL_Code__c, Billing_Cycle__c FROM Revenue_Account__c 
                                                                WHERE ID IN :listRevenueAccountId]);
        	}
            
            if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.REVENUE_CONTRACT_OBJECT,'Id, Contract_End_Date__c, Total_Monthly_Revenue__c, Live_Renewed_Date__c,Batch_Process_Execution__c,Auto_renew__c',Constant.ACTION_TYPE_ACCESS) &&
               PlaceCPM_Utility.checkAccessiblityOfFields(Constant.CONTRACT_LINE_ITEM_OBJECT,'ID,Revenue_Contract_Details__c, Start_Date__c,End_Date__c, Total_Amount__c ',Constant.ACTION_TYPE_ACCESS) && 
               PlaceCPM_Utility.checkAccessiblityOfFields(Constant.REVENUE_PL_ALLOCATION_OBJECT,'Id,Name,P_L__c,Revenue_Contract__c, Forecast_Amount__c ',Constant.ACTION_TYPE_ACCESS) &&
               PlaceCPM_Utility.checkAccessiblityOfFields(Constant.REVENUE_CASH_ALLOCATION_OBJECT,'Id, Name,Revenue_Contract__c ',Constant.ACTION_TYPE_ACCESS) &&
               PlaceCPM_Utility.checkAccessiblityOfFields(Constant.CASH_FORECAST_OBJECT,'Period_End_Date__c',Constant.ACTION_TYPE_ACCESS) &&
			   PlaceCPM_Utility.checkAccessiblityOfFields(Constant.PL_OBJECT,'Period_End_Date__c,Period_Start_Date__c',Constant.ACTION_TYPE_ACCESS)
              ){
            for(Revenue_Contract__c contract : [Select Id, Contract_End_Date__c, Total_Monthly_Revenue__c, Live_Renewed_Date__c,Batch_Process_Execution__c,Auto_renew__c,
                                                (SELECT ID,Revenue_Contract_Details__c, Start_Date__c, 
                                                End_Date__c, Total_Amount__c 
                                                FROM Contract_Line_Items__r),
                                                (Select Id,P_L__r.Period_Start_Date__c, P_L__r.Period_End_Date__c, Name, 
                                                P_L__c, P_L__r.Name, 
                                                Revenue_Contract__c, Forecast_Amount__c 
                                                From Revenue_P_L_Allocations__r),
                                                
                                                (Select Id, Name, Cash_Forecast__r.Period_End_Date__c, 
                                                Cash_Forecast__r.Name,Revenue_Contract__c 
                                                From Revenue_Cash_Allocations__r)
                                                 
                                                From Revenue_Contract__c where Id in : listRevenueContracts]){
                
                mapRCToCLI.put(contract.id, contract.Contract_Line_Items__r);
                if(contract.Contract_End_Date__c != null || contract.Total_Monthly_Revenue__c != null ){
                     for(Revenue_P_L_Allocation__c pla : contract.Revenue_P_L_Allocations__r){
                        existingPLAllocationMap.put(contract.id+'~'+pla.P_L__r.Name, pla);
                     }
                     for(Revenue_Cash_Allocation__c cash : contract.Revenue_Cash_Allocations__r){
                        existingCashAllocationMap.put(contract.id + '~' + cash.Cash_Forecast__r.Name, cash);
                        mapRCA.put(cash.Id,cash);
                     }
                }
            }
        }
            Map<String, Profit_Loss__c> pnlMap = RevenueContractTriggerHandler.getMonthsforPLAllocation(listRevenueContracts, monthsForPL);
            Map<String, Cash_Forecast__c> cashForecastMap = RevenueContractTriggerHandler.getMonthsforCashAllocation(listRevenueContracts, listRevenueAccount, monthsForPL);
            Boolean isPl = false, isRevenueAccount = false, isRevenueContract = false, isGLCode = false, isForecastAmount = false;
            Boolean isRCDate = false, isRCForecastAmount = false;
            if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.REVENUE_PL_ALLOCATION_OBJECT,'P_L__c',Constant.ACTION_TYPE_INSERT)){
                isPl = true;
            }
            if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.REVENUE_PL_ALLOCATION_OBJECT,'Revenue_Account__c',Constant.ACTION_TYPE_INSERT) && PlaceCPM_Utility.checkAccessiblityOfFields(Constant.REVENUE_PL_ALLOCATION_OBJECT,'Revenue_Account__c',Constant.ACTION_TYPE_UPDATE)){
                isRevenueAccount = true;
            }
            if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.REVENUE_PL_ALLOCATION_OBJECT,'Revenue_Contract__c',Constant.ACTION_TYPE_INSERT) && PlaceCPM_Utility.checkAccessiblityOfFields(Constant.REVENUE_PL_ALLOCATION_OBJECT,'Revenue_Contract__c',Constant.ACTION_TYPE_UPDATE)){
                isRevenueContract = true;
            }
            if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.REVENUE_PL_ALLOCATION_OBJECT,'GL_Code__c',Constant.ACTION_TYPE_INSERT) && PlaceCPM_Utility.checkAccessiblityOfFields(Constant.REVENUE_PL_ALLOCATION_OBJECT,'GL_Code__c',Constant.ACTION_TYPE_UPDATE)){
                isGLCode = true;
            }
            if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.REVENUE_PL_ALLOCATION_OBJECT,'Forecast_Amount__c',Constant.ACTION_TYPE_INSERT) && PlaceCPM_Utility.checkAccessiblityOfFields(Constant.REVENUE_PL_ALLOCATION_OBJECT,'Forecast_Amount__c',Constant.ACTION_TYPE_UPDATE)){
                isForecastAmount = true;
            }
            if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.REVENUE_CASH_ALLOCATION_OBJECT,'Cash_Date__c',Constant.ACTION_TYPE_INSERT) && PlaceCPM_Utility.checkAccessiblityOfFields(Constant.REVENUE_CASH_ALLOCATION_OBJECT,'Cash_Date__c',Constant.ACTION_TYPE_UPDATE)){
                isRCDate = true;
            }
            if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.REVENUE_CASH_ALLOCATION_OBJECT,'Forecast_Amount__c',Constant.ACTION_TYPE_INSERT) && PlaceCPM_Utility.checkAccessiblityOfFields(Constant.REVENUE_CASH_ALLOCATION_OBJECT,'Forecast_Amount__c',Constant.ACTION_TYPE_UPDATE)){
                isRCForecastAmount = true;
            }
            for(Revenue_Contract__c rc: listRevenueContracts){
                Integer revenueMonths = 0;
                Date contractEndDate;
                revenueMonths = PlaceCPM_Utility.getRevenueMonths(rc);
                contractEndDate = rc.Live_Renewed_Date__c.addMonths(revenueMonths);
                
                // Logic for Revenue P&L Allocation
                if(rc.Invoice_Date__c != null && rc.Payment_Term_After_Days__c != null && revenueMonths > 0){
                    
                    for(Integer i=0; i<revenueMonths; i++){
                        Integer numberOfDays = Integer.valueOf(rc.Payment_Term_After_Days__c);
                        Date beginDate = rc.Invoice_Date__c + numberOfDays ;
                        Date futureDatesforPL=beginDate.addMonths(i);
                        String monthStr = PlaceCPM_Utility.getMonthString(futureDatesforPL.month());
                        Double totalMonthlyAmount = 0.0;
                        Date cliEndDate;
                        if(pnlMap.containsKey(monthStr+' '+futureDatesforPL.year())){
                            Profit_Loss__c pnlRec = pnlMap.get(monthStr+' '+futureDatesforPL.year());
                            if(mapRCToCLI.containsKey(rc.Id)) {
                                    //#133
                                for(Contract_Line_Items__c cli:mapRCToCLI.get(rc.Id)){
                                    cliEndDate = cli.End_Date__c != null && !rc.Auto_renew__C ? cli.End_Date__c : contractEndDate;
                                    
                                    if((pnlRec.Period_Start_Date__c < cliEndDate || pnlRec.Period_Start_Date__c.month() == cliEndDate.month()) && 
                                        (pnlRec.Period_Start_Date__c  >= cli.Start_Date__c || pnlRec.Period_Start_Date__c.month() == cli.Start_Date__c.month())){
                                        totalMonthlyAmount += cli.Total_Amount__c;
                                    }
                                    
                                }
                            }
                            if(totalMonthlyAmount > 0){
                                Revenue_P_L_Allocation__c rpla = new Revenue_P_L_Allocation__c();
                                if(isPl){
                                    rpla.P_L__c=pnlRec.Id;
                                }
                                if(isRevenueAccount){
                                    rpla.Revenue_Account__c= rc.Revenue_Account__c;
                                }
                                if(isRevenueContract){
                                    rpla.Revenue_Contract__c=rc.Id;
                                }
                                if(isGLCode){
                                    rpla.GL_Code__c = listRevenueAccount.get(rc.revenue_account__c).GL_Code__c;
                                }
                                if(isForecastAmount){
                                    rpla.Forecast_Amount__c =totalMonthlyAmount;
                                }

                                revenuePnlAllocations.add(rpla);
                            }
                        }
                    }
                }
                    
                if(rc.Invoice_Date__c != null && rc.Payment_Term_After_Days__c != null && revenueMonths > 0 && listRevenueAccount.get(rc.revenue_account__c).Billing_Cycle__c != null && !revenuePnlAllocations.isEmpty()){
                    // Logic for Revenue Cash Allocation
                        
                    Double cashAmount = 0;
                    Integer billingCycle = Integer.valueOf(listRevenueAccount.get(rc.revenue_account__c).Billing_Cycle__c);
                    Integer numberOfCashAllocationRecords = (Integer)(revenuePnlAllocations.size()/billingCycle);
                    Integer remainingPaymentMonths = Math.mod(revenuePnlAllocations.size(),billingCycle);
                        
                    for(Integer i=0; i<=numberOfCashAllocationRecords;i++){

                        Integer numberOfDays = Integer.valueOf(rc.Payment_Term_After_Days__c);
                        Date beginDate = rc.Invoice_Date__c + numberOfDays ;
                        Date futureDatesforCash = beginDate.addMonths((i*billingCycle));
                        String monthStr = PlaceCPM_Utility.getMonthString(futureDatesforCash.month());
                        //Add the remaining months PNL allocation to create last cash allocation record
                        if(i==numberOfCashAllocationRecords ){
                            if(remainingPaymentMonths >0){
                                for(Integer j=0;j<remainingPaymentMonths;j++){
                                    cashAmount += revenuePnlAllocations[(i*billingCycle)+j].Forecast_Amount__c;
                                }
                            }
                            
                        }else{
                            for(Integer j=0; j<billingCycle;j++){
                                cashAmount += revenuePnlAllocations[(i*billingCycle)+j].Forecast_Amount__c;
                            }
                        }
                            
                        if(cashAmount > 0){
                            if(!existingCashAllocationMap.containsKey(rc.id+'~'+monthStr+' '+futureDatesforCash.year())){
                                Cash_Forecast__c cashRec = cashForecastMap.get(monthStr+' '+futureDatesforCash.year());
                                if(cashRec != null) {
                                    revenueCashAllocations.add(new Revenue_Cash_Allocation__c(Cash_Forecast__c=cashRec.Id,GL_Code__c = listRevenueAccount.get(rc.revenue_account__c).GL_Code__c, Revenue_Account__c= rc.Revenue_Account__c, Revenue_Contract__c=rc.Id,Cash_Date__c = futureDatesforCash, Forecast_Amount__c = cashAmount));
                                }
                            }else{
                                // section to update existing Revenue Cash Allocation if required in future.
                                // #35
                                Revenue_Cash_Allocation__c resultRCA=existingCashAllocationMap.get(rc.id+'~'+monthStr+' '+futureDatesforCash.year());
                                
                                if(resultRCA.Cash_Forecast__r.Period_End_Date__c != null && resultRCA.Cash_Forecast__r.Period_End_Date__c > System.today()){
                                    if(isRCDate){
                                        resultRCA.Cash_Date__c=futureDatesforCash;
                                    }
                                    if(isRCForecastAmount){
                                        resultRCA.Forecast_Amount__c =cashAmount;
                                    }
                                    revenueCashAllocations.add(resultRCA);
                                    listUpdatedRCAId.add(resultRCA.Id);
                                }
                            }
                        }
                        cashAmount = 0;
                    }
                }
            }
                       
            for(Revenue_Cash_Allocation__c rca:mapRCA.values()){
                if(!listUpdatedRCAId.contains(rca.Id)){
                    listRCATobeDeleted.add(mapRCA.get(rca.Id));
                }
            }
            //520
            PlaceCPM_Utility.upsertRecords(revenuePnlAllocations, CONSTANT.REVENUE_PL_ALLOCATION_OBJECT, false);
            PlaceCPM_Utility.upsertRecords(revenueCashAllocations, CONSTANT.REVENUE_CASH_ALLOCATION_OBJECT, false);
            PlaceCPM_Utility.deleteRecords(listRPLATobeDeleted, CONSTANT.REVENUE_PL_ALLOCATION_OBJECT, false);
            PlaceCPM_Utility.deleteRecords(listRCATobeDeleted, CONSTANT.REVENUE_CASH_ALLOCATION_OBJECT, false);
            PlaceCPM_Utility.updateRecords(listRevenueContractsTobeUpdated, CONSTANT.REVENUE_CONTRACT_OBJECT, false);
            
        }catch(Exception ex){
            PlaceCPM_Utility.debugLog(ex.getMessage() + ' at line number ' + ex.getLineNumber());
        }
    }
}
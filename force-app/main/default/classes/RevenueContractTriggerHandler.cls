/*
Description : Handler class to Revenue Contract trigger.
Date Created : 5th June 2019
Change : PCPM-133, PCPM-166, PCPM-33
*/

public with sharing class RevenueContractTriggerHandler implements CommonTriggerHandler{
    
    public void BeforeInsert(List<SObject> newItems){
    }
    
    public void BeforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems){

        //#166
        validateEndDateUpdation((Map<Id,Revenue_Contract__c>) newItems,(Map<Id,Revenue_Contract__c>) oldItems);
        
    }
    
    public void BeforeDelete(Map<Id, SObject> oldItems){
        //#166
        preventRevenueContractDeletion((Map<Id, Revenue_Contract__c>) oldItems);
        // #166
        deletePNLAllocationAndCashAllocation((Map<Id, Revenue_Contract__C>) oldItems);
        
    }
    
    public void AfterInsert(Map<Id, SObject> newItems){
        //#33
        createUpdatePnLAndCashAllocations((Map<Id, Revenue_Contract__c>)newItems , null);   
    }
    
    public void AfterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems){ 
        //#166,#33 
        createUpdatePnLAndCashAllocations((Map<Id, Revenue_Contract__c>)newItems , (Map<Id, Revenue_Contract__c>)oldItems);     
    }
    
    public void AfterDelete(Map<Id, SObject> oldItems){
    }
    
    public void AfterUndelete(Map<Id, SObject> oldItems){
    }
    
    public Boolean IsDisabled(){
        return false;
    }

    private static void preventRevenueContractDeletion (Map<Id, Revenue_Contract__c> oldItems){
        
        for(Revenue_Contract__c rc:oldItems.values()){
            if(rc.Live_Renewed_Date__c < System.today()){
                rc.addError(System.Label.Error_Revenue_Contract_Cannot_Be_Deleted);
            }

        }
    }
    //#166
    private static Set<Contract_Line_Items__c> updateCLIEndDateToRCEndDate(Set<Revenue_Contract__c> setRevenueContractWithEndDateReduced,Map<String,List<Contract_Line_Items__c>> mapRCToCLI){
        Set<Contract_Line_Items__c> setCLI = new Set<Contract_Line_Items__c>();
        //Manmeet
        Boolean isEndDate = false;
        if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.CONTRACT_LINE_ITEM_OBJECT,'End_date__c',Constant.ACTION_TYPE_UPDATE)){
            isEndDate = true;
        }
        for(Revenue_Contract__c rc:setRevenueContractWithEndDateReduced){
            if(mapRCToCLI.containsKey(rc.Id)){
                for(Contract_Line_Items__c cli:mapRCToCLI.get(rc.Id)){
                    if(((cli.End_date__c==null && rc.Contract_End_date__c != null) || cli.End_date__c > rc.Contract_End_date__c )
                    ){
                        if(isEndDate){
                            cli.End_date__c = rc.Contract_End_date__c;
                            setCLI.add(cli);
                        }
                    }
                }
            }
        }
        return setCLI;
    }

    //#33
    private static void createUpdatePnLAndCashAllocations(Map<Id, Revenue_Contract__c> newItems , Map<Id, Revenue_Contract__c> oldItems){
        Map<String, Revenue_Contract__c> sowNewItems = new Map<String, Revenue_Contract__c>();
        Map<String, Revenue_Contract__c> sowOldItems = new Map<String, Revenue_Contract__c>();
        Map<String, Revenue_Contract__c> rcNewItems = new Map<String, Revenue_Contract__c>();
        Map<String, Revenue_Contract__c> rcNewItemsForBatch = new Map<String, Revenue_Contract__c>();
        Map<String, Revenue_Contract__c> rcOldItems = new Map<String, Revenue_Contract__c>();
        //PCPM-315
        //Id revenueContractRecordTypeId = Schema.SObjectType.Revenue_Contract__c.getRecordTypeInfosByName().get(CONSTANT.REVENUE_CONTRACT_RECORD_TYPE_RC).getRecordTypeId();
        Id sowRecordTypeId = Schema.SObjectType.Revenue_Contract__c.getRecordTypeInfosByName().get(CONSTANT.REVENUE_CONTRACT_RECORD_TYPE_SOW).getRecordTypeId();
        
        //In case of insert.
        if(oldItems==null){
            for(Revenue_Contract__c rcsow : newItems.values()){
             if(rcsow.recordTypeId == sowRecordTypeId){
                    sowNewItems.put(rcsow.Id,rcsow);
              }
            }

        }else{ // In case of update.
            for(Revenue_Contract__c rcsow : newItems.values()){
             if(rcsow.recordTypeId == sowRecordTypeId){
                    sowNewItems.put(rcsow.Id,rcsow);
                    sowOldItems.put(rcsow.Id,oldItems.get(rcsow.Id));
              }else { // PCPM-315 | if (rcsow.recordTypeId == revenueContractRecordTypeId) {
                    if(rcsow.Batch_Process_Execution__c){
                        rcNewItemsForBatch.put(rcsow.Id, rcsow);
                    }else{
                        rcNewItems.put(rcsow.Id,rcsow);
                        rcOldItems.put(rcsow.Id,oldItems.get(rcsow.Id));
                    }
              }

            }

        }
        
        if(!sowNewItems.values().isEmpty()){
            createUpdateSowPnLAndCashAllocations(sowNewItems , sowOldItems);        
        }
        if(!rcNewItems.values().isEmpty()){
            createUpdateRevenueContractPnLAndCashAllocations(rcNewItems , rcOldItems);
        }
        
        //This logic is implemented to move the creation of PL and Cash in bulk
        if(!rcNewItemsForBatch.values().isEmpty()){
            Id apexClassId;
            For(ApexClass ac : [SELECT id From ApexClass where Name =: CONSTANT.PANDLALLOCATIONSBATCHCLASS]){
                apexClassId = ac.Id;
            }
            if(apexClassId != null && !PlaceCPM_Utility.isBatchRunning(apexClassId)){
                Database.executeBatch(new CreatePLAndCashForecastBatchable(), Integer.valueOf(PlaceCPM_Utility.defaultSetting.PLandCashBatchFrequency__c == null ? 50 : PlaceCPM_Utility.defaultSetting.PLandCashBatchFrequency__c));
            }
        }
    }
    //#33
    // @param newItems is the list of Account_Role__c which is going to create
    // @return null
    //TODO: Block this method for update of revenue Contract when SOWLIs are present. Otherwise also allow only when TOtalAmount or End Date is updated
    //TODO: Block past Pnl and Cash allocation to be updated
    private static void createUpdateSowPnLAndCashAllocations(Map<String, Revenue_Contract__c> newRevenueContracts, Map<String, Revenue_Contract__c> oldRevenueContracts){
        List<String> listRevenueContractId = new List<String>();
        Map<String,List<SOW_Line_Item__c>> mapSOWToSOWLI = new Map<String,List<SOW_Line_Item__c>>();
        Map<String,List<Revenue_P_L_Allocation__c>> mapSOWToRPLA = new Map<String,List<Revenue_P_L_Allocation__c>>();
        Map<String, Double> mapMonthToAmount = new Map<String, Double>();
        List<Revenue_P_L_Allocation__c> rplaToBeUpserted = new List<Revenue_P_L_Allocation__c>();
        List<Revenue_P_L_Allocation__c> rplaToBeDeleted = new List<Revenue_P_L_Allocation__c>();
        Map<String,Map<String,Revenue_P_L_Allocation__c>> mapSOWToMonthToRPLA = new Map<String,Map<String,Revenue_P_L_Allocation__c>>();
        Map<String,Map<String,Revenue_Cash_Allocation__c>> mapSOWToMonthToRCA = new Map<String,Map<String,Revenue_Cash_Allocation__c>>();
        List<Revenue_Cash_Allocation__c> cashAllocationToBeUpserted = new List<Revenue_Cash_Allocation__c>();
        List<String> listExistingCashAllocationToBeReused = new List<String>();
        List<Revenue_Cash_Allocation__c> listRCAToBeDeleted = new List<Revenue_Cash_Allocation__c>();
        Map<String,Double> mapMonthToCashAmount;
        List<Revenue_Contract__c> listNewRevenueContract = new List<Revenue_Contract__c>();
        
        Map<String, Cash_Forecast__c> cashForecastMap;
        Map<String, Profit_Loss__c> pnlMap;
            
        List<String> listRevenueAccountId = new List<String>();
        Integer totalMonths;
        Date starDate,currentDate;
        Double monthlyAmount;

        Set<String> monthsForPL = new Set<String>();
        Date minStartDate;
        Date maxEndDate;//556
        
        for(Revenue_Contract__c rc:newRevenueContracts.values()){
            if(oldRevenueContracts.values().isEmpty() 
            || rc.Total_SOW_Line_Item_Amount__c != oldRevenueContracts.get(rc.Id).Total_SOW_Line_Item_Amount__c
            || rc.Total_Amount__c != oldRevenueContracts.get(rc.Id).Total_Amount__c
            || rc.Payment_Term_After_Days__c != oldRevenueContracts.get(rc.Id).Payment_Term_After_Days__c
            || rc.Contract_Start_Date__c != oldRevenueContracts.get(rc.Id).Contract_Start_Date__c
            || rc.Invoice_Date__c != oldRevenueContracts.get(rc.Id).Invoice_Date__c){
                
                listNewRevenueContract.add(rc);
                listRevenueAccountId.add(rc.Revenue_Account__c);
                listRevenueContractId.add(rc.Id);
                //getting the minimum date
                if(minStartDate == null || rc.Contract_Start_Date__c < minStartDate){
                    minStartDate = rc.Contract_Start_Date__c;
                }
                //getting the maximum end date //556
                if(maxEndDate == null || rc.Contract_End_Date__c > maxEndDate){
                    maxEndDate = rc.Contract_End_Date__c;
                }
            }
        }
        
        //preparting map of all the months from minimum start date to assumption date 
        //556
        Integer revenueMonths = minStartDate.monthsBetween(maxEndDate)+1;
        //Integer forecastDuration = PlaceCPM_Utility.assumptionForecastDuration;
        //Integer revenueMonths = minStartDate.monthsBetween(System.Today()) + forecastDuration;
        Date endDate = minStartDate.addMonths(revenueMonths);
        // PCPM-315 | Namita
        for(Date iDate = minStartDate; iDate <= endDate; iDate = iDate.addMonths(1)){
            monthsForPL.add(PlaceCPM_Utility.getMonthString(iDate.month())+' '+iDate.year());
        }

        if(!listRevenueContractId.isEmpty()){
            Map<String,Revenue_Account__c> listRevenueAccount;
            List<Revenue_Contract__c> listSOW;
            if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.revenueAccountObject,'Id,GL_Code__c, Billing_Cycle__c',Constant.ACTION_TYPE_ACCESS)){
                listRevenueAccount = new Map<String,Revenue_Account__c>([SELECT Id,GL_Code__c, Billing_Cycle__c 
                                                                                                FROM Revenue_Account__c 
                                                                                                WHERE ID IN :listRevenueAccountId]);
       		 }
            if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.SOW_LINE_ITEM_OBJECT,'ID, Line_Item_Amount__c, Month__c, Year__c, Revenue_Contract_Statement_of_Work__c',Constant.ACTION_TYPE_ACCESS) &&
               PlaceCPM_Utility.checkAccessiblityOfFields(Constant.REVENUE_PL_ALLOCATION_OBJECT,'ID,Revenue_Contract__c',Constant.ACTION_TYPE_ACCESS) &&
               PlaceCPM_Utility.checkAccessiblityOfFields(Constant.REVENUE_CASH_ALLOCATION_OBJECT,'Id, Name, Revenue_Contract__c',Constant.ACTION_TYPE_ACCESS) &&
               PlaceCPM_Utility.checkAccessiblityOfFields(Constant.PL_OBJECT,'Period_Start_Date__c',Constant.ACTION_TYPE_ACCESS) &&
               PlaceCPM_Utility.checkAccessiblityOfFields(Constant.CASH_FORECAST_OBJECT,'Period_End_Date__c',Constant.ACTION_TYPE_ACCESS) 
              ){
                listSOW = [SELECT ID,
                           (SELECT ID, Line_Item_Amount__c, Month__c, Year__c, Revenue_Contract_Statement_of_Work__c
                            FROM SOW_Line_Items__r),
                           (SELECT ID,Revenue_Contract__c, P_L__r.Period_Start_Date__c, P_L__r.Name
                            FROM Revenue_P_L_Allocations__r),
                           (SELECT Id, Name, Cash_Forecast__r.Period_End_Date__c, Cash_Forecast__r.Name,Revenue_Contract__c 
                            FROM Revenue_Cash_Allocations__r) 
                           FROM Revenue_Contract__c WHERE ID IN :listRevenueContractId];
            }
            try{
                for(Revenue_Contract__c sow:listSOW){
                    // Creating Map SOW to the corresponding line Item 
                    for(SOW_Line_Item__c sli : sow.SOW_Line_Items__r){
                        if(!mapSOWToSOWLI.containsKey(sli.Revenue_Contract_Statement_of_Work__c)){
                            mapSOWToSOWLI.put(sli.Revenue_Contract_Statement_of_Work__c,new List<SOW_Line_Item__c>());
                        }
                        mapSOWToSOWLI.get(sli.Revenue_Contract_Statement_of_Work__c).add(sli);
                    }
                    // Creating Map SOW to the corresponding Revenue PL Allocation
                    for(Revenue_P_L_Allocation__c pla : sow.Revenue_P_L_Allocations__r){
                        if(!mapSOWToRPLA.containsKey(pla.Revenue_Contract__c)){
                            mapSOWToRPLA.put(pla.Revenue_Contract__c,new List<Revenue_P_L_Allocation__c>());
                        }
                        mapSOWToRPLA.get(pla.Revenue_Contract__c).add(pla);

                        if(!mapSOWToMonthToRPLA.containsKey(pla.Revenue_Contract__c)){
                            mapSOWToMonthToRPLA.put(pla.Revenue_Contract__c,new Map<String,Revenue_P_L_Allocation__c>());
                        }
                        mapSOWToMonthToRPLA.get(pla.Revenue_Contract__c).put(pla.P_L__r.Name,pla);
                    }

                    for(Revenue_Cash_Allocation__c rca : sow.Revenue_Cash_Allocations__r){
                        if(!mapSOWToMonthToRCA.containsKey(rca.Revenue_Contract__c)){
                            mapSOWToMonthToRCA.put(rca.Revenue_Contract__c,new Map<String,Revenue_Cash_Allocation__c>());
                        }
                        mapSOWToMonthToRCA.get(rca.Revenue_Contract__c).put(rca.Cash_Forecast__r.Name,rca);
                    }
                } 

                pnlMap = getMonthsforPLAllocation(listNewRevenueContract, monthsForPL);
                cashForecastMap = getMonthsforCashAllocation(listNewRevenueContract,listRevenueAccount, monthsForPL);
                
                //Manmeet
                Boolean isPLForecastAmount = false, isPLRevenueAccount = false, isPLR = false, isPLC = false;
                Boolean isPLRevenueContract = false, isGlCode = false, isCashDate = false, isCashForecastAmount = false;
                Boolean isCashForecast = false, isCashRevenueAccount = false, isCashRevenueContract = false;
                Boolean isCashCashDate = false, isCashGLCode = false, isForecastAmount = false;
                if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.REVENUE_PL_ALLOCATION_OBJECT,'Forecast_Amount__c',Constant.ACTION_TYPE_UPDATE) && PlaceCPM_Utility.checkAccessiblityOfFields(Constant.REVENUE_PL_ALLOCATION_OBJECT,'Forecast_Amount__c',Constant.ACTION_TYPE_INSERT)){
                    isPLForecastAmount = true;
                }
                if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.REVENUE_PL_ALLOCATION_OBJECT,'Revenue_Account__c',Constant.ACTION_TYPE_UPDATE) && PlaceCPM_Utility.checkAccessiblityOfFields(Constant.REVENUE_PL_ALLOCATION_OBJECT,'Revenue_Account__c',Constant.ACTION_TYPE_INSERT)){
                    isPLRevenueAccount = true;
                }
                if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.REVENUE_PL_ALLOCATION_OBJECT,'P_L__c',Constant.ACTION_TYPE_INSERT)){
                   isPLC = true;
                }
                if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.REVENUE_PL_ALLOCATION_OBJECT,'Revenue_Contract__c',Constant.ACTION_TYPE_UPDATE) && PlaceCPM_Utility.checkAccessiblityOfFields(Constant.REVENUE_PL_ALLOCATION_OBJECT,'Revenue_Contract__c',Constant.ACTION_TYPE_INSERT)){
                    isPLRevenueContract = true;
                }
                if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.REVENUE_PL_ALLOCATION_OBJECT,'GL_Code__c',Constant.ACTION_TYPE_UPDATE) && PlaceCPM_Utility.checkAccessiblityOfFields(Constant.REVENUE_PL_ALLOCATION_OBJECT,'GL_Code__c',Constant.ACTION_TYPE_INSERT)){
                    isGlCode = true;
                }
                if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.REVENUE_CASH_ALLOCATION_OBJECT,'Cash_Date__c',Constant.ACTION_TYPE_UPDATE) && PlaceCPM_Utility.checkAccessiblityOfFields(Constant.REVENUE_CASH_ALLOCATION_OBJECT,'Cash_Date__c',Constant.ACTION_TYPE_INSERT)){
                    isCashDate = true;
                }
                if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.REVENUE_CASH_ALLOCATION_OBJECT,'Forecast_Amount__c',Constant.ACTION_TYPE_UPDATE) && PlaceCPM_Utility.checkAccessiblityOfFields(Constant.REVENUE_CASH_ALLOCATION_OBJECT,'Forecast_Amount__c',Constant.ACTION_TYPE_INSERT)){
                    isCashForecastAmount = true;
                }
                
                if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.REVENUE_CASH_ALLOCATION_OBJECT,'Cash_Forecast__c',Constant.ACTION_TYPE_INSERT)){
                    isCashForecast = true;
                }
                if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.REVENUE_CASH_ALLOCATION_OBJECT,'Revenue_Account__c',Constant.ACTION_TYPE_UPDATE) && PlaceCPM_Utility.checkAccessiblityOfFields(Constant.REVENUE_CASH_ALLOCATION_OBJECT,'Revenue_Account__c',Constant.ACTION_TYPE_INSERT)){
                    isCashRevenueAccount = true;
                }
                if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.REVENUE_CASH_ALLOCATION_OBJECT,'Revenue_Contract__c',Constant.ACTION_TYPE_UPDATE) && PlaceCPM_Utility.checkAccessiblityOfFields(Constant.REVENUE_CASH_ALLOCATION_OBJECT,'Revenue_Contract__c',Constant.ACTION_TYPE_INSERT)){
                    isCashRevenueContract = true;
                }
                if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.REVENUE_CASH_ALLOCATION_OBJECT,'Cash_Date__c',Constant.ACTION_TYPE_UPDATE) && PlaceCPM_Utility.checkAccessiblityOfFields(Constant.REVENUE_CASH_ALLOCATION_OBJECT,'Cash_Date__c',Constant.ACTION_TYPE_INSERT)){                                    
                    isCashCashDate = true;
                }
                if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.REVENUE_CASH_ALLOCATION_OBJECT,'Forecast_Amount__c',Constant.ACTION_TYPE_UPDATE) && PlaceCPM_Utility.checkAccessiblityOfFields(Constant.REVENUE_CASH_ALLOCATION_OBJECT,'Forecast_Amount__c',Constant.ACTION_TYPE_INSERT)){
                    isForecastAmount = true; 
                }
                if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.REVENUE_CASH_ALLOCATION_OBJECT,'GL_Code__c',Constant.ACTION_TYPE_UPDATE) && PlaceCPM_Utility.checkAccessiblityOfFields(Constant.REVENUE_CASH_ALLOCATION_OBJECT,'GL_Code__c',Constant.ACTION_TYPE_INSERT)){
                    isCashGLCode = true;
                }
                
                //Start PL Allocation creation/updation
                for(Revenue_Contract__c sow :listNewRevenueContract){
                    totalMonths = Integer.valueOf(sow.Contract_Months__c);//PlaceCPM_Utility.getRevenueMonths(sow);//556
                    //#250
                    if(totalMonths > 0){
                        if(mapSOWToSOWLI.containsKey(sow.Id) && !mapSOWToSOWLI.get(sow.Id).isEmpty()){
                            //Creating Map to sum up the amount of each month
                            for(SOW_Line_Item__c sli : mapSOWToSOWLI.get(sow.Id)){
                                if(!mapMonthToAmount.containsKey(sli.Month__c)){
                                    mapMonthToAmount.put(sli.Month__c+' '+sli.Year__c,sli.Line_Item_Amount__c);
                                }else{
                                    mapMonthToAmount.put(sli.Month__c+' '+sli.Year__c,mapMonthToAmount.get(sli.Month__c) + sli.Line_Item_Amount__c) ;
                                }
                            }
                            
                        }else{
                            //Create according to SOW start/end date when SOWLI not created
                            starDate = sow.Live_Renewed_Date__c;
                            monthlyAmount = sow.Total_Amount__c / totalMonths;
                            for(Integer i=0; i<totalMonths; i++){
                                currentDate = starDate.addMonths(i);
                                mapMonthToAmount.put(PlaceCPM_Utility.getMonthString(currentDate.month())+' '+currentDate.year(),monthlyAmount);

                            }
                        }
                    }

                    //Inserted/Update the PnLs
                    for(String monthYear:mapMonthToAmount.keySet()){
                        Revenue_P_L_Allocation__c rpla;
                        if(mapSOWToMonthToRPLA.containsKey(sow.Id) && mapSOWToMonthToRPLA.get(sow.Id).containsKey(monthYear)){
                            rpla = mapSOWToMonthToRPLA.get(sow.Id).get(monthYear);
                            if(isPLForecastAmount){
                                rpla.Forecast_Amount__c = mapMonthToAmount.get(monthYear);
                            }
						}else{
                            //Insert RPLA
                            rpla = new Revenue_P_L_Allocation__c();
                            if(isPLRevenueAccount){
                                rpla.Revenue_Account__c= sow.Revenue_Account__c;
                            }
                            if(isPLForecastAmount){
                                rpla.Forecast_Amount__c = mapMonthToAmount.get(monthYear);
                            }
                            rpla.P_L__r=pnlMap.get(monthYear);
                            if(isPLC){
                                rpla.P_L__c=pnlMap.get(monthYear).Id;
                            }
                            if(isPLRevenueContract){
                                rpla.Revenue_Contract__c=sow.Id;
                            }
                            if(isGlCode){
                                rpla.GL_Code__c = listRevenueAccount.get(sow.revenue_account__c).GL_Code__c;
                            }
                        }
                        rplaToBeUpserted.add(rpla);

                    }

                    //Delete the Extra PnLs
                    if(mapSOWToRPLA.containsKey(sow.Id)){
                        for(Revenue_P_L_Allocation__c rpla:mapSOWToRPLA.get(sow.Id)){
                            if(! mapMonthToAmount.containsKey(rpla.P_L__r.Name)){
                                rplaToBeDeleted.add(rpla);

                            }
                        }
                    }
                    mapMonthToCashAmount = new Map<String,Double>();
                    Map<String,Date> mapMonthYearToCashDate = new Map<String,Date>();

                    //Inserting and Updating Cash Allocation Record
                    if(sow.Invoice_Date__c != null && sow.Payment_Term_After_Days__c != null && totalMonths > 0 && listRevenueAccount.get(sow.revenue_account__c).Billing_Cycle__c != null && !rplaToBeUpserted.isEmpty()){
                        //Updated Logic for Revenue Contract
                        for(Revenue_P_L_Allocation__c rpla:rplaToBeUpserted){
                            Date cashDate = getCorrespondingCashDate(sow,rpla,Integer.valueOf(listRevenueAccount.get(sow.revenue_account__c).Billing_Cycle__c));
                            String cashMonthYear = PlaceCPM_Utility.getMonthString( cashDate.month())+' '+ cashDate.year();
                            mapMonthYearToCashDate.put(cashMonthYear,cashDate);
                            if(!mapMonthToCashAmount.containsKey(cashMonthYear)){
                                mapMonthToCashAmount.put(cashMonthYear,rpla.Forecast_Amount__c);
                            }else{
                                mapMonthToCashAmount.put(cashMonthYear, mapMonthToCashAmount.get(cashMonthYear) + rpla.Forecast_Amount__c) ;
                            }
                        }
                        Revenue_Cash_Allocation__c resultRCA;
                        for(String monthYear : mapMonthToCashAmount.keySet()){
                            if(mapSOWToMonthToRCA.containsKey(sow.Id) && mapSOWToMonthToRCA.get(sow.Id).containsKey(monthYear)){ 
                                
                                // section to update existing Revenue Cash Allocation if required in future.
                                // #35
                                resultRCA=mapSOWToMonthToRCA.get(sow.id).get(monthYear);
                                if(isGlCode){
                                    resultRCA.Cash_Date__c=mapMonthYearToCashDate.get(monthYear);//sow.contract_start_date__c;
                                }
                                if(isCashForecastAmount){
                                    resultRCA.Forecast_Amount__c = mapMonthToCashAmount.get(monthYear);
                                }
                                listExistingCashAllocationToBeReused.add(resultRCA.Id);
                            }else{
                                Cash_Forecast__c cashRec = cashForecastMap.get(monthYear);
                                if(cashRec != null){
                                    resultRCA = new Revenue_Cash_Allocation__c();
                                    if(isCashForecast){
                                        resultRCA.Cash_Forecast__c=cashRec.Id;
                                    }
                                    if(isCashRevenueAccount){
                                        resultRCA.Revenue_Account__c= sow.Revenue_Account__c;
                                    }
                                    if(isCashRevenueContract){
                                        resultRCA.Revenue_Contract__c=sow.Id;
                                    }
                                    if(isCashCashDate){                                    
                                        resultRCA.Cash_Date__c = mapMonthYearToCashDate.get(monthYear);
                                    }
                                    if(isForecastAmount){
                                        resultRCA.Forecast_Amount__c = mapMonthToCashAmount.get(monthYear);
                                    }
                                    if(isCashGLCode){
                                        resultRCA.GL_Code__c = listRevenueAccount.get(sow.revenue_account__c).GL_Code__c;
                                    } 
                                }
                            }
                            cashAllocationToBeUpserted.add(resultRCA);
                        }

                        //Delete Extra Cash Allocations
                        if(mapSOWToMonthToRCA.containsKey(sow.Id)){
                            for(Revenue_Cash_Allocation__c rca  : mapSOWToMonthToRCA.get(sow.Id).values()){
                                if(! listExistingCashAllocationToBeReused.contains(rca.Id)){
                                    listRCAToBeDeleted.add(rca);
                                }

                            }
                        }
                
                    }
                    //Resetting the Month To Amount map    
                    mapMonthToAmount = new Map<String, Double>(); 
                }
                PlaceCPM_Utility.upsertRecords(rplaToBeUpserted, CONSTANT.REVENUE_PL_ALLOCATION_OBJECT, false); //520
                PlaceCPM_Utility.upsertRecords(cashAllocationToBeUpserted, CONSTANT.REVENUE_CASH_ALLOCATION_OBJECT, false);//520
                PlaceCPM_Utility.deleteRecords(rplaToBeDeleted, CONSTANT.REVENUE_PL_ALLOCATION_OBJECT, false); //520
                PlaceCPM_Utility.deleteRecords(listRCAToBeDeleted, CONSTANT.REVENUE_CASH_ALLOCATION_OBJECT, false);//520
            }catch(Exception ex){
                PlaceCPM_Utility.debugLog(ex.getMessage() + ' at line number ' + ex.getLineNumber());
            }
        }// end if
    }
    //#250
    /* @param 
       sow: Statement Of Work whose invoice date is needed to calculate the Cash Month in which PnL lies   
       rpla: PL Allocation which needs to be added to a specific Cash record 
       billingCycle: Billing cycle from Revenue Account
       @return null
    */
    private static Date getCorrespondingCashDate(Revenue_Contract__c sow,Revenue_P_L_Allocation__c rpla,Integer billingCycle ){
        Integer startingMonthNumber = sow.Invoice_Date__c.month();
        Integer startingYear = sow.Invoice_Date__c.year();
        
        Integer rplaMonthNumber = rpla.P_L__r.Period_Start_Date__c.month();
        Integer rplaYear = rpla.P_L__r.Period_Start_Date__c.year();
        Integer cashMonth = 0;
        Date cashDate;
        if(rplaYear != startingYear){
            cashMonth= Integer.valueOf(Math.floor(( 12*(rplaYear -startingYear)+rplaMonthNumber-startingMonthNumber)/billingCycle)*billingCycle);
        
        }else{
            cashMonth= Integer.valueOf(Math.floor((rplaMonthNumber-startingMonthNumber)/billingCycle)*billingCycle);
        
        }
        return sow.Invoice_Date__c.addDays(Integer.valueOf(sow.Payment_Term_After_Days__c)).addMonths(cashMonth);

    }
    
    public static void createUpdateRevenueContractPnLAndCashAllocations(map<String, Revenue_Contract__c> newRevenueContracts, 
                                                                        map<String, Revenue_Contract__c> oldRevenueAccounts){
        
        Map<String,Revenue_Cash_Allocation__c> mapRCA = new Map<String,Revenue_Cash_Allocation__c> ();
        List<String> listUpdatedRCAId = new List<String> ();
         List<Revenue_Cash_Allocation__c> listRCATobeDeleted = new  List<Revenue_Cash_Allocation__c>();
        List<Revenue_P_L_Allocation__c> listRPLATobeDeleted = new List<Revenue_P_L_Allocation__c>();
        List<String> listRevenueAccountId = new List<String>();
        List<String> listRevenueContractId = new List<String>();
        List<Contract_Line_Items__c> listCLITobeUpdated = new List<Contract_Line_Items__c>();
        Map<String,List<Contract_Line_Items__c>> mapRCToCLI = new Map<String,List<Contract_Line_Items__c>>();
        Set<String> monthsForPL = new Set<String>();
        Map<String, Revenue_Cash_Allocation__c> existingCashAllocationMap = new Map<String, Revenue_Cash_Allocation__c>();
        Date minStartDate;
        
        try{
            for(Revenue_Contract__c rc: newRevenueContracts.values()){
                listRevenueAccountId.add(rc.Revenue_Account__c);
                listRevenueContractId.add(rc.Id);
                //getting the minimum date
                if(minStartDate == null || rc.Contract_Start_Date__c < minStartDate){
                    minStartDate = rc.Contract_Start_Date__c;
                }
            }

            //preparting map of all the months from minimum start date to assumption date
            Integer forecastDuration = PlaceCPM_Utility.assumptionForecastDuration;
            Integer revenueMonthsTemp = minStartDate.monthsBetween(System.Today()) + forecastDuration;
            Date endDate = minStartDate.addMonths(revenueMonthsTemp);
            // PCPM-315 | Namita
            for(Date iDate = minStartDate; iDate <= endDate; iDate = iDate.addMonths(1)){
                monthsForPL.add(PlaceCPM_Utility.getMonthString(iDate.month())+' '+iDate.year());
            }
            Map<String,Revenue_Account__c> listRevenueAccount;
			if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.revenueAccountObject,'Id,GL_Code__c, Billing_Cycle__c',Constant.ACTION_TYPE_ACCESS)){
            	listRevenueAccount = new Map<String,Revenue_Account__c>(
                                        [SELECT Id,GL_Code__c, Billing_Cycle__c FROM Revenue_Account__c 
                                         WHERE ID IN :listRevenueAccountId]);
        	}	
            //#133
            Map<String,Contract_Line_Items__c > mapContractLineItems;
            if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.CONTRACT_LINE_ITEM_OBJECT,'ID,Revenue_Contract_Details__c, Start_Date__c,End_Date__c, Total_Amount__c',Constant.ACTION_TYPE_ACCESS)){
                mapContractLineItems = new Map<String,Contract_Line_Items__c>(
                                                                [SELECT ID,Revenue_Contract_Details__c, Start_Date__c, 
                                                                End_Date__c, Total_Amount__c FROM Contract_Line_Items__c
                                                                WHERE Revenue_Contract_Details__c IN :listRevenueContractId]);
        	}
            for(Contract_Line_Items__c cli:mapContractLineItems.values()){
                if(!mapRCToCLI.containsKey(cli.Revenue_Contract_Details__c)){
                    mapRCToCLI.put(cli.Revenue_Contract_Details__c,new List<Contract_Line_Items__c>());
                }
                mapRCToCLI.get(cli.Revenue_Contract_Details__c).add(cli);
            }

            if(newRevenueContracts != null && newRevenueContracts.size()>0){
                
                Set<String> revenueContractIds = new Set<String>();
                Set<String> revenueContractIdsForCash = new Set<String>();
                Set<String> revenueContractIdsForPL = new Set<String>();
                Set<Revenue_Contract__c> setRevenueContractWithEndDateReduced = new Set<Revenue_Contract__c>();
                
                for(Revenue_Contract__c rc: newRevenueContracts.values()){
                    if((rc.Contract_End_Date__c != null && rc.Contract_End_Date__c != oldRevenueAccounts.get(rc.Id).Contract_End_Date__c ) 
                        || (rc.Total_Monthly_Revenue__c != null && rc.Total_Monthly_Revenue__c != oldRevenueAccounts.get(rc.Id).Total_Monthly_Revenue__c)){
                            //#166
                            if(rc.Contract_End_Date__c != null && rc.Contract_End_Date__c != oldRevenueAccounts.get(rc.Id).Contract_End_Date__c){   
                                setRevenueContractWithEndDateReduced.add(rc);
                            }
                        revenueContractIds.add(rc.Id);
                    }
                    
                    if((listRevenueAccount.get(rc.revenue_account__c).Billing_Cycle__c != Null) 
                        || (rc.Payment_Term_After_Days__c != Null && rc.Payment_Term_After_Days__c != oldRevenueAccounts.get(rc.Id).Payment_Term_After_Days__c)){
                        revenueContractIdsForCash.add(rc.Id);
                    }
                }
                if(revenueContractIds != null && revenueContractIds.size()>0){
                //#166
                //Updating the ContractLineItem record's end date that exceeds the updated End Date to newly reduced Contract End date
                if(!setRevenueContractWithEndDateReduced.isEmpty()){
                    listCLITobeUpdated.addAll(updateCLIEndDateToRCEndDate(setRevenueContractWithEndDateReduced,mapRCToCLI));
                    
                }
                Map<String, Revenue_P_L_Allocation__c> existingPLAllocationMap = new Map<String, Revenue_P_L_Allocation__c>();
                List<Revenue_Contract__c> listRevenueContract; 
                if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.REVENUE_PL_ALLOCATION_OBJECT,'Id,Name, P_L__c,Revenue_Contract__c, Forecast_Amount__c',Constant.ACTION_TYPE_ACCESS) && 
                   PlaceCPM_Utility.checkAccessiblityOfFields(Constant.REVENUE_CASH_ALLOCATION_OBJECT,'Id, Name,Revenue_Contract__c',Constant.ACTION_TYPE_ACCESS) &&
                   PlaceCPM_Utility.checkAccessiblityOfFields(Constant.PL_OBJECT,'Period_Start_Date__c, Period_End_Date__c',Constant.ACTION_TYPE_ACCESS) &&
                   PlaceCPM_Utility.checkAccessiblityOfFields(Constant.CASH_FORECAST_OBJECT,'Period_End_Date__c',Constant.ACTION_TYPE_ACCESS)){
                    listRevenueContract = [Select Id,
                                           (Select Id,P_L__r.Period_Start_Date__c, P_L__r.Period_End_Date__c, Name, P_L__c, P_L__r.Name,
                                            Revenue_Contract__c, Forecast_Amount__c
                                            From Revenue_P_L_Allocations__r),
                                           (Select Id, Name, Cash_Forecast__r.Period_End_Date__c, Cash_Forecast__r.Name,Revenue_Contract__c 
                                            From Revenue_Cash_Allocations__r)
                                           From Revenue_Contract__c 
                                           Where Id IN: revenueContractIds];
                }    
                for(Revenue_Contract__c rc:listRevenueContract){
                    for(Revenue_P_L_Allocation__c pla:rc.Revenue_P_L_Allocations__r){
                        //#35
                        existingPLAllocationMap.put(pla.Revenue_Contract__c+'~'+pla.P_L__r.Name, pla);
                    }
                    for(Revenue_Cash_Allocation__c cash: rc.Revenue_Cash_Allocations__r){
                        //#35
                        existingCashAllocationMap.put(cash.Revenue_Contract__c+'~'+cash.Cash_Forecast__r.Name, cash);
                        mapRCA.put(cash.Id,cash);
                    }
                }
                /*
                List<Revenue_P_L_Allocation__c> existingPLAllocation = [Select Id,P_L__r.Period_Start_Date__c, P_L__r.Period_End_Date__c, Name, P_L__c, P_L__r.Name, 
                                                                        Revenue_Contract__c, Forecast_Amount__c
                                                                        From Revenue_P_L_Allocation__c 
                                                                        Where Revenue_Contract__c IN: revenueContractIds];
                if(existingPLAllocation != null && existingPLAllocation.size()>0){
                    for(Revenue_P_L_Allocation__c pla: existingPLAllocation){
                        //#35
                        existingPLAllocationMap.put(pla.Revenue_Contract__c+'~'+pla.P_L__r.Name, pla);
                    }
                }
                
                List<Revenue_Cash_Allocation__c> existingCashAllocation = [Select Id, Name, Cash_Forecast__r.Period_End_Date__c, Cash_Forecast__r.Name,Revenue_Contract__c 
                                                                                From Revenue_Cash_Allocation__c
                                                                                Where Revenue_Contract__c IN: revenueContractIds];
                if(existingCashAllocation != null && existingCashAllocation.size()>0){
                    for(Revenue_Cash_Allocation__c cash: existingCashAllocation){
                        //#35
                        existingCashAllocationMap.put(cash.Revenue_Contract__c+'~'+cash.Cash_Forecast__r.Name, cash);
                        mapRCA.put(cash.Id,cash);
                    }
                }*/
                
                Map<String, Profit_Loss__c> pnlMap = getMonthsforPLAllocation(newRevenueContracts.values(), monthsForPL);
                Map<String, Cash_Forecast__c> cashForecastMap = getMonthsforCashAllocation(newRevenueContracts.values(),listRevenueAccount, monthsForPL);
                
                List<Revenue_P_L_Allocation__c> revenuePnlAllocations = new List<Revenue_P_L_Allocation__c>();
                List<Revenue_Cash_Allocation__c> revenueCashAllocations = new List<Revenue_Cash_Allocation__c>();
                //PCPM-315
                Id recurringRecordTypeId = Schema.SObjectType.Revenue_Contract__c.getRecordTypeInfosByName().get(CONSTANT.RECURRING_RECORD_TYPE_RC).getRecordTypeId();
                Id nonRecurringRecordTypeId = Schema.SObjectType.Revenue_Contract__c.getRecordTypeInfosByName().get(CONSTANT.NON_RECURRING_RECORD_TYPE_RC).getRecordTypeId();
                
                Boolean isPLRevenueAccount = false, isPLRevenueContract = false, isPLGLCode = false, isPLForecastAmount = false;
                Boolean isCashForecast = false, isCashRevenueAccount = false, isCashGLCode = false, isCashRevenueContract = false, isCashDate = false, isCashForecastAmount = false;
                    
                    if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.REVENUE_CASH_ALLOCATION_OBJECT,'Cash_Forecast__c',Constant.ACTION_TYPE_INSERT)){
                        isCashForecast = true;
                    }
                    if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.REVENUE_CASH_ALLOCATION_OBJECT,'Revenue_Account__c',Constant.ACTION_TYPE_INSERT) && PlaceCPM_Utility.checkAccessiblityOfFields(Constant.REVENUE_CASH_ALLOCATION_OBJECT,'Revenue_Account__c',Constant.ACTION_TYPE_UPDATE)){
                        isCashRevenueAccount = true;
                    }
                    if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.REVENUE_CASH_ALLOCATION_OBJECT,'GL_Code__c',Constant.ACTION_TYPE_INSERT) && PlaceCPM_Utility.checkAccessiblityOfFields(Constant.REVENUE_CASH_ALLOCATION_OBJECT,'GL_Code__c',Constant.ACTION_TYPE_UPDATE)){
                        isCashGLCode = true;
                    }
                    if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.REVENUE_CASH_ALLOCATION_OBJECT,'Revenue_Contract__c',Constant.ACTION_TYPE_INSERT) && PlaceCPM_Utility.checkAccessiblityOfFields(Constant.REVENUE_CASH_ALLOCATION_OBJECT,'Revenue_Contract__c',Constant.ACTION_TYPE_UPDATE)){
                        isCashRevenueContract = true;
                    }
                    if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.REVENUE_CASH_ALLOCATION_OBJECT,'Cash_Date__c',Constant.ACTION_TYPE_INSERT) && PlaceCPM_Utility.checkAccessiblityOfFields(Constant.REVENUE_CASH_ALLOCATION_OBJECT,'Cash_Date__c',Constant.ACTION_TYPE_UPDATE)){
                        isCashDate = true;
                    }
                    if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.REVENUE_CASH_ALLOCATION_OBJECT,'Forecast_Amount__c',Constant.ACTION_TYPE_INSERT) && PlaceCPM_Utility.checkAccessiblityOfFields(Constant.REVENUE_CASH_ALLOCATION_OBJECT,'Forecast_Amount__c',Constant.ACTION_TYPE_UPDATE)){
                        isCashForecastAmount = true;
                    }    
                    if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.REVENUE_PL_ALLOCATION_OBJECT,'Revenue_Account__c',Constant.ACTION_TYPE_INSERT) && PlaceCPM_Utility.checkAccessiblityOfFields(Constant.REVENUE_PL_ALLOCATION_OBJECT,'Revenue_Account__c',Constant.ACTION_TYPE_UPDATE)){
                        isPLRevenueAccount = true;
                    }
                    if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.REVENUE_PL_ALLOCATION_OBJECT,'Revenue_Contract__c',Constant.ACTION_TYPE_INSERT) && PlaceCPM_Utility.checkAccessiblityOfFields(Constant.REVENUE_PL_ALLOCATION_OBJECT,'Revenue_Contract__c',Constant.ACTION_TYPE_UPDATE)){
						isPLRevenueContract = true;
                    }
                    if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.REVENUE_PL_ALLOCATION_OBJECT,'GL_Code__c',Constant.ACTION_TYPE_INSERT) && PlaceCPM_Utility.checkAccessiblityOfFields(Constant.REVENUE_PL_ALLOCATION_OBJECT,'GL_Code__c',Constant.ACTION_TYPE_UPDATE)){
                        isPLGLCode = true;
                    }
                    if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.REVENUE_PL_ALLOCATION_OBJECT,'Forecast_Amount__c',Constant.ACTION_TYPE_INSERT) && PlaceCPM_Utility.checkAccessiblityOfFields(Constant.REVENUE_PL_ALLOCATION_OBJECT,'Forecast_Amount__c',Constant.ACTION_TYPE_UPDATE)){
                        isPLForecastAmount = true;
                    }
                    
                for(Revenue_Contract__c rc: newRevenueContracts.values()){
                    Integer revenueMonths = 0;
                    Date contractEndDate;

                    //PCPM-315
                    if(rc.RecordTypeId == nonRecurringRecordTypeId){
                        revenueMonths = 1;    
                        contractEndDate = rc.Contract_Start_Date__c.addMonths(revenueMonths);
                    }else if(rc.RecordTypeId == recurringRecordTypeId){
                        revenueMonths = PlaceCPM_Utility.getRevenueMonths(rc);
                        contractEndDate = rc.Contract_Start_Date__c.addMonths(revenueMonths);
                    }

                    // Logic for Revenue P&L Allocation
                    if(rc.Invoice_Date__c != null && rc.Payment_Term_After_Days__c != null && revenueMonths > 0){
                        
                        for(Integer i=0; i<revenueMonths; i++){
                            Date futureDatesforPL=rc.Contract_Start_Date__c.addMonths(i);
                            String monthStr = PlaceCPM_Utility.getMonthString(futureDatesforPL.month());
                            Double totalMonthlyAmount = 0.0;
                            Date cliEndDate;
                            if(!existingPLAllocationMap.containsKey(rc.id+'~'+monthStr+' '+futureDatesforPL.year())){
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
                                    rpla.P_L__c=pnlRec.Id;
                                    if(isPLRevenueAccount){
                                        rpla.Revenue_Account__c= rc.Revenue_Account__c;
                                    }
                                    if(isPLRevenueContract){
                                        rpla.Revenue_Contract__c=rc.Id;
                                    }
                                    if(isPLGLCode){
                                        rpla.GL_Code__c = listRevenueAccount.get(rc.revenue_account__c).GL_Code__c;
                                    }
                                    if(isPLForecastAmount){
                                        rpla.Forecast_Amount__c =totalMonthlyAmount;
                                    }
                                    
                                    revenuePnlAllocations.add(rpla);
                                    existingPLAllocationMap.put(rc.Id+'~'+pnlRec.Name,rpla );
                                }
                            }else{
                                // section to update existing Revenue P&L Allocation if required in future.
                                //#35
                                Revenue_P_L_Allocation__c resultRPL=existingPLAllocationMap.get(rc.id+'~'+monthStr+' '+futureDatesforPL.year());
                                if(mapRCToCLI.containsKey(rc.Id)) {
                                    //#133
                                    for(Contract_Line_Items__c cli:mapRCToCLI.get(rc.Id)){
                                        cliEndDate = cli.End_Date__c != null ? cli.End_Date__c : contractEndDate;
                                        if((resultRPL.P_L__r.Period_Start_Date__c < cliEndDate || resultRPL.P_L__r.Period_Start_Date__c.month() == cliEndDate.month()) 
                                        && (resultRPL.P_L__r.Period_Start_Date__c >= cli.Start_Date__c || resultRPL.P_L__r.Period_Start_Date__c.month() == cli.Start_Date__c.month() )){
                                            totalMonthlyAmount += cli.Total_Amount__c;
                                        }
                                    }
                                }
                                if(totalMonthlyAmount ==0){
                                    listRPLATobeDeleted.add(resultRPL);
                                }else{
                                //CONDITION PUT TO PREVENT THE UPDATE OF THE PAST PNL ALLOCATIONS
                                    if(resultRPL.P_L__r.Period_End_Date__c != null && resultRPL.P_L__r.Period_End_Date__c > System.today()){
                                    
                                    Revenue_P_L_Allocation__c rpla = new Revenue_P_L_Allocation__c(Id=resultRPL.Id);
                                    if(isPLRevenueAccount){
                                        rpla.Revenue_Account__c= rc.Revenue_Account__c;
                                    }
                                    if(isPLGLCode){
                                        rpla.GL_Code__c = listRevenueAccount.get(rc.revenue_account__c).GL_Code__c;
                                    }
                                    if(isPLForecastAmount){
                                        rpla.Forecast_Amount__c =totalMonthlyAmount;
                                    }

                                    revenuePnlAllocations.add(rpla);
                                    }else{
                                        revenuePnlAllocations.add(resultRPL);
                                    }
                                }
                            }
                        }
                    }
                    
                    if(rc.Invoice_Date__c != null && rc.Payment_Term_After_Days__c != null && revenueMonths > 0 && listRevenueAccount.get(rc.revenue_account__c).Billing_Cycle__c != null && !revenuePnlAllocations.isEmpty()){
                        //PCPM-315
                        Double cashAmount = 0;
                        Integer numberOfCashAllocationRecords = 0;
                        Integer remainingPaymentMonths = 0;
                        Integer billingCycle = Integer.valueOf(listRevenueAccount.get(rc.revenue_account__c).Billing_Cycle__c);
                        //PCPM-315
                        if(rc.RecordTypeId == nonRecurringRecordTypeId){
                            numberOfCashAllocationRecords = 1;
                        }else if(rc.RecordTypeId == recurringRecordTypeId){
                            numberOfCashAllocationRecords = (Integer)(revenuePnlAllocations.size()/billingCycle);
                            remainingPaymentMonths = Math.mod(revenuePnlAllocations.size(),billingCycle);
                        }
                        // Logic for Revenue Cash Allocation
                        
                        /*Double cashAmount = 0;
                        Integer billingCycle = Integer.valueOf(listRevenueAccount.get(rc.revenue_account__c).Billing_Cycle__c);
                        Integer numberOfCashAllocationRecords = (Integer)(revenuePnlAllocations.size()/billingCycle);
                        Integer remainingPaymentMonths = Math.mod(revenuePnlAllocations.size(),billingCycle);*/
                        
                        for(Integer i=0; i<=numberOfCashAllocationRecords;i++){

                            Integer numberOfDays = Integer.valueOf(rc.Payment_Term_After_Days__c);
                            Date beginDate = rc.Invoice_Date__c + numberOfDays ;
                            Date futureDatesforCash = beginDate.addMonths((i*billingCycle));
                            String monthStr = PlaceCPM_Utility.getMonthString(futureDatesforCash.month());
                            //Add the remaining months PNL allocation to create last cash allocation record
                            //PCPM-561
                            if(rc.RecordTypeId == nonRecurringRecordTypeId){
                                if(revenuePnlAllocations.size() > 0) {
                                    cashAmount += revenuePnlAllocations[0].Forecast_Amount__c;
                                }
                            } else {
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
                            }
                            
                            if(cashAmount > 0){
                            if(!existingCashAllocationMap.containsKey(rc.id+'~'+monthStr+' '+futureDatesforCash.year())){
                                Cash_Forecast__c cashRec = cashForecastMap.get(monthStr+' '+futureDatesforCash.year());
                                if(cashRec != null){
                                    
                                    Revenue_Cash_Allocation__c allocation = new Revenue_Cash_Allocation__c();
                                    allocation.Cash_Forecast__c=cashRec.Id;
                                    if(isCashRevenueAccount){
                                        allocation.Revenue_Account__c= rc.Revenue_Account__c;
                                    }
                                    if(isCashGLCode){
                                        allocation.GL_Code__c = listRevenueAccount.get(rc.revenue_account__c).GL_Code__c;
                                    }
                                    if(isCashRevenueContract){
                                        allocation.Revenue_Contract__c=rc.Id;
                                    }
                                    if(isCashDate){
                                        allocation.Cash_Date__c = futureDatesforCash;
                                    }
                                    if(isCashForecastAmount){
                                        allocation.Forecast_Amount__c = cashAmount;
                                    }

                                    revenueCashAllocations.add(allocation);
                                }
                            }else{
                                
                                // section to update existing Revenue Cash Allocation if required in future.
                                // #35
                                Revenue_Cash_Allocation__c resultRCA=existingCashAllocationMap.get(rc.id+'~'+monthStr+' '+futureDatesforCash.year());
                                
                                if(resultRCA.Cash_Forecast__r.Period_End_Date__c != null && resultRCA.Cash_Forecast__r.Period_End_Date__c > System.today()){
                                    if(isCashDate){
                                        resultRCA.Cash_Date__c=futureDatesforCash;
                                    }
                                    if(isCashForecastAmount){
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
                
                //#199
                // Detecting the existing RPLA that we dont need anymore
                for(Revenue_Cash_Allocation__c rca:mapRCA.values()){
                    if(!listUpdatedRCAId.contains(rca.Id)){
                        listRCATobeDeleted.add(mapRCA.get(rca.Id));
                    }
                }
                PlaceCPM_Utility.upsertRecords(revenuePnlAllocations, CONSTANT.REVENUE_PL_ALLOCATION_OBJECT, false);//520
                PlaceCPM_Utility.upsertRecords(revenueCashAllocations, CONSTANT.REVENUE_CASH_ALLOCATION_OBJECT, false);//520
                PlaceCPM_Utility.updateRecords(listCLITobeUpdated, CONSTANT.CONTRACT_LINE_ITEM_OBJECT, false);//520
                PlaceCPM_Utility.deleteRecords(listRPLATobeDeleted, CONSTANT.REVENUE_PL_ALLOCATION_OBJECT, false);//520
                PlaceCPM_Utility.deleteRecords(listRCATobeDeleted, CONSTANT.REVENUE_CASH_ALLOCATION_OBJECT, false);//520
            }}
        }catch(Exception ex){
            PlaceCPM_Utility.debugLog(ex.getMessage() + ' at line number ' + ex.getLineNumber());
        }
    }
    /* @param 
       rcList : List of Revenue Contract whose PL records are needed
       @return 
       map<String, Profit_Loss__c> : Map of PL records correspnding to each month 
    */
    public static map<String, Profit_Loss__c> getMonthsforPLAllocation(list<Revenue_Contract__c> rcList, Set<String> monthsForPL){
        // Logic for P&L Allocation
        Map<String, Profit_Loss__c> plRecordsMap = new Map<String, Profit_Loss__c>();
        if(monthsForPL != null && monthsForPL.size() > 0){
            plRecordsMap = getPLRecords(monthsForPL);
            if(plRecordsMap==null){
                plRecordsMap=new map<String, Profit_Loss__c>();
            }
                            
            List<Profit_Loss__c> newpnlList = new List<Profit_Loss__c>();
            for(String str: monthsForPL){
                if(!plRecordsMap.containsKey(str)){
                    List<String> monthyear = str.split(' ');
                    Integer year = Integer.valueOf(monthyear[1]);
                    Integer month = PlaceCPM_Utility.getMonthInNumber(monthyear[0]);
                    Integer dim = date.daysInMonth(year, month);
                    date lastDOM = date.newInstance(year, month, dim);
                    date firstDOM = lastDOM.toStartOfMonth();
                    newpnlList.add(new Profit_Loss__c(Name=str, Period_Start_Date__c=firstDOM, Period_End_Date__c=lastDOM));
                    }
            }
            
            if(newpnlList != null && newpnlList.size()>0){
                if(Schema.sObjectType.Profit_Loss__c.isCreateable()){
                    insert newpnlList;
                }
                for(Profit_Loss__c pnl: newpnlList){
                    plRecordsMap.put(pnl.Name, pnl);
                }
            }
        }
        return plRecordsMap;
    }

     /* @param 
       rcList : Revenue_Contract__c record whose months are required for Cash Allocation records to be created
       listRevenueAccount : Revenue_Account__c required for billing cycle
       @return 
       Map<String, Cash_Forecast__c> : Map of all the revenue months to thier correspnding cash forecast record
    */
    public static map<String, Cash_Forecast__c> getMonthsforCashAllocation(List<Revenue_Contract__c> rcList, 
                                                                            Map<String,Revenue_Account__c> listRevenueAccount, 
                                                                            Set<String> monthsForCash){
        Map<String, Cash_Forecast__c> cashForecastRecordsMap = new Map<String, Cash_Forecast__c>();
        
        if(rcList != null && rcList.size()>0){
            if(monthsForCash != null && monthsForCash.size()>0){
                cashForecastRecordsMap =getCashForecastRecords(monthsForCash);
                if(cashForecastRecordsMap == null){
                    cashForecastRecordsMap=new map<String, Cash_Forecast__c>();
                }
                List<Cash_Forecast__c> newcashList = new List<Cash_Forecast__c>();
                for(String str: monthsForCash){
                    if(!cashForecastRecordsMap.containsKey(str)){
                        List<String> monthyear = str.split(' ');
                        Integer year = Integer.valueOf(monthyear[1]);
                        Integer month = PlaceCPM_Utility.getMonthInNumber(monthyear[0]);
                        Integer dim = date.daysInMonth(year, month);
                        date lastDOM = date.newInstance(year, month, dim);
                        date firstDOM = lastDOM.toStartOfMonth();
                        newcashList.add(new Cash_Forecast__c(Name=str, Period_Start_Date__c=firstDOM, Period_End_Date__c=lastDOM));
                    }
                }
                
                if(newcashList != null && newcashList.size()>0){
                    if(Schema.sObjectType.Cash_Forecast__c.isCreateable()){
                        insert newcashList;
                    }
                    for(Cash_Forecast__c cf: newcashList){
                        cashForecastRecordsMap.put(cf.Name, cf);
                    }
                }
            }
        }
        return cashForecastRecordsMap;
    }
    /* @param 
       set<String> : Set of Months string whose PL records are required
       @return 
       map<String, Profit_Loss__c> : Map of PL records correspnding to each month 
    */
    public static map<String, Profit_Loss__c> getPLRecords(set<String> monthNames){
        map<String, Profit_Loss__c> tempPLRecordsMap = new map<String, Profit_Loss__c>();
        if(monthNames != null && monthNames.size()>0){
            List<Profit_Loss__c> plRecords;
        	if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.PROFIT_LOSS_OBJECT,'Id, Name,Period_Start_Date__c,Period_End_Date__c',Constant.ACTION_TYPE_ACCESS)){
            	plRecords = [Select Id, Name,Period_Start_Date__c,Period_End_Date__c From Profit_Loss__c Where Name IN: monthNames];
        	}
            if(plRecords != null && plRecords.size()>0){
                for(Profit_Loss__c pl: plRecords){
                    tempPLRecordsMap.put(pl.Name, pl);
                }
                return tempPLRecordsMap;
            }
        }
        return null;
    }

     /* @param 
       set<String> : Set of Months string whose Cash Forecast records are required
       @return 
       map<String, Cash Forecast> : Map of Cash Forecast records correspnding to each month 
    */
    public static map<String, Cash_Forecast__c> getCashForecastRecords(set<String> monthNames){
        Map<String, Cash_Forecast__c> tempCashRecordsMap = new Map<String, Cash_Forecast__c>();
        if(monthNames != null && monthNames.size()>0){
            list<Cash_Forecast__c> cashForecasts = [Select Id, Name From Cash_Forecast__c Where Name IN: monthNames];
            if(cashForecasts != null && cashForecasts.size()>0){
                for(Cash_Forecast__c cf: cashForecasts){
                    tempCashRecordsMap.put(cf.Name, cf);
                }
                return tempCashRecordsMap;
            }
        }
        return null;
    }

    //#166
    /* @param 
       newItems: Map of new Revenue Contract whose date update needs to be validated
       oldItems: Map of old Revenue Contract whose date is needed for comparison
       @return null
    */
    private void validateEndDateUpdation(Map<Id,Revenue_Contract__c> newItems,Map<Id,Revenue_Contract__c> oldItems){
        for(Revenue_Contract__c rc:newItems.values()){
            if(rc.Contract_End_date__c !=null && 
               (rc.Contract_End_date__c != oldItems.get(rc.Id).Contract_End_date__c )){
                   if(rc.Contract_End_date__c< System.today()){
                       rc.addError(System.label.Error_Revenue_Contract_End_Date_in_Past);
                   }
            }

        }
    } 
    //#166
     /* @param 
       oldItems: Map of old Revenue Contract which if deleted needs to be take PnL and Cash Alllocation records with them
       @return null
    */
    private void deletePNLAllocationAndCashAllocation(Map<Id, Revenue_Contract__c> oldItems ){
        List<String> listRevenueContract = new List<String>();
        for(Revenue_Contract__c rc:oldItems.values()){
            listRevenueContract.add(rc.Id);
        }
        
        PlaceCPM_Utility.deleteRecords([SELECT ID FROM Revenue_Cash_Allocation__c WHERE Revenue_Contract__c IN :listRevenueContract], CONSTANT.REVENUE_CASH_ALLOCATION_OBJECT, false);//520
        
        PlaceCPM_Utility.deleteRecords([SELECT ID FROM Revenue_P_L_Allocation__c WHERE Revenue_Contract__c IN :listRevenueContract], CONSTANT.REVENUE_PL_ALLOCATION_OBJECT, false);//520
    } 
}
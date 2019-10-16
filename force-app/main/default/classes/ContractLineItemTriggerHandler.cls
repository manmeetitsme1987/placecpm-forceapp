/*
Description : Handler class to Contract Line Item trigger.
Date Created : 21st May 2019
Change : PCPM-133, PCPM-166
*/
public with sharing class ContractLineItemTriggerHandler implements CommonTriggerHandler{
    public static boolean hasAlreadyRanAfterInsert = false;
    public static boolean hasAlreadyRanAfterUpdate = false;
    
    public void BeforeInsert(List<SObject> newItems){
        //#133
        populateProductUnitPrice((List<Contract_Line_Items__c>)newItems,null);
        // #31
        calculateTotalAmount((List<Contract_Line_Items__c>)newItems,null);
        //#133
        populateStartEndDate((List<Contract_Line_Items__c>)newItems,null);
        
    }
    
    public void BeforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems){
        // #133
        populateProductUnitPrice(((Map<Id, Contract_Line_Items__c>) newItems).values(), (Map<Id, Contract_Line_Items__c>) oldItems);
        // #31
        calculateTotalAmount(((Map<Id,Contract_Line_Items__c>)newItems).values(),(Map<Id, Contract_Line_Items__c>) oldItems);
        //#133
        populateStartEndDate(((Map<Id,Contract_Line_Items__c>)newItems).values(),(Map<Id, Contract_Line_Items__c>) oldItems);
        
    }
    
    public void BeforeDelete(Map<Id, SObject> oldItems){
        
    }
    
    public void AfterInsert(Map<Id, SObject> newItems){
    }
    
    public void AfterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems){
        updatePnLAllocationRecordsOnDateRangeUpdate((Map<Id, Contract_Line_Items__c>) newItems, (Map<Id, Contract_Line_Items__c>) oldItems);
        //recalculateRevenueContracts((Map<Id, Contract_Line_Items__c>) newItems, (Map<Id, Contract_Line_Items__c>) oldItems);
    }
    
    public void AfterDelete(Map<Id, SObject> oldItems){
       
    }
    
    public void AfterUndelete(Map<Id, SObject> oldItems){
      
    }
    
    public Boolean IsDisabled(){
        return false;
    }
/*
    private static void recalculateRevenueContracts(Map<Id, Contract_Line_Items__c> newItems, Map<Id, Contract_Line_Items__c> oldItems){
        for(Contract_Line_Items__c cli:newItems.values()){
            if((cli.Start_Date__c != oldItems.get(cli.Id).Start_Date__c) || (cli.End_Date__c != oldItems.get(cli.Id).End_Date__c)){
               listRevenueContract.add(cli.Revenue_Contract_Details__c);
            }
        }
        Map<ID,Revenue_Contract__c>  mapRevenueContract =  new Map<Id,Revenue_Contract__c>([SELECT ID, Contract_End_Date__c FROM Revenue_Contract__c WHERE ID IN :listRevenueContract]);
    }*/
    //#133
    /* @param 
       newItems : New Contract_Line_Items__c records
       oldItems : Old Contract_Line_Items__c records
       @return null
      */
    public static void updatePnLAllocationRecordsOnDateRangeUpdate(Map<Id, Contract_Line_Items__c> newItems, Map<Id, Contract_Line_Items__c> oldItems){
        List<String> listRevenueContract = new List<String>();
        Map<Id,Revenue_P_L_Allocation__c> mapRevenuePLAllocationTobeUpdated = new Map<Id,Revenue_P_L_Allocation__c>();
        List<Revenue_P_L_Allocation__c> listRevenuePLAllocationTobeUpdated = new List<Revenue_P_L_Allocation__c>();
        List<Contract_Line_Items__c> listUpdatedCLIs =new List<Contract_Line_Items__c>();
        List<Revenue_P_L_Allocation__c> listRPLAToBeDeleted = new List<Revenue_P_L_Allocation__c>();
        Map<String,List<Revenue_P_L_Allocation__c>> mapRevenueContractToRPLA = new Map<String,List<Revenue_P_L_Allocation__c>>();
        Map<String,Map<String,Revenue_Cash_Allocation__c>> mapRevenueContractToMonthToRCA = new Map<String,Map<String,Revenue_Cash_Allocation__c>>();
        String cashMonthYear;
        Revenue_Cash_Allocation__c revenueCashAllocation;
        Map<Id,Revenue_Cash_Allocation__c> mapRCAToBeUpdated  = new Map<Id,Revenue_Cash_Allocation__c>();
        List<Revenue_Cash_Allocation__c> listRCAToBeDeleted = new List<Revenue_Cash_Allocation__c>();
        for(Contract_Line_Items__c cli:newItems.values()){
            if((cli.Start_Date__c != oldItems.get(cli.Id).Start_Date__c) || (cli.End_Date__c != oldItems.get(cli.Id).End_Date__c)){
               listRevenueContract.add(cli.Revenue_Contract_Details__c);
                listUpdatedCLIs.add(cli);
            }
        }
        If(!listRevenueContract.isEmpty()){
		
        Map<ID,Revenue_Contract__c>  mapRevenueContract;
		if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.REVENUE_CONTRACT_OBJECT,'ID, Contract_End_Date__c, Live_Renewed_Date__c',Constant.ACTION_TYPE_ACCESS) && 
           PlaceCPM_Utility.checkAccessiblityOfFields(Constant.PROFIT_LOSS_OBJECT,'Period_Start_Date__c,Period_End_Date__c',Constant.ACTION_TYPE_ACCESS) &&
           PlaceCPM_Utility.checkAccessiblityOfFields(Constant.revenueAccountObject,'Billing_Cycle__c',Constant.ACTION_TYPE_ACCESS) && 
           PlaceCPM_Utility.checkAccessiblityOfFields(Constant.CASH_FORECAST_OBJECT,'Name',Constant.ACTION_TYPE_ACCESS) &&
           PlaceCPM_Utility.checkAccessiblityOfFields(Constant.REVENUE_PL_ALLOCATION_OBJECT,'Revenue_Contract__c,Forecast_Amount__c',Constant.ACTION_TYPE_ACCESS) &&
           PlaceCPM_Utility.checkAccessiblityOfFields(Constant.REVENUE_CASH_ALLOCATION_OBJECT,'ID, Forecast_Amount__c',Constant.ACTION_TYPE_ACCESS)){ 
           mapRevenueContract =  new Map<Id,Revenue_Contract__c>([SELECT ID, Contract_End_Date__c, Live_Renewed_Date__c, 
                                                                                            Auto_Renew__c, Contract_Months__c, Invoice_Date__c, Payment_Term_After_Days__c,
                                                                                            (SELECT Revenue_Contract__c, P_L__r.Period_Start_Date__c, P_L__r.Period_End_Date__c, Forecast_Amount__c,Revenue_Account__r.Billing_Cycle__c FROM Revenue_P_L_Allocations__r),
                                                                                            (SELECT ID, Forecast_Amount__c, Cash_Forecast__r.Name FROM Revenue_Cash_Allocations__r) 
                                                                                           FROM Revenue_Contract__c WHERE ID IN :listRevenueContract]);
        }    
        //#282
        Map<Id,Revenue_Cash_Allocation__c> mapRCA = new Map<Id,Revenue_Cash_Allocation__c>();

        for(Revenue_Contract__c rc:mapRevenueContract.values()){
            if(!mapRevenueContractToRPLA.containsKey(rc.Id)){
                mapRevenueContractToRPLA.put(rc.Id,mapRevenueContract.get(rc.Id).Revenue_P_L_Allocations__r);
            }
            if(!mapRevenueContractToMonthToRCA.containsKey(rc.Id)){
                mapRevenueContractToMonthToRCA.put(rc.Id,new Map<String,Revenue_Cash_Allocation__c>());
            }
            for(Revenue_Cash_Allocation__c rca:mapRevenueContract.get(rc.Id).Revenue_Cash_Allocations__r){
                mapRevenueContractToMonthToRCA.get(rc.Id).put(rca.Cash_Forecast__r.Name,rca);
            }
        }
        
        Boolean isForecastAmount = false;
        if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.REVENUE_CASH_ALLOCATION_OBJECT,'Forecast_Amount__c',Constant.ACTION_TYPE_UPDATE)){
            isForecastAmount = true;
        }
            for(Contract_Line_Items__c cli:listUpdatedCLIs){
                if(mapRevenueContractToRPLA.containsKey(cli.Revenue_Contract_Details__c) && 
                   (!mapRevenueContractToRPLA.get(cli.Revenue_Contract_Details__c).isEmpty())){
                       
                       for(Revenue_P_L_Allocation__c rpla:mapRevenueContractToRPLA.get(cli.Revenue_Contract_Details__c)){
                           Revenue_Contract__c rc=mapRevenueContract.get(rpla.Revenue_Contract__c);
                           if(rc != null){
                           if(rpla.P_L__r.Period_Start_Date__c > rc.Contract_End_Date__c){
                                listRPLAToBeDeleted.add(rpla);
                            } 
                            else {
                                cashMonthYear = getCorrespndingCashAllocation(mapRevenueContract.get(rpla.Revenue_Contract__c),rpla,Integer.valueOf(rpla.Revenue_Account__r.Billing_Cycle__c));
                                if(rplaInDateRange(cli,rpla,rc) && !rplaInDateRange(oldItems.get(cli.Id),rpla,rc)){
                                    rpla.Forecast_Amount__c +=cli.Total_Amount__c;
                                    //#166
                                    mapRevenuePLAllocationTobeUpdated.put(rpla.Id,rpla);
                                    //#282
                                    if(mapRevenueContractToMonthToRCA.containsKey(rpla.Revenue_Contract__c) 
                                    && mapRevenueContractToMonthToRCA.get(rpla.Revenue_Contract__c).containsKey(cashMonthYear)){
                                        revenueCashAllocation = mapRevenueContractToMonthToRCA.get(rpla.Revenue_Contract__c).get(cashMonthYear);
                                        
                                        if(isForecastAmount){
                                            if(revenueCashAllocation.Forecast_Amount__c != null){
                                                revenueCashAllocation.Forecast_Amount__c +=cli.Total_Amount__c;
                                            }else{
                                                revenueCashAllocation.Forecast_Amount__c = cli.Total_Amount__c;
                                            } 
                                    	}
                                        mapRCAToBeUpdated.put(revenueCashAllocation.Id,revenueCashAllocation);
                                    }
                                    
                                }
                                if(!rplaInDateRange(cli,rpla,rc) && rplaInDateRange(oldItems.get(cli.Id),rpla,rc)){
                                    rpla.Forecast_Amount__c -=cli.Total_Amount__c;
                                    //#282
                                    if(rpla.Forecast_Amount__c <=0){
                                        listRPLAToBeDeleted.add(rpla);
                                    }else{
                                        //#166
                                        mapRevenuePLAllocationTobeUpdated.put(rpla.Id,rpla);
                                    }
                                    

                                    //#282
                                    if(mapRevenueContractToMonthToRCA.containsKey(rpla.Revenue_Contract__c) 
                                    && mapRevenueContractToMonthToRCA.get(rpla.Revenue_Contract__c).containsKey(cashMonthYear)){
                                        revenueCashAllocation = mapRevenueContractToMonthToRCA.get(rpla.Revenue_Contract__c).get(cashMonthYear);
                                        if(revenueCashAllocation.Forecast_Amount__c != null){
                                            
                                            if(isForecastAmount){
                                            	revenueCashAllocation.Forecast_Amount__c -=cli.Total_Amount__c;
                                            }    
                                        }
                                        if(revenueCashAllocation.Forecast_Amount__c <=0){
                                            listRCAToBeDeleted.add(revenueCashAllocation);
                                        }else{
                                            mapRCAToBeUpdated.put(revenueCashAllocation.Id,revenueCashAllocation);
                                        } 

                                    }
                                }
                            }
                           
                       }
                       }
                }
            }
        }

        PlaceCPM_Utility.updateRecords(mapRevenuePLAllocationTobeUpdated.values(), CONSTANT.REVENUE_PL_ALLOCATION_OBJECT, false); //520
        PlaceCPM_Utility.updateRecords(mapRCAToBeUpdated.values(), CONSTANT.REVENUE_CASH_ALLOCATION_OBJECT, false); //520
        PlaceCPM_Utility.deleteRecords(listRPLAToBeDeleted, CONSTANT.REVENUE_PL_ALLOCATION_OBJECT, false); //520
        PlaceCPM_Utility.deleteRecords(listRCAToBeDeleted, CONSTANT.REVENUE_CASH_ALLOCATION_OBJECT, false); //520
        
    }

    //#282
    /* @param 
       sow: Statement Of Work whose invoice date is needed to calculate the Cash Month in which PnL lies   
       rpla: PL Allocation which needs to be added to a specific Cash record 
       billingCycle: Billing cycle from Revenue Account
       @return String
    */
    private static String getCorrespndingCashAllocation(Revenue_Contract__c sow,Revenue_P_L_Allocation__c rpla,Integer billingCycle ){
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
        cashDate = sow.Invoice_Date__c.addDays(Integer.valueOf(sow.Payment_Term_After_Days__c)).addMonths(cashMonth);
        
        return PlaceCPM_Utility.getMonthString(cashDate.month()) +' '+ cashDate.year();

    }
    //#133
    /* @param 
       newItems : Contract_Line_Items__c record that defines date range
       oldItems : Revenue_P_L_Allocation__c records that needs to checked if it falls in CLI date range
       @return boolean
      */
    public static boolean rplaInDateRange(Contract_Line_Items__c cli,Revenue_P_L_Allocation__c rpla,Revenue_Contract__c rc){
        boolean inRange = false;
        //Revenue_Contract__c rc=rpla.Revenue_Contract__r;
        Date contractEndDate = rc.Live_Renewed_Date__c.addMonths(PlaceCPM_Utility.getRevenueMonths(rc));
        Date cliEndDate = cli.End_Date__c != null ? cli.End_Date__c : contractEndDate;
         if((rpla.P_L__r.Period_Start_Date__c < cliEndDate) && (rpla.P_L__r.Period_Start_Date__c  >= cli.Start_Date__c)){
             inRange = true;
         }
        return inRange;
    }
    //#133
    /* @param 
       newItems : New Contract_Line_Items__c records
       oldItems : Old Contract_Line_Items__c records
       @return null
      */
    public static void populateStartEndDate(List<Contract_Line_Items__c> newItems, Map<Id, Contract_Line_Items__c> oldItems){
        List<ID> listRCIds = new List<ID>();
        for(Contract_Line_Items__c cli:newItems){
            listRCIds.add(cli.Revenue_Contract_Details__c );
        }
        
        Map<Id,Revenue_Contract__c > mapRevenuContract;
        if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.REVENUE_CONTRACT_OBJECT,'ID, Live_Renewed_Date__c,Contract_End_Date__c,Auto_Renew__c,Contract_Months__c',Constant.ACTION_TYPE_ACCESS)){
        	mapRevenuContract = new Map<Id,Revenue_Contract__c >([SELECT ID, Live_Renewed_Date__c, 
                                                                Contract_End_Date__c,Auto_Renew__c,Contract_Months__c FROM Revenue_Contract__c WHERE ID IN : listRCIds]);
        }  
        
        Boolean isStartDateInsert = false, isStartDateUpdate = false, isEndDateInsert = false, isEndDateUpdate = false;
        if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.CONTRACT_LINE_ITEM_OBJECT,'Start_Date__c',Constant.ACTION_TYPE_INSERT)){
            isStartDateInsert = true;
        }
        if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.CONTRACT_LINE_ITEM_OBJECT,'Start_Date__c',Constant.ACTION_TYPE_UPDATE)){
            isStartDateUpdate = true;
        }
        if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.CONTRACT_LINE_ITEM_OBJECT,'End_Date__c',Constant.ACTION_TYPE_INSERT)){
            isEndDateInsert = true;
        }
        if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.CONTRACT_LINE_ITEM_OBJECT,'End_Date__c',Constant.ACTION_TYPE_UPDATE)){
            isEndDateUpdate = true;
        }
        
        for(Contract_Line_Items__c cli:newItems){
            //Updating the Start
            
            if(oldItems == null && cli.Start_Date__c  == null){
                if(isStartDateInsert){
                	cli.Start_Date__c = mapRevenuContract.get(cli.Revenue_Contract_Details__c).Live_Renewed_Date__c;
                }    
                
            }else if(oldItems != null && (cli.Revenue_Contract_Details__c != oldItems.get(cli.Id).Revenue_Contract_Details__c || (cli.Start_Date__c != oldItems.get(cli.Id).Start_Date__c))
                     && (cli.Start_Date__c == null)){ 
                if(isStartDateUpdate){
                	cli.Start_Date__c = mapRevenuContract.get(cli.Revenue_Contract_Details__c).Live_Renewed_Date__c;
                }    
            }
            
             
            //RevenueContract End date is null 
            
            if(mapRevenuContract.get(cli.Revenue_Contract_Details__c).Contract_End_Date__c == null && cli.End_Date__c == null){
                if(isEndDateInsert || isEndDateUpdate){
                	cli.End_Date__c = null;
            	}
            }else{
                //Updating the End Date
                
                if(oldItems == null && cli.End_Date__c  == null && isEndDateInsert){
                   cli.End_Date__c = mapRevenuContract.get(cli.Revenue_Contract_Details__c).Contract_End_Date__c;
                    
                }else if(oldItems != null && (cli.Revenue_Contract_Details__c != oldItems.get(cli.Id).Revenue_Contract_Details__c || (cli.End_Date__c != oldItems.get(cli.Id).End_Date__c))
                    && (cli.End_Date__c == null) && isEndDateUpdate){
                    	cli.End_Date__c = mapRevenuContract.get(cli.Revenue_Contract_Details__c).Contract_End_Date__c;
                }
            }
            
        }   
        
            
    }
    //#133
    /* @param 
       newItems : New Contract_Line_Items__c records
       oldItems : Old Contract_Line_Items__c records
       @return null
      */
    public static void populateProductUnitPrice(List<Contract_Line_Items__c> newItems,Map<Id, Contract_Line_Items__c> oldItems){
        List<ID> listProductIds = new List<ID>();
        for(Contract_Line_Items__c cli:newItems){
            listProductIds.add(cli.Product__c);
        }
        
        Boolean isUnitPriceInsert = false, isUnitPriceUpdate = false;
        if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.CONTRACT_LINE_ITEM_OBJECT,'Unit_Price__c',Constant.ACTION_TYPE_INSERT)){ 
            isUnitPriceInsert = true;
        }
        if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.CONTRACT_LINE_ITEM_OBJECT,'Unit_Price__c',Constant.ACTION_TYPE_UPDATE)){         
            isUnitPriceUpdate = true;
        }
        Map<Id,Product__c> mapProduct = new Map<Id,Product__c>();
        
        if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.PRODUCT_OBJECT,'ID,Unit_Price__c',Constant.ACTION_TYPE_ACCESS)){
            mapProduct = new Map<Id,Product__c>([SELECT ID,Unit_Price__c 
                                                                    FROM Product__c WHERE ID IN : listProductIds]);
        }    
        for(Contract_Line_Items__c cli:newItems){
            if(oldItems == null && (cli.Unit_Price__c == null || cli.Unit_Price__c==0)){
               if(isUnitPriceInsert){ 
               		cli.Unit_Price__c = mapProduct.get(cli.Product__c).Unit_Price__c;
               }     
            }else if(oldItems != null && (cli.Product__c != oldItems.get(cli.Id).Product__c || (cli.Unit_Price__c != oldItems.get(cli.Id).Unit_Price__c))
                     && (cli.Unit_Price__c == null || cli.Unit_Price__c==0)){
                if(isUnitPriceUpdate){         
                	cli.Unit_Price__c = mapProduct.get(cli.Product__c).Unit_Price__c;
                }    
            }
            
        }
    }
    //#31
    /* @param 
       newItems : New Contract_Line_Items__c records
       oldItems : Old Contract_Line_Items__c records
       @return null
      */
    public static void calculateTotalAmount(List<Contract_Line_Items__c> newItems,Map<Id,Contract_Line_Items__c> oldItems){
        List<String> listProduct = new List<String>();
        Decimal unitPrice;
        Boolean isTotalAmount = false;
        if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.CONTRACT_LINE_ITEM_OBJECT,'Total_Amount__c',Constant.ACTION_TYPE_UPDATE) || PlaceCPM_Utility.checkAccessiblityOfFields(Constant.CONTRACT_LINE_ITEM_OBJECT,'Total_Amount__c',Constant.ACTION_TYPE_INSERT)){
            isTotalAmount = true;
        }
        for(Contract_Line_Items__c cli : newItems){
            if(cli.Unit_Price__c != null){
                if(isTotalAmount){
                	cli.Total_Amount__c = cli.Quantity__c * cli.Unit_Price__c;
                }    
            }
        }
    }
    
}
public with sharing class EquityTriggerHandler implements CommonTriggerHandler{
    public static boolean hasAlreadyRun = false;
	public void BeforeInsert(List<SObject> newItems){
    }
    
    public void BeforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems){
    }
    
    public void AfterInsert(Map<Id, SObject> newItems){
        if(hasAlreadyRun){
            PlaceCPM_Utility.debugLog('##EquityTriggerHandler :: AfterInsert has already run, returning.');
            return;
        }
        hasAlreadyRun = true;
        upsertCashAllocations((Map<Id, Equity__c>) newItems, null);
    }
    
    public void AfterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems){
        if(hasAlreadyRun){
            PlaceCPM_Utility.debugLog('##EquityTriggerHandler :: AfterUpdate has already run, returning.');
            return;
        }
        hasAlreadyRun = true;
        upsertCashAllocations((Map<Id, Equity__c>) newItems, (Map<Id, Equity__c>) oldItems);
    }
    
    public void BeforeDelete(Map<Id, SObject> oldItems){
        if(hasAlreadyRun){
            PlaceCPM_Utility.debugLog('##EquityTriggerHandler :: BeforeDelete has already run, returning.');
            return;
        }
        deleteCashAllocation((Map<Id, Equity__c>)oldItems);
    }
    
    public void AfterUndelete(Map<Id, SObject> oldItems){
    }
    
    public void AfterDelete(Map<Id, SObject> oldItems){
    }
    
    public Boolean IsDisabled(){
        return false;
    }
    
    private void deleteCashAllocation(Map<Id, Equity__c> oldItems) {
        try{
            PlaceCPM_Utility.deleteRecords([Select Id From Revenue_Cash_Allocation__c Where Equity__c IN :oldItems.keySet()], 'Revenue_Cash_Allocation__c', false);
        }catch(Exception ex) {
            PlaceCPM_Utility.debugLog('##Error: ' + ex.getMessage() + ' at line number ' + ex.getLineNumber());
        }
    }
    
    /*
    @params:
    newItems - new Equity inserting/updating
    oldItems - old Equity before updation
    @return null
     */
    private void upsertCashAllocations(Map<Id, Equity__c> newItems, Map<Id, Equity__c> oldItems){
        List<Equity__c> equities= new List<Equity__c>();
        Map<String, Revenue_Cash_Allocation__c> mapRAToRCA = new Map<String, Revenue_Cash_Allocation__c>();
        Map<String,Cash_Forecast__c> cfMap = new Map<String,Cash_Forecast__c>();
        List<Revenue_Cash_Allocation__c> deleteRCA = new List<Revenue_Cash_Allocation__c>();
        List<Revenue_Cash_Allocation__c> listRCAToBeUpserted = new List<Revenue_Cash_Allocation__c>();
        for(Equity__c equity : newItems.values()){
            if((oldItems == null || (equity.GL_Account__c != oldItems.get(equity.Id).GL_Account__c  || equity.Type__c != oldItems.get(equity.Id).Type__c || equity.Amount__c != oldItems.get(equity.Id).Amount__c ||equity.Date__c != oldItems.get(equity.Id).Date__c))){
                equities.add(equity);
            }
        }
        cfMap = getCashForecastRecords(equities);
        if(!equities.isEmpty()){
            // Querying Cash allocation to update the existing
            if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.REVENUE_CASH_ALLOCATION_OBJECT,'ID, Equity__c, Cash_Forecast__c, Revenue_Account__c, Cash_Date__c,Forecast_Amount__c, GL_Code__c',Constant.ACTION_TYPE_ACCESS)){
                for(Revenue_Cash_Allocation__c rca : [SELECT ID, Equity__c, Cash_Forecast__c, Revenue_Account__c, Cash_Date__c, 
                                                      Forecast_Amount__c, GL_Code__c FROM Revenue_Cash_Allocation__c 
                                                      WHERE Equity__c IN :equities]){
                    mapRAToRCA.put(rca.Equity__c,rca);
                }
        	}
            Boolean isRevenueCashForecast = false, isRevenueCashDate = false, isRevenueForecastAmount = false, isRevenueGL = false, isReveueEquity = false;
            if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.REVENUE_CASH_ALLOCATION_OBJECT,'Cash_Forecast__c',Constant.ACTION_TYPE_INSERT)){
                isRevenueCashForecast = true;
            }
            if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.REVENUE_CASH_ALLOCATION_OBJECT,'Cash_Date__c',Constant.ACTION_TYPE_UPDATE) && PlaceCPM_Utility.checkAccessiblityOfFields(Constant.REVENUE_CASH_ALLOCATION_OBJECT,'Cash_Date__c',Constant.ACTION_TYPE_INSERT)){
                isRevenueCashDate = true;
            }
            if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.REVENUE_CASH_ALLOCATION_OBJECT,'Forecast_Amount__c',Constant.ACTION_TYPE_UPDATE) && PlaceCPM_Utility.checkAccessiblityOfFields(Constant.REVENUE_CASH_ALLOCATION_OBJECT,'Forecast_Amount__c',Constant.ACTION_TYPE_INSERT)){
                isRevenueForecastAmount = true;
            }
            if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.REVENUE_CASH_ALLOCATION_OBJECT,'GL_Code__c',Constant.ACTION_TYPE_UPDATE) && PlaceCPM_Utility.checkAccessiblityOfFields(Constant.REVENUE_CASH_ALLOCATION_OBJECT,'GL_Code__c',Constant.ACTION_TYPE_INSERT)){
                isRevenueGL = true;
            }
            if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.REVENUE_CASH_ALLOCATION_OBJECT,'Equity__c',Constant.ACTION_TYPE_UPDATE) && PlaceCPM_Utility.checkAccessiblityOfFields(Constant.REVENUE_CASH_ALLOCATION_OBJECT,'Equity__c',Constant.ACTION_TYPE_INSERT)){
                isReveueEquity = true;
            }
            // Going through each Investment Revenue Account to update/insert the Cash Allocation
            for(Equity__c equity:equities){
                if(equity.Date__c != null && equity.Amount__c != null){
                    decimal amount = equity.Type__c.equalsIgnoreCase(CONSTANT.EquityContribution) ? equity.Amount__c : -equity.Amount__c;
                    String monthYearOfCashAllocation = PlaceCPM_Utility.getMonthString(equity.Date__c.month()) +' '+ equity.Date__c.year();
                    Cash_Forecast__c cashForecastrecord = cfMap.get(monthYearOfCashAllocation);
                    Revenue_Cash_Allocation__c rca,revenueCashAllocation;
                    if(mapRAToRCA.containsKey(equity.Id) ){
                        revenueCashAllocation = mapRAToRCA.get(equity.Id);
                        if(revenueCashAllocation.Cash_Forecast__c != cashForecastrecord.Id){
                            deleteRCA.add(revenueCashAllocation);
                            rca = new Revenue_Cash_Allocation__c();
                            if(isRevenueCashForecast){
                                rca.Cash_Forecast__c = cashForecastrecord.Id;
                            }
                        }else{
                            rca = revenueCashAllocation;
                        }
                    }else{
                        rca = new Revenue_Cash_Allocation__c();
                        
                        if(isRevenueCashForecast){
                            rca.Cash_Forecast__c = cashForecastrecord.Id;
                        }
                    }
                    //rca.Cash_Forecast__c = cashForecastrecord.Id;
                    if(isRevenueCashDate){
                        rca.Cash_Date__c = equity.Date__c;
                    }
                    if(isRevenueForecastAmount){
                        rca.Forecast_Amount__c = amount;
                    }
                    if(isRevenueGL){
                        rca.GL_Code__c = equity.GL_Account__c;
                    }
                    if(isReveueEquity){
                        rca.Equity__c = equity.Id;
                    }
                    listRCAToBeUpserted.add(rca);
                }
            }
        }
        PlaceCPM_Utility.upsertRecords(listRCAToBeUpserted, 'Revenue_Cash_Allocation__c', false);
        PlaceCPM_Utility.deleteRecords(deleteRCA, 'Revenue_Cash_Allocation__c', false);
    }

    /*
    @params:
    listRevenueAccount - list Revenue accounts 
    @return Map<String,Cash_Forecast__c>
     */

	private Map<String,Cash_Forecast__c> getCashForecastRecords(List<Equity__c> equities){
        List<String> monthsForEquity = new List<String>();
        Map<String,Cash_Forecast__c> mapMonthToCashForecast = new Map<String,Cash_Forecast__c>();
        Cash_Forecast__c cashForecast;
        Date startDate,endDate;
        String currentMonth;
        List<Cash_Forecast__c> listCashForecastToBeInserted = new List<Cash_Forecast__c>();
        for(Equity__c equity :equities){
            monthsForEquity.add(PlaceCPM_Utility.getMonthString(equity.Date__c.month()) +' '+ equity.Date__c.year());
        }
        for(Cash_Forecast__c cf:[SELECT ID, Name FROM Cash_Forecast__c WHERE NAME IN :monthsForEquity]){
            mapMonthToCashForecast.put(cf.Name,cf);
        }
        for(Equity__c equity:equities){
            currentMonth = PlaceCPM_Utility.getMonthString(equity.Date__c.month()) +' '+ equity.Date__c.year();
            if(!mapMonthToCashForecast.containsKey(currentMonth)){
                startDate = Date.newInstance(equity.Date__c.year(), equity.Date__c.month(), 1);
                endDate = Date.newInstance(equity.Date__c.year(), equity.Date__c.month(),1).addMonths(1)-1;
                cashForecast = new Cash_Forecast__c(Name=currentMonth,Period_Start_Date__c=startDate,Period_End_Date__c=endDate);
                listCashForecastToBeInserted.add(cashForecast);
            }
        }

        PlaceCPM_Utility.insertRecords(listCashForecastToBeInserted, 'Cash_Forecast__c', false);
        for(Cash_Forecast__c cf:listCashForecastToBeInserted){
            mapMonthToCashForecast.put(cf.Name,cf);
        }
		return mapMonthToCashForecast;
	}
}
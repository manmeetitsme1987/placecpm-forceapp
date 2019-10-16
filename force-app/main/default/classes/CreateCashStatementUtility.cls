public class CreateCashStatementUtility {

    /*
    public static void createPLStatements(List<SObject> scope){
        Set<Integer> monthsNo = new Set<Integer>();
        monthsNo.add(1);
        monthsNo.add(2);
        monthsNo.add(3);
        monthsNo.add(4);
        monthsNo.add(5);
        monthsNo.add(6);
        monthsNo.add(7);
        monthsNo.add(8);
        monthsNo.add(9);
        monthsNo.add(10);
        monthsNo.add(11);
        monthsNo.add(12);
        
        Set<String> revenueCashAllIdSet = new Set<String>();
        Map<String,String> revenueAccountToRTMap = new Map<String,String>();
        String inverstorRTId = PlaceCPM_Utility.getRecordTypeIdbyDeveloperName(PlaceCPM_Utility.getCustomObjOrFieldName(CONSTANT.revenueAccountObject), CONSTANT.INVESTMENT_RECORD_TYPE_RA); //520
        for(SObject epla : scope){
            if(epla instanceOf Revenue_Cash_Allocation__c){
                revenueCashAllIdSet.add((String)epla.get('Id'));
            }
        }
        for(Revenue_Cash_Allocation__c rca : [SELECT Id, Revenue_Account__c, Revenue_Account__r.RecordTypeId FROM Revenue_Cash_Allocation__c WHERE Id IN : revenueCashAllIdSet]){
            if(rca.Revenue_Account__r.RecordTypeId == inverstorRTId ){
                revenueAccountToRTMap.put(rca.Revenue_Account__c,rca.Revenue_Account__r.RecordTypeId);
            }
            
        }
        String paymentAccountId;
        String year;
        Integer month;
        Integer week;        
        Set<String> paymentAccountIdSet = new Set<String>();
        List<String> yearList = new List<String>();
        List<Expense_Cash_Allocation__c> expesneCashAllocationList = new List<Expense_Cash_Allocation__c>();
        List<Revenue_Cash_Allocation__c> revenueCashAllocationList = new List<Revenue_Cash_Allocation__c>();
        Map<String , Decimal> paymentAccMonthYearAndForecastAmount = new  Map<String , Decimal>();
        Map<String , Decimal> paymentAccMonthYearWeekAndAmount = new  Map<String , Decimal>();
        Expense_Cash_Allocation__c expenseCashAllocation;
        Revenue_Cash_Allocation__c revenuCasheAllocation;
        String cashType = '';
        Cash_Statement_Setting__c CSS = Cash_Statement_Setting__c.getOrgDefaults();
        
        //520
        String paymentAccountIdField = PlaceCPM_Utility.getCustomObjOrFieldName('Payment_Account_Id__c');
        String revenueAccountObj = PlaceCPM_Utility.getCustomObjOrFieldName(CONSTANT.revenueAccountObject);
        String cashDateField = PlaceCPM_Utility.getCustomObjOrFieldName('Cash_Date__c');
        String actualAmountField = PlaceCPM_Utility.getCustomObjOrFieldName('Actual_Amount__c');
        String forecastAmountField = PlaceCPM_Utility.getCustomObjOrFieldName('Forecast_Amount__c');

        for (SObject epla : scope) {
            if((String)epla.get(paymentAccountIdField) != null || (epla instanceOf Revenue_Cash_Allocation__c && (String)epla.get(revenueAccountObj) != null && revenueAccountToRTMap.containsKey((String)epla.get(revenueAccountObj)))){
                
                if(epla instanceOf Expense_Cash_Allocation__c){
                    expesneCashAllocationList.add((Expense_Cash_Allocation__c)epla);
                    cashType = CONSTANT.PLS_CashType_Expense; //520
                }
                else if(epla instanceOf Revenue_Cash_Allocation__c){
                    revenueCashAllocationList.add((Revenue_Cash_Allocation__c)epla);
                    if((String)epla.get(revenueAccountObj) != null && revenueAccountToRTMap.containsKey((String)epla.get(revenueAccountObj))) {  
                        cashType = CONSTANT.PLS_CashType_Deposits; //520
                    }
                    else{
                        cashType = CONSTANT.PLS_CashType_Revenue; //520
                    }
                }
                paymentAccountId = (String)epla.get(paymentAccountIdField);
                year = String.valueOf(((Date)epla.get(cashDateField)).year());
                month = ((Date)epla.get(cashDateField)).month();
                week = PlaceCPM_Utility.getWeekOfMonth((Date)epla.get(cashDateField));
                yearList.add(year);
                paymentAccountIdSet.add(paymentAccountId);
                if((Decimal)epla.get(forecastAmountField) != null || (Decimal)epla.get(actualAmountField) != null){
                    if(!paymentAccMonthYearAndForecastAmount.containsKey(paymentAccountId+':'+year+':'+month+':'+cashType)){
                        paymentAccMonthYearAndForecastAmount.put(paymentAccountId+':'+year+':'+month+':'+cashType ,(Decimal)epla.get(actualAmountField) == null ? (Decimal)epla.get(forecastAmountField) : (Decimal)epla.get(actualAmountField) );
                    }
                    
                    else{
                        decimal newAmt = (Decimal)epla.get(actualAmountField) == null ? (Decimal)epla.get(forecastAmountField) : (Decimal)epla.get(actualAmountField);
                        Decimal updatedAmount = paymentAccMonthYearAndForecastAmount.get(paymentAccountId+':'+year+':'+month+':'+cashType) + newAmt ;
                        paymentAccMonthYearAndForecastAmount.put(paymentAccountId+':'+year+':'+month+':'+cashType , updatedAmount);
                    }  
                }
                
                if((Decimal)epla.get(forecastAmountField) != null || (Decimal)epla.get(actualAmountField) != null){
                    if(!paymentAccMonthYearWeekAndAmount.containsKey(paymentAccountId+':'+year+':'+month+':'+week)){
                        paymentAccMonthYearWeekAndAmount.put(paymentAccountId+':'+year+':'+month+':'+week ,(Decimal)epla.get(actualAmountField) == null ? (Decimal)epla.get(forecastAmountField) : (Decimal)epla.get(actualAmountField) );
                    }
                    else{
                        Decimal newAmt = (Decimal)epla.get(actualAmountField) == null ? (Decimal)epla.get(forecastAmountField) : (Decimal)epla.get(actualAmountField);
                        Decimal updatedAmount = paymentAccMonthYearWeekAndAmount.get(paymentAccountId+':'+year+':'+month+':'+week)+ newAmt ;
                        paymentAccMonthYearWeekAndAmount.put(paymentAccountId+':'+year+':'+month+':'+week , updatedAmount);
                    }  
                }
            }
        }
        List<P_L_Statement__c> plStatementListAlreadyExits = [SELECT id , Year__c , January__c , February__c , March__c , April__c ,
                                                              May__c , June__c , July__c , August__c , September__c , October__c , 
                                                              November__c , December__c,Parent_Bank_Account__c, (SELECT id , Year__c , week1Date__c, week2Date__c, week3Date__c, week4Date__c, week5Date__c, Month_In_Number__c ,
                                                                                                                 Parent_P_L_Statement__c  ,Week1__c, week2__c, week3__c, week4__c, week5__c,Payment_Account__c From PL_Statement_Weeks__r)  From P_L_Statement__c WHERE Year__c IN : yearList 
                                                              AND Parent_Bank_Account__c IN : paymentAccountIdSet AND Parent_P_L_Statement__c  = null AND Cash_Tyoe__c = : cashType];
        Map<String , P_L_Statement__c> bankAccYearAndStatementMap = new Map<String , P_L_Statement__c>();
        Map<String , List<PL_Statement_Week__c>> bankAccYearAndStatementListMap = new Map<String , List<PL_Statement_Week__c>>();
        List<PL_Statement_Week__c> childPLStatementList = new List<PL_Statement_Week__c>();
        For(P_L_Statement__c pls : plStatementListAlreadyExits){
            bankAccYearAndStatementMap.put(pls.Parent_Bank_Account__c+':'+pls.Year__c , pls); 
            
            if(pls.PL_Statement_Weeks__r.size()>0){
                for(PL_Statement_Week__c plChild : pls.PL_Statement_Weeks__r){
                    if(!bankAccYearAndStatementListMap.containsKey(plChild.Payment_Account__c+':'+plChild.Year__c)){
                        bankAccYearAndStatementListMap.put(plChild.Payment_Account__c+':'+plChild.Year__c, new List<PL_Statement_Week__c>());
                    }
                    bankAccYearAndStatementListMap.get(plChild.Payment_Account__c+':'+plChild.Year__c).add(plChild);  
                }
                
            }
        }
        List<P_L_Statement__c> plStatementToInsert = new List<P_L_Statement__c>();
        List<String> arrCatYearMonth = new List<String>();
        For(String catYearMonthLoop : paymentAccMonthYearAndForecastAmount.keySet()){
            
            arrCatYearMonth = catYearMonthLoop.split(':');
            String catYearMonth = arrCatYearMonth[0]+':'+arrCatYearMonth[1]+':'+arrCatYearMonth[2];
            String toBeMatched = arrCatYearMonth[0]+':'+arrCatYearMonth[1];
            P_L_Statement__c pls;
            
            system.debug('catYearMonth'+catYearMonth);
            List<String> arrCatYearMonthWeek = new List<String>();
            String notTocreateChild = '';
            if(!bankAccYearAndStatementMap.containsKey(toBeMatched)){
                pls = new P_L_Statement__c();
                List<PL_Statement_Week__c> childPLWeek = CashForecastMainController.getChildPl(arrCatYearMonth[1], CSS).values();
                if(arrCatYearMonth[0] != 'null'){
                    pls.Parent_Bank_Account__c = arrCatYearMonth[0];
                }
                pls.Cash_Tyoe__c = arrCatYearMonth[3];
                pls.Year__c = arrCatYearMonth[1];
                bankAccYearAndStatementMap.put(toBeMatched,pls);
                
                for(String strFromChild : paymentAccMonthYearWeekAndAmount.keySet()){
                    system.debug('strFromChild'+strFromChild);
                    arrCatYearMonthWeek = strFromChild.split(':');
                    if(arrCatYearMonthWeek[0] == arrCatYearMonth[0] && arrCatYearMonth[1] == arrCatYearMonthWeek[1] && arrCatYearMonth[2] == arrCatYearMonthWeek[2]){
                        system.debug('catYearMonth'+catYearMonth);
                        for(PL_Statement_Week__c psw:childPLWeek){
                            if(arrCatYearMonthWeek[0] != 'null'){
                            	psw.Payment_Account__c =  arrCatYearMonthWeek[0];
                            }
                            //PL_Statement_Week__c psw = new PL_Statement_Week__c ();
                            if(psw.Month_In_Number__c == arrCatYearMonthWeek[2]){
                                system.debug('arrCatYearMonthWeek'+arrCatYearMonthWeek[2]);
                                Decimal catweekAmount = paymentAccMonthYearWeekAndAmount.get(strFromChild);
                                switch on arrCatYearMonthWeek[3] {
                                    when '1' {
                                        psw.Week1__c = psw.Week1__c == null ? catweekAmount : psw.Week1__c + catweekAmount;
                                    }   
                                    when '2' {
                                        psw.Week2__c = psw.Week2__c == null ? catweekAmount : psw.Week2__c + catweekAmount;
                                    }
                                    when '3' {
                                        psw.Week3__c = psw.Week3__c == null ? catweekAmount : psw.Week3__c + catweekAmount;
                                    }
                                    when '4' {
                                        psw.Week4__c = psw.Week4__c == null ? catweekAmount : psw.Week4__c + catweekAmount;
                                    }
                                    when '5' {
                                        psw.Week5__c = psw.Week5__c == null ? catweekAmount : psw.Week5__c + catweekAmount;
                                    }
                                    
                                }
                                //system.debug('psw'+psw);
                                notTocreateChild = strFromChild;
                            }
                            
                        }
                        
                    }
                }
                childPLStatementList.addAll(childPLWeek);
            }
            else{
                //system.assert(false,'notTocreateChild'+notTocreateChild);
                pls = bankAccYearAndStatementMap.get(toBeMatched);
                for(String strFromChild : paymentAccMonthYearWeekAndAmount.keySet()){
                    arrCatYearMonthWeek = strFromChild.split(':');
                    if(arrCatYearMonthWeek[0] == arrCatYearMonth[0] && arrCatYearMonth[1] == arrCatYearMonthWeek[1] && arrCatYearMonth[2] == arrCatYearMonthWeek[2] && !bankAccYearAndStatementListMap.containsKey(arrCatYearMonthWeek[0]+':'+arrCatYearMonthWeek[1])){
                        for(PL_Statement_Week__c psw : childPLStatementList){
                            if(psw.Year__c == arrCatYearMonthWeek[1] && psw.Month_In_Number__c == arrCatYearMonthWeek[2] && psw.Payment_Account__c == arrCatYearMonthWeek[0] ){
                                system.debug('psw'+psw);
                            
                                Decimal catweekAmount = paymentAccMonthYearWeekAndAmount.get(strFromChild);
                                switch on arrCatYearMonthWeek[3] {
                                    when '1' {
                                        psw.Week1__c = psw.Week1__c == null ? catweekAmount : psw.Week1__c + catweekAmount;
                                    }   
                                    when '2' {
                                        psw.Week2__c = psw.Week2__c == null ? catweekAmount : psw.Week2__c + catweekAmount;
                                    }
                                    when '3' {
                                        psw.Week3__c = psw.Week3__c == null ? catweekAmount : psw.Week3__c + catweekAmount;
                                    }
                                    when '4' {
                                        psw.Week4__c = psw.Week4__c == null ? catweekAmount : psw.Week4__c + catweekAmount;
                                    }
                                    when '5' {
                                        psw.Week5__c = psw.Week5__c == null ? catweekAmount : psw.Week5__c + catweekAmount;
                                    }
                                }
                            }
                        }
                    }
                    else if(arrCatYearMonthWeek[0] == arrCatYearMonth[0] && arrCatYearMonth[1] == arrCatYearMonthWeek[1] && arrCatYearMonth[2] == arrCatYearMonthWeek[2] && bankAccYearAndStatementListMap.containsKey(arrCatYearMonthWeek[0]+':'+arrCatYearMonthWeek[1])){
                        for(PL_Statement_Week__c plsw: bankAccYearAndStatementListMap.get((arrCatYearMonthWeek[0]+':'+arrCatYearMonthWeek[1]))){
                            system.debug(plsw.Month_In_Number__c+'<>'+arrCatYearMonth[2]);
                            if(plsw.Month_In_Number__c == arrCatYearMonth[2] && (arrCatYearMonth[3] == 'Deposits' || plsw.Payment_Account__c == arrCatYearMonthWeek[0])){
                                system.debug('plsw'+plsw.Month_In_Number__c);
                                system.debug('plsw'+plsw);
                                Decimal catweekAmount = paymentAccMonthYearWeekAndAmount.get(strFromChild);
                                switch on arrCatYearMonthWeek[3] {
                                    when '1' {
                                        if(Schema.sObjectType.PL_Statement_Week__c.fields.Week1__c.isUpdateable() || Schema.sObjectType.PL_Statement_Week__c.fields.Week1__c.isCreateable()){
                                            plsw.Week1__c = plsw.Week1__c == null ? catweekAmount : plsw.Week1__c + catweekAmount;
                                        }
                                    }   
                                    when '2' {
                                        if(Schema.sObjectType.PL_Statement_Week__c.fields.Week2__c.isUpdateable() || Schema.sObjectType.PL_Statement_Week__c.fields.Week2__c.isCreateable()){
                                            plsw.Week2__c = plsw.Week2__c == null ? catweekAmount : plsw.Week2__c + catweekAmount;
                                        }
                                    }
                                    when '3' {
                                        if(Schema.sObjectType.PL_Statement_Week__c.fields.Week3__c.isUpdateable() || Schema.sObjectType.PL_Statement_Week__c.fields.Week3__c.isCreateable()){
                                            plsw.Week3__c = plsw.Week3__c == null ? catweekAmount : plsw.Week3__c + catweekAmount;
                                        }
                                    }
                                    when '4' {
                                        if(Schema.sObjectType.PL_Statement_Week__c.fields.Week4__c.isUpdateable() || Schema.sObjectType.PL_Statement_Week__c.fields.Week4__c.isCreateable()){
                                            plsw.Week4__c = plsw.Week4__c == null ? catweekAmount : plsw.Week4__c + catweekAmount;
                                        }
                                    }
                                    when '5' {
                                        if(Schema.sObjectType.PL_Statement_Week__c.fields.Week5__c.isUpdateable() || Schema.sObjectType.PL_Statement_Week__c.fields.Week5__c.isCreateable()){
                                            plsw.Week5__c = plsw.Week5__c == null ? catweekAmount : plsw.Week5__c + catweekAmount;
                                        }
                                    }
                                }
                                childPLStatementList.add(plsw);
                            }
                        }
                    }
                }
                
            }
            
            Decimal catmonthAmount = paymentAccMonthYearAndForecastAmount.get(catYearMonthLoop);
            switch on arrCatYearMonth[2] {
                when '1' {
                    pls.January__c = pls.January__c == null ? catmonthAmount : pls.January__c + catmonthAmount;
                }   
                when '2' {
                    pls.February__c = pls.February__c == null ? catmonthAmount : pls.February__c + catmonthAmount;
                }
                when '3' {
                    pls.March__c = pls.March__c == null ? catmonthAmount : pls.March__c + catmonthAmount;
                }
                when '4' {
                    pls.April__c = pls.April__c == null ? catmonthAmount : pls.April__c + catmonthAmount;
                }
                when '5' {
                    pls.May__c = pls.May__c == null ? catmonthAmount : pls.May__c + catmonthAmount;
                }
                when '6' {
                    pls.June__c = pls.June__c == null ? catmonthAmount : pls.June__c + catmonthAmount;
                }
                when '7' {
                    pls.July__c = pls.July__c == null ? catmonthAmount : pls.July__c + catmonthAmount;
                }
                when '8' {
                    pls.August__c = pls.August__c == null ? catmonthAmount : pls.August__c + catmonthAmount;
                }
                when '9' {
                    pls.September__c = pls.September__c == null ? catmonthAmount : pls.September__c + catmonthAmount;
                }
                when '10' {
                    pls.October__c = pls.October__c == null ? catmonthAmount : pls.October__c + catmonthAmount;
                }
                when '11' {
                    pls.November__c = pls.November__c == null ? catmonthAmount : pls.November__c + catmonthAmount;
                }
                when else {
                    pls.December__c = pls.December__c == null ? catmonthAmount : pls.December__c + catmonthAmount;
                }
            }
            
        }
        if(bankAccYearAndStatementMap.values().size()>0){
            try{
                PlaceCPM_Utility.upsertRecords(bankAccYearAndStatementMap.values(), CONSTANT.expenseAccountObject, false); //520
            }
            catch(Exception ex){
                PlaceCPM_Utility.debugLog(ex.getMessage() + ' at line number ' + ex.getLineNumber());
            }
            
        }
        //system.debug('bankAccYearAndStatementMap'+bankAccYearAndStatementMap);
        for(PL_Statement_Week__c plCh : childPLStatementList){
            if(plCh.Parent_P_L_Statement__c == null){
                String matchingStr = plCh.Payment_Account__c+':'+plch.Year__c;
                plCh.Parent_P_L_Statement__c =  bankAccYearAndStatementMap.get(matchingStr).Id;
            }
            
        }
        
        
        try{
            PlaceCPM_Utility.upsertRecords(childPLStatementList, CONSTANT.PL_STATEMENT_WEEK_OBJECT, false); //520
        }catch(Exception ex){
            PlaceCPM_Utility.debugLog(ex.getMessage() + ' at line number ' + ex.getLineNumber());
        }
        
    }*/
}
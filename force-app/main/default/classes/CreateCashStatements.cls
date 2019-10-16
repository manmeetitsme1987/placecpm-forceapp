public with sharing class CreateCashStatements {
    public static void createCategoryStatements(List<SObject> newList , Map<Id , SObject> oldMap){
        Expense_Cash_Allocation__c expl;
        Revenue_Cash_Allocation__c rvpl;
        Expense_Cash_Allocation__c oldexpl;
        Revenue_Cash_Allocation__c oldrvpl;
        Set<String> yearList = new Set<String>();
        Set<String> categoryList = new Set<String>();
        Set<String> paymentAccountSet = new Set<String>();
        Set<GL_Code__c> glCodeList = new  Set<GL_Code__c>();
        Id cat;
        Id plcat;
        Id paymentAccountId;
        String year;
        Integer month;
        PLWrapper plswrap;
        PLWrapper weekPlswrap;
        Decimal oldAmountForecast;
        Decimal newAmountForecast;
        Decimal amountForecastDiff = 0.0;
        Decimal oldAmountActual;
        Decimal oldAmountActualtDiff = 0.0;
        Decimal newAmountActual;
        String mapkey;
        String weekMapKey;
		Id oldcat;
        String oldmapkey;
        PLWrapper oldplswrap;
        Date weekEndDate;
        Map<String , PLWrapper> categoryMonthYearAndExpenseAmount = new  Map<String , PLWrapper>();
        Map<String , PLWrapper> categoryDateAndExpenseAmount = new  Map<String , PLWrapper>();
        Map<String , P_L_Statement__c> yearCatAndStatementMap = new Map<String , P_L_Statement__c>();
        List<String> arrCatYearMonth = new List<String>();
        For(SObject sobj : newList != null ? newList : oldMap.values()){
            Boolean isChangedGlCode = false;
            if(sobj instanceOF Expense_Cash_Allocation__c){
                expl = (Expense_Cash_Allocation__c)sobj;
                cat = expl.GL_Code__c;
                plcat = expl.PLCategory__c;
                year = String.valueOf((Integer)expl.Cash_Forecast_Year__c);
                month = (Integer)expl.Cash_Forecast_Month__c;
                paymentAccountId = expl.Payment_Account_Id__c;
                weekEndDate = expl.Week_End_Date_Gregorian__c;
                categoryList.add(cat);
                yearList.add(year);
                paymentAccountSet.add(paymentAccountId);
                mapkey = cat+':'+year+':'+month+':'+plcat+':'+paymentAccountId;
                weekMapKey = cat + ';' + year +  ';' + plcat + ';' + paymentAccountId + ';' +  weekEndDate;
                if(!categoryMonthYearAndExpenseAmount.containsKey(mapkey)){
                    plswrap = new PLWrapper();
                    categoryMonthYearAndExpenseAmount.put(mapkey , plswrap);
                }
                if(!categoryDateAndExpenseAmount.containsKey(weekMapKey)){
                    weekPlswrap = new PLWrapper();
                    categoryDateAndExpenseAmount.put(weekMapKey , weekPlswrap);
                }
                plswrap = categoryMonthYearAndExpenseAmount.get(mapkey);
                weekPlswrap = categoryDateAndExpenseAmount.get(weekMapKey);
                if(oldMap != null){
                    oldexpl = (Expense_Cash_Allocation__c)oldMap.get(expl.Id);
                    if(expl.GL_Code__c != null && expl.GL_Code__c != oldexpl.GL_Code__c) {
                        isChangedGlCode = true;
                    }
                    if(expl.Forecast_Amount__c != oldexpl.Forecast_Amount__c ){
                        oldAmountForecast = oldexpl.Forecast_Amount__c != null ? oldexpl.Forecast_Amount__c : 0.0;
                        newAmountForecast = expl.Forecast_Amount__c != null ? expl.Forecast_Amount__c : 0.0;
                        amountForecastDiff = newAmountForecast - oldAmountForecast;
                        plswrap.forecastAmount = categoryMonthYearAndExpenseAmount.get(mapkey).forecastAmount + amountForecastDiff;
                        weekPlswrap.forecastAmount = categoryDateAndExpenseAmount.get(weekMapKey).forecastAmount + amountForecastDiff;
                    }
                    if(expl.Actual_Amount__c != oldexpl.Actual_Amount__c){
                        oldAmountActual = oldexpl.Actual_Amount__c != null ? oldexpl.Actual_Amount__c : 0.0;
                        newAmountActual = expl.Actual_Amount__c != null ?  expl.Actual_Amount__c  : 0.0;
                        oldAmountActualtDiff = newAmountActual - oldAmountActual;
                        plswrap.actualAmount = categoryMonthYearAndExpenseAmount.get(mapkey).actualAmount + oldAmountActualtDiff;
                        weekPlswrap.actualAmount = categoryDateAndExpenseAmount.get(weekMapKey).actualAmount + oldAmountActualtDiff;
                    }
                    if(isChangedGlCode){
                        if(expl.Forecast_Amount__c == oldexpl.Forecast_Amount__c) {
                            amountForecastDiff = expl.Forecast_Amount__c != null ? expl.Forecast_Amount__c : 0.0;
                        } else {
                            oldAmountForecast = oldexpl.Forecast_Amount__c != null ? oldexpl.Forecast_Amount__c : 0.0;
                            newAmountForecast = expl.Forecast_Amount__c != null ? expl.Forecast_Amount__c : 0.0;
                            amountForecastDiff = newAmountForecast - oldAmountForecast;
                        }
                        if(expl.Actual_Amount__c == oldexpl.Actual_Amount__c) {
                            oldAmountActualtDiff = expl.Actual_Amount__c != null ?  expl.Actual_Amount__c  : 0.0;
                        } else {
                            oldAmountActual = oldexpl.Actual_Amount__c != null ? oldexpl.Actual_Amount__c : 0.0;
                            newAmountActual = expl.Actual_Amount__c != null ?  expl.Actual_Amount__c  : 0.0;
                            oldAmountActualtDiff = newAmountActual - oldAmountActual;
                        }
                        plswrap.actualAmount = categoryMonthYearAndExpenseAmount.get(mapkey).actualAmount + oldAmountActualtDiff;
                        plswrap.forecastAmount = categoryMonthYearAndExpenseAmount.get(mapkey).forecastAmount + amountForecastDiff;
                        oldcat = oldexpl.GL_Code__c ;
                        categoryList.add(oldcat);
                        oldmapkey = oldcat+':'+year+':'+month+':'+plcat+':'+paymentAccountId;
                        if(!categoryMonthYearAndExpenseAmount.containsKey(oldmapkey)){
                            oldplswrap = new PLWrapper();
                            oldplswrap.forecastAmount = 0.0;
                            oldplswrap.actualAmount = 0.0;
                            categoryMonthYearAndExpenseAmount.put(oldmapkey , oldplswrap);
                        }
                        oldplswrap = categoryMonthYearAndExpenseAmount.get(oldmapkey);
                        oldplswrap.forecastAmount = categoryMonthYearAndExpenseAmount.get(oldmapkey).forecastAmount - amountForecastDiff;
                        oldplswrap.actualAmount = categoryMonthYearAndExpenseAmount.get(oldmapkey).actualAmount - oldAmountActualtDiff;
                        categoryMonthYearAndExpenseAmount.put(oldmapkey , oldplswrap);
                    }
                    if(newList == null){
                        if(oldexpl.Forecast_Amount__c != null){
                            oldAmountForecast = oldexpl.Forecast_Amount__c != null ? oldexpl.Forecast_Amount__c : 0.0;
                            newAmountForecast = 0.0;
                            amountForecastDiff = newAmountForecast - oldAmountForecast;
                            plswrap.forecastAmount = categoryMonthYearAndExpenseAmount.get(mapkey).forecastAmount + amountForecastDiff;
                            weekPlswrap.forecastAmount = categoryDateAndExpenseAmount.get(weekMapKey).forecastAmount + amountForecastDiff;
                        }
                        if(oldexpl.Actual_Amount__c != null){
                            oldAmountActual = oldexpl.Actual_Amount__c != null ? oldexpl.Actual_Amount__c : 0.0;
                            newAmountActual = 0.0;
                            amountForecastDiff = newAmountActual - oldAmountActual;
                            plswrap.actualAmount = categoryMonthYearAndExpenseAmount.get(mapkey).actualAmount + amountForecastDiff;
                            weekPlswrap.actualAmount = categoryDateAndExpenseAmount.get(weekMapKey).actualAmount + amountForecastDiff;
                        }
                    }
                }
                else{
                    if(expl.Forecast_Amount__c != null){
                        plswrap.forecastAmount = categoryMonthYearAndExpenseAmount.get(mapkey).forecastAmount + expl.Forecast_Amount__c;
                        weekPlswrap.forecastAmount = categoryDateAndExpenseAmount.get(weekMapKey).forecastAmount + expl.Forecast_Amount__c;
                    }
                    if(expl.Actual_Amount__c != null){
                        plswrap.actualAmount = categoryMonthYearAndExpenseAmount.get(mapkey).actualAmount + expl.Actual_Amount__c;
                        weekPlswrap.actualAmount = categoryDateAndExpenseAmount.get(weekMapKey).actualAmount + expl.Actual_Amount__c;
                    }
                }
                categoryMonthYearAndExpenseAmount.put(mapkey , plswrap);
                categoryDateAndExpenseAmount.put(weekMapKey , weekPlswrap);
            }
            else{
                rvpl = (Revenue_Cash_Allocation__c)sobj;
                cat = rvpl.GL_Code__c;
                plcat = rvpl.PLCategory__c;
                year = String.valueOf((Integer)rvpl.Cash_Forecast_Year__c);
                month = (Integer)rvpl.Cash_Forecast_Month__c;
                weekEndDate = rvpl.Week_End_Date_Gregorian__c;
                paymentAccountId = rvpl.Payment_Account_Id__c;
                categoryList.add(cat);
                yearList.add(year);
                paymentAccountSet.add(paymentAccountId);
                mapkey = cat+':'+year+':'+month+':'+plcat+':'+paymentAccountId;
                weekMapKey = cat + ';' + year +  ';' + plcat + ';' + paymentAccountId + ';' +  weekEndDate;
                if(!categoryMonthYearAndExpenseAmount.containsKey(mapkey)){
                    plswrap = new PLWrapper();
                    categoryMonthYearAndExpenseAmount.put(mapkey , plswrap);
                }
                if(!categoryDateAndExpenseAmount.containsKey(weekMapKey)){
                    weekPlswrap = new PLWrapper();
                    categoryDateAndExpenseAmount.put(weekMapKey , weekPlswrap);
                }
                plswrap = categoryMonthYearAndExpenseAmount.get(mapkey);
                weekPlswrap = categoryDateAndExpenseAmount.get(weekMapKey);
                if(oldMap != null){
                    oldrvpl = (Revenue_Cash_Allocation__c)oldMap.get(rvpl.Id);
                    if(rvpl.GL_Code__c != oldrvpl.GL_Code__c) {
                        isChangedGlCode = true;
                    }
                    if(rvpl.Forecast_Amount__c != oldrvpl.Forecast_Amount__c ){
                        oldAmountForecast = oldrvpl.Forecast_Amount__c != null ? oldrvpl.Forecast_Amount__c : 0.0;
                        newAmountForecast = rvpl.Forecast_Amount__c != null ? rvpl.Forecast_Amount__c : 0.0;
                        amountForecastDiff =  newAmountForecast - oldAmountForecast;
                        plswrap.forecastAmount = categoryMonthYearAndExpenseAmount.get(mapkey).forecastAmount + amountForecastDiff;
                        weekPlswrap.forecastAmount = categoryDateAndExpenseAmount.get(weekMapKey).forecastAmount + amountForecastDiff;
                    }
                    if(rvpl.Actual_Amount__c != oldrvpl.Actual_Amount__c ){
                        oldAmountActual = oldrvpl.Actual_Amount__c != null ? oldrvpl.Actual_Amount__c : 0.0;
                        newAmountActual = rvpl.Actual_Amount__c != null ?  rvpl.Actual_Amount__c  : 0.0;
                        oldAmountActualtDiff =  newAmountActual - oldAmountActual;
                        plswrap.actualAmount = categoryMonthYearAndExpenseAmount.get(mapkey).actualAmount + oldAmountActualtDiff;
                        weekPlswrap.actualAmount = categoryDateAndExpenseAmount.get(weekMapKey).actualAmount + oldAmountActualtDiff;
                    }
                    if(isChangedGlCode){
                        if(rvpl.Forecast_Amount__c == oldrvpl.Forecast_Amount__c) {
                            amountForecastDiff = rvpl.Forecast_Amount__c != null ? rvpl.Forecast_Amount__c : 0.0;
                        } else {
                            oldAmountForecast = oldrvpl.Forecast_Amount__c != null ? oldrvpl.Forecast_Amount__c : 0.0;
                            newAmountForecast = rvpl.Forecast_Amount__c != null ? rvpl.Forecast_Amount__c : 0.0;
                            amountForecastDiff = newAmountForecast - oldAmountForecast;
                        }
                        if(rvpl.Actual_Amount__c == oldrvpl.Actual_Amount__c) {
                            oldAmountActualtDiff = rvpl.Actual_Amount__c != null ? rvpl.Actual_Amount__c  : 0.0;
                        } else {
                            oldAmountActual = oldrvpl.Actual_Amount__c != null ? oldrvpl.Actual_Amount__c : 0.0;
                            newAmountActual = rvpl.Actual_Amount__c != null ?  rvpl.Actual_Amount__c  : 0.0;
                            oldAmountActualtDiff = newAmountActual - oldAmountActual;
                        }
                        plswrap.actualAmount = categoryMonthYearAndExpenseAmount.get(mapkey).actualAmount + oldAmountActualtDiff;
                        plswrap.forecastAmount = categoryMonthYearAndExpenseAmount.get(mapkey).forecastAmount + amountForecastDiff;
                        oldcat = oldrvpl.GL_Code__c ;
                        categoryList.add(oldcat);
                        oldmapkey = oldcat+':'+year+':'+month+':'+plcat+':'+paymentAccountId;
                        if(!categoryMonthYearAndExpenseAmount.containsKey(oldmapkey)){
                            oldplswrap = new PLWrapper();
                            oldplswrap.forecastAmount = 0.0;
                            oldplswrap.actualAmount = 0.0;
                            categoryMonthYearAndExpenseAmount.put(oldmapkey , oldplswrap);
                        }
                        oldplswrap = categoryMonthYearAndExpenseAmount.get(oldmapkey);
                        oldplswrap.forecastAmount = categoryMonthYearAndExpenseAmount.get(oldmapkey).forecastAmount - amountForecastDiff;
                        oldplswrap.actualAmount = categoryMonthYearAndExpenseAmount.get(oldmapkey).actualAmount - oldAmountActualtDiff;
                        categoryMonthYearAndExpenseAmount.put(oldmapkey , oldplswrap);
                    }
                    if(newList == null){
                        if(oldrvpl.Forecast_Amount__c != null){
                            oldAmountForecast = oldrvpl.Forecast_Amount__c != null ? oldrvpl.Forecast_Amount__c : 0.0;
                            newAmountForecast = 0.0;
                            amountForecastDiff = newAmountForecast - oldAmountForecast;
                            plswrap.forecastAmount = categoryMonthYearAndExpenseAmount.get(mapkey).forecastAmount + amountForecastDiff;
                            weekPlswrap.forecastAmount = categoryDateAndExpenseAmount.get(weekMapKey).forecastAmount + amountForecastDiff;
                        }
                        if(oldrvpl.Actual_Amount__c != null){
                            oldAmountActual = oldrvpl.Actual_Amount__c != null ? oldrvpl.Actual_Amount__c : 0.0;
                            newAmountActual = 0.0;
                            amountForecastDiff = newAmountActual - oldAmountActual;
                            plswrap.actualAmount = categoryMonthYearAndExpenseAmount.get(mapkey).actualAmount + amountForecastDiff;
                            weekPlswrap.actualAmount = categoryDateAndExpenseAmount.get(weekMapKey).actualAmount + amountForecastDiff;
                        }
                    }
                }
                else{
                    if(rvpl.Forecast_Amount__c != null){
                        plswrap.forecastAmount = categoryMonthYearAndExpenseAmount.get(mapkey).forecastAmount + rvpl.Forecast_Amount__c;
                        weekPlswrap.forecastAmount = categoryDateAndExpenseAmount.get(weekMapKey).forecastAmount + rvpl.Forecast_Amount__c;
                    }
                    if(rvpl.Actual_Amount__c != null){
                        plswrap.actualAmount = categoryMonthYearAndExpenseAmount.get(mapkey).actualAmount + rvpl.Actual_Amount__c;
                        weekPlswrap.actualAmount = categoryDateAndExpenseAmount.get(weekMapKey).actualAmount + rvpl.Actual_Amount__c;
                    }
                }
                categoryMonthYearAndExpenseAmount.put(mapkey , plswrap);
                categoryDateAndExpenseAmount.put(weekMapKey , weekPlswrap);
            }
        }
        if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.PL_STATEMENT_OBJECT,'January__c , February__c , March__c , April__c ,'+
                                                                    'May__c , June__c , July__c , August__c , September__c , October__c ,'+
                                                                    'November__c , December__c ,Sequence__c , Parent_Bank_Account__c,Year__c,'+
                                                                    'January_Actual__c , February_Actual__c , March_Actual__c , April_Actual__c , May_Actual__c ,'+
                                                                    'June_Actual__c , July_Actual__c , August_Acutal__c , September_Acutal__c , October_Actual__c ,'+ 
                                                                    'November_Actual__c , December_Actual__c',Constant.ACTION_TYPE_ACCESS) &&
          PlaceCPM_Utility.checkAccessiblityOfFields(Constant.GL_CODE_OBJECT,'PL_Category__c',Constant.ACTION_TYPE_ACCESS)
          ){
            for(P_L_Statement__c plStatementListAlreadyExits : [SELECT id , Year__c , January__c , February__c , March__c , April__c ,
                                                                    May__c , June__c , July__c , August__c , September__c , October__c , 
                                                                    November__c , December__c , GL_Code__c, Sequence__c, GL_Code__r.PL_Category__c ,
                                                                    January_Actual__c , February_Actual__c , March_Actual__c , April_Actual__c , May_Actual__c , 
                                                                    June_Actual__c , July_Actual__c , August_Acutal__c , September_Acutal__c , October_Actual__c , 
                                                                    November_Actual__c , December_Actual__c , Parent_Bank_Account__c  From P_L_Statement__c WHERE Year__c IN : yearList 
                                                                    AND GL_Code__c IN : categoryList AND Statement_Type__c  =: CONSTANT.EXPCASHTYPE AND Parent_Bank_Account__c IN : paymentAccountSet]){
                yearCatAndStatementMap.put(plStatementListAlreadyExits.GL_Code__c + ':' + plStatementListAlreadyExits.Year__c + ':' + plStatementListAlreadyExits.Parent_Bank_Account__c 
                                            , plStatementListAlreadyExits); 
            }
    	}
        
        Boolean isJanuary = false, isFebruary = false, isMarch = false, isApril = false, isMay = false, isJune = false, isJuly = false;
        Boolean isAugust = false, isSeptember = false, isOctober = false, isNovember = false, isDecember = false;
        Boolean isJanActual = false, isFebActual = false, isMarchActual = false, isAprilActual = false, isMayActual = false, isJunActual = false, isJulActual = false;
        Boolean isAugActual = false, isSeptActual = false, isOctActual = false, isNovActual = false, isDecActual = false;
        
        if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.PL_STATEMENT_OBJECT,'January__c',Constant.ACTION_TYPE_UPDATE)){
            isJanuary = true;
        }  
        if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.PL_STATEMENT_OBJECT,'January_Actual__c',Constant.ACTION_TYPE_UPDATE)){
            isJanActual = true;
        }  
        if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.PL_STATEMENT_OBJECT,'February__c',Constant.ACTION_TYPE_UPDATE)){
            isFebruary = true;
        }
        if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.PL_STATEMENT_OBJECT,'February_Actual__c',Constant.ACTION_TYPE_UPDATE)){
            isFebActual = true;
        }
        if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.PL_STATEMENT_OBJECT,'March__c',Constant.ACTION_TYPE_UPDATE)){
            isMarch = true;
        }
        if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.PL_STATEMENT_OBJECT,'March_Actual__c',Constant.ACTION_TYPE_UPDATE)){
            isMarchActual = true;
        }
		if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.PL_STATEMENT_OBJECT,'April__c',Constant.ACTION_TYPE_UPDATE)){
            isApril = true;
        }
        if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.PL_STATEMENT_OBJECT,'April_Actual__c',Constant.ACTION_TYPE_UPDATE)){
            isAprilActual = true;
        } 
        if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.PL_STATEMENT_OBJECT,'May__c',Constant.ACTION_TYPE_UPDATE)){
            isMay = true;
        }
        if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.PL_STATEMENT_OBJECT,'May_Actual__c',Constant.ACTION_TYPE_UPDATE)){
            isMayActual = true;
        } 
        if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.PL_STATEMENT_OBJECT,'June__c',Constant.ACTION_TYPE_UPDATE)){
            isJune = true;
        }
        if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.PL_STATEMENT_OBJECT,'June_Actual__c',Constant.ACTION_TYPE_UPDATE)){
            isJunActual = true;
        }
        if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.PL_STATEMENT_OBJECT,'July__c',Constant.ACTION_TYPE_UPDATE)){
            isJuly = true;
        }
        if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.PL_STATEMENT_OBJECT,'July_Actual__c',Constant.ACTION_TYPE_UPDATE)){
            isJulActual = true;
        } 
        if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.PL_STATEMENT_OBJECT,'August__c',Constant.ACTION_TYPE_UPDATE)){
            isAugust = true;
        }
        if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.PL_STATEMENT_OBJECT,'August_Acutal__c',Constant.ACTION_TYPE_UPDATE)){
            isAugActual = true;
        } 
        if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.PL_STATEMENT_OBJECT,'September__c',Constant.ACTION_TYPE_UPDATE)){
            isSeptember = true;
        }
        if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.PL_STATEMENT_OBJECT,'September_Acutal__c',Constant.ACTION_TYPE_UPDATE)){
            isSeptActual = true;
        } 
        if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.PL_STATEMENT_OBJECT,'October__c',Constant.ACTION_TYPE_UPDATE)){
            isOctober = true;
        }
        if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.PL_STATEMENT_OBJECT,'October_Actual__c',Constant.ACTION_TYPE_UPDATE)){
            isOctActual = true;
        } 
        if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.PL_STATEMENT_OBJECT,'November__c',Constant.ACTION_TYPE_UPDATE)){
            isNovember = true;
        }
        if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.PL_STATEMENT_OBJECT,'November_Actual__c',Constant.ACTION_TYPE_UPDATE)){
            isNovActual = true;
        } 
        if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.PL_STATEMENT_OBJECT,'December__c',Constant.ACTION_TYPE_UPDATE)){
            isDecember = true;
        }
        if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.PL_STATEMENT_OBJECT,'December_Actual__c',Constant.ACTION_TYPE_UPDATE)){
            isDecActual = true;
        } 
        for(String catYearMonth : categoryMonthYearAndExpenseAmount.keySet()){
            arrCatYearMonth = catYearMonth.split(':');
            String toBeMatched = arrCatYearMonth[0] + ':' + arrCatYearMonth[1] + ':' + arrCatYearMonth[4];
            P_L_Statement__c pls = yearCatAndStatementMap.containsKey(toBeMatched) ? yearCatAndStatementMap.get(toBeMatched) : new P_L_Statement__c();
            if(yearCatAndStatementMap.containsKey(toBeMatched)){
                Decimal catmonthForecastAmount = categoryMonthYearAndExpenseAmount.get(catYearMonth).forecastAmount;
                Decimal catmonthActualAmount = categoryMonthYearAndExpenseAmount.get(catYearMonth).actualAmount;
                switch on arrCatYearMonth[2] {
                    when '1' {
                        if(isJanuary){
                            pls.January__c = pls.January__c == null ? catmonthForecastAmount : pls.January__c + catmonthForecastAmount;
                        }  
                        if(isJanActual){
                            pls.January_Actual__c = pls.January_Actual__c == null ? catmonthActualAmount : pls.January_Actual__c + catmonthActualAmount;
                        }    
                    }   
                    when '2' {
                        if(isFebruary){
                        	pls.February__c = pls.February__c == null ? catmonthForecastAmount : pls.February__c + catmonthForecastAmount;
                        }
                        if(isFebActual){
                        	pls.February_Actual__c = pls.February_Actual__c == null ? catmonthActualAmount : pls.February_Actual__c + catmonthActualAmount;
                        }
                    }
                    when '3' {
                        if(isMarch){
                        	pls.March__c = pls.March__c == null ? catmonthForecastAmount : pls.March__c + catmonthForecastAmount;
                        }
                        if(isMarchActual){
                        	pls.March_Actual__c = pls.March_Actual__c == null ? catmonthActualAmount : pls.March_Actual__c + catmonthActualAmount;
                        }
                    }
                    when '4' {
                        if(isApril){
                        	pls.April__c = pls.April__c == null ? catmonthForecastAmount : pls.April__c + catmonthForecastAmount;
                        }
                        if(isAprilActual){
                        	pls.April_Actual__c = pls.April_Actual__c == null ? catmonthActualAmount : pls.April_Actual__c + catmonthActualAmount;
                        }    
                    }
                    when '5' {
                        if(isMay){
                        	pls.May__c = pls.May__c == null ? catmonthForecastAmount : pls.May__c + catmonthForecastAmount;
                        }
                        if(isMayActual){
                        	pls.May_Actual__c = pls.May_Actual__c == null ? catmonthActualAmount : pls.May_Actual__c + catmonthActualAmount;
                        }    
                    }
                    when '6' {
                        if(isJune){
                        	pls.June__c = pls.June__c == null ? catmonthForecastAmount : pls.June__c + catmonthForecastAmount;
                        }
                        if(isJunActual){
                        	pls.June_Actual__c = pls.June_Actual__c == null ? catmonthActualAmount : pls.June_Actual__c + catmonthActualAmount;
                        }
                    }
                    when '7' {
                        if(isJuly){
                        	pls.July__c = pls.July__c == null ? catmonthForecastAmount : pls.July__c + catmonthForecastAmount;
                        }
                        if(isJulActual){
                        	pls.July_Actual__c = pls.July_Actual__c == null ? catmonthActualAmount : pls.July_Actual__c + catmonthActualAmount;
                        }    
                    }
                    when '8' {
                        if(isAugust){
                        	pls.August__c = pls.August__c == null ? catmonthForecastAmount : pls.August__c + catmonthForecastAmount;	
                        }
                        if(isAugActual){
                        	pls.August_Acutal__c = pls.August_Acutal__c == null ? catmonthActualAmount : pls.August_Acutal__c + catmonthActualAmount;
                        }    
                    }
                    when '9' {
						if(isSeptember){
                        	pls.September__c = pls.September__c == null ? catmonthForecastAmount : pls.September__c + catmonthForecastAmount;	
                        }
                        if(isSeptActual){
                        	pls.September_Acutal__c = pls.September_Acutal__c == null ? catmonthActualAmount : pls.September_Acutal__c + catmonthActualAmount;
                        }    
                    }
                    when '10' {
                        if(isOctober){
                        	pls.October__c = pls.October__c == null ? catmonthForecastAmount : pls.October__c + catmonthForecastAmount;
                        }
                        if(isOctActual){
                        	pls.October_Actual__c = pls.October_Actual__c == null ? catmonthActualAmount : pls.October_Actual__c + catmonthActualAmount;
                        }    
                    }
                    when '11' {
                        if(isNovember){
                        	pls.November__c = pls.November__c == null ? catmonthForecastAmount : pls.November__c + catmonthForecastAmount;
                        }
                        if(isNovActual){
                            pls.November_Actual__c = pls.November_Actual__c == null ? catmonthActualAmount : pls.November_Actual__c + catmonthActualAmount;
                        }    
                    }
                    when else {
                        if(isDecember){
                        	pls.December__c = pls.December__c == null ? catmonthForecastAmount : pls.December__c + catmonthForecastAmount;
                        }
                        if(isDecActual){
                        	pls.December_Actual__c = pls.December_Actual__c == null ? catmonthActualAmount : pls.December_Actual__c + catmonthActualAmount;
                        }    
                    }
                }
            }
        }
        getYearWeekDate(yearList);
        for(String catDatePaymentAccount : categoryDateAndExpenseAmount.keySet()){
            arrCatYearMonth = catDatePaymentAccount.split(';');
            String toBeMatched = arrCatYearMonth[0] + ':' + arrCatYearMonth[1] + ':' + arrCatYearMonth[3];  
            P_L_Statement__c pls = yearCatAndStatementMap.containsKey(toBeMatched) ? yearCatAndStatementMap.get(toBeMatched) : new P_L_Statement__c();
            if(yearCatAndStatementMap.containsKey(toBeMatched)){
                Decimal catmonthForecastAmount = categoryDateAndExpenseAmount.get(catDatePaymentAccount).forecastAmount;
                Decimal catmonthActualAmount = categoryDateAndExpenseAmount.get(catDatePaymentAccount).actualAmount;
                if(arrCatYearMonth[4] != 'null' && dateAndkey.containsKey(Date.valueOf(arrCatYearMonth[4]))){
                    pls.put('week' + dateAndkey.get(Date.valueOf(arrCatYearMonth[4])) + '_Actual__c' , catmonthActualAmount);
                    pls.put('week' + dateAndkey.get(Date.valueOf(arrCatYearMonth[4])) + '_Forecast__c' , catmonthForecastAmount);
                }
            }
        }
        PlaceCPM_Utility.updateRecords(yearCatAndStatementMap.values() , CONSTANT.PL_STATEMENT_OBJECT , false);
    }
    
    static Map<Date , Integer> dateAndkey = new  Map<Date , Integer>();

    static void getYearWeekDate(Set<String> yearList){
        Date startDate;
        Date tempDateSunday = Date.newInstance(1900, 1, 7);
        Integer mod;
        Date firstSunday;
        Integer i;
        for(String years : yearList){
            i = 0;
            Integer tempYear = Integer.valueOf(years);
            startDate = Date.newInstance(tempYear, 1, 1);
            mod =  Math.mod(tempDateSunday.daysBetween(startDate) , 7);
            firstSunday = mod == 0 ? startDate : startDate.addDays(7 - mod);
            for(Date d = firstSunday ; firstSunday.year() <= tempYear ; firstSunday = firstSunday+7){
                dateAndkey.put(firstSunday , ++i);
            }
        }
    }
    
    class PLWrapper{
        public Decimal forecastAmount = 0.0;
        public Decimal actualAmount = 0.0;
    }
}
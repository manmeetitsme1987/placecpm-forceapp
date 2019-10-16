/*
Description : This class will be as controller for PAndL component.
Date Created : 17th June 2019
*/
public with sharing class PAndLTabController{
    Static Integer currentMonth = System.today().month();
    Public Static MainWrapper mainWrapper;
    Public Static SummaryWrapper temp;
    Public Static String timeFrameGlobal = Label.MONTH;

    // Method to delete the object of given id
    // PCPM-438
    @AuraEnabled
    public static String removeAcc(Id recId){
        try{
            if(recId != null) {
                PlaceCPM_Utility.deleteRecords(Database.query('Select Id From '+recId.getSObjectType().getDescribe().getName()+' where Id =: recId'), recId.getSObjectType().getDescribe().getName(), false);
                return null; 
            } else {
                return recId.getSObjectType().getDescribe().getLabel()+' '+ System.Label.Is_Not_Deletable ;
            }   
        } catch(Exception ex) {
            PlaceCPM_Utility.debugLog(ex.getMessage() + ' at line number ' + ex.getLineNumber());
         	return ex.getMessage();   
        }
    }

    //  Method to fetch PL Statement records.
    //  @param year is the selected year on PAndL component
    //  @return MainWrapper
    @AuraEnabled
    public static MainWrapper getPLStatement(String view , String timeFrame  , String dateRangesAttr) {
        Map<Integer , List<Integer>> dateRangeInput = new Map<Integer , List<Integer>>();
        List<Integer> tempList;
        if(dateRangesAttr != null && dateRangesAttr.length() > 0){
            yearsTobeFetched.clear();
            Map<String, Object> m = (Map<String , Object>)JSON.deserializeUntyped(dateRangesAttr);
            for(String year : m.keySet()){
                tempList = new List<Integer>();
                for(Object o : (List<Object>)m.get(year)){
                    tempList.add((Integer)o);
                }
                dateRangeInput.put(Integer.valueOf(year) , tempList);
                yearsTobeFetched.add(year);
            }
            dateRanges = dateRangeInput;
        }
        timeFrameGlobal = timeFrame;
        String plQuery;
        if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.P_L_STATEMENT_OBJECT,' January__c , February__c , March__c , April__c , '+
                                                                    'May__c , June__c , July__c , August__c , September__c , October__c , '+
                                                                    'November__c  , December__c,'+
                                                                    'January_Actual__c , February_Actual__c , March_Actual__c , April_Actual__c , '+
                                                                    'May_Actual__c , June_Actual__c , July_Actual__c , August_Acutal__c , September_Acutal__c , '+
                                                                    'October_Actual__c , December_Actual__c , '+
                                                                    'November_Actual__c, GL_Code__c,P_L_Category__c, Year_Total_Variance__c, Year_Total__c, Type__c,Year__c ,Year_Total_Actual__c,Type_Label__c',Constant.ACTION_TYPE_ACCESS)&&
           PlaceCPM_Utility.checkAccessiblityOfFields(Constant.GL_CODE_OBJECT,'GL_Code__c',Constant.ACTION_TYPE_ACCESS) &&
           PlaceCPM_Utility.checkAccessiblityOfFields(Constant.PL_CATEGORY_OBJECT,'type__c',Constant.ACTION_TYPE_ACCESS)
          ){
            plQuery = 'SELECT id , Year__c , January__c , February__c , March__c , April__c , '+
                                                                    'May__c , June__c , July__c , August__c , September__c , October__c , '+
                                                                    'November__c , December__c , GL_Code__c , GL_Code__r.PL_Category__c , '+
                                                                    'GL_Code__r.PL_Category__r.Name,GL_Code__r.name , P_L_Category__r.Name , '+
                                                                    'Type_Label__c , Year_Total__c , Type__c , GL_Code__r.GL_Code__c , '+ 
                                                                    'January_Actual__c , February_Actual__c , March_Actual__c , April_Actual__c , '+
                                                                    'May_Actual__c , June_Actual__c , July_Actual__c , August_Acutal__c , September_Acutal__c , '+
                                                                    'October_Actual__c , November_Actual__c , December_Actual__c , Year_Total_Actual__c , Year_Total_Variance__c ,'+
                                                                    'P_L_Category__c , P_L_Category__r.type__c '+
                                                                    'FROM P_L_Statement__c';
    	}
        plQuery += ' WHERE Year__c In : yearsTobeFetched and type__c != null and Statement_Type__c = null';
        plQuery += ' ORDER BY Sequence__c ,GL_Code__c , Type_Label__c , Year__c';
        List<P_L_Statement__c> plsList = Database.query(plQuery);
        PlWrapper wr;
        String plSectionCurrent;
        String plSectionPrev;
        Integer i=0;
        mainWrapper = new MainWrapper();
        For(i=0 ; i< plsList.size() ; i++){
            if(i==0 || plsList[i].GL_Code__c != plsList[i-1].GL_Code__c || (plsList[i].Type_Label__c != null && plsList[i].Type_Label__c != plsList[i-1].Type_Label__c)){
                wr = new PlWrapper();
                plSectionCurrent = (plsList[i].Type__c == CONSTANT.PL_STATEMENT_TYPE_CATEGORY) ? plsList[i].P_L_Category__r.Name : plsList[i].Type_Label__c;
                plSectionPrev = i >= 1 ? ((plsList[i].Type__c == CONSTANT.PL_STATEMENT_TYPE_CATEGORY) ? plsList[i-1].P_L_Category__r.Name : plsList[i-1].Type_Label__c) : plSectionCurrent;
                if(i == 0){
                    if(plsList[i].Type__c == CONSTANT.PL_STATEMENT_TYPE_CATEGORY){
                        wr.showHeader = true;
                        wr.HeaderTitle = plSectionCurrent;
                        wr.sameRowDisplay = false;
                    }else{
                        wr.showHeader = true;
                        wr.HeaderTitle = plSectionCurrent;
                        wr.sameRowDisplay = true;
                    }
                }else{
                    if( plSectionCurrent == plSectionPrev){
                        wr.showHeader = false;
                    }else{
                        wr.showHeader = true;
                        if(plsList[i].Type__c == CONSTANT.PL_STATEMENT_TYPE_CATEGORY){
                            wr.HeaderTitle = plsList[i].P_L_Category__r.Name;
                            wr.sameRowDisplay = false;
                        }else{
                           wr.HeaderTitle = plsList[i].Type_Label__c;
                           wr.sameRowDisplay = true;
                        }
                    }
                }
                wr.pls = new SummaryWrapper(plsList[i]);
                temp = wr.pls;
                mainWrapper.plsWrapper.add(wr);
            }
            else{
                mergeSummaryWrapper(plsList[i] , temp); 
            }
        }
        TableHeader th;
        Integer j=0;
        for(Integer years : dateRanges.keySet()){
            if(j == 0){
                mainWrapper.startYear = years;
            }
            if(j == dateRanges.size() - 1){
                mainWrapper.endYear = years;
            }
            j++;
            String yearShortValue = String.valueOf(years).substring(2);
            if(timeFrame == Label.YEAR){
                th = new TableHeader();
                th.header = String.valueOf(years);
                tableHeaderList.add(th);
                monthAndYearList.add(1+':'+years);
                monthAndYearList.add(2+':'+years);
                monthAndYearList.add(3+':'+years);
                monthAndYearList.add(4+':'+years);
                monthAndYearList.add(5+':'+years);
                monthAndYearList.add(6+':'+years);
                monthAndYearList.add(7+':'+years);
                monthAndYearList.add(8+':'+years);
                monthAndYearList.add(9+':'+years);
                monthAndYearList.add(10+':'+years);
                monthAndYearList.add(11+':'+years);
                monthAndYearList.add(12+':'+years);
            }
            else{
              for(Integer months : dateRanges.get(years)){
                th = new TableHeader();
                if(timeFrame == Label.MONTH || timeFrame == null){
                    switch on months{
                        when 1 {
                            th.header = 'Jan ';
                        }      
                        when 2 {
                            th.header = 'Feb ';
                        }
                        when 3 {
                            th.header = 'Mar ';
                        }
                        when 4 {
                            th.header = 'Apr ';
                        }
                        when 5 {
                            th.header = 'May ';
                        }
                        when 6 {
                            th.header = 'Jun ';
                        }
                        when 7 {
                            th.header = 'Jul ';
                        }
                        when 8 {
                            th.header = 'Aug ';
                        }
                        when 9 {
                            th.header = 'Sep ';
                        }
                        when 10 {
                            th.header = 'Oct ';
                        }
                        when 11 {
                            th.header = 'Nov ';
                        }
                        when else {
                            th.header = 'Dec ';
                        }
                    }
                th.header += yearShortValue;
                tableHeaderList.add(th);
                monthAndYearList.add(months+':'+years);
                }
                else if(timeFrame == Label.QUARTER){
                    switch on months{
                        when 1 {
                            th.header = CONSTANT.Q1+' ';
                            monthAndYearList.add(1+':'+years);
                            monthAndYearList.add(2+':'+years);
                            monthAndYearList.add(3+':'+years);
                        }   
                        when 2 {
                            th.header = CONSTANT.Q2+' ';
                            monthAndYearList.add(4+':'+years);
                            monthAndYearList.add(5+':'+years);
                            monthAndYearList.add(6+':'+years);
                        }
                        when 3 {
                            th.header = CONSTANT.Q3+' ';
                            monthAndYearList.add(7+':'+years);
                            monthAndYearList.add(8+':'+years);
                            monthAndYearList.add(9+':'+years);
                        }
                        when 4 {
                            th.header = CONSTANT.Q4+' ';
                            monthAndYearList.add(10+':'+years);
                            monthAndYearList.add(11+':'+years);
                            monthAndYearList.add(12+':'+years);
                        }
                    }
                    th.header += years;
                    tableHeaderList.add(th);
                }
                }  
            }
        }
        mainWrapper.tableHeader = tableHeaderList;
        mainWrapper.monthAndYearList = monthAndYearList;
        mainWrapper.dateRange = dateRanges;
        mainWrapper.yearsTobeFetched = yearsTobeFetched;
        //calculateTotal(mainWrapper.plsWrapper);
        calculateDefaultValue(view != null ? view : Label.Acutal_Forecast_UTD, mainWrapper.plsWrapper);
        return mainWrapper;
    }
    
    //  Method to fetch PL Statement records.
    //  @param year is the selected year on PAndL component
    //  @return MainWrapper
    @AuraEnabled
    public static MainWrapper getPLStatementWithFilterAndExpansion(String view , String timeFrame , Map<Integer , List<Integer>> dateRangesAttr , List<String> monthAndYearListAttr , List<Integer> expandedRowsList , List<String> yearListAttr) {
        dateRanges = dateRangesAttr;
        monthAndYearList = monthAndYearListAttr;
        yearsTobeFetched = yearListAttr;
        MainWrapper mainWrap = getPLStatement(view , timeFrame , null);
        expandedRowsList.sort();
        Integer index;
        Integer childRecords = 0;
        For(Integer i=0 ; i<expandedRowsList.size() ; i++){
            index = expandedRowsList[i];
            index += childRecords;
            List<PlWrapper> tempList = addPL(mainWrap.plsWrapper[index].pls.glCode , null , mainWrap.plsWrapper[index].wrapId , mainWrap.dateRange , mainWrap.monthAndYearList , null);
            for(PlWrapper pls : tempList){
                mainWrap.plsWrapper.add(++index , pls);
                childRecords++;
            }
        }
        return mainWrap;
    }
    
    @AuraEnabled
    public static MainWrapper applyFiltersPL(Integer startMonth , Integer endMonth , Integer startYear , Integer endYear , String timeFrame , String view){ 
        Integer startMonthtemp;
        Integer endMonthtemp;
        dateRanges.clear();
        yearsTobeFetched.clear();
        for(Integer i=startYear ;  i<=endYear ; i++){
            if(i == startYear && i != endYear){
                startMonthtemp = startMonth;
                if(timeFrame == Label.MONTH || timeFrame == null)
                endMonthtemp = 12;
                else if(timeFrame == Label.QUARTER)
                endMonthtemp = 4;
                else if(timeFrame == Label.YEAR){
                   startMonthtemp = 1;
                   endMonthtemp = 12;
                }
            }
            else if(i == startYear && i == endYear){
                if(timeFrame == Label.MONTH || timeFrame == Label.QUARTER){
                    startMonthtemp = startMonth;
                    endMonthtemp = endMonth;
                }
                else{
                    startMonthtemp = 1;
                    endMonthtemp = 12;
                }
            }
            else if(i == endYear){
                if(timeFrame == Label.MONTH || timeFrame == Label.QUARTER){
                    startMonthtemp = 1;
                    endMonthtemp = endMonth;
                }
                else{
                    startMonthtemp = 1;
                    endMonthtemp = 12;
                }
            }
            else{
                startMonthtemp = 1;
                if(timeFrame == Label.MONTH)
                endMonthtemp = 12;
                else if(timeFrame == Label.QUARTER)
                endMonthtemp = 4;
                else
                endMonthtemp = 12;
            }
            yearsTobeFetched.add(String.valueOf(i));
            For(Integer j = startMonthtemp ; j<=endMonthtemp ; j++){
                if(!dateRanges.containsKey(i)){
                    dateRanges.put(i , new List<Integer>());
                }
                dateRanges.get(i).add(j);
            }
        }
        return getPLStatement(view , timeFrame , null);
    }
    
    @AuraEnabled
    public static MainWrapper applyTimeFrame(String timeFrame , String view , String dateRangesAttr){ 
        if(dateRangesAttr == null){
            if(timeFrame == Label.MONTH){
                List<Integer> templList = new List<Integer>();
                templList.add(1);
                templList.add(2);
                templList.add(3);
                templList.add(4);
                templList.add(5);
                templList.add(6);
                templList.add(7);
                templList.add(8);
                templList.add(9);
                templList.add(10);
                templList.add(11);
                templList.add(12);
                dateRanges.put(System.today().year() , templList);
                yearsTobeFetched.add(String.valueOf(System.today().year()));
                return getPLStatement(view , timeFrame , null);
            }
            else if(timeFrame == Label.QUARTER){
                List<Integer> templList = new List<Integer>();
                templList.add(1);
                templList.add(2);
                templList.add(3);
                templList.add(4);
                dateRanges.put(System.today().year() , templList);
                yearsTobeFetched.add(String.valueOf(System.today().year()));
                return getPLStatement(view , timeFrame , null);
            }   
            else if(timeFrame == Label.YEAR){
                List<Integer> templList = new List<Integer>();
                templList.add(1);
                templList.add(2);
                templList.add(3);
                templList.add(4);
                templList.add(5);
                templList.add(6);
                templList.add(7);
                templList.add(8);
                templList.add(9);
                templList.add(10);
                templList.add(11);
                templList.add(12);
                dateRanges.put(System.today().year() , templList);
                yearsTobeFetched.add(String.valueOf(System.today().year()));
                return getPLStatement(view , timeFrame , null);
            }
        }
        else{
            return getPLStatement(view , timeFrame , dateRangesAttr);
        }
        return null;
    }

    @AuraEnabled
    public static List<PlWrapper> changeview(String view , String plsWrapperList){
        List<PlWrapper> plsWrapList = (List<PlWrapper>)JSON.deserialize(plsWrapperList, List<PlWrapper>.class);
        return calculateDefaultValue(view , plsWrapList);
    }
    
    //  Method to child rows to related gl account called from pandl component
    //  @param glCode and year
    //  @return PlWrapper list
    @AuraEnabled
    public static List<PlWrapper> addPL(String glCode , String view , Integer parentIndex , Map<Integer , List<Integer>> dateRangesAttr , List<String> monthAndYearListAttr , String timeFrame){
        dateRanges = dateRangesAttr;
        monthAndYearList = monthAndYearListAttr;
        PlWrapper plwrapper;
        Map<String , PlWrapper> mapOfRevenueAccountsAndPl = new Map<String , PlWrapper>();
        List<PlWrapper> sortedAccountAndPlWrapper = new List<PlWrapper>();
        Map<String , List<Decimal>> sobjs = new Map<String , List<Decimal>>();
        String mapUniqueKey;
        ActualForceastWrap afw;
        SummaryWrapper smw;
        String monthAndYear;
        String pltype;
        List<Decimal> tempList;
        List<String> keys = new  List<String>();
        For(Expense_PL_Allocation__c expl : [SELECT Id ,GL_Code__r.PL_Category__r.Type__c ,  Wage__c , Wage__r.Employee_Name__c , Wage__r.Employee_Number__c , Wage__r.Employee_Number__r.Name , Expense_Account__r.Vendor__c ,  Expense_Account__r.name , Expense_Account__r.Vendor__r.name , Forecast_Amount__c , Actual_Amount__c , P_L__r.Period_Start_Date__c , MonthAndYear__c FROM Expense_PL_Allocation__c where GL_Code__c =: glCode and MonthAndYear__c In : monthAndYearList]){
            mapUniqueKey = expl.Expense_Account__r != null ? expl.Expense_Account__r.name : expl.Wage__r.Employee_Number__c;
            if(sobjs.containsKey(expl.MonthAndYear__c + mapUniqueKey)){
                tempList = sobjs.get(expl.MonthAndYear__c + mapUniqueKey);
                if(expl.Actual_Amount__c != null){
                	tempList[0] = tempList[0] != null ? tempList[0] +  expl.Actual_Amount__c : 0.0 + expl.Actual_Amount__c;
                }
                if(expl.Forecast_Amount__c != null){
                    tempList[1] = tempList[1] != null ? tempList[1] + expl.Forecast_Amount__c : 0.0 + expl.Forecast_Amount__c;
                }
                sobjs.put(expl.MonthAndYear__c + mapUniqueKey , tempList);
            }
            else{
                sobjs.put(expl.MonthAndYear__c + mapUniqueKey , new List<Decimal>{expl.Actual_Amount__c != null ? expl.Actual_Amount__c : 0.0 , expl.Forecast_Amount__c != null ? expl.Forecast_Amount__c : 0.0});
            }
            mapUniqueKey = expl.Expense_Account__r != null ? expl.Expense_Account__r.name : expl.Wage__r.Employee_Number__c;
            if(!mapOfRevenueAccountsAndPl.containsKey(mapUniqueKey)){
                plwrapper = new PlWrapper();
                plwrapper.pls = new SummaryWrapper();
                mapOfRevenueAccountsAndPl.put(mapUniqueKey , plwrapper);
                keys.add(mapUniqueKey);
                if(expl.Expense_Account__c != null){
                    plwrapper.HeaderTitle = expl.Expense_Account__r.name;
                    plwrapper.accountId = expl.Expense_Account__c;
                }
                else if(expl.Wage__c != null){
                    plwrapper.HeaderTitle = expl.Wage__r.Employee_Number__r.Name;
                    plwrapper.accountId = expl.Wage__r.Employee_Number__c;
                }
                plwrapper.sameRowDisplay = true;
                plwrapper.isChild = true;
                plwrapper.pls.glCodeType = CONSTANT.PL_CATEGORY_EXPENSE;
            }
            pltype = CONSTANT.PL_CATEGORY_EXPENSE;
        }
        For(Revenue_P_L_Allocation__c rvpl : [Select id ,GL_Code__r.PL_Category__r.Type__c , Revenue_Account__r.Account__c , Revenue_Account__r.name , Revenue_Account__r.Account__r.name , Forecast_Amount__c , Actual_Amount__c , P_L__r.Period_Start_Date__c , MonthAndYear__c FROM Revenue_P_L_Allocation__c where GL_Code__c =: glCode and MonthAndYear__c In : monthAndYearList]){
            mapUniqueKey = rvpl.Revenue_Account__r.name;
            if(sobjs.containsKey(rvpl.MonthAndYear__c + mapUniqueKey)){
                tempList = sobjs.get(rvpl.MonthAndYear__c + mapUniqueKey);
                if(rvpl.Actual_Amount__c != null){
                    tempList[0] = tempList[0] + rvpl.Actual_Amount__c;
                }
                if(rvpl.Forecast_Amount__c != null){
                	tempList[1] = tempList[1] + rvpl.Forecast_Amount__c;
                }
                sobjs.put(rvpl.MonthAndYear__c + mapUniqueKey , tempList);
            }
            else{
                sobjs.put(rvpl.MonthAndYear__c + mapUniqueKey , new List<Decimal>{rvpl.Actual_Amount__c != null ? rvpl.Actual_Amount__c : 0 , rvpl.Forecast_Amount__c != null ? rvpl.Forecast_Amount__c : 0});
            }
            if(!mapOfRevenueAccountsAndPl.containsKey(mapUniqueKey)){
                plwrapper = new PlWrapper();
                plwrapper.pls = new SummaryWrapper();
                mapOfRevenueAccountsAndPl.put(mapUniqueKey , plwrapper);
                keys.add(mapUniqueKey);
                plwrapper.HeaderTitle = rvpl.Revenue_Account__r.Account__c != null ? rvpl.Revenue_Account__r.Account__r.name : rvpl.Revenue_Account__r.name;
                plwrapper.accountId = rvpl.Revenue_Account__c;
                plwrapper.sameRowDisplay = true;
                plwrapper.isChild = true;
                plwrapper.pls.glCodeType = CONSTANT.PL_CATEGORY_REVENUE;
            }
            pltype = CONSTANT.PL_CATEGORY_REVENUE;
        }
        Decimal actualAmountTemp = 0.0;
        Decimal forecastAmountTemp = 0.0;
        String tempKey;
        for(String mapUniqueKeys : mapOfRevenueAccountsAndPl.keySet()){
            plwrapper = mapOfRevenueAccountsAndPl.get(mapUniqueKeys);
            for(Integer plyear : dateRanges.keySet()){
                for(Integer plmonth : dateRanges.get(plyear)){
                    if(timeFrame == Label.MONTH || timeFrame == null){
                        smw = plwrapper.pls;
                        smw.glcode = glCode;
                        smw.parentIndex = parentIndex;
                        afw = new ActualForceastWrap();
                        monthAndYear = plmonth + ':' + plyear;
                        afw.actual = sobjs.containsKey(monthAndYear + mapUniqueKeys) ? sobjs.get(monthAndYear + mapUniqueKeys)[0] : 0.0;
                        afw.forecast = sobjs.containsKey(monthAndYear + mapUniqueKeys) ? sobjs.get(monthAndYear + mapUniqueKeys)[1] : 0.0;
                        afw.variance = pltype == CONSTANT.PL_CATEGORY_REVENUE ?  afw.actual - afw.forecast : afw.forecast - afw.actual;
                        afw.month = plmonth;
                        afw.year = plyear;
                        smw.valuesList.add(afw);
                    }
                    if(timeFrame == Label.QUARTER){
                        smw = plwrapper.pls;
                        smw.glcode = glCode; 
                        smw.parentIndex = parentIndex;
                        afw = new ActualForceastWrap();
                        actualAmountTemp = 0.0;
                        forecastAmountTemp = 0.0;
                        if(sobjs.containsKey(tempKey = (3*plmonth - 2) + ':' + plyear +  mapUniqueKeys)){
                            actualAmountTemp += sobjs.get(tempKey)[0];
                            forecastAmountTemp += sobjs.get(tempKey)[1];
                        }
                        if(sobjs.containsKey(tempKey = (3*plmonth - 1) + ':' + plyear + mapUniqueKeys)){
                            actualAmountTemp += sobjs.get(tempKey)[0];
                            forecastAmountTemp += sobjs.get(tempKey)[1];
                        }
                        if(sobjs.containsKey(tempKey = (3*plmonth) + ':' + plyear + mapUniqueKeys)){
                            actualAmountTemp += sobjs.get(tempKey)[0];
                            forecastAmountTemp += sobjs.get(tempKey)[1];
                        }
                        afw.month = (3*plmonth);
                        afw.actual = actualAmountTemp;
                        afw.forecast = forecastAmountTemp;
                        afw.variance = pltype == CONSTANT.PL_CATEGORY_REVENUE ?  afw.actual - afw.forecast : afw.forecast - afw.actual;
                        afw.year = plyear;
                        smw.valuesList.add(afw);
                    }
                    if(timeFrame == Label.YEAR){
                        if(sobjs.containsKey(tempKey = plmonth + ':' + plyear + mapUniqueKeys)){
                            actualAmountTemp += sobjs.get(tempKey)[0];
                            forecastAmountTemp += sobjs.get(tempKey)[1];
                        }
                    }
                }
                if(timeFrame == Label.YEAR){
                    afw = new ActualForceastWrap();
                    smw = plwrapper.pls;
                    smw.glcode = glCode;
                    smw.parentIndex = parentIndex;
                    afw.actual = actualAmountTemp;
                    afw.forecast = forecastAmountTemp;
                    afw.variance = pltype == CONSTANT.PL_CATEGORY_REVENUE ?  afw.actual - afw.forecast : afw.forecast - afw.actual;
                    afw.year = plyear;
                    afw.month = 12;
                    actualAmountTemp = 0.0;
                    forecastAmountTemp = 0.0;
                    smw.valuesList.add(afw);
                }
            }
        }
        keys.sort();
        For(String key : keys){
            sortedAccountAndPlWrapper.add(mapOfRevenueAccountsAndPl.get(key));
        }
        calculateDefaultValue(view , mapOfRevenueAccountsAndPl.values());
        return sortedAccountAndPlWrapper;
    }
    
    //  Method to save PL allocation records.
    //  @param AccountId is the id of expense or revenue account.
    //  @param month is the month of pl allocation
    //  @param amount is actual amount to be updated.
    //  @param isActual 
    //  @param year is the selected year on PAndL component
    //  @return MainWrapper
    @AuraEnabled
    public static MainWrapper savePL(String AccountId , String month , String amount , Boolean isActual , String year , String glcode , Map<Integer , List<Integer>> dateRangesAttr , List<String> monthAndYearListAttr , List<Integer> expandedRowsList , List<String> yearListAttr , String view){
        dateRanges = dateRangesAttr;
        monthAndYearList = monthAndYearListAttr;
        yearsTobeFetched = yearListAttr;
        Id id = AccountId;
        String sObjName = id.getSObjectType().getDescribe().getName();
        Revenue_P_L_Allocation__c rpl;
        Expense_PL_Allocation__c epl;
        Boolean isUpdated = false;
        if(sObjName == PlaceCPM_Utility.getCustomObjOrFieldName(CONSTANT.revenueAccountObject)){
            Boolean isActualUpsert = false, isForecastUpsert = false;
            if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.REVENUE_PL_ALLOCATION_OBJECT,'Actual_Amount__c',Constant.ACTION_TYPE_UPDATE) && PlaceCPM_Utility.checkAccessiblityOfFields(Constant.REVENUE_PL_ALLOCATION_OBJECT,'Actual_Amount__c',Constant.ACTION_TYPE_INSERT)){
                isActualUpsert = true;
            }
            if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.REVENUE_PL_ALLOCATION_OBJECT,'Forecast_Amount__c',Constant.ACTION_TYPE_UPDATE) && PlaceCPM_Utility.checkAccessiblityOfFields(Constant.REVENUE_PL_ALLOCATION_OBJECT,'Forecast_Amount__c',Constant.ACTION_TYPE_INSERT)){
                isForecastUpsert = true;
            }
            if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.REVENUE_PL_ALLOCATION_OBJECT,'id , Actual_Amount__c , Forecast_Amount__c',Constant.ACTION_TYPE_ACCESS)){
                For(Revenue_P_L_Allocation__c rvpl : [Select id , Actual_Amount__c , Forecast_Amount__c from Revenue_P_L_Allocation__c where Revenue_Account__c =: AccountId
                                                      and PL_Month__c =: Integer.valueOf(month) and GL_Code__c =:glcode and PL_Year__c =: Decimal.valueOf(year) limit 1]){
                    if(isActual && isActualUpsert){
                        rvpl.Actual_Amount__c = Decimal.valueOf(amount);
                    }
                    else{
                        if(isForecastUpsert){
                            rvpl.Forecast_Amount__c = Decimal.valueOf(amount);
                        }
                    }
                    rpl = rvpl;
                }
        	}
        }
        else if(sObjName == PlaceCPM_Utility.getCustomObjOrFieldName(CONSTANT.expenseAccountObject)){
            Boolean isActualUpsert = false, isForecastUpsert = false;
            if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.EXPENSE_PL_ALLOCATION_OBJECT,'Actual_Amount__c',Constant.ACTION_TYPE_UPDATE) && PlaceCPM_Utility.checkAccessiblityOfFields(Constant.REVENUE_PL_ALLOCATION_OBJECT,'Actual_Amount__c',Constant.ACTION_TYPE_INSERT)){
                isActualUpsert = true;
            }
            if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.EXPENSE_PL_ALLOCATION_OBJECT,'Forecast_Amount__c',Constant.ACTION_TYPE_UPDATE) && PlaceCPM_Utility.checkAccessiblityOfFields(Constant.REVENUE_PL_ALLOCATION_OBJECT,'Forecast_Amount__c',Constant.ACTION_TYPE_INSERT)){
                isForecastUpsert = true;
            } 
            if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.EXPENSE_PL_ALLOCATION_OBJECT,'id , Actual_Amount__c , Forecast_Amount__c',Constant.ACTION_TYPE_ACCESS)){
                 For(Expense_PL_Allocation__c expl : [Select id , Actual_Amount__c , Forecast_Amount__c from Expense_PL_Allocation__c where Expense_Account__c =: AccountId
                                                        and PL_Month__c =: Integer.valueOf(month) and GL_Code__c =:glcode and PL_Year__c =: Decimal.valueOf(year) limit 1]){
                    if(isActual && isActualUpsert){
                        expl.Actual_Amount__c = Decimal.valueOf(amount);
                    }
                    else{
                        if(isForecastUpsert){
                            expl.Forecast_Amount__c = Decimal.valueOf(amount);
                        }
                    }
                    epl = expl;
                }
        	}
        }
        else if(sObjName == PlaceCPM_Utility.getCustomObjOrFieldName(CONSTANT.EMPLOYEE_OBJECT)){
            Boolean isActualUpsert = false, isForecastUpsert = false;
            if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.EXPENSE_PL_ALLOCATION_OBJECT,'Actual_Amount__c',Constant.ACTION_TYPE_UPDATE) && PlaceCPM_Utility.checkAccessiblityOfFields(Constant.REVENUE_PL_ALLOCATION_OBJECT,'Actual_Amount__c',Constant.ACTION_TYPE_INSERT)){
                isActualUpsert = true;
            }
            if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.EXPENSE_PL_ALLOCATION_OBJECT,'Forecast_Amount__c',Constant.ACTION_TYPE_UPDATE) && PlaceCPM_Utility.checkAccessiblityOfFields(Constant.REVENUE_PL_ALLOCATION_OBJECT,'Forecast_Amount__c',Constant.ACTION_TYPE_INSERT)){
                isForecastUpsert = true;
            } 
            if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.EXPENSE_PL_ALLOCATION_OBJECT,'id , Actual_Amount__c , Forecast_Amount__c',Constant.ACTION_TYPE_ACCESS)){
                 For(Expense_PL_Allocation__c expl : [Select id , Actual_Amount__c , Forecast_Amount__c from Expense_PL_Allocation__c where Wage__r.Employee_Number__c =: AccountId
                                                        and PL_Month__c =: Integer.valueOf(month) and GL_Code__c =:glcode and PL_Year__c =: Decimal.valueOf(year) limit 1]){
                    if(isActual && isActualUpsert){
                        expl.Actual_Amount__c = Decimal.valueOf(amount);
                    }
                    else{
                        if(isForecastUpsert){
                            expl.Forecast_Amount__c = Decimal.valueOf(amount);
                        }
                    }
                    epl = expl;
                }
        	}
        }
        Database.UpsertResult saveResult;        

            if(rpl != null && Schema.sObjectType.Revenue_P_L_Allocation__c.isCreateable() && Schema.sObjectType.Revenue_P_L_Allocation__c.isUpdateable())
            saveResult = Database.upsert(rpl, false);
            
            if(epl != null && Schema.sObjectType.Expense_PL_Allocation__c.isCreateable() && Schema.sObjectType.Expense_PL_Allocation__c.isUpdateable())
            saveResult = Database.upsert(epl , false);
            
            if(saveResult != null && saveResult.isSuccess()){
                MainWrapper mainWrap = getPLStatement(view , Label.MONTH , null);
                expandedRowsList.sort();
                Integer index;
                Integer childRecords = 0;
                For(Integer i=0 ; i<expandedRowsList.size() ; i++){
                    index = expandedRowsList[i];
                    index += childRecords;
                    List<PlWrapper> tempList = addPL(mainWrap.plsWrapper[index].pls.glCode , view , mainWrap.plsWrapper[index].wrapId , mainWrap.dateRange , mainWrap.monthAndYearList , Label.MONTH);
                    for(PlWrapper pls : tempList){
                        mainWrap.plsWrapper.add(++index , pls);
                        childRecords++;
                    }
                }
                return mainWrap;
            }
            else
                return null;
    }
    
    @AuraEnabled
    public static MainWrapper saveAllocation(Map<Integer , List<Integer>> dateRangesAttr , List<String> monthAndYearListAttr , List<Integer> expandedRowsList , List<String> yearListAttr){
        dateRanges = dateRangesAttr;
        monthAndYearList = monthAndYearListAttr;
        yearsTobeFetched = yearListAttr;
        MainWrapper mainWrap = getPLStatement(Label.MONTH , null , null);
        expandedRowsList.sort();
        Integer index;
        Integer childRecords = 0;
        For(Integer i=0 ; i<expandedRowsList.size() ; i++){
            index = expandedRowsList[i];
            index += childRecords;
            List<PlWrapper> tempList = addPL(mainWrap.plsWrapper[index].pls.glCode , null , mainWrap.plsWrapper[index].wrapId , mainWrap.dateRange , mainWrap.monthAndYearList , null);
            for(PlWrapper pls : tempList){
                mainWrap.plsWrapper.add(++index , pls);
                childRecords++;
            }
        }
        system.debug('mainWrap'+mainWrap);
        return mainWrap;
    }
    //  Method to changeview
    //  @param view and plsWrapperList
    //  @return PlWrapper
    public static List<PlWrapper> calculateDefaultValue(String view , List<PlWrapper> plsWrapList){
        Integer currentYear = System.today().year();
        For(PlWrapper plsw : plsWrapList){
            For(ActualForceastWrap afw : plsw.pls.valuesList){
                if(view == Label.Acutal_Forecast_UTD || view == null){
                    afw.defaultValue = afw.year < currentYear || (currentMonth > afw.month  && afw.year == currentYear) ?  afw.actual : afw.forecast;
                }
                else if(view == Label.Only_Actual){
                    afw.defaultValue = afw.actual;
                }
                else if(view == Label.Only_Forecast){
                    afw.defaultValue = afw.forecast;
                }
                else if(view == Label.PLTabVariance){
                    afw.defaultValue = afw.variance;
                }
            }
            /*
            plsw.pls.total.defaultValue = plsw.pls.jan.defaultValue + plsw.pls.feb.defaultValue + plsw.pls.mar.defaultValue  + plsw.pls.april.defaultValue + plsw.pls.may.defaultValue + plsw.pls.june.defaultValue + plsw.pls.july.defaultValue + plsw.pls.aug.defaultValue +
                                            plsw.pls.sept.defaultValue + plsw.pls.oct.defaultValue + plsw.pls.nov.defaultValue + plsw.pls.dec.defaultValue;
                                            */
        }
        return plsWrapList;
    }
    
    //  Method to fetch all years for PL Statement records.
    //  @return Set<String>
    public static Set<String> getAllYears(){
        Set<String> yearList = new Set<String>();
        Integer noOfYears = 0;
        if(PlaceCPM_Utility.assumptionForecastDuration > 0){
            Date dateAfterAssumptionDuration = System.today().addMonths(PlaceCPM_Utility.assumptionForecastDuration);
            noOfYears = dateAfterAssumptionDuration.year();
            if(noOfYears > 0){
                For(Integer i= System.today().year() - 1 ; i<=noOfYears ; i++)
                    yearList.add(String.valueOf(i));
            }
        }
        return yearList;
    }

    //  Method to calculate total values
    //  @param plsList PlWrapper wrapper list from which total has to be populated
    //  @return void
    /*
    static void calculateTotal(List<PlWrapper> plsList){
        For(PlWrapper plsWrap : plsList){
            plsWrap.pls.total.forecast = plsWrap.pls.jan.forecast + plsWrap.pls.feb.forecast + plsWrap.pls.mar.forecast + plsWrap.pls.april.forecast + plsWrap.pls.may.forecast + plsWrap.pls.june.forecast + plsWrap.pls.july.forecast + plsWrap.pls.aug.forecast +
                                        plsWrap.pls.sept.forecast + plsWrap.pls.oct.forecast + plsWrap.pls.nov.forecast + plsWrap.pls.dec.forecast;
            plsWrap.pls.total.actual = plsWrap.pls.jan.actual + plsWrap.pls.feb.actual + plsWrap.pls.mar.actual  + plsWrap.pls.april.actual + plsWrap.pls.may.actual + plsWrap.pls.june.actual + plsWrap.pls.july.actual + plsWrap.pls.aug.actual +
                                        plsWrap.pls.sept.actual + plsWrap.pls.oct.actual + plsWrap.pls.nov.actual + plsWrap.pls.dec.actual;
            plsWrap.pls.total.variance = plsWrap.pls.jan.variance + plsWrap.pls.feb.variance + plsWrap.pls.mar.variance  + plsWrap.pls.april.variance + plsWrap.pls.may.variance + plsWrap.pls.june.variance + plsWrap.pls.july.variance + plsWrap.pls.aug.variance +
                                        plsWrap.pls.sept.variance + plsWrap.pls.oct.variance + plsWrap.pls.nov.variance + plsWrap.pls.dec.variance;
        }
    }*/
    
    public class MainWrapper{
        @AuraEnabled  
        public List<String> years;
        @AuraEnabled
        public List<PlWrapper> plsWrapper;
        @AuraEnabled
        public List<TableHeader> tableHeader;
        @AuraEnabled
        public List<String> monthAndYearList;
        @AuraEnabled
        public Map<Integer , List<Integer>> dateRange;
        @AuraEnabled
        public Integer currentYear;
        @AuraEnabled
        public Integer startYear;
        @AuraEnabled
        public Integer endYear;
        @AuraEnabled
        public String startMonth;
        @AuraEnabled
        public String endMonth;
        @AuraEnabled  
        public List<String> yearsTobeFetched;
        MainWrapper(){
            plsWrapper = new List<PlWrapper>();
            tableHeader = tableHeaderList;
            years = new List<String>(getAllYears());
            currentYear = System.today().year();
        }
    }
    
    Public Class TableHeader{
        @AuraEnabled
        public String header;
        @AuraEnabled
        public Boolean expanded;
        TableHeader(){
            expanded = false;
        }
    }
    
    public Class PlWrapper{
        @AuraEnabled
        public Boolean coulmnExpand;
        @AuraEnabled
        public Id accountId;
        @AuraEnabled
        public boolean showHeader;
        @AuraEnabled
        public boolean sameRowDisplay;
        @AuraEnabled
        public String HeaderTitle;
        @AuraEnabled
        public SummaryWrapper pls;
        @AuraEnabled
        public String styleClass;
        @AuraEnabled
        public boolean isExpanded;
        @AuraEnabled
        public boolean isEdited;
        @AuraEnabled
        public boolean isChild;
        @AuraEnabled
        public List<Boolean> inLineEditActual = new List<Boolean>();
        @AuraEnabled
        public List<Boolean> inLineEditForecast = new List<Boolean>();
        @AuraEnabled
        public Decimal defaultTemp = 0.0;
        @AuraEnabled
        public Integer wrapId;
        @AuraEnabled
        public Integer childWrapId;
        @AuraEnabled
        public Integer parentWrapId;
        PlWrapper(){
            isExpanded = false;
            coulmnExpand = false;
            wrapId =  wrapIdStatic++;
        }
    }
    public static Map<Integer , List<Integer>> dateRanges = new Map<Integer , List<Integer>>();
    public static List<String> monthAndYearList = new List<String>();
    public static List<String> yearsTobeFetched = new List<String>();
    static List<TableHeader> tableHeaderList = new List<TableHeader>();
    static{
        List<Integer> templList = new List<Integer>();
        templList.add(1);
        templList.add(2);
        templList.add(3);
        templList.add(4);
        templList.add(5);
        templList.add(6);
        templList.add(7);
        templList.add(8);
        templList.add(9);
        templList.add(10);
        templList.add(11);
        templList.add(12);
        dateRanges.put(System.today().year() , templList);
        yearsTobeFetched.add(String.valueOf(System.today().year()));
    }
    
    public static Integer wrapIdStatic = 0;
    public class SummaryWrapper{
        @AuraEnabled
        public List<ActualForceastWrap> valuesList = new List<ActualForceastWrap>();
        @AuraEnabled
        public ActualForceastWrap total;
        @AuraEnabled
        public String glcodeAndName; 
        @AuraEnabled
        public String glcode;
        @AuraEnabled
        public String glCodeType;
        @AuraEnabled
        public Integer parentIndex;
        @AuraEnabled
        public Integer noOfChildRecords;
        @AuraEnabled
        public String type;
        @AuraEnabled
        public Integer year;
        SummaryWrapper(){
            ActualForceastWrap();
        }
        SummaryWrapper(P_L_Statement__c pls){
            ActualForceastWrap();
            if(pls != null)
            initForecastAndActual(pls);
        }
        void ActualForceastWrap(){
        }
        void initForecastAndActual(P_L_Statement__c pls){
            Integer year = Integer.valueOf(pls.Year__c);
            if(dateRanges.keySet().contains(year)){
                ActualForceastWrap afw;
                For(Integer month : dateRanges.get(Integer.valueOf(pls.Year__c))){
                    afw = new ActualForceastWrap();
                    if(timeFrameGlobal == Label.MONTH || timeFrameGlobal == null){
                        switch on month{
                        when 1 {
                            afw.actual = pls.January_Actual__c;
                            afw.forecast = pls.January__c;
                            afw.month = 1;
                        }   
                        when 2 {
                            afw.actual = pls.February_Actual__c;
                            afw.forecast = pls.February__c;
                            afw.month = 2;
                        }
                        when 3 {
                            afw.actual = pls.March_Actual__c;
                            afw.forecast = pls.March__c;
                            afw.month = 3;
                        }
                        when 4 {
                            afw.actual = pls.April_Actual__c;
                            afw.forecast = pls.April__c;
                            afw.month = 4;
                        }
                        when 5 {
                            afw.actual = pls.May_Actual__c;
                            afw.forecast = pls.May__c;
                            afw.month = 5;
                        }
                        when 6 {
                            afw.actual = pls.June_Actual__c;
                            afw.forecast = pls.June__c;
                            afw.month = 6;
                        }
                        when 7 {
                            afw.actual = pls.July_Actual__c;
                            afw.forecast = pls.July__c;
                            afw.month = 7;
                        }
                        when 8 {
                            afw.actual = pls.August_Acutal__c;
                            afw.forecast = pls.August__c;
                            afw.month = 8;
                        }
                        when 9 {
                            afw.actual = pls.September_Acutal__c;
                            afw.forecast = pls.September__c;
                            afw.month = 9;
                        }
                        when 10 {
                            afw.actual = pls.October_Actual__c;
                            afw.forecast = pls.October__c;
                            afw.month = 10;
                        }
                        when 11 {
                            afw.actual = pls.November_Actual__c;
                            afw.forecast = pls.November__c;
                            afw.month = 11;
                        }
                        when else {
                            afw.actual = pls.December_Actual__c;
                            afw.forecast = pls.December__c;
                            afw.month = 12;
                        }
                    }   
                        afw.variance = pls.P_L_Category__r.type__c == CONSTANT.PL_CATEGORY_REVENUE || pls.Type_Label__c == CONSTANT.NET_INCOME ?  afw.actual - afw.forecast : afw.forecast - afw.actual;
                        afw.year = year;
                        valuesList.add(afw);
                    }
                    else if(timeFrameGlobal == Label.QUARTER){
                        switch on month{
                            when 1 {
                                afw.actual = pls.January_Actual__c + pls.February_Actual__c + pls.March_Actual__c;
                                afw.forecast = pls.January__c + pls.February__c + pls.March__c;
                                afw.month = 3;
                            }   
                            when 2 {
                                afw.actual = pls.April_Actual__c + pls.May_Actual__c + pls.June_Actual__c;
                                afw.forecast = pls.April__c + pls.May__c + pls.June__c;
                                afw.month = 6;
                            }
                            when 3 {
                                afw.actual = pls.July_Actual__c + pls.August_Acutal__c + pls.September_Acutal__c;
                                afw.forecast = pls.July__c + pls.August__c + pls.September__c;
                                afw.month = 9;
                            }
                            when 4 {
                                afw.actual = pls.October_Actual__c + pls.November_Actual__c + pls.December_Actual__c;
                                afw.forecast = pls.October__c + pls.November__c + pls.December__c;
                                afw.month = 12;
                            }
                        }
                        afw.variance = pls.P_L_Category__r.type__c == CONSTANT.PL_CATEGORY_REVENUE || pls.Type_Label__c == CONSTANT.NET_INCOME ?  afw.actual - afw.forecast : afw.forecast - afw.actual;
                        afw.year = year;
                        valuesList.add(afw);
                    }
                    else if(timeFrameGlobal == Label.YEAR){
                        afw.actual = pls.January_Actual__c + pls.February_Actual__c + pls.March_Actual__c + pls.April_Actual__c + pls.May_Actual__c + pls.June_Actual__c+
                                     pls.July_Actual__c + pls.August_Acutal__c + pls.September_Acutal__c + pls.October_Actual__c + pls.November_Actual__c + pls.December_Actual__c;
                        afw.forecast = pls.January__c + pls.February__c + pls.March__c + pls.April__c + pls.May__c + pls.June__c + pls.July__c + pls.August__c + pls.September__c +
                                       pls.October__c + pls.November__c + pls.December__c;
                        afw.variance = pls.P_L_Category__r.type__c == CONSTANT.PL_CATEGORY_REVENUE || pls.Type_Label__c == CONSTANT.NET_INCOME ?  afw.actual - afw.forecast : afw.forecast - afw.actual;
                        afw.month = 12;
                        afw.year = year;
                    }
                }
                if(timeFrameGlobal == Label.YEAR)
                    valuesList.add(afw);
                this.glcodeAndName = pls.GL_Code__r.GL_Code__c + ' ' + pls.GL_Code__r.Name;
                this.glcode = pls.GL_Code__c;
                this.glCodeType = pls.P_L_Category__r.type__c;
                this.year = Integer.valueOf(pls.year__c);
                this.type = pls.Type_Label__c;
            }
        }
     }
    
    public static void mergeSummaryWrapper(P_L_Statement__c pls , SummaryWrapper smw){
        Integer year = Integer.valueOf(pls.Year__c);
        if(dateRanges.keySet().contains(year)){
            ActualForceastWrap afw;
            For(Integer month : dateRanges.get(Integer.valueOf(pls.Year__c))){
                afw = new ActualForceastWrap();
                if(timeFrameGlobal == Label.MONTH || timeFrameGlobal == null){
                    switch on month{
                    when 1 {
                        afw.actual = pls.January_Actual__c;
                        afw.forecast = pls.January__c;
                        afw.month = 1;
                    }   
                    when 2 {
                        afw.actual = pls.February_Actual__c;
                        afw.forecast = pls.February__c;
                        afw.month = 2;
                    }
                    when 3 {
                        afw.actual = pls.March_Actual__c;
                        afw.forecast = pls.March__c;
                        afw.month = 3;
                    }
                    when 4 {
                        afw.actual = pls.April_Actual__c;
                        afw.forecast = pls.April__c;
                        afw.month = 4;
                    }
                    when 5 {
                        afw.actual = pls.May_Actual__c;
                        afw.forecast = pls.May__c;
                        afw.month = 5;
                    }
                    when 6 {
                        afw.actual = pls.June_Actual__c;
                        afw.forecast = pls.June__c;
                        afw.month = 6;
                    }
                    when 7 {
                        afw.actual = pls.July_Actual__c;
                        afw.forecast = pls.July__c;
                        afw.month = 7;
                    }
                    when 8 {
                        afw.actual = pls.August_Acutal__c;
                        afw.forecast = pls.August__c;
                        afw.month = 8;
                    }
                    when 9 {
                        afw.actual = pls.September_Acutal__c;
                        afw.forecast = pls.September__c;
                        afw.month = 9;
                    }
                    when 10 {
                        afw.actual = pls.October_Actual__c;
                        afw.forecast = pls.October__c;
                        afw.month = 10;
                    }
                    when 11 {
                        afw.actual = pls.November_Actual__c;
                        afw.forecast = pls.November__c;
                        afw.month = 11;
                    }
                    when else {
                        afw.actual = pls.December_Actual__c;
                        afw.forecast = pls.December__c;
                        afw.month = 12;
                    }
                }   
                    afw.variance = pls.P_L_Category__r.type__c == CONSTANT.PL_CATEGORY_REVENUE || pls.Type_Label__c == CONSTANT.NET_INCOME ?  afw.actual - afw.forecast : afw.forecast - afw.actual;
                    afw.year = year;
                    smw.valuesList.add(afw);
                }
                else if(timeFrameGlobal == Label.QUARTER){
                    switch on month{
                        when 1 {
                            afw.actual = pls.January_Actual__c + pls.February_Actual__c + pls.March_Actual__c;
                            afw.forecast = pls.January__c + pls.February__c + pls.March__c;
                            afw.month = 3;
                        }   
                        when 2 {
                            afw.actual = pls.April_Actual__c + pls.May_Actual__c + pls.June_Actual__c;
                            afw.forecast = pls.April__c + pls.May__c + pls.June__c;
                            afw.month = 6;
                        }
                        when 3 {
                            afw.actual = pls.July_Actual__c + pls.August_Acutal__c + pls.September_Acutal__c;
                            afw.forecast = pls.July__c + pls.August__c + pls.September__c;
                            afw.month = 9;
                        }
                        when 4 {
                            afw.actual = pls.October_Actual__c + pls.November_Actual__c + pls.December_Actual__c;
                            afw.forecast = pls.October__c + pls.November__c + pls.December__c;
                            afw.month = 12;
                        }
                    }
                    afw.variance = pls.P_L_Category__r.type__c == CONSTANT.PL_CATEGORY_REVENUE || pls.Type_Label__c == CONSTANT.NET_INCOME ? afw.actual - afw.forecast : afw.forecast - afw.actual;
                    afw.year = year;
                    smw.valuesList.add(afw);
                }
                else if(timeFrameGlobal == Label.YEAR){
                    afw.actual = pls.January_Actual__c + pls.February_Actual__c + pls.March_Actual__c + pls.April_Actual__c + pls.May_Actual__c + pls.June_Actual__c+
                                 pls.July_Actual__c + pls.August_Acutal__c + pls.September_Acutal__c + pls.October_Actual__c + pls.November_Actual__c + pls.December_Actual__c;
                    afw.forecast = pls.January__c + pls.February__c + pls.March__c + pls.April__c + pls.May__c + pls.June__c + pls.July__c + pls.August__c + pls.September__c +
                                   pls.October__c + pls.November__c + pls.December__c;
                    afw.variance = pls.P_L_Category__r.type__c == CONSTANT.PL_CATEGORY_REVENUE || pls.Type_Label__c == CONSTANT.NET_INCOME ? afw.actual - afw.forecast : afw.forecast - afw.actual;
                    afw.month = 12;
                    afw.year = year;
                }
            }
            if(timeFrameGlobal == Label.YEAR)
                smw.valuesList.add(afw);
        }
    }

    public class ActualForceastWrap{
        @AuraEnabled
        public Decimal actual = 0.0;
        @AuraEnabled
        public Decimal actualold = 0.0;
        @AuraEnabled
        public Decimal forecast = 0.0;
        @AuraEnabled
        public Decimal forecastOld = 0.0;
        @AuraEnabled
        public Decimal defaultValue = 0.0;
        @AuraEnabled
        public Decimal variance = 0.0; 
        @AuraEnabled
        public Integer month = 0; 
        @AuraEnabled
        public Integer year = 0;
        @AuraEnabled
        public Boolean columnExpanded = false;
        @AuraEnabled
        public Boolean inlineEditActual = false;
        @AuraEnabled
        public Boolean inlineEditForecast = false;
        @AuraEnabled
        public Id plId;
    }
    
    @AuraEnabled
    //this method is used to get the data displayed on split screen
    //@param record id of the record clicked to open the split screen
    //return wrapper contains information of split screen
    public static splitWrapper getSplitScreenData(Id recordId){
        //563
        List<String> listOfRelatedList = new List<String>();
        splitWrapper sw = new splitWrapper();
        List<PLCashTabUtility.relatedListWrapper> rlwList = new List<PLCashTabUtility.relatedListWrapper>();
        List<LayoutSection> lsList = new List<LayoutSection>();
        String sobjectName = recordId.getSObjectType().getDescribe().getName();
        if(sobjectName !=null){
            sw.isEditable = Schema.getGlobalDescribe().get(PlaceCPM_Utility.getCustomObjOrFieldName(sobjectName)).getDescribe().isUpdateable();
        }
        List<RecordType> recordTypeList = [SELECT Id, SobjectType, Name, DeveloperName FROM RecordType WHERE SobjectType =: sobjectName ];
        if(recordTypeList.size()>0){
            String query = 'SELECT recordTypeId FROM '+sobjectName+' WHERE Id=:'+'recordId';
            List<sObject> sobjectGet = Database.query(query);
            //515 / CPM-569
            String recordTypeId = (String)sobjectGet[0].get('recordTypeId');
            rlwList = getDetailPageLayoutSections(PlaceCPM_Utility.getCustomObjOrFieldName(sobjectName), recordTypeId);
            lsList = getEditPageLayoutSections(PlaceCPM_Utility.getCustomObjOrFieldName(sobjectName), recordTypeId);
            RecordType rt = [SELECT Id,Name FROM RecordType WHERE SobjectType=: sobjectName AND Id=:recordTypeId LIMIT 1];
            sw.sobjectRecordTypeName = rt.Name + ' - ';
        }
        else{
            rlwList = getDetailPageLayoutSections(PlaceCPM_Utility.getCustomObjOrFieldName(sobjectName),null);
            lsList = getEditPageLayoutSections(PlaceCPM_Utility.getCustomObjOrFieldName(sobjectName),null);
            sw.sobjectRecordTypeName = ''; //515 / CPM-569
        }
        sw.sobjectType = sobjectName;
        sw.sobjectLabel = recordId.getSObjectType().getDescribe().getLabel();
        sw.editPageInfo = lsList;
        sw.relatedListWrap = rlwList;
        return sw;
    }
    
    // Call the describe layout API and get detail page layout details,
    // @param sObjectName is the give object api name. 
    // @return list of LayoutSection wrapper
    @AuraEnabled 
    //563
    public static List<PLCashTabUtility.relatedListWrapper> getDetailPageLayoutSections(String sObjectName,String recordTypeId) {
        return PLCashTabUtility.getDetailPageLayout(sObjectName, recordTypeId);
    }

    //563
    
    public class splitWrapper{
        @AuraEnabled
        public String sobjectType;
        @AuraEnabled
        public Boolean isEditable;
        @AuraEnabled
        public String sobjectLabel;
        @AuraEnabled
        public List<String> fieldSet1;
        @AuraEnabled
        public List<String> fieldSet2;
        @AuraEnabled
        public List<String> requiredFields;
        @AuraEnabled
        public List<PLCashTabUtility.relatedListWrapper> relatedListWrap; //563
        @AuraEnabled
        public List<RecordTypeInfo> rtInfoList;
        @AuraEnabled
        public List<LayoutSection> editPageInfo; //563
        //515/CPM-569
        @AuraEnabled
        public String sobjectRecordTypeName;
    }
    
    public class relatedListWrapper{
        @AuraEnabled
        public String childObjectName;
        @AuraEnabled
        public String relationshipField;
        @AuraEnabled
        public List<childFieldAttributes> fieldAPINames;
    }
    public class childFieldAttributes{
        @AuraEnabled
        public String label;
        @AuraEnabled
        public String apiName;
        @AuraEnabled
        public String fieldType;
    }
    
    @AuraEnabled
    //this method is used to get type of PL category
    //@param record id of the record clicked to open the split screen
    //return stringr contains type of pl category
    public static splitWrapper getPLCategoryType(Id recordId){
        String type='';
        splitWrapper sw = new splitWrapper();
        if(recordId != null){
            GL_Code__c glAccount = [SELECT id, PL_Category__r.Type__c FROM GL_Code__c WHERE Id = : recordId LIMIT 1];
            type = glAccount.PL_Category__r.Type__c;
            if(type == CONSTANT.PL_CATEGORY_EXPENSE){ 
                sw.sobjectType = PlaceCPM_Utility.getCustomObjOrFieldName(CONSTANT.expenseAccountObject);
                sw.sobjectLabel = CONSTANT.EXPENSE_ACCOUNT_OBJECT_LABEL;
                
            }
            if(type == CONSTANT.PL_CATEGORY_REVENUE){ 
                sw.sobjectType = PlaceCPM_Utility.getCustomObjOrFieldName(CONSTANT.revenueAccountObject);
                sw.sobjectLabel = CONSTANT.REVENUE_ACCOUNT_OBJECT_LABEL;
                
            }
            Map<Id,String> rtList = new Map<Id,String>();
            List<RecordTypeInfo> rtInfoList = new List<RecordTypeInfo>();
            rtList = PlaceCPM_Utility.fetchRecordTypeValues(sw.sobjectType);
            Map<Id,RecordType> rtInfoMap = new Map<Id,RecordType>([SELECT Id, Description FROM RecordType WHERE Id IN: rtList.keySet()]);
            for(String rtid : rtList.keySet()){
                RecordTypeInfo rtinfo = new RecordTypeInfo();
                rtinfo.rtId = rtid;
                rtInfo.rtName = rtList.get(rtid).split(':')[0]; //rtList.get(rtid); //532 /cpm-569/515
                rtInfo.Description = rtInfoMap.get(rtId).Description;
                rtInfoList.add(rtInfo);
            }
            sw.rtInfoList = rtInfoList;
        }
        return sw;
    }
    
    @AuraEnabled
    public static List<RecordTypeInfo> fetchRecordTypeValues(String sobjectApiName){
        Map<Id,String> rtList = new Map<Id,String>();
        List<RecordTypeInfo> rtInfoList = new List<RecordTypeInfo>();
        if(sobjectApiName != null){
            rtList = PlaceCPM_Utility.fetchRecordTypeValues(sobjectApiName);
            if(rtList.size()>0){
                Map<Id,RecordType> rtInfoMap = new Map<Id,RecordType>([SELECT Id, Description FROM RecordType WHERE Id IN: rtList.keySet()]);
                system.debug('rtInfoMap'+rtInfoMap);
                for(String rtid : rtList.keySet()){
                    RecordTypeInfo rtinfo = new RecordTypeInfo();
                    rtinfo.rtId = rtid;
                    rtInfo.rtName = rtList.get(rtid);
                    rtInfo.Description = rtInfoMap.get(rtId).Description;
                    rtInfoList.add(rtInfo);
                }
            }
            
        }
        return rtInfoList;
    }
    
    public class RecordTypeInfo{
        @AuraEnabled
        public String rtId;
        @AuraEnabled
        public String rtName;
        @AuraEnabled
        public String Description;
        
    }
    
    
    // Call the describe layout API and get edit page layout details,
    // @param sObjectName is the give object api name. 
    // @return list of LayoutSection wrapper
    @AuraEnabled 
    public static List<LayoutSection> getEditPageLayoutSections(String sObjectName,String recordTypeId) {
        List<LayoutSection> lstSections = new List<LayoutSection>();
        Map<String, Object> deseralizedJsonResult = new Map<String, Object>();
        List<Object> editLayoutSections = new List<Object>();
        try {

            String sessionId = placeCPM_Utility.fetchUserSessionId();
            Http http = new Http();
            HttpRequest httpReq = new HttpRequest();
            HttpResponse httpRes = new HttpResponse();
            httpReq.setMethod('GET');
            httpReq.setHeader('Authorization', 'Bearer ' + sessionId);
            if(recordTypeId !=null){
                httpReq.setEndpoint(System.URL.getSalesforceBaseURL().toExternalForm() + '/services/data/v44.0/sobjects/'+sObjectName+'/describe/layouts/'+recordTypeId);
            }
            else{
                httpReq.setEndpoint(System.URL.getSalesforceBaseURL().toExternalForm() + '/services/data/v44.0/sobjects/'+sObjectName+'/describe/layouts/');
            }
            
            httpRes = http.send(httpReq);
            deseralizedJsonResult = (Map<String,Object>)JSON.deserializeUntyped(httpRes.getBody());
            if(recordTypeId !=null){
                editLayoutSections = (List<Object>)deseralizedJsonResult.get('editLayoutSections');
            }
            else{
                List<Object> layouts = (List<Object> )deseralizedJsonResult.get('layouts');
                Map<String, Object> detailLayout = (Map<String, Object>) layouts[0];
                editLayoutSections = (List<Object>)detailLayout.get('editLayoutSections');
            }
            
            for (Object allSections: editLayoutSections) {
                Map<String, Object> j = (Map<String, Object> ) allSections;
                List<Object> layoutRows = (List<Object>)j.get('layoutRows');
                String heading = ((String) j.get('heading'));
                Integer columns = ((Integer)j.get('columns'));
                LayoutSection ls = new LayoutSection(heading, columns);
                for(Object allLayoutRows: layoutRows) {
                    Map<String,Object > k = (Map <String,Object> ) allLayoutRows;
                    List<Object> layoutItems = (List<Object> ) k.get('layoutItems');
                    for (Object allLayoutItems: layoutItems) {
                        Map<String, Object> l = (Map<String, Object> ) allLayoutItems;
                        LayoutField field = new LayoutField();
                        field.isRequired = (Boolean) l.get('required');
                        List<Object > layoutComponents = (List<Object> ) l.get('layoutComponents');
                        for (Object allLayoutComponents: layoutComponents) {
                            Map<String, Object> m = (Map <String, Object> ) allLayoutComponents;
                            if (((String) m.get('type')) == 'Field') {
                                if (m.containsKey('components')) {
                                    List<Object> componenets = (List<Object> ) m.get('components');
                                    for (Object allComponents: componenets) {
                                        Map<String, Object> n = (Map<String, Object> ) allComponents;
                                        field.fieldName = (String) n.get('value');
                                    }
                                } else {
                                    field.fieldName  = (String) m.get('value');
                                }
                            }  
                        }
                        ls.lstFields.add(field);
                    }
                }
                lstSections.add(ls);
            }
        }
        catch( Exception e ){
            System.debug('Exception==='+e.getLineNumber() + ' : ' + e.getMessage());
        }
        return lstSections;
    }
    
    
    // Wrapper class to store the layout section details
    public class LayoutSection {   
        @AuraEnabled public String label;
        @AuraEnabled public List<LayoutField> lstFields;
        @AuraEnabled public Integer totalColumns;
        public LayoutSection( String label, Integer totalColumns ) {
            this.label = label;
            this.totalColumns = totalColumns;
            this.lstFields = new List<LayoutField>();
        }
    }
    
    // Wrapper class to store the field details
    public class LayoutField {
        @AuraEnabled public String fieldName;
        @AuraEnabled public Boolean isRequired;
        @AuraEnabled public Boolean isReadOnly;
        
    }
    
    @AuraEnabled
    public static AllocarionWrapper createAllocations(String AccountId, String glCode, String month,String year,String amount , Boolean isActual){
        system.debug(AccountId+glCode+month+year+amount+isActual);
        Id id = AccountId;
        String sObjName = id.getSObjectType().getDescribe().getName();
        String monthYear = PlaceCPM_Utility.getMonthString(Integer.valueOf(month))+' '+year;
        String plId='';
        system.debug('monthYear'+monthYear);
        AllocarionWrapper aw = new AllocarionWrapper();
        List<Profit_Loss__c> plList = [SELECT Id FROM Profit_Loss__c WHERE Name = :PlaceCPM_Utility.getMonthString(Integer.valueOf(month))+' '+year];
        
        if(sObjName == PlaceCPM_Utility.getCustomObjOrFieldName(CONSTANT.revenueAccountObject)){
            aw.sObjName = PlaceCPM_Utility.getCustomObjOrFieldName(CONSTANT.REVENUE_PL_ALLOCATION_OBJECT);
            aw.rtId = null;
            aw.isEmployee = false;
            aw.sObjLabel = CONSTANT.REVENUE_PL_ALLOCATION_LABEL;
            List<LayoutSection> lsList = getEditPageLayoutSections(PlaceCPM_Utility.getCustomObjOrFieldName(CONSTANT.REVENUE_PL_ALLOCATION_OBJECT),null);
            aw.layoutSection = lsList;
            if(plList.size() == 0){
                Integer dim = date.daysInMonth(Integer.valueOf(year),Integer.valueOf(month));
                date lastDOM = date.newInstance(Integer.valueOf(year),Integer.valueOf(month), dim);
                date firstDOM = lastDOM.toStartOfMonth();
                Profit_Loss__c pl = new Profit_Loss__c(Name=monthYear, Period_Start_Date__c=firstDOM, Period_End_Date__c=lastDOM);
                PlaceCPM_Utility.insertRecords(new List<Profit_Loss__c>{pl}, 'Profit_Loss__c', false);
                plId = pl.Id;
            }
            else{
                plId = plList[0].Id;
            }
            aw.plId = plId;
        }
        else if(sObjName == PlaceCPM_Utility.getCustomObjOrFieldName(CONSTANT.expenseAccountObject)){
            String nonWageExpPL = PlaceCPM_Utility.getRecordTypeIdbyDeveloperName(PlaceCPM_Utility.getCustomObjOrFieldName(CONSTANT.EXPENSE_PL_ALLOCATION_OBJECT), CONSTANT.PL_NON_WAGE_RDT);
            List<LayoutSection> lsList = getEditPageLayoutSections(PlaceCPM_Utility.getCustomObjOrFieldName(CONSTANT.EXPENSE_PL_ALLOCATION_OBJECT),nonWageExpPL);
            aw.sObjName = PlaceCPM_Utility.getCustomObjOrFieldName(CONSTANT.EXPENSE_PL_ALLOCATION_OBJECT);
            aw.rtId = nonWageExpPL;
            aw.isEmployee = false;
            aw.layoutSection = lsList;
            aw.sObjLabel = CONSTANT.EXPENSE_PL_ALLOCATION_LABEL;
            if(plList.size() == 0){
                Integer dim = date.daysInMonth(Integer.valueOf(year),Integer.valueOf(month));
                date lastDOM = date.newInstance(Integer.valueOf(year),Integer.valueOf(month), dim);
                date firstDOM = lastDOM.toStartOfMonth();
                Profit_Loss__c pl = new Profit_Loss__c(Name=monthYear, Period_Start_Date__c=firstDOM, Period_End_Date__c=lastDOM);
                PlaceCPM_Utility.insertRecords(new List<Profit_Loss__c>{pl}, 'Profit_Loss__c', false);
                plId = pl.Id;
            }
            else{
                plId = plList[0].Id;
            }
            aw.plId = plId;
        }
        else{
            aw.isEmployee =true;
        }
        return aw;
    }
    
    public class AllocarionWrapper {
        @AuraEnabled public String sObjName;
        @AuraEnabled public String sObjLabel;
        @AuraEnabled public String rtId;
        @AuraEnabled public String plId;
        @AuraEnabled public Boolean isEmployee;
        @AuraEnabled public List<LayoutSection> layoutSection;
        
    }

    //Returns first record of Assumption
    @AuraEnabled
    public static Assumption__c getAssumptions(){
        if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.ASSUMPTION_OBJECT,'Id, Name, Forecast_Duration__c, Forecasting_Quota__c, Hours_Per_day__c, Payment_Account__c, Revenue_GL_Account__c, Contract_Period__c, Discounted_Receipts__c, Recurring_Revenue_Billing_Cycle__c, Average_License_Price__c',Constant.ACTION_TYPE_ACCESS)){
        	return [SELECT Id, Name, Forecast_Duration__c, Forecasting_Quota__c, Hours_Per_day__c, Payment_Account__c, Revenue_GL_Account__c, Contract_Period__c, Discounted_Receipts__c, Recurring_Revenue_Billing_Cycle__c, Average_License_Price__c FROM Assumption__c LIMIT 1];
        }    
        return null;
    }	   
}
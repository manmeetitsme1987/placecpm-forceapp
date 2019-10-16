/*
Description : This class will be as controller for PAndL component.
Date Created : 17th June 2019
*/
public with sharing class CashForecastMainController{
    Static Integer currentMonth = System.today().month();
    Public Static MainWrapper mainWrapper = new MainWrapper();
    Public Static SummaryWrapper temp;
    Public Static String timeFrameGlobal = Label.MONTH;
    public static List<String> paymentAccountIdList;
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
    
    public static Decimal calculateOpeningBalance(){
        Decimal openingBalance = 0.0;
        String plQuery = 'SELECT id FROM Payment_Account__c';
        if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.PAYMENT_ACCOUNT_OBJECT,'id , Name , Balance__c',Constant.ACTION_TYPE_ACCESS)){
        	plQuery = 'SELECT id , Name , Bank_Account__r.name , Balance__c FROM Payment_Account__c';
        }    
        if(paymentAccountIdList != null && paymentAccountIdList.size() > 0){
            plQuery += ' WHERE Id IN : paymentAccountIdList';
        }
        for(Payment_Account__c pa : Database.query(plQuery)){
            if(pa.Balance__c != null)
            openingBalance += pa.Balance__c;
        }
        return openingBalance;
    }
    
    public static void parseDateRangeStringAndAssign(String dateRangesAttr){
        List<Integer> tempList;
        List<Date> tempListWeek;
        if(timeFrameGlobal == Label.Week){
            tempListWeek = new List<Date>();
        }
        else{
            tempList = new List<Integer>();
        }
        Map<Integer , List<Object>> dateRangeInput = new Map<Integer , List<Object>>();
        if(dateRangesAttr != null && dateRangesAttr.length() > 0){
            dateRanges.clear();
            yearsTobeFetched.clear();
            Map<String, Object> m = (Map<String , Object>)JSON.deserializeUntyped(dateRangesAttr);
            for(String year : m.keySet()){
                for(Object o : (List<Object>)m.get(year)){
                    if(timeFrameGlobal == Label.Week){
                        tempListWeek.add(Date.valueOf((String)o));
                        dateRangeInput.put(Integer.valueOf(year) , tempListWeek);
                    }else{
                        tempList.add((Integer)o);
                        dateRangeInput.put(Integer.valueOf(year) , tempList);
                    }
                }
                yearsTobeFetched.add(year);
            }
            dateRanges = dateRangeInput;
        }  
    }
    public static Map<Date , Integer> dateAndMonth;
    public static Map<Date , Integer> dateAndYear;
    public static Map<Integer , String> mapOfMonthAndName = new Map<Integer , String>();
    static{
        mapOfMonthAndName.put(1 , 'Jan');
        mapOfMonthAndName.put(2 , 'Feb');
        mapOfMonthAndName.put(3 , 'Mar');
        mapOfMonthAndName.put(4 , 'Apr');
        mapOfMonthAndName.put(5 , 'May');
        mapOfMonthAndName.put(6 , 'Jun');
        mapOfMonthAndName.put(7 , 'Jul');
        mapOfMonthAndName.put(8 , 'Aug');
        mapOfMonthAndName.put(9 , 'Sep');
        mapOfMonthAndName.put(10 , 'Oct');
        mapOfMonthAndName.put(11 , 'Nov');
        mapOfMonthAndName.put(12 , 'Dec');
    }
    public static boolean parseFromObject = false;
    public static void createTableHeader(String timeFrame){
        monthAndYearList.clear();
        tableHeaderList.clear();
        TableHeader th;
        Integer j=0;
        if(timeFrame == Label.Week){
            dateAndMonth = new Map<Date , Integer>();
            dateAndYear = new Map<Date , Integer>();
            Set<String> monthAndYearSet = new Set<String>();
            Integer tempMonth;
            Date tempDateSunday = Date.newInstance(1900, 1, 7);
            Integer mod;
            Date firstSunday;
            Date startDate;
            for(Integer years : dateRanges.keySet()){
                if(parseFromObject){
                    Date tempDate;
                    for(Object dates : (List<Object>)dateRanges.get(years)){
                        tempDate = Date.valueOf((String)dates);
                        th = new TableHeader();
                        tempMonth = tempDate.month();
                        dateAndMonth.put(tempDate , tempMonth);
                        dateAndYear.put(tempDate , years);
                        th.header = tempDate.day() + ' ' + mapOfMonthAndName.get(tempMonth) + ' ' + years;
                        tableHeaderList.add(th);
                        monthAndYearSet.add(tempDate.month()+':'+years);
                    }
                }
                else{
                    for(Date dates : (List<Date>)dateRanges.get(years)){
                        th = new TableHeader();
                        tempMonth = dates.month();
                        dateAndMonth.put(dates , tempMonth);
                        dateAndYear.put(dates , years);
                        th.header = dates.day() + ' ' + mapOfMonthAndName.get(tempMonth) + ' ' + years;
                        tableHeaderList.add(th);
                        monthAndYearSet.add(dates.month()+':'+years);
                    }
                }
                yearsTobeFetched.add(String.valueOf(years));
                startDate = Date.newInstance(System.today().year(), 1, 1);
                mod =  Math.mod(tempDateSunday.daysBetween(startDate) , 7);
                DateIndexlist.clear();
                firstSunday = mod == 0 ? startDate : startDate.addDays(7 - mod);
                mod =  Math.mod(tempDateSunday.daysBetween(startDate) , 7);
                for( ; firstSunday.year() <= years ; firstSunday = firstSunday+7){
                    DateIndexlist.add(firstSunday);
                }
            }
            MainWrapper.weekStartDate = tableHeaderList[0].header;
            MainWrapper.weekEndDate = tableHeaderList[tableHeaderList.size() - 1].header;
            monthAndYearList = new List<String>(monthAndYearSet);
        }
        else{
            for(Integer years : dateRanges.keySet()){
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
                Integer months;
                for(Object month : dateRanges.get(years)){
                    months = Integer.valueOf(month);
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
            if(j == 0){
                mainWrapper.startYear = years;
            }
            if(j == dateRanges.size() - 1){
                mainWrapper.endYear = years;
            }
            j++;
        }
        }
        
    }
    
    public static void createPlWrapper(String HeaderTitle , boolean showHeader , boolean sameRowDisplay , String type , String mapKey){
        PlWrapper plw = new PlWrapper();
        plw.pls = new SummaryWrapper();
        plw.HeaderTitle = HeaderTitle;
        plw.showHeader = showHeader;
        plw.sameRowDisplay = sameRowDisplay;
        plw.pls.type = type;
        plw.pls.valuesList = totalWrapper.get(mapKey);
        mainWrapper.plsWrapper.add(plw);
    }
    

    //  Method to fetch PL Statement records.
    //  @param year is the selected year on PAndL component
    //  @return MainWrapper
    @AuraEnabled
    public static MainWrapper getPLStatement(String view , String timeFrame  , String dateRangesAttr) {
        timeFrameGlobal = timeFrame;
        if(dateRangesAttr != null){
            parseDateRangeStringAndAssign(dateRangesAttr);
        }
        createTableHeader(timeFrame);
        createTotalWrapper();
        mainWrapper.tableHeader = tableHeaderList;
        mainWrapper.monthAndYearList = monthAndYearList;
        mainWrapper.dateRange = dateRanges;
        mainWrapper.yearsTobeFetched = yearsTobeFetched;
        String cashtype = CONSTANT.EXPCASHTYPE;
        String plQuery = 'SELECT id FROM P_L_Statement__c';
        if(timeFrame == Label.Week){
            DescribeSObjectResult describeResult = P_L_Statement__c.getSObjectType().getDescribe();	
            List<String> fieldNames = new List<String>( describeResult.fields.getMap().keySet() );	
            plQuery = ' SELECT ' + String.join( fieldNames, ',' ) + ', P_L_Category__r.type__c , GL_Code__r.PL_Category__c , GL_Code__r.PL_Category__r.Name , GL_Code__r.GL_Code__c , GL_Code__r.name' + ' FROM ' + describeResult.getName();
        }
        else{
            if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.PL_STATEMENT_OBJECT,'id , Year__c , January__c , February__c , March__c , April__c , '+
                                                                    'May__c , June__c , July__c , August__c , September__c , October__c , '+
                                                                    'November__c , December__c , GL_Code__c , '+
                                                                    'Type_Label__c , Year_Total__c , Type__c , '+ 
                                                                    'January_Actual__c , February_Actual__c , March_Actual__c , April_Actual__c , '+
                                                                    'May_Actual__c , June_Actual__c , July_Actual__c , August_Acutal__c , September_Acutal__c , '+
                                                                    'October_Actual__c , November_Actual__c , December_Actual__c , Year_Total_Actual__c , Year_Total_Variance__c ,'+
                                                                    'P_L_Category__c , Parent_Bank_Account__c ',Constant.ACTION_TYPE_ACCESS) &&
               PlaceCPM_Utility.checkAccessiblityOfFields(Constant.GL_CODE_OBJECT,'GL_Code__c, PL_Category__c',Constant.ACTION_TYPE_ACCESS) &&
               PlaceCPM_Utility.checkAccessiblityOfFields(Constant.PL_CATEGORY_OBJECT,'type__c',Constant.ACTION_TYPE_ACCESS)){
                plQuery = 'SELECT id , Year__c , January__c , February__c , March__c , April__c , '+
                                                                    'May__c , June__c , July__c , August__c , September__c , October__c , '+
                                                                    'November__c , December__c , GL_Code__c , GL_Code__r.PL_Category__c , '+
                                                                    'GL_Code__r.PL_Category__r.Name,GL_Code__r.name , P_L_Category__r.Name , '+
                                                                    'Type_Label__c , Year_Total__c , Type__c , GL_Code__r.GL_Code__c , '+ 
                                                                    'January_Actual__c , February_Actual__c , March_Actual__c , April_Actual__c , '+
                                                                    'May_Actual__c , June_Actual__c , July_Actual__c , August_Acutal__c , September_Acutal__c , '+
                                                                    'October_Actual__c , November_Actual__c , December_Actual__c , Year_Total_Actual__c , Year_Total_Variance__c ,'+
                                                                    'P_L_Category__c , P_L_Category__r.type__c , Parent_Bank_Account__c '+
                                                                    'FROM P_L_Statement__c';
                }   
        }
        plQuery += ' WHERE Year__c In : yearsTobeFetched AND type__c != null AND Statement_Type__c =: cashtype';
        if(paymentAccountIdList != null && paymentAccountIdList.size() > 0){
            plQuery += ' AND Parent_Bank_Account__c IN : paymentAccountIdList';
        }
        plQuery += ' ORDER BY Sequence__c ,GL_Code__c , Type_Label__c , Year__c';
        List<P_L_Statement__c> plsList = Database.query(plQuery);
        PlWrapper wr;
        PlWrapper tw;
        String plSectionCurrent;
        String plSectionPrev;
        Integer i=0;
        
        For(i=0 ; i< plsList.size() ; i++){
            if(i==0 || plsList[i].GL_Code__c != plsList[i-1].GL_Code__c || (plsList[i].Type_Label__c != null && plsList[i].Type_Label__c != plsList[i-1].Type_Label__c)){
                plSectionCurrent = plsList[i].P_L_Category__r.Type__c == CONSTANT.PL_CATEGORY_REVENUE ? Label.CashTab_INCOME : Label.CashTab_LESS_OPERATING_EXPENSES;
                plSectionPrev = i >= 1 ? (plsList[i-1].P_L_Category__r.Type__c ==  CONSTANT.PL_CATEGORY_REVENUE ? Label.CashTab_INCOME : Label.CashTab_LESS_OPERATING_EXPENSES) : plSectionCurrent;
                if(i == 0){
                    wr = new PlWrapper();
                    if(plsList[i].Type__c == CONSTANT.PL_STATEMENT_TYPE_CATEGORY){
                        wr.showHeader = true;
                        wr.HeaderTitle = plSectionCurrent;
                        wr.sameRowDisplay = false;
                    }else{
                        wr.showHeader = true;
                        wr.HeaderTitle = plSectionCurrent;
                        wr.sameRowDisplay = true;
                    }
                }
                else{
                    if(plSectionPrev != plSectionCurrent){
                        if(plSectionPrev == Label.CashTab_INCOME){
                            createPlWrapper(Label.CashTab_Total_Income , true , true , CONSTANT.PL_STATEMENT_TYPE_TOTAL , CONSTANT.PL_CATEGORY_REVENUE);
                        }
                        else if(plSectionPrev == Label.CashTab_LESS_OPERATING_EXPENSES){
                            createPlWrapper(Label.CashTab_Total_Operating_Expenses , true , true , CONSTANT.PL_STATEMENT_TYPE_TOTAL , CONSTANT.PL_CATEGORY_EXPENSE);
                            createPlWrapper(Label.CashTab_Cash_Surplus_Deficit , true , true , CONSTANT.PL_STATEMENT_TYPE_FORMULA , Label.CashTab_Cash_Surplus_Deficit);
                        }
                    }
                    wr = new PlWrapper();
                    if( plSectionCurrent == plSectionPrev){
                        wr.showHeader = false;
                    }else{
                        wr.showHeader = true;
                        if(plsList[i].Type__c == CONSTANT.PL_STATEMENT_TYPE_CATEGORY){
                            wr.HeaderTitle = plSectionCurrent ;
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
                if(plsList[i].Year__c != plsList[i-1].Year__c){
                    mergeSummaryWrapper(plsList[i] , temp); 
                }
                else if( plsList[i].Parent_Bank_Account__c != plsList[i-1].Parent_Bank_Account__c){
                    mergePaymentAccount(plsList[i] , temp , mainWrapper.monthAndYearList);
                }
            }
            if(i == plsList.size() - 1){
                tw = new PlWrapper();
                tw.pls = new SummaryWrapper();
                if(plsList[i].P_L_Category__r.Type__c == CONSTANT.PL_CATEGORY_REVENUE){
                    createPlWrapper(Label.CashTab_Total_Income , true , true , CONSTANT.PL_STATEMENT_TYPE_TOTAL , CONSTANT.PL_CATEGORY_REVENUE);
                }
                else if(plsList[i].P_L_Category__r.Type__c == CONSTANT.PL_CATEGORY_EXPENSE){
                    createPlWrapper(Label.CashTab_Total_Operating_Expenses , true , true , CONSTANT.PL_STATEMENT_TYPE_TOTAL , CONSTANT.PL_CATEGORY_EXPENSE);
                    createPlWrapper(Label.CashTab_Cash_Surplus_Deficit , true , true , CONSTANT.PL_STATEMENT_TYPE_FORMULA , Label.CashTab_Cash_Surplus_Deficit);
                }
                createPlWrapper(Label.CashTab_Net_Cash_Movement , true , true , CONSTANT.PL_STATEMENT_TYPE_FORMULA , Label.CashTab_Net_Cash_Movement);
                if(timeFrame == Label.Month || timeFrame == null){
                    createPlWrapper(Label.CashTab_Opening_Balance , true , true , CONSTANT.PL_STATEMENT_TYPE_FORMULA , Label.CashTab_Opening_Balance);
                    createPlWrapper(Label.CashTab_Plus_Net_Cash_Movement , true , true , CONSTANT.PL_STATEMENT_TYPE_FORMULA , Label.CashTab_Plus_Net_Cash_Movement);
                    createPlWrapper(Label.CashTab_Closing_Balance , true , true , CONSTANT.PL_STATEMENT_TYPE_FORMULA , Label.CashTab_Closing_Balance);
                }
            }
        }
        calculateVarianceInTotals(totalWrapper.get(CONSTANT.PL_CATEGORY_REVENUE) , true);
        calculateVarianceInTotals(totalWrapper.get(CONSTANT.PL_CATEGORY_EXPENSE) , false);
        calculateCashSurplusFormual(totalWrapper.get(CONSTANT.PL_CATEGORY_REVENUE) , totalWrapper.get(CONSTANT.PL_CATEGORY_EXPENSE));
        calculateOpeningBalance();
        calculateDefaultValue(view != null ? view : Label.Acutal_Forecast_UTD , mainWrapper.plsWrapper);
        if(timeFrame == 'Week' )
        calculateWeekDate(mainWrapper);
        return mainWrapper;
    }
    
    public static void calculateWeekDate(MainWrapper mw){
        Map<Integer , List<String>> dateMap = new Map<Integer , List<String>>();
        Integer noOfYears = 0;
        Date startDate;
        Date tempDateSunday = Date.newInstance(1900, 1, 7);
        Integer mod;
        Date firstSunday;
        List<String> tempList = new List<String>();
        if(PlaceCPM_Utility.assumptionForecastDuration > 0){
            Date dateAfterAssumptionDuration = System.today().addMonths(PlaceCPM_Utility.assumptionForecastDuration);
            noOfYears = dateAfterAssumptionDuration.year();
        }
        for(Integer i = System.today().year() - 1 ; i<=noOfYears ; i++){
            startDate = Date.newInstance(i, 1, 1);
            mod =  Math.mod(tempDateSunday.daysBetween(startDate) , 7);
            firstSunday = mod == 0 ? startDate : startDate.addDays(7 - mod);
            for( ; firstSunday.year() <= i ; firstSunday = firstSunday+7){
                if(!dateMap.containsKey(i)){
                    dateMap.put(i , new List<String>{});
                }
                tempList = dateMap.get(i);
                tempList.add(firstSunday.day() + ' ' + mapOfMonthAndName.get(firstSunday.month()) + ' ' + i);
                dateMap.put(i , tempList);
            }
        }
        mw.weekDates = dateMap;
    }
    Public static List<String> monthAndYearIndex;
    public static void createTotalWrapper(){
        monthAndYearIndex = new List<String>();
        List<ActualForceastWrap> newTotalWrapper;
        ActualForceastWrap afw;
        Integer currentMonth = System.today().month();
        Integer currentYear = System.today().year();
        boolean temp = true;
        for(String totalLabel : totalWrapper.keySet()){
            newTotalWrapper = new List<ActualForceastWrap>();
            newTotalWrapper.clear();
            for(Integer year : dateRanges.keySet()){
                if(timeFrameGlobal == 'Week'){
                    if(parseFromObject){
                        Date tempDate;
                        for(Object dates : dateRanges.get(year)){
                            tempDate = Date.valueOf((String)dates);
                            afw = new ActualForceastWrap();
                            afw.month = dateAndMonth.get(tempDate);
                            afw.year = dateAndYear.get(tempDate);
                            newTotalWrapper.add(afw);
                            if(temp){
                                monthAndYearIndex.add(String.valueOf(tempDate));
                            }
                        }
                    }
                    else{
                        for(Date dates : (List<Date>)dateRanges.get(year)){
                            afw = new ActualForceastWrap();
                            afw.month = dateAndMonth.get(dates);
                            afw.year = dateAndYear.get(dates);
                            newTotalWrapper.add(afw);
                            if(temp){
                                monthAndYearIndex.add(String.valueOf(dates));
                            }
                        }
                    }
                }
                else if(timeFrameGlobal == Label.YEAR){
                    afw = new ActualForceastWrap();
                    afw.month = 12;
                    afw.year = year;
                    newTotalWrapper.add(afw);
                    if(temp){
                        monthAndYearIndex.add(String.valueOf(year));
                    }
                    continue;
                }
                else{
                    Integer month;
                    for(Object months : dateRanges.get(year)){
                        month = Integer.valueOf(months);
                        afw = new ActualForceastWrap();
                        if(timeFrameGlobal == Label.MONTH || timeFrameGlobal ==  null)
                            afw.month = month;
                        else
                            afw.month = 3*month;
                        afw.year = year;
                        newTotalWrapper.add(afw);
                        if(totalLabel == Label.CashTab_Opening_Balance && currentMonth == afw.month && currentYear == afw.year){
                            afw.forecast = calculateOpeningBalance();
                        }
                        if(temp){
                            monthAndYearIndex.add(month + ':' + year);
                        }
                    }
                }
            }
            temp = false;
            totalWrapper.put(totalLabel , newTotalWrapper);
        }
    }
  
    //  Method to fetch PL Statement records.
    //  @param year is the selected year on PAndL component
    //  @return MainWrapper
    @AuraEnabled
    public static MainWrapper getPLStatementWithFilterAndExpansion(String view , String timeFrame , Map<Integer , List<Object>> dateRangesAttr ,
                                                    List<String> monthAndYearListAttr , List<Integer> expandedRowsList , List<String> yearListAttr ,
                                                    List<String> paymentAccIdList) {
        dateRanges = dateRangesAttr;
        monthAndYearList = monthAndYearListAttr;
        yearsTobeFetched = yearListAttr;
        paymentAccountIdList = paymentAccIdList;
        parseFromObject = true;
        MainWrapper mainWrap = getPLStatement(view , timeFrame , null);
        if(expandedRowsList != null && expandedRowsList.size() > 0){
            expandedRowsList.sort();
            Integer index;
            Integer childRecords = 0;
            if(mainWrap.plsWrapper.size() > 0){
                For(Integer i=0 ; i<expandedRowsList.size() ; i++){
                    index = expandedRowsList[i];
                    index += childRecords;
                    List<PlWrapper> tempList = addPL(mainWrap.plsWrapper[index].pls.glCode , view , mainWrap.plsWrapper[index].wrapId , mainWrap.dateRange , mainWrap.monthAndYearList , timeFrame , paymentAccIdList);
                    for(PlWrapper pls : tempList){
                        mainWrap.plsWrapper.add(++index , pls);
                        childRecords++;
                    }
                }
            }
        }
        return mainWrap;
    }
    
    public static Date getDateFromString(String dates){
        String [] arr = dates.split(' ');
        Integer month;
        Switch on arr[1]
        {
            when 'Jan' {month = 1;}
            when 'Feb' {month = 2;}
            when 'Mar' {month = 3;}
            when 'April' {month = 4;}
            when 'May' {month = 5;}
            when 'Jun' {month = 6;}
            when 'July' {month = 7;}
            when 'Aug' {month = 8;}
            when 'Sep' {month = 9;}
            when 'Oct' {month = 10;}
            when 'Nov' {month = 11;}
            when 'Dec' {month = 12;}
        }
        return Date.newInstance(Integer.valueOf(arr[2]) , month , Integer.valueOf(arr[0]));
    }
    
    
    @AuraEnabled
    public static MainWrapper applyFiltersPL(Integer startMonth , Integer endMonth , Integer startYear , Integer endYear , String timeFrame , String view , List<String> paymentAccIdList , String startDate , String endDate){ 
        Integer startMonthtemp;
        Integer endMonthtemp;
        dateRanges.clear();
        yearsTobeFetched.clear();
        paymentAccountIdList = paymentAccIdList;
        for(Integer i=startYear ;  i<=endYear ; i++){
            if(timeFrame == Label.Week){
                Map<Integer , List<Date>> dateMap = new Map<Integer , List<Date>>();
                Date startDateVal = getDateFromString(startDate);
                Date endDateVal = getDateFromString(endDate);
                Integer year;
                List<Date> tempList = new List<Date>();
                for( ; startDateVal <= endDateVal  ; startDateVal = startDateVal+7){
                    year = startDateVal.year();
                    if(!dateMap.containsKey(i)){
                        dateMap.put(i , new List<Date>{});
                    }
                    tempList = dateMap.get(i);
                    tempList.add(startDateVal);
                    dateMap.put(i , tempList);
                }
                dateRanges = dateMap;
            }else{
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
        }
        return getPLStatement(view , timeFrame , null);
    }
    
    @AuraEnabled
    public static MainWrapper applyTimeFrame(String timeFrame , String view , String dateRangesAttr , List<String> paymentAccIdList){
        yearsTobeFetched.clear();
        paymentAccountIdList = paymentAccIdList;
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
            else if(timeFrame == Label.Week){
                List<Date> templList = new List<Date>();
                Integer i = 0;
                Date startDate;
                Date tempDateSunday = Date.newInstance(1900, 1, 7);
                Integer mod;
                Date firstSunday;
                startDate = Date.newInstance(System.today().year(), 1, 1);
                Integer currYear = System.today().year();
                mod =  Math.mod(tempDateSunday.daysBetween(startDate) , 7);
                firstSunday = mod == 0 ? startDate : startDate.addDays(7 - mod);
                for(Date d = firstSunday ; firstSunday.year() <= currYear ; firstSunday = firstSunday+7){
                    templList.add(firstSunday);
                }
                DateIndexlist = templList;
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
    static List<Date> dateIndexlist = new List<Date>();

    @AuraEnabled
    public static List<PlWrapper> changeview(String view , String plsWrapperList){
        List<PlWrapper> plsWrapList = (List<PlWrapper>)JSON.deserialize(plsWrapperList, List<PlWrapper>.class);
        return calculateDefaultValue(view , plsWrapList);
    }
    
    //  Method to child rows to related gl account called from pandl component
    //  @param glCode and year
    //  @return PlWrapper list
    @AuraEnabled
    public static List<PlWrapper> addPL(String glCode , String view , Integer parentIndex , Map<Integer , List<Object>> dateRangesAttr , List<String> monthAndYearListAttr , String timeFrame , List<String> paymentAccIdList){
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
        String cashQuery;
        if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.EXPENSE_CASG_ALLOCATION_OBJECT,'Id , Week_End_Date_Gregorian__c ,Wage__c, Forecast_Amount__c , Actual_Amount__c , MonthAndYear__c',Constant.ACTION_TYPE_ACCESS) &&
           PlaceCPM_Utility.checkAccessiblityOfFields(Constant.GL_CODE_OBJECT,'PL_Category__c',Constant.ACTION_TYPE_ACCESS) &&
		   PlaceCPM_Utility.checkAccessiblityOfFields(Constant.PL_CATEGORY_OBJECT,'Type__c',Constant.ACTION_TYPE_ACCESS)  &&
           PlaceCPM_Utility.checkAccessiblityOfFields(Constant.WAGES_OBJECT,'Employee_Name__c, Employee_Number__c',Constant.ACTION_TYPE_ACCESS) &&
		   PlaceCPM_Utility.checkAccessiblityOfFields(Constant.expenseAccountObject,'Vendor__c',Constant.ACTION_TYPE_ACCESS) &&
           PlaceCPM_Utility.checkAccessiblityOfFields(Constant.CASH_FORECAST_OBJECT,'Period_Start_Date__c',Constant.ACTION_TYPE_ACCESS)
          ){
            cashQuery = 'SELECT Id , Week_End_Date_Gregorian__c , GL_Code__r.PL_Category__r.Type__c ,  Wage__c , Wage__r.Employee_Name__c , Wage__r.Employee_Number__c , Wage__r.Employee_Number__r.Name , Expense_Account__r.Vendor__c ,  Expense_Account__r.name , Expense_Account__r.Vendor__r.name , Forecast_Amount__c , Actual_Amount__c , Cash_Forecast__r.Period_Start_Date__c , MonthAndYear__c FROM Expense_Cash_Allocation__c where GL_Code__c =: glCode and MonthAndYear__c In : monthAndYearList';
        }    
        if(paymentAccIdList != null && paymentAccIdList.size() > 0){
            cashQuery += ' AND Payment_Account_Id__c IN : paymentAccIdList';
        }
        else{
            cashQuery += ' AND Payment_Account_Id__c != null';
        }
        For(Expense_Cash_Allocation__c expl : Database.query(cashQuery)){
            mapUniqueKey = expl.Expense_Account__r != null ? expl.Expense_Account__r.name : expl.Wage__r.Employee_Number__c;
            if(timeFrame == Label.Week){
                 if(sobjs.containsKey(expl.Week_End_Date_Gregorian__c + mapUniqueKey)){
                    tempList = sobjs.get(expl.Week_End_Date_Gregorian__c + mapUniqueKey);
                    if(expl.Actual_Amount__c != null){
                    	tempList[0] = tempList[0] != null ? tempList[0] +  expl.Actual_Amount__c : 0.0 + expl.Actual_Amount__c;
                    }
                    if(expl.Forecast_Amount__c != null){
                        tempList[1] = tempList[1] != null ? tempList[1] + expl.Forecast_Amount__c : 0.0 + expl.Forecast_Amount__c;
                    }
                    sobjs.put(expl.Week_End_Date_Gregorian__c + mapUniqueKey , tempList);
                }
                else{
                    sobjs.put(expl.Week_End_Date_Gregorian__c + mapUniqueKey , new List<Decimal>{expl.Actual_Amount__c != null ? expl.Actual_Amount__c : 0.0 , expl.Forecast_Amount__c != null ? expl.Forecast_Amount__c : 0.0});
                }
            }
            else{
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
        if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.REVENUE_CASH_ALLOCATION_OBJECT,'id , Week_End_Date_Gregorian__c , Forecast_Amount__c , Actual_Amount__c , MonthAndYear__c',Constant.ACTION_TYPE_ACCESS) &&
           PlaceCPM_Utility.checkAccessiblityOfFields(Constant.GL_CODE_OBJECT,'PL_Category__c',Constant.ACTION_TYPE_ACCESS) &&
           PlaceCPM_Utility.checkAccessiblityOfFields(Constant.PL_CATEGORY_OBJECT,'Type__c',Constant.ACTION_TYPE_ACCESS) &&
		   PlaceCPM_Utility.checkAccessiblityOfFields(Constant.revenueAccountObject,'Account__c',Constant.ACTION_TYPE_ACCESS) &&
           PlaceCPM_Utility.checkAccessiblityOfFields(Constant.CASH_FORECAST_OBJECT,'Period_Start_Date__c',Constant.ACTION_TYPE_ACCESS)
          ){
        	cashQuery = 'Select id , Week_End_Date_Gregorian__c , GL_Code__r.PL_Category__r.Type__c , Revenue_Account__r.Account__c , Revenue_Account__r.name , Revenue_Account__r.Account__r.name , Forecast_Amount__c , Actual_Amount__c , Cash_Forecast__r.Period_Start_Date__c , MonthAndYear__c FROM Revenue_Cash_Allocation__c where GL_Code__c =: glCode and MonthAndYear__c In : monthAndYearList';
        }
        if(paymentAccIdList != null && paymentAccIdList.size() > 0){
        	cashQuery += ' AND Payment_Account_Id__c IN : paymentAccIdList';
        }
        else{
            cashQuery += ' AND Payment_Account_Id__c != null';
        }
        For(Revenue_Cash_Allocation__c rvpl : Database.query(cashQuery)){
            mapUniqueKey = rvpl.Revenue_Account__r.name;
             if(timeFrame == Label.Week){
                 if(sobjs.containsKey(rvpl.Week_End_Date_Gregorian__c + mapUniqueKey)){
                    tempList = sobjs.get(rvpl.Week_End_Date_Gregorian__c + mapUniqueKey);
                    if(rvpl.Actual_Amount__c != null){
                    	tempList[0] = tempList[0] != null ? tempList[0] +  rvpl.Actual_Amount__c : 0.0 + rvpl.Actual_Amount__c;
                    }
                    if(rvpl.Forecast_Amount__c != null){
                        tempList[1] = tempList[1] != null ? tempList[1] + rvpl.Forecast_Amount__c : 0.0 + rvpl.Forecast_Amount__c;
                    }
                    sobjs.put(rvpl.Week_End_Date_Gregorian__c + mapUniqueKey , tempList);
                }
                else{
                    sobjs.put(rvpl.Week_End_Date_Gregorian__c + mapUniqueKey , new List<Decimal>{rvpl.Actual_Amount__c != null ? rvpl.Actual_Amount__c : 0.0 , rvpl.Forecast_Amount__c != null ? rvpl.Forecast_Amount__c : 0.0});
                }
            }
            else{
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
        Integer monthInteger;
        Date tempDate;
        for(String mapUniqueKeys : mapOfRevenueAccountsAndPl.keySet()){
            plwrapper = mapOfRevenueAccountsAndPl.get(mapUniqueKeys);
            if(timeFrame == Label.Week){
                for(Integer weekYear : dateRanges.keySet()){
                    for(Object weekDate : dateRanges.get(weekYear)){
                        tempDate = Date.valueOf((String)weekDate);
                        smw = plwrapper.pls;
                        smw.glcode = glCode;
                        smw.parentIndex = parentIndex;
                        afw = new ActualForceastWrap();
                        afw.actual = sobjs.containsKey(weekDate + ' 00:00:00' + mapUniqueKeys) ? sobjs.get(weekDate + ' 00:00:00' +  mapUniqueKeys)[0] : 0.0;
                        afw.forecast = sobjs.containsKey(weekDate + ' 00:00:00' + mapUniqueKeys) ? sobjs.get(weekDate + ' 00:00:00' + mapUniqueKeys)[1] : 0.0;
                        afw.variance = pltype == CONSTANT.PL_CATEGORY_REVENUE ?  afw.actual - afw.forecast : afw.forecast - afw.actual;
                        afw.month = tempDate.month();
                        afw.year = weekYear;
                        smw.valuesList.add(afw);
                    }
                }
            }else{
                for(Integer plyear : dateRanges.keySet()){
                    for(Object plmonth : dateRanges.get(plyear)){
                        monthInteger = Integer.valueOf(plmonth);
                        if(timeFrame == Label.MONTH || timeFrame == null){
                            smw = plwrapper.pls;
                            smw.glcode = glCode;
                            smw.parentIndex = parentIndex;
                            afw = new ActualForceastWrap();
                            monthAndYear = plmonth + ':' + plyear;
                            afw.actual = sobjs.containsKey(monthAndYear + mapUniqueKeys) ? sobjs.get(monthAndYear + mapUniqueKeys)[0] : 0.0;
                            afw.forecast = sobjs.containsKey(monthAndYear + mapUniqueKeys) ? sobjs.get(monthAndYear + mapUniqueKeys)[1] : 0.0;
                            afw.variance = pltype == CONSTANT.PL_CATEGORY_REVENUE ?  afw.actual - afw.forecast : afw.forecast - afw.actual;
                            afw.month = monthInteger;
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
                            if(sobjs.containsKey(tempKey = (3*monthInteger - 2) + ':' + plyear +  mapUniqueKeys)){
                                actualAmountTemp += sobjs.get(tempKey)[0];
                                forecastAmountTemp += sobjs.get(tempKey)[1];
                            }
                            if(sobjs.containsKey(tempKey = (3*monthInteger - 1) + ':' + plyear + mapUniqueKeys)){
                                actualAmountTemp += sobjs.get(tempKey)[0];
                                forecastAmountTemp += sobjs.get(tempKey)[1];
                            }
                            if(sobjs.containsKey(tempKey = (3*monthInteger) + ':' + plyear + mapUniqueKeys)){
                                actualAmountTemp += sobjs.get(tempKey)[0];
                                forecastAmountTemp += sobjs.get(tempKey)[1];
                            }
                            afw.month = (3*monthInteger);
                            afw.actual = actualAmountTemp;
                            afw.forecast = forecastAmountTemp;
                            afw.variance = pltype == CONSTANT.PL_CATEGORY_REVENUE ?  afw.actual - afw.forecast : afw.forecast - afw.actual;
                            afw.year = plyear;
                            smw.valuesList.add(afw);
                        }
                        if(timeFrame == Label.YEAR){
                            if(sobjs.containsKey(tempKey = monthInteger + ':' + plyear + mapUniqueKeys)){
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
    public static MainWrapper savePL(String AccountId , String month , String amount , Boolean isActual , String year , String glcode , Map<Integer , List<Object>> dateRangesAttr , List<String> monthAndYearListAttr , List<Integer> expandedRowsList , List<String> yearListAttr , String view , List<String> paymentAccIdList , String timeFrame){

        dateRanges = dateRangesAttr;
        monthAndYearList = monthAndYearListAttr;
        yearsTobeFetched = yearListAttr;
        Id id = AccountId;
        String sObjName = id.getSObjectType().getDescribe().getName();
        Revenue_Cash_Allocation__c rpl;
        Expense_Cash_Allocation__c epl;
        Boolean isUpdated = false;
        Boolean isRCActualAmount = false, isRCForecastAmount = false;
        Boolean ECAActualAmount = false, isECAForecastAmount = false;
        if(isActual && PlaceCPM_Utility.checkAccessiblityOfFields(Constant.REVENUE_CASH_ALLOCATION_OBJECT,'Actual_Amount__c',Constant.ACTION_TYPE_INSERT) && PlaceCPM_Utility.checkAccessiblityOfFields(Constant.REVENUE_CASH_ALLOCATION_OBJECT,'Actual_Amount__c',Constant.ACTION_TYPE_UPDATE) ){
            isRCActualAmount = true;
        }
        if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.REVENUE_CASH_ALLOCATION_OBJECT,'Forecast_Amount__c',Constant.ACTION_TYPE_INSERT) && PlaceCPM_Utility.checkAccessiblityOfFields(Constant.REVENUE_CASH_ALLOCATION_OBJECT,'Forecast_Amount__c',Constant.ACTION_TYPE_UPDATE) ){
            isRCForecastAmount = true;
        }
        if(isActual && PlaceCPM_Utility.checkAccessiblityOfFields(Constant.EXPENSE_CASG_ALLOCATION_OBJECT,'Actual_Amount__c',Constant.ACTION_TYPE_INSERT) && PlaceCPM_Utility.checkAccessiblityOfFields(Constant.EXPENSE_CASG_ALLOCATION_OBJECT,'Actual_Amount__c',Constant.ACTION_TYPE_UPDATE)){
            ECAActualAmount = true;
        }
        if( PlaceCPM_Utility.checkAccessiblityOfFields(Constant.EXPENSE_CASG_ALLOCATION_OBJECT,'Forecast_Amount__c',Constant.ACTION_TYPE_INSERT) && PlaceCPM_Utility.checkAccessiblityOfFields(Constant.EXPENSE_CASG_ALLOCATION_OBJECT,'Forecast_Amount__c',Constant.ACTION_TYPE_UPDATE)){
            isECAForecastAmount = true;
        }
        if(sObjName == PlaceCPM_Utility.getCustomObjOrFieldName(CONSTANT.revenueAccountObject)){
            if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.REVENUE_CASH_ALLOCATION_OBJECT,'id , Actual_Amount__c , Forecast_Amount__c',Constant.ACTION_TYPE_ACCESS)){
                For(Revenue_Cash_Allocation__c rvpl : [Select id , Actual_Amount__c , Forecast_Amount__c from Revenue_Cash_Allocation__c where Revenue_Account__c =: AccountId
                                                      and Cash_Forecast_Month__c =: Integer.valueOf(month) and GL_Code__c =:glcode and Cash_Forecast_Year__c =: Decimal.valueOf(year) limit 1]){
                    if(isActual && isRCActualAmount){
                        rvpl.Actual_Amount__c = Decimal.valueOf(amount);
                    }
                    else{
                        if(isRCForecastAmount){
                            rvpl.Forecast_Amount__c = Decimal.valueOf(amount);
                        }
                    }
                    rpl = rvpl;
                }
            }     
        }
        else if(sObjName == PlaceCPM_Utility.getCustomObjOrFieldName(CONSTANT.expenseAccountObject)){
            if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.EXPENSE_CASG_ALLOCATION_OBJECT,'id , Actual_Amount__c , Forecast_Amount__c',Constant.ACTION_TYPE_ACCESS)){
                 For(Expense_Cash_Allocation__c expl : [Select id , Actual_Amount__c , Forecast_Amount__c from Expense_Cash_Allocation__c where Expense_Account__c =: AccountId
                                                        and Cash_Forecast_Month__c =: Integer.valueOf(month) and GL_Code__c =:glcode and Cash_Forecast_Year__c =: Decimal.valueOf(year) limit 1]){
                    if(isActual && PlaceCPM_Utility.checkAccessiblityOfFields(Constant.EXPENSE_CASG_ALLOCATION_OBJECT,'Actual_Amount__c',Constant.ACTION_TYPE_INSERT) && PlaceCPM_Utility.checkAccessiblityOfFields(Constant.EXPENSE_CASG_ALLOCATION_OBJECT,'Actual_Amount__c',Constant.ACTION_TYPE_UPDATE)){
                        expl.Actual_Amount__c = Decimal.valueOf(amount);
                    }
                    else{
                        if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.EXPENSE_CASG_ALLOCATION_OBJECT,'Forecast_Amount__c',Constant.ACTION_TYPE_INSERT) && PlaceCPM_Utility.checkAccessiblityOfFields(Constant.EXPENSE_CASG_ALLOCATION_OBJECT,'Forecast_Amount__c',Constant.ACTION_TYPE_UPDATE)){
                            expl.Forecast_Amount__c = Decimal.valueOf(amount);
                        }
                    }
                    epl = expl;
                }
        	}	 
        }
        else if(sObjName == PlaceCPM_Utility.getCustomObjOrFieldName(CONSTANT.EMPLOYEE_OBJECT)){
            if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.EXPENSE_CASG_ALLOCATION_OBJECT,'id , Actual_Amount__c , Forecast_Amount__c',Constant.ACTION_TYPE_ACCESS)){
                 For(Expense_Cash_Allocation__c expl : [Select id , Actual_Amount__c , Forecast_Amount__c from Expense_Cash_Allocation__c where Wage__r.Employee_Number__c =: AccountId
                                                        and Cash_Forecast_Month__c =: Integer.valueOf(month) and GL_Code__c =:glcode and Cash_Forecast_Year__c =: Decimal.valueOf(year) limit 1]){
                    if(isActual && ECAActualAmount){
                        expl.Actual_Amount__c = Decimal.valueOf(amount);
                    }
                    else{
                        if(isECAForecastAmount){
                            expl.Forecast_Amount__c = Decimal.valueOf(amount);
                        }
                    }
                    epl = expl;
                }
        	}  
        }
        Database.UpsertResult saveResult;        

            if(rpl != null && Schema.sObjectType.Revenue_Cash_Allocation__c.isCreateable() && Schema.sObjectType.Revenue_Cash_Allocation__c.isUpdateable())
            saveResult = Database.upsert(rpl, false);
            
            if(epl != null && Schema.sObjectType.Expense_Cash_Allocation__c.isCreateable() && Schema.sObjectType.Expense_Cash_Allocation__c.isUpdateable())
            saveResult = Database.upsert(epl , false);
            
            if(saveResult != null && saveResult.isSuccess()){
                paymentAccountIdList = paymentAccIdList;
                parseFromObject = true;
                MainWrapper mainWrap = getPLStatement(view , timeFrame , null);
                if(expandedRowsList != null && expandedRowsList.size() >0){
                    expandedRowsList.sort();
                    Integer index;
                    Integer childRecords = 0;
                    For(Integer i=0 ; i<expandedRowsList.size() ; i++){
                        index = expandedRowsList[i];
                        index += childRecords;
                        List<PlWrapper> tempList = addPL(mainWrap.plsWrapper[index].pls.glCode , view , mainWrap.plsWrapper[index].wrapId , mainWrap.dateRange , mainWrap.monthAndYearList , timeFrame , paymentAccIdList);
                        for(PlWrapper pls : tempList){
                            mainWrap.plsWrapper.add(++index , pls);
                            childRecords++;
                        }
                    }
                }
                return mainWrap;
            }
            else
                return null;
    }
    
    //  Method to changeview
    //  @param view and plsWrapperList
    //  @return PlWrapper
    public static List<PlWrapper> calculateDefaultValue(String view , List<PlWrapper> plsWrapList){
        Integer currentYear = System.today().year();
        For(PlWrapper plsw : plsWrapList){
            if(plsw.pls != null)
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
        public Map<Integer , List<Object>> dateRange;
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
        @AuraEnabled
        public String weekStartDate;
        @AuraEnabled
        public String weekEndDate;
        @AuraEnabled  
        public Map<Integer , List<String>> weekDates;
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
    public static Map<Integer , List<Object>> dateRanges = new Map<Integer , List<Object>>();
    public static List<String> monthAndYearList = new List<String>();
    public static List<String> yearsTobeFetched = new List<String>();
    static List<TableHeader> tableHeaderList = new List<TableHeader>();
    public static Map<String , List<ActualForceastWrap>> totalWrapper = new Map<String , List<ActualForceastWrap>>();

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
        monthAndYearList.add('1:2019');
        monthAndYearList.add('2:2019');
        monthAndYearList.add('3:2019');
        monthAndYearList.add('4:2019');
        monthAndYearList.add('5:2019');
        monthAndYearList.add('6:2019');
        monthAndYearList.add('7:2019');
        monthAndYearList.add('8:2019');
        monthAndYearList.add('9:2019');
        monthAndYearList.add('10:2019');
        monthAndYearList.add('11:2019');
        monthAndYearList.add('12:2019');
        totalWrapper.put(CONSTANT.PL_CATEGORY_REVENUE , new List<ActualForceastWrap>());
        totalWrapper.put(CONSTANT.PL_CATEGORY_EXPENSE , new List<ActualForceastWrap>());
        totalWrapper.put(Label.CashTab_Cash_Surplus_Deficit , new List<ActualForceastWrap>());
        totalWrapper.put(Label.CashTab_Net_Cash_Movement , new List<ActualForceastWrap>());
        totalWrapper.put(Label.CashTab_Opening_Balance , new List<ActualForceastWrap>());
        totalWrapper.put(Label.CashTab_Plus_Net_Cash_Movement , new List<ActualForceastWrap>());
        totalWrapper.put(Label.CashTab_Closing_Balance , new List<ActualForceastWrap>());
        createTableHeader(Label.Month);
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
        
        SummaryWrapper(){}
        
        SummaryWrapper(P_L_Statement__c pls){
            if(pls != null)
            initForecastAndActual(pls);
        }
        void initForecastAndActual(P_L_Statement__c pls){
            Integer year = Integer.valueOf(pls.Year__c);
            Integer tempIndex;
            Boolean isIncome;
            Decimal temp;
            if(dateRanges.keySet().contains(year)){
                ActualForceastWrap afw;
                isIncome = pls.P_L_Category__r.type__c == CONSTANT.PL_CATEGORY_REVENUE || pls.Type_Label__c == CONSTANT.NET_INCOME ? true : false;
                if(timeFrameGlobal == Label.Week){
                    if(parseFromObject){
                        Date tempDate;
                        for(Object dates : dateRanges.get(Integer.valueOf(pls.Year__c))){
                            tempDate = Date.valueOf((String)dates);
                            afw = new ActualForceastWrap();
                            tempIndex = dateIndexlist.indexOf(tempDate) + 1;
                            temp = (Decimal)pls.get('week' + tempIndex + '_Actual__c');
                            afw.actual = temp != null ? temp : 0.0;
                            temp = (Decimal)pls.get('week' + tempIndex + '_Forecast__c');
                            afw.forecast = temp != null ? temp : 0.0;
                            afw.variance = isIncome ?  afw.actual - afw.forecast : afw.forecast - afw.actual;
                            afw.month = dateAndMonth.get(tempDate);
                            afw.year = dateAndYear.get(tempDate);
                            valuesList.add(afw);
                            addInTotalWeek(afw.forecast , afw.actual , tempDate , pls.P_L_Category__r.Type__c);
                        }
                    }
                    else{
                        for(Date weekDate : (List<Date>)dateRanges.get(Integer.valueOf(pls.Year__c))){
                            afw = new ActualForceastWrap();
                            tempIndex = dateIndexlist.indexOf(weekDate) + 1;
                            temp = (Decimal)pls.get('week' + tempIndex + '_Actual__c');
                            afw.actual = temp != null ? temp : 0.0;
                            temp = (Decimal)pls.get('week' + tempIndex + '_Forecast__c');
                            afw.forecast = temp != null ? temp : 0.0;
                            afw.variance = isIncome ?  afw.actual - afw.forecast : afw.forecast - afw.actual;
                            afw.month = dateAndMonth.get(weekDate);
                            afw.year = dateAndYear.get(weekDate);
                            valuesList.add(afw);
                            addInTotalWeek(afw.forecast , afw.actual , weekDate , pls.P_L_Category__r.Type__c);
                        }
                    }
                }
                else if(timeFrameGlobal == Label.YEAR){
                    afw = new ActualForceastWrap();
                    afw.actual = pls.January_Actual__c + pls.February_Actual__c + pls.March_Actual__c + pls.April_Actual__c + pls.May_Actual__c + pls.June_Actual__c+
                                     pls.July_Actual__c + pls.August_Acutal__c + pls.September_Acutal__c + pls.October_Actual__c + pls.November_Actual__c + pls.December_Actual__c;
                    afw.forecast = pls.January__c + pls.February__c + pls.March__c + pls.April__c + pls.May__c + pls.June__c + pls.July__c + pls.August__c + pls.September__c +
                                       pls.October__c + pls.November__c + pls.December__c;
                    afw.variance = isIncome ?  afw.actual - afw.forecast : afw.forecast - afw.actual;
                    afw.month = 12;
                    afw.year = year;
                    valuesList.add(afw);
                    addInTotal(afw.forecast , afw.actual , 12 , pls.P_L_Category__r.Type__c , year);
                }
                else{
                    Integer month;
                    For(Object months : dateRanges.get(Integer.valueOf(pls.Year__c))){
                        month = Integer.valueOf(months);
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
                            afw.variance = isIncome ?  afw.actual - afw.forecast : afw.forecast - afw.actual;
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
                            afw.variance = isIncome ?  afw.actual - afw.forecast : afw.forecast - afw.actual;
                            afw.year = year;
                            valuesList.add(afw);
                        }
                        addInTotal(afw.forecast , afw.actual , month , pls.P_L_Category__r.Type__c , year);
                    }
                }
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
            Integer tempIndex;
            Decimal temp;
            Boolean isIncome = pls.P_L_Category__r.type__c == CONSTANT.PL_CATEGORY_REVENUE || pls.Type_Label__c == CONSTANT.NET_INCOME ? true : false;
            if(timeFrameGlobal == 'Week'){
                if(parseFromObject){
                    Date tempDate;
                    for(Object dates : dateRanges.get(Integer.valueOf(pls.Year__c))){
                        tempDate = Date.valueOf((String)dates);
                        afw = new ActualForceastWrap();
                        tempIndex = dateIndexlist.indexOf(tempDate) + 1;
                        temp = (Decimal)pls.get('week' + tempIndex + '_Actual__c');
                        afw.actual = temp != null ? temp : 0.0;
                        temp = (Decimal)pls.get('week' + tempIndex + '_Forecast__c');
                        afw.forecast = temp != null ? temp : 0.0;
                        afw.variance = isIncome ?  afw.actual - afw.forecast : afw.forecast - afw.actual;
                        afw.month = dateAndMonth.get(tempDate);
                        afw.year = dateAndYear.get(tempDate);
                        smw.valuesList.add(afw);
                        addInTotalWeek(afw.forecast , afw.actual , tempDate , pls.P_L_Category__r.Type__c);
                    }
                }
                else{
                    for(Date weekDate : (List<Date>)dateRanges.get(Integer.valueOf(pls.Year__c))){
                        afw = new ActualForceastWrap();
                        tempIndex = dateIndexlist.indexOf(weekDate) + 1;
                        temp = (Decimal)pls.get('week' + tempIndex + '_Actual__c');
                        afw.actual = temp != null ? temp : 0.0;
                        temp = (Decimal)pls.get('week' + tempIndex + '_Forecast__c');
                        afw.forecast = temp != null ? temp : 0.0;
                        afw.variance = isIncome ?  afw.actual - afw.forecast : afw.forecast - afw.actual;
                        afw.month = dateAndMonth.get(weekDate);
                        afw.year = dateAndYear.get(weekDate);
                        smw.valuesList.add(afw);
                        addInTotalWeek(afw.forecast , afw.actual , weekDate , pls.P_L_Category__r.Type__c);
                    }
                }
            }
            else if(timeFrameGlobal == Label.Year){
                afw = new ActualForceastWrap();
                afw.actual = pls.January_Actual__c + pls.February_Actual__c + pls.March_Actual__c + pls.April_Actual__c + pls.May_Actual__c + pls.June_Actual__c+
                             pls.July_Actual__c + pls.August_Acutal__c + pls.September_Acutal__c + pls.October_Actual__c + pls.November_Actual__c + pls.December_Actual__c;
                afw.forecast = pls.January__c + pls.February__c + pls.March__c + pls.April__c + pls.May__c + pls.June__c + pls.July__c + pls.August__c + pls.September__c +
                               pls.October__c + pls.November__c + pls.December__c;
                afw.variance = isIncome ? afw.actual - afw.forecast : afw.forecast - afw.actual;
                afw.month = 12;
                afw.year = year;
                smw.valuesList.add(afw);
                addInTotal(afw.forecast , afw.actual , 12 , pls.P_L_Category__r.Type__c , year);
            }
            else{
                Integer month;
                For(Object months : dateRanges.get(Integer.valueOf(pls.Year__c))){
                    month = Integer.valueOf(months);
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
                        afw.variance = isIncome ?  afw.actual - afw.forecast : afw.forecast - afw.actual;
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
                        afw.variance = isIncome ? afw.actual - afw.forecast : afw.forecast - afw.actual;
                        afw.year = year;
                        smw.valuesList.add(afw);
                    }
                    addInTotal(afw.forecast , afw.actual , month  , pls.P_L_Category__r.Type__c , year);
                }
            }
        }
    }
    
    public static void mergePaymentAccount(P_L_Statement__c pls , SummaryWrapper smw , List<String> monthAndYearList){
        Integer year = Integer.valueOf(pls.Year__c);
        ActualForceastWrap afw;
        Decimal actualTemp;
        Decimal forecastTemp;
        if(dateRanges.keySet().contains(year)){
            Integer tempIndex;
            Integer i = 0;
            Decimal temp;
            if(timeFrameGlobal == Label.Week){
                if(parseFromObject){
                    Date tempDate;
                    for(Object dates : dateRanges.get(Integer.valueOf(pls.Year__c))){
                        tempDate = Date.valueOf((String)dates);
                        afw = smw.valuesList[i];
                        actualTemp = afw.actual;
                        forecastTemp = afw.forecast;
                        i++;
                        tempIndex = dateIndexlist.indexOf(tempDate) + 1;
                        temp = (Decimal)pls.get('week' + tempIndex + '_Actual__c');
                        afw.actual += temp != null ? temp : 0.0;
                        temp = (Decimal)pls.get('week' + tempIndex + '_Forecast__c');
                        afw.forecast += temp != null ? temp : 0.0;
                        afw.variance = pls.P_L_Category__r.type__c == CONSTANT.PL_CATEGORY_REVENUE || pls.Type_Label__c == CONSTANT.NET_INCOME ?  afw.actual - afw.forecast : afw.forecast - afw.actual;
                        addInTotalWeek(afw.forecast - forecastTemp , afw.actual - actualTemp , tempDate , pls.P_L_Category__r.Type__c);
                    }
                }
                else{
                    for(Date weekDate : (List<Date>)dateRanges.get(Integer.valueOf(pls.Year__c))){
                        afw = smw.valuesList[i];
                        actualTemp = afw.actual;
                        forecastTemp = afw.forecast;
                        i++;
                        tempIndex = dateIndexlist.indexOf(weekDate) + 1;
                        temp = (Decimal)pls.get('week' + tempIndex + '_Actual__c');
                        afw.actual += temp != null ? temp : 0.0;
                        temp = (Decimal)pls.get('week' + tempIndex + '_Forecast__c');
                        afw.forecast += temp != null ? temp : 0.0;
                        afw.variance = pls.P_L_Category__r.type__c == CONSTANT.PL_CATEGORY_REVENUE || pls.Type_Label__c == CONSTANT.NET_INCOME ?  afw.actual - afw.forecast : afw.forecast - afw.actual;
                        addInTotalWeek(afw.forecast - forecastTemp , afw.actual - actualTemp , weekDate , pls.P_L_Category__r.Type__c);
                    }
                }
            }
            else if(timeFrameGlobal == Label.YEAR){
                afw = smw.valuesList[monthAndYearIndex.indexOf(String.valueOf(year))];
                actualTemp = afw.actual;
                forecastTemp = afw.forecast;
                afw.actual += pls.January_Actual__c + pls.February_Actual__c + pls.March_Actual__c + pls.April_Actual__c + pls.May_Actual__c + pls.June_Actual__c+
                             pls.July_Actual__c + pls.August_Acutal__c + pls.September_Acutal__c + pls.October_Actual__c + pls.November_Actual__c + pls.December_Actual__c;
                afw.forecast += pls.January__c + pls.February__c + pls.March__c + pls.April__c + pls.May__c + pls.June__c + pls.July__c + pls.August__c + pls.September__c +
                               pls.October__c + pls.November__c + pls.December__c;
                afw.variance = pls.P_L_Category__r.type__c == CONSTANT.PL_CATEGORY_REVENUE || pls.Type_Label__c == CONSTANT.NET_INCOME ? afw.actual - afw.forecast : afw.forecast - afw.actual;
                addInTotal(afw.forecast -  forecastTemp , afw.actual - actualTemp , 12 , pls.P_L_Category__r.Type__c , year);
            }
            else{
                Integer month;
                For(Object months : dateRanges.get(Integer.valueOf(pls.Year__c))){
                    month = Integer.valueOf(months);
                    afw = smw.valuesList[monthAndYearIndex.indexOf(month + ':' + year)];
                    actualTemp = afw.actual;
                    forecastTemp = afw.forecast;
                    if(timeFrameGlobal == Label.MONTH || timeFrameGlobal == null){
                        switch on month{
                            when 1 {
                                afw.actual += pls.January_Actual__c;
                                afw.forecast += pls.January__c;
                            }   
                            when 2 {
                                afw.actual += pls.February_Actual__c;
                                afw.forecast += pls.February__c;
                            }
                            when 3 {
                                afw.actual += pls.March_Actual__c;
                                afw.forecast += pls.March__c;
                            }
                            when 4 {
                                afw.actual += pls.April_Actual__c;
                                afw.forecast += pls.April__c;
                            }
                            when 5 {
                                afw.actual += pls.May_Actual__c;
                                afw.forecast += pls.May__c;
                            }
                            when 6 {
                                afw.actual += pls.June_Actual__c;
                                afw.forecast += pls.June__c;
                            }
                            when 7 {
                                afw.actual += pls.July_Actual__c;
                                afw.forecast += pls.July__c;
                            }
                            when 8 {
                                afw.actual += pls.August_Acutal__c;
                                afw.forecast += pls.August__c;
                            }
                            when 9 {
                                afw.actual += pls.September_Acutal__c;
                                afw.forecast += pls.September__c;
                            }
                            when 10 {
                                afw.actual += pls.October_Actual__c;
                                afw.forecast += pls.October__c;
                            }
                            when 11 {
                                afw.actual += pls.November_Actual__c;
                                afw.forecast += pls.November__c;
                            }
                            when else {
                                afw.actual += pls.December_Actual__c;
                                afw.forecast += pls.December__c;
                            }
                        }   
                    afw.variance = pls.P_L_Category__r.type__c == CONSTANT.PL_CATEGORY_REVENUE || pls.Type_Label__c == CONSTANT.NET_INCOME ?  afw.actual - afw.forecast : afw.forecast - afw.actual;
                }
                    else if(timeFrameGlobal == Label.QUARTER){
                        switch on month{
                            when 1 {
                                afw.actual += pls.January_Actual__c + pls.February_Actual__c + pls.March_Actual__c;
                                afw.forecast += pls.January__c + pls.February__c + pls.March__c;
                            }   
                            when 2 {
                                afw.actual += pls.April_Actual__c + pls.May_Actual__c + pls.June_Actual__c;
                                afw.forecast += pls.April__c + pls.May__c + pls.June__c;
                            }
                            when 3 {
                                afw.actual += pls.July_Actual__c + pls.August_Acutal__c + pls.September_Acutal__c;
                                afw.forecast += pls.July__c + pls.August__c + pls.September__c;
                            }
                            when 4 {
                                afw.actual += pls.October_Actual__c + pls.November_Actual__c + pls.December_Actual__c;
                                afw.forecast += pls.October__c + pls.November__c + pls.December__c;
                            }
                        }
                        afw.variance = pls.P_L_Category__r.type__c == CONSTANT.PL_CATEGORY_REVENUE || pls.Type_Label__c == CONSTANT.NET_INCOME ? afw.actual - afw.forecast : afw.forecast - afw.actual;
                    }
                    addInTotal(afw.forecast -  forecastTemp , afw.actual - actualTemp , month , pls.P_L_Category__r.Type__c , year);
                }
            }
        }
    }
    
    public static void addInTotal(Decimal forecastAmount , Decimal  actualAmount , Integer month , String category , Integer year){
        String key = timeFrameGlobal == Label.YEAR ? String.valueOf(year) : (month + ':' + year);
        ActualForceastWrap afw = totalWrapper.get(category)[monthAndYearIndex.indexOf(key)];
        afw.actual += actualAmount;
        afw.forecast += forecastAmount;
    }
    public static void addInTotalWeek(Decimal forecastAmount , Decimal  actualAmount , Date dates , String category){
        ActualForceastWrap afw = totalWrapper.get(category)[monthAndYearIndex.indexOf(String.valueOf(dates))];
        afw.actual += actualAmount;
        afw.forecast += forecastAmount;
    }
    
    public static void calculateVarianceInTotals(List<ActualForceastWrap> listOfTotals , boolean isIncome){
        for(ActualForceastWrap afw : listOfTotals){
            if(isIncome)
            afw.variance = afw.actual - afw.forecast;
            else
            afw.variance = afw.forecast - afw.actual;
        }
    }
    
    public static void calculateCashSurplusFormual(List<ActualForceastWrap> listOfTotalsIncome , List<ActualForceastWrap> listOfTotalsExpense){
        Integer i = 0;
        List<ActualForceastWrap> netCashMovement = totalWrapper.get(Label.CashTab_Net_Cash_Movement);
        List<ActualForceastWrap> openingBalance = totalWrapper.get(Label.CashTab_Opening_Balance);
        List<ActualForceastWrap> closingBalance = totalWrapper.get(Label.CashTab_Closing_Balance);
        List<ActualForceastWrap> plusNetCashMovement = totalWrapper.get(Label.CashTab_Plus_Net_Cash_Movement);

        Integer month = system.today().month();
        Integer year = system.today().year();
        Integer indexMonthAndYear = monthAndYearIndex.indexOf(month + ':' + year);
        Decimal tempBalance = 0.0;
        for(ActualForceastWrap afw : totalWrapper.get(Label.CashTab_Cash_Surplus_Deficit)){
            afw.actual = listOfTotalsIncome[i].actual - listOfTotalsExpense[i].actual;
            afw.forecast = listOfTotalsIncome[i].forecast - listOfTotalsExpense[i].forecast;
            afw.variance = listOfTotalsIncome[i].variance - listOfTotalsExpense[i].variance;
            netCashMovement[i].actual = 0 - afw.actual;
            netCashMovement[i].forecast = 0 - afw.forecast;
            netCashMovement[i].variance = 0 - afw.variance;
            plusNetCashMovement[i].actual = 0 - afw.actual;
            plusNetCashMovement[i].forecast = 0 - afw.forecast;
            plusNetCashMovement[i].variance = 0 - afw.variance;
            if(indexMonthAndYear == i){
                closingBalance[i].forecast = openingBalance[i].forecast -  netCashMovement[i].forecast;
                tempBalance = closingBalance[i].forecast;
            }
            if(indexMonthAndYear < i){
                openingBalance[i].forecast = tempBalance;
                closingBalance[i].forecast = tempBalance - netCashMovement[i].forecast;
                tempBalance = closingBalance[i].forecast;
            }
            i++;
        }
        totalWrapper.put(Label.CashTab_Plus_Net_Cash_Movement , netCashMovement);
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
         List<String> listOfRelatedList = new List<String>();
        splitWrapper sw = new splitWrapper();
        List<PLCashTabUtility.relatedListWrapper> rlwList = new List<PLCashTabUtility.relatedListWrapper>(); //563
        List<LayoutSection> lsList = new List<LayoutSection>(); //563
        String sobjectName = recordId.getSObjectType().getDescribe().getName();
        //563
        if(sobjectName !=null){
            sw.isEditable = Schema.getGlobalDescribe().get(PlaceCPM_Utility.getCustomObjOrFieldName(sobjectName)).getDescribe().isUpdateable();
        }
        List<RecordType> recordTypeList = [SELECT Id, SobjectType, Name, DeveloperName FROM RecordType WHERE SobjectType =: sobjectName ];
        if(recordTypeList.size()>0){
            String query = 'SELECT recordTypeId FROM '+sobjectName+' WHERE Id=:'+'recordId';
            List<sObject> sobjectGet = Database.query(query);
            rlwList = getDetailPageLayoutSections(PlaceCPM_Utility.getCustomObjOrFieldName(sobjectName),(String)sobjectGet[0].get('recordTypeId'));
            lsList = getEditPageLayoutSections(PlaceCPM_Utility.getCustomObjOrFieldName(sobjectName),(String)sobjectGet[0].get('recordTypeId'));
        }
        else{
            rlwList = getDetailPageLayoutSections(PlaceCPM_Utility.getCustomObjOrFieldName(sobjectName),null);
            lsList = getEditPageLayoutSections(PlaceCPM_Utility.getCustomObjOrFieldName(sobjectName),null);
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
    public static  List<PLCashTabUtility.relatedListWrapper> getDetailPageLayoutSections(String sObjectName,String recordTypeId) {
        return PLCashTabUtility.getDetailPageLayout(sObjectName, recordTypeId);
    }
    
    //563  | removed method fetchUserSessionId method

    public class splitWrapper{
        @AuraEnabled
        public String sobjectType;
        @AuraEnabled
        public Boolean isEditable;//563
        @AuraEnabled
        public String sobjectLabel;
        //@AuraEnabled
        //public Boolean isEditable;//563
        @AuraEnabled
        public List<String> fieldSet1;
        @AuraEnabled
        public List<String> fieldSet2;
        @AuraEnabled
        public List<String> requiredFields;
        @AuraEnabled
        public List<PLCashTabUtility.relatedListWrapper> relatedListWrap; //563
        //public List<relatedListWrapper> relatedListWrap;	        
        @AuraEnabled
        public List<RecordTypeInfo> rtInfoList;
        @AuraEnabled
        public List<LayoutSection> editPageInfo;//563
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
            GL_Code__c glAccount;
            if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.PL_CATEGORY_OBJECT,'Type__c',Constant.ACTION_TYPE_ACCESS)){
            	glAccount = [SELECT id, PL_Category__r.Type__c FROM GL_Code__c WHERE Id = : recordId LIMIT 1];
            }    
            type = glAccount.PL_Category__r.Type__c;
            if(type == 'Expense'){
                sw.sobjectType = PlaceCPM_Utility.getCustomObjOrFieldName('Expense_Account__c');
                sw.sobjectLabel = 'Expense Account';
                
            }
            if(type == 'Revenue'){
                sw.sobjectType = PlaceCPM_Utility.getCustomObjOrFieldName('Revenue_Account__c');
                sw.sobjectLabel = 'Revenue Account';
                
            }
            Map<Id,String> rtList = new Map<Id,String>();
            List<RecordTypeInfo> rtInfoList = new List<RecordTypeInfo>();
            rtList = PlaceCPM_Utility.fetchRecordTypeValues(sw.sobjectType);
            Map<Id,RecordType> rtInfoMap = new Map<Id,RecordType>([SELECT Id, Description FROM RecordType WHERE Id IN: rtList.keySet()]);
            for(String rtid : rtList.keySet()){
                RecordTypeInfo rtinfo = new RecordTypeInfo();
                rtinfo.rtId = rtid;
                rtInfo.rtName = rtList.get(rtid);
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
            String sessionId = PlaceCPM_Utility.fetchUserSessionId(); //563
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
}

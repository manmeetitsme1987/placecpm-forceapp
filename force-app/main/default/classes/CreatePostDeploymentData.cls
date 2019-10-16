global with sharing class CreatePostDeploymentData implements InstallHandler {
    static List<Assumption__c> assumptions = new List<Assumption__c>();
    
    global void onInstall(InstallContext context) {
      String orgId = UserInfo.getOrganizationId();
        if(context.previousVersion() == null) {
        createAssumption();
        //List<Assumption__c> assumptions = [Select id , Forecast_Duration__c from Assumption__c];
        List<Profit_Loss__c> plsList = new List<Profit_Loss__c>();
        List<Cash_Forecast__c> cashList = new List<Cash_Forecast__c>();
        Boolean isPLPeriodStartDate = false, isPLPeriodEndDate = false, isPLName = false;
        Boolean isCFPeriodStartDate = false, isCFPeriodEndDate = false, isCFName = false;
        if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.PROFIT_LOSS_OBJECT,'Period_Start_Date__c',Constant.ACTION_TYPE_INSERT)){
            isPLPeriodStartDate = true;
        }
        if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.PROFIT_LOSS_OBJECT,'Period_End_Date__c',Constant.ACTION_TYPE_INSERT)){
            isPLPeriodEndDate = true;
        }
        if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.PROFIT_LOSS_OBJECT,'Name',Constant.ACTION_TYPE_INSERT)){
            isPLName = true;
        }
        if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.CASH_FORECAST_OBJECT,'Period_Start_Date__c',Constant.ACTION_TYPE_INSERT)){
            isCFPeriodStartDate = true;
        }
        if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.CASH_FORECAST_OBJECT,'Period_End_Date__c',Constant.ACTION_TYPE_INSERT)){
            isCFPeriodEndDate = true;
        }
        if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.CASH_FORECAST_OBJECT,'Name',Constant.ACTION_TYPE_INSERT)){
            isCFName = true;
        }
        For(Integer i = 0 ; i < assumptions[0].Forecast_Duration__c ; i++){
            Profit_Loss__c pl = new Profit_Loss__c();
            Date startDate = System.today().toStartOfMonth().addMonths(i);
            if(isPLPeriodStartDate){
                pl.Period_Start_Date__c = startDate;
            }
            Integer daysInMonth = Date.daysInMonth(startDate.year() , startDate.month());
            if(isPLPeriodEndDate){
                pl.Period_End_Date__c = startDate.addDays(daysInMonth - 1);
            }
            if(isPLName){
                pl.Name = getMonthName(startDate);
            }
            plsList.add(pl);


            Cash_Forecast__c cash = new Cash_Forecast__c();
            if(isCFPeriodStartDate){
                cash.Period_Start_Date__c = startDate;
            }
            if(isCFPeriodEndDate){
                cash.Period_End_Date__c = startDate.addDays(daysInMonth - 1);
            }
            if(isCFName){
                cash.Name = getMonthName(startDate);
            }
            cashList.add(cash);
        }

        PlaceCPM_Utility.insertRecords(plsList, CONSTANT.PROFIT_LOSS_OBJECT, false);
        PlaceCPM_Utility.insertRecords(cashList, CONSTANT.CASH_FORECAST_OBJECT, false);
        createPLCategory();
        setCustomSettings(orgId);
    }
    }
    private void setCustomSettings(String orgId){
        
        Cash_Statement_Setting__c cashSetting = new Cash_Statement_Setting__c();
        if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.CASH_STATEMENT_CUSTOM_SETTING,'Day_for_week_split__c',Constant.ACTION_TYPE_INSERT)){
            cashSetting.Day_for_week_split__c = 'Fri';
        }
        if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.CASH_STATEMENT_CUSTOM_SETTING,'Greater_than_Min_Amt_Color__c',Constant.ACTION_TYPE_INSERT)){
            cashSetting.Greater_than_Min_Amt_Color__c = 'White';
        }
        if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.CASH_STATEMENT_CUSTOM_SETTING,'Less_than_Min_Amount_Color__c',Constant.ACTION_TYPE_INSERT)){
            cashSetting.Less_than_Min_Amount_Color__c = 'White';
        }
        if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.CASH_STATEMENT_CUSTOM_SETTING,'Less_than_Min_Balance_Color__c',Constant.ACTION_TYPE_INSERT)){
            cashSetting.Less_than_Min_Balance_Color__c = 'White';
        }
        if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.CASH_STATEMENT_CUSTOM_SETTING,'Minimum_Surplus_Amount__c',Constant.ACTION_TYPE_INSERT)){
            cashSetting.Minimum_Surplus_Amount__c = 5000.00;
        }
        if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.CASH_STATEMENT_CUSTOM_SETTING,'setupOwnerid',Constant.ACTION_TYPE_INSERT)){
            cashSetting.setupOwnerid = orgId;
        }

        PlaceCPM_Utility.insertRecords(new List<Cash_Statement_Setting__c>{cashSetting}, CONSTANT.CASH_STATEMENT_CUSTOM_SETTING, false);
        
        PlaceCPM_AdminSetting__c adminSetting = new PlaceCPM_AdminSetting__c();

        if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.ADMIN_CUSTOM_SETTING,'EnableDebugLog__c',Constant.ACTION_TYPE_INSERT)){
            adminSetting.EnableDebugLog__c = true;
        }
        if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.ADMIN_CUSTOM_SETTING,'PLandCashBatchFrequency__c',Constant.ACTION_TYPE_INSERT)){
            adminSetting.PLandCashBatchFrequency__c = 50;
        }
        if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.ADMIN_CUSTOM_SETTING,'setupOwnerid',Constant.ACTION_TYPE_INSERT)){
            adminSetting.setupOwnerid = orgId;
        }
         PlaceCPM_Utility.insertRecords(new List<PlaceCPM_AdminSetting__c>{adminSetting}, CONSTANT.ADMIN_CUSTOM_SETTING, false);
    }


    private static String getMonthName(Date dateToGetName){
        Integer year = dateToGetName.year();
        Integer month = dateToGetName.month();
        String monthAndYear;
         switch on month {
                when 1 {
                    monthAndYear =  'January';
                }   
                when 2 {
                    monthAndYear =  'February';
                }
                when 3 {
                    monthAndYear =  'March';
                }
                when 4 {
                    monthAndYear =  'April';
                }
                when 5 {
                    monthAndYear =  'May';
                }
                when 6 {
                    monthAndYear =  'June';
                }
                when 7 {
                    monthAndYear =  'July';
                }
                when 8 {
                    monthAndYear =  'August';
                }
                when 9 {
                    monthAndYear =  'September';
                }
                when 10 {
                    monthAndYear =  'October';
                }
                when 11 {
                    monthAndYear =  'November';
                }
                when 12 {
                    monthAndYear =  'December';
                }
            }
        monthAndYear += ' ';
        monthAndYear += year;
        return monthAndYear;
    }


    private static void createAssumption(){
        List<Assumption__c> assumptionsNew = [Select id from Assumption__c limit 1];
        if(assumptionsNew.size() == 0){
            Assumption__c assumption = new Assumption__c();
            if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.ASSUMPTION_OBJECT,'Forecasting_Quota__c',Constant.ACTION_TYPE_INSERT)){
                assumption.Forecasting_Quota__c = 80;
            }
            if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.ASSUMPTION_OBJECT,'Average_License_Price__c',Constant.ACTION_TYPE_INSERT)){
                assumption.Average_License_Price__c = 105;
            }
            if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.ASSUMPTION_OBJECT,'Forecast_Duration__c',Constant.ACTION_TYPE_INSERT)){
                assumption.Forecast_Duration__c = 24;
            }
            if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.ASSUMPTION_OBJECT,'Contract_Period__c',Constant.ACTION_TYPE_INSERT)){
                assumption.Contract_Period__c = 12;
            }
            if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.ASSUMPTION_OBJECT,'Recurring_Revenue_Billing_Cycle__c',Constant.ACTION_TYPE_INSERT)){
                assumption.Recurring_Revenue_Billing_Cycle__c = '1';
            }
            if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.ASSUMPTION_OBJECT,'Discounted_Receipts__c',Constant.ACTION_TYPE_INSERT)){
                assumption.Discounted_Receipts__c = 10;
            }
            if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.ASSUMPTION_OBJECT,'Hours_Per_day__c',Constant.ACTION_TYPE_INSERT)){
                assumption.Hours_Per_day__c = 8;
            }
            assumptions.add(assumption);
            PlaceCPM_Utility.insertRecords(assumptions, CONSTANT.ASSUMPTION_OBJECT, false);
        }
    }


    private static void createPLCategory(){
        List<P_L_Category__c> plCategoryList = new List<P_L_Category__c>();
        P_L_Category__c plCategory;
        List<GL_Code__c> glCodeList = new List<GL_Code__c>();
        
        Map<String , String> catAndTypeMap = new Map<String , String>();
        catAndTypeMap.put('REVENUE' , 'Revenue' + ':' + 1);
        catAndTypeMap.put('COGS' , 'Expense'+ ':' + 2);
        catAndTypeMap.put('OPS AND SALES WAGES' , 'Expense'+ ':' + 3);
        catAndTypeMap.put('GENERAL AND ADMIN' , 'Expense'+ ':' + 4);
        catAndTypeMap.put('OTHER INCOME AND EXPENSES' , 'Expense'+ ':' + 5);
        
        Map<String ,  List<String>> catAndAccounts = new Map<String ,  List<String>>();
        List<String> accountAndCat;
        accountAndCat = new List<String>();
        accountAndCat.add('Channel Revenue'+ ':' + 430+ ':' + 1);
        accountAndCat.add('Intercompany Income'+ ':' + 440+ ':' + 2);
        accountAndCat.add('Other Revenue'+ ':' + 450+ ':' + 3);
        accountAndCat.add('Recurring'+ ':' + 400+ ':' + 4);
        accountAndCat.add('Time & Materials'+ ':' + 410 + ':' + 5);
        catAndAccounts.put('REVENUE' , accountAndCat);
        
        accountAndCat = new List<String>();
        accountAndCat.add('Recurring Cost of Goods Sold'+ ':' + 500  + ':' + 1);
        accountAndCat.add('Transfer Pricing Cost'+ ':' + 510 + ':' + 2);
        accountAndCat.add('Hosting'+ ':' + 520 + ':' + 3);
        accountAndCat.add('Third Party Partner Fees'+ ':' + 530 + ':' + 5);
        accountAndCat.add('Client Reimbursable Expenses'+ ':' + 540 + ':' + 6);
        accountAndCat.add('Foreign Exchange (Withholding Tax)'+ ':' + 550 + ':' + 7);
        catAndAccounts.put('COGS' , accountAndCat);
        
        accountAndCat = new List<String>();
        accountAndCat.add('Ops Wages & Salaries' + ':' + 667 + ':' + 1);
        accountAndCat.add('Sales Wages & Salaries' + ':' + 668 + ':' + 2);
        accountAndCat.add('Sales Incentives' + ':' + 669 + ':' + 3);
        catAndAccounts.put('OPS AND SALES WAGES' , accountAndCat);
        
        accountAndCat = new List<String>();
        accountAndCat.add('Advertising' + ':' + 600 + ':' + 1);
        accountAndCat.add('Bad Debt Expense' + ':' + 690 + ':' + 2);
        accountAndCat.add('Blueprint Expenses' + ':' + 691 + ':' + 3);
        accountAndCat.add('Charitable Contributions' + ':' + 644 + ':' + 4);
        accountAndCat.add('Client Gifts' + ':' + 648+ ':' + 5) ;
        accountAndCat.add('Dues and Subscriptions' + ':' + 676+ ':' + 6);
        accountAndCat.add('General Expenses' + ':' + 628+ ':' + 7);
        accountAndCat.add('Income Tax Expense' + ':' + 710+ ':' + 8);
        accountAndCat.add('Insurance' + ':' + 632+ ':' + 9);
        accountAndCat.add('Internal I Costs' + ':' + 608+ ':' + 10);
        accountAndCat.add('Office Expenses' + ':' + 640+ ':' + 11);
        accountAndCat.add('Payroll Tax Expense' + ':' + 672+ ':' + 12);
        accountAndCat.add('Professional Development & Incentives' + ':' + 664+ ':' + 13);
        accountAndCat.add('Professional Fees' + ':' + 612+ ':' + 14);
        accountAndCat.add('Recruiting' + ':' + 656+ ':' + 15);
        accountAndCat.add('Rent' + ':' + 660+ ':' + 16);
        accountAndCat.add('Research & Development' + ':' + 665+ ':' + 17);
        accountAndCat.add('Telephone & Internet' + ':' + 680+ ':' + 18);
        accountAndCat.add('Travel' + ':' + 684+ ':' + 19);
        catAndAccounts.put('GENERAL AND ADMIN' , accountAndCat);
        accountAndCat = new List<String>();
        accountAndCat.add('Depreciation Expense' + ':' + 700 + ':' + 1);
        accountAndCat.add('Bank Service Charges' + ':' + 604 + ':' + 2);
        accountAndCat.add('Interest Expense' + ':' + 800 + ':' + 3);
        catAndAccounts.put('OTHER INCOME AND EXPENSES' , accountAndCat);
        String[] temp;
        Boolean isPLCatName = false, isPLCatType = false, isPLCatSequence = false;
		if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.PL_CATEGORY_OBJECT,'Name',Constant.ACTION_TYPE_INSERT)){
            isPLCatName = true;
        }
        if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.PL_CATEGORY_OBJECT,'Type__c',Constant.ACTION_TYPE_INSERT)){
            isPLCatType = true;
        }
        if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.PL_CATEGORY_OBJECT,'Sequence__c',Constant.ACTION_TYPE_INSERT)){
            isPLCatSequence = true;
        }
        For(String key : catAndTypeMap.keySet()){
           plCategory = new P_L_Category__c();
           if(isPLCatName){
                plCategory.Name = key;
           }
           temp = catAndTypeMap.get(key).split(':');
           if(isPLCatType){
                plCategory.Type__c = temp[0];
           }
           if(isPLCatSequence){
                plCategory.Sequence__c = Integer.valueOf(temp[1]);
           }
           plCategoryList.add(plCategory);
        }

        PlaceCPM_Utility.insertRecords(plCategoryList, CONSTANT.PL_CATEGORY_OBJECT, false);
        
        
       // List<P_L_Category__c> plclist = [Select id , Name from P_L_Category__c];
        Map<String , Id> plcNameAndId = new Map<String , Id>();
        For(P_L_Category__c plc : plCategoryList){
            plcNameAndId.put(plc.Name , plc.Id);
        }
        Boolean isNameCreatable = false, isPLCategoryA = false, isPLCategoryB = false, isOperatorCreatable = false;
        if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.PL_CATEGORY_OBJECT,'Name',Constant.ACTION_TYPE_INSERT)){
            isNameCreatable = true;
        }
            isPLCategoryA = true;
            isPLCategoryB = true;
            isOperatorCreatable = true;

        List<P_L_Formula__c> formulaList = new List<P_L_Formula__c>();
        P_L_Formula__c plf = new P_L_Formula__c();
        if(isNameCreatable){
            plf.Name = 'GROSS PROFIT';
        }
        if(isPLCategoryA){
            plf.P_L_Category_A__c = plcNameAndId.get('REVENUE');
        }
        if(isPLCategoryB){
            plf.P_L_Category_B__c = plcNameAndId.get('COGS');
        }
        if(isOperatorCreatable){
            plf.Operator__c = '_';
        }
        formulaList.add(plf);


        P_L_Formula__c plf1 = new P_L_Formula__c();
        if(isNameCreatable){
            plf1.Name = 'GROSS CONTRIBUTION';
        }
        if(isPLCategoryA){
            plf1.P_L_Formula_A__c = plf.Id;
        }
        if(isPLCategoryB){
            plf1.P_L_Category_B__c = plcNameAndId.get('OPS AND SALES WAGES');
        }
        if(isOperatorCreatable){
            plf1.Operator__c = '_';
        }
        formulaList.add(plf1);


        P_L_Formula__c plf2 = new P_L_Formula__c();
        if(isNameCreatable){
            plf2.Name = 'EBITDA';
        }
        if(isPLCategoryA){
            plf2.P_L_Formula_A__c = plf1.Id;
        }
        if(isPLCategoryB){
            plf2.P_L_Category_B__c = plcNameAndId.get('GENERAL AND ADMIN');
        }
        if(isOperatorCreatable){
            plf2.Operator__c = '_';
        }
        formulaList.add(plf2);


        P_L_Formula__c plf3 = new P_L_Formula__c();
        if(isNameCreatable){
        plf3.Name = 'NET INCOME';
        }
        if(isPLCategoryA){
        plf3.P_L_Formula_A__c = plf2.Id;
        }
        if(isPLCategoryB){
            plf3.P_L_Category_B__c = plcNameAndId.get('OTHER INCOME AND EXPENSES');
        }
        if(isOperatorCreatable){
            plf3.Operator__c = '_';
        }
        formulaList.add(plf3);


        PlaceCPM_Utility.insertRecords(formulaList, CONSTANT.PL_FORMULA_OBJECT, false);
        
        GL_Code__c glc;
        String[] glcTempArr;
        Boolean isGLName = false, isGLCode = false, isGLSequence = false, isGLPLCategory = false;
        if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.GL_CODE_OBJECT,'Name',Constant.ACTION_TYPE_INSERT)){
            isGLName = false;
        }
        if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.GL_CODE_OBJECT,'GL_Code__c',Constant.ACTION_TYPE_INSERT)){
            isGLCode = true;
        }
        if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.GL_CODE_OBJECT,'Sequence__c',Constant.ACTION_TYPE_INSERT)){
            isGLSequence = true;
        }
        if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.GL_CODE_OBJECT,'PL_Category__c',Constant.ACTION_TYPE_INSERT)){
            isGLPLCategory = true;
        }
        For(P_L_Category__c plc : plCategoryList){
            For(String glcString : catAndAccounts.get(plc.Name)){
                glc = new GL_Code__c();
                glcTempArr = glcString.split(':');
                if(isGLName){
                    glc.Name = glcTempArr[0];
                }
                if(isGLCode){
                    glc.GL_Code__c = Integer.valueOf(glcTempArr[1]);
                }
                if(isGLSequence){
                    glc.Sequence__c = Integer.valueOf(glcTempArr[2]);
                }
                if(isGLPLCategory){
                    glc.PL_Category__c = plc.Id;
                }
                glCodeList.add(glc);
            }
        }
        PlaceCPM_Utility.insertRecords(glCodeList, CONSTANT.GL_CODE_OBJECT, false);
    }
}


/*public with sharing class CreatePostDeploymentData {
    public static void createData() {
        createAssumption();
        List<Assumption__c> assumptions = [Select id , Forecast_Duration__c from Assumption__c];
        List<Profit_Loss__c> plsList = new List<Profit_Loss__c>();
        List<Cash_Forecast__c> cashList = new List<Cash_Forecast__c>();
        For(Integer i = 0 ; i < assumptions[0].Forecast_Duration__c ; i++){
            Profit_Loss__c pl = new Profit_Loss__c();
            Date startDate = System.today().toStartOfMonth().addMonths(i);
            pl.Period_Start_Date__c = startDate;
            Integer daysInMonth = Date.daysInMonth(startDate.year() , startDate.month());
            pl.Period_End_Date__c = startDate.addDays(daysInMonth - 1);
            pl.Name = getMonthName(startDate);
            plsList.add(pl);
            Cash_Forecast__c cash = new Cash_Forecast__c();
            cash.Period_Start_Date__c = startDate;
            cash.Period_End_Date__c = startDate.addDays(daysInMonth - 1);
            cash.Name = getMonthName(startDate);
            cashList.add(cash);
        }
        insert plsList;
        insert cashList;
        createPLCategory();
        //Test
    }
     public static void createPLCategory(){
        List<P_L_Category__c> plCategoryList = new List<P_L_Category__c>();
        P_L_Category__c plCategory;
        List<GL_Code__c> glCodeList = new List<GL_Code__c>();
        
        Map<String , String> catAndTypeMap = new Map<String , String>();
        catAndTypeMap.put('REVENUE' , 'Revenue' + ':' + 1);
        catAndTypeMap.put('COGS' , 'Expense'+ ':' + 2);
        catAndTypeMap.put('OPS AND SALES WAGES' , 'Expense'+ ':' + 3);
        catAndTypeMap.put('GENERAL AND ADMIN' , 'Expense'+ ':' + 4);
        catAndTypeMap.put('OTHER INCOME AND EXPENSES' , 'Expense'+ ':' + 5);
        
        Map<String ,  List<String>> catAndAccounts = new Map<String ,  List<String>>();
        List<String> accountAndCat;
        accountAndCat = new List<String>();
        accountAndCat.add('Channel Revenue'+ ':' + 430+ ':' + 1);
        accountAndCat.add('Intercompany Income'+ ':' + 440+ ':' + 2);
        accountAndCat.add('Other Revenue'+ ':' + 450+ ':' + 3);
        accountAndCat.add('Recurring'+ ':' + 400+ ':' + 4);
        accountAndCat.add('Time & Materials'+ ':' + 410 + ':' + 5);
        catAndAccounts.put('REVENUE' , accountAndCat);
        
        accountAndCat = new List<String>();
        accountAndCat.add('Recurring Cost of Goods Sold'+ ':' + 500  + ':' + 1);
        accountAndCat.add('Transfer Pricing Cost'+ ':' + 510 + ':' + 2);
        accountAndCat.add('Hosting'+ ':' + 520 + ':' + 3);
        accountAndCat.add('Third Party Partner Fees'+ ':' + 530 + ':' + 5);
        accountAndCat.add('Client Reimbursable Expenses'+ ':' + 540 + ':' + 6);
        accountAndCat.add('Foreign Exchange (Withholding Tax)'+ ':' + 550 + ':' + 7);
        catAndAccounts.put('COGS' , accountAndCat);
        
        accountAndCat = new List<String>();
        accountAndCat.add('Ops Wages & Salaries' + ':' + 667 + ':' + 1);
        accountAndCat.add('Sales Wages & Salaries' + ':' + 668 + ':' + 2);
        accountAndCat.add('Sales Incentives' + ':' + 669 + ':' + 3);
        catAndAccounts.put('OPS AND SALES WAGES' , accountAndCat);
        
        accountAndCat = new List<String>();
        accountAndCat.add('Advertising' + ':' + 600 + ':' + 1);
        accountAndCat.add('Bad Debt Expense' + ':' + 690 + ':' + 2);
        accountAndCat.add('Blueprint Expenses' + ':' + 691 + ':' + 3);
        accountAndCat.add('Charitable Contributions' + ':' + 644 + ':' + 4);
        accountAndCat.add('Client Gifts' + ':' + 648+ ':' + 5) ;
        accountAndCat.add('Dues and Subscriptions' + ':' + 676+ ':' + 6);
        accountAndCat.add('General Expenses' + ':' + 628+ ':' + 7);
        accountAndCat.add('Income Tax Expense' + ':' + 710+ ':' + 8);
        accountAndCat.add('Insurance' + ':' + 632+ ':' + 9);
        accountAndCat.add('Internal IT Costs' + ':' + 608+ ':' + 10);
        accountAndCat.add('Office Expenses' + ':' + 640+ ':' + 11);
        accountAndCat.add('Payroll Tax Expense' + ':' + 672+ ':' + 12);
        accountAndCat.add('Professional Development & Incentives' + ':' + 664+ ':' + 13);
        accountAndCat.add('Professional Fees' + ':' + 612+ ':' + 14);
        accountAndCat.add('Recruiting' + ':' + 656+ ':' + 15);
        accountAndCat.add('Rent' + ':' + 660+ ':' + 16);
        accountAndCat.add('Research & Development' + ':' + 665+ ':' + 17);
        accountAndCat.add('Telephone & Internet' + ':' + 680+ ':' + 18);
        accountAndCat.add('Travel' + ':' + 684+ ':' + 19);
        catAndAccounts.put('GENERAL AND ADMIN' , accountAndCat);
        accountAndCat = new List<String>();
        accountAndCat.add('Depreciation Expense' + ':' + 700 + ':' + 1);
        accountAndCat.add('Bank Service Charges' + ':' + 604 + ':' + 2);
        accountAndCat.add('Interest Expense' + ':' + 800 + ':' + 3);
        catAndAccounts.put('OTHER INCOME AND EXPENSES' , accountAndCat);
        String[] temp;
        For(String key : catAndTypeMap.keySet()){
           plCategory = new P_L_Category__c();
           plCategory.Name = key;
           temp = catAndTypeMap.get(key).split(':');
           plCategory.Type__c = temp[0];
           plCategory.Sequence__c = Integer.valueOf(temp[1]);
           plCategoryList.add(plCategory);
        }
        insert plCategoryList;
        
        List<P_L_Category__c> plclist = [Select id , Name from P_L_Category__c];
        Map<String , Id> plcNameAndId = new Map<String , Id>();
        For(P_L_Category__c plc : plclist){
            plcNameAndId.put(plc.Name , plc.Id);
        }
        
        List<P_L_Formula__c> formulaList = new List<P_L_Formula__c>();
        P_L_Formula__c plf = new P_L_Formula__c();
        plf.Name = 'GROSS PROFIT';
        plf.P_L_Category_A__c = plcNameAndId.get('REVENUE');
        plf.P_L_Category_B__c = plcNameAndId.get('COGS');
        formulaList.add(plf);
        P_L_Formula__c plf1 = new P_L_Formula__c();
        plf1.Name = 'GROSS CONTRIBUTION';
        plf1.P_L_Formula_A__c = plf.Id;
        plf1.P_L_Category_B__c = plcNameAndId.get('OPS AND SALES WAGES');
        formulaList.add(plf1);
        P_L_Formula__c plf2 = new P_L_Formula__c();
        plf2.Name = 'EBITDA';
        plf2.P_L_Formula_A__c = plf1.Id;
        plf2.P_L_Category_B__c = plcNameAndId.get('GENERAL AND ADMIN');
        formulaList.add(plf2);
        P_L_Formula__c plf3 = new P_L_Formula__c();
        plf3.Name = 'NET INCOME';
        plf3.P_L_Formula_A__c = plf2.Id;
        plf3.P_L_Category_B__c = plcNameAndId.get('OTHER INCOME AND EXPENSES');
        formulaList.add(plf3);
        insert formulaList;
        
        GL_Code__c glc;
        String[] glcTempArr;
        For(P_L_Category__c plc : plclist){
            For(String glcString : catAndAccounts.get(plc.Name)){
                glc = new GL_Code__c();
                glcTempArr = glcString.split(':');
                glc.Name = glcTempArr[0];
                glc.GL_Code__c = Integer.valueOf(glcTempArr[1]);
                glc.Sequence__c = Integer.valueOf(glcTempArr[2]);
                glc.PL_Category__c = plc.Id;
                glCodeList.add(glc);
            }
        }
        insert glCodeList;
    }
    
    public static void createAssumption(){
        List<Assumption__c> assumptions = [Select id from Assumption__c];
        if(assumptions.size() == 0){
            Assumption__c assumption = new Assumption__c();
            assumption.Forecasting_Quota__c = 80;
            assumption.Average_License_Price__c = 105;
            assumption.Forecast_Duration__c = 24;
            assumption.Contract_Period__c = 12;
            insert assumption;  
        }
    }
    
    public static String getMonthName(Date dateToGetName){
        Integer year = dateToGetName.year();
        Integer month = dateToGetName.month();
        String monthAndYear;
         switch on month {
                when 1 {
                    monthAndYear =  'January';
                }   
                when 2 {
                    monthAndYear =  'February';
                }
                when 3 {
                    monthAndYear =  'March';
                }
                when 4 {
                    monthAndYear =  'April';
                }
                when 5 {
                    monthAndYear =  'May';
                }
                when 6 {
                    monthAndYear =  'June';
                }
                when 7 {
                    monthAndYear =  'July';
                }
                when 8 {
                    monthAndYear =  'August';
                }
                when 9 {
                    monthAndYear =  'September';
                }
                when 10 {
                    monthAndYear =  'October';
                }
                when 11 {
                    monthAndYear =  'November';
                }
                when 12 {
                    monthAndYear =  'December';
                }
            }
        monthAndYear += ' ';
        monthAndYear += year;
        return monthAndYear;
    }
}*/
/*
 * Description  : This class holds all the utility methods for Place CPM product. 
 *                Please write all the functions inside if it is being used more then once in the code.  
 * Date Created : 7th May 2019
*/
public with sharing class PlaceCPM_Utility {
    
    //STATIC Variables
    
    public static Double assumptionAmount = 0;
    public static Decimal assumptionAvgLicenserPrice = 0;
    public static Decimal assumptionDiscountedReciepts = 0;
    public static String assumptionDuration = '';
    public static Integer assumptionForecastDuration = 0;
    public static Decimal assumptionForecastQuota = 0;
    public static Integer assumptionSequence = 0;
    public static Integer contractDuration = 0;
    public static String billingCycle = '';
    public static String assumptionRevenueGLAccount = null; 
    public static Integer assumptionHoursPerDay = 0;
    public static String assumptionPaymentAccount = null;
    public static Map<String, EmployeeRevenueDetailWrapper> empRevDetailWrapper = new Map<String,EmployeeRevenueDetailWrapper>();

    public static PlaceCPM_AdminSetting__c defaultSetting = new PlaceCPM_AdminSetting__c();
    public static Schema.DescribeSObjectResult plSchema = Expense_PL_Allocation__c.sObjectType.getDescribe();
    public static Schema.DescribeSObjectResult cashSchema = Expense_Cash_Allocation__c.sObjectType.getDescribe();
    public static String namespacePrefix = '';
    
    /*
     * Static block to fetch the asumption data
     * 
    */
    static{
        defaultSetting = PlaceCPM_AdminSetting__c.getOrgDefaults(); 
        String[] classNameParts = String.valueOf(PlaceCPM_Utility.class).split('\\.', 2);
        if(classNameParts.size() > 1) {
            Type classType = Type.forName(classNameParts[0], classNameParts[1]);
            if(classType == PlaceCPM_Utility.class) {
                namespacePrefix = classNameParts[0];
            } else {
                namespacePrefix = '';
            }
        } else {
            //If there is only one part, the class has no namespace
            namespacePrefix = '';
        }
        getAssumption();
    }
    
    public static void getAssumption() {
        if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.ASSUMPTION_OBJECT,'id,Amount__c,Average_License_Price__c,Discounted_Receipts__c,Duration__c,'+
                        'Forecast_Duration__c,Revenue_GL_Account__c,Forecasting_Quota__c,Recurring_Revenue_Billing_Cycle__c,Payment_Account__c,Contract_Period__c',Constant.ACTION_TYPE_ACCESS)){
            for(Assumption__c assumption: [Select id, 
                                           Amount__c, 
                                           Average_License_Price__c, 
                                           Discounted_Receipts__c, 
                                           Duration__c, 
                                           Forecast_Duration__c, 
                                           Revenue_GL_Account__c,
                                           Forecasting_Quota__c, 
                                           Recurring_Revenue_Billing_Cycle__c,
                                           Payment_Account__c,
                                           Contract_Period__c from Assumption__c Limit 1]){
                                               assumptionAmount = assumption.Amount__c;
                                               assumptionAvgLicenserPrice = assumption.Average_License_Price__c;
                                               assumptionDiscountedReciepts = assumption.Discounted_Receipts__c;
                                               assumptionDuration = assumption.Duration__c;
                                               assumptionRevenueGLAccount = assumption.Revenue_GL_Account__c;
                                               if(assumption.Forecast_Duration__c != null){
                                                   assumptionForecastDuration = Integer.Valueof(assumption.Forecast_Duration__c);
                                               }
                                               assumptionForecastQuota = assumption.Forecasting_Quota__c;
                                               contractDuration = (Integer)assumption.Contract_Period__c;
                                               billingCycle = (String)assumption.Recurring_Revenue_Billing_Cycle__c;
                                               assumptionPaymentAccount = assumption.Payment_Account__c;
                                           }
    	}        
    }

    /*
     * This method will return all the record type Id for a Record Type Developer Name
     * @parameter objectName, Object Name
     * @parameter strRecordTypeName, Record Type Name of that obejct
     * @returns String
    */
     public static String getRecordTypeIdbyDeveloperName(String objectName, String strRecordTypeName){
       objectName = namespacePrefix != '' ? namespacePrefix + '__' + objectName : objectName;
       Schema.SObjectType objType = Schema.getGlobalDescribe().get(objectName);
       Schema.DescribeSobjectResult objTypeDesc = objType.getDescribe();
       Map<String, Schema.RecordTypeInfo> recTypeMap = objTypeDesc.getrecordtypeinfosbydevelopername();
       Schema.RecordTypeInfo rtByName =  recTypeMap.get(strRecordTypeName);
       if(rtByName != null){
           return  rtByName.getRecordTypeId();
       }else{ return null;}
   }

   /*
     * This method will return all the record type Name for a Record Type Id
     * @parameter objectName, Object Name
     * @parameter strRecordTypeName, Record Type Id
     * @returns String
   */
   public static String getRecordTypeNameById(String objectName, Id strRecordTypeId){
       objectName = namespacePrefix != '' ? namespacePrefix + '__' + objectName : objectName;
       Schema.SObjectType objType = Schema.getGlobalDescribe().get(objectName);
       Schema.DescribeSobjectResult objTypeDesc = objType.getDescribe();
       Map<Id, Schema.RecordTypeInfo> recTypeMap = objTypeDesc.getRecordTypeInfosById();
       Schema.RecordTypeInfo rtById =  recTypeMap.get(strRecordTypeId);
       if(rtById != null){
           return  rtById.getName();
       }else{ return null;}
   }
    
  /*
     * This method be used to debug the code when running inside subscriber org.
     * @parameter str, String which needs to be displayed as a part of log
     * @returns void
   */
    public static void debugLog(String str){
        if(defaultSetting.EnableDebugLog__c){
            system.debug(str);
        }
    }

    /*
     * This method will be used to get the Month number on the basis of a String
     * @parameter month, Month String
     * @returns Integer
   */
    public static Integer getMonthInNumber(String month){
        if(month=='January'){
            return 1;
        }else if(month=='February'){
            return 2;
        }else if(month=='March'){
            return 3;
        }else if(month=='April'){
            return 4;
        }else if(month=='May'){
            return 5;
        }else if(month=='June'){
            return 6;
        }else if(month=='July'){
            return 7;
        }else if(month=='August'){
            return 8;
        }else if(month=='September'){
            return 9;
        }else if(month=='October'){
            return 10;
        }else if(month=='November'){
            return 11;
        }else if(month=='December'){
            return 12;
        }
        return null;
    } 

    /*
     * This method will be used to get the Month Name on the basis of a Integer
     * @parameter Integer, Month value
     * @returns String
   */
    public static string getMonthString(Integer month){
        if(month==1){
            return 'January';
        }else if(month==2){
            return 'February';
        }else if(month==3){
            return 'March';
        }else if(month==4){
            return 'April';
        }else if(month==5){
            return 'May';
        }else if(month==6){
            return 'June';
        }else if(month==7){
            return 'July';
        }else if(month==8){
            return 'August';
        }else if(month==9){
            return 'September';
        }else if(month==10){
            return 'October';
        }else if(month==11){
            return 'November';
        }else if(month==12){
            return 'December';
        }
        return null;
    }

    /*
     * This method is used for getting the PL Records
     * @parameter monthNames, Set<String> holds the String of month names
     * @returns Map<String, Profit_Loss__c>
   */
    public static Map<String, Profit_Loss__c> getPLRecords(Set<String> monthNames){
        Map<String, Profit_Loss__c> tempPLRecordsMap = new Map<String, Profit_Loss__c>();
        if(monthNames != null && monthNames.size()>0){
            list<Profit_Loss__c> plRecords;
            if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.PROFIT_LOSS_OBJECT,'Period_Start_Date__c',Constant.ACTION_TYPE_ACCESS)){
            	plRecords = [Select Id, Name, Period_Start_Date__c From Profit_Loss__c Where Name IN: monthNames];
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
    
    /*
     * This method is used for getting the Cash Forecast Records
     * @parameter monthNames, Set<String> holds the String of month names
     * @returns Map<String, Cash_Forecast__c>
   */
    public static Map<String, Cash_Forecast__c> getCashForecastRecords(Set<String> monthNames){
        system.debug('### monthNames Size: '+monthNames.size());
        map<String, Cash_Forecast__c> tempCashRecordsMap = new map<String, Cash_Forecast__c>();
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

    /*
     * This method is used for creating the PL records
     * @parameter startDateList, List of Dates
     * @parameter isInsert, boolean
     * @returns List<Profit_Loss__c>
   */
    public static List<Profit_Loss__c> createPL(List<Date> startDateList , boolean isInsert){
        List<Profit_Loss__c> plsList = new List<Profit_Loss__c>();
        Boolean isPeriodStartDate = false, isPeriodEndDate = false, isName = false;
        if(Schema.sObjectType.Profit_Loss__c.fields.Period_Start_Date__c.isCreateable()){
            isPeriodStartDate = true;
        }
        if(Schema.sObjectType.Profit_Loss__c.fields.Period_End_Date__c.isCreateable()){
            isPeriodEndDate = true;
        }
        if(Schema.sObjectType.Profit_Loss__c.fields.Name.isCreateable()){
            isName = true;
        }
        
        For(Date plDate : startDateList){
            Profit_Loss__c pl = new Profit_Loss__c();
            if(isPeriodStartDate){
                pl.Period_Start_Date__c = plDate;
            }
            Integer daysInMonth = Date.daysInMonth(plDate.year() , plDate.month());
            if(isPeriodEndDate){
                pl.Period_End_Date__c = plDate.addDays(daysInMonth - 1);
            }
            if(isName){
                pl.Name = getMonthName(plDate);
            }
            plsList.add(pl);
        }
        if(isInsert){
            PlaceCPM_Utility.insertRecords(plsList, CONSTANT.PROFIT_LOSS_OBJECT, false);//520
        }
        return plsList;
    }
    
    /*
     * This method is used for creating the Cash records
     * @parameter startDateList, List of Dates
     * @parameter isInsert, boolean
     * @returns List<Cash_Forecast__c>
   */
    public static List<Cash_Forecast__c> createCash(List<Date> startDateList , boolean isInsert){
        List<Cash_Forecast__c> cashList = new List<Cash_Forecast__c>();
        Boolean isPeriodStartDate = false, isPeriodEndDate = false, isName = false;
        if(Schema.sObjectType.Cash_Forecast__c.fields.Period_Start_Date__c.isCreateable()){
            isPeriodStartDate = true;
        }
        if(Schema.sObjectType.Cash_Forecast__c.fields.Period_End_Date__c.isCreateable()){
            isPeriodEndDate = true;
        }
        if(Schema.sObjectType.Cash_Forecast__c.fields.Name.isCreateable()){
            isName = true;
        }
        
        For(Date cashDate : startDateList){
            Cash_Forecast__c cash = new Cash_Forecast__c();
            if(isPeriodStartDate){
                cash.Period_Start_Date__c = cashDate;
            }
            Integer daysInMonth = Date.daysInMonth(cashDate.year() , cashDate.month());
            if(isPeriodEndDate){
                cash.Period_End_Date__c = cashDate.addDays(daysInMonth - 1);
            }
            if(isName){
                cash.Name = getMonthName(cashDate);
            }
            cashList.add(cash);
        }
        if(isInsert){
            PlaceCPM_Utility.insertRecords(cashList, CONSTANT.CASH_FORECAST_OBJECT, false); //520
        }
        return cashList;
    }
    
    /*
     * This method is used for getting the month name on the basis of Date
     * @parameter dateToGetName, Date
     * @returns String
   */
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
    

    /*
     * This method is used for creating the Formulas on PL statement
     * @parameter 
     * @returns Set<P_L_Statement__c>
   */
    public static Set<P_L_Statement__c> createTotalAndFormulaPlStatement(){
        List<P_L_Statement__c> totalPlList = new List<P_L_Statement__c>();
        List<P_L_Statement__c> categoryPlList = new List<P_L_Statement__c>();
        List<P_L_Statement__c> pltypeFormulaList = new List<P_L_Statement__c>();
        if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.PL_STATEMENT_OBJECT,'Type__c ,  Year__c , '+
                                       'January__c , February__c , March__c , April__c ,May__c , June__c , July__c , August__c , September__c , October__c ,November__c , December__c ,' +
                                       'GL_Code__c, Sequence__c,January_Actual__c , February_Actual__c , March_Actual__c , April_Actual__c , May_Actual__c , '+
                                       'June_Actual__c , July_Actual__c , August_Acutal__c , September_Acutal__c , October_Actual__c ,November_Actual__c , December_Actual__c',Constant.ACTION_TYPE_ACCESS) &&
          PlaceCPM_Utility.checkAccessiblityOfFields(Constant.GL_CODE_OBJECT,'PL_Category__c',Constant.ACTION_TYPE_ACCESS) &&
          PlaceCPM_Utility.checkAccessiblityOfFields(Constant.PL_CATEGORY_OBJECT,'Sequence__c',Constant.ACTION_TYPE_ACCESS)
          ){
            For(P_L_Statement__c pl : [SELECT id , GL_Code__r.PL_Category__r.Sequence__c , GL_Code__r.PL_Category__r.Name , Type__c ,  Year__c , January__c , February__c , March__c , April__c ,
                                       May__c , June__c , July__c , August__c , September__c , October__c , 
                                       November__c , December__c , GL_Code__c, Sequence__c, GL_Code__r.PL_Category__c ,
                                       January_Actual__c , February_Actual__c , March_Actual__c , April_Actual__c , May_Actual__c , 
                                       June_Actual__c , July_Actual__c , August_Acutal__c , September_Acutal__c , October_Actual__c , 
                                       November_Actual__c , December_Actual__c From P_L_Statement__c where Type__c != null] ){
                                           if(pl.Type__c == 'Total'){
                                               totalPlList.add(pl);
                                           }
                                           else if(pl.Type__c == 'Category'){
                                               categoryPlList.add(pl);
                                           }
                                           else if(pl.Type__c == 'Formula'){
                                               pltypeFormulaList.add(pl);
                                           }
                                       }
        }
        PlaceCPM_Utility.deleteRecords(totalPlList, CONSTANT.P_L_STATEMENT_OBJECT, false); //520
        totalPlList.clear();
        PlaceCPM_Utility.deleteRecords(pltypeFormulaList, CONSTANT.P_L_STATEMENT_OBJECT, false); //520
        pltypeFormulaList.clear();
        
        List<P_L_Formula__c> allPLFormulas;
        if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.PL_FORMULA_OBJECT,'P_L_Category_A__c, P_L_Category_B__c',Constant.ACTION_TYPE_ACCESS) &&
          PlaceCPM_Utility.checkAccessiblityOfFields(Constant.PL_CATEGORY_OBJECT,'Sequence__c',Constant.ACTION_TYPE_ACCESS)){
            allPLFormulas = [SELECT id, Name, P_L_Category_A__c, P_L_Category_B__c, 
                                                  P_L_Category_A__r.Sequence__c, P_L_Category_B__r.Sequence__c 
                                                  FROM P_L_Formula__c where Operator__c != null];
        }    
        Map<String , P_L_Formula__c> plsTypeAndFormula = new Map<String , P_L_Formula__c>();
        for(P_L_Formula__c plf:allPLFormulas){
            if(!plsTypeAndFormula.containsKey(plf.Name)){
                plsTypeAndFormula.put(plf.Name, plf);
            }
        }
        List<GL_Code__c> allGLAccounts;
        if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.GL_CODE_OBJECT,'Sequence__c',Constant.ACTION_TYPE_ACCESS)){
        	allGLAccounts = [SELECT Id, Pl_Category__c, Sequence__c from GL_Code__c where PL_Category__c != null];
        }    
        Map<Id , List<GL_Code__c>> categoryIdAndGLAccountList = new Map<Id , List<GL_Code__c>>();
        for(GL_Code__c glAcc:allGLAccounts){
            if(!categoryIdAndGLAccountList.containsKey(glAcc.Pl_Category__c)){
                categoryIdAndGLAccountList.put(glAcc.Pl_Category__c, new List<GL_Code__c>());
            }
            categoryIdAndGLAccountList.get(glAcc.Pl_Category__c).add(glAcc);
        }
        
        Map<Id , Decimal> categoryIdAndMaxGLSequence = new Map<Id , Decimal>();
        for(Id plcId: categoryIdAndGLAccountList.keySet()){
            Decimal sequence=1;
            for(GL_Code__c gl:categoryIdAndGLAccountList.get(plcId)){
                if(sequence < gl.Sequence__c){
                    sequence = gl.Sequence__c;
                }
            }
            categoryIdAndMaxGLSequence.put(plcId, sequence);
        }

        Map<String , P_L_Statement__c> plSectionAndMonthTotal = new Map<String , P_L_Statement__c>();
        For(P_L_Statement__c pls : categoryPlList){
            String mapkey = pls.Year__c + ':' + pls.GL_Code__r.PL_Category__c;
            P_L_Statement__c wrapper;
            if(!plSectionAndMonthTotal.containsKey(mapkey)){
                wrapper = new P_L_Statement__c();
            }
            else{
                wrapper = plSectionAndMonthTotal.get(mapkey);
            }
            wrapper.January__c = wrapper.January__c != Null ? (pls.January__c != Null ? pls.January__c : 0) + wrapper.January__c : pls.January__c;
            wrapper.January_Actual__c = wrapper.January_Actual__c != Null ? (pls.January_Actual__c != Null ? pls.January_Actual__c : 0) + wrapper.January_Actual__c : pls.January_Actual__c;
            
            wrapper.February__c = wrapper.February__c != Null ? (pls.February__c != Null ? pls.February__c : 0)+ wrapper.February__c : pls.February__c;
            wrapper.February_Actual__c = wrapper.February_Actual__c != Null ? (pls.February_Actual__c != Null ? pls.February_Actual__c : 0)+ wrapper.February_Actual__c : pls.February_Actual__c;

            wrapper.March__c = wrapper.March__c != Null ? (pls.March__c != Null ? pls.March__c : 0)+ wrapper.March__c : pls.March__c;
            wrapper.March_Actual__c = wrapper.March_Actual__c != Null ? (pls.March_Actual__c != Null ? pls.March_Actual__c : 0)+ wrapper.March_Actual__c : pls.March_Actual__c;
            
            wrapper.April__c = wrapper.April__c != Null ? (pls.April__c != Null ? pls.April__c : 0) + wrapper.April__c : pls.April__c;
            wrapper.April_Actual__c = wrapper.April_Actual__c != Null ? (pls.April_Actual__c != Null ? pls.April_Actual__c : 0) + wrapper.April_Actual__c : pls.April_Actual__c;
            
            wrapper.May__c = wrapper.May__c != Null ? (pls.May__c != Null ? pls.May__c : 0) + wrapper.May__c : pls.May__c;
            wrapper.May_Actual__c = wrapper.May_Actual__c != Null ? (pls.May_Actual__c != Null ? pls.May_Actual__c : 0) + wrapper.May_Actual__c : pls.May_Actual__c;
            
            wrapper.June__c = wrapper.June__c != Null ? (pls.June__c != Null ? pls.June__c : 0) + wrapper.June__c : pls.June__c;
            wrapper.June_Actual__c = wrapper.June_Actual__c != Null ? (pls.June_Actual__c != Null ? pls.June_Actual__c : 0) + wrapper.June_Actual__c : pls.June_Actual__c;
            
            wrapper.July__c = wrapper.July__c != Null ? (pls.July__c != Null ? pls.July__c : 0) + wrapper.July__c : pls.July__c;
            wrapper.July_Actual__c = wrapper.July_Actual__c != Null ? (pls.July_Actual__c != Null ? pls.July_Actual__c : 0) + wrapper.July_Actual__c : pls.July_Actual__c;
            
            wrapper.August__c = wrapper.August__c != Null ? (pls.August__c != Null ? pls.August__c : 0) + wrapper.August__c : pls.August__c;
            wrapper.August_Acutal__c = wrapper.August_Acutal__c != Null ? (pls.August_Acutal__c != Null ? pls.August_Acutal__c : 0) + wrapper.August_Acutal__c : pls.August_Acutal__c;
            
            wrapper.September__c = wrapper.September__c != Null ? (pls.September__c != Null ? pls.September__c : 0) + wrapper.September__c : pls.September__c;
            wrapper.September_Acutal__c = wrapper.September_Acutal__c != Null ? (pls.September_Acutal__c != Null ? pls.September_Acutal__c : 0) + wrapper.September_Acutal__c : pls.September_Acutal__c;
            
            wrapper.October__c = wrapper.October__c != Null ? (pls.October__c != Null ? pls.October__c : 0) + wrapper.October__c : pls.October__c;
            wrapper.October_Actual__c = wrapper.October_Actual__c != Null ? (pls.October_Actual__c != Null ? pls.October_Actual__c : 0) + wrapper.October_Actual__c : pls.October_Actual__c;

            wrapper.November__c = wrapper.November__c != Null ? (pls.November__c != Null ? pls.November__c : 0) + wrapper.November__c : pls.November__c;
            wrapper.November_Actual__c = wrapper.November_Actual__c != Null ? (pls.November_Actual__c != Null ? pls.November_Actual__c : 0) + wrapper.November_Actual__c : pls.November_Actual__c;
            
            wrapper.December__c = wrapper.December__c != Null ? (pls.December__c != Null ? pls.December__c : 0) + wrapper.December__c : pls.December__c;
            wrapper.December_Actual__c = wrapper.December_Actual__c != Null ? (pls.December_Actual__c != Null ? pls.December_Actual__c : 0) + wrapper.December_Actual__c : pls.December_Actual__c;

            wrapper.Type__c = 'Total';
            wrapper.P_L_Category__c =  pls.GL_Code__r.PL_Category__c;
            wrapper.Year__c = pls.Year__c;
            if(wrapper.Type__c == 'Total'){
                switch on pls.GL_Code__r.PL_Category__r.Name {
                    when 'GENERAL AND ADMIN' {
                        wrapper.Type_Label__c = 'TOTAL G&A';
                    }   
                    when 'COGS' {
                        wrapper.Type_Label__c = 'TOTAL COGS';
                    }
                    when 'OPS AND SALES WAGES' {
                        wrapper.Type_Label__c = 'TOTAL OPS & SALES WAGES';
                    }
                    when 'OTHER INCOME AND EXPENSES' {
                        wrapper.Type_Label__c = 'TOTAL OTHER INCOME AND EXPENSES';
                    }
                    when 'REVENUE' {
                        wrapper.Type_Label__c = 'TOTAL REVENUES';
                    }
                    when else{
                        wrapper.Type_Label__c = 'TOTAL ' + pls.GL_Code__r.PL_Category__r.Name ;
                    }
                }
            }
            if(categoryIdAndMaxGLSequence.containsKey(pls.GL_Code__r.PL_Category__c)){
                wrapper.Sequence__c = Integer.valueOf(pls.GL_Code__r.PL_Category__r.Sequence__c)+ ((categoryIdAndMaxGLSequence.get(pls.GL_Code__r.PL_Category__c)+1)/100);
            }
            plSectionAndMonthTotal.put(mapkey , wrapper);
        }

        PlaceCPM_Utility.insertRecords(plSectionAndMonthTotal.values(), CONSTANT.P_L_STATEMENT_OBJECT, false); //520
        
        totalPlList = plSectionAndMonthTotal.values();
        Map<String , P_L_Statement__c> totalTypeAndPLMap = new Map<String , P_L_Statement__c>();
        Set<P_L_Statement__c> formulaPLS = new Set<P_L_Statement__c>();
        Map<String , P_L_Statement__c> catAndTotal = new Map<String , P_L_Statement__c>();
        For(P_L_Statement__c pls : plSectionAndMonthTotal.values()){
            totalTypeAndPLMap.put(pls.Type_Label__c + ':' + pls.Year__c , pls);
        }
        For(P_L_Statement__c pls : totalPlList){
            P_L_Statement__c grossProfitWrapper = new P_L_Statement__c();
            String revenueKey = 'TOTAL REVENUES'+ ':' + pls.Year__c;
            String cogsKey = 'TOTAL COGS' + ':' + pls.Year__c;
            grossProfitWrapper.January__c = (totalTypeAndPLMap.containsKey(revenueKey) ? (totalTypeAndPLMap.get(revenueKey).January__c != Null ? totalTypeAndPLMap.get(revenueKey).January__c : 0) : 0) - 
                                                (totalTypeAndPLMap.containsKey(cogsKey) ? (totalTypeAndPLMap.get(cogsKey).January__c != Null ? totalTypeAndPLMap.get(cogsKey).January__c : 0) : 0);
            grossProfitWrapper.January_Actual__c = (totalTypeAndPLMap.containsKey(revenueKey) ? (totalTypeAndPLMap.get(revenueKey).January_Actual__c != Null ? totalTypeAndPLMap.get(revenueKey).January_Actual__c : 0) : 0) - 
                                                (totalTypeAndPLMap.containsKey(cogsKey) ? (totalTypeAndPLMap.get(cogsKey).January_Actual__c != Null ? totalTypeAndPLMap.get(cogsKey).January_Actual__c : 0) : 0);
                                
            grossProfitWrapper.February__c = (totalTypeAndPLMap.containsKey(revenueKey) ? (totalTypeAndPLMap.get(revenueKey).February__c != Null ? totalTypeAndPLMap.get(revenueKey).February__c : 0) : 0) - 
                                                (totalTypeAndPLMap.containsKey(cogsKey) ? (totalTypeAndPLMap.get(cogsKey).February__c != Null ? totalTypeAndPLMap.get(cogsKey).February__c : 0) : 0);
            grossProfitWrapper.February_Actual__c = (totalTypeAndPLMap.containsKey(revenueKey) ? (totalTypeAndPLMap.get(revenueKey).February_Actual__c != Null ? totalTypeAndPLMap.get(revenueKey).February_Actual__c : 0) : 0) - 
                                                (totalTypeAndPLMap.containsKey(cogsKey) ? (totalTypeAndPLMap.get(cogsKey).February_Actual__c != Null ? totalTypeAndPLMap.get(cogsKey).February_Actual__c : 0) : 0);
                                                
            grossProfitWrapper.March__c = (totalTypeAndPLMap.containsKey(revenueKey) ? (totalTypeAndPLMap.get(revenueKey).March__c != Null ? totalTypeAndPLMap.get(revenueKey).March__c : 0) : 0) - 
                                                (totalTypeAndPLMap.containsKey(cogsKey) ?  (totalTypeAndPLMap.get(cogsKey).March__c != Null ? totalTypeAndPLMap.get(cogsKey).March__c : 0) : 0);
            grossProfitWrapper.March_Actual__c = (totalTypeAndPLMap.containsKey(revenueKey) ? (totalTypeAndPLMap.get(revenueKey).March_Actual__c != Null ? totalTypeAndPLMap.get(revenueKey).March_Actual__c : 0) : 0) - 
                                                (totalTypeAndPLMap.containsKey(cogsKey) ? (totalTypeAndPLMap.get(cogsKey).March_Actual__c != Null ? totalTypeAndPLMap.get(cogsKey).March_Actual__c : 0) : 0);
            
            grossProfitWrapper.April__c = (totalTypeAndPLMap.containsKey(revenueKey) ? (totalTypeAndPLMap.get(revenueKey).April__c != Null ? totalTypeAndPLMap.get(revenueKey).April__c : 0) : 0) - 
                                                (totalTypeAndPLMap.containsKey(cogsKey) ?  (totalTypeAndPLMap.get(cogsKey).April__c != Null ? totalTypeAndPLMap.get(cogsKey).April__c : 0) : 0);
            grossProfitWrapper.April_Actual__c = (totalTypeAndPLMap.containsKey(revenueKey) ? (totalTypeAndPLMap.get(revenueKey).April_Actual__c != Null ? totalTypeAndPLMap.get(revenueKey).April_Actual__c : 0) : 0) - 
                                                (totalTypeAndPLMap.containsKey(cogsKey) ? (totalTypeAndPLMap.get(cogsKey).April_Actual__c != Null ? totalTypeAndPLMap.get(cogsKey).April_Actual__c : 0) : 0);
            
            grossProfitWrapper.May__c = (totalTypeAndPLMap.containsKey(revenueKey) ? (totalTypeAndPLMap.get(revenueKey).May__c != Null ? totalTypeAndPLMap.get(revenueKey).May__c : 0) : 0) - 
                                                (totalTypeAndPLMap.containsKey(cogsKey) ?  (totalTypeAndPLMap.get(cogsKey).May__c != Null ? totalTypeAndPLMap.get(cogsKey).May__c : 0) : 0);
            grossProfitWrapper.May_Actual__c = (totalTypeAndPLMap.containsKey(revenueKey) ? (totalTypeAndPLMap.get(revenueKey).May_Actual__c != Null ? totalTypeAndPLMap.get(revenueKey).May_Actual__c : 0) : 0) - 
                                                (totalTypeAndPLMap.containsKey(cogsKey) ? (totalTypeAndPLMap.get(cogsKey).May_Actual__c != Null ? totalTypeAndPLMap.get(cogsKey).May_Actual__c : 0) : 0);
            
            grossProfitWrapper.June__c = (totalTypeAndPLMap.containsKey(revenueKey) ? (totalTypeAndPLMap.get(revenueKey).June__c != Null ? totalTypeAndPLMap.get(revenueKey).June__c : 0) : 0) - 
                                                (totalTypeAndPLMap.containsKey(cogsKey) ?  (totalTypeAndPLMap.get(cogsKey).June__c != Null ? totalTypeAndPLMap.get(cogsKey).June__c : 0) : 0);
            grossProfitWrapper.June_Actual__c = (totalTypeAndPLMap.containsKey(revenueKey) ? (totalTypeAndPLMap.get(revenueKey).June_Actual__c != Null ? totalTypeAndPLMap.get(revenueKey).June_Actual__c : 0) : 0) - 
                                                (totalTypeAndPLMap.containsKey(cogsKey) ? (totalTypeAndPLMap.get(cogsKey).June_Actual__c != Null ? totalTypeAndPLMap.get(cogsKey).June_Actual__c : 0) : 0);
            
            grossProfitWrapper.July__c = (totalTypeAndPLMap.containsKey(revenueKey) ? (totalTypeAndPLMap.get(revenueKey).July__c != Null ? totalTypeAndPLMap.get(revenueKey).July__c : 0) : 0) - 
                                                (totalTypeAndPLMap.containsKey(cogsKey) ?  (totalTypeAndPLMap.get(cogsKey).July__c != Null ? totalTypeAndPLMap.get(cogsKey).July__c : 0) : 0);
            grossProfitWrapper.July_Actual__c = (totalTypeAndPLMap.containsKey(revenueKey) ? (totalTypeAndPLMap.get(revenueKey).July_Actual__c != Null ? totalTypeAndPLMap.get(revenueKey).July_Actual__c : 0) : 0) - 
                                                (totalTypeAndPLMap.containsKey(cogsKey) ? (totalTypeAndPLMap.get(cogsKey).July_Actual__c != Null ? totalTypeAndPLMap.get(cogsKey).July_Actual__c : 0) : 0);
            
            grossProfitWrapper.August__c = (totalTypeAndPLMap.containsKey(revenueKey) ? (totalTypeAndPLMap.get(revenueKey).August__c != Null ? totalTypeAndPLMap.get(revenueKey).August__c : 0) : 0) - 
                                                (totalTypeAndPLMap.containsKey(cogsKey) ?  (totalTypeAndPLMap.get(cogsKey).August__c != Null ? totalTypeAndPLMap.get(cogsKey).August__c : 0) : 0);
            grossProfitWrapper.August_Acutal__c = (totalTypeAndPLMap.containsKey(revenueKey) ? (totalTypeAndPLMap.get(revenueKey).August_Acutal__c != Null ? totalTypeAndPLMap.get(revenueKey).August_Acutal__c : 0) : 0) - 
                                                (totalTypeAndPLMap.containsKey(cogsKey) ? (totalTypeAndPLMap.get(cogsKey).August_Acutal__c != Null ? totalTypeAndPLMap.get(cogsKey).August_Acutal__c : 0) : 0);
            
            grossProfitWrapper.September__c =(totalTypeAndPLMap.containsKey(revenueKey) ? (totalTypeAndPLMap.get(revenueKey).September__c != Null ? totalTypeAndPLMap.get(revenueKey).September__c : 0) : 0) - 
                                                (totalTypeAndPLMap.containsKey(cogsKey) ?  (totalTypeAndPLMap.get(cogsKey).September__c != Null ? totalTypeAndPLMap.get(cogsKey).September__c : 0) : 0);
            grossProfitWrapper.September_Acutal__c = (totalTypeAndPLMap.containsKey(revenueKey) ? (totalTypeAndPLMap.get(revenueKey).September_Acutal__c != Null ? totalTypeAndPLMap.get(revenueKey).September_Acutal__c : 0) : 0) - 
                                                (totalTypeAndPLMap.containsKey(cogsKey) ? (totalTypeAndPLMap.get(cogsKey).September_Acutal__c != Null ? totalTypeAndPLMap.get(cogsKey).September_Acutal__c : 0) : 0);
            
            grossProfitWrapper.October__c = (totalTypeAndPLMap.containsKey(revenueKey) ? (totalTypeAndPLMap.get(revenueKey).October__c != Null ? totalTypeAndPLMap.get(revenueKey).October__c : 0) : 0) - 
                                                (totalTypeAndPLMap.containsKey(cogsKey) ?  (totalTypeAndPLMap.get(cogsKey).October__c != Null ? totalTypeAndPLMap.get(cogsKey).October__c : 0) : 0);
            grossProfitWrapper.October_Actual__c = (totalTypeAndPLMap.containsKey(revenueKey) ? (totalTypeAndPLMap.get(revenueKey).October_Actual__c != Null ? totalTypeAndPLMap.get(revenueKey).October_Actual__c : 0) : 0) - 
                                                (totalTypeAndPLMap.containsKey(cogsKey) ? (totalTypeAndPLMap.get(cogsKey).October_Actual__c != Null ? totalTypeAndPLMap.get(cogsKey).October_Actual__c : 0) : 0);
            
            grossProfitWrapper.November__c = (totalTypeAndPLMap.containsKey(revenueKey) ? (totalTypeAndPLMap.get(revenueKey).November__c != Null ? totalTypeAndPLMap.get(revenueKey).November__c : 0) : 0) - 
                                                (totalTypeAndPLMap.containsKey(cogsKey) ?  (totalTypeAndPLMap.get(cogsKey).November__c != Null ? totalTypeAndPLMap.get(cogsKey).November__c : 0) : 0);
            grossProfitWrapper.November_Actual__c = (totalTypeAndPLMap.containsKey(revenueKey) ? (totalTypeAndPLMap.get(revenueKey).November_Actual__c != Null ? totalTypeAndPLMap.get(revenueKey).November_Actual__c : 0) : 0) - 
                                                (totalTypeAndPLMap.containsKey(cogsKey) ? (totalTypeAndPLMap.get(cogsKey).November_Actual__c != Null ? totalTypeAndPLMap.get(cogsKey).November_Actual__c : 0) : 0);
           
            grossProfitWrapper.December__c = (totalTypeAndPLMap.containsKey(revenueKey) ? (totalTypeAndPLMap.get(revenueKey).December__c != Null ? totalTypeAndPLMap.get(revenueKey).December__c : 0) : 0) - 
                                                (totalTypeAndPLMap.containsKey(cogsKey) ?  (totalTypeAndPLMap.get(cogsKey).December__c != Null ? totalTypeAndPLMap.get(cogsKey).December__c : 0) : 0);
            grossProfitWrapper.December_Actual__c = (totalTypeAndPLMap.containsKey(revenueKey) ? (totalTypeAndPLMap.get(revenueKey).December_Actual__c != Null ? totalTypeAndPLMap.get(revenueKey).December_Actual__c : 0) : 0) - 
                                                (totalTypeAndPLMap.containsKey(cogsKey) ? (totalTypeAndPLMap.get(cogsKey).December_Actual__c != Null ? totalTypeAndPLMap.get(cogsKey).December_Actual__c : 0) : 0);
            grossProfitWrapper.Type_Label__c = 'GROSS PROFIT';
            grossProfitWrapper.Year__c = pls.Year__c;
            grossProfitWrapper.Type__c = 'Formula';
            catAndTotal.put('GROSS PROFIT' + ':' + pls.Year__c , grossProfitWrapper);
            if(plsTypeAndFormula.containsKey(grossProfitWrapper.Type_Label__c)){
                if(plsTypeAndFormula.get(grossProfitWrapper.Type_Label__c).P_L_Category_B__r.Sequence__c!=null){
                    grossProfitWrapper.Sequence__c = plsTypeAndFormula.get(grossProfitWrapper.Type_Label__c).P_L_Category_B__r.Sequence__c + 1;
                } else if(plsTypeAndFormula.get(grossProfitWrapper.Type_Label__c).P_L_Category_A__r.Sequence__c!=null){
                    grossProfitWrapper.Sequence__c = plsTypeAndFormula.get(grossProfitWrapper.Type_Label__c).P_L_Category_A__r.Sequence__c + 1;
                }
            }
            formulaPLS.add(grossProfitWrapper);
        }
        
        For(P_L_Statement__c pls : totalPlList){
            P_L_Statement__c grossContributionWrapper = new P_L_Statement__c();
            String grossProfitKey = 'GROSS PROFIT'+ ':' + pls.Year__c;
            String wageKey = 'TOTAL OPS & SALES WAGES' + ':' + pls.Year__c;
            grossContributionWrapper.January__c = (catAndTotal.containsKey(grossProfitKey) ? (catAndTotal.get(grossProfitKey).January__c != Null ? catAndTotal.get(grossProfitKey).January__c : 0) : 0) - 
                                                    (totalTypeAndPLMap.containsKey(wageKey) ? (totalTypeAndPLMap.get(wageKey).January__c != Null ? totalTypeAndPLMap.get(wageKey).January__c : 0) : 0);
            grossContributionWrapper.January_Actual__c = (catAndTotal.containsKey(grossProfitKey) ? (catAndTotal.get(grossProfitKey).January_Actual__c != Null ? catAndTotal.get(grossProfitKey).January_Actual__c : 0) : 0) - 
                                                    (totalTypeAndPLMap.containsKey(wageKey) ? (totalTypeAndPLMap.get(wageKey).January_Actual__c != Null ? totalTypeAndPLMap.get(wageKey).January_Actual__c : 0) : 0);
            
            grossContributionWrapper.February__c = (catAndTotal.containsKey(grossProfitKey) ? (catAndTotal.get(grossProfitKey).February__c != Null ? catAndTotal.get(grossProfitKey).February__c : 0) : 0) - 
                                                    (totalTypeAndPLMap.containsKey(wageKey) ? (totalTypeAndPLMap.get(wageKey).February__c != Null ? totalTypeAndPLMap.get(wageKey).February__c : 0) : 0);
            grossContributionWrapper.February_Actual__c = (catAndTotal.containsKey(grossProfitKey) ? (catAndTotal.get(grossProfitKey).February_Actual__c != Null ? catAndTotal.get(grossProfitKey).February_Actual__c : 0) : 0) - 
                                                    (totalTypeAndPLMap.containsKey(wageKey) ? (totalTypeAndPLMap.get(wageKey).February_Actual__c != Null ? totalTypeAndPLMap.get(wageKey).February_Actual__c : 0) : 0);
            
            grossContributionWrapper.March__c = (catAndTotal.containsKey(grossProfitKey) ? (catAndTotal.get(grossProfitKey).March__c != Null ? catAndTotal.get(grossProfitKey).March__c : 0) : 0) - 
                                                    (totalTypeAndPLMap.containsKey(wageKey) ? (totalTypeAndPLMap.get(wageKey).March__c != Null ? totalTypeAndPLMap.get(wageKey).March__c : 0) : 0);
            grossContributionWrapper.March_Actual__c = (catAndTotal.containsKey(grossProfitKey) ? (catAndTotal.get(grossProfitKey).March_Actual__c != Null ? catAndTotal.get(grossProfitKey).March_Actual__c : 0) : 0) - 
                                                    (totalTypeAndPLMap.containsKey(wageKey) ? (totalTypeAndPLMap.get(wageKey).March_Actual__c != Null ? totalTypeAndPLMap.get(wageKey).March_Actual__c : 0) : 0);
            
            grossContributionWrapper.April__c = (catAndTotal.containsKey(grossProfitKey) ? (catAndTotal.get(grossProfitKey).April__c != Null ? catAndTotal.get(grossProfitKey).April__c : 0) : 0) - 
                                                    (totalTypeAndPLMap.containsKey(wageKey) ? (totalTypeAndPLMap.get(wageKey).April__c != Null ? totalTypeAndPLMap.get(wageKey).April__c : 0) : 0);
            grossContributionWrapper.April_Actual__c = (catAndTotal.containsKey(grossProfitKey) ? (catAndTotal.get(grossProfitKey).April_Actual__c != Null ? catAndTotal.get(grossProfitKey).April_Actual__c : 0) : 0) - 
                                                    (totalTypeAndPLMap.containsKey(wageKey) ? (totalTypeAndPLMap.get(wageKey).April_Actual__c != Null ? totalTypeAndPLMap.get(wageKey).April_Actual__c : 0) : 0);
            
            grossContributionWrapper.May__c = (catAndTotal.containsKey(grossProfitKey) ? (catAndTotal.get(grossProfitKey).May__c != Null ? catAndTotal.get(grossProfitKey).May__c : 0) : 0) - 
                                                    (totalTypeAndPLMap.containsKey(wageKey) ? (totalTypeAndPLMap.get(wageKey).May__c != Null ? totalTypeAndPLMap.get(wageKey).May__c : 0) : 0);
            grossContributionWrapper.May_Actual__c = (catAndTotal.containsKey(grossProfitKey) ? (catAndTotal.get(grossProfitKey).May_Actual__c != Null ? catAndTotal.get(grossProfitKey).May_Actual__c : 0) : 0) - 
                                                    (totalTypeAndPLMap.containsKey(wageKey) ? (totalTypeAndPLMap.get(wageKey).May_Actual__c != Null ? totalTypeAndPLMap.get(wageKey).May_Actual__c : 0) : 0);
            
            grossContributionWrapper.June__c = (catAndTotal.containsKey(grossProfitKey) ? (catAndTotal.get(grossProfitKey).June__c != Null ? catAndTotal.get(grossProfitKey).June__c : 0) : 0) - 
                                                    (totalTypeAndPLMap.containsKey(wageKey) ? (totalTypeAndPLMap.get(wageKey).June__c != Null ? totalTypeAndPLMap.get(wageKey).June__c : 0) : 0);
            grossContributionWrapper.June_Actual__c = (catAndTotal.containsKey(grossProfitKey) ? (catAndTotal.get(grossProfitKey).June_Actual__c != Null ? catAndTotal.get(grossProfitKey).June_Actual__c : 0) : 0) - 
                                                    (totalTypeAndPLMap.containsKey(wageKey) ? (totalTypeAndPLMap.get(wageKey).June_Actual__c != Null ? totalTypeAndPLMap.get(wageKey).June_Actual__c : 0) : 0);
            
            grossContributionWrapper.July__c = (catAndTotal.containsKey(grossProfitKey) ? (catAndTotal.get(grossProfitKey).July__c != Null ? catAndTotal.get(grossProfitKey).July__c : 0) : 0) - 
                                                    (totalTypeAndPLMap.containsKey(wageKey) ?  (totalTypeAndPLMap.get(wageKey).July__c != Null ? totalTypeAndPLMap.get(wageKey).July__c : 0) : 0);
            grossContributionWrapper.July_Actual__c = (catAndTotal.containsKey(grossProfitKey) ? (catAndTotal.get(grossProfitKey).July_Actual__c != Null ? catAndTotal.get(grossProfitKey).July_Actual__c : 0) : 0) - 
                                                    (totalTypeAndPLMap.containsKey(wageKey) ? (totalTypeAndPLMap.get(wageKey).July_Actual__c != Null ? totalTypeAndPLMap.get(wageKey).July_Actual__c : 0) : 0);
            
            grossContributionWrapper.August__c = (catAndTotal.containsKey(grossProfitKey) ? (catAndTotal.get(grossProfitKey).August__c != Null ? catAndTotal.get(grossProfitKey).August__c : 0) : 0) - 
                                                    (totalTypeAndPLMap.containsKey(wageKey) ? (totalTypeAndPLMap.get(wageKey).August__c != Null ? totalTypeAndPLMap.get(wageKey).August__c : 0) : 0);
            grossContributionWrapper.August_Acutal__c = (catAndTotal.containsKey(grossProfitKey) ? (catAndTotal.get(grossProfitKey).August_Acutal__c != Null ? catAndTotal.get(grossProfitKey).August_Acutal__c : 0) : 0) - 
                                                    (totalTypeAndPLMap.containsKey(wageKey) ? (totalTypeAndPLMap.get(wageKey).August_Acutal__c != Null ? totalTypeAndPLMap.get(wageKey).August_Acutal__c : 0) : 0);
            
            grossContributionWrapper.September__c = (catAndTotal.containsKey(grossProfitKey) ? (catAndTotal.get(grossProfitKey).September__c != Null ? catAndTotal.get(grossProfitKey).September__c : 0) : 0) - 
                                                    (totalTypeAndPLMap.containsKey(wageKey) ? (totalTypeAndPLMap.get(wageKey).September__c != Null ? totalTypeAndPLMap.get(wageKey).September__c : 0) : 0);
            grossContributionWrapper.September_Acutal__c = (catAndTotal.containsKey(grossProfitKey) ? (catAndTotal.get(grossProfitKey).September_Acutal__c != Null ? catAndTotal.get(grossProfitKey).September_Acutal__c : 0) : 0) - 
                                                    (totalTypeAndPLMap.containsKey(wageKey) ? (totalTypeAndPLMap.get(wageKey).September_Acutal__c != Null ? totalTypeAndPLMap.get(wageKey).September_Acutal__c : 0) : 0);
            
            grossContributionWrapper.October__c = (catAndTotal.containsKey(grossProfitKey) ? (catAndTotal.get(grossProfitKey).October__c != Null ? catAndTotal.get(grossProfitKey).October__c : 0) : 0) - 
                                                    (totalTypeAndPLMap.containsKey(wageKey) ? (totalTypeAndPLMap.get(wageKey).October__c != Null ? totalTypeAndPLMap.get(wageKey).October__c : 0) : 0);
            grossContributionWrapper.October_Actual__c = (catAndTotal.containsKey(grossProfitKey) ? (catAndTotal.get(grossProfitKey).October_Actual__c != Null ? catAndTotal.get(grossProfitKey).October_Actual__c : 0) : 0) - 
                                                    (totalTypeAndPLMap.containsKey(wageKey) ? (totalTypeAndPLMap.get(wageKey).October_Actual__c != Null ? totalTypeAndPLMap.get(wageKey).October_Actual__c : 0) : 0);
            
            grossContributionWrapper.November__c = (catAndTotal.containsKey(grossProfitKey) ? (catAndTotal.get(grossProfitKey).November__c != Null ? catAndTotal.get(grossProfitKey).November__c : 0) : 0) - 
                                                    (totalTypeAndPLMap.containsKey(wageKey) ? (totalTypeAndPLMap.get(wageKey).November__c != Null ? totalTypeAndPLMap.get(wageKey).November__c : 0) : 0);
            grossContributionWrapper.November_Actual__c = (catAndTotal.containsKey(grossProfitKey) ? (catAndTotal.get(grossProfitKey).November_Actual__c != Null ? catAndTotal.get(grossProfitKey).November_Actual__c : 0) : 0) - 
                                                    (totalTypeAndPLMap.containsKey(wageKey) ? (totalTypeAndPLMap.get(wageKey).November_Actual__c != Null ? totalTypeAndPLMap.get(wageKey).November_Actual__c : 0) : 0);
            
            grossContributionWrapper.December__c = (catAndTotal.containsKey(grossProfitKey) ? (catAndTotal.get(grossProfitKey).December__c != Null ? catAndTotal.get(grossProfitKey).December__c : 0) : 0) - 
                                                    (totalTypeAndPLMap.containsKey(wageKey) ? (totalTypeAndPLMap.get(wageKey).December__c != Null ? totalTypeAndPLMap.get(wageKey).December__c : 0) : 0);
            grossContributionWrapper.December_Actual__c = (catAndTotal.containsKey(grossProfitKey) ? (catAndTotal.get(grossProfitKey).December_Actual__c != Null ? catAndTotal.get(grossProfitKey).December_Actual__c : 0) : 0) - 
                                                    (totalTypeAndPLMap.containsKey(wageKey) ? (totalTypeAndPLMap.get(wageKey).December_Actual__c != Null ? totalTypeAndPLMap.get(wageKey).December_Actual__c : 0) : 0);
            grossContributionWrapper.Type_Label__c = 'GROSS CONTRIBUTION';
            grossContributionWrapper.Year__c = pls.Year__c;
            grossContributionWrapper.Type__c = 'Formula';
            catAndTotal.put('GROSS CONTRIBUTION' + ':' + pls.Year__c , grossContributionWrapper);
            if(plsTypeAndFormula.containsKey(grossContributionWrapper.Type_Label__c)){
                if(plsTypeAndFormula.get(grossContributionWrapper.Type_Label__c).P_L_Category_B__r.Sequence__c!=null){
                    grossContributionWrapper.Sequence__c = plsTypeAndFormula.get(grossContributionWrapper.Type_Label__c).P_L_Category_B__r.Sequence__c + 1;
                } else if(plsTypeAndFormula.get(grossContributionWrapper.Type_Label__c).P_L_Category_A__r.Sequence__c!=null){
                    grossContributionWrapper.Sequence__c = plsTypeAndFormula.get(grossContributionWrapper.Type_Label__c).P_L_Category_A__r.Sequence__c + 1;
                }
            } 
            formulaPLS.add(grossContributionWrapper);
        }
        
        For(P_L_Statement__c pls : totalPlList){
            P_L_Statement__c ebitaWrapper = new P_L_Statement__c();
            String grossContributionKey = 'GROSS CONTRIBUTION'+ ':' + pls.Year__c;
            String gaKey = 'TOTAL G&A' + ':' + pls.Year__c;
            ebitaWrapper.January__c = (catAndTotal.containsKey(grossContributionKey) ? (catAndTotal.get(grossContributionKey).January__c != Null ? catAndTotal.get(grossContributionKey).January__c : 0) : 0) - 
                                            (totalTypeAndPLMap.containsKey(gaKey) ? (totalTypeAndPLMap.get(gaKey).January__c != Null ? totalTypeAndPLMap.get(gaKey).January__c : 0) : 0);
            ebitaWrapper.January_Actual__c = (catAndTotal.containsKey(grossContributionKey) ? (catAndTotal.get(grossContributionKey).January_Actual__c != Null ? catAndTotal.get(grossContributionKey).January_Actual__c : 0) : 0) - 
                                            (totalTypeAndPLMap.containsKey(gaKey) ? (totalTypeAndPLMap.get(gaKey).January_Actual__c != Null ? totalTypeAndPLMap.get(gaKey).January_Actual__c : 0) : 0);
            
            ebitaWrapper.February__c = (catAndTotal.containsKey(grossContributionKey) ? (catAndTotal.get(grossContributionKey).February__c != Null ? catAndTotal.get(grossContributionKey).February__c : 0) : 0) - 
                                            (totalTypeAndPLMap.containsKey(gaKey) ? (totalTypeAndPLMap.get(gaKey).February__c != Null ? totalTypeAndPLMap.get(gaKey).February__c : 0) : 0);
            ebitaWrapper.February_Actual__c = (catAndTotal.containsKey(grossContributionKey) ? (catAndTotal.get(grossContributionKey).February_Actual__c != Null ? catAndTotal.get(grossContributionKey).February_Actual__c : 0) : 0) - 
                                            (totalTypeAndPLMap.containsKey(gaKey) ? (totalTypeAndPLMap.get(gaKey).February_Actual__c != Null ? totalTypeAndPLMap.get(gaKey).February_Actual__c : 0) : 0);
            
            ebitaWrapper.March__c = (catAndTotal.containsKey(grossContributionKey) ? (catAndTotal.get(grossContributionKey).March__c != Null ? catAndTotal.get(grossContributionKey).March__c : 0) : 0) - 
                                            (totalTypeAndPLMap.containsKey(gaKey) ? (totalTypeAndPLMap.get(gaKey).March__c != Null ? totalTypeAndPLMap.get(gaKey).March__c : 0) : 0);
            ebitaWrapper.March_Actual__c = (catAndTotal.containsKey(grossContributionKey) ? (catAndTotal.get(grossContributionKey).March_Actual__c != Null ? catAndTotal.get(grossContributionKey).March_Actual__c : 0) : 0) - 
                                            (totalTypeAndPLMap.containsKey(gaKey) ? (totalTypeAndPLMap.get(gaKey).March_Actual__c != Null ? totalTypeAndPLMap.get(gaKey).March_Actual__c : 0) : 0);
            
            ebitaWrapper.April__c = (catAndTotal.containsKey(grossContributionKey) ? (catAndTotal.get(grossContributionKey).April__c != Null ? catAndTotal.get(grossContributionKey).April__c : 0) : 0) - 
                                            (totalTypeAndPLMap.containsKey(gaKey) ? (totalTypeAndPLMap.get(gaKey).April__c != Null ? totalTypeAndPLMap.get(gaKey).April__c : 0) : 0);
            ebitaWrapper.April_Actual__c = (catAndTotal.containsKey(grossContributionKey) ? (catAndTotal.get(grossContributionKey).April_Actual__c != Null ? catAndTotal.get(grossContributionKey).April_Actual__c : 0) : 0) - 
                                            (totalTypeAndPLMap.containsKey(gaKey) ? (totalTypeAndPLMap.get(gaKey).April_Actual__c != Null ? totalTypeAndPLMap.get(gaKey).April_Actual__c : 0) : 0);
            
            ebitaWrapper.May__c = (catAndTotal.containsKey(grossContributionKey) ? (catAndTotal.get(grossContributionKey).May__c != Null ? catAndTotal.get(grossContributionKey).May__c : 0) : 0) - 
                                        (totalTypeAndPLMap.containsKey(gaKey) ? (totalTypeAndPLMap.get(gaKey).May__c != Null ? totalTypeAndPLMap.get(gaKey).May__c : 0) : 0);
            ebitaWrapper.May_Actual__c = (catAndTotal.containsKey(grossContributionKey) ? (catAndTotal.get(grossContributionKey).May_Actual__c != Null ? catAndTotal.get(grossContributionKey).May_Actual__c : 0) : 0) - 
                                            (totalTypeAndPLMap.containsKey(gaKey) ? (totalTypeAndPLMap.get(gaKey).May_Actual__c != Null ? totalTypeAndPLMap.get(gaKey).May_Actual__c : 0) : 0);
            
            ebitaWrapper.June__c = (catAndTotal.containsKey(grossContributionKey) ? (catAndTotal.get(grossContributionKey).June__c != Null ? catAndTotal.get(grossContributionKey).June__c : 0) : 0) - 
                                        (totalTypeAndPLMap.containsKey(gaKey) ? (totalTypeAndPLMap.get(gaKey).June__c != Null ? totalTypeAndPLMap.get(gaKey).June__c : 0) : 0);
            ebitaWrapper.June_Actual__c = (catAndTotal.containsKey(grossContributionKey) ? (catAndTotal.get(grossContributionKey).June_Actual__c != Null ? catAndTotal.get(grossContributionKey).June_Actual__c : 0) : 0) - 
                                            (totalTypeAndPLMap.containsKey(gaKey) ? (totalTypeAndPLMap.get(gaKey).June_Actual__c != Null ? totalTypeAndPLMap.get(gaKey).June_Actual__c : 0) : 0);
            
            ebitaWrapper.July__c = (catAndTotal.containsKey(grossContributionKey) ? (catAndTotal.get(grossContributionKey).July__c != Null ? catAndTotal.get(grossContributionKey).July__c : 0) : 0) - 
                                        (totalTypeAndPLMap.containsKey(gaKey) ?  (totalTypeAndPLMap.get(gaKey).July__c != Null ? totalTypeAndPLMap.get(gaKey).July__c : 0) : 0);
            ebitaWrapper.July_Actual__c = (catAndTotal.containsKey(grossContributionKey) ? (catAndTotal.get(grossContributionKey).July_Actual__c != Null ? catAndTotal.get(grossContributionKey).July_Actual__c : 0) : 0) - 
                                            (totalTypeAndPLMap.containsKey(gaKey) ? (totalTypeAndPLMap.get(gaKey).July_Actual__c != Null ? totalTypeAndPLMap.get(gaKey).July_Actual__c : 0) : 0);
            
            ebitaWrapper.August__c = (catAndTotal.containsKey(grossContributionKey) ? (catAndTotal.get(grossContributionKey).August__c != Null ? catAndTotal.get(grossContributionKey).August__c : 0) : 0) - 
                                            (totalTypeAndPLMap.containsKey(gaKey) ? (totalTypeAndPLMap.get(gaKey).August__c != Null ? totalTypeAndPLMap.get(gaKey).August__c : 0) : 0);
            ebitaWrapper.August_Acutal__c = (catAndTotal.containsKey(grossContributionKey) ? (catAndTotal.get(grossContributionKey).August_Acutal__c != Null ? catAndTotal.get(grossContributionKey).August_Acutal__c : 0) : 0) - 
                                            (totalTypeAndPLMap.containsKey(gaKey) ? (totalTypeAndPLMap.get(gaKey).August_Acutal__c != Null ? totalTypeAndPLMap.get(gaKey).August_Acutal__c : 0) : 0);
            
            ebitaWrapper.September__c = (catAndTotal.containsKey(grossContributionKey) ? (catAndTotal.get(grossContributionKey).September__c != Null ? catAndTotal.get(grossContributionKey).September__c : 0) : 0) - 
                                            (totalTypeAndPLMap.containsKey(gaKey) ? (totalTypeAndPLMap.get(gaKey).September__c != Null ? totalTypeAndPLMap.get(gaKey).September__c : 0) : 0);
            ebitaWrapper.September_Acutal__c = (catAndTotal.containsKey(grossContributionKey) ? (catAndTotal.get(grossContributionKey).September_Acutal__c != Null ? catAndTotal.get(grossContributionKey).September_Acutal__c : 0) : 0) - 
                                            (totalTypeAndPLMap.containsKey(gaKey) ? (totalTypeAndPLMap.get(gaKey).September_Acutal__c != Null ? totalTypeAndPLMap.get(gaKey).September_Acutal__c : 0) : 0);
            
            ebitaWrapper.October__c = (catAndTotal.containsKey(grossContributionKey) ? (catAndTotal.get(grossContributionKey).October__c != Null ? catAndTotal.get(grossContributionKey).October__c : 0) : 0) - 
                                            (totalTypeAndPLMap.containsKey(gaKey) ? (totalTypeAndPLMap.get(gaKey).October__c != Null ? totalTypeAndPLMap.get(gaKey).October__c : 0) : 0);
            ebitaWrapper.October_Actual__c = (catAndTotal.containsKey(grossContributionKey) ? (catAndTotal.get(grossContributionKey).October_Actual__c != Null ? catAndTotal.get(grossContributionKey).October_Actual__c : 0) : 0) - 
                                            (totalTypeAndPLMap.containsKey(gaKey) ? (totalTypeAndPLMap.get(gaKey).October_Actual__c != Null ? totalTypeAndPLMap.get(gaKey).October_Actual__c : 0) : 0);
            
            ebitaWrapper.November__c = (catAndTotal.containsKey(grossContributionKey) ? (catAndTotal.get(grossContributionKey).November__c != Null ? catAndTotal.get(grossContributionKey).November__c : 0) : 0) - 
                                            (totalTypeAndPLMap.containsKey(gaKey) ? (totalTypeAndPLMap.get(gaKey).November__c != Null ? totalTypeAndPLMap.get(gaKey).November__c : 0) : 0);
            ebitaWrapper.November_Actual__c = (catAndTotal.containsKey(grossContributionKey) ? (catAndTotal.get(grossContributionKey).November_Actual__c != Null ? catAndTotal.get(grossContributionKey).November_Actual__c : 0) : 0) - 
                                            (totalTypeAndPLMap.containsKey(gaKey) ? (totalTypeAndPLMap.get(gaKey).November_Actual__c != Null ? totalTypeAndPLMap.get(gaKey).November_Actual__c : 0) : 0);
            
            ebitaWrapper.December__c = (catAndTotal.containsKey(grossContributionKey) ? (catAndTotal.get(grossContributionKey).December__c != Null ? catAndTotal.get(grossContributionKey).December__c : 0) : 0) - 
                                            (totalTypeAndPLMap.containsKey(gaKey) ? (totalTypeAndPLMap.get(gaKey).December__c != Null ? totalTypeAndPLMap.get(gaKey).December__c : 0) : 0);
            ebitaWrapper.December_Actual__c = (catAndTotal.containsKey(grossContributionKey) ? (catAndTotal.get(grossContributionKey).December_Actual__c != Null ? catAndTotal.get(grossContributionKey).December_Actual__c : 0) : 0) - 
                                            (totalTypeAndPLMap.containsKey(gaKey) ? (totalTypeAndPLMap.get(gaKey).December_Actual__c != Null ? totalTypeAndPLMap.get(gaKey).December_Actual__c : 0) : 0);
            ebitaWrapper.Type_Label__c = 'EBITDA';
            ebitaWrapper.Year__c = pls.Year__c;
            ebitaWrapper.Type__c = 'Formula';
            catAndTotal.put('EBITDA' + ':' + pls.Year__c , ebitaWrapper);
            if(plsTypeAndFormula.containsKey(ebitaWrapper.Type_Label__c)){
                if(plsTypeAndFormula.get(ebitaWrapper.Type_Label__c).P_L_Category_B__r.Sequence__c!=null){
                    ebitaWrapper.Sequence__c = plsTypeAndFormula.get(ebitaWrapper.Type_Label__c).P_L_Category_B__r.Sequence__c + 1;
                } else if(plsTypeAndFormula.get(ebitaWrapper.Type_Label__c).P_L_Category_A__r.Sequence__c!=null){
                    ebitaWrapper.Sequence__c = plsTypeAndFormula.get(ebitaWrapper.Type_Label__c).P_L_Category_A__r.Sequence__c + 1;
                }
            }
            formulaPLS.add(ebitaWrapper);
        }
        
        For(P_L_Statement__c pls : totalPlList){
            P_L_Statement__c ebitaWrapper = new P_L_Statement__c();
            String ebitaKey = 'EBITDA'+ ':' + pls.Year__c;
            String otherIEKey = 'TOTAL OTHER INCOME AND EXPENSES' + ':' + pls.Year__c;
            ebitaWrapper.January__c = (catAndTotal.containsKey(ebitaKey) ? (catAndTotal.get(ebitaKey).January__c != Null ? catAndTotal.get(ebitaKey).January__c : 0) : 0) - 
                                            (totalTypeAndPLMap.containsKey(otherIEKey) ? (totalTypeAndPLMap.get(otherIEKey).January__c != Null ? totalTypeAndPLMap.get(otherIEKey).January__c : 0) : 0);
            ebitaWrapper.January_Actual__c = (catAndTotal.containsKey(ebitaKey) ? (catAndTotal.get(ebitaKey).January_Actual__c != Null ? catAndTotal.get(ebitaKey).January_Actual__c : 0) : 0) - 
                                            (totalTypeAndPLMap.containsKey(otherIEKey) ? (totalTypeAndPLMap.get(otherIEKey).January_Actual__c != Null ? totalTypeAndPLMap.get(otherIEKey).January_Actual__c : 0) : 0);
            
            ebitaWrapper.February__c = (catAndTotal.containsKey(ebitaKey) ? (catAndTotal.get(ebitaKey).February__c != Null ? catAndTotal.get(ebitaKey).February__c : 0) : 0) - 
                                            (totalTypeAndPLMap.containsKey(otherIEKey) ? (totalTypeAndPLMap.get(otherIEKey).February__c != Null ? totalTypeAndPLMap.get(otherIEKey).February__c : 0) : 0);
            ebitaWrapper.February_Actual__c = (catAndTotal.containsKey(ebitaKey) ? (catAndTotal.get(ebitaKey).February_Actual__c != Null ? catAndTotal.get(ebitaKey).February_Actual__c : 0) : 0) - 
                                            (totalTypeAndPLMap.containsKey(otherIEKey) ? (totalTypeAndPLMap.get(otherIEKey).February_Actual__c != Null ? totalTypeAndPLMap.get(otherIEKey).February_Actual__c : 0) : 0);
            
            ebitaWrapper.March__c = (catAndTotal.containsKey(ebitaKey) ? (catAndTotal.get(ebitaKey).March__c != Null ? catAndTotal.get(ebitaKey).March__c : 0) : 0) - 
                                            (totalTypeAndPLMap.containsKey(otherIEKey) ? (totalTypeAndPLMap.get(otherIEKey).March__c != Null ? totalTypeAndPLMap.get(otherIEKey).March__c : 0) : 0);
            ebitaWrapper.March_Actual__c = (catAndTotal.containsKey(ebitaKey) ? (catAndTotal.get(ebitaKey).March_Actual__c != Null ? catAndTotal.get(ebitaKey).March_Actual__c : 0) : 0) - 
                                            (totalTypeAndPLMap.containsKey(otherIEKey) ? (totalTypeAndPLMap.get(otherIEKey).March_Actual__c != Null ? totalTypeAndPLMap.get(otherIEKey).March_Actual__c : 0) : 0);
            
            ebitaWrapper.April__c = (catAndTotal.containsKey(ebitaKey) ? (catAndTotal.get(ebitaKey).April__c != Null ? catAndTotal.get(ebitaKey).April__c : 0) : 0) - 
                                            (totalTypeAndPLMap.containsKey(otherIEKey) ? (totalTypeAndPLMap.get(otherIEKey).April__c != Null ? totalTypeAndPLMap.get(otherIEKey).April__c : 0) : 0);
            ebitaWrapper.April_Actual__c = (catAndTotal.containsKey(ebitaKey) ? (catAndTotal.get(ebitaKey).April_Actual__c != Null ? catAndTotal.get(ebitaKey).April_Actual__c : 0) : 0) - 
                                            (totalTypeAndPLMap.containsKey(otherIEKey) ? (totalTypeAndPLMap.get(otherIEKey).April_Actual__c != Null ? totalTypeAndPLMap.get(otherIEKey).April_Actual__c : 0) : 0);
            
            ebitaWrapper.May__c = (catAndTotal.containsKey(ebitaKey) ? (catAndTotal.get(ebitaKey).May__c != Null ? catAndTotal.get(ebitaKey).May__c : 0) : 0) - 
                                        (totalTypeAndPLMap.containsKey(otherIEKey) ? (totalTypeAndPLMap.get(otherIEKey).May__c != Null ? totalTypeAndPLMap.get(otherIEKey).May__c : 0) : 0);
            ebitaWrapper.May_Actual__c = (catAndTotal.containsKey(ebitaKey) ? (catAndTotal.get(ebitaKey).May_Actual__c != Null ? catAndTotal.get(ebitaKey).May_Actual__c : 0) : 0) - 
                                            (totalTypeAndPLMap.containsKey(otherIEKey) ? (totalTypeAndPLMap.get(otherIEKey).May_Actual__c != Null ? totalTypeAndPLMap.get(otherIEKey).May_Actual__c : 0) : 0);
            
            ebitaWrapper.June__c = (catAndTotal.containsKey(ebitaKey) ? (catAndTotal.get(ebitaKey).June__c != Null ? catAndTotal.get(ebitaKey).June__c : 0) : 0) - 
                                        (totalTypeAndPLMap.containsKey(otherIEKey) ? (totalTypeAndPLMap.get(otherIEKey).June__c != Null ? totalTypeAndPLMap.get(otherIEKey).June__c : 0) : 0);
            ebitaWrapper.June_Actual__c = (catAndTotal.containsKey(ebitaKey) ? (catAndTotal.get(ebitaKey).June_Actual__c != Null ? catAndTotal.get(ebitaKey).June_Actual__c : 0) : 0) - 
                                            (totalTypeAndPLMap.containsKey(otherIEKey) ? (totalTypeAndPLMap.get(otherIEKey).June_Actual__c != Null ? totalTypeAndPLMap.get(otherIEKey).June_Actual__c : 0) : 0);
            
            ebitaWrapper.July__c = (catAndTotal.containsKey(ebitaKey) ? (catAndTotal.get(ebitaKey).July__c != Null ? catAndTotal.get(ebitaKey).July__c : 0) : 0) - 
                                        (totalTypeAndPLMap.containsKey(otherIEKey) ?  (totalTypeAndPLMap.get(otherIEKey).July__c != Null ? totalTypeAndPLMap.get(otherIEKey).July__c : 0) : 0);
            ebitaWrapper.July_Actual__c = (catAndTotal.containsKey(ebitaKey) ? (catAndTotal.get(ebitaKey).July_Actual__c != Null ? catAndTotal.get(ebitaKey).July_Actual__c : 0) : 0) - 
                                            (totalTypeAndPLMap.containsKey(otherIEKey) ? (totalTypeAndPLMap.get(otherIEKey).July_Actual__c != Null ? totalTypeAndPLMap.get(otherIEKey).July_Actual__c : 0) : 0);
            
            ebitaWrapper.August__c = (catAndTotal.containsKey(ebitaKey) ? (catAndTotal.get(ebitaKey).August__c != Null ? catAndTotal.get(ebitaKey).August__c : 0) : 0) - 
                                            (totalTypeAndPLMap.containsKey(otherIEKey) ? (totalTypeAndPLMap.get(otherIEKey).August__c != Null ? totalTypeAndPLMap.get(otherIEKey).August__c : 0) : 0);
            ebitaWrapper.August_Acutal__c = (catAndTotal.containsKey(ebitaKey) ? (catAndTotal.get(ebitaKey).August_Acutal__c != Null ? catAndTotal.get(ebitaKey).August_Acutal__c : 0) : 0) - 
                                            (totalTypeAndPLMap.containsKey(otherIEKey) ? (totalTypeAndPLMap.get(otherIEKey).August_Acutal__c != Null ? totalTypeAndPLMap.get(otherIEKey).August_Acutal__c : 0) : 0);
            
            ebitaWrapper.September__c = (catAndTotal.containsKey(ebitaKey) ? (catAndTotal.get(ebitaKey).September__c != Null ? catAndTotal.get(ebitaKey).September__c : 0) : 0) - 
                                            (totalTypeAndPLMap.containsKey(otherIEKey) ? (totalTypeAndPLMap.get(otherIEKey).September__c != Null ? totalTypeAndPLMap.get(otherIEKey).September__c : 0) : 0);
            ebitaWrapper.September_Acutal__c = (catAndTotal.containsKey(ebitaKey) ? (catAndTotal.get(ebitaKey).September_Acutal__c != Null ? catAndTotal.get(ebitaKey).September_Acutal__c : 0) : 0) - 
                                            (totalTypeAndPLMap.containsKey(otherIEKey) ? (totalTypeAndPLMap.get(otherIEKey).September_Acutal__c != Null ? totalTypeAndPLMap.get(otherIEKey).September_Acutal__c : 0) : 0);
            
            ebitaWrapper.October__c = (catAndTotal.containsKey(ebitaKey) ? (catAndTotal.get(ebitaKey).October__c != Null ? catAndTotal.get(ebitaKey).October__c : 0) : 0) - 
                                            (totalTypeAndPLMap.containsKey(otherIEKey) ? (totalTypeAndPLMap.get(otherIEKey).October__c != Null ? totalTypeAndPLMap.get(otherIEKey).October__c : 0) : 0);
            ebitaWrapper.October_Actual__c = (catAndTotal.containsKey(ebitaKey) ? (catAndTotal.get(ebitaKey).October_Actual__c != Null ? catAndTotal.get(ebitaKey).October_Actual__c : 0) : 0) - 
                                            (totalTypeAndPLMap.containsKey(otherIEKey) ? (totalTypeAndPLMap.get(otherIEKey).October_Actual__c != Null ? totalTypeAndPLMap.get(otherIEKey).October_Actual__c : 0) : 0);
                                            
            ebitaWrapper.November__c = (catAndTotal.containsKey(ebitaKey) ? (catAndTotal.get(ebitaKey).November__c != Null ? catAndTotal.get(ebitaKey).November__c : 0) : 0) - 
                                            (totalTypeAndPLMap.containsKey(otherIEKey) ? (totalTypeAndPLMap.get(otherIEKey).November__c != Null ? totalTypeAndPLMap.get(otherIEKey).November__c : 0) : 0);
            ebitaWrapper.November_Actual__c = (catAndTotal.containsKey(ebitaKey) ? (catAndTotal.get(ebitaKey).November_Actual__c != Null ? catAndTotal.get(ebitaKey).November_Actual__c : 0) : 0) - 
                                            (totalTypeAndPLMap.containsKey(otherIEKey) ? (totalTypeAndPLMap.get(otherIEKey).November_Actual__c != Null ? totalTypeAndPLMap.get(otherIEKey).November_Actual__c : 0) : 0);
                                            
            ebitaWrapper.December__c = (catAndTotal.containsKey(ebitaKey) ? (catAndTotal.get(ebitaKey).December__c != Null ? catAndTotal.get(ebitaKey).December__c : 0) : 0) - 
                                            (totalTypeAndPLMap.containsKey(otherIEKey) ? (totalTypeAndPLMap.get(otherIEKey).December__c != Null ? totalTypeAndPLMap.get(otherIEKey).December__c : 0) : 0);
            ebitaWrapper.December_Actual__c = (catAndTotal.containsKey(ebitaKey) ? (catAndTotal.get(ebitaKey).December_Actual__c != Null ? catAndTotal.get(ebitaKey).December_Actual__c : 0) : 0) - 
                                            (totalTypeAndPLMap.containsKey(otherIEKey) ? (totalTypeAndPLMap.get(otherIEKey).December_Actual__c != Null ? totalTypeAndPLMap.get(otherIEKey).December_Actual__c : 0) : 0);
            ebitaWrapper.Type_Label__c = 'NET INCOME';
            ebitaWrapper.Year__c = pls.Year__c;
            ebitaWrapper.Type__c = 'Formula';
            catAndTotal.put('NET INCOME ' + ':' + pls.Year__c , ebitaWrapper);
            if(plsTypeAndFormula.containsKey(ebitaWrapper.Type_Label__c)){
                if(plsTypeAndFormula.get(ebitaWrapper.Type_Label__c).P_L_Category_B__r.Sequence__c!=null){
                    ebitaWrapper.Sequence__c = plsTypeAndFormula.get(ebitaWrapper.Type_Label__c).P_L_Category_B__r.Sequence__c + 1;
                    
                } else if(plsTypeAndFormula.get(ebitaWrapper.Type_Label__c).P_L_Category_A__r.Sequence__c!=null){
                    ebitaWrapper.Sequence__c = plsTypeAndFormula.get(ebitaWrapper.Type_Label__c).P_L_Category_A__r.Sequence__c + 1;
                }
            }
            formulaPLS.add(ebitaWrapper);
        }
        return formulaPLS;
    }
    
    /*
     * This method is used for checking if the batch is already running
     * @parameter classID : Apex class Id of the Batch Class
     * @returns Boolean
   */
    public static Boolean isBatchRunning(String classID){
        boolean isBatchRunning = false;
        For(AsyncApexJob aaj : [SELECT Id, Status, ApexClassID FROM AsyncApexJob WHERE ApexClassID =: classID]){
            if(aaj.Status == CONSTANT.ASYNCH_JOB_STATUS_HOLDING || 
                                aaj.Status == CONSTANT.ASYNCH_JOB_STATUS_QUEUED || 
                                aaj.Status == CONSTANT.ASYNCH_JOB_STATUS_PROCESSING){
                isBatchRunning = true;
                break;
            } 
        }
        if(isBatchRunning){
            return true;
        }
        else{
            return false;
        }
    }

    /*
     * This method is used for calling the PL statement batch
     * @parameter 
     * @returns void
   */
    public static void CallPLStatementBatch(){
        //CreatePLStatement cps = new CreatePLStatement();
        //Database.executeBatch(cps , 2000);
    }

    /*
    * This method will return QuotaSchedule Order By Range_Start__c
    * @parameter none
    * @returns List of Quota_Schedule__c
    */
    public static List<Quota_Schedule__c> getQuotaSchedule(){
        List<Quota_Schedule__c> listQuotaSchdule = new List<Quota_Schedule__c>();
        for(Quota_Schedule__c quotaScheduleRec : [Select id , Type__c , Range_Start__c , Range_End__c , Monthly_Amount__c from  Quota_Schedule__c Where Range_Start__c != null order by Range_Start__c asc]){
            listQuotaSchdule.add(quotaScheduleRec);
        }
        return listQuotaSchdule;
    }

    /*
    * This method will return GL Code
    * @parameter none
    * @returns List of GL_Code__c
    */
     public static List<GL_Code__c> getRecurringGLCode(){
        List<GL_Code__c> listGLCode = new List<GL_Code__c>();
        for(GL_Code__c glRec : [Select id from GL_Code__c where Name =: Constant.RECURRING_GL_CODE]){
            listGLCode.add(glRec);
        }
        return listGLCode;
    }
    /* @param 
       rc : Revenue_Contract__c record whose number of active months needs to be verified
       @return 
       Integer: Number of Months required  
      */
    public static Integer getRevenueMonths(Revenue_Contract__c rc){
        Integer totalMonths=0;
        Integer forecastDuration = PlaceCPM_Utility.assumptionForecastDuration; 
        if(forecastDuration > 0 && rc.Live_Renewed_Date__c != null){
           totalMonths=  forecastDuration + Integer.valueOf(Math.ceil(rc.Live_Renewed_Date__c.daysBetween(System.today())/30));
            return  Integer.valueOf(rc.Auto_Renew__c || rc.Contract_Months__c ==null  ? totalMonths : 
                                                                (rc.Contract_End_Date__c <  rc.Live_Renewed_Date__c.addMonths(forecastDuration) ? 
                                                                rc.Contract_Months__c : totalMonths) );
        }else if(rc.Contract_Months__c !=null){
            return Integer.valueOf(rc.Contract_Months__c);
        }else{
            return 0;
        }         

    }
    
    /*
    //  Method to reset isproceed on gl_code and related pl statement with 0 values.
    //  @param new map and old map of Revenue_P_L_Allocation__c and Expense_P_L_Allocation__c
    //  @return void
    public static void deletePLStatementAndUpdateIsProceedOnGl(Map<Id, SObject> newItems , Map<Id, SObject> oldItems){
        Set<String> glCodeIdSet = new Set<String>();
        List<GL_Code__c> glCodeList = new List<GL_Code__c>();
        List<P_L_Statement__c> plStatementList = new List<P_L_Statement__c>();
        Set<String> years = new Set<String>();
        //520
        String glCodeObj = PlaceCPM_Utility.getCustomObjOrFieldName(CONSTANT.GL_CODE_OBJECT);
        String plMonthStartDate = PlaceCPM_Utility.getCustomObjOrFieldName('PlMonthStartDate__c');
        String forecastAmount = PlaceCPM_Utility.getCustomObjOrFieldName('Forecast_Amount__c');

        For(SObject expl : newItems != Null ? newItems.values() : oldItems.values()){
            if(oldItems != null && newItems != null){
                SObject oldpl = oldItems.get(expl.Id);
                if(expl.get(glCodeObj) != null && (Id)expl.get(glCodeObj) == (Id)oldpl.get(glCodeObj)){
                    if(expl.get(forecastAmount) != null && (Decimal)expl.get(forecastAmount) != (Decimal)oldpl.get(forecastAmount)){
                        glCodeIdSet.add((Id)expl.get(glCodeObj));
                        years.add(String.valueOf(((Date)expl.get(plMonthStartDate)).year()));
                    }
                }
                else if(expl.get(glCodeObj) != null && (Id)expl.get(glCodeObj) != (Id)oldpl.get(glCodeObj)){
                    glCodeIdSet.add((Id)expl.get(glCodeObj));
                    glCodeIdSet.add((Id)oldpl.get(glCodeObj));
                    years.add(String.valueOf(((Date)expl.get(plMonthStartDate)).year()));
                    years.add(String.valueOf(((Date)oldpl.get(plMonthStartDate)).year()));
                } 
            }
            else{
                glCodeIdSet.add((Id)expl.get(glCodeObj));
                years.add(String.valueOf(((Date)expl.get(plMonthStartDate)).year()));
            }
        }
        For(String glcIId : glCodeIdSet){
            GL_Code__c glc = new GL_Code__c(Id = (Id) glcIId);
            if(Schema.sObjectType.GL_Code__c.fields.IsProceed__c.isUpdateable()){
                glc.IsProceed__c = false;
            }
            glCodeList.add(glc);
        }

        if(glCodeList != null){
             For(P_L_Statement__c pls : [SELECT id From P_L_Statement__c WHERE GL_Code__c IN : glCodeList AND year__c in: years]){
                if(Schema.sObjectType.P_L_Statement__c.fields.January__c.isUpdateable() && Schema.sObjectType.P_L_Statement__c.fields.January__c.isCreateable()){
                    pls.January__c = 0.0;
                }
                if(Schema.sObjectType.P_L_Statement__c.fields.February__c.isUpdateable() && Schema.sObjectType.P_L_Statement__c.fields.February__c.isCreateable()){
                    pls.February__c = 0.0;
                }
                if(Schema.sObjectType.P_L_Statement__c.fields.March__c.isUpdateable() && Schema.sObjectType.P_L_Statement__c.fields.March__c.isCreateable()){
                    pls.March__c = 0.0;
                }
                if(Schema.sObjectType.P_L_Statement__c.fields.April__c.isUpdateable() && Schema.sObjectType.P_L_Statement__c.fields.April__c.isCreateable()){
                    pls.April__c = 0.0;
                }
                if(Schema.sObjectType.P_L_Statement__c.fields.May__c.isUpdateable() && Schema.sObjectType.P_L_Statement__c.fields.May__c.isCreateable()){
                    pls.May__c = 0.0;
                }
                if(Schema.sObjectType.P_L_Statement__c.fields.June__c.isUpdateable() && Schema.sObjectType.P_L_Statement__c.fields.June__c.isCreateable()){
                    pls.June__c = 0.0;
                }
                if(Schema.sObjectType.P_L_Statement__c.fields.July__c.isUpdateable() && Schema.sObjectType.P_L_Statement__c.fields.July__c.isCreateable()){
                    pls.July__c = 0.0;
                }
                if(Schema.sObjectType.P_L_Statement__c.fields.August__c.isUpdateable() && Schema.sObjectType.P_L_Statement__c.fields.August__c.isCreateable()){
                    pls.August__c = 0.0;
                }
                if(Schema.sObjectType.P_L_Statement__c.fields.September__c.isUpdateable() && Schema.sObjectType.P_L_Statement__c.fields.September__c.isCreateable()){
                    pls.September__c = 0.0;
                }
                if(Schema.sObjectType.P_L_Statement__c.fields.October__c.isUpdateable() && Schema.sObjectType.P_L_Statement__c.fields.October__c.isCreateable()){
                    pls.October__c = 0.0;
                }
                if(Schema.sObjectType.P_L_Statement__c.fields.November__c.isUpdateable() && Schema.sObjectType.P_L_Statement__c.fields.November__c.isCreateable()){
                    pls.November__c = 0.0;
                }
                if(Schema.sObjectType.P_L_Statement__c.fields.December__c.isUpdateable() && Schema.sObjectType.P_L_Statement__c.fields.December__c.isCreateable()){
                    pls.December__c = 0.0;
                }
                plStatementList.add(pls);
            }
        }
        try{
            PlaceCPM_Utility.updateRecords(glCodeList, CONSTANT.GL_CODE_OBJECT, false); //520
            PlaceCPM_Utility.upsertRecords(plStatementList, CONSTANT.P_L_STATEMENT_OBJECT, false);//520
        }
        catch(Exception ex){
            PlaceCPM_Utility.debugLog(ex.getMessage() + ' at line number ' + ex.getLineNumber());
        }
        
    }
    /*
    public static Integer getWeekOfMonth(Date dateOfMonth){
        return Math.ceil((Double)(dateOfMonth.Day()) / 7).intValue();
    }
    
    //  Method to reset pl statement with 0 values.
    //  @param new map and old map of Revenue_Cash_Allocation__c and Expense_Cash_Allocation__c
    //  @return void
    public static void resetPLStatementsOnCashAllocationChange(Map<Id, SObject> newItems , Map<Id, SObject> oldItems){
        Set<String> paymentAccountIdSet = new Set<String>();
        List<P_L_Statement__c> plStatementList = new List<P_L_Statement__c>();
        List<PL_Statement_Week__c> plChildToUpdate = new List<PL_Statement_Week__c>();
        Set<String> years = new Set<String>();
        Set<String> months = new Set<String>();
        String cashType = '';
        Map<String,Decimal>psIdToMonthMap = new Map<String,Decimal>();
        Set<String> revenueCashAllIdSet = new Set<String>();
        Map<String,String> revenueAccountToRTMap = new Map<String,String>();
        //520
        String revenueAccount = PlaceCPM_Utility.getCustomObjOrFieldName(CONSTANT.revenueAccountObject);
        String investmentRT = PlaceCPM_Utility.getCustomObjOrFieldName(CONSTANT.INVESTMENT_RECORD_TYPE_RA);
        
        String inverstorRTId = PlaceCPM_Utility.getRecordTypeIdbyDeveloperName(revenueAccount, investmentRT);

        for(SObject epla : newItems != Null ? newItems.values() : oldItems.values()){
            if(epla instanceOf Revenue_Cash_Allocation__c){
                revenueCashAllIdSet.add((String)epla.get('Id'));
            }
        }
        for(Revenue_Cash_Allocation__c rca : [SELECT Id, Revenue_Account__c, Revenue_Account__r.RecordTypeId FROM Revenue_Cash_Allocation__c WHERE Id IN : revenueCashAllIdSet]){
            if(rca.Revenue_Account__r.RecordTypeId == inverstorRTId ){
                revenueAccountToRTMap.put(rca.Revenue_Account__c,rca.Revenue_Account__r.RecordTypeId);
            }
            
        }
        For(SObject expl : newItems != null ? newItems.values() : oldItems.values()){
            if(expl instanceOf Expense_Cash_Allocation__c){
                cashType = CONSTANT.PLS_CashType_Expense;
            }
            else if(expl instanceOf Revenue_Cash_Allocation__c){
                if((String)expl.get(revenueAccount) != null && revenueAccountToRTMap.containsKey((String)expl.get(revenueAccount))) {  
                    cashType = CONSTANT.PLS_CashType_Deposits; 
                }
                else{
                    cashType = CONSTANT.PLS_CashType_Revenue;
                }
            }
            //520
            String paymentAccountId = PlaceCPM_Utility.getCustomObjOrFieldName('Payment_Account_Id__c');
            String actualAmount = PlaceCPM_Utility.getCustomObjOrFieldName('Actual_Amount__c');
            String forecastAmount = PlaceCPM_Utility.getCustomObjOrFieldName('Forecast_Amount__c');
            String cashDate = PlaceCPM_Utility.getCustomObjOrFieldName('Cash_Date__c'); 

            if(oldItems != null && newItems != null){
                SObject oldpl = oldItems.get(expl.Id);
                 if(expl.get(paymentAccountId) != null || cashType == CONSTANT.PLS_CashType_Deposits){ //520
                    
                    if((Decimal)expl.get(actualAmount) != (Decimal)oldpl.get(actualAmount)){
                        if(oldpl.get(actualAmount) != null ){
                            paymentAccountIdSet.add((Id)expl.get(paymentAccountId));
                            years.add(String.valueOf(((Date)expl.get(cashDate)).year()));
                            String toBeMatched = (String)expl.get(paymentAccountId)+':'+String.valueOf(((Date)expl.get(cashDate)).year())+':'+getMonthString(((Date)expl.get(cashDate)).month())+'__c'+':'+(Date)expl.get(cashDate);
                            if(!psIdToMonthMap.containsKey(toBeMatched)){
                                psIdToMonthMap.put(toBeMatched,0);
                            }
                            Decimal updatedAmt = psIdToMonthMap.get(toBeMatched)+ (Decimal)oldpl.get(actualAmount);
                            psIdToMonthMap.put(toBeMatched,updatedAmt);
                            //months.add();
                        }
                        if(oldpl.get(actualAmount) == null && (Decimal)expl.get(actualAmount) != null && oldpl.get(forecastAmount) != null){
                            paymentAccountIdSet.add((Id)expl.get(paymentAccountId));
                            years.add(String.valueOf(((Date)expl.get(cashDate)).year()));
                            String toBeMatched = (String)expl.get(paymentAccountId)+':'+String.valueOf(((Date)expl.get(cashDate)).year())+':'+getMonthString(((Date)expl.get(cashDate)).month())+'__c'+':'+(Date)expl.get(cashDate);
                            if(!psIdToMonthMap.containsKey(toBeMatched)){
                                psIdToMonthMap.put(toBeMatched,0);
                            }
                            Decimal updatedAmt = psIdToMonthMap.get(toBeMatched)+ (Decimal)oldpl.get(forecastAmount);
                            psIdToMonthMap.put(toBeMatched,updatedAmt);
                        }
                        if(oldpl.get(actualAmount) != null && (Decimal)expl.get(actualAmount) == null && (Decimal)expl.get(forecastAmount) != null){
                            paymentAccountIdSet.add((Id)expl.get(paymentAccountId));
                            years.add(String.valueOf(((Date)expl.get(cashDate)).year()));
                            String toBeMatched = (String)expl.get(paymentAccountId)+':'+String.valueOf(((Date)expl.get(cashDate)).year())+':'+getMonthString(((Date)expl.get(cashDate)).month())+'__c'+':'+(Date)expl.get(cashDate);
                            if(!psIdToMonthMap.containsKey(toBeMatched)){
                                psIdToMonthMap.put(toBeMatched,0);
                            }
                            Decimal updatedAmt = psIdToMonthMap.get(toBeMatched)+ (Decimal)oldpl.get(actualAmount);
                            psIdToMonthMap.put(toBeMatched,updatedAmt);
                        }
                    }
                    else if(oldpl.get(forecastAmount) != null && (Decimal)expl.get(forecastAmount) != (Decimal)oldpl.get(forecastAmount)){
                        paymentAccountIdSet.add((Id)expl.get(paymentAccountId));
                        years.add(String.valueOf(((Date)expl.get(cashDate)).year()));
                        String toBeMatched = (String)expl.get(paymentAccountId)+':'+String.valueOf(((Date)expl.get(cashDate)).year())+':'+getMonthString(((Date)expl.get(cashDate)).month())+'__c'+':'+(Date)expl.get(cashDate);
                        if(!psIdToMonthMap.containsKey(toBeMatched)){
                            psIdToMonthMap.put(toBeMatched,0);
                        }
                        Decimal updatedAmt = psIdToMonthMap.get(toBeMatched)+ (Decimal)oldpl.get(forecastAmount);
                        psIdToMonthMap.put(toBeMatched,updatedAmt);
                    }
                }
                
            }
            else{
                //SObject oldpl = oldItems.get(expl.Id);
                if(expl.get(paymentAccountId) != null || cashType == CONSTANT.PLS_CashType_Deposits){ //520
                    if(expl.get(actualAmount) != null ){
                        
                        paymentAccountIdSet.add((Id)expl.get(paymentAccountId));
                        years.add(String.valueOf(((Date)expl.get(cashDate)).year()));
                        String toBeMatched = (String)expl.get(paymentAccountId)+':'+String.valueOf(((Date)expl.get(cashDate)).year())+':'+getMonthString(((Date)expl.get(cashDate)).month())+'__c'+':'+(Date)expl.get(cashDate);
                        if(!psIdToMonthMap.containsKey(toBeMatched)){
                            psIdToMonthMap.put(toBeMatched,0);
                        }
                        Decimal updatedAmt = psIdToMonthMap.get(toBeMatched)+ (Decimal)expl.get(actualAmount);
                        psIdToMonthMap.put(toBeMatched,updatedAmt);
                        //months.add();
                        
                    }
                    else if(expl.get(forecastAmount) != null ){
                        paymentAccountIdSet.add((Id)expl.get(paymentAccountId));
                        years.add(String.valueOf(((Date)expl.get(cashDate)).year()));
                        String toBeMatched = (String)expl.get(paymentAccountId)+':'+String.valueOf(((Date)expl.get(cashDate)).year())+':'+getMonthString(((Date)expl.get(cashDate)).month())+'__c'+':'+(Date)expl.get(cashDate);
                        if(!psIdToMonthMap.containsKey(toBeMatched)){
                            psIdToMonthMap.put(toBeMatched,0);
                        }
                        Decimal updatedAmt = psIdToMonthMap.get(toBeMatched)+ (Decimal)expl.get(forecastAmount);
                        psIdToMonthMap.put(toBeMatched,updatedAmt);
                    }
                }
                //paymentAccountIdSet.add((Id)expl.get('Payment_Account_Id__c'));
                //years.add(String.valueOf(((Date)expl.get('Cash_Date__c')).year()));
            }
        }
        if(paymentAccountIdSet != null || cashType == CONSTANT.PLS_CashType_Deposits){ //520
            
            For(P_L_Statement__c pls : [SELECT id,Parent_Bank_Account__c,Year__c,January__c,February__c,March__c,April__c,May__c,June__c,July__c,August__c,September__c,October__c,November__c,December__c,
                                        (SELECT id , Year__c , week1Date__c, week2Date__c, week3Date__c, week4Date__c, week5Date__c, Month_In_Number__c ,
                                         Parent_P_L_Statement__c  ,Week1__c, week2__c, week3__c, week4__c, week5__c,Payment_Account__c From PL_Statement_Weeks__r)
                                        From P_L_Statement__c 
                                        WHERE Parent_Bank_Account__c IN : paymentAccountIdSet AND year__c in: years AND Cash_Tyoe__c =: cashType]){
                                           
                    List<String> pbYearMonth = new List<String>();
                    for(String toBeMatched: psIdToMonthMap.keySet()){
                        pbYearMonth = toBeMatched.split(':');
                        //520
                        if(( cashType == CONSTANT.PLS_CashType_Deposits ||pbYearMonth[0] == pls.Parent_Bank_Account__c) && pbYearMonth[1] == pls.Year__c){
                            system.debug('pls'+pls);
                            String plsField = pbYearMonth[2];
                            Decimal updatedValue = (Decimal)pls.get(plsField) - psIdToMonthMap.get(toBeMatched);
                            system.debug('updatedValue'+updatedValue);
                            pls.put(pbYearMonth[2],updatedValue);
                            for(PL_Statement_Week__c plc : pls.PL_Statement_Weeks__r){
                                Integer weekOfCashDate = getWeekOfMonth(date.valueOf(pbYearMonth[3]));
                                Decimal updatedWeekValue = (Decimal)plc.get('week'+weekOfCashDate+'__c') - psIdToMonthMap.get(toBeMatched);
                                if(plc.Month_In_Number__c == String.valueOf(date.valueOf(pbYearMonth[3]).month())){
                                    plc.put('week'+weekOfCashDate+'__c',updatedWeekValue);
                                }
                                plChildToUpdate.add(plc);
                            }
                        }
                    }                     
					plStatementList.add(pls);
               }
        }
        
        try{
            PlaceCPM_Utility.upsertRecords(plStatementList, CONSTANT.P_L_STATEMENT_OBJECT, false); //520
            PlaceCPM_Utility.updateRecords(plChildToUpdate, CONSTANT.PL_STATEMENT_WEEK_OBJECT, false); //520
        }
        catch(Exception ex){
            PlaceCPM_Utility.debugLog(ex.getMessage() + ' at line number ' + ex.getLineNumber());
        }
    }

    //This method will return the date of the day for the month and year provided in params
    public static List<Date> getFridays(Integer year, Integer month, String day) {
        List<Date> toReturn = new List<Date>();
        DateTime checkDate = Date.newInstance(year, month, 1);
        DateTime endDate = checkDate.addMonths(1);
        while(checkDate <= endDate){
            if(checkDate.format('E') == day){
                if(checkDate.date().month() == month){
                    toReturn.add(checkDate.date());
                }
                checkdate = checkdate.addDays(7);
            } else {
                checkDate = checkDate.addDays(1);
            }
        }
        return toReturn;
    }
    
    //#166
    //TODO:To be used in place of Division by 30 calculation
    /* @param 
       endDate : End date  
       startDate : Start Date
       @return 
       Integer: Number of Months between two dates including the start and end months 
    *//*

    public static Integer getMonthsBetween(Date endDate, Date startDate){
        If(endDate != null && startDate != null){
        Integer startMonth = startDate.month();
        Integer endMonth = endDate.month();
        Integer startYear = startDate.year();
        Integer endYear = endDate.year();
        if(startYear == endYear){
            return endMonth-startMonth+1;

        } else{
            return (12-startMonth)+1+endMonth+((endYear-startYear-1)*12);
        }

        }else{
            return 0;
        }
    }
    */

    //  Method to Calculated Number of months for which P&L and Cash should be created.
    //  @param Date StartDate = Start Date of the Record
    //  @param Date EndDate = End Date of the Record
    //  @param Date todayDate = Currect Date
    //  @param Boolean autoRenew = Auto Renew fields values of the Record.
    //  @return Integer expenseMonths = Number of months for P&L and Cash Creation

    public static Integer getTotalMonths(Date StartDate, Date EndDate, Date todayDate, Boolean autoRenew){
        Integer expenseMonths = 0;
        Integer monthsToAdd = 0;
        if(StartDate < todayDate){
            monthsToAdd = StartDate.monthsBetween(todayDate);
            StartDate = todayDate;
        }
        if(StartDate < todayDate.addMonths(PlaceCPM_Utility.assumptionForecastDuration)){
            If(StartDate >= todayDate){
                If(autoRenew || 
                    (!autoRenew && EndDate == null) ||
                    (!autoRenew && EndDate != null && EndDate > todayDate.addMonths(PlaceCPM_Utility.assumptionForecastDuration))
                    ){
                    expenseMonths = StartDate.monthsBetween(todayDate.addMonths(PlaceCPM_Utility.assumptionForecastDuration));
                }
                else If(!autoRenew && EndDate != null && EndDate <= todayDate.addMonths(PlaceCPM_Utility.assumptionForecastDuration)){
                    expenseMonths = StartDate.monthsBetween(EndDate)+1;
                }
            
            }
        }
        return expenseMonths+monthsToAdd;
    }
    /*
    //  Method to create PL Statement from Quota Schedule
    //  @param List<sObject> scopeTemp = list of either Revenue PL Allocations of Expense PL Allocations
    //  @param String typeSobj = String type of Sobject
    //  @return 
    public static void createPLstatement(List<sObject> scopeTemp, String typeSobj){
        List<String> yearList = new List<String>();
        List<String> categoryList = new List<String>();
        Set<String> glCodeId = new  Set<String>();
        Set<Id> plSection = new Set<Id>();
        Map<String , Decimal> categoryMonthYearAndExpenseAmount = new  Map<String , Decimal>();
        Id cat;
        String year;
        Integer month;
        Map<Id , String> catIdAndName = new Map<Id , String>();
        Map<Id , Decimal> categoryIdAndCategorySequence = new Map<Id , Decimal>();
        Map<Id , Decimal> glAccountIdAndGLSequence = new Map<Id , Decimal>();
        Expense_PL_Allocation__c expenseAllocation;
        Revenue_P_L_Allocation__c revenueAllocation;
        List<sObject> scope = new List<sObject>();
        
        //Need to query again to get the parent relationships
        if(typeSobj == CONSTANT.EXPENSE_PL_ALLOCATION_OBJECT){
            For(Expense_PL_Allocation__c expl : [SELECT Id , P_L__r.Period_Start_Date__c , GL_Code__c , GL_Code__r.Name , 
                                                GL_Code__r.PL_Category__c , GL_Code__r.Sequence__c, 
                                                GL_Code__r.PL_Category__r.Sequence__c, Forecast_Amount__c 
                                                FROM Expense_PL_Allocation__c 
                                                where Id In: scopeTemp]){
                scope.add(expl);
            }
        
        }else{
            For(Revenue_P_L_Allocation__c rvpl : [SELECT Id , P_L__r.Period_Start_Date__c , GL_Code__c ,  GL_Code__r.Name , 
                                                    GL_Code__r.PL_Category__c , GL_Code__r.Sequence__c, GL_Code__r.PL_Category__r.Sequence__c, 
                                                    Forecast_Amount__c 
                                                    FROM Revenue_P_L_Allocation__c 
                                                    where Id In: scopeTemp]){
                scope.add(rvpl);
            }
        }
        
        for (SObject epla : scope) {
            //start 520
            epla.put(PlaceCPM_Utility.getCustomObjOrFieldName('isProceed__c'), true);
            
            String glCodec = PlaceCPM_Utility.getCustomObjOrFieldName(CONSTANT.GL_CODE_OBJECT);
            String glCoder = PlaceCPM_Utility.getCustomObjOrFieldName('GL_Code__r');
            String plr = PlaceCPM_Utility.getCustomObjOrFieldName('P_L__r');
            String pStartDate = PlaceCPM_Utility.getCustomObjOrFieldName('Period_Start_Date__c');
            String sequence = PlaceCPM_Utility.getCustomObjOrFieldName('Sequence__c');
            String name = PlaceCPM_Utility.getCustomObjOrFieldName('Name');
            String plCategoryc = PlaceCPM_Utility.getCustomObjOrFieldName(CONSTANT.P_L_Category_OBJECT);
            String plCategoryr = PlaceCPM_Utility.getCustomObjOrFieldName('PL_Category__r');
            String forecastAmount = PlaceCPM_Utility.getCustomObjOrFieldName('Forecast_Amount__c');
            
            glCodeId.add((Id)epla.get(glCodec));
            
            cat = (Id)epla.get(glCodec);
            year = String.valueOf(((Date)epla.getSobject(plr).get(pStartDate)).year());
            month = ((Date)epla.getSobject(plr).get(pStartDate)).month();
            categoryList.add(cat);
            yearList.add(year);
            catIdAndName.put((Id)epla.get(glCodec) , String.valueOf(epla.getSobject(glCoder).get(name)));
            if(epla.getSobject(glCoder).get(sequence) != Null)
                glAccountIdAndGLSequence.put((Id)epla.get(glCodec) , (Decimal)epla.getSobject(glCoder).get(sequence));
            if((Decimal)epla.getSobject(glCoder).getSobject(plCategoryr).get(sequence) != Null)
                categoryIdAndCategorySequence.put((Id)epla.getSobject(glCoder).get(plCategoryc) , (Decimal)epla.getSobject(glCoder).getSobject(plCategoryr).get(sequence));
            if((Decimal)epla.get(forecastAmount) != Null){
                if(!categoryMonthYearAndExpenseAmount.containsKey(cat+':'+year+':'+month)){
                    categoryMonthYearAndExpenseAmount.put(cat+':'+year+':'+month , (Decimal)epla.get(forecastAmount));
                }
                else{
                    Decimal updatedAmount = categoryMonthYearAndExpenseAmount.get(cat+':'+year+':'+month) + (Decimal)epla.get(forecastAmount);
                    categoryMonthYearAndExpenseAmount.put(cat+':'+year+':'+month , updatedAmount);
                }  
            }
            plSection.add((Id)epla.getSobject(glCoder).get(plCategoryc));
        }
        // end 520
        
        Map<Id , GL_Code__c> plCategories = new Map<Id , GL_Code__c>([SELECT Id , PL_Category__c FROM GL_Code__c where PL_Category__c IN : plSection]);
       
        List<P_L_Statement__c> plStatementListAlreadyExits = [SELECT id , Year__c , January__c , February__c , March__c , April__c ,
                                                                May__c , June__c , July__c , August__c , September__c , October__c , 
                                                                November__c , December__c , GL_Code__c, Sequence__c, GL_Code__r.PL_Category__c From P_L_Statement__c WHERE Year__c IN : yearList 
                                                                AND GL_Code__c IN : categoryList];
        Map<String , P_L_Statement__c> yearCatAndStatementMap = new Map<String , P_L_Statement__c>();
        List<P_L_Statement__c> plLisToInsertOrUpdate = new List<P_L_Statement__c>();
        For(P_L_Statement__c pls : plStatementListAlreadyExits){
           yearCatAndStatementMap.put(pls.GL_Code__c+':'+pls.Year__c , pls); 
        }
        List<String> arrCatYearMonth = new List<String>();
        For(String catYearMonth : categoryMonthYearAndExpenseAmount.keySet()){
            arrCatYearMonth = catYearMonth.split(':');
            String toBeMatched = arrCatYearMonth[0]+':'+arrCatYearMonth[1];
            P_L_Statement__c pls;
            if(yearCatAndStatementMap.containsKey(toBeMatched)){
                pls = yearCatAndStatementMap.get(toBeMatched);
                if(categoryIdAndCategorySequence.containsKey(pls.GL_Code__r.PL_Category__c) && glAccountIdAndGLSequence.containsKey(pls.GL_Code__c)){
                    if(categoryIdAndCategorySequence.get(pls.GL_Code__r.PL_Category__c)!=null && glAccountIdAndGLSequence.get(pls.GL_Code__c)!=null){
                        pls.Sequence__c = categoryIdAndCategorySequence.get(pls.GL_Code__r.PL_Category__c) + glAccountIdAndGLSequence.get(pls.GL_Code__c)/100;
                    }
                }
                yearCatAndStatementMap.put(toBeMatched , pls);
            }
            else{
                pls = new P_L_Statement__c();
                pls.GL_Code__c = arrCatYearMonth[0];
                pls.Year__c = arrCatYearMonth[1];
                pls.P_L_Category__c = plCategories.containsKey(arrCatYearMonth[0]) ? plCategories.get(arrCatYearMonth[0]).PL_Category__c : Null;
                pls.Type__c = CONSTANT.PL_STATEMENT_TYPE_CATEGORY;
                if(categoryIdAndCategorySequence.containsKey(pls.GL_Code__r.PL_Category__c) && glAccountIdAndGLSequence.containsKey(pls.GL_Code__c)){
                    if(categoryIdAndCategorySequence.get(pls.GL_Code__r.PL_Category__c)!=null && glAccountIdAndGLSequence.get(pls.GL_Code__c)!=null){
                        pls.Sequence__c = categoryIdAndCategorySequence.get(pls.GL_Code__r.PL_Category__c) + glAccountIdAndGLSequence.get(pls.GL_Code__c)/100;
                    }
                }
                yearCatAndStatementMap.put(toBeMatched , pls);
            }
            Decimal catmonthAmount = categoryMonthYearAndExpenseAmount.get(catYearMonth);
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
        try{
            PlaceCPM_Utility.upsertRecords(yearCatAndStatementMap.values(), CONSTANT.P_L_STATEMENT_OBJECT, false); //520
        }
        catch(Exception ex){
            PlaceCPM_Utility.debugLog(ex.getMessage() + ' at line number ' + ex.getLineNumber());
        }
    }
    */

    // Wrapper class to get the employee details for revenue account creation
    public class EmployeeRevenueDetailWrapper{
        public Date maxContractEndDate;
    }

    //This method is used to return the field set information
    //@param Field set name and object api name
    //return List<Schema.FieldSetMember>
    public static List<Schema.FieldSetMember> readFieldSet(String fieldSetName, String ObjectName){
        Map<String, Schema.SObjectType> GlobalDescribeMap = Schema.getGlobalDescribe(); 
        Schema.SObjectType SObjectTypeObj = GlobalDescribeMap.get(ObjectName);
        Schema.DescribeSObjectResult DescribeSObjectResultObj = SObjectTypeObj.getDescribe();
        
        //system.debug('====>' + DescribeSObjectResultObj.FieldSets.getMap().get(fieldSetName));
        
        Schema.FieldSet fieldSetObj = DescribeSObjectResultObj.FieldSets.getMap().get(fieldSetName);
        
        //List<Schema.FieldSetMember> fieldSetMemberList =  fieldSetObj.getFields();
        //system.debug('fieldSetMemberList ====>' + fieldSetMemberList); 
        if(fieldSetObj != null){
            return fieldSetObj.getFields(); 
        }
        else{
            return null;
        }
        
    } 
    
    //This method is used to get record type info of the objects
    //@param Objecct Api Name
    //Return list of recordtype names
    public static Map<Id,String> fetchRecordTypeValues(String objectApiName){
        Map<Id, String> recordtypemap;
        List<Schema.RecordTypeInfo> recordtypes = Schema.getGlobalDescribe().get(getCustomObjOrFieldName(objectApiName)).getDescribe().getRecordTypeInfos();    
        recordtypemap = new Map<Id, String>();
        for(RecordTypeInfo rt : recordtypes){
            if(rt.getName() != 'Master')
                
            recordtypemap.put(rt.getRecordTypeId(), rt.getName()+':'+rt.getDeveloperName());
        }        
        return recordtypemap;
    }


    //This function returns the Object or Field Name with Namespace
    public static String getCustomObjOrFieldName(String objOrFieldName){
        return namespacePrefix != '' ? namespacePrefix + '__' + objOrFieldName : objOrFieldName;
    }

    //This function returns the Object or Field Name without Namespace
    public static String removeNameSpacePrefix(String objOrFieldName){
        List<String> pieces = objOrFieldName.split('__');
    	Integer size = pieces.size();
    	if(!(size == 1 || pieces[1] == 'c' || (size > 2 && pieces[2] == 's'))){
        	return pieces[1]+'__'+pieces[2];
        }else{
            return objOrFieldName;
        }
    }

    /*************************************
    //SOQL LAYER : 
    ********************************************/

    //Insert operation
    public static void insertRecords(List<Sobject> sObjList, String sObjName, Boolean isPartial){
        System.debug('sObjName+++'+sObjName);
        if(sObjList.size() > 0 && Schema.getGlobalDescribe().get(getCustomObjOrFieldName(sObjName)).getDescribe().isCreateable()){
            System.debug('hi');
            insert sObjList;
        }
    }

    //Update operation
    public static void updateRecords(List<Sobject> sObjList, String sObjName, Boolean isPartial){
        if(sObjList.size() > 0 && Schema.getGlobalDescribe().get(getCustomObjOrFieldName(sObjName)).getDescribe().isUpdateable()){
            update sObjList;
        }
    }
    
    //Update operation with SaveResult | 557
    public static Database.SaveResult[] updateRecordsWithSaveResult(List<Sobject> sObjList, String sObjName, Boolean isPartial){
        if(sObjList.size() > 0 && Schema.getGlobalDescribe().get(getCustomObjOrFieldName(sObjName)).getDescribe().isUpdateable()){
            Database.SaveResult[] results = Database.update(sObjList, false);
            return results;
        }
        return null;
    }

    //Delete operation
    public static void deleteRecords(List<Sobject> sObjList, String sObjName, Boolean isPartial){
        if(sObjList.size() > 0 && Schema.getGlobalDescribe().get(getCustomObjOrFieldName(sObjName)).getDescribe().isDeletable()){
            delete sObjList;
        }
    }

    //Upsert operation   !expensePnlAllocations.isEmpty()
    public static void upsertRecords(List<Sobject> sObjList, String sObjName, Boolean isPartial){
        if(sObjList.size() > 0 && Schema.getGlobalDescribe().get(getCustomObjOrFieldName(sObjName)).getDescribe().isCreateable() && Schema.getGlobalDescribe().get(getCustomObjOrFieldName(sObjName)).getDescribe().isUpdateable()){
            upsert sObjList;
        }
    }

    //492
    // Call the VF page and get the Log In Use Session Id,
    // @param none. 
    // @return String
    public static String fetchUserSessionId(){
        String sessionId = '';
        PageReference reportPage = Page.placeCPM_GetSessionId;
        String vfContent = '';
        if(Test.isRunningTest()) { 
            vfContent = CONSTANT.START_OF_SESSIONID+' xyz '+CONSTANT.END_OF_SESSIONID;
        } else {
            vfContent = reportPage.getContent().toString();
        } 
        String sos = CONSTANT.START_OF_SESSIONID;
        Integer startP = vfContent.indexOf(CONSTANT.START_OF_SESSIONID) + sos.length(),
        endP = vfContent.indexOf(CONSTANT.END_OF_SESSIONID);
        sessionId = vfContent.substring(startP, endP);
        return sessionId;
    }
    
    // This method checks the isUpdateable, isCreateable, isAccessible permission of fields
    // @param String sObjectType, String commaDelimitedFields, String actionType
    // @return boolean
    public static boolean checkAccessiblityOfFields(String sObjectType, String commaDelimitedFields, String actionType) {
        Boolean isFieldAccessible = true;
        SObjectType schemaType = sObjectType.endsWith('__c') ? Schema.getGlobalDescribe().get(getCustomObjOrFieldName(sObjectType)) : Schema.getGlobalDescribe().get(sObjectType);
        Map<String, SObjectField> fields = schemaType.getDescribe().fields.getMap();
        if(actionType == CONSTANT.ACTION_TYPE_INSERT){
            for (String fieldName : commaDelimitedFields.split(',')){
                String field = fieldName.trim().endsWith('__c') ? getCustomObjOrFieldName(fieldName.trim()) : fieldName.trim();
                if(!fields.get(field).getDescribe().isCreateable()){
                   return false;
                }
            }
        }else if(actionType == CONSTANT.ACTION_TYPE_UPDATE){
            for (String fieldName : commaDelimitedFields.split(',')){
                String field = fieldName.trim().endsWith('__c') ? getCustomObjOrFieldName(fieldName.trim()) : fieldName.trim();
                if(!fields.get(field).getDescribe().isUpdateable()){
                   return false;
                }
            }
        }else if(actionType == CONSTANT.ACTION_TYPE_UPSERT){
            for (String fieldName : commaDelimitedFields.split(',')){
                String field = fieldName.trim().endsWith('__c') ? getCustomObjOrFieldName(fieldName.trim()) : fieldName.trim();
                if((!fields.get(field).getDescribe().isUpdateable() || !fields.get(field).getDescribe().isCreateable())){
                   return false;
                }
            }
        }else if(actionType == CONSTANT.ACTION_TYPE_ACCESS){
            for (String fieldName : commaDelimitedFields.split(',')){
                String field = fieldName.trim().endsWith('__c') ? getCustomObjOrFieldName(fieldName.trim()) : fieldName.trim();
                if(!fields.get(field).getDescribe().isAccessible()){
                   return false;
                }
            }
        }
        
        return true;
    }
}
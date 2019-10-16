/*
Description : This class holds all the String Constants used throughout the product.
				(Manmeet) TODO : Need to rename the Class
Date Created : 21th June 2019
*/
public class CONSTANT {
    public static final Map<String, Integer> mapMonthsCountWeekly = new Map<String, Integer>();
    public static final Map<String, Integer> mapMonthsCountBiWeekly = new Map<String, Integer>();
    public static final String PL_WAGE_RDT_NET_WAGE = 'Wage_Net_Wage';
    public static final String PL_WAGE_RDT_EMPLOYER_TAX = 'Wage_Employer_Tax';
    public static final String PL_NON_WAGE_RDT = 'Non_Wage';
    public static final String CASH_WAGE_RDT_MPLOYER_TAX= 'Wage_Employer_Tax';
    public static final String RA_RDT_FORECAST_REVENUE = 'Forecasted_Revenue';
    public static final String CASH_WAGE_RDT_NET_WAGE = 'Wage_Net_Wage';
    public static final String BONUS_PLAN_ACCELERATOR_BONUS_RT = 'Accelerator_Bonus';

    public static final String BONUS_PAY_SCHEDULE_MONTHLY = '1';
    public static final String BONUS_PAY_SCHEDULE_IN_TWO_MONTHS = '2';
    public static final String BONUS_PAY_SCHEDULE_IN_THREE_MONTHS = '3';
    public static final String BONUS_PAY_SCHEDULE_IN_FOUR_MONTHS = '4';
    public static final String BONUS_PAY_SCHEDULE_IN_FIVE_MONTHS = '5';
    public static final String BONUS_PAY_SCHEDULE_IN_SIX_MONTHS = '6';
    public static final String BONUS_PAY_SCHEDULE_IN_SEVEN_MONTHS = '7';
    public static final String BONUS_PAY_SCHEDULE_IN_EIGHT_MONTHS = '8';
    public static final String BONUS_PAY_SCHEDULE_IN_NINE_MONTHS = '9';
    public static final String BONUS_PAY_SCHEDULE_IN_TEN_MONTHS = '10';
    public static final String BONUS_PAY_SCHEDULE_IN_ELEVEN_MONTHS = '11';
    public static final String BONUS_PAY_SCHEDULE_IN_TWELVE_MONTHS = '12';

    public static final String BASE_PAY_SCHEDULE_MONTHLY = 'Monthly';
    public static final String BASE_PAY_SCHEDULE_SEMI_MONTHLY = 'Semi-Monthly';
    public static final String BASE_PAY_SCHEDULE_BI_WEEKLY = 'Bi-Weekly';
    public static final String BASE_PAY_SCHEDULE_WEEKLY = 'Weekly';

    public static final String COMPENSATION_RECORD_TYPE_SALES_EMPLOYEE = 'Sales_Employee_Compensation';
    public static final String COMPENSATION_RECORD_TYPE_OPS_EMPLOYEE = 'Ops_Employee_Compensation';
    
    public static final String PL_CATEGORY_EXPENSE = 'Expense';
    public static final String PL_CATEGORY_REVENUE = 'Revenue';
    public static final String PL_STATEMENT_TYPE_CATEGORY = 'Category';
    public static final String PL_STATEMENT_TYPE_TOTAL = 'Total';
    public static final String PL_STATEMENT_TYPE_FORMULA = 'Formula';
    public static final String ASYNCH_JOB_STATUS_HOLDING = 'Holding';
    public static final String ASYNCH_JOB_STATUS_QUEUED = 'Queued';
    public static final String ASYNCH_JOB_STATUS_PROCESSING = 'Processing';
    public static final String BATCH_CLASS_CREATE_PL_STATEMENT = 'CreatePLStatement';
    public static final String EMPLOYEE_TYPE_HOURLY_EMPLOYEE = 'Hourly Employee';
    public static final String EMPLOYEE_TYPE_HOURLY_CONTRACTORS = 'Hourly Contractors';
    public static final String RECURRING_GL_CODE = 'Recurring';
    public static final String EMPLOYEE_ROLE_FORMULA_ACCOUNT_EXECUTIVE = 'Account Executive';
    public static final String EMPLOYEE_DEPARTMENT_FORMULA_SALES = 'Sales';
    public static final String EMPLOYEE_STATUS_TERMINATED = 'Terminated';
    //#33
    public static final String REVENUE_CONTRACT_RECORD_TYPE_RC = 'Revenue Contract';
    public static final String REVENUE_CONTRACT_RECORD_TYPE_SOW = 'Statement of Work';
    public static final String REVENUE_RECORD_TYPE_GENERAL = 'General';
    public static final String EMPLOYEE_SALES_RT = Schema.SObjectType.Employee__c.getRecordTypeInfosByName().get('Sales Employee').getRecordTypeId();
    public static final String EMPLOYEE_OPERATIONS_RT = Schema.SObjectType.Employee__c.getRecordTypeInfosByName().get('Operations Employee').getRecordTypeId();
    public static final String EMPLOYEE_EXPENSE_ALLOCATION_INSERT = 'Insert';
    public static final String EMPLOYEE_EXPENSE_ALLOCATION_DELETE = 'Delete';
    public static final String EMPLOYEE_EXPENSE_ALLOCATION_UPDATE = 'Update';
    public static final String EMPLOYEE_DEPARTMENT_SALES = 'Sales';
    public static final String EMPLOYEE_ROLE_AE = 'Account Executive';
    public static final String GL_CODE_RECURRING = 'Recurring';
    public static final String REVENUE_RECORD_TYPE_TnM = 'Time and Material';
    public static final String EXPENSE_DETAIL_REVENUE_RECURRING_RT = 'Revenue_Expense_Recurring';
    public static final String EXPENSE_PL_ALLOCATION_OBJECT = 'Expense_PL_Allocation__c';
    public static final String REVENUE_PL_ALLOCATION_OBJECT = 'Revenue_P_L_Allocation__c';
    public static final String EXPENSE_PL_ALLOCATION_LABEL = 'Expense PL Allocation';
    public static final String REVENUE_PL_ALLOCATION_LABEL = 'Revenue PL Allocation';
    public static final String EXPENSE_CASG_ALLOCATION_OBJECT = 'Expense_Cash_Allocation__c';
    Public Static Final String EMPLOYEE_OBJECT = 'Employee__c';
    Public Static Final String PAYMENT_ACCOUNT_OBJECT = 'Payment_Account__c';
    Public Static Final String PL_STATEMENT_OBJECT = 'P_L_Statement__c';

    public static final Integer INTEGER_MAX_VALUE = 2147483647;
    public static final  String EXPPLTYPE = 'P&L';
    public static final String EXPCASHTYPE = 'CASH';
    public static final String EMPLOYEE_STATUS_ACTIVE = 'Active';
    public static final String PANDLALLOCATIONSBATCHCLASS = 'CreatePLAndCashForecastBatchable';
    public static final String expenseAccountObject = 'Expense_Account__c';
    public static final String revenueAccountObject = 'Revenue_Account__c';
    public static final String NET_INCOME = 'NET INCOME';
    public static final String CASH_AND_PL_TYPE_WAGE = 'Wage';
    public static final String CASH_AND_PL_TYPE_BONUS = 'Bonus';
    public static final String CASH_AND_PL_TYPE_PAYROLL_TAX = 'Payroll Tax';
    public static final String CASH_AND_PL_TYPE_EXPENSE_ACCOUNT = 'Expense Account';
    public static final String RECURRING_RECORD_TYPE_RC = 'Recurring'; //PCPM-315
    public static final String NON_RECURRING_RECORD_TYPE_RC = 'Non - Recurring'; //PCPM-315
    
    public static final String Q1 = 'Q1';
    public static final String Q2 = 'Q2';
    public static final String Q3 = 'Q3';
    public static final String Q4 = 'Q4';

    public static final String START_OF_SESSIONID = 'Start_Of_Session_Id';
    public static final String END_OF_SESSIONID = 'End_Of_Session_Id';
    public static final String LEFT_FIELDSET_NAME = 'PL_FieldSet';
    public static final String RIGHT_FIELDSET_NAME = 'PL_FieldSet2';
    public static final String RELATED_FIELDSET_NAME = 'relatedFields';

    //PCPM-520
    public static final String PLS_CashType_Expense = 'Expense';
    public static final String PLS_CashType_Revenue = 'Revenue';
    public static final String PLS_CashType_Deposits = 'Deposits';
    public static final String INVESTMENT_RECORD_TYPE_RA = 'Investment'; 
    public static final String EMPLOYEE_TYPE_SALARIED_EMPLOYEE = 'Salaried Employee';
    public static final String EMPLOYEE_RECORD_TYPE_SALES_EMPLOYEE = 'Sales_Employee';
    public static final String REVENUE_CASH_ALLOCATION_OBJECT = 'Revenue_Cash_Allocation__c';  
    public static final String WAGES_OBJECT = 'Wages__c';    
    public static final String COMPENSATION_OBJECT = 'Compensation__c';
    public static final String PL_STATEMENT_WEEK_OBJECT = 'PL_Statement_Week__c';
    public static final String P_L_STATEMENT_OBJECT = 'P_L_Statement__c';
    public static final String REVENUE_CONTRACT_OBJECT = 'Revenue_Contract__c'; 
    public static final String EMPLOYEE_DEPARTMENT_ALLOCATION_OBJECT = 'Employee_Department_Allocation__c'; 
    public static final String EMPLOYEE_EXPENSE_ALLOCATION_OBJECT = 'Employee_Expense_Allocation__c';
    public static final String QUOTA_OBJECT = 'Quota__c';
    public static final String EXPENSE_DETAIL_OBJECT = 'Expense_Detail__c';
    public static final String NON_WAGE_RECORD_TYPE_EPLA = 'Non-Wage';
    public static final String NON_WAGE_RECORD_TYPE_ECHA = 'Non-Wage';
    public static final String EXPENSE_ACCOUNT_OBJECT_LABEL = 'Expense Account';
    public static final String REVENUE_ACCOUNT_OBJECT_LABEL = 'Revenue Account'; 
    public static final String PROFIT_LOSS_OBJECT = 'Profit_Loss__c';
    public static final String CASH_FORECAST_OBJECT = 'Cash_Forecast__c';
    public static final String GL_CODE_OBJECT = 'GL_Code__c';
    public static final String P_L_Category_OBJECT = 'PL_Category__c'; 
    public static final String QUOTA_SCHEDULE_OBJECT = 'Quota_Schedule__c';
    public static final String CONTRACT_LINE_ITEM_OBJECT = 'Contract_Line_Items__c';
    public static final String NON_RECURRING_RECORD_TYPE_ED = 'Non Recurring'; 
    public static final String RECURRING_RECORD_TYPE_ED = 'Recurring'; 
    public static final String REVENUE_EXPENSE_RECURRING_RECORD_TYPE_ED = 'Revenue Expense Recurring';
    public static final String CASH_STATEMENT_CUSTOM_SETTING = 'Cash_Statement_Setting__c';
    public static final String ADMIN_CUSTOM_SETTING = 'PlaceCPM_AdminSetting__c';
    public static final String ASSUMPTION_OBJECT = 'Assumption__c';
    public static final String PL_CATEGORY_OBJECT = 'P_L_Category__c';
    public static final String PL_FORMULA_OBJECT = 'P_L_Formula__c';
    public static final String EquityContribution = 'Contribution';
    
    public static final String ACTION_TYPE_INSERT = 'INSERT'; 
    public static final String ACTION_TYPE_UPDATE = 'UPDATE'; 
    public static final String ACTION_TYPE_UPSERT = 'UPSERT'; 
    public static final String ACTION_TYPE_ACCESS = 'ACCESS';
    public static final String BONUS_PLAN_OBJECT = 'Bonus_Plan__c';
    public static final String PRODUCT_OBJECT = 'Product__c';
    public static final String ROLE_OBJECT = 'Role__c';
    public static final String EXPENSE_ALLOCATION_OBJECT = 'Expense_Allocation__c'; 
    public static final String SOW_LINE_ITEM_OBJECT = 'SOW_Line_Item__c'; 
    public static final String LOCATION_OBJECT = 'Location__c'; 
    public static final String DEPARTMENT_OBJECT = 'Department__c';
    public static final String PL_OBJECT = 'Profit_Loss__c';
    
    static{
        mapMonthsCountWeekly.put(CONSTANT.BONUS_PAY_SCHEDULE_MONTHLY, 4);
        mapMonthsCountWeekly.put(CONSTANT.BONUS_PAY_SCHEDULE_IN_TWO_MONTHS, 8);
        mapMonthsCountWeekly.put(CONSTANT.BONUS_PAY_SCHEDULE_IN_THREE_MONTHS, 12);
        mapMonthsCountWeekly.put(CONSTANT.BONUS_PAY_SCHEDULE_IN_FOUR_MONTHS, 16);
        mapMonthsCountWeekly.put(CONSTANT.BONUS_PAY_SCHEDULE_IN_FIVE_MONTHS, 20);
        mapMonthsCountWeekly.put(CONSTANT.BONUS_PAY_SCHEDULE_IN_SIX_MONTHS, 24);
        mapMonthsCountWeekly.put(CONSTANT.BONUS_PAY_SCHEDULE_IN_SEVEN_MONTHS, 28);
        mapMonthsCountWeekly.put(CONSTANT.BONUS_PAY_SCHEDULE_IN_EIGHT_MONTHS, 32);
        mapMonthsCountWeekly.put(CONSTANT.BONUS_PAY_SCHEDULE_IN_NINE_MONTHS, 36);
        mapMonthsCountWeekly.put(CONSTANT.BONUS_PAY_SCHEDULE_IN_TEN_MONTHS, 40);
        mapMonthsCountWeekly.put(CONSTANT.BONUS_PAY_SCHEDULE_IN_ELEVEN_MONTHS, 44);
        mapMonthsCountWeekly.put(CONSTANT.BONUS_PAY_SCHEDULE_IN_TWELVE_MONTHS, 48);
    } 
    static{ 
        mapMonthsCountBiWeekly.put(CONSTANT.BONUS_PAY_SCHEDULE_MONTHLY, 2);
        mapMonthsCountBiWeekly.put(CONSTANT.BONUS_PAY_SCHEDULE_IN_TWO_MONTHS, 4);
        mapMonthsCountBiWeekly.put(CONSTANT.BONUS_PAY_SCHEDULE_IN_THREE_MONTHS, 6);
        mapMonthsCountBiWeekly.put(CONSTANT.BONUS_PAY_SCHEDULE_IN_FOUR_MONTHS, 8);
        mapMonthsCountBiWeekly.put(CONSTANT.BONUS_PAY_SCHEDULE_IN_FIVE_MONTHS, 10);
        mapMonthsCountBiWeekly.put(CONSTANT.BONUS_PAY_SCHEDULE_IN_SIX_MONTHS, 12);
        mapMonthsCountBiWeekly.put(CONSTANT.BONUS_PAY_SCHEDULE_IN_SEVEN_MONTHS, 14);
        mapMonthsCountBiWeekly.put(CONSTANT.BONUS_PAY_SCHEDULE_IN_EIGHT_MONTHS, 16);
        mapMonthsCountBiWeekly.put(CONSTANT.BONUS_PAY_SCHEDULE_IN_NINE_MONTHS, 18);
        mapMonthsCountBiWeekly.put(CONSTANT.BONUS_PAY_SCHEDULE_IN_TEN_MONTHS, 20);
        mapMonthsCountBiWeekly.put(CONSTANT.BONUS_PAY_SCHEDULE_IN_ELEVEN_MONTHS, 22);
        mapMonthsCountBiWeekly.put(CONSTANT.BONUS_PAY_SCHEDULE_IN_TWELVE_MONTHS, 24);
    }
}
@isTest 
public class CashControllerTest {
    static GL_Code__c glCode;
    static GL_Code__c glc;
    static Account account1;
    static Expense_Account__c expAcc;
    static void createTestData(){
        TestUtility.createAssumption(24 , true);
        Profit_Loss__c pl = TestUtility.createPL('Test', Date.today(), date.today(), true);
        P_L_Category__c plCategory = TestUtility.createPlCategory('Test','Expense', true);
        glCode = TestUtility.createGLCode('Test', 500, plCategory.Id, true);
        
        account1 = TestUtility.createAccount('Test vendor1', true);
        Payment_Account__c pa = TestUtility.createPaymentAccount('testPaymentAccount',true);
        expAcc = TestUtility.createExpenseAccount(account1.Id, glCode.Id, '3', false);
        expAcc.Name = 'D-Link';
        expAcc.Payment_Account__c = pa.id;
        insert expAcc;
        
        Expense_Detail__c expDt = TestUtility.createExpenseDetail(expAcc.Id,  date.newInstance(2019,01,01) ,  date.newInstance(2019,12,31) , date.newInstance(2019,01,01) , 1000.00, '0', True);
        Expense_PL_Allocation__c expense = TestUtility.createExpensePlAllocation(glCode.Id, pl.Id, true);   
        
        glc = TestUtility.createGLCode('Test', 100 , plCategory.Id , true);
        
    }
    
    static testMethod void testGetPLStatement(){
        createTestData();
        CashForecastMainController.createTableHeader('Year');
        CashForecastMainController.createTableHeader('Quarter');
        //CashController.parseDateRangeStringAndAssign('{\'2019\':[2,3,4,5,6,7,8,9,10,11,12]}');
        CashForecastMainController.MainWrapper mw = CashForecastMainController.getPLStatement(null , Label.MONTH , null);
        CashForecastMainController.getPLStatementWithFilterAndExpansion(null , Label.MONTH  , mw.dateRange , mw.monthAndYearList , null , mw.yearsTobeFetched , null);
        //mw = CashController.getPLStatement(null ,Label.QUARTER , null);
        //mw = CashController.getPLStatement(null ,Label.YEAR , null);
        CashForecastMainController.getPLStatement(Label.Only_Actual ,Label.MONTH , null);
        CashForecastMainController.getPLStatement(Label.Only_Forecast ,Label.MONTH , null);
        CashForecastMainController.getPLStatement(Label.PLTabVariance ,Label.MONTH , null);
        System.assert(mw.plsWrapper.size() > 0 , 'No statement data');
        CashForecastMainController.addPL(glCode.Id , null , 0 , mw.dateRange , mw.monthAndYearList , Label.MONTH ,  null);
        CashForecastMainController.addPL(glCode.Id , null , 0 , mw.dateRange , mw.monthAndYearList , Label.QUARTER , null);
        CashForecastMainController.addPL(glCode.Id , null , 0 , mw.dateRange , mw.monthAndYearList , Label.YEAR , null);
        CashForecastMainController.applyTimeFrame(Label.MONTH , null , null , null);
        CashForecastMainController.applyTimeFrame(Label.QUARTER , null , null , null);
        CashForecastMainController.applyTimeFrame(Label.YEAR , null , null , null);
        CashForecastMainController.parseFromObject = false;
        //CashForecastMainController.applyTimeFrame(Label.Week , null , null , null);
        CashForecastMainController.applyFiltersPL(1 , 12 , 2019 , 2021 , Label.MONTH , null , null , '1 oct 2019' , '31 oct 2019');
        CashForecastMainController.applyFiltersPL(1 , 12 , 2019 , 2019 , Label.MONTH , null , null , '1 oct 2019' , '31 oct 2019');
        //CashController.applyFiltersPL(1 , 4 , 2019 , 2021 , Label.QUARTER , null);
        //CashController.applyFiltersPL(1 , 12 , 2019 , 2021 , Label.YEAR , null);
        CashForecastMainController.savePL(expAcc.Id , '1' , '100' , false , '2019' , glCode.Id , mw.dateRange , mw.monthAndYearList , null , mw.yearsTobeFetched, null , null , 'Month');
        //CashForecastMainController.savePL(expAcc.Id , '1' , '100' , false , '2019' , glCode.Id , mw.dateRange , mw.monthAndYearList , null , mw.yearsTobeFetched, null , null , 'Week');
        CashForecastMainController.getPLCategoryType(glCode.id);
        CashForecastMainController.getSplitScreenData(expAcc.Id);
    }
    
     static testMethod void readPageLayout(){
        Id recordTypeId = Schema.SObjectType.Expense_Account__c.getRecordTypeInfosByDeveloperName().get('Revenue_Expense').getRecordTypeId();
        CashForecastMainController.getEditPageLayoutSections('Expense_Account__c' , recordTypeId);
        CashForecastMainController.fetchRecordTypeValues('Expense_Account__c');
        PAndLTabController.getDetailPageLayoutSections(PlaceCPM_Utility.getCustomObjOrFieldName('Expense_Account__c') , recordTypeId);
        System.assertNotEquals(null, PAndLTabController.getDetailPageLayoutSections(PlaceCPM_Utility.getCustomObjOrFieldName('Expense_Account__c'), recordTypeId));
    }
}
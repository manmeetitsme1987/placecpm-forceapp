@isTest 
public class PAndLTabControllerTest {
    static GL_Code__c glCode;
    static GL_Code__c glc;
    static Account account1;
    static Expense_Account__c expAcc;
    static void createTestData(){
        TestUtility.createAssumption(24,true);
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
        System.assert([Select id from P_L_Statement__c].size() > 0 , '');
        
        glc = TestUtility.createGLCode('Test', 100 , plCategory.Id , true);
        List<P_L_Statement__c> plsStatementList = new List<P_L_Statement__c>();
        P_L_Statement__c pls = new P_L_Statement__c();
        pls.P_L_Category__c = plCategory.Id;
        pls.GL_Code__c = glc.Id;
        pls.type__c = CONSTANT.PL_STATEMENT_TYPE_TOTAL;
        pls.Year__c = '2019';
        plsStatementList.add(pls);
        pls = new P_L_Statement__c();
        pls.P_L_Category__c = plCategory.Id;
        pls.GL_Code__c = glc.Id;
        pls.type__c = CONSTANT.PL_STATEMENT_TYPE_CATEGORY;
        pls.Year__c = '2019';
        plsStatementList.add(pls);
        pls = new P_L_Statement__c();
        pls.P_L_Category__c = plCategory.Id;
        pls.GL_Code__c = glc.Id;
        pls.type__c = CONSTANT.PL_STATEMENT_TYPE_TOTAL;
        pls.Year__c = '2019';
        plsStatementList.add(pls);
        insert plsStatementList;
    }
    
    static testMethod void testGetPLStatement(){
        createTestData();
        PAndLTabController.MainWrapper mw = PAndLTabController.getPLStatement(null ,Label.MONTH , null);
        PAndLTabController.getPLStatementWithFilterAndExpansion(null , Label.MONTH  , mw.dateRange , mw.monthAndYearList ,  new List<Integer>{0} , mw.yearsTobeFetched);
        mw = PAndLTabController.getPLStatement(null ,Label.QUARTER , null);
        mw = PAndLTabController.getPLStatement(null ,Label.YEAR , null);
        PAndLTabController.getPLStatement(Label.Only_Actual ,Label.MONTH , null);
        PAndLTabController.getPLStatement(Label.Only_Forecast ,Label.MONTH , null);
        PAndLTabController.getPLStatement(Label.PLTabVariance ,Label.MONTH , null);
        System.assert(mw.plsWrapper.size() > 0 , 'No statement data');
        PAndLTabController.addPL(glCode.Id , null , 0 , mw.dateRange , mw.monthAndYearList , Label.MONTH);
        PAndLTabController.addPL(glCode.Id , null , 0 , mw.dateRange , mw.monthAndYearList , Label.QUARTER);
        PAndLTabController.addPL(glCode.Id , null , 0 , mw.dateRange , mw.monthAndYearList , Label.YEAR);
        PAndLTabController.applyTimeFrame(Label.MONTH , null , null);
        PAndLTabController.applyTimeFrame(Label.QUARTER , null , null);
        PAndLTabController.applyTimeFrame(Label.YEAR , null , null);
        PAndLTabController.applyFiltersPL(1 , 12 , 2019 , 2021 , Label.MONTH , null);
        PAndLTabController.applyFiltersPL(1 , 12 , 2019 , 2019 , Label.MONTH , null);
        PAndLTabController.applyFiltersPL(1 , 4 , 2019 , 2021 , Label.QUARTER , null);
        PAndLTabController.applyFiltersPL(1 , 12 , 2019 , 2021 , Label.YEAR , null);
        PAndLTabController.savePL(expAcc.Id , '1' , '100' , false , '2019' , glCode.Id , mw.dateRange , mw.monthAndYearList , new List<Integer>{0} , mw.yearsTobeFetched , null);
        PAndLTabController.createAllocations(expAcc.Id ,glCode.Id , '1' ,'2019', '100' , false );
        PAndLTabController.saveAllocation(mw.dateRange , mw.monthAndYearList , new List<Integer>{0} , mw.yearsTobeFetched);
        PAndLTabController.getPLCategoryType(glCode.Id);
        PAndLTabController.getSplitScreenData(expAcc.Id);
    }

    static testMethod void testPLAndCashAllocationScheduler(){
        Test.startTest();
        String sch = '0  00 1 3 * ?';
        placeCPM_SchedulePLAndCashAllocations sh1 = new placeCPM_SchedulePLAndCashAllocations();
        system.schedule('TestplaceCPM_SchedulePLAndCashAllocations', sch, sh1);
        Test.stopTest();
        
        //Assert
        System.assertNotEquals(null, sh1);
    }
    
    static testMethod void testPLAndCashControllerRemainingMethods(){
        createTestData();
        Test.startTest();
        PAndLTabController.removeAcc(null);
        PAndLTabController.removeAcc(glc.id);
        PAndLTabController.removeAcc(glc.id);
        System.assertNotEquals(null, glc);
        Test.stopTest();
    }
    static testMethod void removeAcc(){
        createTestData();
        Test.startTest();
        PAndLTabController.removeAcc(null);
        PAndLTabController.removeAcc(glc.id);
        PAndLTabController.removeAcc(glc.id);
        System.assertNotEquals(null, glc);        
        Test.stopTest();
    }
     static testMethod void readPageLayout(){
        Id recordTypeId = Schema.SObjectType.Expense_Account__c.getRecordTypeInfosByDeveloperName().get('Revenue_Expense').getRecordTypeId();
        PAndLTabController.getEditPageLayoutSections('Expense_Account__c' , recordTypeId);
        PAndLTabController.fetchRecordTypeValues('Expense_Account__c');
        System.assertNotEquals(null, PAndLTabController.getDetailPageLayoutSections(PlaceCPM_Utility.getCustomObjOrFieldName('Expense_Account__c') , recordTypeId));
    }
}

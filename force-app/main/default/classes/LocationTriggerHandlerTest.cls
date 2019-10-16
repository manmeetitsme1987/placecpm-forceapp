/*
 * Test Class for LocationTriggerHandler
 * createdOn 8August 2019
 */
@isTest
private class LocationTriggerHandlerTest {
    @testSetup
    static void createData(){
        list<Profit_Loss__c> listPL = new list<Profit_Loss__c>();
        list<Cash_Forecast__c> listCashForecast = new list<Cash_Forecast__c>();
        list<Bonus_Plan__c> bonusPlanList = new list<Bonus_Plan__c>();
        map<Integer,String> mapMonthYear = new map<Integer,String>();
        mapMonthYear.put(3,'March 2020');
        mapMonthYear.put(4,'April 2020');
        mapMonthYear.put(5,'May 2020');
        mapMonthYear.put(6,'June 2020');
        mapMonthYear.put(7,'July 2020');
        mapMonthYear.put(8,'August 2020');
        Assumption__c assumptionRec = TestUtility.createAssumption(1,True);
        
        Account acc = TestUtility.createAccount('TestAccount1',True);
        organisation__c organisation = TestUtility.createOrganisation('Place Technology', true); 
        P_L_Category__c plCategory = TestUtility.createPlCategory('General and Admin','Expense',true);
        GL_Code__c glaccount = TestUtility.createGLCode('Recurring',600,plCategory.id,true);
        Location__c loc = new Location__c(Payment_Term__c ='Monthly', GL_Code__c = glaccount.Id, Tax__c = 17);
        insert loc;
        Department__c department = TestUtility.createDepartment('SFDC', organisation.Id, glaccount.Id, true);  
        Role__c role = TestUtility.createRole('Tester', department.Id ,true);
        
        Employee__c employeeRec = TestUtility.createEmployee('TestEmployee',role.Id, date.newinstance(2020, 3, 1),'Austin','Salaried Employee',CONSTANT.EMPLOYEE_SALES_RT,false);
        employeeRec.Location__c  = loc.id;
        insert employeeRec;        
        for(Integer i = 3; i < 9 ; i++){
           Profit_Loss__c pl = TestUtility.createPL(mapMonthYear.get(i),date.newinstance(2020, i, 1),date.newinstance(2020, i, Date.daysInMonth(2020,i)),false);
           Cash_Forecast__c cashForcast = TestUtility.createCashForecast(mapMonthYear.get(i),date.newinstance(2020, i, 1),date.newinstance(2020, i, Date.daysInMonth(2020,i)),false);
           listPL.add(pl);
           listCashForecast.add(cashForcast);
        }
        if(listPL.size()>0){
            insert listPL;
        }
        if(listCashForecast.size() > 0){
            insert listCashForecast;
        }
      
        for(Integer i =0;i <12;i++){
            bonusPlanList.add(new Bonus_Plan__c (Name='i',GL_Account__c= glaccount.Id, Percentage__c =10, Payment_Frequency__c ='1'));
        }   
        insert bonusPlanList;
        Expense_Account__c expenseAcc = TestUtility.createExpenseAccount(acc.Id, glaccount.Id, '1', true);
        Expense_Allocation__c expenseAlloc = TestUtility.createExpenseAllocation(expenseAcc.Id, false);
        expenseAlloc.Role__c = role.Id;
        insert expenseAlloc;
        
        Compensation__c com = TestUtility.createCompensation(date.newinstance(2020, 7, 1), date.newinstance(2020, 7, 31),employeeRec.id, 10,'Semi-Monthly', bonusPlanList[0].id,True);
        delete com;
        Compensation__c cmp = TestUtility.createCompensation(date.newinstance(2020, 7, 1), date.newinstance(2020, 7, 31), employeeRec.Id , 50000, 'Monthly',bonusPlanList[1].id ,true);
    
        Wages__c wage = TestUtility.createWages(system.today(), system.today().addDays(3),employeeRec.Id , 1500, cmp.Id, 500, 1000, true);
    }
    
    @isTest
    static void testMethod1(){
        List<Wages__c> wageList = [SELECT Id,Employee_Name__c FROM Wages__c];
        system.debug('wagelist'+wageList);
        P_L_Category__c plCategory = [SELECT id FROM P_L_Category__c WHERE Name = 'General and Admin'];
        GL_Code__c glaccount = TestUtility.createGLCode('Time and revenue',400,plCategory.id,true);
        Location__c loc = [SELECT Id,GL_Code__c,Tax__c FROM Location__c LIMIT 1];
        loc.GL_Code__c = glaccount.Id;
        loc.Tax__c = 20.00;
        Test.startTest();
        update loc;
        List<Expense_Cash_Allocation__c> expList = [SELECT Id,Forecast_Amount__c,GL_Code__r.Name FROM Expense_Cash_Allocation__c WHERE Type__c =: CONSTANT.CASH_AND_PL_TYPE_PAYROLL_TAX];
       	Test.stopTest();
        system.assertEquals(expList[0].GL_Code__r.Name, 'Time and revenue');
    }
}
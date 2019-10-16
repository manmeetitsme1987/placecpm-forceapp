/* Class : BonusTriggerHandlerTest
 * Description : Test class for BonusTriggerHandlerTest
 * 
 * Change 1 :
 */
@isTest
public class BonusPlanTriggerHandlerTest {
    static List<Bonus_Plan__c> bonusPlanList = new List<Bonus_Plan__c>();
    static Organisation__c organisation;
    static GL_Code__c glaccount;
    static Role__c role;
    static Employee__c employeeRec;
    static Account acc;
    
    static void createtestData(){
        list<Profit_Loss__c> listPL = new list<Profit_Loss__c>();
        list<Cash_Forecast__c> listCashForecast = new list<Cash_Forecast__c>();
        map<Integer,String> mapMonthYear = new map<Integer,String>();
        mapMonthYear.put(3,'March 2020');
        mapMonthYear.put(4,'April 2020');
        mapMonthYear.put(5,'May 2020');
        mapMonthYear.put(6,'June 2020');
        mapMonthYear.put(7,'July 2020');
        mapMonthYear.put(8,'August 2020');
        Assumption__c assumptionRec = TestUtility.createAssumption(10,True);
        
        acc = TestUtility.createAccount('TestAccount1',True);
        organisation = TestUtility.createOrganisation('Place Technology', true); 
        P_L_Category__c plCategory = TestUtility.createPlCategory('General and Admin','Expense',true);
        glaccount = TestUtility.createGLCode('Recurring',600,plCategory.id,true);
        Location__c loc = new Location__c(Payment_Term__c ='Monthly', GL_Code__c = glaccount.Id, Tax__c = 17);
        insert loc;
        Department__c department = TestUtility.createDepartment('SFDC', organisation.Id, glaccount.Id, true);  
        role = TestUtility.createRole('Tester', department.Id ,true);
        
        employeeRec = TestUtility.createEmployee('TestEmployee',role.Id, System.today(),'Austin','Salaried Employee',CONSTANT.EMPLOYEE_OPERATIONS_RT,false);
        //employeeRec.Location__c  = loc.id;
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
    }
    
    @isTest
    public static void testBonusTriggerHandler(){
        createtestData();
        
        Expense_Account__c expenseAcc = TestUtility.createExpenseAccount(acc.Id, glaccount.Id, '1', true);
        Expense_Allocation__c expenseAlloc = TestUtility.createExpenseAllocation(expenseAcc.Id, false);
        expenseAlloc.Role__c = role.Id;
        insert expenseAlloc;
        
        Compensation__c com = TestUtility.createCompensation(date.newinstance(2020, 7, 1), date.newinstance(2020, 7, 31),employeeRec.id, 10,'Semi-Monthly', bonusPlanList[0].id,True);
        delete com;
        Compensation__c cmp = TestUtility.createCompensation(System.today(), System.today().addDays(45), employeeRec.Id , 50000, 'Monthly',bonusPlanList[1].id ,true);
    
        Wages__c wage = TestUtility.createWages(system.today(), system.today().addDays(3),employeeRec.Id , 1500, cmp.Id, 500, 1000, true);
        delete wage;
        System.assertEquals(2, [Select Id from Wages__c where Employee_Number__c =: employeeRec.Id].size());
        glaccount = TestUtility.createGLCode('Recurring1',800,glaccount.PL_Category__c ,true);
        Bonus_Plan__c bonus = bonusPlanList[1]; 
        bonus.GL_Account__c = glaccount.Id;
		bonus.Percentage__c = 20;
        update bonus;
        List<Wages__C> wageList = [Select Id,
                               (Select Id , GL_Code__c 
                                From Wage_Expense_Allocations__r 
                                WHERE Type__c =: CONSTANT.CASH_AND_PL_TYPE_BONUS)
                               From Wages__c
                               Where Compensation__c in 
                               (Select Id From Compensation__c
                                Where Bonus_Plan__c =: bonus.Id)];
         System.assertEquals(2, wageList.size());
    }
    
}
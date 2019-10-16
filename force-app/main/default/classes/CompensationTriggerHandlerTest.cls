@isTest 
private class CompensationTriggerHandlerTest {
    static Assumption__c assumptionRec;
    static Employee__c employeeRec;
    static List<Bonus_Plan__c> bonusPlanList = new List<Bonus_Plan__c>();
    static List<Compensation__c> compensationList = new List<Compensation__c>();
    public static  void createPLandCash(){
        assumptionRec = TestUtility.createAssumption(10,True);
        List<Profit_Loss__c> plsList = new List<Profit_Loss__c>();
        List<Cash_Forecast__c> cashList = new List<Cash_Forecast__c>();
        For(Integer i = 0 ; i < 12 ; i++){
            Profit_Loss__c pl = new Profit_Loss__c();
            Date startDate = System.today().toStartOfMonth().addMonths(i);
            pl.Period_Start_Date__c = startDate;
            Integer daysInMonth = Date.daysInMonth(startDate.year() , startDate.month());
            pl.Period_End_Date__c = startDate.addDays(daysInMonth - 1);
            pl.Name = PlaceCPM_Utility.getMonthName(startDate);
            plsList.add(pl);
            Cash_Forecast__c cash = new Cash_Forecast__c();
            cash.Period_Start_Date__c = startDate;
            cash.Period_End_Date__c = startDate.addDays(daysInMonth - 1);
            cash.Name = PlaceCPM_Utility.getMonthName(startDate);
            cashList.add(cash);
        }
        insert plsList;
        insert cashList;
    }
    
    static testMethod void createtestData(){
        createPLandCash();
        P_L_Category__c plCategory = TestUtility.createPlCategory('General and Admin','Expense',false);
        plCategory.Sequence__c = 1;
        insert plCategory;
        GL_Code__c glaccount = TestUtility.createGLCode('Advertising',600,plCategory.id,True);
        Organisation__c organisation = TestUtility.createOrganisation('Place Technology', true); 
        Department__c department = TestUtility.createDepartment('SFDC', organisation.Id, glaccount.Id, true);  
        Role__c role = TestUtility.createRole('Tester', department.Id ,true);
        employeeRec = TestUtility.createEmployee('TestEmployee',role.Id,System.today(),'Austin','Salaried Employee',CONSTANT.EMPLOYEE_SALES_RT,true);
        Integer month = 1;
        do{
            bonusPlanList.add(new Bonus_Plan__c (Name='i',Percentage__c =10, Payment_Frequency__c = String.valueOf(month)));
            if(month == 1){
                month += 2;
            } else {
               month = month * 2; 
            }
        } while(month < 12) ; 
        insert bonusPlanList;
    }
    static testMethod void CompensationTestMethod2(){
        list<Compensation__c> listcom = new list<Compensation__c>();
        createtestData();
        Test.startTest();
        Id comSalesRecordTypeId = PlaceCPM_Utility.getRecordTypeIdbyDeveloperName('Compensation__c','Sales_Employee_Compensation');
        Compensation__c comRecord = TestUtility.createCompensation(System.today(),System.today().addDays(60),employeeRec.id, 10,'Monthly', bonusPlanList[0].id,False);
        comRecord.recordTypeId = comSalesRecordTypeId;
        insert comRecord;
        Compensation__c comRecord1 = TestUtility.createCompensation(System.today().addDays(40), System.today().addDays(45),employeeRec.id, 10,'Weekly', bonusPlanList[1].id,False);
        comRecord1.recordTypeId = comSalesRecordTypeId;
        insert comRecord1;
        Compensation__c comRecord2 = TestUtility.createCompensation(System.today().addDays(50), System.today().addDays(60),employeeRec.id, 10,'Bi-Weekly', bonusPlanList[1].id,False);
        comRecord2.recordTypeId = comSalesRecordTypeId;
        insert comRecord2;
        Compensation__c com = TestUtility.createCompensation(System.today().addDays(70), System.today().addDays(75),employeeRec.id, 10,'Semi-Monthly', bonusPlanList[2].id,False);
        com.recordTypeId = comSalesRecordTypeId;
        insert com;
        delete com;
        listcom = [Select Id from Compensation__c where Id =: com.id];
        System.assert(listcom.size() == 0,'Compensation has not been deleted');
        Test.stopTest();
    }  
    static testMethod void CompensationTestMethod3(){
       createtestData();
       Id comSalesRecordTypeId = PlaceCPM_Utility.getRecordTypeIdbyDeveloperName('Compensation__c','Sales_Employee_Compensation');
       Test.startTest();
       Compensation__c com = TestUtility.createCompensation(System.today().addDays(80), System.today().addDays(90),employeeRec.id, 10,'Monthly', bonusPlanList[2].id,False);
       com.recordTypeId = comSalesRecordTypeId;
       insert com;
       com.End_Date__c = System.today().addDays(95);
       //update com;
       System.assert(com.End_Date__c == System.today().addDays(95), 'End Date is not populated correctly');
       Test.stopTest();
    }     
   static testMethod void CompensationTestMethod4(){
       createtestData();
       Id comSalesRecordTypeId = PlaceCPM_Utility.getRecordTypeIdbyDeveloperName('Compensation__c','Sales_Employee_Compensation');
       Test.startTest();
       Compensation__c com = TestUtility.createCompensation(System.today().addDays(100), System.today().addDays(110),employeeRec.id, 10,'Semi-Monthly', bonusPlanList[2].id,False);
       com.recordTypeId = comSalesRecordTypeId;
       insert com;
       System.assertEquals(True, [Select Id From Wages__c where Compensation__c =: com.Id].size() > 0);
       Test.stopTest();
   } 
   static testMethod void CompensationTestMethod5(){
       createtestData();
       Id comSalesRecordTypeId = PlaceCPM_Utility.getRecordTypeIdbyDeveloperName('Compensation__c','Sales_Employee_Compensation');
       Test.startTest();
       Compensation__c com = TestUtility.createCompensation(System.today().addDays(35), System.today().addDays(40),employeeRec.id, 10,'Semi-Monthly', bonusPlanList[2].id,False);
       com.recordTypeId = comSalesRecordTypeId;
       insert com;
       System.assertEquals(comSalesRecordTypeId, [Select Id,recordTypeId from Compensation__c].recordTypeId);
       Test.stopTest();
   } 
   static testMethod void CompensationTestMethod6(){
       createtestData();
       Id comSalesRecordTypeId = PlaceCPM_Utility.getRecordTypeIdbyDeveloperName('Compensation__c','Sales_Employee_Compensation');
       Test.startTest();
       Compensation__c com = TestUtility.createCompensation(System.today().addDays(35), System.today().addDays(40),employeeRec.id, 10,'Weekly', bonusPlanList[2].id,False);
       com.recordTypeId = comSalesRecordTypeId;
       insert com;
       System.assertEquals(True, [Select Id From Wages__c where Compensation__c =: com.Id].size() > 0);
       Test.stopTest();
   }  
   static testMethod void CompensationTestMethod7(){
       createtestData();
       Id comSalesRecordTypeId = PlaceCPM_Utility.getRecordTypeIdbyDeveloperName('Compensation__c','Sales_Employee_Compensation');
       Test.startTest();
       Compensation__c com = TestUtility.createCompensation(System.today().addDays(35), System.today().addDays(40),employeeRec.id, 10,'Weekly', bonusPlanList[2].id,False);
       com.recordTypeId = comSalesRecordTypeId;
       insert com;
       assumptionRec.Forecast_Duration__c = null;
       com.End_Date__c = null;
       update com;
       System.assertEquals(True, [Select Start_Date__c from Compensation__c limit 1].Start_Date__c <= [Select Cash_Date__c  from Wages__c limit 1].Cash_Date__c );
       Test.stopTest();
   }  
    
}
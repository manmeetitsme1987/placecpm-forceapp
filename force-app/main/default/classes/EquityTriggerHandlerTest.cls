/*
Description  : This class will cover testing of funactionality related to Equity and its functional behavior.
Created On   : 5th of September 2019 
Version      : 1 
*/
@isTest(seeAllData = false)
public class EquityTriggerHandlerTest {
	public static List<Equity__c> equities;
    public static List<Account> accountList;
    public static List<Revenue_Contract__c> revenueContractList;
    public static List<GL_Code__c> glCodeList;
    public static List<Contract_Line_Items__c> listContractLineItems;
    public static Employee__c employee;
    public static Department__c department;
    public static Role__c role;
    public static Quota__c quota;
    
    private static void createData(){
        TestUtility.createAssumption(24,true);
        accountList= new List<Account>();
        glCodeList = new List<GL_Code__c>();
        listContractLineItems = new List<Contract_Line_Items__c>();
        accountList.add(TestUtility.createAccount('testAccount',true));
        glCodeList.add(TestUtility.createGLCode('test GL code',1111,TestUtility.createPlCategory('test PL category','Revenue',true).Id,true));
    }
    
    @isTest
    public static void testEquity(){
        integer totalRec = 20;
        createData();
        test.startTest();
        equities = new List<Equity__c>();
        for(integer i=0;i<totalRec;i++){
            equities.add(TestUtility.createEquity('Contribution','Equity:'+i, accountList[0].id, glCodeList[0].id, 500, date.today(), false));
        }
        INSERT equities;
        
        UPDATE equities; //Blank update to check recursion blocker
        
        List<Revenue_Cash_Allocation__c> revenueCash = [SELECT Id, Cash_Forecast__c, Forecast_Amount__c, Cash_Date__c, GL_Code__c FROM Revenue_Cash_Allocation__c WHERE Equity__c IN :equities];
        system.assert(revenueCash.size() == totalRec);
        system.assert(revenueCash[5].Forecast_Amount__c == 500 && revenueCash[4].Cash_Date__c == date.today());
        
        for(integer i=0;i<5;i++){
            equities[i].Type__c = 'Draw';
            equities[i].Amount__c = 300;
        }
        EquityTriggerHandler.hasAlreadyRun = false;
        UPDATE equities;
        
        revenueCash = [SELECT Id, Cash_Forecast__c, Forecast_Amount__c, Cash_Date__c, GL_Code__c FROM Revenue_Cash_Allocation__c WHERE Equity__c IN :equities AND Forecast_Amount__c <0];
        system.assert(revenueCash.size() == 5);
        system.assert(revenueCash[3].Forecast_Amount__c == -300 && revenueCash[2].Cash_Date__c == date.today());
        
        EquityTriggerHandler.hasAlreadyRun = false;
        DELETE equities;
        revenueCash = [SELECT Id, Cash_Forecast__c, Forecast_Amount__c, Cash_Date__c, GL_Code__c FROM Revenue_Cash_Allocation__c WHERE Equity__c IN :equities AND Forecast_Amount__c <0];
        system.assert(revenueCash.isEmpty());
        
        test.stopTest();
    }
}
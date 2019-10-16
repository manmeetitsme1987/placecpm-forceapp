/*
Class Name   : RevenueAccountTriggerTest
Description  : This class will cover funactionality related to Revenue Account object.

Change 1 :  1 SEPT 19 
*/
@isTest
public class RevenueAccountTriggerTest {
     public static List<Revenue_Account__c> revenueAccountList;
    public static List<Payment_Account__c> paymentAccountList;
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
        paymentAccountList = new List<Payment_Account__c>();
        revenueAccountList = new List<Revenue_Account__c>();
        glCodeList = new List<GL_Code__c>();
        listContractLineItems = new List<Contract_Line_Items__c>();
        accountList.add(TestUtility.createAccount('testAccount',true));
        paymentAccountList.add(TestUtility.createPaymentAccount('testPaymentAccount',true));
        glCodeList.add(TestUtility.createGLCode('test GL code',1111,TestUtility.createPlCategory('test PL category','Revenue',true).Id,true));
        revenueAccountList.add(TestUtility.createRevenueAccount(accountList[0].Id,glCodeList[0].Id,paymentAccountList[0].Id,'1',false));
        String recordTypeIdEmployee = Schema.SObjectType.Employee__c.getRecordTypeInfosByName().get('Sales Employee').getRecordTypeId();
        
        department = TestUtility.createDepartment('test department', TestUtility.createOrganisation('Org test',true).Id,glCodeList[0].Id,true);
        role = TestUtility.createRole('Role Name',department.id,true);
        employee = TestUtility.createEmployee('Test employee',role.Id,System.today(),'Austin','Salaried Employee',recordTypeIdEmployee,true);
        quota = TestUtility.createQuota(employee.Id,100.0,System.today(),system.today().addMonths(1),glCodeList[0].Id,true);
        
        
    }
    
    @isTest
    public static void testInvesmtent(){
        createData();
        System.debug('employee.Id'+employee.Id);
        revenueAccountList[0].Account_Executive__c =employee.Id;
        insert revenueAccountList;
        
        //Update case
        revenueAccountList[0].Name = 'test updated';
        revenueAccountList[0].Quota__c = quota.Id;
        //revenueAccountList[0].Account_Executive__c =employee.Id;
        update revenueAccountList;
        //Making quota null
        revenueAccountList[0].Quota__c = null;
        update revenueAccountList;
        
        //Delete Case
        delete revenueAccountList;
        
        //assert
        System.assertEquals(1, [Select Id from Employee__c where Name = 'Test employee'].size());
    }
}
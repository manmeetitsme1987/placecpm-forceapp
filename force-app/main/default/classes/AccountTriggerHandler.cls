/*
Class Name   : AccountTriggerHandler | PCPM-304
Description  : This class will be used for writing all the functionalities of Different Trigger Events related to Account object.
Date Created : 18 July 2019

Change 1 :  PCPM-316 | 22 JULY 19 | Namita
// Comment put by Manmeet to test the retrive by Salesforce CLI
*/

public with sharing class AccountTriggerHandler implements CommonTriggerHandler{
    public void BeforeInsert(List<SObject> newItems){
        
    }
    
    public void BeforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems){
       
    }
    
    public void BeforeDelete(Map<Id, SObject> oldItems){
    }
    
    public void AfterInsert(Map<Id, SObject> newItems){
        
    }    
    public void AfterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems){
        populateExpenseAccNameOnVendorUpdate((List<Account>)newItems.values(),(Map<Id, Account>)oldItems); //PCPM-316
    }

    public void AfterDelete(Map<Id, SObject> oldItems){
    }
    
    public void AfterUndelete(Map<Id, SObject> oldItems){
    }
    
    public Boolean IsDisabled(){
        return false;
    }
    
    //  Method for after Update Account to populate Expense Account Name.
    //  @param1 newAccountList is the list of New Expense_Account__c Records.
    //  @param2 mapOldAccounts is map of old accounts
    //  @return void
    public static void populateExpenseAccNameOnVendorUpdate(List<Account> newAccountList, Map<Id, Account> mapOldAccounts){
        List<Expense_Account__c> vendorExpenseAccountList = new List<Expense_Account__c>();
        List<Revenue_Account__c> vendorRevenueAccountList = new List<Revenue_Account__c>(); //PCPM-316
        Map<String, Account> accountMap = new Map<String, Account>();
        
        for(Account acc : newAccountList){
            if(acc.Name != mapOldAccounts.get(acc.Id).Name){
                accountMap.put(acc.Id, acc);
            }
        }
        
        if(accountMap.size() > 0){
            
            if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.expenseAccountObject,'Id, Name, Vendor__c',Constant.ACTION_TYPE_ACCESS)){
                for(Expense_Account__c expenseAcc : [Select Id, Name, Vendor__c, Vendor__r.Name
                                                 FROM Expense_Account__c 
                                                 WHERE Vendor__c IN : accountMap.keySet()]){
                    expenseAcc.Name = expenseAcc.Name.replace(mapOldAccounts.get(expenseAcc.Vendor__c).Name + ' - ', accountMap.get(expenseAcc.Vendor__c).Name + ' - ');
                    vendorExpenseAccountList.add(expenseAcc);
                }
            }     
            //PCPM-316
            
            if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.revenueAccountObject,'Id, Name, Account__c',Constant.ACTION_TYPE_ACCESS)){
                for(Revenue_Account__c revenueAcc : [SELECT Id, Name, Account__c, Account__r.Name 
                                                     FROM Revenue_Account__c
                                                     WHERE Account__c IN : accountMap.keySet()]){
                      revenueAcc.Name = revenueAcc.Name.replace(mapOldAccounts.get(revenueAcc.Account__c).Name + ' - ', accountMap.get(revenueAcc.Account__c).Name + ' - ');    
                      vendorRevenueAccountList.add(revenueAcc);
                }
            }    
        }
        try{
            ExpenseAccountTriggerHandler.isRunExpenseAccountTriggerHandler = false;
            RevenueAccountTriggerHandler.isRunRevenueAccountTriggerHandler = false; //PCPM-316
            PlaceCPM_Utility.updateRecords(vendorExpenseAccountList, CONSTANT.expenseAccountObject, false); // PCPM-520
            PlaceCPM_Utility.updateRecords(vendorRevenueAccountList, CONSTANT.revenueAccountObject, false); // PCPM-520
        }catch(Exception ex){
            PlaceCPM_Utility.debugLog(ex.getMessage() + ' at line number ' + ex.getLineNumber());
        }
    }
}
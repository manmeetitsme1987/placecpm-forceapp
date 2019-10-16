/*
Class Name   : RevenueAccountTriggerHandler 
Description  : This class will be used for writing all the functionalities of Different Trigger Events related to Revenue Account object.

Change 1 :  PCPM-316 | 22 JULY 19 | Namita
*/

public with sharing class RevenueAccountTriggerHandler implements CommonTriggerHandler{
    public static Boolean isRunRevenueAccountTriggerHandler = true;//PCPM-316
    
    public void BeforeInsert(List<SObject> newItems){
        handleBeforeInsert(newItems);
    }
    
    public void BeforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems){
       //PCPM-316
        handleBeforeUpdate((List<Revenue_Account__c> )newItems.values(), (Map<Id, Revenue_Account__c>) oldItems);
    }
    
    public void BeforeDelete(Map<Id, SObject> oldItems){
        deletePlAndCashAllocation((Map<Id, Revenue_Account__c>)oldItems);
    }
    
    public void AfterInsert(Map<Id, SObject> newItems){
    }
    
    public void AfterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems){
    }
    
    public void AfterDelete(Map<Id, SObject> oldItems){
       
    }
    
    public void AfterUndelete(Map<Id, SObject> oldItems){
    }
    
    public Boolean IsDisabled(){
        return false;
    }
   
    public void handleBeforeInsert(List<Revenue_Account__c> newItems) {
        updateUniqueId(newItems);
         // PCPM-316
        if(isRunRevenueAccountTriggerHandler){
            populateAndUpdateRevenueAccName(newItems, null);
        }
    }
    public void handleBeforeUpdate(List<Revenue_Account__c> newItems, Map<Id, Revenue_Account__c> oldItems) {
        updateUniqueId(newItems);
        // PCPM-316
        if(isRunRevenueAccountTriggerHandler){
            populateAndUpdateRevenueAccName(newItems, oldItems);
        }
    }
    
    public void updateUniqueId(List<Revenue_Account__c> newItems) {
        Boolean isUniqueId = false;
        if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.revenueAccountObject,'Unique_Id__c',Constant.ACTION_TYPE_UPDATE)){
            isUniqueId = true;
        }
        for(Revenue_Account__c ra : newItems) {
            if(ra.Account__c != null && ra.GL_Code__c != null) {
                
                if(isUniqueId){
                    ra.Unique_Id__c = ra.Account__c+'-'+ra.GL_Code__c;
                }
            }
        }
    }
    
     /* This method will delete related P&L and Cash Allocation of revenue account.
     * @param 
       oldItems : Map of new Revenue_Account__c records to revenue Id
       @return null
      */
    public void deletePlAndCashAllocation(Map<Id, Revenue_Account__c> oldItems) {
        try{
            PlaceCPM_Utility.deleteRecords([Select Id From Revenue_Cash_Allocation__c Where Revenue_Account__c  in: oldItems.keySet()], CONSTANT.REVENUE_CASH_ALLOCATION_OBJECT, false); //520

            PlaceCPM_Utility.deleteRecords([Select Id From Revenue_P_L_Allocation__c Where Revenue_Account__c  in: oldItems.keySet()], CONSTANT.REVENUE_PL_ALLOCATION_OBJECT, false); //520

        } catch(Exception ex) {
            PlaceCPM_Utility.debugLog('Exception : == ' + ex.getMessage() + ' at line number ' + ex.getLineNumber());
        }
    }

    // PCPM-316
    //  Method for before Insert and Update to populate Revenue Account Name.
    //  @param1 newRevenueAccountList is the list of New Revenue_Account__c  Records.
    //  @param2 mapOldRevenueAccounts is map of old Revenue Accounts
    //  @return void
    public static void populateAndUpdateRevenueAccName(List<Revenue_Account__c > newRevenueAccountList, Map<Id, Revenue_Account__c > mapOldRevenueAccounts){
        Map<String,Account> vendorMap = new Map<String,Account>();
        Map<String,Employee__c> employeeMap = new Map<String,Employee__c>();
        Boolean isInsert = mapOldRevenueAccounts == null;
        for(Revenue_Account__c  revenueAcc : newRevenueAccountList){
            if(isInsert || (revenueAcc.Account__c  != mapOldRevenueAccounts.get(revenueAcc.id).Account__c ) 
                        || (revenueAcc.Name != mapOldRevenueAccounts.get(revenueAcc.id).Name)
                        || (revenueAcc.Quota__c != null && revenueAcc.Account_Executive__c != mapOldRevenueAccounts.get(revenueAcc.id).Account_Executive__c) 
            ){ 
                if(revenueAcc.Account__c  != null && revenueAcc.Quota__c == null){
                    vendorMap.put(revenueAcc.Account__c, new Account());
                }  
                if(!isInsert && mapOldRevenueAccounts.get(revenueAcc.id).Account__c  != null && revenueAcc.Quota__c == null){
                	vendorMap.put(mapOldRevenueAccounts.get(revenueAcc.id).Account__c , new Account());    
                } 
                if(revenueAcc.Quota__c != null){
                    employeeMap.put(revenueAcc.Account_Executive__c, new Employee__c());
                } 
                if(!isInsert && revenueAcc.Quota__c != null && mapOldRevenueAccounts.get(revenueAcc.id).Account_Executive__c != null){
                	employeeMap.put(mapOldRevenueAccounts.get(revenueAcc.id).Account_Executive__c , new Employee__c());    
                } 
            }
        }
        
        //quering Name field 
        for(Employee__c employee : [SELECT Id, Name FROM Employee__c WHERE ID IN : employeeMap.keySet()]){
           employeeMap.put(employee.Id, employee);
        }
        //quering Name field 
        for(Account acc : [SELECT Id, Name FROM Account WHERE ID IN : vendorMap.keySet()]){
           vendorMap.put(acc.Id, acc);
        }
       
        for(Revenue_Account__c  revenueAcc : newRevenueAccountList){
            if(vendorMap.containsKey(revenueAcc.Account__c)){
                if(isInsert){
                    revenueAcc.Name = vendorMap.get(revenueAcc.Account__c).Name + ' - '+ revenueAcc.Name;
                }else{
                    if(vendorMap.containsKey(mapOldRevenueAccounts.get(revenueAcc.Id).Account__c) && revenueAcc.Name.contains(vendorMap.get(mapOldRevenueAccounts.get(revenueAcc.Id).Account__c).Name)){
                        String oldVendorName = vendorMap.get(mapOldRevenueAccounts.get(revenueAcc.Id).Account__c).Name;
                        revenueAcc.Name = revenueAcc.Name.replace(oldVendorName, vendorMap.get(revenueAcc.Account__c).Name);
                    }else{
                        revenueAcc.Name = vendorMap.get(revenueAcc.Account__c).Name + ' - '+ revenueAcc.Name;
                    }
                }
            }else{
                if(!isInsert && mapOldRevenueAccounts.get(revenueAcc.Id).Account__c != null && vendorMap.containsKey(mapOldRevenueAccounts.get(revenueAcc.Id).Account__c)){
                    revenueAcc.Name = revenueAcc.Name.replace(vendorMap.get(mapOldRevenueAccounts.get(revenueAcc.Id).Account__c).Name + ' - ','');
                } 
            }
            
            if(employeeMap.containsKey(revenueAcc.Account_Executive__c)){
                if(isInsert){
                    revenueAcc.Name = employeeMap.get(revenueAcc.Account_Executive__c).Name + ' - '+ revenueAcc.Name;
                }else{
                    if(employeeMap.containsKey(mapOldRevenueAccounts.get(revenueAcc.Id).Account_Executive__c) && revenueAcc.Name.contains(employeeMap.get(mapOldRevenueAccounts.get(revenueAcc.Id).Account_Executive__c).Name)){
                        String oldEmployeeName = employeeMap.get(mapOldRevenueAccounts.get(revenueAcc.Id).Account_Executive__c).Name;
                        revenueAcc.Name = revenueAcc.Name.replace(oldEmployeeName, employeeMap.get(revenueAcc.Account_Executive__c).Name);
                    }else{
                        revenueAcc.Name = employeeMap.get(revenueAcc.Account_Executive__c).Name + ' - '+ revenueAcc.Name;
                    }
                }
            }else{
                if(!isInsert && mapOldRevenueAccounts.get(revenueAcc.Id).Account_Executive__c != null && employeeMap.containsKey(mapOldRevenueAccounts.get(revenueAcc.Id).Account_Executive__c)){
                    revenueAcc.Name = revenueAcc.Name.replace(employeeMap.get(mapOldRevenueAccounts.get(revenueAcc.Id).Account_Executive__c).Name + ' - ','');
                } 
            }
        } //end for 
    }//end of populateAndUpdateRevenueAccName method
}
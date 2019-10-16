/*
Description : This class will be used for writing all the functionalities of Different Trigger Events related to Expense_Account__c object.
Date Created : 22 June 2019
Functionality Included:  When Expense Account is Created, Create Employee Expense Allocation Records.

Change 1 : PCPM-304 | Namita | 17 July 19 | Added method populateAndUpdateExpenseAccName on before insert and update
*/
public with sharing class ExpenseAccountTriggerHandler implements CommonTriggerHandler{
    public static Boolean isRunExpenseAccountTriggerHandler = true;
    
    public void BeforeInsert(List<SObject> newItems){
        // PCPM-304
        if(isRunExpenseAccountTriggerHandler){
            populateAndUpdateExpenseAccName((List<Expense_Account__c>)newItems, null);
        }
    }
    
    public void BeforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems){
        // PCPM-304
        if(isRunExpenseAccountTriggerHandler){
        	populateAndUpdateExpenseAccName((List<Expense_Account__c>)newItems.values(),(Map<Id, Expense_Account__c>)oldItems);
        }
    }
    
    public void BeforeDelete(Map<Id, SObject> oldItems){
        //Validate if Expense Details are not in Past and Delete.
        validateAndDelete((Map<Id, Expense_Account__c>)oldItems);
    }
    
    public void AfterInsert(Map<Id, SObject> newItems){
        //createEmployeeExpenseAllocation((List<Expense_Account__c> )newItems.values() );
    }
    //  This method will will run for all after update events
    //  @param newItems, Map of Expense Account Id and Expense Account records
    //  @param oldItems, Map of old Expense Account Id and Expense Account records
    //  @return void
    public void AfterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems){
        //PCPM -320
        updateExpenseGLAcc((Map<Id, Expense_Account__c>) newItems, (Map<Id, Expense_Account__c>) oldItems);
        //createEmployeeExpenseAllocation((List<Expense_Account__c> )newItems.values());
        //#321
        onPaymentFrequencyUpdate((Map<Id, Expense_Account__c>) newItems,(Map<Id, Expense_Account__c>) oldItems);
    }

    public void AfterDelete(Map<Id, SObject> oldItems){
    }
    
    public void AfterUndelete(Map<Id, SObject> oldItems){
    }
    
    public Boolean IsDisabled(){
        return false;
    }
    
    //  Method for After Insert event, to Create Employee Allocation Records based on Role Profile.
    //  @param newExpenseAccounts is the list of New Expense_Account__c Records.
    //  @return void
    /*public static void createEmployeeExpenseAllocation(List<Expense_Account__c> newExpenseAccounts){
        Map<String, List<Expense_Account__c>> mapEmpRoleExpenses = new Map<String, List<Expense_Account__c>>();
        List<Employee_Expense_Allocation__c> listTOInsertEEA = new List<Employee_Expense_Allocation__c>();
        
        for(Expense_Account__c expA: newExpenseAccounts){
            if(expA.Employee_Role_Profile__c != null){
                if(!mapEmpRoleExpenses.containsKey(expA.Employee_Role_Profile__c )){
                    mapEmpRoleExpenses.put(expA.Employee_Role_Profile__c, new List<Expense_Account__c>());
                }
                mapEmpRoleExpenses.get(expA.Employee_Role_Profile__c).add(expA);
            }
        }
        for(Employee__c emp:[Select Id, Name, Employee_Role_Profile__c from Employee__c where Employee_Role_Profile__c IN: mapEmpRoleExpenses.keySet()]){
            If(emp.Employee_Role_Profile__c != null && mapEmpRoleExpenses.containsKey(emp.Employee_Role_Profile__c)){
                for(Expense_Account__c expAcc: mapEmpRoleExpenses.get(emp.Employee_Role_Profile__c)){
                    Employee_Expense_Allocation__c allocation = new Employee_Expense_Allocation__c();
                    if(Schema.sObjectType.Employee_Expense_Allocation__c.fields.Employee__c.isCreateable()){
                        allocation.Employee__c = emp.Id;
                    }
                    if(Schema.sObjectType.Employee_Expense_Allocation__c.fields.Expense_Account__c.isCreateable()){
                    allocation.Expense_Account__c= expAcc.Id;
                    }
                    if(Schema.sObjectType.Employee_Expense_Allocation__c.fields.Start_Date__c.isCreateable()){        allocation.Start_Date__c=date.newinstance(expAcc.createdDate.year(), expAcc.createdDate.month(), expAcc.createdDate.day());
                    }

                    listTOInsertEEA.add(allocation);
                }        
            }
        }
        PlaceCPM_Utility.insertRecords(listTOInsertEEA, 'Employee_Expense_Allocation__c', false);
    }*/

    //  Method for before Delete to validate, if the Record can be deleted or not.
    //  @param newExpenseAccounts is the list of New Expense_Account__c Records.
    //  @return void
    public static void validateAndDelete(Map<Id, Expense_Account__c> mapExpAccounts){
        List<Expense_Detail__c> listExpDetailsToDelete = new List<Expense_Detail__c>();
        Map<String, List<Expense_Detail__c>> mapToDeleteExpDetails = new  Map<String, List<Expense_Detail__c>>();
        Set<String> setErrorIds = new Set<String>();
        if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.EXPENSE_DETAIL_OBJECT,'Start_Date__c',Constant.ACTION_TYPE_ACCESS)){
            for(Expense_Detail__c expDet: [Select id, Start_Date__c, Expense_Account__c From Expense_Detail__c where Expense_Account__c IN: mapExpAccounts.keySet()]){
                if(!mapToDeleteExpDetails.containsKey(expDet.Expense_Account__c)){
                    mapToDeleteExpDetails.put(expDet.Expense_Account__c, new List<Expense_Detail__c>());
                }
                mapToDeleteExpDetails.get(expDet.Expense_Account__c).add(expDet);
                if(expDet.Start_Date__c < system.today()){
                     setErrorIds.add(expDet.Expense_Account__c);
                     mapExpAccounts.get(expDet.Expense_Account__c).addError(System.Label.Expense_Account_Has_Past_Details);
                }
            }
    	}
        if(mapExpAccounts.keySet() != null && !mapExpAccounts.keySet().isEmpty()){
            for(String str: mapExpAccounts.keySet()){
               if(!setErrorIds.contains(str) && mapToDeleteExpDetails.containsKey(str)){
                   listExpDetailsToDelete.addAll(mapToDeleteExpDetails.get(str));
               }
            }
        }
        PlaceCPM_Utility.deleteRecords(listExpDetailsToDelete, CONSTANT.EXPENSE_DETAIL_OBJECT, false); //520
    }

    // PCPM-304
    //  Method for before Insert and Update to populate Expense Account Name.
    //  @param1 newExpenseAccounts is the list of New Expense_Account__c Records.
    //  @param2 mapOldExpenseAccounts is map of old ExpenseAccounts
    //  @return void
    public static void populateAndUpdateExpenseAccName(List<Expense_Account__c> newExpenseAccountList, Map<Id, Expense_Account__c> mapOldExpenseAccounts){
        Map<String,Account> vendorMap = new Map<String,Account>();
        Boolean isInsert = mapOldExpenseAccounts == null;
        
        for(Expense_Account__c expenseAcc : newExpenseAccountList){
            if(isInsert || (expenseAcc.Vendor__c != mapOldExpenseAccounts.get(expenseAcc.id).Vendor__c) || (expenseAcc.Name != mapOldExpenseAccounts.get(expenseAcc.id).Name)){ 
                if(expenseAcc.Vendor__c != null){
                    vendorMap.put(expenseAcc.Vendor__c, new Account());
                }        
                if(!isInsert && mapOldExpenseAccounts.get(expenseAcc.id).Vendor__c != null){
                	vendorMap.put(mapOldExpenseAccounts.get(expenseAcc.id).Vendor__c, new Account());    
                }
            }
        }
        
        //quering Name field 
        for(Account acc : [SELECT Id, Name FROM Account WHERE ID IN : vendorMap.keySet()]){
           vendorMap.put(acc.Id, acc);
        }
        
        for(Expense_Account__c expenseAcc : newExpenseAccountList){
            if(vendorMap.containsKey(expenseAcc.Vendor__c)){
                if(isInsert){
                    expenseAcc.Name = vendorMap.get(expenseAcc.Vendor__c).Name + ' - '+ expenseAcc.Name;
                }else{
                    if(vendorMap.containsKey(mapOldExpenseAccounts.get(expenseAcc.Id).Vendor__c) && expenseAcc.Name.contains(vendorMap.get(mapOldExpenseAccounts.get(expenseAcc.Id).Vendor__c).Name)){
                        String oldVendorName = vendorMap.get(mapOldExpenseAccounts.get(expenseAcc.Id).Vendor__c).Name;
                        expenseAcc.Name = expenseAcc.Name.replace(oldVendorName, vendorMap.get(expenseAcc.Vendor__c).Name);
                    }else{
                        expenseAcc.Name = vendorMap.get(expenseAcc.Vendor__c).Name + ' - '+ expenseAcc.Name;
                    }
                }
            }else{
                if(!isInsert && mapOldExpenseAccounts.get(expenseAcc.Id).Vendor__c != null && vendorMap.containsKey(mapOldExpenseAccounts.get(expenseAcc.Id).Vendor__c)){
                    expenseAcc.Name = expenseAcc.Name.replace(vendorMap.get(mapOldExpenseAccounts.get(expenseAcc.Id).Vendor__c).Name + ' - ','');
                }           
            }
        } //end for 
    }//end of populateAndUpdateExpenseAccName method
    
    // PCPM-320
    // Method for after Update to upadte GL Account on Expense PL Allocation.
    // @param1 newExpenseAccounts is the list of New Expense_Account__c Records.
    // @param2 mapOldExpenseAccounts is map of old ExpenseAccounts
    // @return void
    public static void updateExpenseGLAcc(Map<Id,Expense_Account__c> newExpenseAccountList, Map<Id, Expense_Account__c> mapOldExpenseAccounts){
        List<Expense_PL_Allocation__c> expensePlAllocation = new List<Expense_PL_Allocation__c>();
        List<Expense_Account__c> expenseAccountList = new List<Expense_Account__c>();
        for(Expense_Account__c expenseAcc : newExpenseAccountList.values()) {
            if(expenseAcc.GL_Code__c != null 
               && expenseAcc.GL_Code__c != mapOldExpenseAccounts.get(expenseAcc.Id).GL_Code__c) {
                   expenseAccountList.add(expenseAcc);
               }
        }
        if(expenseAccountList.size() > 0){
            if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.EXPENSE_PL_ALLOCATION_OBJECT,'Expense_Account__c',Constant.ACTION_TYPE_ACCESS)){
                for(Expense_PL_Allocation__c  expensePl : [Select Id, GL_Code__c,Expense_Account__c  From Expense_PL_Allocation__c Where Expense_Account__c in: expenseAccountList]) {
                        expensePl.GL_Code__c = newExpenseAccountList.get(expensePl.Expense_Account__c).GL_Code__c;
                        expensePlAllocation.add(expensePl);
                }
        	}
            PlaceCPM_Utility.updateRecords(expensePlAllocation, CONSTANT.EXPENSE_PL_ALLOCATION_OBJECT, false); //520
        }
    }
    
//#321
//  Method for After Update event, to update the Payment Frequency
    //  @param 
    //  @ newItems is the list of New Expense_Account__c Records.
    //  @ oldItems is the list of Old Expense_Account__c Records.
    //  @return void
	private void onPaymentFrequencyUpdate(Map<Id, Expense_Account__c> newItems, Map<Id, Expense_Account__c> oldItems){
        List<Expense_Account__c> listExpenseAccount = new List<Expense_Account__c>();
        Set<Expense_PL_Allocation__c> setToExpla= new Set<Expense_PL_Allocation__c>();
        List<Expense_PL_Allocation__c> listExpla= new List<Expense_PL_Allocation__c>();
        Set<Expense_Cash_Allocation__c> setToExcla= new Set<Expense_Cash_Allocation__c>();
        List<Expense_Cash_Allocation__c> listExca= new List<Expense_Cash_Allocation__c>();
        for(Expense_Account__c ea:newItems.values()){
            if(ea.Payment_Frequency__c != oldItems.get(ea.Id).Payment_Frequency__c){
                listExpenseAccount.add(ea);
            }
        }
        List<Expense_Detail__c> listExpenseDetail;
        if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.EXPENSE_DETAIL_OBJECT,'Expense_Amount__c,Start_Date__c,End_Date__c,Auto_Renew__c,Payment_Frequency__c,Invoice_Date__c, Payment_Term_After_Days__c,RecordTypeId,Vendor_Id__c,Monthly_Expense_Amount__c, GL_Account_Id__c',Constant.ACTION_TYPE_ACCESS)){
            listExpenseDetail = [SELECT ID,Expense_Account__c,Expense_Amount__c,Start_Date__c,End_Date__c,Auto_Renew__c,
                                                         Payment_Frequency__c,Invoice_Date__c, Payment_Term_After_Days__c,RecordTypeId,Vendor_Id__c,
                                                         Monthly_Expense_Amount__c, GL_Account_Id__c,
                                                         (SELECT ID FROM Expense_P_L_Allocations__r),
                                                         (SELECT ID FROM Expense_Cash_Allocations__r) 
                                                         FROM Expense_Detail__c WHERE Expense_Account__c IN :listExpenseAccount AND Invoice_Date__c > TODAY];
    	}
        for(Expense_Detail__c ed:listExpenseDetail){
            for(Expense_PL_Allocation__c expla:ed.Expense_P_L_Allocations__r){
                setToExpla.add(expla);
        }
            for(Expense_Cash_Allocation__c exca:ed.Expense_Cash_Allocations__r){
                setToExcla.add(exca);
            }
        }
        listExpla.addAll(setToExpla);
        listExca.addAll(setToExcla);
        PlaceCPM_Utility.deleteRecords(listExpla, CONSTANT.EXPENSE_PL_ALLOCATION_OBJECT, false); //520
        PlaceCPM_Utility.deleteRecords(listExca, CONSTANT.EXPENSE_CASG_ALLOCATION_OBJECT, false); //520
        ExpenseDetailTriggerHandler.createPnlAndCashAllocations(listExpenseDetail);
    }
}
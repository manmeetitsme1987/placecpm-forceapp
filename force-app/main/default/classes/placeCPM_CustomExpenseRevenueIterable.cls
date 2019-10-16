/*
 Created Date :  19 June 2019
 Class Name   :  placeCPM_CustomExpenseRevenueIterable
 Description  :  PCPM-67 & 72 | Custom Iterable class for Expense and Revenue Accounts  

 Change 1     :
*/

public with sharing class placeCPM_CustomExpenseRevenueIterable implements Iterator<SObject>{
	public List<SObject> sobjs {get; set;} 
    Integer i {get; set;} 
    
    public placeCPM_CustomExpenseRevenueIterable(){
        sobjs = new List<SObject>();
        
        if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.expenseAccountObject,'ID ,Payment_Frequency__c',Constant.ACTION_TYPE_ACCESS) &&
           PlaceCPM_Utility.checkAccessiblityOfFields(Constant.EXPENSE_DETAIL_OBJECT,'id , Start_Date__c, End_Date__c,Auto_Renew__c,Invoice_Date__c,Payment_Frequency__c,'+
           'GL_Account_Id__c,Vendor_Id__c,Monthly_Expense_Amount__c,Payment_Term_After_Days__c',Constant.ACTION_TYPE_ACCESS) &&
           PlaceCPM_Utility.checkAccessiblityOfFields(Constant.expenseAccountObject,'ID ,Payment_Frequency__c,Vendor__c',Constant.ACTION_TYPE_ACCESS)){
            for( Expense_Account__c expDetailAcc : [SELECT ID ,Payment_Frequency__c,
                                                           (SELECT id , Start_Date__c, End_Date__c, 
                                                                    Auto_Renew__c,Invoice_Date__c,Payment_Frequency__c, 
                                                                    Expense_Account__r.Id , Expense_Account__r.Vendor__c , 
                                                                    GL_Account_Id__c,Vendor_Id__c,Monthly_Expense_Amount__c,
                                                                    Payment_Term_After_Days__c From Expense_Details__r 
                                                                    WHERE Start_Date__c != null AND 
                                                                    (End_Date__c = null OR (End_Date__c != null AND Auto_Renew__c = true))                          
                                                                    ORDER BY Start_Date__c DESC LIMIT 1),
                                                            (SELECT Id, P_L__r.Period_Start_Date__c, P_L__c FROM 
                                                                     Wage_Expense_Allocations__r 
                                                                     ORDER BY P_L__r.Period_Start_Date__c DESC LIMIT 1)                                                                 
                                                            FROM Expense_Account__c]) {
                sobjs.add(expDetailAcc);
           }
    	} 
       if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.revenueAccountObject,'ID , GL_Code__c , Billing_Cycle__c',Constant.ACTION_TYPE_ACCESS) &&
          PlaceCPM_Utility.checkAccessiblityOfFields(Constant.REVENUE_CONTRACT_OBJECT,'id,Contract_Start_Date__c,Contract_End_Date__c,Revenue_Account__c, Auto_Renew__c, Contract_Months__c,Invoice_Date__c,Payment_Term_After_Days__c,Total_Monthly_Revenue__c',Constant.ACTION_TYPE_ACCESS) && 
          PlaceCPM_Utility.checkAccessiblityOfFields(Constant.REVENUE_PL_ALLOCATION_OBJECT,'Id, Period_Start_Date__c',Constant.ACTION_TYPE_ACCESS)){
       for( Revenue_Account__c revenueAccount : [SELECT ID , GL_Code__c , Billing_Cycle__c,
                                                            (SELECT id,Contract_Start_Date__c,Contract_End_Date__c,
                                                                    Revenue_Account__c, Auto_Renew__c, Contract_Months__c,
                                                                    Invoice_Date__c,Payment_Term_After_Days__c,
                                                                    Total_Monthly_Revenue__c From 
                                                                    Revenue_Contracts__r 
                                                                    WHERE Contract_Start_Date__c != null AND
                                                                    (Contract_End_Date__c  = null OR (Contract_End_Date__c  != null AND Auto_Renew__c=true))
                                                                    ORDER BY Contract_Start_Date__c desc limit 1),
                                                             (SELECT Id, Period_Start_Date__c 
                                                                    FROM Revenue_P_L_Allocations_del__r  
                                                                    ORDER BY Period_Start_Date__c desc limit 1)
                                                             FROM Revenue_Account__c] ) {
            sobjs.add(revenueAccount);
       }
    }
       i = 0; 
   }   
   public boolean hasNext(){ 
       if(i >= sobjs.size()) 
           return false; 
       else 
           return true; 
   }    
   public SObject next(){ 
       if(i == sobjs.size()){return null;} 
       i++; 
       return sobjs[i-1];
   } 
}
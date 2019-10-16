/*
Description : Handler class to Quota trigger.
Date Created : 5th June 2019
Change 1 :  PCPM-316 | 22 JULY 19 | Namita 
*/

public with sharing class QuotaTriggerHandler implements CommonTriggerHandler{
    public static List<Quota_Schedule__c> quoataSchdule;
    public static String RA_General_RTID;
    static{
        Schema.DescribeSObjectResult raSchema = Revenue_Account__c.sObjectType.getDescribe();
        Map<String,Schema.RecordTypeInfo>  recordTypeInfoRA = raSchema.getRecordTypeInfosByDeveloperName(); 
        RA_General_RTID = recordTypeInfoRA.get(CONSTANT.REVENUE_RECORD_TYPE_GENERAL).getRecordTypeId();
        quoataSchdule = [Select id , Type__c , Range_Start__c , Range_End__c , Monthly_Amount__c from Quota_Schedule__c where Range_Start__c != null order by Name];
    }
    
    
    public void BeforeInsert(List<SObject> newItems){
        
    }
    
    public void BeforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems){
        
    }
    
    public void BeforeDelete(Map<Id, SObject> oldItems){
        deleteRevenueAccount((Map<Id, Quota__c>)oldItems);
    }
    
    public void AfterInsert(Map<Id, SObject> newItems){
        insertRevenueAccount((Map<Id, Quota__c>)newItems, null);
    }
    
    public void AfterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems){
        insertRevenueAccount((Map<Id, Quota__c>)newItems, (Map<Id, Quota__c>)oldItems);
    }
    
    public void AfterDelete(Map<Id, SObject> oldItems){
        
    }
    
    public void AfterUndelete(Map<Id, SObject> oldItems){
        
    }
    
    public Boolean IsDisabled(){
        return false;
    }
    
    /* This method will create revenue account
     * @param 
       newItems : new map of quota id to quota record
       @return null
     */
    public void insertRevenueAccount(Map<Id, Quota__c> newItems, Map<Id, Quota__c> oldItems){
        Boolean isInsert = oldItems == null;
        Revenue_Account__c revenueAccount;
        Revenue_Contract__c revenueContract;
        Map<String, Double> quotaToAmount = new Map<String, Double>();
        List<Revenue_Contract__c> revenueContractsList = new List<Revenue_Contract__c>();
        List<Revenue_Account__c> deleteRevenueAccounts = new List<Revenue_Account__c>();
        Map<Revenue_Contract__c,Revenue_Account__c> mapRContractToRAccout = new Map<Revenue_Contract__c,Revenue_Account__c>();
        Map<String, Revenue_Contract__c> mapQuotaToContract = new Map<String, Revenue_Contract__c>();
        List<Quota_Schedule__c> quoataSchdule;
        if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.QUOTA_SCHEDULE_OBJECT,'id , Type__c , Range_Start__c , Range_End__c , Monthly_Amount__c',Constant.ACTION_TYPE_ACCESS)){
        	quoataSchdule =  [Select id , Type__c , Range_Start__c , Range_End__c , Monthly_Amount__c from Quota_Schedule__c limit 1];
    	}
        Integer months = 0;
        if(quoataSchdule.size() > 0){
            months = Integer.valueOf(quoataSchdule[0].Type__c);
        }
        
        if(!isInsert) {
            if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.REVENUE_CONTRACT_OBJECT,'Id,Revenue_Account__c, Live_Renewed_Date__c,Contract_Start_Date__c',Constant.ACTION_TYPE_ACCESS) &&
               PlaceCPM_Utility.checkAccessiblityOfFields(Constant.revenueAccountObject,'Quota__c',Constant.ACTION_TYPE_ACCESS)
              ){
                for(Revenue_Contract__c ra : [Select Id,Revenue_Account__c, Live_Renewed_Date__c,
                                              Revenue_Account__r.Quota__c,Contract_Start_Date__c,
                                              (Select Id From Contract_Line_Items__r)
                                              From Revenue_Contract__c where Revenue_Account__r.Quota__c in: oldItems.keySet()]) {
                                                  mapQuotaToContract.put(ra.Revenue_Account__r.Quota__c +':'+ra.Contract_Start_Date__c, ra);
                                              }
        	} 

        }
        PlaceCPM_Utility.getAssumption();
        Boolean isContractStartDate = false, isLiveRenewDate = false, isInvoiceDate = false, isName = false;
        Boolean isRecordType = false, isGLCode = false, isAccountExecutive = false, isPaymentAccount = false;
        Boolean isQuota = false, isContractEndDate = false, isPaymentTermAfterDays = false, isRevenueAccountBillingCycle = false;
        
        if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.REVENUE_CONTRACT_OBJECT,'Contract_Start_Date__c',Constant.ACTION_TYPE_UPDATE) && PlaceCPM_Utility.checkAccessiblityOfFields(Constant.REVENUE_CONTRACT_OBJECT,'Contract_Start_Date__c',Constant.ACTION_TYPE_INSERT)){
        	isContractStartDate = true;
        }
        if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.REVENUE_CONTRACT_OBJECT,'Live_Renewed_Date__c',Constant.ACTION_TYPE_UPDATE) && PlaceCPM_Utility.checkAccessiblityOfFields(Constant.REVENUE_CONTRACT_OBJECT,'Live_Renewed_Date__c',Constant.ACTION_TYPE_INSERT)){
            isLiveRenewDate = true;
        }
        if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.REVENUE_CONTRACT_OBJECT,'Invoice_Date__c',Constant.ACTION_TYPE_UPDATE) && PlaceCPM_Utility.checkAccessiblityOfFields(Constant.REVENUE_CONTRACT_OBJECT,'Invoice_Date__c',Constant.ACTION_TYPE_INSERT)){
            isInvoiceDate = true;
        }
        //PCPM-316
        if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.revenueAccountObject,'Name',Constant.ACTION_TYPE_UPDATE) && PlaceCPM_Utility.checkAccessiblityOfFields(Constant.revenueAccountObject,'Name',Constant.ACTION_TYPE_INSERT)){
            isName = true;
        }
        if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.revenueAccountObject,'RecordTypeId',Constant.ACTION_TYPE_UPDATE) && PlaceCPM_Utility.checkAccessiblityOfFields(Constant.revenueAccountObject,'RecordTypeId',Constant.ACTION_TYPE_INSERT)){
            isRecordType = true;
        }
        if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.revenueAccountObject,'GL_Code__c',Constant.ACTION_TYPE_UPDATE) && PlaceCPM_Utility.checkAccessiblityOfFields(Constant.revenueAccountObject,'GL_Code__c',Constant.ACTION_TYPE_INSERT)){
            isGLCode = true;
        }
        if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.revenueAccountObject,'Account_Executive__c',Constant.ACTION_TYPE_UPDATE) && PlaceCPM_Utility.checkAccessiblityOfFields(Constant.revenueAccountObject,'Account_Executive__c',Constant.ACTION_TYPE_INSERT)){
            isAccountExecutive = true;
        }
        if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.revenueAccountObject,'Payment_Account__c',Constant.ACTION_TYPE_UPDATE) && PlaceCPM_Utility.checkAccessiblityOfFields(Constant.revenueAccountObject,'Payment_Account__c',Constant.ACTION_TYPE_INSERT)){
            isPaymentAccount = true;
        }
        if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.revenueAccountObject,'Quota__c',Constant.ACTION_TYPE_UPDATE) && PlaceCPM_Utility.checkAccessiblityOfFields(Constant.revenueAccountObject,'Quota__c',Constant.ACTION_TYPE_INSERT)){
            isQuota = true;
        }
        if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.REVENUE_CONTRACT_OBJECT,'Contract_End_Date__c',Constant.ACTION_TYPE_UPDATE) && PlaceCPM_Utility.checkAccessiblityOfFields(Constant.REVENUE_CONTRACT_OBJECT,'Contract_End_Date__c',Constant.ACTION_TYPE_INSERT)){
            isContractEndDate = true;
        }
        if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.REVENUE_CONTRACT_OBJECT,'Payment_Term_After_Days__c',Constant.ACTION_TYPE_UPDATE) && PlaceCPM_Utility.checkAccessiblityOfFields(Constant.REVENUE_CONTRACT_OBJECT,'Payment_Term_After_Days__c',Constant.ACTION_TYPE_INSERT)){
            isPaymentTermAfterDays = true;
        }
        
        if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.revenueAccountObject,'Billing_Cycle__c',Constant.ACTION_TYPE_UPDATE) && PlaceCPM_Utility.checkAccessiblityOfFields(Constant.revenueAccountObject,'Billing_Cycle__c',Constant.ACTION_TYPE_INSERT)){
        	isRevenueAccountBillingCycle = true;                   
		}
        for(Quota__c q : newItems.values()){
            if(q.Employee__c != null 
               && PlaceCPM_Utility.assumptionRevenueGLAccount != null
               && q.Monthly_Quota_Amount__c != null 
               && q.Quota_Start_Date__c != null 
               && q.Quota_End_Date__c != null ){
                   quotaToAmount.put(q.Id, q.Monthly_Quota_Amount__c);
                   For(Integer i=0 ; i < months ; i++){
                       revenueAccount = new Revenue_Account__c();
                       revenueContract = new Revenue_Contract__c();
                       if(isContractStartDate){
                            revenueContract.Contract_Start_Date__c = q.Quota_Start_Date__c.addMonths(i);
                       }
                       String key = q.Id +':'+revenueContract.Contract_Start_Date__c;
                       if(mapQuotaToContract.containsKey(key)) {
                           system.debug(key);
                           revenueContract = mapQuotaToContract.get(key);
                           revenueAccount.Id = revenueContract.Revenue_Account__c;
                           //revenueContract.Id = mapQuotaToContract.get(key).Id;
                       }
                       if(isLiveRenewDate){
                            revenueContract.Live_Renewed_Date__c = revenueContract.Contract_Start_Date__c;
                       }
                       if(isInvoiceDate){
                            revenueContract.Invoice_Date__c = revenueContract.Contract_Start_Date__c;
                       }
                       if(isName){
                            revenueAccount.Name = System.Label.Quota+' - '+ placeCPM_Utility.getMonthString(revenueContract.Live_Renewed_Date__c.month()) + ' ' +revenueContract.Live_Renewed_Date__c.year();
                       }
                       if(isRecordType){
                            revenueAccount.RecordTypeId = RA_General_RTID;
                       }
                       if(isGLCode){
                            revenueAccount.GL_Code__c = PlaceCPM_Utility.assumptionRevenueGLAccount;
                       }
                       if(isAccountExecutive){
                            revenueAccount.Account_Executive__c = q.Employee__c;
                       }
                       if(isPaymentAccount){
                            revenueAccount.Payment_Account__c = PlaceCPM_Utility.assumptionPaymentAccount;
                       }
                       if(isQuota){
                            revenueAccount.Quota__c = q.Id;
                       }
                       if(isContractEndDate){
                            revenueContract.Contract_End_Date__c = q.Quota_Start_Date__c.addMonths(i+PlaceCPM_Utility.contractDuration-1);
                       }
                       if(isPaymentTermAfterDays){
                            revenueContract.Payment_Term_After_Days__c = '0';
                       }
                       
                       if(PlaceCPM_Utility.empRevDetailWrapper.containsKey(q.Employee__c) && revenueContract.Contract_End_Date__c > PlaceCPM_Utility.empRevDetailWrapper.get(q.Employee__c).maxContractEndDate 
                       && revenueContract.Contract_Start_Date__c < PlaceCPM_Utility.empRevDetailWrapper.get(q.Employee__c).maxContractEndDate 
                       && isContractEndDate) {
                           revenueContract.Contract_End_Date__c = PlaceCPM_Utility.empRevDetailWrapper.get(q.Employee__c).maxContractEndDate;
                       }
                       if(isRevenueAccountBillingCycle){
                            revenueAccount.Billing_Cycle__c = PlaceCPM_Utility.billingCycle;
                       }
                       if(revenueContract.Contract_Start_Date__c >= q.Quota_End_Date__c) {
                           if(revenueAccount.Id != null) {
                               deleteRevenueAccounts.add(revenueAccount);
                           }
                       } else {
                           revenueContractsList.add(revenueContract);
                           mapRContractToRAccout.put(revenueContract,revenueAccount);
                       }
                   }
               }
        }
        PlaceCPM_Utility.deleteRecords(deleteRevenueAccounts, CONSTANT.revenueAccountObject, false); //520
        if(mapRContractToRAccout.size() > 0) {
          PlaceCPM_Utility.upsertRecords(mapRContractToRAccout.values(), CONSTANT.revenueAccountObject, false); //520
          insertRevenueContract(mapRContractToRAccout, quotaToAmount);
        }
    }
    
    /* This method will create revenue contract
     * @param 
       listOfRevenueAccounts : List of Revenue_Account__c records
       quotaToAmount : Map of Quata Id to Quota Amount
       @return null
      */
    public void insertRevenueContract(Map<Revenue_Contract__c,Revenue_Account__c> mapRContractToRAccout, Map<String, Double> quotaToAmount){
        Revenue_Account__c revenueAccount;
        List<Revenue_Contract__c> listOfRevenueContract = new List<Revenue_Contract__c>();
        Map<String,  Revenue_Contract__c> revenueAccountToRevenueContractMap = new Map<String,  Revenue_Contract__c>();
        Boolean isRevenueAccount = false, isBatchProcessExecution = false;
        if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.REVENUE_CONTRACT_OBJECT,'Revenue_Account__c',Constant.ACTION_TYPE_INSERT)){
        	isRevenueAccount = true;
        }
        if (PlaceCPM_Utility.checkAccessiblityOfFields(Constant.REVENUE_CONTRACT_OBJECT,'Batch_Process_Execution__c',Constant.ACTION_TYPE_UPDATE)){
        	isBatchProcessExecution = true;
        }
        for(Revenue_Contract__c revenueContract : mapRContractToRAccout.keySet()) {
            revenueAccount = mapRContractToRAccout.get(revenueContract);
            if(revenueContract.Revenue_Account__c == null){
                if(isRevenueAccount){
                    revenueContract.Revenue_Account__c = revenueAccount.Id;
                }
            }
            if (isBatchProcessExecution){
                revenueContract.Batch_Process_Execution__c = true;
            }
            quotaToAmount.put(revenueAccount.Id, quotaToAmount.get(revenueAccount.Quota__c));
            listOfRevenueContract.add(revenueContract);
            revenueAccountToRevenueContractMap.put(revenueAccount.Id, revenueContract);
        }

        PlaceCPM_Utility.upsertRecords(listOfRevenueContract, CONSTANT.REVENUE_CONTRACT_OBJECT, false); //520
        insertContractLineItem(listOfRevenueContract, quotaToAmount, revenueAccountToRevenueContractMap);
    }
    
    /* This method will create contract line item
     * @param 
       listOfRevenueContract : List of Revenue_Contract__c records
       quotaToAmount : Map of Quata Id to Quota Amount
       @return null
      */
    public void insertContractLineItem(List<Revenue_Contract__c> listOfRevenueContract, Map<String, Double> quotaToAmount, Map<String,  Revenue_Contract__c> revenueAccountToRevenueContractMap){
        Contract_Line_Items__c cli ;
        List<Contract_Line_Items__c> listOfContractLineItem = new List<Contract_Line_Items__c>();
        Boolean isUnitPrice = false, isRevenueContractDetails = false, isStartDate = false, isEndDate = false, isRevenueContractId = false, isQuantity = false;
        if (PlaceCPM_Utility.checkAccessiblityOfFields(Constant.CONTRACT_LINE_ITEM_OBJECT,'Unit_Price__c',Constant.ACTION_TYPE_UPDATE) && PlaceCPM_Utility.checkAccessiblityOfFields(Constant.CONTRACT_LINE_ITEM_OBJECT,'Unit_Price__c',Constant.ACTION_TYPE_INSERT)){
            isUnitPrice = true;
        }
        if (PlaceCPM_Utility.checkAccessiblityOfFields(Constant.CONTRACT_LINE_ITEM_OBJECT,'Revenue_Contract_Details__c',Constant.ACTION_TYPE_INSERT)){
            isRevenueContractDetails = true;
        }
        if (PlaceCPM_Utility.checkAccessiblityOfFields(Constant.CONTRACT_LINE_ITEM_OBJECT,'Start_Date__c',Constant.ACTION_TYPE_UPDATE) && PlaceCPM_Utility.checkAccessiblityOfFields(Constant.CONTRACT_LINE_ITEM_OBJECT,'Start_Date__c',Constant.ACTION_TYPE_INSERT)){
            isStartDate = true;
        }
        if (PlaceCPM_Utility.checkAccessiblityOfFields(Constant.CONTRACT_LINE_ITEM_OBJECT,'End_Date__c',Constant.ACTION_TYPE_UPDATE) && PlaceCPM_Utility.checkAccessiblityOfFields(Constant.CONTRACT_LINE_ITEM_OBJECT,'End_Date__c',Constant.ACTION_TYPE_INSERT)){
            isEndDate = true;
        }
        if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.CONTRACT_LINE_ITEM_OBJECT,'Id',Constant.ACTION_TYPE_INSERT)){
            isRevenueContractId = true;
        }
        if (PlaceCPM_Utility.checkAccessiblityOfFields(Constant.CONTRACT_LINE_ITEM_OBJECT,'Quantity__c',Constant.ACTION_TYPE_UPDATE) && PlaceCPM_Utility.checkAccessiblityOfFields(Constant.CONTRACT_LINE_ITEM_OBJECT,'Quantity__c',Constant.ACTION_TYPE_INSERT)){
            isQuantity = true;
        }
        
        for(Revenue_Contract__c revenueContract : listOfRevenueContract) {
            cli = new Contract_Line_Items__c ();
            if (isUnitPrice){
                cli.Unit_Price__c = PlaceCPM_Utility.assumptionAvgLicenserPrice;
            }
            if (isRevenueContractDetails){
                cli.Revenue_Contract_Details__c = revenueContract.Id;
            }
            if (isStartDate){
                cli.Start_Date__c = revenueContract.Contract_Start_Date__c;
            }
            if (isEndDate){
                cli.End_Date__c = revenueContract.Contract_End_Date__c;
            }
            if(revenueAccountToRevenueContractMap.containsKey(revenueContract.Revenue_Account__c)
              && revenueAccountToRevenueContractMap.get(revenueContract.Revenue_Account__c).Contract_Line_Items__r != null
              && revenueAccountToRevenueContractMap.get(revenueContract.Revenue_Account__c).Contract_Line_Items__r.size() > 0
              ) {
                if(isRevenueContractId){
                    cli.Id = revenueAccountToRevenueContractMap.get(revenueContract.Revenue_Account__c).Contract_Line_Items__r[0].Id;
                }
            }
            if(cli.Unit_Price__c != null && cli.Unit_Price__c != 0) {
                if (isQuantity){
                    cli.Quantity__c = (quotaToAmount.get(revenueContract.Revenue_Account__c)*(PlaceCPM_Utility.assumptionForecastQuota/100))/cli.Unit_Price__c;
                }
                listOfContractLineItem.add(cli);
            }
        }
        PlaceCPM_Utility.upsertRecords(listOfContractLineItem, CONSTANT.CONTRACT_LINE_ITEM_OBJECT, false); //520
    }
    
    public void deleteRevenueAccount(Map<Id, Quota__c> oldItems){
        PlaceCPM_Utility.deleteRecords([Select Id From Revenue_Account__c WHERE Quota__c in: oldItems.keySet()], CONSTANT.revenueAccountObject, false); //520
    }
}
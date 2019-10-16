/*
* Description  : Handler class to SOW Line Item Trigger
* Date Created : 4th July 2019
*/
public with sharing class SOWLineItemTriggerHandler implements CommonTriggerHandler{
    
     
   public void BeforeInsert(List<SObject> newItems){
       //#33
       validateLineItemInDateRange((List<SOW_Line_Item__c >)newItems);
       //#33
       validateSingleRecordPerMonth((List<SOW_Line_Item__c >)newItems);
   }
    
    public void BeforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems){
    }
    
    public void BeforeDelete(Map<Id, SObject> oldItems){
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
    //#33
    /* @param newItems is the list of SOW_Line_Item__c to be checked if they lie within SOW start and End date
       @return null
    */
    private void validateLineItemInDateRange(List<SOW_Line_Item__c > newItems){
        List<String> listSowId =new List<String>();
        Date sowliDate;
        Date endDate;
        Double amount=0;
        for(SOW_Line_Item__c sowli:newItems){
            listSowId.add(sowli.Revenue_Contract_Statement_of_Work__c);
        }
        
        Map<String,Revenue_Contract__c> mapRevenueContract;
        if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.REVENUE_CONTRACT_OBJECT,'ID, Live_Renewed_Date__c , Contract_End_Date__c, Auto_Renew__c,Contract_Months__c',Constant.ACTION_TYPE_ACCESS)){
        	mapRevenueContract = new Map<String,Revenue_Contract__c>([SELECT ID, Live_Renewed_Date__c , Contract_End_Date__c, Auto_Renew__c,
                                                                                          Contract_Months__c FROM Revenue_Contract__c WHERE ID IN :listSowId]);
        }    
        for(SOW_Line_Item__c sowli:newItems){
            if(sowli.Year__c != null 
            && mapRevenueContract.containsKey(sowli.Revenue_Contract_Statement_of_Work__c) 
            && mapRevenueContract.get(sowli.Revenue_Contract_Statement_of_Work__c).Live_Renewed_Date__c !=null){

            }
            sowliDate= Date.newInstance(Integer.valueOf(sowli.Year__c),PlaceCPM_Utility.getMonthInNumber(sowli.Month__c) , 1);
            endDate = mapRevenueContract.get(sowli.Revenue_Contract_Statement_of_Work__c).Live_Renewed_Date__c.addMonths(PlaceCPM_Utility.getRevenueMonths(mapRevenueContract.get(sowli.Revenue_Contract_Statement_of_Work__c)));
            if((sowliDate < mapRevenueContract.get(sowli.Revenue_Contract_Statement_of_Work__c).Live_Renewed_Date__c) 
                  ||(mapRevenueContract.get(sowli.Revenue_Contract_Statement_of_Work__c).Contract_End_Date__c != null && sowliDate >  mapRevenueContract.get(sowli.Revenue_Contract_Statement_of_Work__c).Contract_End_Date__c)
                  ||(endDate != null && sowliDate > endDate )){
                    sowli.addError(System.label.Error_SOW_Date_range);
                }
            
        }
     }
    //#33
    /* @param newItems is the list of SOW_Line_Item__c to ensure only one Line item is created for each month
       @return null
    */
    private void validateSingleRecordPerMonth(List<SOW_Line_Item__c > newItems){
    	List<String> listSowId =new List<String>();
        Map<String,List<String>> mapSOWToMonthToSOWLI = new Map<String,List<String>>();
        for(SOW_Line_Item__c sowli:newItems){
            listSowId.add(sowli.Revenue_Contract_Statement_of_Work__c);
        } 
        Map<String,SOW_Line_Item__c> mapSOWLI;
        if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.SOW_LINE_ITEM_OBJECT,'ID, Month__c, Year__c, Revenue_Contract_Statement_of_Work__c',Constant.ACTION_TYPE_ACCESS)){
            mapSOWLI = new Map<String,SOW_Line_Item__c>([SELECT ID, Month__c, Year__c, Revenue_Contract_Statement_of_Work__c FROM SOW_Line_Item__c WHERE 
                                                                                        Revenue_Contract_Statement_of_Work__c IN :listSowId]);
        }    
        for(SOW_Line_Item__c sowli:mapSOWLI.values()){
            if(!mapSOWToMonthToSOWLI.containsKey(sowli.Revenue_Contract_Statement_of_Work__c)){
                mapSOWToMonthToSOWLI.put(sowli.Revenue_Contract_Statement_of_Work__c, new List<String>());
            }
            if(sowli.Month__c != null && sowli.Year__c != null){
                mapSOWToMonthToSOWLI.get(sowli.Revenue_Contract_Statement_of_Work__c).add(sowli.Month__c+' '+sowli.Year__c);
            }
        }
        for(SOW_Line_Item__c sowli:newItems){
            if(sowli.Month__c != null && sowli.Year__c != null){
                if(mapSOWToMonthToSOWLI.containsKey(sowli.Revenue_Contract_Statement_of_Work__c) && 
                mapSOWToMonthToSOWLI.get(sowli.Revenue_Contract_Statement_of_Work__c).contains(sowli.Month__c+' '+sowli.Year__c)){
                    sowli.addError(System.label.Error_SOW_Line_Item_Month_Exists);
                }
            }
        }
    }
    
}
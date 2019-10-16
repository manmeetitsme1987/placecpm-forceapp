/*
* Description  : Handler class to Product Trigger
* Date Created : 4th July 2019
*/
public with sharing class ProductTriggerHandler implements CommonTriggerHandler{
    
    public void BeforeInsert(List<SObject> newItems){
    }
    
    public void BeforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems){
        
    }
    
    public void BeforeDelete(Map<Id, SObject> oldItems){
        //#199
        checkIfProductIsBeingUsed((Map<Id, Product__c>) oldItems);
    }
    
    public void AfterInsert(Map<Id, SObject> newItems){
    }

    public void afterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems){
    }
        
    public void AfterDelete(Map<Id, SObject> oldItems){
        
    }
    
    public void AfterUndelete(Map<Id, SObject> oldItems){
        
    }
    
    public Boolean IsDisabled(){
        return false;
    }

    //#33
    /* @param 
       oldItems : Old Product__c records whose deletion needs to be prevented if they are used by any Contract Line Item
       @return null
      */
    private void checkIfProductIsBeingUsed(Map<Id, Product__c> oldItems){
        List<String> listProductId = new List<String>();
        Map<String,List<Contract_Line_Items__c>> mapProductToContractLineItems = new Map<String,List<Contract_Line_Items__c>>();
        for(Product__c product:oldItems.values()){
            listProductId.add(product.Id);
        }
        
        if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.CONTRACT_LINE_ITEM_OBJECT,'ID,Product__c',Constant.ACTION_TYPE_ACCESS)){
            for(Contract_Line_Items__c cli: [SELECT ID,Product__c FROM Contract_Line_Items__c WHERE Product__c IN :listProductId]){
                if(!mapProductToContractLineItems.containsKey(cli.Product__c)){
                    mapProductToContractLineItems.put(cli.Product__c, new List<Contract_Line_Items__c>());
                }
                mapProductToContractLineItems.get(cli.Product__c).add(cli);
            }
    	}
        // Checking if Product to be deleted are being used by Contract Line Item
        for(Product__c prod:oldItems.values()){
            if(mapProductToContractLineItems.containsKey(prod.Id) && !(mapProductToContractLineItems.get(prod.Id).isEmpty())){
                prod.addError(System.label.Error_Product_in_Use);
            }

        }
    }
  

}
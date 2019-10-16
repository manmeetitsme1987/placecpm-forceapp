/*
Description : This class is controller to Add Quota Schedule component
Date Created : 11 July 2019
*/
public with sharing class QuotaScheduleController {
    private static List<Revenue_Contract__c> insertedRevenueContacts;  
    public static Map<Id , Quota_Schedule__c> quotaMap;
    public static List<String> typePickListValue = new List<String>();
    public static Map<String , String> typePickListMap = new Map<String , String>();

    static{
        Schema.DescribeFieldResult fieldResult = Quota_Schedule__c.Type__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        for( Schema.PicklistEntry f : ple){
            typePickListMap.put(f.getLabel() , f.getValue());
            typePickListValue.add(f.getLabel());
        }
        
        if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.QUOTA_SCHEDULE_OBJECT,'id , Range_Start__c , Range_End__c , Quota_Amount__c , type__c , Monthly_Amount__c',Constant.ACTION_TYPE_ACCESS)){ 
        	quotaMap = new Map<Id , Quota_Schedule__c>([Select id , Range_Start__c , Range_End__c , Quota_Amount__c , type__c , Monthly_Amount__c  From Quota_Schedule__c where Range_Start__c != null order by Range_Start__c]);
    	}
    }
    
    

    @AuraEnabled
    public static wrapper fetchAllData(){
        return new wrapper();
    }
    
    @AuraEnabled
    public static Quota_Schedule__c addQuotaSchedule(List<Quota_Schedule__c> quotaList) {
        return new Quota_Schedule__c();
    } 

    @AuraEnabled
    public static String createQuotaSchedule(List<Quota_Schedule__c> quotaList  , String typeValue){
        if(typeValue == Null){
            typeValue = typePickListMap.get(typePickListValue[0]);
        }
        For(Quota_Schedule__c qs : quotaList){
            qs.type__c = typeValue;
            if(quotaMap.containsKey(qs.id)){
                quotaMap.remove(qs.id);
            }
        }
        try{
            PlaceCPM_Utility.upsertRecords(quotaList, CONSTANT.QUOTA_SCHEDULE_OBJECT, false); //520
        }
        catch(Exception ex){
            return 'Error : ' + ex.getMessage();
        }
        
        try{
            PlaceCPM_Utility.deleteRecords(quotaMap.values(), CONSTANT.QUOTA_SCHEDULE_OBJECT, false); //520
        }
        catch(Exception ex){
            return 'Error : ' + ex.getMessage();
        }
        
        return 'Success';
    }
    
  //wrapper class to hold the values
    public class wrapper{
        @AuraEnabled public List<Quota_Schedule__c> quotaList;
        @AuraEnabled public Map<String , String> mapOfTypePicklist;
        @AuraEnabled public Integer forecastDuration;
        wrapper(){
            quotaList = quotaMap.values();
            mapOfTypePicklist = typePickListMap;
            forecastDuration = PlaceCPM_Utility.assumptionForecastDuration;
        }
    }
}
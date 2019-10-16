public with sharing class SingleRelatedListController {
    public static final String FIELDS_PARAM = 'fields';
    public static final String NUMBER_OF_RECORDS_PARAM = 'numberOfRecords';
    public static final String RECORD_ID_PARAM = 'recordId';
    public static final String SOBJECT_API_NAME_PARAM = 'sobjectApiName';
    public static final String SOBJECT_LABEL_PARAM = 'sobjectLabel';
    public static final String SOBJECT_LABEL_PLURAL_PARAM = 'sobjectLabelPlural';
    public static final String PARENT_RELATIONSHIP_API_NAME_PARAM = 'parentRelationshipApiName';
    public static final String RELATED_FIELD_API_NAME_PARAM = 'relatedFieldApiName';
    public static final String SORTED_DIRECTION_PARAM = 'sortedDirection';
    public static final String SORTED_BY_PARAM = 'sortedBy';
    public static final String RECORDS_PARAM = 'records';
    public static final String ICON_NAME_PARAM = 'iconName';
    public static final String sessionId = placeCPM_Utility.fetchUserSessionId(); //492
    
    public static final String IS_NEW_NEEDED = 'isNew';
    @AuraEnabled
    public static String initData(String jsonData){
        Map<String, Object> requestMap = (Map<String, Object>)JSON.deserializeUntyped(jsonData);  
        Map<String, Object> responseMap = new Map<String, Object>();
        responseMap.put(RECORDS_PARAM, getRecords(jsonData));
        
        String sobjectApiName = (String)requestMap.get(SOBJECT_API_NAME_PARAM);
        responseMap.put(ICON_NAME_PARAM, getIconName(sobjectApiName));
        String recordId = (String)requestMap.get(RECORD_ID_PARAM);
        responseMap.put(PARENT_RELATIONSHIP_API_NAME_PARAM, getParentRelationshipName(recordId, sobjectApiName));
        
        Schema.SObjectType sobjectType = Schema.getGlobalDescribe().get(sobjectApiName);
        Schema.DescribeSObjectResult sobjectDescribe = sobjectType.getDescribe();
        responseMap.put(SOBJECT_LABEL_PARAM, sobjectDescribe.getLabel());
        responseMap.put(SOBJECT_LABEL_PLURAL_PARAM, sobjectDescribe.getLabelPlural());
        List<String> rtNamesToDisplay = new List<String>();
        for(SplitScreenParenChildSetting__mdt rtInfoSetting: [SELECT Child_Record_Types__c FROM SplitScreenParenChildSetting__mdt WHERE Type__c = 'NewButton' LIMIT 1]){
            for(String sobjName : rtInfoSetting.Child_Record_Types__c.split(',')){
                rtNamesToDisplay.add(PlaceCPM_Utility.getCustomObjOrFieldName(sobjName));
            }    
        }
        system.debug('sobjectApiName'+sobjectApiName);
        system.debug('rtNamesToDisplay'+rtNamesToDisplay);
        if(rtNamesToDisplay.contains(sobjectApiName)){
            responseMap.put(IS_NEW_NEEDED, false);
        }
        else{
            responseMap.put(IS_NEW_NEEDED, true);
        }
        system.debug(''+responseMap.get(IS_NEW_NEEDED));
        return JSON.serialize(responseMap);
    }
    
	@AuraEnabled
    public static List<Sobject> getRecords(String jsonData){
		Map<String, Object> root = (Map<String, Object>)JSON.deserializeUntyped(jsonData);  
        String fields = (String)root.get(FIELDS_PARAM);
		//Integer numberOfRecords = (Integer)root.get(NUMBER_OF_RECORDS_PARAM);
        String recordId = (String)root.get(RECORD_ID_PARAM);
		String relatedFieldApiName = (String)root.get(RELATED_FIELD_API_NAME_PARAM);
		String sobjectApiName = (String)root.get(SOBJECT_API_NAME_PARAM);        
		String orderBy = (String)root.get(SORTED_BY_PARAM) + ' ' + (String)root.get(SORTED_DIRECTION_PARAM);    
        String query;
        if(PlaceCPM_Utility.checkAccessiblityOfFields(sobjectApiName,fields,Constant.ACTION_TYPE_ACCESS)){
        	query = 'Select '+fields+' From '+sobjectApiName+' WHERE ' +relatedFieldApiName+ '= :recordId ORDER BY ' +orderBy;
        }    
        return Database.query(String.escapeSingleQuotes(query));
	}
        
    private static String getParentRelationshipName(Id recordId, String parentSobjectName){
        Schema.DescribeSObjectResult descrRes = recordId.getSObjectType().getDescribe();
        String name;
        for (Schema.ChildRelationship cr: descrRes.getChildRelationships()){ 
            if(cr.getChildSObject().getDescribe().getName() == parentSobjectName){
          	 	name = cr.getRelationshipName();
                break;
            }
        }
        return name;
    }

	@AuraEnabled
    public static String deleteRecord(Id recordId){
        Sobject sobj = recordId.getSObjectType().newSObject(recordId);
        Database.DeleteResult result;
        if(Schema.getGlobalDescribe().get(recordId.getSObjectType().getDescribe().getName()).getDescribe().isDeletable()){
            result = Database.delete(sobj, false);
        }
        String message ='';
        if(!result.isSuccess()){
            for(Database.Error err : result.getErrors()) {

            message = err.getMessage();
                }
        }
        return message;
	}       
    
    @AuraEnabled
    public static String getIconName(String sobjectApiName){
        String iconName;
        List<Schema.DescribeTabSetResult> tabSetDesc = Schema.DescribeTabs();
        List<Schema.DescribeTabResult> tabDesc = new List<Schema.DescribeTabResult>();
        List<Schema.DescribeIconResult> iconDesc = new List<Schema.DescribeIconResult>();

        for(Schema.DescribeTabSetResult tsr : tabSetDesc) { 
            tabDesc.addAll(tsr.getTabs()); 
        }

        for(Schema.DescribeTabResult tr : tabDesc) {
            if( sobjectApiName == tr.getSobjectName() ) {
                if( tr.isCustom() ) {
                    iconDesc.addAll(tr.getIcons());
                } else {
                    iconName = 'standard:' + sobjectApiName.toLowerCase();
                }
            }
        }
        for (Schema.DescribeIconResult ir : iconDesc) {
            if (ir.getContentType() == 'image/svg+xml'){
                iconName = 'custom:' + ir.getUrl().substringBetween('custom/','.svg').substringBefore('_');
                break;
            }
        }
         //492
        if(iconName == null){
            iconName = getIconURL(sobjectApiName);
            if(iconName == null){
                iconName = 'standard:custom';
            }
        }
        return iconName;
    }    
    
    //492
    // Call the ui-api and get the icons of the objects,
    // @param objectName : api name of the object. 
    // @return String
    private static String getIconURL(String objectName){
        HttpRequest req = new HttpRequest();
        req.setEndpoint(System.URL.getSalesforceBaseURL().toExternalForm() +'/services/data/v43.0/ui-api/object-info/'+objectName);
        req.setHeader('Content-type','application/json; charset=UTF-8');
        req.setHeader('Accept','application/json');
        req.setMethod('GET');
        req.setHeader('Authorization', 'OAuth ' + sessionId);        
        Http http = new Http();
        try{
            HTTPResponse res = http.send(req);
            if(res.getStatusCode() == 200){
                String response = res.getBody();
                Map<String,object> apiResponse =(Map<String,Object>)JSON.deserializeUntyped(response);
                Map<String,object> themeInfo = (Map<String,object>)apiResponse.get('themeInfo');
                String objectIcon;
                if(themeInfo != null){
                    String iconUrl = (String)themeInfo.get('iconUrl');
                    if(String.isNotBlank(iconUrl)){
                        List<String> urlList = iconUrl.split('/');
                        if(urlList.size() > 2){
                            String iconSvg = urlList[urlList.size() - 1];
                            String iconName = iconSvg.substringBeforeLast('_');
                            objectIcon = urlList[urlList.size() - 2]+ ':' + iconName;
                        }
                    }
                    return objectIcon;
                }
            }
        }catch(Exception ex){
            PlaceCPM_Utility.debugLog(ex.getMessage() + ' at line number ' + ex.getLineNumber());
        }
        return null;
    }

    @AuraEnabled
    public static List<RecordTypeInfo> fetchRecordTypeValues(String sobjectApiName, String parentSobjectName, String parentRecordId){
        Map<Id,String> rtList = new Map<Id,String>();
        List<RecordTypeInfo> rtInfoList = new List<RecordTypeInfo>();
        if(sobjectApiName != null && parentSobjectName !=null && parentRecordId != null){
            String query = 'SELECT recordType.DeveloperName FROM '+parentSobjectName+' WHERE Id=:'+'parentRecordId';
            List<sObject> sobjectGet = Database.query(query);
            system.debug('sobjectGet'+sobjectGet);
            RecordType rt  = (RecordType)sobjectGet[0].getSObject('RecordType');
            String rtName = rt.DeveloperName;
            List<String> rtNamesToDisplay = new List<String>();
            for(SplitScreenParenChildSetting__mdt rtInfoSetting: [SELECT Child_Record_Types__c FROM SplitScreenParenChildSetting__mdt WHERE Parent_sObject_Api_Name__c = :PlaceCPM_Utility.removeNameSpacePrefix(parentSobjectName) AND Child_sObject_Api_Name__c = :PlaceCPM_Utility.removeNameSpacePrefix(sobjectApiName) AND Parent_Record_Type__c = :PlaceCPM_Utility.removeNameSpacePrefix(rtName) AND Type__c = 'RecordType' LIMIT 1]){
                for(String rtDevName : rtInfoSetting.Child_Record_Types__c.split(',')){
                    rtNamesToDisplay.add(rtDevName);
                }
            }
            rtList = PlaceCPM_Utility.fetchRecordTypeValues(sobjectApiName);
            for(String rtid : rtList.keySet()){
                if(rtNamesToDisplay.contains(rtList.get(rtid).split(':')[1])){
                    RecordTypeInfo rtinfo = new RecordTypeInfo();
                	rtinfo.rtId = rtid;
                	rtInfo.rtName = rtList.get(rtid).split(':')[0];
                	rtInfoList.add(rtInfo);
                }
                
            }
        }
        return rtInfoList;
    }
    
    public class RecordTypeInfo{
        @AuraEnabled
        public String rtId;
        @AuraEnabled
        public String rtName;
        
    }
    
    // Call the describe layout API and get edit page layout details,
    // @param sObjectName is the give object api name. 
    // @return list of LayoutSection wrapper
    @AuraEnabled 
    public static List<LayoutSection> getEditPageLayoutSections(String sObjectName,String recordTypeId) {
        List<LayoutSection> lstSections = new List<LayoutSection>();
        Map<String, Object> deseralizedJsonResult = new Map<String, Object>();
        List<Object> editLayoutSections = new List<Object>();
        try {
            String sessionId = fetchUserSessionId();
            Http http = new Http();
            HttpRequest httpReq = new HttpRequest();
            HttpResponse httpRes = new HttpResponse();
            httpReq.setMethod('GET');
            httpReq.setHeader('Authorization', 'Bearer ' + sessionId);
            if(recordTypeId !=null){
                httpReq.setEndpoint(System.URL.getSalesforceBaseURL().toExternalForm() + '/services/data/v44.0/sobjects/'+sObjectName+'/describe/layouts/'+recordTypeId);
            }
            else{
                httpReq.setEndpoint(System.URL.getSalesforceBaseURL().toExternalForm() + '/services/data/v44.0/sobjects/'+sObjectName+'/describe/layouts/');
            }
            
            httpRes = http.send(httpReq);
            deseralizedJsonResult = (Map<String,Object>)JSON.deserializeUntyped(httpRes.getBody());
            if(recordTypeId !=null){
                editLayoutSections = (List<Object>)deseralizedJsonResult.get('editLayoutSections');
            }
            else{
                List<Object> layouts = (List<Object> )deseralizedJsonResult.get('layouts');
                Map<String, Object> detailLayout = (Map<String, Object>) layouts[0];
                editLayoutSections = (List<Object>)detailLayout.get('editLayoutSections');
            }
            
            for (Object allSections: editLayoutSections) {
                Map<String, Object> j = (Map<String, Object> ) allSections;
                List<Object> layoutRows = (List<Object>)j.get('layoutRows');
                String heading = ((String) j.get('heading'));
                Integer columns = ((Integer)j.get('columns'));
                LayoutSection ls = new LayoutSection(heading, columns);
                for(Object allLayoutRows: layoutRows) {
                    Map<String,Object > k = (Map <String,Object> ) allLayoutRows;
                    List<Object> layoutItems = (List<Object> ) k.get('layoutItems');
                    for (Object allLayoutItems: layoutItems) {
                        Map<String, Object> l = (Map<String, Object> ) allLayoutItems;
                        LayoutField field = new LayoutField();
                        field.isRequired = (Boolean) l.get('required');
                        List<Object > layoutComponents = (List<Object> ) l.get('layoutComponents');
                        for (Object allLayoutComponents: layoutComponents) {
                            Map<String, Object> m = (Map <String, Object> ) allLayoutComponents;
                            if (((String) m.get('type')) == 'Field') {
                                if (m.containsKey('components')) {
                                    List<Object> componenets = (List<Object> ) m.get('components');
                                    for (Object allComponents: componenets) {
                                        Map<String, Object> n = (Map<String, Object> ) allComponents;
                                        field.fieldName = (String) n.get('value');
                                    }
                                } else {
                                    field.fieldName  = (String) m.get('value');
                                }
                            }  
                        }
                        ls.lstFields.add(field);
                    }
                }
                lstSections.add(ls);
            }
        }
        catch( Exception e ){
            System.debug('Exception==='+e.getLineNumber() + ' : ' + e.getMessage());
            // System.assert(false, e.getLineNumber() + ' : ' + e.getMessage() );
        }
        //System.debug('lstSections==='+lstSections);
        return lstSections;
    }
    
    // Call the VF page and get the Log In Use Session Id,
    // @param none. 
    // @return String
    public static String fetchUserSessionId(){
        String sessionId = '';
        PageReference reportPage = Page.placeCPM_GetSessionId;
        String vfContent = '';
        if(Test.isRunningTest()) { 
            vfContent = CONSTANT.START_OF_SESSIONID+' xyz '+CONSTANT.END_OF_SESSIONID;
        } else {
            vfContent = reportPage.getContent().toString();
        } 
        String sos = CONSTANT.START_OF_SESSIONID;
        Integer startP = vfContent.indexOf(CONSTANT.START_OF_SESSIONID) + sos.length(),
        endP = vfContent.indexOf(CONSTANT.END_OF_SESSIONID);
        sessionId = vfContent.substring(startP, endP);
        return sessionId;
    }
    
    // Wrapper class to store the layout section details
    public class LayoutSection {   
        @AuraEnabled public String label;
        @AuraEnabled public List<LayoutField> lstFields;
        @AuraEnabled public Integer totalColumns;
        public LayoutSection( String label, Integer totalColumns ) {
            this.label = label;
            this.totalColumns = totalColumns;
            this.lstFields = new List<LayoutField>();
        }
    }
    
    // Wrapper class to store the field details
    public class LayoutField {
        @AuraEnabled public String fieldName;
        @AuraEnabled public Boolean isRequired;
        @AuraEnabled public Boolean isReadOnly;
        
    }
}
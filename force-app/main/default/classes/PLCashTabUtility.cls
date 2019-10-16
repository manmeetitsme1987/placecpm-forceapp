public class PLCashTabUtility {
    
	// Call the describe layout API and get detail page layout details,
    // @param sObjectName is the give object api name. 
    // @return list of LayoutSection wrapper
    public static List<relatedListWrapper> getDetailPageLayout(String sObjectName,String recordTypeId) { //563
        List<String> lstSections = new List<String>();
        Map<String, Object> deseralizedJsonResult = new Map<String, Object>();
        List<Object> detailLayoutSections = new List<Object>();
        //563
        List<relatedListWrapper> rlwList = new List<relatedListWrapper>();
        Map<String, Schema.SObjectField> fieldMap  = Schema.getGlobalDescribe().get(sObjectName).getDescribe().fields.getMap();
        try {
            String sessionId = placeCPM_Utility.fetchUserSessionId(); //563
            Http http = new Http();
            HttpRequest httpReq = new HttpRequest();
            HttpResponse httpRes = new HttpResponse();
            httpReq.setMethod('GET');
            httpReq.setHeader('Authorization', 'Bearer ' + sessionId);
            if(recordTypeId != null){
                httpReq.setEndpoint(System.URL.getSalesforceBaseURL().toExternalForm() + '/services/data/v44.0/sobjects/'+sObjectName+'/describe/layouts/'+recordTypeId);
            }
            else{
                httpReq.setEndpoint(System.URL.getSalesforceBaseURL().toExternalForm() + '/services/data/v44.0/sobjects/'+sObjectName+'/describe/layouts/');
            }
            httpRes = http.send(httpReq);
            deseralizedJsonResult = (Map<String,Object>)JSON.deserializeUntyped(httpRes.getBody());
            if(recordTypeId != null){
                detailLayoutSections = (List<Object> )deseralizedJsonResult.get('relatedLists');
            }
            else{
                List<Object> layouts = (List<Object> )deseralizedJsonResult.get('layouts');
                Map<String, Object> detailLayout = (Map<String, Object>) layouts[0];
                detailLayoutSections = (List<Object>)detailLayout.get('relatedLists');
            }
            for (Object allSections: detailLayoutSections) {
                Map<String, Object> j = (Map<String, Object> ) allSections;
                //563
                if(j.get('columns') != null && String.valueOf(j.get('sobject')).endsWith('__c')){
                    List<Object> relObj = (List<Object>)j.get('columns');
                    relatedListWrapper relatedWrap = new relatedListWrapper();
                    for(Schema.ChildRelationship child  :Schema.getGlobalDescribe().get(sobjectName).getDescribe().getChildRelationships()){
                        if(String.valueOf(child.getChildSObject()) == (String)j.get('sobject')){
                            relatedWrap.relationshipField = String.valueOf(child.getField());
                        }
                    }
                    relatedWrap.childObjectName = (String)j.get('sobject');
                    List<childFieldAttributes> cfaList = new List<childFieldAttributes>();
                    for(Object rel : relObj){
                        if(cfaList.size()<3){
                            Map<String, Object> relval = (Map<String, Object> ) rel;
                            childFieldAttributes cfa = new childFieldAttributes();
                            cfa.label = String.valueOf(relval.get('label'));
                            cfa.apiName = String.valueOf(relval.get('fieldApiName'));
                            if(relval.get('format') != null){
                                cfa.fieldType = String.valueOf(relval.get('format'));
                            }
                            else if(fieldMap.containsKey(String.valueOf(relval.get('fieldApiName')))){
                                Schema.DescribeFieldResult f = fieldMap.get(String.valueOf(relval.get('fieldApiName'))).getDescribe();
                                cfa.fieldType = String.valueOf(f.getType());
                            }
                            cfaList.add(cfa);
                        }
                    }
                    relatedWrap.fieldAPINames = cfaList;
            		rlwList.add(relatedWrap);
                }
            }
        }
        catch( Exception ex ){
            PlaceCPM_Utility.debugLog(ex.getMessage() + ' at line number ' + ex.getLineNumber());
        }
        return rlwList;
    }
    //563
    public class relatedListWrapper{
        @AuraEnabled
        public String childObjectName;
        @AuraEnabled
        public String relationshipField;
        @AuraEnabled
        public List<childFieldAttributes> fieldAPINames;
    }
    
    public class childFieldAttributes{
        @AuraEnabled
        public String label;
        @AuraEnabled
        public String apiName;
        @AuraEnabled
        public String fieldType;
    } 
    
}
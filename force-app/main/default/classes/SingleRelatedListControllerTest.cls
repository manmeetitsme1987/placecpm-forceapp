@isTest
public class SingleRelatedListControllerTest {
    
    @isTest public static void testInit(){
        //492
        Assumption__c aa1 = TestUtility.createAssumption(24,True);
        Account testAccount = TestUtility.createAccount('Test vendor1', true);
        P_L_Category__c plCat1=  TestUtility.createPlCategory('COGS','Expense',True);
        GL_Code__c glCode1 = TestUtility.createGLCode('Advertising', 200, plCat1.Id ,True);
        
        Organisation__c organisation = TestUtility.createOrganisation('Place Technology', true); 
        Department__c department = TestUtility.createDepartment('SFDC', organisation.Id, glCode1.Id, true);  
        Role__c role = TestUtility.createRole('Tester', department.Id ,true);
        
        Expense_Account__c expAccount = TestUtility.createExpenseAccount(testAccount.Id, glCode1.Id, '3', true);
        
        Expense_Allocation__c expenseAlloc = TestUtility.createExpenseAllocation(expAccount.Id, false);
        expenseAlloc.Role__c = role.Id;
        insert expenseAlloc;
        
        Map<String, Object> requestMap = new Map<String, Object>(); 
        requestMap.put(SingleRelatedListController.FIELDS_PARAM, 'Name');
        requestMap.put(SingleRelatedListController.RELATED_FIELD_API_NAME_PARAM, PlaceCPM_Utility.getCustomObjOrFieldName('Expense_Account__c'));
        requestMap.put(SingleRelatedListController.RECORD_ID_PARAM, expAccount.Id);
        requestMap.put(SingleRelatedListController.NUMBER_OF_RECORDS_PARAM, 1);
        requestMap.put(SingleRelatedListController.SOBJECT_API_NAME_PARAM, PlaceCPM_Utility.getCustomObjOrFieldName('Expense_Allocation__c'));
        requestMap.put(SingleRelatedListController.SORTED_BY_PARAM, 'Name');
        requestMap.put(SingleRelatedListController.SORTED_DIRECTION_PARAM, 'ASC');
      
        Test.startTest();
        
        Test.setMock(HttpCalloutMock.class, new SingleRelatedListMock());
        
        String jsonData = SingleRelatedListController.initData(JSON.serialize(requestMap));
        Map<String, Object> responseMap = (Map<String, Object>)JSON.deserializeUntyped(jsonData);
        List<Object> records = (List<Object>)responseMap.get(SingleRelatedListController.RECORDS_PARAM);
        System.assert(!records.isEmpty());
        String iconName = (String)responseMap.get(SingleRelatedListController.ICON_NAME_PARAM);
        System.assert(String.isNotBlank(iconName));
        
        Test.stopTest();
            
        Profit_Loss__c pl = TestUtility.createPL('Test', Date.today(), date.today(), true);
        SingleRelatedListController.deleteRecord(pl.id);
       
        SingleRelatedListController.fetchRecordTypeValues(PlaceCPM_Utility.getCustomObjOrFieldName('Expense_Detail__c'), PlaceCPM_Utility.getCustomObjOrFieldName('Expense_Account__c'), expAccount.Id);
        SingleRelatedListController.fetchUserSessionId();
        Id expRtId = Schema.SObjectType.Expense_Account__c.getRecordTypeInfosByName().get('General').getRecordTypeId();
        SingleRelatedListController.getEditPageLayoutSections(PlaceCPM_Utility.getCustomObjOrFieldName('Expense_Account__c'), expRtId);
    }
}
/*
Description : This class is test class for GLAccountTriggerHandler.
Date Created : 21th June 2019
*/
@isTest
Private class GLAccountTriggerHandlerTest {
    static GL_Code__c glaccount;
    //  Method to create test data.
    //  @param 
    //  @return void
    static void createTestData(){
        TestUtility.createAssumption(24 , true);
        P_L_Category__c plCategory = TestUtility.createPlCategory('General and Admin','Revenue',True);
        glaccount = TestUtility.createGLCode('Advertising',600,plCategory.id,True);
    }

    //  Method to test insert cases
    //  @param year is the selected year on PAndL component
    //  @return MainWrapper
    static testMethod void testInsert(){
        createTestData();
        // When gl account is inserted its corresponding pl statement should also get inserted with 0 values.
        System.assert([Select id FROM P_L_Statement__c].size() > 0);
    }

    //  Method to test update scenerio
    //  @param 
    //  @return void
    static testMethod void testUpdate(){
        createTestData();
        For(GL_Code__c glc : [Select id , sequence__c from GL_Code__c limit 1]){
            glc.sequence__c = 2;
            glaccount = glc;
        }
        update glaccount;
        System.assert([Select id, sequence__c FROM P_L_Statement__c][0].sequence__c == 1.02);
    }

    //  Method to test delete scenerio
    //  @param 
    //  @return void
    static testMethod void testDelete(){
        createTestData();
        delete glaccount;
        System.assert([Select id FROM P_L_Statement__c where GL_Code__c != Null ].size() == 0);
    }
}
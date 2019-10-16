    /*
    Description : This class will be as Test for PLCategoryTriggerHandler.
    Date Created : 21th June 2019
    */
    @isTest
    private class PLCategoryTriggerHandlerTest {
        static P_L_Category__c plcat;
        //  Method to crate Data
        //  @param Null
        //  @return void
        static void createTestData(){
            TestUtility.createAssumption(24 , true);
            plcat = TestUtility.createPlCategory('General and Admin','Revenue',True);
            GL_Code__c glaccount = TestUtility.createGLCode('Advertising',600,plcat.id,True);
        }

        //  Method to test update scenerio
        //  @param Null
        //  @return void
        static testMethod void testUpdate(){
            createTestData();
            For(P_L_Category__c plc : [Select id , sequence__c from P_L_Category__c limit 1]){
                plc.sequence__c = 2;
                plcat = plc;
            }
            update plcat;
            //If pl category sequence udpated then its pl statement sequence should also get update.
            System.assert([Select id, sequence__c FROM P_L_Statement__c][0].sequence__c == 2.01);
        }

        //  Method to test delete scenerio
        //  @param Null
        //  @return MainWrapper
        static testMethod void testDelete(){
            createTestData();
            delete plcat;
            System.assert([Select id FROM P_L_Statement__c where P_L_Category__c != Null ].size() == 0);
        }
    }
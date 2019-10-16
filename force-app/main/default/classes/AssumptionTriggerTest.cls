@isTest
public class AssumptionTriggerTest {
    static testMethod void checkRecordForAssumption(){ 
        Test.StartTest();
        List<Assumption__c> assumptionRec = TestUtility.createAssumptions(20, 1, true);
        AssumptionTriggerHandler assumptionHandler = new AssumptionTriggerHandler();
        assumptionHandler.checkDuplicateRecordForAssumption(assumptionRec);
        assumptionHandler.checkAtleastOneRecordForAssumption(assumptionRec);
        List<Assumption__c> assumpList = [Select Id From  Assumption__c];
        system.assertEquals(assumpList.size(), 1);
        update assumpList;
        delete assumpList;
        Test.stopTest();
    }
}
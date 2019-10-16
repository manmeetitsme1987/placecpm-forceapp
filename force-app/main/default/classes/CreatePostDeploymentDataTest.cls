@isTest
public class CreatePostDeploymentDataTest {
       /* static testMethod void testCreateData(){
            CreatePostDeploymentData.createData();
            System.assert([Select id , Forecast_Duration__c from Assumption__c].size() > 0);
        } */

    @isTest
    static void testInstallScript() {
    CreatePostDeploymentData postinstall = new CreatePostDeploymentData();
        Test.testInstall(postinstall, null);
        Test.testInstall(postinstall, new Version(1,0), true);

        List<P_L_Category__c> a = [Select id, name from P_L_Category__c where name ='REVENUE'];
        System.assertEquals(a.size(), 1, 'P&L Category not found');
    }
    
}
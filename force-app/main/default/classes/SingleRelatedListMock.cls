/* Name : SingleRelatedListMock
 * Description : PCPM-492 | Mock Class for callout in SingleRelatedList class 
 * Date : 6 Sept 2019
 * Change 1 : 
 */
public class SingleRelatedListMock implements HttpCalloutMock {
    
    public HttpResponse respond(HttpRequest req){
        String body = '{"apiName":"Expense_Allocation__c","themeInfo" : {"color":"747E96","iconUrl":"/img/icon/t4v35/custom/custom40_120.png"}}';
        HttpResponse response = new HttpResponse();
        response.setHeader('Content-Type', 'application/json');
        response.setStatusCode(200);
        response.setBody(body);
        return response;
    }
}
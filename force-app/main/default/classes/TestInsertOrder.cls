@isTest
public class TestInsertOrder {
    
    
    @isTest
    public static void makePostCallout(){
        
        String JSONMsg = '[{"AccountId": "001ak00000Fnb5rAAB","EffectiveDate": "2024-05-02","ContractId": "800ak000008fd33AAA","Status": "Draft"}]';
        
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
        
        req.requestURI = '/services/apexrest/InsertOrder';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueof(JsonMsg);
        res.responseBody = Blob.valueOf('Order Inserted');
        
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
        REST_InsertOrder.insertOrder();
        Test.stopTest();
        
        System.assertEquals(200, res.statusCode);
        System.assertNotEquals(res.responseBody.toString(), 'A resposta não deve ser nula.');
        System.assertEquals(res.responseBody.toString(), 'Order Inserted');
    }  
}
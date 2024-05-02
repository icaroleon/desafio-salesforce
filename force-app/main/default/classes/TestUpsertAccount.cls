@isTest
public class TestUpsertAccount {
    
    @isTest
    public static void makePostCallout(){
        
        String JSONMsg = '[{"Name": "ContaTeste", "Pais__c": "a00ak000008dZOAAA2", "Email__c": "teste@teste.com" }]';
        
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
        
        req.requestURI = '/services/apexrest/AccountUpsert';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueof(JsonMsg);
        res.responseBody = Blob.valueOf('Account Inserted');
        
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
        REST_UpsertConta.upsertAccount();
        Test.stopTest();
        
        System.assertEquals(200, res.statusCode);
        System.assertNotEquals(res.responseBody.toString(), 'A resposta não deve ser nula.');
        System.assertEquals(res.responseBody.toString(), 'Account Inserted');
    }  
}
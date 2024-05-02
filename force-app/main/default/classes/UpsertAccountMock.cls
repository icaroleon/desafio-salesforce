global class UpsertAccountMock implements HttpCalloutMock{
    
    global HTTPResponse respond(HTTPRequest request) {
        
        HttpResponse response = new HttpResponse();
        response.setHeader('Content-Type', 'application/json');
        response.setBody('{"Name": "ContaTeste", "Pais__c": "a00ak000008dZOAAA2" }');
        response.setStatusCode(500);
        return response;  
    }
}
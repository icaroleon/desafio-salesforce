@RestResource(urlMapping='/AccountUpsert/*')
global class REST_UpsertConta {
    
    @HttpPost
    global static void upsertAccount(){
        RestRequest request = RestContext.request;
        RestResponse response = RestContext.response;
        
        String requestBody = request.requestBody.toString();
        List<Account> accountsToUpsert = (List<Account>) JSON.deserialize(requestBody, List<Account>.class);
        
        try{
            upsert accountsToUpsert;
            
            Map<String, Object> responseMap = new Map<String, Object>{
                'status' => 'success',
                    'message' => 'Accounts have been upserted successfully.',
                    'recordsUpsertedSize' => accountsToUpsert.size(),
                    'recordsUpserted' => accountsToUpsert
                    };
                        
                        String jsonResponse = JSON.serialize(responseMap);
            response.responseBody = Blob.valueOf(jsonResponse);
            
            response.statusCode = 200;
        } catch (Exception e){
            RestContext.response.responseBody = Blob.valueOf('Error: ' + e.getMessage());
            response.statusCode = 500;
        }
    }
}
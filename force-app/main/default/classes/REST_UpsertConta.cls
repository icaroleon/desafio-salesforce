@RestResource(urlMapping='/AccountUpsert/*')
global class REST_UpsertConta {
    
    @HttpPost
    global static void upsertAccount(){
        RestRequest req = RestContext.request;
        String reqBody = req.requestBody.toString();
        List<Account> accountsToUpsert = (List<Account>) JSON.deserialize(reqBody, List<Account>.class);
        
        try{
            upsert accountsToUpsert;
        } catch (Exception e){
            RestContext.response.responseBody = Blob.valueOf('Error: ' + e.getMessage());
        }
    }
}
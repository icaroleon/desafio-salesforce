@RestResource(urlMapping='/InsertOrder/*')
global class REST_InsertOrder {
    
    @HttpPost
    global static void insertOrder(){
        RestRequest req = RestContext.request;
        RestResponse response = RestContext.response;
        
        String reqBody = req.requestBody.toString();
        List<Order> ordersToInsert = (List<Order>) JSON.deserialize(reqBody, List<Order>.class);
        
        try{
            insert ordersToInsert;
            
            response.statusCode = 200;
        } catch (Exception e){
            RestContext.response.responseBody = Blob.valueOf('Error: ' + e.getMessage());   
        }
    }
}
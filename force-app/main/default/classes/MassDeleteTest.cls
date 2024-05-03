@isTest
public class MassDeleteTest {
    
    @testSetup
    static void setup() {
        List<Order> orders = new List<Order>();
        
        for (Integer i=0;i<10;i++) {
            String orderJson = '{"AccountId": "001ak00000Fnb5rAAB", "EffectiveDate": "2024-05-02", "ContractId": "800ak000008fd33AAA", "Status": "Draft", "LastModifiedDate" : "2024-02-01"}';
            Order order = (Order) JSON.deserialize(orderJson, Order.class);
            orders.add(order);
        }
        
        insert orders;
    }
    
    @isTest static void test() {
        Test.startTest();
        MassDeleteOrders massDeleteOrders = new MassDeleteOrders();
        Id batchId = Database.executeBatch(massDeleteOrders);
        Test.stopTest();
        
        Date threeMonthsFromToday = Date.Today().addMonths(-3);
        
        System.assertEquals(0, [SELECT count() FROM Order WHERE LastModifiedDate < :threeMonthsFromToday ]); 
    }
}
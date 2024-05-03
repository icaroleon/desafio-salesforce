global class ScheduleMassDelete implements Schedulable {

    global void execute(SchedulableContext sc){
        
        Database.executeBatch(new MassDeleteOrders(), 200);
    }
}
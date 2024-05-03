global class MassDeleteOrders implements Database.Batchable<sObject>, Database.Stateful {
    
    public Database.QueryLocator start(Database.BatchableContext bc) {
        Date threeMonthsAgo = Date.Today().addMonths(-3);
        String query = 'SELECT Id FROM Order WHERE LastModifiedDate < :threeMonthsAgo';
        
        return Database.getQueryLocator(query);
    }
    
    public void execute(Database.BatchableContext bc, List<Order> records){
        
        delete records;
    }
    
    public void finish(Database.BatchableContext bc){ 
        AsyncApexJob job = [SELECT Id, Status, NumberOfErrors,
                            JobItemsProcessed,
                            TotalJobItems, CreatedBy.Email
                            FROM AsyncApexJob
                            WHERE Id = :bc.getJobId()];
        
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        String[] toAddresses = new String[]{'icvieiramg@gmail.com'};
            
            
            try {
                mail.setToAddresses(toAddresses);
                mail.setSubject('Apex Sharing Recalculation ' + job.Status);
                mail.setPlainTextBody
                    ('The batch Apex job processed ' + job.TotalJobItems +
                     ' batches with '+ job.NumberOfErrors + ' failures.');
                Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
            } catch(Exception e){
                System.debug('Error sending email: ' + e.getMessage());
            }
        
    }
}
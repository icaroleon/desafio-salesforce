public class SendAccountEmail {
    
    public static void sendEmail(List<Account> accountsCreated){
        
        EmailTemplate emailTemplate = [Select ID from EmailTemplate WHERE DeveloperName = 'SalesNewCustomerEmail'];
        
        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
        
        for(Account acc : accountsCreated){
            
            if(acc.Wish_To_Send_Email_Confirmation__c == 'Yes' && acc.Email__c != null){
                
                Messaging.SingleEmailMessage singleMail = new Messaging.SingleEmailMessage();
                String [] toAddress = new String[]{acc.Email__c};
                    
                singleMail.setToAddresses(toAddress);
                singleMail.setSubject('Welcome to Our Service!');
                singleMail.setPlainTextBody('Dear Customer, thank you for signing up!');
                singleMail.setSaveAsActivity(false);
           
                emails.add(singleMail);
            }       
        }   
        
        if (!emails.isEmpty()) {
            Messaging.sendEmail(emails);
        }
    }
}
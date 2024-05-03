trigger sendEmailWhenAccountIsCreated on Account (before insert, before update) {
    List<Account> accountsCreated = new List<Account>();

    for(Account acc : Trigger.new){
       accountsCreated.add(acc);
    }

    SendAccountEmail.sendEmail(accountsCreated);
}
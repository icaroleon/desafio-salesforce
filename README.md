# Documentação do Projeto Desafio Salesforce

## Visão Geral do Projeto

Este projeto foi desenvolvido como parte do Desafio Salesforce, com o objetivo de implementar uma série de funcionalidades na plataforma Salesforce que permitem uma gestão mais eficaz e automatizada dos objetos `Account` e `Order`, assim como a criação e gestão de um objeto customizado chamado `País`. Este documento visa detalhar as soluções implementadas, explicar as decisões de design tomadas durante o desenvolvimento e discutir os componentes utilizados. 

Para tanto, os tópicos serão divididos conforme os requisitos apresentados no Desafio.

## 1. Customização de objetos

### Objeto `País` (Pais__c)
Foi criado um objeto customizado `País`, equipado com campos para `Sigla`, `Moeda` e `Idioma`. O campo `Sigla` foi configurado como obrigatório e único para evitar duplicidades e garantir a integridade dos dados.

| Campo  | API Name  | Tipo de Campo  | Objetivo |
|--------|-----------|----------------|----------|
| Idioma | Idioma__c | Texto          | Campo para armazenar informações sobre o `Idioma` do País. |
| Moeda  | Moeda__c  | Texto          | Campo para armazenar informações sobre a `Moeda` do País.  |
| Sigla  | Sigla__c  | Texto          | Campo para armazenar informações sobre a `Sigla` do País.  |
<br>

### - Campos Customizados no Objeto `Account` (Account)
Foram adicionados ao objeto `Account` três campos customizados:

| Campo                             | API Name                          | Tipo de Campo         | Objetivo                    |
|-----------------------------------|-----------------------------------|-----------------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| Valor Total de Vendas             | Valor_Total_de_Vendas__c          | Número (Currency)     | Campo para armazenar o valor total de vendas da conta.                                                                                                            |
| País                              | Pais__c                           | Lookup (País)         | Campo de relacionamento Lookup obrigatório com o objeto `País`, permitindo uma associação direta entre uma conta e um país.                                       |
| Resumo das Informações do País*   | Resumo_das_Informacoes_do_Pais__c | Texto (Formula)       | Campo para exibir um resumo das informações do país associado, formatado para mostrar nome, sigla, idioma e moeda, com a previsão de exibir "N/A" caso alguma informação não esteja disponível. |
| Email                             | Email__c                          | Texto (Email)         | Campo utilizado para armazenar um endereço de email que será enviado a informação sobre a criação da conta (Explicação detalhada mais a frente).                 |
| Wish To Send Email Confirmation?  | Wish_To_Send_Email_Confirmation__c| Checkbox              | Indica se o cliente deseja receber emails de confirmação ou não. (Explicação detalhada mais a frente)                                                            |



## 2. Campo de resumo das informações do País em Conta

Um dos requisitos apresentados era criar um campo que exibisse um resumo das informações principais de um país, formatado de maneira específica. Esse campo deveria incluir o nome do país, a sigla, o idioma oficial e a moeda em uso, apresentados de forma clara e concisa para fácil consulta e integração. Para tanto, foi implementado um campo **fórmula**, sendo que a expressão restou configurada da seguinte forma:

```
"- N: " & IF(Pais__r.Name = null, "__N/A__", Pais__r.Name) &BR()&
"- S: " & IF(Pais__r.Sigla__c = null, "__N/A__", Pais__r.Sigla__c) &BR()&
"- I: " & IF(Pais__r.Idioma__c = null, "__N/A__", Pais__r.Idioma__c)&BR()&
"- M: " & IF(Pais__r.Moeda__c = null, "__N/A__", Pais__r.Moeda__c)
```


## 3. Endpoints Customizados e seus respectivos testes
### Endpoint de "Upsert" para o objeto `Account`:

```
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
```
### Teste do Endpoint de "Upsert" para Account:
```
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
```

### Endpoint de "Insert" para `Order`:

```
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
```
### Teste do Endpoint de "Insert" para `Order`:

```
@isTest
public class TestInsertOrder {
    @isTest
    public static void makePostCallout(){

        String JSONMsg = '[{"AccountId": "001ak00000Fnb5rAAB","EffectiveDate": "2024-05-02","ContractId": "800ak000008fd33AAA","Status": "Draft"}]';

        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();

        req.requestURI = '/services/apexrest/InsertOrder';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueof(JsonMsg);
        res.responseBody = Blob.valueOf('Order Inserted');

        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        REST_InsertOrder.insertOrder();
        Test.stopTest();

        System.assertEquals(200, res.statusCode);
        System.assertNotEquals(res.responseBody.toString(), 'A resposta não deve ser nula.');
        System.assertEquals(res.responseBody.toString(), 'Order Inserted');
    }
}
```

## 4. Automação com Código para enviar email sempre que uma cria conta
Foi desenvolvida uma automação com código para enviar um email sempre que uma conta for criada ou editada, com a possibilidade de habilitar ou desabilitar essa funcionalidade via interface gráfica. 

Para tanto, foi criado tanto um componente LWC afim de demonstrar os conhecimentos adquiridos quanto adicionado um campo de confirmação ao formulário de criação de registro. 

Caso a opção "*Wish To Send Email Confirmation*" esteja desabilitada, o email de criação de conta não é enviado. Também, a lógica da confirmação do email foi separada da Trigger, de modo a seguir as boas práticas.

PS: Cabe ressaltar que, apesar de ter sido uma ótima oportunidade de aplicar os conhecimentos LWC, após uma análise da possível implementação, é bem possível que, a depender das *regras de negócio* não seja necessário desenvolver um componente ou uma trigger que seja acionada no momento da edição do registro. Afinal, se o objetivo é somente enviar um e-mail ao criar contas, não há necessidade de acionar a trigger no evento de atualização. Limitando a trigger ao evento before insert, seria otimizado o desempenho e evita-se o envio desnecessário de e-mails durante atualizações. 

### Trigger:
```
trigger sendEmailWhenAccountIsCreated on Account (before insert, before update) {
    SendAccountEmail.sendEmail(Trigger.new);
}
```
### Classe Apex responsável pelo envio do email:

```
public class SendAccountEmail {
    
   public static void sendEmail(List<Account> accountsCreated){
        
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
```
### Componente LWC (HTML):

```
<template>
  <lightning-card>
    <div class="inputs">
      <lightning-record-edit-form
      record-id={recordId}
      object-api-name="Account"
      >
      <lightning-messages> </lightning-messages>
      <lightning-output-field field-name="AccountId">
      </lightning-output-field>
      <lightning-input-field field-name="Email__c"> </lightning-input-field>
      <lightning-input-field field-name="Wish_To_Send_Email_Confirmation__c"></lightning-input-field>
      <lightning-input-field field-name="Email"> </lightning-input-field>
      <lightning-button
      class="slds-m-top_small"
      variant="brand"
      type="submit"
      name="update"
      label="Salvar"
      >
      </lightning-button>
      </lightning-record-edit-form>
    </div>
  </lightning-card>
</template>
```
### Componente LWC (Javascript):

```
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { LightningElement, api } from 'lwc';

export default class AccountEmailEditor extends LightningElement {

  @api recordId;

    handleSuccess(event) {
        this.dispatchEvent(new ShowToastEvent({
            title: 'Success',
            message: 'E-mail has been updated!',
            variant: 'success'
        }));
    }
}
```
## 4. Automação sem código
- Uma automação sem uso de código foi implementada para atualizar o valor total de vendas de uma conta sempre que uma nova `Order` for associada a essa conta.


### 5. Processo Automático de Limpeza de Dados
A fim de criar uma automação que seja capaz de realizar a deleção de ordens com data de modificação maior que 3 meses e, de modo a considerar o alto volume de dados envolvido, foi criado um código que define uma classe global chamada ScheduleMassDelete que implementa a interface Schedulable do Salesforce. Isso permite que a classe seja agendada para executar em intervalos específicos conforme definido pelo agendamento do Apex. Tal classe chama outra classe Apex inicia um trabalho de processamento em lote. Isso é adequado para operações que precisam processar um grande número de registros, como deletar ordens em massa.

### Classe Apex de Agendamento

 ```
 global class ScheduleMassDelete implements Schedulable {

    global void execute(SchedulableContext sc){
        Database.executeBatch(new MassDeleteOrders(), 200);
    }
}
```
### Classe Apex responsável por buscar as Ordens à serem deletadas e lidar com o alto volume de dados:

```
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
```

### Teste da Classe Apex responsável pela deleção:

```
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
```


## Considerações de Design e Implementação

Durante o desenvolvimento, diversas considerações de design foram feitas para maximizar a eficiência e a eficácia das soluções implementadas. Este documento também inclui uma discussão sobre alternativas de implementação, vantagens e desvantagens das abordagens escolhidas, impactos nos limites da plataforma Salesforce e outras notas relevantes.

## Conclusão

Este documento fornece uma visão completa das funcionalidades implementadas no Desafio Globo Salesforce, oferecendo insights sobre as técnicas e práticas adotadas. As soluções propostas visam melhorar a interação com a plataforma Salesforce, proporcionando maior automação e integração de processos críticos de negócios.

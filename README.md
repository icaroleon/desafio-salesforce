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

	// Converte o corpo da requisição de JSON para uma lista de objetos Account
        String requestBody = request.requestBody.toString();
        List<Account> accountsToUpsert = (List<Account>) JSON.deserialize(requestBody, List<Account>.class);

        try{
            upsert accountsToUpsert;

	    // Prepara a resposta de sucesso caso seja inserido com sucesso
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
	    // Em caso de exceção, prepara a resposta de erro
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
        
        // Converte o corpo da requisição de JSON para uma lista de objetos Account
        String reqBody = req.requestBody.toString();
        List<Order> ordersToInsert = (List<Order>) JSON.deserialize(reqBody, List<Order>.class);
        
        try{
            insert ordersToInsert;
             // Prepara a resposta de sucesso caso seja inserido com sucesso
            Map<String, Object> responseMap = new Map<String, Object>{
                'status' => 'success',
                    'message' => 'Orders have been inserted successfully.',
                    'recordsInsertedSize' => ordersToInsert.size(),
                    'recordsInserted' => ordersToInsert
                    };
                        
                        String jsonResponse = JSON.serialize(responseMap);
            response.responseBody = Blob.valueOf(jsonResponse);
            response.statusCode = 200;
        } catch (Exception e){     
            // Em caso de exceção, prepara a resposta de erro
            Map<String, Object> errorResponse = new Map<String, Object>{
                'status' => 'error',
                'message' => 'Error: ' + e.getMessage()
            };
            
            String errorJsonResponse = JSON.serialize(errorResponse);
            response.responseBody = Blob.valueOf(errorJsonResponse);
            response.statusCode = 500;
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

    // Método estático para enviar e-mails de confirmação de conta
    public static void sendEmail(List<Account> accountsCreated) {

        // Lista para armazenar os e-mails a serem enviados
        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();

        // Itera sobre as contas criadas
        for (Account acc : accountsCreated) {
            // Verifica se a opção de envio de e-mail de confirmação está habilitada e se o e-mail da conta não é nulo
            if (acc.Wish_To_Send_Email_Confirmation__c == 'Yes' && acc.Email__c != null) {
                
                // Cria um objeto SingleEmailMessage para o e-mail
                Messaging.SingleEmailMessage singleMail = new Messaging.SingleEmailMessage();
                
                // Define o endereço de e-mail do destinatário
                String[] toAddress = new String[]{acc.Email__c};
                singleMail.setToAddresses(toAddress);
                
                // Define o assunto e o corpo do e-mail
                singleMail.setSubject('Welcome to Our Service!');
                singleMail.setPlainTextBody('Dear Customer, thank you for signing up!');
                
                // Define se o e-mail deve ser salvo como uma atividade na Salesforce
                singleMail.setSaveAsActivity(false);
                
                // Adiciona o e-mail à lista de e-mails
                emails.add(singleMail);
            }
        }
        
        // Se a lista de e-mails não estiver vazia, envia os e-mails
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
Uma automação sem uso de código foi implementada para atualizar o valor total de vendas de uma conta sempre que uma nova `Order` for associada a essa conta. Para tanto, utilizou-se Flow Buider. Contudo, algumas considerações são necessárias.

O requisito da tarefa é atualizar o campo Valor Total de Vendas sempre que uma nova Order for criada. No entanto, observa-se que, **no momento de criação de Order**, atualmente não há como associar o registro do objeto Order a um Produto específico. Além disso, mesmo que um campo fosse adicionado para permitir a associação de um produto ao criar uma Order, essa automação apresentaria limitações. A principal delas é que a atualização do Valor Total de Vendas ficaria limitada ao momento da criação da Order, sem considerar atualizações subsequentes, como a adição de novos itens, o que comprometeria a precisão do valor total.

Outra limitação é que o campo "Order Amount" em Order é um campo de totalização e não ativa Flow Triggers, o que impede seu uso efetivo nesse contexto. Uma solução alternativa poderia ser a criação de um objeto Order personalizado, mas optou-se por não seguir esse caminho para poder aproveitar todas as funcionalidades padrão oferecidas pelo Salesforce.

Para contornar essas dificuldades, implementou-se um Flow Trigger associado ao Objeto Order Product. Nesse cenário, sempre que um registro é criado ou atualizado, o sistema captura automaticamente a Order relacionada. Em seguida, obtém-se a Conta associada (informação disponível apenas após a captura da Order correspondente) e recolhe-se os demais itens da Order. Em seguida, realiza-se um loop em que todos os itens capturados são processados, atribuindo-se os seus valores ao valor total da Conta. Totalizando assim o Valor Total no Objeto Conta.

<p align="center">
  <img src="https://github.com/icaroleon/desafio-salesforce/assets/100085859/017a3db7-10f9-4816-9fb7-92eaac274ab0" />
</p>

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


## Conclusão e Considerações de Design e Implementação

Durante o desenvolvimento, diversas considerações de design foram feitas para maximizar a eficiência e a eficácia das soluções implementadas. A princípio, apesar da Salesforce apresentar diversas possibilidades de customização, propõe-se seguir o seu LDS, de modo a aproveitar o máximo dos recursos nativos. Contudo, a depender das Regras de Negócio ou dos objetivos da implementação, não se vê obstáculos em modificar o caminho. Também, cabe destacar que o escopo do projeto representa apenas uma parcela das possibilidades disponíveis e que a solução deve ser adaptada de acordo com as necessidades individuais de cada cliente.

Para garantir uma implementação sem contratempos,atenção especial à documentação e à consulta à comunidade Salesforce foi dedicada, realizando profunda pesquisa antes do início da implementação. Questões específicas, como as peculiaridades do objeto Order, foram abordadas com base em experiências anteriores compartilhadas por outros membros da comunidade.

Quanto a futuras melhorias, seria interessante a implementação de testes unitários abrangentes, incluindo cenários negativos, e uma cobertura mais completa, especialmente para o componente LWC. Embora não tenha sido abordado esses aspectos completamente devido a restrições de tempo, a importância de sua inclusão para garantir a qualidade e a robustez da solução é essencial.

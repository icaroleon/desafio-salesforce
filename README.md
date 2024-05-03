# Documentação do Projeto Desafio Globo Salesforce

## Visão Geral do Projeto

Este projeto foi desenvolvido como parte do Desafio Globo Salesforce, com o objetivo de implementar uma série de funcionalidades na plataforma Salesforce que permitem uma gestão mais eficaz e automatizada dos objetos `Account` e `Order`, assim como a criação e gestão de um objeto customizado chamado `País`. Este documento visa detalhar as soluções implementadas, explicar as decisões de design tomadas durante o desenvolvimento e discutir os componentes utilizados.

## Funcionalidades Implementadas
## 1. Customização de objetos

### - Objeto `País` (Pais__c)
Foi criado um objeto customizado `País`, equipado com campos para `Sigla`, `Moeda` e `Idioma`. O campo `Sigla` foi configurado como obrigatório e único para evitar duplicidades e garantir a integridade dos dados.

| Campo  | API Name  | Tipo de Campo  | Objetivo |
|--------|-----------|----------------|----------|
| Idioma | Idioma__c | Texto          | Campo para armazenar informações sobre o `Idioma` do País. |
| Moeda  | Moeda__c  | Texto          | Campo para armazenar informações sobre a `Moeda` do País.  |
| Sigla  | Sigla__c  | Texto          | Campo para armazenar informações sobre a `Sigla` do País.  |


### - Campos Customizados no Objeto `Account` (Account)
Foram adicionados ao objeto `Account` três campos customizados:

| Campo                             | API Name                          | Tipo de Campo         | Objetivo                                                                                                                                                          |
|-----------------------------------|-----------------------------------|-----------------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| Valor Total de Vendas             | Valor_Total_de_Vendas__c          | Número (Currency)     | Campo para armazenar o valor total de vendas da conta.                                                                                                            |
| País                              | Pais__c                           | Lookup (País)         | Campo de relacionamento Lookup obrigatório com o objeto `País`, permitindo uma associação direta entre uma conta e um país.                                       |
| Resumo das Informações do País*   | Resumo_das_Informacoes_do_Pais__c | Texto (Formula)       | Campo para exibir um resumo das informações do país associado, formatado para mostrar nome, sigla, idioma e moeda, com a previsão de exibir "N/A" caso alguma informação não esteja disponível. |
| Email                             | Email__c                          | Texto (Email)         | Campo utilizado para armazenar um endereço de email que será enviado a informação sobre a criação da conta (Explicação detalhada mais a frente).                 |
| Wish To Send Email Confirmation?  | Wish_To_Send_Email_Confirmation__c| Checkbox              | Indica se o cliente deseja receber emails de confirmação ou não. (Explicação detalhada mais a frente)                                                            |

</br>
</br>

### Detalhamento do Campo de Fórmula (Requisito do Desafio)

**Objetivo:** *Para realizar tal inserção, o tipo de campo selecionado foi **fórmula**, de modo a capturar as informações do relacionamento com o Objeto País e inserir tais informações.*

**Validação Final:**
A expressão de fórmula usada para construir o campo foi configurada da seguinte forma:

```
"- N: " & IF(Pais__r.Name = null, "__N/A__", Pais__r.Name) &BR()&
"- S: " & IF(Pais__r.Sigla__c = null, "__N/A__", Pais__r.Sigla__c) &BR()&
"- I: " & IF(Pais__r.Idioma__c = null, "__N/A__", Pais__r.Idioma__c)&BR()&
"- M: " & IF(Pais__r.Moeda__c = null, "__N/A__", Pais__r.Moeda__c)
```

</br>
</br>
</br>

### 2. Endpoints Customizados e seus respectivos testes
Implementamos dois endpoints customizados:
- Um endpoint de "Upsert" para o objeto `Account`, permitindo atualizações ou inserções baseadas na existência do registro.

Endpoint:

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

Teste:

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




- Um endpoint de "Insert" para o objeto `Order`, facilitando a inserção de novas ordens com detalhamento claro dos contratos de entrada e saída.

### 4. Automação com e sem Código
- Foi desenvolvida uma automação com código para enviar um email sempre que uma conta for criada ou editada, com a possibilidade de habilitar ou desabilitar essa funcionalidade via interface gráfica.
- Uma automação sem uso de código foi implementada para atualizar o valor total de vendas de uma conta sempre que uma nova `Order` for associada a essa conta.

### 5. Processo Automático de Limpeza de Dados
Criamos um processo que executa automaticamente uma vez por dia para deletar ordens com data de modificação maior que 3 meses, considerando o alto volume de dados envolvido.

## Considerações de Design e Implementação

Durante o desenvolvimento, diversas considerações de design foram feitas para maximizar a eficiência e a eficácia das soluções implementadas. Este documento também inclui uma discussão sobre alternativas de implementação, vantagens e desvantagens das abordagens escolhidas, impactos nos limites da plataforma Salesforce e outras notas relevantes.

## Conclusão

Este documento fornece uma visão completa das funcionalidades implementadas no Desafio Globo Salesforce, oferecendo insights sobre as técnicas e práticas adotadas. As soluções propostas visam melhorar a interação com a plataforma Salesforce, proporcionando maior automação e integração de processos críticos de negócios.

# Busca de CEP e CNPJ: decisões técnicas

> Escrito para: desenvolvedores Salesforce que vão manter ou revisar este projeto.

## 1. Objetivo

Buscar endereço por CEP (ViaCEP) e dados cadastrais por CNPJ (CNPJ.ws) em uma tela LWC, com validação, cache, tratamento de erro e acessibilidade.

## 2. Decisões

### 2.1 Chamadas feitas no Apex, não no LWC

O LWC não chama as APIs diretamente. O Apex faz o callout usando **Named Credential**.

- **Motivo:** o endereço da API fica em configuração, não no front-end. O Salesforce cuida da política de rede (Remote Site ou Named Credential), e o código fica testável com `HttpCalloutMock`.
- **Custo:** cada busca passa pelo servidor, então o cache tem mais valor.

### 2.2 Camadas: Controller → Service → Client

| Camada | Responsabilidade |
|---|---|
| Controller (`@AuraEnabled`) | Recebe o pedido do LWC, valida a entrada e devolve o resultado. Não contém regra de negócio. |
| Service | Regra de negócio: escolhe cache ou API, normaliza o resultado. |
| Client HTTP | Monta a requisição, chama a Named Credential e interpreta a resposta. Uma classe por API (`ViaCepClient`, `CnpjWsClient`). |

Cada client é injetável por interface. Assim os testes trocam a API real por um stub ou por um `HttpCalloutMock`.

### 2.3 Erros

- Erro de infraestrutura (timeout, HTTP 5xx, resposta inesperada) vira uma exceção própria, por exemplo `CepServiceException`.
- O usuário recebe uma **mensagem genérica**, sem detalhe técnico.
- O detalhe vai para o log do Logger, que é o projeto `logger-platform-events`.
- CEP ou CNPJ não encontrado não é erro de infraestrutura: é um resultado normal, com mensagem própria.

### 2.4 Validação centralizada no Apex

- CEP (8 dígitos) e CNPJ (14 dígitos, com dígitos verificadores) são validados no Apex, pela classe `CpfCnpjValidator` e por regras equivalentes para CEP.
- O LWC faz apenas uma checagem cosmética (formato e tamanho), para dar retorno rápido ao usuário. A regra oficial fica no servidor.

### 2.5 Cache

- **Primeira opção:** Platform Cache (partição de organização), com TTL definido por tipo de consulta.
- **Fallback:** objeto customizado de cache, usado quando a partição não estiver disponível na org.
- **Motivo:** CEP e CNPJ mudam pouco. Evitar a mesma chamada várias vezes reduz latência e uso das APIs.

### 2.6 Segurança

- Consultas em `WITH USER_MODE`.
- Acesso ao app pelo permission set `Busca_Dados_Cadastrais`.
- Named Credentials sem autenticação, porque ViaCEP e CNPJ.ws são públicas e não recebem dados sensíveis.

### 2.7 Versão da API

Projeto em API **67.0**, o mesmo do `projeto-entrevista`.

### 2.8 Provedor de CNPJ: CNPJ.ws, e não BrasilAPI

A BrasilAPI foi a primeira escolha. Na validação real pela org, ela respondeu **HTTP 403** com uma página do Cloudflare, enquanto a mesma URL respondia 200 fora do Salesforce. O bloqueio é do provedor, e não há como contorná-lo do nosso lado sem disfarçar a origem das chamadas, o que não fazemos.

Trocamos para a **API pública do CNPJ.ws**: documentação oficial, sem chave de acesso e limite de **3 consultas por minuto por IP** (HTTP 429 quando excedido). O `CnpjWsClient` implementa a mesma interface `ICnpjClient`, então Service e Controller não mudaram. O limite de 429 vira `ExternalApiException`, tratada como indisponibilidade.

Consequência para o produto: em volume alto, a busca de CNPJ exige um plano pago do CNPJ.ws ou outro provedor. Isso fica registrado como limite conhecido.

## 3. Estado atual do repositório

| Item | Situação |
|---|---|
| Validação de CPF e CNPJ (CpfCnpjValidator) | Presente e testado. A biblioteca de Invocable Actions (dias úteis, telefone, slug e outras) foi separada para o repositório invocable-actions-library. |
| Named Credentials `ViaCEP` e `CnpjWs` | Criadas (`NoAuthentication`) e testadas com chamadas reais pela org. |
| Permission set `Busca_Dados_Cadastrais` | Criado, sem acessos ainda. |
| Clients HTTP (ViaCepClient, CnpjWsClient) | Presentes e deployados na DevEd, com 11 testes usando HttpCalloutMock. Erros de infraestrutura viram ExternalApiException; entrada inválida vira InvalidInputException. |
| Service (BuscaDadosService) e Controller (BuscaDadosController) | Presentes e deployados na DevEd. O Controller traduz erros para mensagens genéricas e registra o detalhe no debug log. |
| Cache (`BuscaCacheStore`) | Presente: Platform Cache (partição `BuscaCache`) com fallback no objeto `Busca_Cache__c`. Testado com busca real: 231 ms na API e 1 ms no cache. |
| LWC de busca (`cepCnpjBusca`) | Presente e deployado, com 8 testes Jest e App Page "Busca de Dados Cadastrais". Acessibilidade: rótulos, região aria-live, erros com role alert e foco no resultado. |
| Testes com `HttpCalloutMock` | **Não iniciados.** |

## 4. Fases previstas

1. **Estrutura e metadados** (esta fase): Named Credentials, permission set e documento de decisões.
2. **Clients HTTP** para ViaCEP e CNPJ.ws, com testes e mocks. *(concluída)*
3. **Service e Controller**, com validação e tratamento de erro. *(concluída)*
4. **Cache** com Platform Cache e fallback. *(concluída)*
5. **LWC de busca**, com acessibilidade. *(concluída)*
6. **README final**, com deploy e demonstração.

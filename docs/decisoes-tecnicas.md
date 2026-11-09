# Busca de CEP e CNPJ: decisões técnicas

> Escrito para: desenvolvedores Salesforce que vão manter ou revisar este projeto.

## 1. Objetivo

Buscar endereço por CEP (ViaCEP) e dados cadastrais por CNPJ (BrasilAPI) em uma tela LWC, com validação, cache, tratamento de erro e acessibilidade.

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
| Client HTTP | Monta a requisição, chama a Named Credential e interpreta a resposta. Uma classe por API (`ViaCepClient`, `BrasilApiClient`). |

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
- Named Credentials sem autenticação, porque ViaCEP e BrasilAPI são públicas e não recebem dados sensíveis.

### 2.7 Versão da API

Projeto em API **67.0**, o mesmo do `projeto-entrevista`.

## 3. Estado atual do repositório

| Item | Situação |
|---|---|
| Validação de CPF e CNPJ, telefone, dias úteis, slugs e utilitários | Presente e deployado na DevEd: 109 testes passando, sem erros. |
| Named Credentials `ViaCEP` e `BrasilAPI` | Criadas (`NoAuthentication`). |
| Permission set `Busca_Dados_Cadastrais` | Criado, sem acessos ainda. |
| Controller, Service e Clients HTTP | **Não iniciados.** Fase 2. |
| Cache | **Não iniciado.** Fase 3 ou 4. |
| LWC de busca | **Não iniciado.** |
| Testes com `HttpCalloutMock` | **Não iniciados.** |

## 4. Fases previstas

1. **Estrutura e metadados** (esta fase): Named Credentials, permission set e documento de decisões.
2. **Clients HTTP** para ViaCEP e BrasilAPI, com testes e mocks.
3. **Service e Controller**, com validação e tratamento de erro.
4. **Cache** com Platform Cache e fallback.
5. **LWC de busca**, com acessibilidade.
6. **README final**, com deploy e demonstração.

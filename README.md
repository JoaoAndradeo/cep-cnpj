# Busca de CEP e CNPJ no Salesforce

Tela em LWC para buscar endereço por CEP (ViaCEP) e dados cadastrais por CNPJ (CNPJ.ws), com validação no servidor, cache, tratamento de erro e acessibilidade.

> Decisões técnicas e histórico de cada fase: [docs/decisoes-tecnicas.md](docs/decisoes-tecnicas.md).

<!-- O GIF ainda não foi gravado. Grave a tela de busca com um CEP e um CNPJ, salve em docs/demo.gif e o link abaixo passa a funcionar. -->
![Demonstração da busca de CEP e CNPJ](docs/demo.gif)

## Funcionalidades

- **Busca por CEP:** endereço completo (logradouro, complemento, bairro, cidade e UF). Aceita o CEP com ou sem máscara.
- **Busca por CNPJ:** razão social, nome fantasia, situação cadastral e endereço do estabelecimento. O CNPJ é validado com os dígitos verificadores antes de qualquer chamada.
- **Cache:** resultados encontrados ficam guardados (CEP por 1 dia, CNPJ por 1 hora), para reduzir chamadas às APIs. Resultados "não encontrado" não são guardados.
- **Erros tratados:** entrada inválida, CEP ou CNPJ inexistente, e falha das APIs têm mensagens próprias para o usuário.
- **Acessibilidade:** rótulos em todos os campos, região `aria-live` para os resultados, erros anunciados com `role="alert"`, e foco no título do resultado depois da busca.

## Arquitetura

```mermaid
flowchart LR
    LWC[LWC cepCnpjBusca] --> C[BuscaDadosController<br/>@AuraEnabled]
    C --> S[BuscaDadosService<br/>validação e cache]
    S --> K{Cache}
    K -->|1ª opção| P[(Platform Cache<br/>BuscaCache)]
    K -->|fallback| O[(Busca_Cache__c)]
    S --> CL[ViaCepClient<br/>CnpjWsClient]
    CL --> H[Chamada HTTP com timeout de 10 s]
    H -->|Named Credential ViaCEP| V[viacep.com.br]
    H -->|Named Credential CnpjWs| W[publica.cnpj.ws]
```

- **Controller:** recebe o pedido do LWC e traduz exceções em mensagens seguras. O detalhe técnico vai para o log, e a tela nunca o recebe.
- **Service:** valida a entrada antes de qualquer chamada, consulta o cache e só então chama o client.
- **Clients:** uma classe por API, atrás de uma interface (`ICepClient`, `ICnpjClient`). Assim os testes trocam a API real por um stub.
- **Named Credentials:** o endereço das APIs fica em configuração, não no código. Não há autenticação, porque as duas APIs são públicas.

## Estrutura

```
force-app/main/default/
├── classes/              Controller, Service, clients, cache, validadores e testes
├── cachePartitions/      Partição BuscaCache (Platform Cache)
├── flexipages/           App Page "Busca de Dados Cadastrais"
├── lwc/cepCnpjBusca/     Componente de busca, com testes Jest
├── namedCredentials/     ViaCEP e CnpjWs
├── objects/Busca_Cache__c/  Fallback do cache
└── permissionsets/       Busca_Dados_Cadastrais
docs/decisoes-tecnicas.md
```

## Deploy

**Pré-requisitos:** Salesforce CLI, Node.js (para os testes Jest) e uma Developer Edition.

1. **Autorize a org**
   ```bash
   sf org login web --alias DevEd --set-default --instance-url https://login.salesforce.com
   ```

2. **Publique o código e rode os testes**
   ```bash
   sf project deploy start --source-dir force-app --target-org DevEd --test-level RunLocalTests
   ```

3. **Atribua o permission set** ao usuário que vai usar a busca
   ```bash
   sf org assign permset --name Busca_Dados_Cadastrais --target-org DevEd
   ```

4. **Ative a App Page** em *Setup → Lightning App Builder*: abra **Busca de Dados Cadastrais** e atribua a um app.

5. **Testes Jest do LWC:**
   ```bash
   npm install
   npm run test:unit
   ```

## Testes

| Tipo | Resultado |
|---|---|
| Apex (`RunLocalTests`) | 144 testes passando |
| Cobertura Apex (org) | 95% |
| Jest (LWC `cepCnpjBusca`) | 8 testes passando |

Os testes Apex não fazem chamadas reais: usam `HttpCalloutMock` e stubs. As chamadas reais foram validadas à parte, de dentro da org, com o ViaCEP e com o CNPJ.ws.

## Limitações conhecidas

- **CNPJ.ws:** a API pública aceita **3 consultas por minuto por IP**. Acima disso, a busca mostra a mensagem de indisponibilidade. Para uso em volume, é preciso um plano pago.
- **BrasilAPI não é usada:** ela foi a primeira escolha, mas bloqueia requisições vindas de servidores do Salesforce (HTTP 403 do Cloudflare). A troca está registrada na seção 2.8 das decisões técnicas.
- **Registro de erros:** o detalhe técnico vai para o debug log. A integração com o Logger do projeto `logger-platform-events` está prevista, mas não feita.
- **Cache:** a partição Platform Cache tem 1 MB. Quando ela não está disponível na org, o cache usa o objeto `Busca_Cache__c`.
- **Análise estática:** o projeto não passou pelo Code Analyzer.

## Próximos passos

- Enviar os erros técnicos ao Logger, em vez do debug log.
- Gravar o GIF de demonstração.
- Avaliar outro provedor de CNPJ para uso em volume.

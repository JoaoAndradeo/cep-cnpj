# CEP/CNPJ: validação e enriquecimento de dados cadastrais no Salesforce

> **Status: em desenvolvimento.** Este repositório reúne a parte já organizada do projeto. Ainda não está pronto para deploy.

## O que tem aqui

- **Validação:** `CpfCnpjValidator` valida CPF (11 dígitos) e CNPJ (14 dígitos) com os dígitos verificadores. É lógica pura, sem SOQL nem DML.
- **Formatação:** `PhoneFormatter` e `FormatPhoneAction`, para telefones.
- **Dias úteis:** `BusinessDaysCalculator` e `BusinessDaysAction`, com feriados em Custom Metadata (`Feriado__mdt`) e um provider com `IHolidayProvider`.
- **Strings:** `SlugGenerator`, `StringSplitter`, `SplitStringAction` e `ActionMessages`.
- **Campos relacionados:** `RelatedFieldReader` e `ReadRelatedFieldAction`.
- **Validação de documento em Flow:** `ValidateDocumentAction`.
- **Testes de apoio:** `TestDataFactory` e as classes `*Test`.
- **Flow de demonstração** (`Demo_Invocable_Actions`) e o permission set `Invocable_Actions_User`.

## Limitações conhecidas

- **CNPJ:** a API pública do CNPJ.ws aceita 3 consultas por minuto por IP. Em volume maior, é preciso um plano pago.

## Deploy (quando estiver pronto)

```bash
sf org login web --alias DevEd --set-default --instance-url https://login.salesforce.com
sf project deploy start --source-dir force-app --target-org DevEd --test-level RunLocalTests
```
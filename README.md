# Busca de CEP e CNPJ

Tela em LWC para buscar endereço por CEP (ViaCEP) e dados de empresa por CNPJ (CNPJ.ws). As chamadas saem do servidor, por Named Credentials.

As decisões técnicas e o histórico de cada etapa estão em [docs/decisoes-tecnicas.md](docs/decisoes-tecnicas.md).

<!-- O GIF ainda não foi gravado. Grave a tela de busca com um CEP e um CNPJ, salve em docs/demo.gif e o link abaixo passa a funcionar. -->
![Demonstração da busca de CEP e CNPJ](docs/demo.gif)

## O que faz

- **CEP:** mostra logradouro, complemento, bairro, cidade e UF. Aceita o CEP com ou sem máscara.
- **CNPJ:** mostra razão social, nome fantasia, situação cadastral e endereço. O CNPJ é validado com os dígitos verificadores antes da consulta.
- **Cache:** guarda os resultados encontrados por 1 dia (CEP) ou 1 hora (CNPJ). Quando não encontra, não guarda.
- **Erros:** entrada inválida, CEP ou CNPJ inexistente e falha das APIs têm mensagens próprias para o usuário.
- **Acessibilidade:** rótulos em todos os campos, resultados anunciados por leitor de tela e foco no título do resultado depois da busca.

## Por que importa

Digitar endereço e dados de empresa à mão gera erro e retrabalho. Um CEP ou uma razão social digitados errado afetam entrega, cobrança e cadastro.

## Ganho

- Menos digitação e menos erro de endereço e de razão social.
- O CNPJ é validado antes da consulta, então não há chamada desnecessária à API.
- O cache reduz consultas e ajuda a respeitar o limite de 3 consultas por minuto da CNPJ.ws.
- As chaves e os endereços das APIs ficam fora do código, nas Named Credentials.

## Como o código se organiza

- `BuscaDadosController`: expõe os métodos para o LWC e transforma erros em mensagens para a tela.
- `BuscaDadosService`: valida a entrada, consulta o cache e chama a API só quando precisa.
- `ViaCepClient` e `CnpjWsClient`: fazem a chamada a cada API e leem a resposta.
- `BuscaCacheStore`: usa Platform Cache e, se a partição não existir, o objeto `Busca_Cache__c`.

## Limitações

- **CNPJ.ws:** a API pública aceita 3 consultas por minuto por IP. Acima disso, a busca mostra a mensagem de indisponibilidade.
- **BrasilAPI:** foi a primeira escolha, mas bloqueou as chamadas vindas do Salesforce (HTTP 403). A troca está em [docs/decisoes-tecnicas.md](docs/decisoes-tecnicas.md).
- **Erros técnicos:** vão para o debug log. Ainda não são enviados ao Logger.
- **Cache:** a partição de Platform Cache tem 1 MB. Sem ela na org, o cache usa o objeto `Busca_Cache__c`.

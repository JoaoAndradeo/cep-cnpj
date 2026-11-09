/**
 * Client HTTP da API pública do CNPJ.ws, via Named Credential CnpjWs.
 * Limite da API pública: 3 consultas por minuto por IP (HTTP 429 quando excedido).
 * Não exige chave de acesso.
 */
public with sharing class CnpjWsClient implements ICnpjClient {

    private static final String SERVICE = 'CNPJ.ws';

    private final ExternalHttpClient http;

    public CnpjWsClient() {
        this(new ExternalHttpClient());
    }

    public CnpjWsClient(ExternalHttpClient http) {
        this.http = http;
    }

    public CompanyInfo findByCnpj(String cnpj) {
        CpfCnpjValidator.Result check = CpfCnpjValidator.validate(cnpj);
        if (!check.isValid || check.documentType != CpfCnpjValidator.TYPE_CNPJ) {
            throw new InvalidInputException('CNPJ inválido.');
        }
        String digits = check.normalizedNumber;

        HttpResponse response = http.get('callout:CnpjWs/cnpj/' + digits, SERVICE);
        if (response.getStatusCode() == 404) {
            return null;
        }

        Map<String, Object> body = parseBody(response.getBody());
        Map<String, Object> establishment = child(body, 'estabelecimento');
        Map<String, Object> city = child(establishment, 'cidade');
        Map<String, Object> state = child(establishment, 'estado');

        CompanyInfo company = new CompanyInfo();
        company.cnpj = digits;
        company.legalName = text(body, 'razao_social');
        company.tradeName = text(establishment, 'nome_fantasia');
        company.registrationStatus = text(establishment, 'situacao_cadastral');
        company.street = text(establishment, 'logradouro');
        company.streetNumber = text(establishment, 'numero');
        company.neighborhood = text(establishment, 'bairro');
        company.city = text(city, 'nome');
        company.state = text(state, 'sigla');
        company.zipCode = text(establishment, 'cep');
        return company;
    }

    private static Map<String, Object> parseBody(String body) {
        try {
            Object parsed = JSON.deserializeUntyped(body);
            if (parsed instanceof Map<String, Object>) {
                return (Map<String, Object>) parsed;
            }
        } catch (JSONException e) {
            // cai na exceção abaixo
        }
        throw new ExternalApiException(SERVICE + ': resposta inválida.');
    }

    private static Map<String, Object> child(Map<String, Object> parent, String key) {
        Object value = parent.get(key);
        return (value instanceof Map<String, Object>) ? (Map<String, Object>) value : new Map<String, Object>();
    }

    private static String text(Map<String, Object> body, String key) {
        Object value = body.get(key);
        return (value == null) ? null : String.valueOf(value);
    }
}

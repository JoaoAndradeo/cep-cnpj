/** Client HTTP da BrasilAPI (CNPJ), via Named Credential BrasilAPI. */
public with sharing class BrasilApiClient implements ICnpjClient {

    private static final String SERVICE = 'BrasilAPI';

    private final ExternalHttpClient http;

    public BrasilApiClient() {
        this(new ExternalHttpClient());
    }

    public BrasilApiClient(ExternalHttpClient http) {
        this.http = http;
    }

    public CompanyInfo findByCnpj(String cnpj) {
        CpfCnpjValidator.Result check = CpfCnpjValidator.validate(cnpj);
        if (!check.isValid || check.documentType != CpfCnpjValidator.TYPE_CNPJ) {
            throw new InvalidInputException('CNPJ inválido.');
        }
        String digits = check.normalizedNumber;

        HttpResponse response = http.get('callout:BrasilAPI/cnpj/v1/' + digits, SERVICE);
        if (response.getStatusCode() == 404) {
            return null;
        }

        Map<String, Object> body = parseBody(response.getBody());
        CompanyInfo company = new CompanyInfo();
        company.cnpj = digits;
        company.legalName = text(body, 'razao_social');
        company.tradeName = text(body, 'nome_fantasia');
        company.registrationStatus = text(body, 'descricao_situacao_cadastral');
        company.street = text(body, 'logradouro');
        company.streetNumber = text(body, 'numero');
        company.neighborhood = text(body, 'bairro');
        company.city = text(body, 'municipio');
        company.state = text(body, 'uf');
        company.zipCode = text(body, 'cep');
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

    private static String text(Map<String, Object> body, String key) {
        Object value = body.get(key);
        return (value == null) ? null : String.valueOf(value);
    }
}

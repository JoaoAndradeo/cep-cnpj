/**
 * Consulta CNPJ no CNPJ.ws pela Named Credential CnpjWs.
 * A API pública aceita 3 consultas por minuto por IP; acima disso responde 429.
 */
public with sharing class CnpjWsClient implements ICnpjClient {

    public CompanyInfo findByCnpj(String cnpj) {
        CpfCnpjValidator.Result check = CpfCnpjValidator.validate(cnpj);
        if (!check.isValid || check.documentType != CpfCnpjValidator.TYPE_CNPJ) {
            throw new InvalidInputException('CNPJ inválido.');
        }
        String digits = check.normalizedNumber;

        HttpRequest request = new HttpRequest();
        request.setEndpoint('callout:CnpjWs/cnpj/' + digits);
        request.setMethod('GET');
        request.setTimeout(10000);

        HttpResponse response = send(request);
        if (response.getStatusCode() == 404) {
            return null;
        }

        Map<String, Object> body = parse(response.getBody());
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

    private static HttpResponse send(HttpRequest request) {
        try {
            HttpResponse response = new Http().send(request);
            Integer status = response.getStatusCode();
            if (status == 404 || (status >= 200 && status < 300)) {
                return response;
            }
            throw new ExternalApiException('CNPJ.ws: HTTP ' + status);
        } catch (CalloutException e) {
            throw new ExternalApiException('CNPJ.ws: falha de comunicação.');
        }
    }

    private static Map<String, Object> parse(String responseBody) {
        try {
            Object parsed = JSON.deserializeUntyped(responseBody);
            if (parsed instanceof Map<String, Object>) {
                return (Map<String, Object>) parsed;
            }
        } catch (JSONException e) {
            // tratado abaixo
        }
        throw new ExternalApiException('CNPJ.ws: resposta inválida.');
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

/** Consulta CEP no ViaCEP pela Named Credential ViaCEP. */
public with sharing class ViaCepClient implements ICepClient {

    public AddressInfo findByCep(String cep) {
        String digits = (cep == null) ? '' : cep.replaceAll('\\D', '');
        if (digits.length() != 8) {
            throw new InvalidInputException('CEP deve ter 8 dígitos.');
        }

        HttpRequest request = new HttpRequest();
        request.setEndpoint('callout:ViaCEP/' + digits + '/json/');
        request.setMethod('GET');
        request.setTimeout(10000);

        HttpResponse response = send(request);
        if (response.getStatusCode() == 404) {
            return null;
        }

        Map<String, Object> body = parse(response.getBody());
        // Com CEP inexistente, o ViaCEP responde 200 e {"erro": true}.
        if ('true'.equalsIgnoreCase(String.valueOf(body.get('erro')))) {
            return null;
        }

        AddressInfo address = new AddressInfo();
        address.cep = digits;
        address.street = text(body, 'logradouro');
        address.complement = text(body, 'complemento');
        address.neighborhood = text(body, 'bairro');
        address.city = text(body, 'localidade');
        address.state = text(body, 'uf');
        return address;
    }

    private static HttpResponse send(HttpRequest request) {
        try {
            HttpResponse response = new Http().send(request);
            Integer status = response.getStatusCode();
            if (status == 404 || (status >= 200 && status < 300)) {
                return response;
            }
            throw new ExternalApiException('ViaCEP: HTTP ' + status);
        } catch (CalloutException e) {
            throw new ExternalApiException('ViaCEP: falha de comunicação.');
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
        throw new ExternalApiException('ViaCEP: resposta inválida.');
    }

    private static String text(Map<String, Object> body, String key) {
        Object value = body.get(key);
        return (value == null) ? null : String.valueOf(value);
    }
}

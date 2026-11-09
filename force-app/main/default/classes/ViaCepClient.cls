/** Client HTTP do ViaCEP, via Named Credential ViaCEP. */
public with sharing class ViaCepClient implements ICepClient {

    private static final String SERVICE = 'ViaCEP';

    private final ExternalHttpClient http;

    public ViaCepClient() {
        this(new ExternalHttpClient());
    }

    public ViaCepClient(ExternalHttpClient http) {
        this.http = http;
    }

    public AddressInfo findByCep(String cep) {
        String digits = (cep == null) ? '' : cep.replaceAll('\\D', '');
        if (digits.length() != 8) {
            throw new InvalidInputException('CEP deve ter 8 dígitos.');
        }

        HttpResponse response = http.get('callout:ViaCEP/' + digits + '/json/', SERVICE);
        if (response.getStatusCode() == 404) {
            return null;
        }

        Map<String, Object> body = parseBody(response.getBody());
        // ViaCEP responde 200 com {"erro": true} quando o CEP não existe.
        if (isTrue(body.get('erro'))) {
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

    private static Boolean isTrue(Object value) {
        return 'true'.equalsIgnoreCase(String.valueOf(value));
    }

    private static String text(Map<String, Object> body, String key) {
        Object value = body.get(key);
        return (value == null) ? null : String.valueOf(value);
    }
}

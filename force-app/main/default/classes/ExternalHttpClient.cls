/**
 * Envio HTTP compartilhado pelos clients das APIs externas.
 * Trata timeout, falha de comunicação e status de erro de forma única.
 * 404 não é erro aqui: cada client decide o que ele significa.
 */
public with sharing class ExternalHttpClient {

    public static final Integer TIMEOUT_MS = 10000;

    public HttpResponse get(String endpoint, String serviceName) {
        HttpRequest request = new HttpRequest();
        request.setEndpoint(endpoint);
        request.setMethod('GET');
        request.setTimeout(TIMEOUT_MS);
        request.setHeader('Accept', 'application/json');

        HttpResponse response;
        try {
            response = new Http().send(request);
        } catch (CalloutException e) {
            throw new ExternalApiException(serviceName + ': falha de comunicação.');
        }

        Integer status = response.getStatusCode();
        if (status == 404 || (status >= 200 && status < 300)) {
            return response;
        }
        throw new ExternalApiException(serviceName + ': resposta HTTP ' + status + '.');
    }
}

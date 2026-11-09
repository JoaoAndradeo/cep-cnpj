/** Mock de callout reutilizável nos testes. Guarda o último endpoint chamado para asserts. */
@IsTest
public class HttpMockFactory implements HttpCalloutMock {

    private final Integer statusCode;
    private final String body;

    public String lastEndpoint;

    public HttpMockFactory(Integer statusCode, String body) {
        this.statusCode = statusCode;
        this.body = body;
    }

    public HttpResponse respond(HttpRequest request) {
        lastEndpoint = request.getEndpoint();
        HttpResponse response = new HttpResponse();
        response.setStatusCode(statusCode);
        response.setHeader('Content-Type', 'application/json');
        response.setBody(body);
        return response;
    }
}

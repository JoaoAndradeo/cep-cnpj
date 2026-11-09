@IsTest
private class ViaCepClientTest {

    private static final String FOUND_BODY =
        '{"cep":"01001-000","logradouro":"Praça da Sé","complemento":"lado ímpar",' +
        '"bairro":"Sé","localidade":"São Paulo","uf":"SP","ibge":"3550308"}';

    @IsTest
    static void returnsAddressWhenCepExists() {
        HttpMockFactory mock = new HttpMockFactory(200, FOUND_BODY);
        Test.setMock(HttpCalloutMock.class, mock);

        Test.startTest();
        AddressInfo address = new ViaCepClient().findByCep('01001-000');
        Test.stopTest();

        System.assertEquals('callout:ViaCEP/01001000/json/', mock.lastEndpoint, 'CEP deve ser enviado só com dígitos');
        System.assertEquals('01001000', address.cep);
        System.assertEquals('Praça da Sé', address.street);
        System.assertEquals('Sé', address.neighborhood);
        System.assertEquals('São Paulo', address.city);
        System.assertEquals('SP', address.state);
    }

    @IsTest
    static void returnsNullWhenViaCepSaysNotFound() {
        Test.setMock(HttpCalloutMock.class, new HttpMockFactory(200, '{"erro": true}'));

        AddressInfo address = new ViaCepClient().findByCep('00000000');

        System.assertEquals(null, address, 'CEP inexistente não é erro: deve voltar null');
    }

    @IsTest
    static void returnsNullOn404() {
        Test.setMock(HttpCalloutMock.class, new HttpMockFactory(404, ''));

        System.assertEquals(null, new ViaCepClient().findByCep('01001000'));
    }

    @IsTest
    static void throwsExternalApiExceptionOnServerError() {
        Test.setMock(HttpCalloutMock.class, new HttpMockFactory(503, 'indisponível'));

        Boolean thrown = false;
        try {
            new ViaCepClient().findByCep('01001000');
        } catch (ExternalApiException e) {
            thrown = e.getMessage().contains('503');
        }
        System.assert(thrown, 'HTTP 503 deve virar ExternalApiException com o status');
    }

    @IsTest
    static void throwsExternalApiExceptionOnInvalidJson() {
        Test.setMock(HttpCalloutMock.class, new HttpMockFactory(200, 'isto não é json'));

        Boolean thrown = false;
        try {
            new ViaCepClient().findByCep('01001000');
        } catch (ExternalApiException e) {
            thrown = true;
        }
        System.assert(thrown, 'Resposta que não é JSON deve virar ExternalApiException');
    }

    @IsTest
    static void rejectsCepWithWrongLength() {
        Boolean thrown = false;
        try {
            new ViaCepClient().findByCep('123');
        } catch (InvalidInputException e) {
            thrown = true;
        }
        System.assert(thrown, 'CEP com menos de 8 dígitos deve ser rejeitado antes do callout');
    }
}

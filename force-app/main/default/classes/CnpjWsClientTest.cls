@IsTest
private class CnpjWsClientTest {

    // CNPJ fictício com dígitos verificadores válidos.
    private static final String VALID_CNPJ = '11.222.333/0001-81';

    private static final String FOUND_BODY =
        '{"cnpj_raiz":"11222333","razao_social":"EMPRESA EXEMPLO LTDA",' +
        '"estabelecimento":{"cnpj":"11222333000181","nome_fantasia":"Exemplo",' +
        '"situacao_cadastral":"Ativa","logradouro":"RUA DAS FLORES","numero":"100",' +
        '"bairro":"CENTRO","cep":"01001000",' +
        '"cidade":{"nome":"Sao Paulo"},"estado":{"sigla":"SP"}}}';

    @IsTest
    static void returnsCompanyWhenCnpjExists() {
        HttpMockFactory mock = new HttpMockFactory(200, FOUND_BODY);
        Test.setMock(HttpCalloutMock.class, mock);

        Test.startTest();
        CompanyInfo company = new CnpjWsClient().findByCnpj(VALID_CNPJ);
        Test.stopTest();

        System.assertEquals('callout:CnpjWs/cnpj/11222333000181', mock.lastEndpoint, 'CNPJ deve ser enviado só com dígitos');
        System.assertEquals('11222333000181', company.cnpj);
        System.assertEquals('EMPRESA EXEMPLO LTDA', company.legalName);
        System.assertEquals('Exemplo', company.tradeName);
        System.assertEquals('Ativa', company.registrationStatus);
        System.assertEquals('RUA DAS FLORES', company.street);
        System.assertEquals('100', company.streetNumber);
        System.assertEquals('CENTRO', company.neighborhood);
        System.assertEquals('Sao Paulo', company.city);
        System.assertEquals('SP', company.state);
        System.assertEquals('01001000', company.zipCode);
    }

    @IsTest
    static void returnsNullOn404() {
        Test.setMock(HttpCalloutMock.class, new HttpMockFactory(404, '{"status":404}'));

        System.assertEquals(null, new CnpjWsClient().findByCnpj(VALID_CNPJ));
    }

    @IsTest
    static void throwsExternalApiExceptionOnRateLimit() {
        Test.setMock(HttpCalloutMock.class, new HttpMockFactory(429, 'limite excedido'));

        Boolean thrown = false;
        try {
            new CnpjWsClient().findByCnpj(VALID_CNPJ);
        } catch (ExternalApiException e) {
            thrown = e.getMessage().contains('429');
        }
        System.assert(thrown, 'HTTP 429 (limite de 3 por minuto) deve virar ExternalApiException com o status');
    }

    @IsTest
    static void missingEstablishmentReturnsNullFields() {
        Test.setMock(HttpCalloutMock.class, new HttpMockFactory(200, '{"razao_social":"SEM ESTABELECIMENTO"}'));

        CompanyInfo company = new CnpjWsClient().findByCnpj(VALID_CNPJ);

        System.assertEquals('SEM ESTABELECIMENTO', company.legalName);
        System.assertEquals(null, company.registrationStatus, 'Campos ausentes devem ficar nulos, sem erro');
    }

    @IsTest
    static void rejectsCnpjWithInvalidCheckDigits() {
        Boolean thrown = false;
        try {
            new CnpjWsClient().findByCnpj('11222333000182');
        } catch (InvalidInputException e) {
            thrown = true;
        }
        System.assert(thrown, 'CNPJ com dígitos verificadores errados deve ser rejeitado antes do callout');
    }
}

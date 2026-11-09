@IsTest
private class BrasilApiClientTest {

    // CNPJ fictício com dígitos verificadores válidos.
    private static final String VALID_CNPJ = '11.222.333/0001-81';

    private static final String FOUND_BODY =
        '{"cnpj":"11222333000181","razao_social":"EMPRESA EXEMPLO LTDA",' +
        '"nome_fantasia":"Exemplo","descricao_situacao_cadastral":"ATIVA",' +
        '"logradouro":"RUA DAS FLORES","numero":"100","bairro":"CENTRO",' +
        '"municipio":"SAO PAULO","uf":"SP","cep":"01001000"}';

    @IsTest
    static void returnsCompanyWhenCnpjExists() {
        HttpMockFactory mock = new HttpMockFactory(200, FOUND_BODY);
        Test.setMock(HttpCalloutMock.class, mock);

        Test.startTest();
        CompanyInfo company = new BrasilApiClient().findByCnpj(VALID_CNPJ);
        Test.stopTest();

        System.assertEquals('callout:BrasilAPI/cnpj/v1/11222333000181', mock.lastEndpoint, 'CNPJ deve ser enviado só com dígitos');
        System.assertEquals('11222333000181', company.cnpj);
        System.assertEquals('EMPRESA EXEMPLO LTDA', company.legalName);
        System.assertEquals('Exemplo', company.tradeName);
        System.assertEquals('ATIVA', company.registrationStatus);
        System.assertEquals('SAO PAULO', company.city);
        System.assertEquals('SP', company.state);
        System.assertEquals('01001000', company.zipCode);
    }

    @IsTest
    static void returnsNullOn404() {
        Test.setMock(HttpCalloutMock.class, new HttpMockFactory(404, '{"message":"CNPJ não encontrado"}'));

        System.assertEquals(null, new BrasilApiClient().findByCnpj(VALID_CNPJ));
    }

    @IsTest
    static void throwsExternalApiExceptionOnServerError() {
        Test.setMock(HttpCalloutMock.class, new HttpMockFactory(500, 'erro interno'));

        Boolean thrown = false;
        try {
            new BrasilApiClient().findByCnpj(VALID_CNPJ);
        } catch (ExternalApiException e) {
            thrown = e.getMessage().contains('500');
        }
        System.assert(thrown, 'HTTP 500 deve virar ExternalApiException com o status');
    }

    @IsTest
    static void rejectsCnpjWithInvalidCheckDigits() {
        Boolean thrown = false;
        try {
            new BrasilApiClient().findByCnpj('11222333000182');
        } catch (InvalidInputException e) {
            thrown = true;
        }
        System.assert(thrown, 'CNPJ com dígitos verificadores errados deve ser rejeitado antes do callout');
    }

    @IsTest
    static void rejectsCnpjWithWrongLength() {
        Boolean thrown = false;
        try {
            new BrasilApiClient().findByCnpj('123');
        } catch (InvalidInputException e) {
            thrown = true;
        }
        System.assert(thrown, 'CNPJ com tamanho errado deve ser rejeitado');
    }
}

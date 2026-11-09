@IsTest
private class BuscaDadosServiceTest {

    @IsTest
    static void buscarCepDelegatesDigitsOnly() {
        TestStubs.CepStub cep = new TestStubs.CepStub();
        AddressInfo expected = new AddressInfo();
        expected.street = 'Praça da Sé';
        cep.result = expected;

        BuscaDadosService service = new BuscaDadosService(cep, new TestStubs.CnpjStub());
        AddressInfo address = service.buscarCep('01001-000');

        System.assertEquals('01001000', cep.lastCep, 'Service deve passar só os dígitos ao client');
        System.assertEquals('Praça da Sé', address.street);
    }

    @IsTest
    static void buscarCepRejectsInvalidInputWithoutCallingClient() {
        TestStubs.CepStub cep = new TestStubs.CepStub();
        BuscaDadosService service = new BuscaDadosService(cep, new TestStubs.CnpjStub());

        Boolean thrown = false;
        try {
            service.buscarCep('123');
        } catch (InvalidInputException e) {
            thrown = true;
        }
        System.assert(thrown, 'CEP inválido deve ser rejeitado');
        System.assertEquals(0, cep.calls, 'Entrada inválida não pode gerar callout');
    }

    @IsTest
    static void buscarCepReturnsNullWhenNotFound() {
        TestStubs.CepStub cep = new TestStubs.CepStub();
        cep.result = null;
        BuscaDadosService service = new BuscaDadosService(cep, new TestStubs.CnpjStub());

        System.assertEquals(null, service.buscarCep('00000000'), 'CEP inexistente volta null');
    }

    @IsTest
    static void buscarCepPropagatesExternalError() {
        TestStubs.CepStub cep = new TestStubs.CepStub();
        cep.toThrow = new ExternalApiException('falha simulada');
        BuscaDadosService service = new BuscaDadosService(cep, new TestStubs.CnpjStub());

        Boolean thrown = false;
        try {
            service.buscarCep('01001000');
        } catch (ExternalApiException e) {
            thrown = true;
        }
        System.assert(thrown, 'Erro de infraestrutura deve chegar ao Controller para ser traduzido');
    }

    @IsTest
    static void buscarCnpjDelegatesNormalizedDocument() {
        TestStubs.CnpjStub cnpj = new TestStubs.CnpjStub();
        CompanyInfo expected = new CompanyInfo();
        expected.legalName = 'EMPRESA EXEMPLO LTDA';
        cnpj.result = expected;

        BuscaDadosService service = new BuscaDadosService(new TestStubs.CepStub(), cnpj);
        CompanyInfo company = service.buscarCnpj('11.222.333/0001-81');

        System.assertEquals('11222333000181', cnpj.lastCnpj);
        System.assertEquals('EMPRESA EXEMPLO LTDA', company.legalName);
    }

    @IsTest
    static void buscarCnpjRejectsInvalidDocumentWithoutCallingClient() {
        TestStubs.CnpjStub cnpj = new TestStubs.CnpjStub();
        BuscaDadosService service = new BuscaDadosService(new TestStubs.CepStub(), cnpj);

        Boolean thrown = false;
        try {
            service.buscarCnpj('11222333000182');
        } catch (InvalidInputException e) {
            thrown = true;
        }
        System.assert(thrown, 'CNPJ com dígito verificador errado deve ser rejeitado');
        System.assertEquals(0, cnpj.calls);
    }

    @IsTest
    static void buscarCnpjRejectsCpf() {
        TestStubs.CnpjStub cnpj = new TestStubs.CnpjStub();
        BuscaDadosService service = new BuscaDadosService(new TestStubs.CepStub(), cnpj);

        Boolean thrown = false;
        try {
            service.buscarCnpj('529.982.247-25');
        } catch (InvalidInputException e) {
            thrown = true;
        }
        System.assert(thrown, 'CPF não é aceito na busca de CNPJ');
        System.assertEquals(0, cnpj.calls);
    }
}

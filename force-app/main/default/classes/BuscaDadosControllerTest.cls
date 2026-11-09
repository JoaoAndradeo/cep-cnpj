@IsTest
private class BuscaDadosControllerTest {

    /** Cada teste começa com cache vazio, para um resultado não vazar para outro. */
    private static void isolateCache() {
        BuscaDadosController.cacheStore = new TestStubs.MemoryCacheStore();
    }

    @IsTest
    static void buscarCepReturnsAddress() {
        isolateCache();
        TestStubs.CepStub cep = new TestStubs.CepStub();
        AddressInfo expected = new AddressInfo();
        expected.city = 'São Paulo';
        cep.result = expected;
        BuscaDadosController.cepClient = cep;

        AddressInfo address = BuscaDadosController.buscarCep('01001000');

        System.assertEquals('São Paulo', address.city);
    }

    @IsTest
    static void buscarCepReturnsNullWhenNotFound() {
        isolateCache();
        BuscaDadosController.cepClient = new TestStubs.CepStub();

        System.assertEquals(null, BuscaDadosController.buscarCep('00000000'));
    }

    @IsTest
    static void buscarCepInvalidInputBecomesAuraException() {
        isolateCache();
        BuscaDadosController.cepClient = new TestStubs.CepStub();

        Boolean thrown = false;
        try {
            BuscaDadosController.buscarCep('12');
        } catch (AuraHandledException e) {
            thrown = true;
        }
        System.assert(thrown, 'Entrada inválida deve virar AuraHandledException para a tela');
    }

    @IsTest
    static void buscarCepExternalErrorBecomesAuraException() {
        isolateCache();
        TestStubs.CepStub cep = new TestStubs.CepStub();
        cep.toThrow = new ExternalApiException('detalhe técnico que não pode vazar');
        BuscaDadosController.cepClient = cep;

        Boolean thrown = false;
        try {
            BuscaDadosController.buscarCep('01001000');
        } catch (AuraHandledException e) {
            thrown = true;
        }
        System.assert(thrown, 'Falha de API deve virar AuraHandledException genérica');
    }

    @IsTest
    static void buscarCepUnexpectedErrorBecomesAuraException() {
        isolateCache();
        TestStubs.CepStub cep = new TestStubs.CepStub();
        cep.toThrow = new TypeException('falha inesperada');
        BuscaDadosController.cepClient = cep;

        Boolean thrown = false;
        try {
            BuscaDadosController.buscarCep('01001000');
        } catch (AuraHandledException e) {
            thrown = true;
        }
        System.assert(thrown, 'Erro inesperado também deve ser traduzido, sem vazar detalhe');
    }

    @IsTest
    static void buscarCnpjReturnsCompany() {
        isolateCache();
        TestStubs.CnpjStub cnpj = new TestStubs.CnpjStub();
        CompanyInfo expected = new CompanyInfo();
        expected.registrationStatus = 'Ativa';
        cnpj.result = expected;
        BuscaDadosController.cnpjClient = cnpj;

        CompanyInfo company = BuscaDadosController.buscarCnpj('11.222.333/0001-81');

        System.assertEquals('Ativa', company.registrationStatus);
    }

    @IsTest
    static void buscarCnpjInvalidInputBecomesAuraException() {
        isolateCache();
        BuscaDadosController.cnpjClient = new TestStubs.CnpjStub();

        Boolean thrown = false;
        try {
            BuscaDadosController.buscarCnpj('11222333000182');
        } catch (AuraHandledException e) {
            thrown = true;
        }
        System.assert(thrown, 'CNPJ inválido deve virar AuraHandledException');
    }

    @IsTest
    static void buscarCnpjExternalErrorBecomesAuraException() {
        isolateCache();
        TestStubs.CnpjStub cnpj = new TestStubs.CnpjStub();
        cnpj.toThrow = new ExternalApiException('HTTP 429');
        BuscaDadosController.cnpjClient = cnpj;

        Boolean thrown = false;
        try {
            BuscaDadosController.buscarCnpj('11.222.333/0001-81');
        } catch (AuraHandledException e) {
            thrown = true;
        }
        System.assert(thrown, 'Limite ou falha do CNPJ.ws deve virar AuraHandledException');
    }
}

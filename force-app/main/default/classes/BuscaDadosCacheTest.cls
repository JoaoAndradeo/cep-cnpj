@IsTest
private class BuscaDadosCacheTest {

    @IsTest
    static void secondCepLookupUsesCache() {
        TestStubs.CepStub cep = new TestStubs.CepStub();
        cep.result = new AddressInfo();
        cep.result.city = 'São Paulo';
        TestStubs.MemoryCacheStore cache = new TestStubs.MemoryCacheStore();
        BuscaDadosService service = new BuscaDadosService(cep, new TestStubs.CnpjStub(), cache);

        AddressInfo first = service.buscarCep('01001-000');
        AddressInfo second = service.buscarCep('01001000');

        System.assertEquals(1, cep.calls, 'Segunda busca do mesmo CEP deve vir do cache');
        System.assertEquals('São Paulo', second.city);
        System.assertEquals(first.city, second.city);
        System.assertEquals(BuscaDadosService.CEP_TTL_SECONDS, cache.ttls.get('cep01001000'));
    }

    @IsTest
    static void notFoundCepIsNotCached() {
        TestStubs.CepStub cep = new TestStubs.CepStub();
        cep.result = null;
        TestStubs.MemoryCacheStore cache = new TestStubs.MemoryCacheStore();
        BuscaDadosService service = new BuscaDadosService(cep, new TestStubs.CnpjStub(), cache);

        service.buscarCep('00000000');
        service.buscarCep('00000000');

        System.assertEquals(2, cep.calls, 'CEP inexistente não pode ficar cacheado');
        System.assert(!cache.values.containsKey('cep00000000'));
    }

    @IsTest
    static void cnpjCacheKeyIsNormalizedAndUsesShortTtl() {
        TestStubs.CnpjStub cnpj = new TestStubs.CnpjStub();
        cnpj.result = new CompanyInfo();
        cnpj.result.legalName = 'EMPRESA EXEMPLO LTDA';
        TestStubs.MemoryCacheStore cache = new TestStubs.MemoryCacheStore();
        BuscaDadosService service = new BuscaDadosService(new TestStubs.CepStub(), cnpj, cache);

        service.buscarCnpj('11.222.333/0001-81');
        CompanyInfo again = service.buscarCnpj('11222333000181');

        System.assertEquals(1, cnpj.calls, 'CNPJ com e sem máscara deve usar a mesma chave de cache');
        System.assertEquals('EMPRESA EXEMPLO LTDA', again.legalName);
        System.assert(cache.values.containsKey('cnpj11222333000181'));
        System.assertEquals(BuscaDadosService.CNPJ_TTL_SECONDS, cache.ttls.get('cnpj11222333000181'));
    }

    @IsTest
    static void cacheFailureFallsBackToApi() {
        TestStubs.CepStub cep = new TestStubs.CepStub();
        cep.result = new AddressInfo();
        cep.result.city = 'Rio de Janeiro';
        BuscaDadosService service = new BuscaDadosService(cep, new TestStubs.CnpjStub(), new TestStubs.BrokenCacheStore());

        AddressInfo address = service.buscarCep('20031170');

        System.assertEquals('Rio de Janeiro', address.city, 'Cache indisponível não pode quebrar a busca');
        System.assertEquals(1, cep.calls);
    }
}

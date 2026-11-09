/** Stubs de clients e de cache para os testes. Não fazem callout nem usam a org. */
@IsTest
public class TestStubs {

    public class CepStub implements ICepClient {
        public Integer calls = 0;
        public String lastCep;
        public AddressInfo result;
        public Exception toThrow;

        public AddressInfo findByCep(String cep) {
            calls++;
            lastCep = cep;
            if (toThrow != null) {
                throw toThrow;
            }
            return result;
        }
    }

    public class CnpjStub implements ICnpjClient {
        public Integer calls = 0;
        public String lastCnpj;
        public CompanyInfo result;
        public Exception toThrow;

        public CompanyInfo findByCnpj(String cnpj) {
            calls++;
            lastCnpj = cnpj;
            if (toThrow != null) {
                throw toThrow;
            }
            return result;
        }
    }

    /** Cache em memória, com registro dos TTLs pedidos. */
    public class MemoryCacheStore implements ICacheStore {
        public Map<String, String> values = new Map<String, String>();
        public Map<String, Integer> ttls = new Map<String, Integer>();

        public String get(String key) {
            return values.get(key);
        }

        public void put(String key, String payload, Integer ttlSeconds) {
            values.put(key, payload);
            ttls.put(key, ttlSeconds);
        }
    }

    /** Cache que sempre falha: a busca deve continuar pela API. */
    public class BrokenCacheStore implements ICacheStore {
        public String get(String key) {
            throw new CalloutException('cache indisponível');
        }

        public void put(String key, String payload, Integer ttlSeconds) {
            throw new CalloutException('cache indisponível');
        }
    }
}

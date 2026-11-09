/** Stubs de clients para os testes de Service e Controller. Não fazem callout. */
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
}

/**
 * Regra de negócio da busca de CEP e CNPJ.
 * Valida a entrada antes de qualquer callout, consulta o cache e delega ao client só quando precisa.
 * Não sabe nada de tela: quem traduz erros para o usuário é o Controller.
 */
public with sharing class BuscaDadosService {

    // CEP muda pouco: 1 dia. CNPJ pode mudar de situação: 1 hora.
    public static final Integer CEP_TTL_SECONDS = 86400;
    public static final Integer CNPJ_TTL_SECONDS = 3600;

    private final ICepClient cepClient;
    private final ICnpjClient cnpjClient;
    private final ICacheStore cache;

    /** Sem cache: usado quando o chamador não precisa dele. */
    public BuscaDadosService(ICepClient cepClient, ICnpjClient cnpjClient) {
        this(cepClient, cnpjClient, null);
    }

    public BuscaDadosService(ICepClient cepClient, ICnpjClient cnpjClient, ICacheStore cache) {
        this.cepClient = cepClient;
        this.cnpjClient = cnpjClient;
        this.cache = cache;
    }

    /** Retorna null quando o CEP não existe. Resultados nulos não são cacheados. */
    public AddressInfo buscarCep(String cep) {
        String digits = (cep == null) ? '' : cep.replaceAll('\\D', '');
        if (digits.length() != 8) {
            throw new InvalidInputException('CEP deve ter 8 dígitos.');
        }
        String key = 'cep' + digits;
        String cached = readCache(key);
        if (cached != null) {
            return (AddressInfo) JSON.deserialize(cached, AddressInfo.class);
        }

        AddressInfo address = cepClient.findByCep(digits);
        if (address != null) {
            writeCache(key, JSON.serialize(address), CEP_TTL_SECONDS);
        }
        return address;
    }

    /** Retorna null quando o CNPJ não existe. Resultados nulos não são cacheados. */
    public CompanyInfo buscarCnpj(String cnpj) {
        CpfCnpjValidator.Result check = CpfCnpjValidator.validate(cnpj);
        if (!check.isValid || check.documentType != CpfCnpjValidator.TYPE_CNPJ) {
            throw new InvalidInputException('CNPJ inválido.');
        }
        String digits = check.normalizedNumber;
        String key = 'cnpj' + digits;
        String cached = readCache(key);
        if (cached != null) {
            return (CompanyInfo) JSON.deserialize(cached, CompanyInfo.class);
        }

        CompanyInfo company = cnpjClient.findByCnpj(digits);
        if (company != null) {
            writeCache(key, JSON.serialize(company), CNPJ_TTL_SECONDS);
        }
        return company;
    }

    /** Falha no cache não pode impedir a busca: nesse caso, segue para a API. */
    private String readCache(String key) {
        if (cache == null) {
            return null;
        }
        try {
            return cache.get(key);
        } catch (Exception e) {
            BuscaErrorReporter.report('cache.get ' + key, e);
            return null;
        }
    }

    private void writeCache(String key, String payload, Integer ttlSeconds) {
        if (cache == null) {
            return;
        }
        try {
            cache.put(key, payload, ttlSeconds);
        } catch (Exception e) {
            BuscaErrorReporter.report('cache.put ' + key, e);
        }
    }
}

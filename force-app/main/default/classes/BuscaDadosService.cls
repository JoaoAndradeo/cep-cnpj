/**
 * Busca de CEP e CNPJ com cache.
 * Valida a entrada antes de qualquer chamada externa e só consulta a API quando o cache não tem o valor.
 */
public with sharing class BuscaDadosService {

    public static final Integer CEP_TTL_SECONDS = 86400;   // 1 dia
    public static final Integer CNPJ_TTL_SECONDS = 3600;   // 1 hora

    private final ICepClient cepClient;
    private final ICnpjClient cnpjClient;
    private final ICacheStore cache;

    public BuscaDadosService(ICepClient cepClient, ICnpjClient cnpjClient) {
        this(cepClient, cnpjClient, null);
    }

    public BuscaDadosService(ICepClient cepClient, ICnpjClient cnpjClient, ICacheStore cache) {
        this.cepClient = cepClient;
        this.cnpjClient = cnpjClient;
        this.cache = cache;
    }

    /** Devolve null se o CEP não existir. Resultado vazio não vai para o cache. */
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

    /** Devolve null se o CNPJ não existir. Resultado vazio não vai para o cache. */
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

    // Se o cache falhar, a busca continua pela API.
    private String readCache(String key) {
        if (cache == null) {
            return null;
        }
        try {
            return cache.get(key);
        } catch (Exception e) {
            System.debug(LoggingLevel.WARN, '[Busca] Falha ao ler o cache: ' + e.getMessage());
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
            System.debug(LoggingLevel.WARN, '[Busca] Falha ao gravar o cache: ' + e.getMessage());
        }
    }
}

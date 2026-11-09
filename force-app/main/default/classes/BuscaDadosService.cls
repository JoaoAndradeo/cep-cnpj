/**
 * Regra de negócio da busca de CEP e CNPJ.
 * Valida a entrada antes de qualquer callout e delega a consulta ao client correspondente.
 * Não sabe nada de tela: quem traduz erros para o usuário é o Controller.
 */
public with sharing class BuscaDadosService {

    private final ICepClient cepClient;
    private final ICnpjClient cnpjClient;

    public BuscaDadosService(ICepClient cepClient, ICnpjClient cnpjClient) {
        this.cepClient = cepClient;
        this.cnpjClient = cnpjClient;
    }

    /** Retorna null quando o CEP não existe. */
    public AddressInfo buscarCep(String cep) {
        String digits = (cep == null) ? '' : cep.replaceAll('\\D', '');
        if (digits.length() != 8) {
            throw new InvalidInputException('CEP deve ter 8 dígitos.');
        }
        return cepClient.findByCep(digits);
    }

    /** Retorna null quando o CNPJ não existe. */
    public CompanyInfo buscarCnpj(String cnpj) {
        CpfCnpjValidator.Result check = CpfCnpjValidator.validate(cnpj);
        if (!check.isValid || check.documentType != CpfCnpjValidator.TYPE_CNPJ) {
            throw new InvalidInputException('CNPJ inválido.');
        }
        return cnpjClient.findByCnpj(check.normalizedNumber);
    }
}

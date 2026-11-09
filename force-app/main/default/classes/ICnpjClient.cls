/** Contrato da busca de dados cadastrais por CNPJ. Retorna null quando o CNPJ não existe. */
public interface ICnpjClient {
    CompanyInfo findByCnpj(String cnpj);
}

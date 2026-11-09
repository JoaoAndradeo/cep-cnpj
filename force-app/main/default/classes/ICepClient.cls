/** Contrato da busca de endereço por CEP. Retorna null quando o CEP não existe. */
public interface ICepClient {
    AddressInfo findByCep(String cep);
}

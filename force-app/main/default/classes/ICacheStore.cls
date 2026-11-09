/** Contrato de cache de respostas das APIs. get devolve null quando não há valor válido. */
public interface ICacheStore {
    String get(String key);
    void put(String key, String payload, Integer ttlSeconds);
}

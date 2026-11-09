/**
 * Cache de respostas das APIs.
 * Primeira opção: Platform Cache (partição BuscaCache, de organização).
 * Fallback: objeto Busca_Cache__c, usado quando a partição não está disponível na org.
 * Consultas e gravações do fallback rodam em USER_MODE.
 */
public with sharing class BuscaCacheStore implements ICacheStore {

    public static final String PARTITION = 'local.BuscaCache';
    // Limites do Platform Cache para TTL de organização.
    public static final Integer MIN_TTL_SECONDS = 300;
    public static final Integer MAX_TTL_SECONDS = 172800;

    @TestVisible private static Boolean forceFallback = false;

    public String get(String key) {
        Cache.OrgPartition partition = partition();
        if (partition != null) {
            Object value = partition.get(key);
            return (value == null) ? null : String.valueOf(value);
        }
        return getFromObject(key);
    }

    public void put(String key, String payload, Integer ttlSeconds) {
        Integer ttl = Math.min(Math.max(ttlSeconds, MIN_TTL_SECONDS), MAX_TTL_SECONDS);
        Cache.OrgPartition partition = partition();
        if (partition != null) {
            partition.put(key, payload, ttl);
            return;
        }
        putInObject(key, payload, ttl);
    }

    private static Cache.OrgPartition partition() {
        if (forceFallback) {
            return null;
        }
        try {
            return Cache.Org.getPartition(PARTITION);
        } catch (Cache.Org.OrgCacheException e) {
            return null;
        }
    }

    private static String getFromObject(String key) {
        DateTime now = DateTime.now();
        List<Busca_Cache__c> rows = [
            SELECT Payload__c
            FROM Busca_Cache__c
            WHERE Key__c = :key
              AND Expires_At__c > :now
            WITH USER_MODE
            LIMIT 1
        ];
        return rows.isEmpty() ? null : rows[0].Payload__c;
    }

    private static void putInObject(String key, String payload, Integer ttl) {
        Busca_Cache__c row = new Busca_Cache__c(
            Key__c = key,
            Payload__c = payload,
            Expires_At__c = DateTime.now().addSeconds(ttl)
        );
        Database.upsert(new List<Busca_Cache__c>{ row }, Busca_Cache__c.Key__c, false, AccessLevel.USER_MODE);
    }
}

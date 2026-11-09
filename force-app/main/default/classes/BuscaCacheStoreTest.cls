@IsTest
private class BuscaCacheStoreTest {

    @IsTest
    static void platformCacheRoundTrip() {
        BuscaCacheStore.forceFallback = false;
        BuscaCacheStore store = new BuscaCacheStore();

        store.put('testplatform', 'valor-platform', 600);

        System.assertEquals('valor-platform', store.get('testplatform'));
    }

    @IsTest
    static void fallbackStoresInObjectWhenPlatformCacheIsDisabled() {
        BuscaCacheStore.forceFallback = true;
        BuscaCacheStore store = new BuscaCacheStore();

        store.put('testfallback', 'valor-objeto', 600);

        System.assertEquals('valor-objeto', store.get('testfallback'));
        Integer rows = [SELECT COUNT() FROM Busca_Cache__c WHERE Key__c = 'testfallback' WITH SYSTEM_MODE];
        System.assertEquals(1, rows, 'Fallback deve gravar uma linha no objeto Busca_Cache__c');
    }

    @IsTest
    static void fallbackIgnoresExpiredRows() {
        BuscaCacheStore.forceFallback = true;
        insert new Busca_Cache__c(
            Key__c = 'testexpired',
            Payload__c = 'vencido',
            Expires_At__c = DateTime.now().addMinutes(-5)
        );

        System.assertEquals(null, new BuscaCacheStore().get('testexpired'), 'Linha vencida não pode ser devolvida');
    }

    @IsTest
    static void fallbackUpdatesExistingKey() {
        BuscaCacheStore.forceFallback = true;
        BuscaCacheStore store = new BuscaCacheStore();

        store.put('testupdate', 'primeiro', 600);
        store.put('testupdate', 'segundo', 600);

        System.assertEquals('segundo', store.get('testupdate'));
        Integer rows = [SELECT COUNT() FROM Busca_Cache__c WHERE Key__c = 'testupdate' WITH SYSTEM_MODE];
        System.assertEquals(1, rows, 'Chave única: regravar deve atualizar, não duplicar');
    }
}

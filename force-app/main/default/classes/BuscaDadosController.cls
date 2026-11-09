/**
 * Controller do componente de busca. Devolve os dados ou uma mensagem segura para a tela.
 * O erro técnico vai para o debug log; a tela recebe só o texto genérico.
 */
public with sharing class BuscaDadosController {

    @TestVisible private static ICepClient cepClient = new ViaCepClient();
    @TestVisible private static ICnpjClient cnpjClient = new CnpjWsClient();
    @TestVisible private static ICacheStore cacheStore = new BuscaCacheStore();

    private static final String MSG_UNAVAILABLE = 'Serviço de consulta indisponível no momento. Tente novamente em instantes.';
    private static final String MSG_GENERIC = 'Não foi possível concluir a busca. Tente novamente.';

    @AuraEnabled
    public static AddressInfo buscarCep(String cep) {
        try {
            return service().buscarCep(cep);
        } catch (InvalidInputException e) {
            throw new AuraHandledException(e.getMessage());
        } catch (ExternalApiException e) {
            System.debug(LoggingLevel.ERROR, '[CEP] ' + e.getMessage());
            throw new AuraHandledException(MSG_UNAVAILABLE);
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, '[CEP] ' + e.getTypeName() + ': ' + e.getMessage());
            throw new AuraHandledException(MSG_GENERIC);
        }
    }

    @AuraEnabled
    public static CompanyInfo buscarCnpj(String cnpj) {
        try {
            return service().buscarCnpj(cnpj);
        } catch (InvalidInputException e) {
            throw new AuraHandledException(e.getMessage());
        } catch (ExternalApiException e) {
            System.debug(LoggingLevel.ERROR, '[CNPJ] ' + e.getMessage());
            throw new AuraHandledException(MSG_UNAVAILABLE);
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, '[CNPJ] ' + e.getTypeName() + ': ' + e.getMessage());
            throw new AuraHandledException(MSG_GENERIC);
        }
    }

    private static BuscaDadosService service() {
        return new BuscaDadosService(cepClient, cnpjClient, cacheStore);
    }
}

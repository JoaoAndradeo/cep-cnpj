/**
 * Ponto de entrada do LWC de busca. Traduz exceções em mensagens seguras para o usuário.
 * Detalhes técnicos vão para BuscaErrorReporter; a tela recebe só texto genérico.
 */
public with sharing class BuscaDadosController {

    @TestVisible private static ICepClient cepClient = new ViaCepClient();
    @TestVisible private static ICnpjClient cnpjClient = new BrasilApiClient();

    private static final String MSG_UNAVAILABLE = 'Serviço de consulta indisponível no momento. Tente novamente em instantes.';
    private static final String MSG_GENERIC = 'Não foi possível concluir a busca. Tente novamente.';

    @AuraEnabled
    public static AddressInfo buscarCep(String cep) {
        try {
            return service().buscarCep(cep);
        } catch (InvalidInputException e) {
            throw new AuraHandledException(e.getMessage());
        } catch (ExternalApiException e) {
            BuscaErrorReporter.report('buscarCep', e);
            throw new AuraHandledException(MSG_UNAVAILABLE);
        } catch (Exception e) {
            BuscaErrorReporter.report('buscarCep', e);
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
            BuscaErrorReporter.report('buscarCnpj', e);
            throw new AuraHandledException(MSG_UNAVAILABLE);
        } catch (Exception e) {
            BuscaErrorReporter.report('buscarCnpj', e);
            throw new AuraHandledException(MSG_GENERIC);
        }
    }

    private static BuscaDadosService service() {
        return new BuscaDadosService(cepClient, cnpjClient);
    }
}

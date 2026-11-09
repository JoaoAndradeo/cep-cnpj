/**
 * Registra o detalhe técnico de uma falha. O usuário nunca vê esse conteúdo.
 * Hoje grava no debug log. Ao integrar com o projeto logger-platform-events,
 * apenas este método passa a chamar Logger.error.
 */
public with sharing class BuscaErrorReporter {

    public static void report(String context, Exception e) {
        System.debug(LoggingLevel.ERROR, '[CEP/CNPJ] ' + context + ' | ' + e.getTypeName() + ': ' + e.getMessage());
    }
}

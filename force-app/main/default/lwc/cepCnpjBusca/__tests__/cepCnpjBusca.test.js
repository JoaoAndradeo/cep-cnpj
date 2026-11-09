import { createElement } from 'lwc';
import CepCnpjBusca from 'c/cepCnpjBusca';
import buscarCep from '@salesforce/apex/BuscaDadosController.buscarCep';
import buscarCnpj from '@salesforce/apex/BuscaDadosController.buscarCnpj';

jest.mock(
    '@salesforce/apex/BuscaDadosController.buscarCep',
    () => ({ default: jest.fn() }),
    { virtual: true }
);
jest.mock(
    '@salesforce/apex/BuscaDadosController.buscarCnpj',
    () => ({ default: jest.fn() }),
    { virtual: true }
);

const flushPromises = () => new Promise((resolve) => setTimeout(resolve, 0));

const ADDRESS = {
    cep: '01001000',
    street: 'Praça da Sé',
    complement: 'lado ímpar',
    neighborhood: 'Sé',
    city: 'São Paulo',
    state: 'SP'
};

const COMPANY = {
    cnpj: '33000167000101',
    legalName: 'PETROLEO BRASILEIRO S A PETROBRAS',
    tradeName: 'PETROBRAS - EDISE',
    registrationStatus: 'Ativa',
    street: 'REPUBLICA DO CHILE',
    streetNumber: '65',
    neighborhood: 'CENTRO',
    city: 'Rio de Janeiro',
    state: 'RJ',
    zipCode: '20031170'
};

function mount() {
    const element = createElement('c-cep-cnpj-busca', { is: CepCnpjBusca });
    document.body.appendChild(element);
    return element;
}

function typeInInput(element, value) {
    const input = element.shadowRoot.querySelector('lightning-input');
    input.value = value;
    input.dispatchEvent(new CustomEvent('change', { detail: { value }, bubbles: true }));
}

function clickSearch(element) {
    element.shadowRoot.querySelector('lightning-button').dispatchEvent(new CustomEvent('click'));
}

describe('c-cep-cnpj-busca', () => {
    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
        jest.clearAllMocks();
    });

    it('começa no modo CEP, com rótulo e máscara de CEP', () => {
        const element = mount();

        const input = element.shadowRoot.querySelector('lightning-input');
        expect(input.label).toBe('CEP');
        expect(input.placeholder).toBe('00000-000');
    });

    it('busca o CEP com dígitos e mostra o endereço', async () => {
        buscarCep.mockResolvedValue(ADDRESS);
        const element = mount();

        typeInInput(element, '01001-000');
        clickSearch(element);
        await flushPromises();

        expect(buscarCep).toHaveBeenCalledWith({ cep: '01001000' });
        expect(element.shadowRoot.textContent).toContain('Praça da Sé');
        expect(element.shadowRoot.textContent).toContain('São Paulo');
    });

    it('valida o formato no cliente e não chama o Apex com CEP incompleto', async () => {
        const element = mount();

        typeInInput(element, '0100');
        clickSearch(element);
        await flushPromises();

        expect(buscarCep).not.toHaveBeenCalled();
        const alert = element.shadowRoot.querySelector('[role="alert"]');
        expect(alert.textContent).toContain('CEP deve ter 8 dígitos.');
    });

    it('mostra mensagem de não encontrado quando a busca volta vazia', async () => {
        buscarCep.mockResolvedValue(null);
        const element = mount();

        typeInInput(element, '00000000');
        clickSearch(element);
        await flushPromises();

        expect(element.shadowRoot.textContent).toContain('Nenhum resultado encontrado para este CEP.');
    });

    it('mostra a mensagem de erro do servidor sem detalhe técnico', async () => {
        buscarCep.mockRejectedValue({ body: { message: 'Serviço de consulta indisponível no momento.' } });
        const element = mount();

        typeInInput(element, '01001000');
        clickSearch(element);
        await flushPromises();

        const alert = element.shadowRoot.querySelector('[role="alert"]');
        expect(alert.textContent).toContain('Serviço de consulta indisponível no momento.');
    });

    it('mostra o spinner e desabilita o botão durante a busca', async () => {
        let resolve;
        buscarCep.mockReturnValue(new Promise((r) => { resolve = r; }));
        const element = mount();

        typeInInput(element, '01001000');
        clickSearch(element);
        await flushPromises();

        expect(element.shadowRoot.querySelector('lightning-spinner')).not.toBeNull();
        expect(element.shadowRoot.querySelector('lightning-button').disabled).toBe(true);

        resolve(ADDRESS);
        await flushPromises();
        expect(element.shadowRoot.querySelector('lightning-spinner')).toBeNull();
    });

    it('troca para CNPJ, busca com dígitos e mostra a empresa', async () => {
        buscarCnpj.mockResolvedValue(COMPANY);
        const element = mount();

        element.shadowRoot.querySelector('lightning-radio-group')
            .dispatchEvent(new CustomEvent('change', { detail: { value: 'cnpj' } }));
        await flushPromises();

        const input = element.shadowRoot.querySelector('lightning-input');
        expect(input.label).toBe('CNPJ');

        typeInInput(element, '33.000.167/0001-01');
        clickSearch(element);
        await flushPromises();

        expect(buscarCnpj).toHaveBeenCalledWith({ cnpj: '33000167000101' });
        expect(element.shadowRoot.textContent).toContain('PETROBRAS - EDISE');
        expect(element.shadowRoot.textContent).toContain('Ativa');
    });

    it('move o foco para o título do resultado depois da busca', async () => {
        buscarCep.mockResolvedValue(ADDRESS);
        const element = mount();

        typeInInput(element, '01001000');
        clickSearch(element);
        await flushPromises();

        const heading = element.shadowRoot.querySelector('[data-result-heading]');
        expect(heading).not.toBeNull();
        expect(heading.getAttribute('tabindex')).toBe('-1');
    });
});

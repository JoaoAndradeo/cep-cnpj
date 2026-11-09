import { LightningElement } from 'lwc';
import buscarCep from '@salesforce/apex/BuscaDadosController.buscarCep';
import buscarCnpj from '@salesforce/apex/BuscaDadosController.buscarCnpj';

const TYPE_CEP = 'cep';
const TYPE_CNPJ = 'cnpj';
const DIGITS_CEP = 8;
const DIGITS_CNPJ = 14;
const GENERIC_ERROR = 'Não foi possível concluir a busca. Tente novamente.';
const EMPTY = '—';

const TYPE_OPTIONS = [
    { label: 'CEP', value: TYPE_CEP },
    { label: 'CNPJ', value: TYPE_CNPJ }
];

function field(key, label, value) {
    return { key, label, value: value || EMPTY };
}

export default class CepCnpjBusca extends LightningElement {
    searchType = TYPE_CEP;
    inputValue = '';
    inputError;
    isLoading = false;
    errorMessage;
    hasSearched = false;
    address;
    company;
    shouldFocusResult = false;

    typeOptions = TYPE_OPTIONS;

    get isCep() {
        return this.searchType === TYPE_CEP;
    }

    get inputLabel() {
        return this.isCep ? 'CEP' : 'CNPJ';
    }

    get placeholder() {
        return this.isCep ? '00000-000' : '00.000.000/0000-00';
    }

    get maxLength() {
        return this.isCep ? 9 : 18;
    }

    get hasAddress() {
        return this.hasResult && !!this.address;
    }

    get hasCompany() {
        return this.hasResult && !!this.company;
    }

    get notFound() {
        return this.hasSearched && !this.isLoading && !this.errorMessage && !this.address && !this.company;
    }

    get hasResult() {
        return this.hasSearched && !this.isLoading && !this.errorMessage;
    }

    get addressFields() {
        const a = this.address;
        if (!a) {
            return [];
        }
        return [
            field('cep', 'CEP', a.cep),
            field('street', 'Logradouro', a.street),
            field('complement', 'Complemento', a.complement),
            field('neighborhood', 'Bairro', a.neighborhood),
            field('city', 'Cidade', a.city),
            field('state', 'UF', a.state)
        ];
    }

    get companyFields() {
        const c = this.company;
        if (!c) {
            return [];
        }
        return [
            field('cnpj', 'CNPJ', c.cnpj),
            field('legalName', 'Razão social', c.legalName),
            field('tradeName', 'Nome fantasia', c.tradeName),
            field('status', 'Situação cadastral', c.registrationStatus),
            field('street', 'Logradouro', c.street),
            field('number', 'Número', c.streetNumber),
            field('neighborhood', 'Bairro', c.neighborhood),
            field('city', 'Cidade', c.city),
            field('state', 'UF', c.state),
            field('zipCode', 'CEP', c.zipCode)
        ];
    }

    handleTypeChange(event) {
        this.searchType = event.detail.value;
        this.inputValue = '';
        this.clearResults();
    }

    handleInput(event) {
        this.inputValue = event.target.value;
        this.inputError = undefined;
    }

    handleKeyUp(event) {
        if (event.key === 'Enter') {
            this.handleSearch();
        }
    }

    handleSearch() {
        const digits = this.inputValue.replace(/\D/g, '');
        const expected = this.isCep ? DIGITS_CEP : DIGITS_CNPJ;
        if (digits.length !== expected) {
            this.inputError = `${this.inputLabel} deve ter ${expected} dígitos.`;
            this.clearResults();
            return;
        }

        this.inputError = undefined;
        this.clearResults();
        this.hasSearched = true;
        this.isLoading = true;

        const request = this.isCep ? buscarCep({ cep: digits }) : buscarCnpj({ cnpj: digits });
        request
            .then((result) => {
                if (this.isCep) {
                    this.address = result;
                } else {
                    this.company = result;
                }
                this.shouldFocusResult = true;
            })
            .catch((error) => {
                this.errorMessage = error?.body?.message || GENERIC_ERROR;
                this.shouldFocusResult = true;
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    renderedCallback() {
        if (this.shouldFocusResult) {
            this.shouldFocusResult = false;
            const heading = this.template.querySelector('[data-result-heading]');
            if (heading) {
                heading.focus();
            }
        }
    }

    clearResults() {
        this.hasSearched = false;
        this.address = undefined;
        this.company = undefined;
        this.errorMessage = undefined;
    }
}

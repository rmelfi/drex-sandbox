
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./RealDigital.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

/**
 * Contrato que representa a consulta de carteiras de clientes, semelhante ao DICT para o PIX
 * 
 * Esse contrato será usado durante o piloto. 
 */

contract KeyDictionary {

    using Counters for Counters.Counter;

    Counters.Counter private _proposalIdCounter;

    /**
     * Referencia o contrato de Real Digital
     */
    RealDigital CBDC;


    /**
     * Estrutura para armazenar os dados de cliente ficticio
     * @param taxId O CPF do cliente
     * @param cnpj8 O cnpj8 do participante
     * @param bankNumber O código do participante
     * @param account A conta do cliente
     * @param branch A agência do cliente
     * @param wallet A carteira do cliente
     * @param registered Registrado ou não
     * @param owner A carteira do participante que inseriu o cliente
     */
    struct CustomerData {
        uint256 taxId;
        uint256 cnpj8;
        uint256 bankNumber;
        uint256 account;
        uint256 branch;
        address wallet;
        bool registered;
        address owner;
    }

    /**
     * Mapping da chave para dados de consumidor
     */
    mapping(bytes32 => CustomerData) private _customersData;
    /**
     * Mapping de id pra proposta de troca de owner de chave
     */
    mapping(uint256 => mapping(bytes32 => CustomerData)) private _customersProposedData;
    /**
     * Mapping de endereço para chave
     */
    mapping(address => bytes32) private _walletsKeys;

    /**
     * Evento de solicitação de troca de dono de chave
     * @param owner Dono da chave
     * @param proposalId Id da proposta
     * @param key Chave
     */
    event KeyRequested(address owner, uint256 proposalId, bytes32 key);

    /**
     * 
     * Modificador de método: somente participantes podem criar chaves
     */
    modifier onlyParticipant {
        require ( CBDC.authorizedAccounts(msg.sender), "RealDigitalDefaultAccount: Not authorized Account");
        _;
    }

    /**
     * Construtor
     * @param token Endereço do token do Real Digital
     */
    constructor(RealDigital token) {
        CBDC = token;               
    }

    /**
     * Adiciona dados de cliente, vinculando à chave _key_
     * @param key Chave
     * @param _taxId CPF
     * @param _cnpj8 Cnpj8 do participante
     * @param _bankNumber ID do participante
     * @param _account Conta do cliente
     * @param _branch Agência do cliente
     * @param _wallet Carteira
     */
    function addAccount(bytes32 key, uint256 _taxId, uint256 _bankNumber, uint256 _account, uint256 _branch, address _wallet, uint256 _cnpj8) public onlyParticipant {
        require(_customersData[key].registered == false , "KeyDictionary: already registered");
        _customersData[key] = CustomerData(_taxId, _cnpj8, _bankNumber, _account, _branch,  _wallet, true, msg.sender);
        _walletsKeys[_wallet] = key;
    }

    /**
     * Retorna a carteira do cliente baseado na chave _key_
     * @param key Chave
     */
    function getWallet (bytes32 key) public view onlyParticipant returns(address) {
        return _customersData[key].wallet;        
    }

    /**
     * Retorna a chave baseado na carteira
     * @param wallet Carteira
     */
    function getKey(address wallet) public view onlyParticipant returns(bytes32) {
        return _walletsKeys[wallet];        
    }

    /**
     * Retorna todos os dados do cliente
     * @param key Chave 
     */
    function getCustomerData (bytes32 key) public view  onlyParticipant  returns(CustomerData memory){
        return _customersData[key];
    }

    /**
     * Atualiza os dados do cliente da chave _key_
     * @param key Chave
     * @param _taxId CPF
     * @param _cnpj8 Cnpj8 do participante
     * @param _bankNumber ID do participante
     * @param _account Conta do cliente
     * @param _branch Agência do cliente
     * @param _wallet Carteira
     */
    function updateData (bytes32 key, uint256 _taxId, uint256 _cnpj8, uint256 _bankNumber, uint256 _account, uint256 _branch, address _wallet) public onlyParticipant{
       require(_customersData[key].registered == true , "KeyDictionary: not registered");
       require(_customersData[key].owner == msg.sender, "KeyDictionary: not owner");
       _customersData[key] = CustomerData(_taxId, _cnpj8, _bankNumber, _account, _branch,  _wallet, true, msg.sender);
       _walletsKeys[_wallet] = key;       
    }

    /**
     * Requisita uma chave que pertence a outro participante
     * @param key Chave
     * @param _taxId CPF
     * @param _cnpj8 Cnpj8 do participante
     * @param _bankNumber ID do participante
     * @param _account Conta do cliente
     * @param _branch Agência do cliente
     * @param _wallet Carteira
     */
    function requestKey(bytes32 key, uint256 _taxId, uint256 _cnpj8, uint256 _bankNumber, uint256 _account, uint256 _branch, address _wallet) public onlyParticipant{
       require(_customersData[key].registered == true , "KeyDictionary: not registered");
       require(_customersData[key].taxId == _taxId, "KeyDictionary: not same taxId");

       uint256 proposalId = _proposalIdCounter.current();
       _proposalIdCounter.increment();

       _customersProposedData[proposalId][key] = CustomerData(_taxId, _cnpj8, _bankNumber, _account, _branch,  _wallet, false, msg.sender);

        emit KeyRequested(_customersData[key].owner, proposalId, key);
             
    }

    /**
     * Aceita a requisição
     * @param proposalId Id da proposta
     * @param key Chave
     */
    function authorizeKey(uint256 proposalId, bytes32 key) public onlyParticipant {
        require(_customersData[key].owner == msg.sender , "KeyDictionary: not data owner");
        require(_customersProposedData[proposalId][key].registered == false,  "KeyDictionary: already registered");

        _customersProposedData[proposalId][key].registered = true;
        _customersData[key] = _customersProposedData[proposalId][key];
        _walletsKeys[_customersProposedData[proposalId][key].wallet] = key;   
    }
}
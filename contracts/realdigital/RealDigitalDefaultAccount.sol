// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./RealDigital.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

/**
 * Contrato que permite aos participantes trocarem sua carteira default
 * A carteira default é usada nas operações de _swap_ de Real Tokenizado 
 */
contract RealDigitalDefaultAccount is AccessControl {

    /**
     * _Role_ de acesso, pertencente a autoridade do contrato
     */
    bytes32 public constant ACCESS_ROLE = keccak256("ACCESS_ROLE");

    /**
     * _Mapping_ das contas default, a chave é o CPNJ8
     */
    mapping (uint256 => address) public defaultAccount;

    /**
     * Referência ao contrato do Real Digital, para validação de participantes
     */
    RealDigital CBDC;

    /**
     * Modificador de método: somente participantes podem alterar suas carteiras default      
     */
    modifier onlyParticipant {
        require ( CBDC.authorizedAccounts(msg.sender), "RealDigitalDefaultAccount: Not authorized Account");
        _;
    }

    /**
     * Evento de alteração de carteira padrão
     * @param cnpj8 cnpj8 do participante
     * @param wallet endereço da carteira
    */
    event DefaultAccountChanged(uint256 cnpj8, address wallet);

    /**
     * 
     * @param token Endereço do Real Digital
     * @param _authority Autoridade do contrato, pode adicionar carteiras default
     * @param _admin Administrador do contrato, pode trocar a autoridade
     */
    constructor(RealDigital token, address _authority, address _admin) {
        CBDC = token; 
        _grantRole(ACCESS_ROLE, _authority);
        _grantRole(DEFAULT_ADMIN_ROLE, _admin); 
    }

    /**
     * Adiciona uma carteira default pela primeira vez, permitido apenas para a autoridade
     * @param cnpj8 CNPJ8 do participante
     * @param wallet Carteira
     */
    function addDefaultAccount(uint256 cnpj8, address wallet) public onlyRole(ACCESS_ROLE) {
        defaultAccount[cnpj8] = wallet;
        CBDC.enableAccount(wallet);

        emit DefaultAccountChanged(cnpj8, wallet);
    }

    /**
     * Depois de adicionada pela autoridade, esse método permite ao participante trocar sua carteira default
     * @param cnpj8 CNPJ8 do participante
     * @param newWallet Carteira
     */
    function updateDefaultWallet(uint256 cnpj8, address newWallet) public onlyParticipant {
        require(defaultAccount[cnpj8] == msg.sender, "RealDigitalDefaultAccount: Not authorized Account");
        defaultAccount[cnpj8] = newWallet;
        CBDC.enableAccount(newWallet);

        emit DefaultAccountChanged(cnpj8, newWallet);    
    }
}
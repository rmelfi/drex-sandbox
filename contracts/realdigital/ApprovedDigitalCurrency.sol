// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/AccessControl.sol";

/**
 * @title ApprovedDigitalCurrency
 * @author BCB
 * @notice _Smart Contract_ utilitário para gerenciar que tokens podem ser usados nos contrato de _swap
 */
contract ApprovedDigitalCurrency is AccessControl {

    /**
     * _Role_ que permite adicionar tokens na lista de tokens permitidos
    */
    bytes32 public constant ACCESS_ROLE = keccak256("ACCESS_ROLE");

    mapping( address => bool) approvedDigitalCurrency;

    
    /**
     * Construtor
     * @param _authority Autoridade do contrato, pode fazer todas as operações com o contrato
     * @param _admin Administrador do contrato, pode trocar a autoridade do contrato caso seja necessário
    */
    constructor (address _authority, address _admin) {
        _grantRole(DEFAULT_ADMIN_ROLE, _admin);
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(ACCESS_ROLE, _authority);
    }

    /**
     * Habilita ou desabilita a operação de um token nos contratos de swap
     * @param asset endereço do token
     * @param approved habilitado ou desabilitado
     */
    function setDigitalCurrencyApproval(address asset, bool approved) public onlyRole(ACCESS_ROLE) {

        approvedDigitalCurrency[asset] = approved;

    }

}
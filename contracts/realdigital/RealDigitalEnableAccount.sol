//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./CBDCAccessControl.sol";

/**
 * Contrato que permite ao participante habilitar outras carteiras de sua posse 
 */
contract RealDigitalEnableAccount {
    CBDCAccessControl private accessControl;

    /**
     * Construtor
     * @param accessControlAddress Endereço do contrato de controle de acesso
     */
    constructor(address accessControlAddress) {
        accessControl = CBDCAccessControl(accessControlAddress);
    }

    /**
     * Habilita uma nova carteira do participante, permitido para todas as carteiras habilitadas
     * @param member Novo endereço do participante
     */
    function enableAccount(address member) public {
        require(member!= address(0), "RealDigitalEnableAccount: address cannot be zero");
        require(accessControl.verifyAccount(msg.sender), "RealDigitalEnableAccount: sender does not have permission to enable account");

        accessControl.enableAccount(member);
    }

    /**
     * Desabilita sua própria carteira
     */
    function disableAccount() public {
        accessControl.disableAccount(msg.sender);
    }
}
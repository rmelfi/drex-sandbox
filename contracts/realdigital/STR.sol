// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./RealDigital.sol";

/**
 * Esse contrato simula o STR. Através dele, participantes autorizados podem emitir Real Digital.
 * 
 * Para o piloto, nenhuma validação é feita, basta que o participante esteja autorizado 
 */
contract STR {
    /**
     * Referência ao contrato de CBDC, para checar se o participante é autorizado
     */
    RealDigital CBDC;

    /**
     * 
     * Modificador de método: somente participantes podem emitir Real Digital
     */
    modifier onlyParticipant {
        require ( CBDC.authorizedAccounts(msg.sender), "RealDigitalDefaultAccount: Not authorized Account");
        _;
    }

    /**
     * Construtor
     * @param token Endereço do Real Digital
     */
    constructor(RealDigital token) {
        CBDC = token;               
    }

    /**
     * Emite Real Digital para a sua carteira
     * @param amount Quantidade a ser emitida: lembrar das 2 casas decimais
     */
    function requestToMint(uint256 amount) public onlyParticipant {
        CBDC.mint(msg.sender, amount);
    }

    /**
     * Queima Real Digital da sua carteira
     * @param amount Quantidade a ser queimada: lembrar das 2 casas decimais
     */
    function requestToBurn(uint256 amount) public onlyParticipant {
        CBDC.moveAndBurn(msg.sender, amount);
    }
}
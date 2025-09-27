// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./RealTokenizado.sol";
import "./RealDigital.sol";
import  "./ApprovedDigitalCurrency.sol";


/**
 * Esse contrato implementa o depósito de Real Tokenizado através da transferência de reserva de Real Digital
 * 
 * 
 * 
 */
contract SwapToRetail is ApprovedDigitalCurrency {

    /**
     * Referência ao contrato do Real Digital, para que seja efetuada a movimentação de Real Digital
     */
    RealDigital CBDC;

    /**
     * Evento de _swap_ executado
     * @param receiverNumber CNPJ8 do recebedor
     * @param sender Carteira do pagador
     * @param receiver Carteira do recebedor
     * @param amount Valor
     */
    event SwapToRetailExecuted(uint256 indexed receiverNumber, address sender, address receiver, uint256 amount);
   
    /**
     * Construtor
     * @param _CBDC Endereço do contrato de Real Digital
     * @param _authority Autoridade do contrato, pode fazer todas as operações com o token
     * @param _admin Administrador do contrato, pode trocar a autoridade do contrato caso seja necessário
     */
    constructor (address _admin, address _authority, RealDigital _CBDC) ApprovedDigitalCurrency(_authority, _admin) {
        CBDC = _CBDC;       
    }

     /**
     * Transfere o Real Tokenizado do cliente pagador para o recebedor pelo uso do allowance. O cliente pagador é o _sender_
     * @param tokenReceiver Endereço do contrato de Real Tokenizado do recebedor
     * @param receiver Endereço do cliente recebedor
     * @param amount Valor
     */

    function executeSwapToRetail(RealTokenizado tokenReceiver, address receiver, uint256 amount) public {
        require(tokenReceiver.reserve()!= address(0), "SwapToRetail: Receiver Reserve not registered");                          
        require(tokenReceiver.authorizedAccounts(receiver), "SwapToRetail: Unknown account");
        require(receiver!= address(0),  "SwapToRetail: Receiver cannot be address zero");
        require(approvedDigitalCurrency[address(tokenReceiver)], "SwapToRetail: Digital currency not allowed to swap");
              
        CBDC.transferFrom(_msgSender(), tokenReceiver.reserve(), amount);
        
        tokenReceiver.mint(receiver, amount);
        
        emit SwapToRetailExecuted(tokenReceiver.cnpj8(), _msgSender(), receiver, amount);

    }
}
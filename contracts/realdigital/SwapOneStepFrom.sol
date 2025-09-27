// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./RealTokenizado.sol";
import "./RealDigital.sol";
import  "./ApprovedDigitalCurrency.sol";


/**
 * Esse contrato implementa a troca de Real Tokenizado entre dois participantes distintos
 * 
 * A troca queima Real Tokenizado do cliente pagador, 
 * transfere Real Digital do participante pagador para o recebedor
 * e emite Real Tokenizado para o cliente recebedor.
 * 
 * A operação de _swap_ é feita em apenas uma transação
 */
contract SwapOneStepFrom is ApprovedDigitalCurrency {

    /**
     * Referência ao contrato do Real Digital, para que seja efetuada a movimentação de Real Digital
     */
    RealDigital CBDC;

    /**
     * Evento de _swap_ executado
     * @param senderNumber CNPJ8 do pagador
     * @param receiverNumber CNPJ8 do recebedor
     * @param sender Carteira do pagador
     * @param receiver Carteira do recebedor
     * @param amount Valor
     */
    event SwapExecuted(uint256 indexed senderNumber, uint256 indexed receiverNumber, address sender, address receiver, uint256 amount);
   
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
     * @param tokenSender Endereço do contrato de Real Tokenizado do pagador
     * @param tokenReceiver Endereço do contrato de Real Tokenizado do recebedor
     * @param sender Endereço que autorizou a transferencia a outra carteira
     * @param receiver Endereço do cliente recebedor
     * @param amount Valor
     */

    function executeSwapFrom(RealTokenizado tokenSender, RealTokenizado tokenReceiver, address sender, address receiver, uint256 amount) public {
        require(tokenSender.reserve()!= address(0), "SwapRealTokenizado: Sender Reserve not registered");
        require(tokenReceiver.reserve()!= address(0), "SwapRealTokenizado: Receiver Reserve not registered");                          
        require(tokenReceiver.authorizedAccounts(receiver), "SwapRealTokenizado: Unknown account");
        require(tokenSender.authorizedAccounts(sender), "SwapRealTokenizado: Unknown account");
        require(receiver!= address(0),  "SwapRealTokenizado: Receiver cannot be address zero");
        require(tokenReceiver != tokenSender , "SwapRealTokenizado: same Real Tokenizado");
        require(tokenSender.allowance(sender, _msgSender()) >= amount, string.concat("SwapRealTokenizado: ",tokenSender.name()," not allowed to transfer funds"));
        require(approvedDigitalCurrency[address(tokenSender)] && approvedDigitalCurrency[address(tokenReceiver)], "SwapRealTokenizado: Digital currency not allowed to swap");

        tokenSender.spendAllowanceFrom(sender, _msgSender(), amount);

        tokenSender.moveAndBurn(sender, amount);
                
        CBDC.move(tokenSender.reserve(), tokenReceiver.reserve(), amount);
        
        tokenReceiver.mint(receiver, amount);
        
        emit SwapExecuted(tokenSender.cnpj8(), tokenReceiver.cnpj8(), sender, receiver, amount);
    }
}
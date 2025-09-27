// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./RealTokenizado.sol";
import "./RealDigital.sol";
import  "./ApprovedDigitalCurrency.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

/**
 * Esse contrato implementa a troca de Real Tokenizado entre dois participantes distintos
 * 
 * A troca queima Real Tokenizado do cliente pagador, 
 * transfere Real Digital do participante pagador para o recebedor
 * e emite Real Tokenizado para o cliente recebedor.
 * 
 * A operação de _swap_ é feita em duas transações: uma de proposta e outra de aceite
 * e parte da premissa que o participante pagador já aprovou a movimentação
 * de Real Digital pelo contrato usando o método _approve_ do ERC20
 */

contract SwapTwoSteps is ApprovedDigitalCurrency {

    using Counters for Counters.Counter;

    Counters.Counter private _proposalIdCounter;
    
    /**
     * Referência ao contrato do Real Digital, para que seja efetuada a movimentação de Real Digital
     */
    RealDigital CBDC;

    /**
     * Status do _swap_
     */
    enum SwapStatus {
        PENDING,
        EXECUTED,
        CANCELLED
    }

    struct SwapProposal {
        RealTokenizado tokenSender;
        RealTokenizado tokenReceiver;
        address sender;
        address receiver;
        uint256 amount;
        SwapStatus status;
        uint timestamp;       
    }

    /**
     * _Mapping_ de propostas de _swap_
     */
    mapping( uint256 => SwapProposal) swapProposals;
    
    /**
     * Evento de início do _swap_
     * @param proposalId Id da proposta
     * @param senderNumber CNPJ8 do pagador
     * @param receiverNumber CNPJ8 do recebedor
     * @param sender Endereço do pagador
     * @param receiver Endereço do recebedor
     * @param amount Valor
     */
    event SwapStarted(uint256 indexed proposalId, uint256 indexed senderNumber, uint256 indexed receiverNumber, address sender, address receiver, uint256 amount);
    /**
     * Evento de _swap_ executado
     * @param proposalId Id da proposta
     * @param senderNumber CNPJ8 do pagador
     * @param receiverNumber CNPJ8 do recebedor
     * @param sender Endereço do pagador
     * @param receiver Endereço do recebedor
     * @param amount Valor
     */
    event SwapExecuted(uint256 indexed proposalId, uint256 indexed senderNumber, uint256 indexed receiverNumber, address sender, address receiver, uint256 amount);
    /**
     * Evento de swap cancelado
     * @param proposalId Id da proposta
     * @param reason Razão do cancelamento
     */
    event SwapCancelled(uint256 indexed proposalId, string reason);
    /**
     * Evento de proposta expirada. A proposta expira em 1 minuto
     * @param proposalId Id da proposta
     */
    event ExpiredProposal(uint256 indexed proposalId);

    /**
     * Construtor
     * @param _CBDC Endereço do contrato do Real Digital
     * @param _authority Autoridade do contrato, pode fazer todas as operações com o token
     * @param _admin Administrador do contrato, pode trocar a autoridade do contrato caso seja necessário
     */
     constructor (address _admin, address _authority, RealDigital _CBDC) ApprovedDigitalCurrency(_authority, _admin) {
        CBDC = _CBDC;       
    }

    /**
     * Cria a proposta de _swap_
     * @param tokenSender Endereço do contrato de Real Tokenizado do pagador
     * @param tokenReceiver Endereço do contrato de Real Tokenizado do recebedor
     * @param receiver Endereço do cliente recebedor
     * @param amount Valor
     */
   function startSwap(RealTokenizado tokenSender, RealTokenizado tokenReceiver, address receiver, uint256 amount) public {
        require(tokenReceiver.authorizedAccounts(receiver), "SwapRealTokenizado: Unknown account");
        require(tokenSender.balanceOf(_msgSender()) >= amount, "SwapRealTokenizado: Not dvt enough balance");
        require(CBDC.balanceOf(tokenSender.reserve()) >= amount, "SwapRealTokenizado: Not cbdc enough balance");
        require (tokenReceiver != tokenSender , "SwapRealTokenizado: same Real Tokenizado");
        require(receiver != address(0),  "SwapRealTokenizado: Receiver cannot be address zero");
        require(approvedDigitalCurrency[address(tokenSender)] && approvedDigitalCurrency[address(tokenReceiver)], "SwapRealTokenizado: Digital currency not allowed to swap");
        

        uint256 proposalId = _proposalIdCounter.current();
        _proposalIdCounter.increment();
    
        swapProposals[proposalId] = SwapProposal(tokenSender,tokenReceiver,_msgSender(), receiver, amount, SwapStatus.PENDING, block.timestamp);
        
        emit SwapStarted(proposalId, tokenSender.cnpj8(), tokenReceiver.cnpj8(), _msgSender(), receiver, amount);
    }
    
    /**
     * Aceita a proposta de swap, executável apenas pelo recebedor
     * @param proposalId Id da proposta
     */
   function executeSwap(uint256 proposalId) public { 
        require(swapProposals[proposalId].tokenSender.reserve()!= address(0), "SwapRealTokenizado: Sender Reserve not registered");
        require(swapProposals[proposalId].tokenReceiver.reserve()!= address(0), "SwapRealTokenizado: Receiver Reserve not registered");                          
        require(_msgSender() == swapProposals[proposalId].receiver, "SwapRealTokenizado: Receiver not _msgSender()");
        require(swapProposals[proposalId].status == SwapStatus.PENDING, "SwapRealTokenizado: Swap cancelled or executed");
        require(swapProposals[proposalId].tokenReceiver.authorizedAccounts(swapProposals[proposalId].receiver), "SwapRealTokenizado: Unknown account");
        require(approvedDigitalCurrency[address(swapProposals[proposalId].tokenSender)] && approvedDigitalCurrency[address(swapProposals[proposalId].tokenReceiver)], "SwapRealTokenizado: Digital currency not allowed to swap");

        if (block.timestamp - swapProposals[proposalId].timestamp > 60) {
            emit ExpiredProposal(proposalId);
            revert("SwapRealTokenizado: Expired proposal");
        }

        swapProposals[proposalId].status = SwapStatus.EXECUTED;

        swapProposals[proposalId].tokenSender.burnFrom(swapProposals[proposalId].sender, swapProposals[proposalId].amount);

        CBDC.transferFrom(swapProposals[proposalId].tokenSender.reserve(), swapProposals[proposalId].tokenReceiver.reserve(), swapProposals[proposalId].amount);
        
        swapProposals[proposalId].tokenReceiver.mint(swapProposals[proposalId].receiver, swapProposals[proposalId].amount);
        
        emit SwapExecuted(proposalId, swapProposals[proposalId].tokenSender.cnpj8(), swapProposals[proposalId].tokenReceiver.cnpj8(), swapProposals[proposalId].sender, swapProposals[proposalId].receiver, swapProposals[proposalId].amount);
    }

    /**
     * Cancela a proposta. Pode ser executada tanto pelo pagador quanto pelo recebedor
     * @param proposalId Id da proposta
     * @param reason Razão do cancelamento
     */
    function cancelSwap(uint256 proposalId, string calldata reason) public {
        require(swapProposals[proposalId].status == SwapStatus.PENDING, "SwapRealTokenizado: Swap cancelled or executed");
        require(_msgSender() == swapProposals[proposalId].receiver || _msgSender() == swapProposals[proposalId].sender, "SwapRealTokenizado:Sender or Receiver not _msgSender()");

        swapProposals[proposalId].status = SwapStatus.CANCELLED;

        emit SwapCancelled(proposalId, reason);
    }
}
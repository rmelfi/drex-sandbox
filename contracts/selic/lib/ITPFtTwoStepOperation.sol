// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {ITPFt} from "../ITPFt.sol";
import {RealTokenizado} from "../../realdigital/RealTokenizado.sol";

/**
 * @title ITPFtTwoStepOperation
 * @author BCB
 * @notice Interface que adiciona funcionalidades específicas para operações de dois comandos com TPFt.
 */
interface ITPFtTwoStepOperation is IAccessControl {
    /**
     * Evento emitido quando uma operação de trade é realizada entre participante envolvendo CNPJ8s.
     * @param operationId Número de operação + data vigente no formato yyyyMMdd.
     * @param cnpj8Sender CNPJ8 do cedente da operação.
     * @param cnpj8Receiver CNPJ8 do cessionário da operação.
     * @param sender Endereço do cedente da operação.
     * @param receiver Endereço do cessionarário da operação.
     * @param tpftData Estrutura de dados do TPFt, que incluem as seguintes informações: <br />- `acronym`: A sigla do TPFt. <br />- `code`: O código único do TPFt. <br />- `maturityDate`: A data de vencimento do TPFt, representada como um valor numérico (timestamp Unix).
     * @param tpftAmount Quantidade de TPFt a ser negociada.
     * @param unitPrice Preço unitário do TPFt. Incluindo as 8 casas decimais.
     * @param financialValue Calculado pela quantidade de TPFt a ser negociada vezes Preço unitário do TPFt.
     * @param status Status da operação.
     * @param timestamp Valor numérico que indica um ponto específico no tempo fornecido em formato de timestamp Unix.
     */
    event OperationEvent(uint256 operationId, uint256 cnpj8Sender, uint256 cnpj8Receiver, address sender, address receiver, ITPFt.TPFtData tpftData, uint256 tpftAmount, uint256 unitPrice, uint256 financialValue, string status, uint256 timestamp);

    /**
     * Evento emitido quando uma operação de trade é realizada entre participante envolvendo endereços.
     * @param operationId Número de operação + data vigente no formato yyyyMMdd.
     * @param sender Endereço do cedente da operação.
     * @param receiver Endereço do cessionarário da operação.
     * @param tpftData Estrutura de dados do TPFt, que incluem as seguintes informações: <br />- `acronym`: A sigla do TPFt. <br />- `code`: O código único do TPFt. <br />- `maturityDate`: A data de vencimento do TPFt, representada como um valor numérico (timestamp Unix).
     * @param tpftAmount Quantidade de TPFt a ser negociada.
     * @param unitPrice Preço unitário do TPFt. Incluindo as 8 casas decimais.
     * @param financialValue Calculado pela quantidade de TPFt a ser negociada vezes Preço unitário do TPFt.
     * @param status Status da operação.
     * @param timestamp Valor numérico que indica um ponto específico no tempo fornecido em formato de timestamp Unix.
     */
    event OperationTradeEvent(uint256 operationId, address sender, address receiver, ITPFt.TPFtData tpftData, uint256 tpftAmount, uint256 unitPrice, uint256 financialValue, string status, uint256 timestamp);

    /**
     * Evento emitido quando uma operação de trade entre clientes é realizada envolvendo endereços e seus
     * Real Tokenizados.
     * @param operationId Número de operação + data vigente no formato yyyyMMdd.
     * @param sender Endereço da carteira do cedente da operação.
     * @param senderToken RealTokenizado do cedente da operação.
     * @param receiver Endereço da carteira do cessionário da operação.
     * @param receiverToken RealTokenizado do cessionário da operação.
     * @param tpftData Estrutura de dados do TPFt, que incluem as seguintes informações: <br />- `acronym`: A sigla do TPFt. <br />- `code`: O código único do TPFt. <br />- `maturityDate`: A data de vencimento do TPFt, representada como um valor numérico (timestamp Unix).
     * @param tpftAmount Quantidade de TPFt a ser negociada.
     * @param unitPrice Preço unitário do TPFt. Incluindo as 8 casas decimais.
     * @param financialValue Calculado pela quantidade de TPFt a ser negociada vezes Preço unitário do TPFt.
     * @param status Status da operação.
     * @param timestamp Valor numérico que indica um ponto específico no tempo fornecido em formato de timestamp Unix.
     */
    event OperationClientTradeEvent(
        uint256 operationId,
        address sender,
        RealTokenizado senderToken,
        address receiver,
        RealTokenizado receiverToken,
        ITPFt.TPFtData tpftData,
        uint256 tpftAmount,
        uint256 unitPrice,
        uint256 financialValue,
        string status,
        uint256 timestamp
    );

    /**
     * Evento emitido quando uma operação de compra/venda definitiva entre participantes envolvendo CNPJ8s.
     * @param operationId Número de operação + data vigente no formato yyyyMMdd.
     * @param cnpj8Sender CNPJ8 do cedente da operação.
     * @param sender Endereço da carteira do cedente da operação.
     * @param cnpj8Receiver CNPJ8 do cessionário da operação.
     * @param receiver Endereço da carteira do cessionário da operação.
     * @param tpftData Estrutura de dados do TPFt, que incluem as seguintes informações: <br />- `acronym`: A sigla do TPFt. <br />- `code`: O código único do TPFt. <br />- `maturityDate`: A data de vencimento do TPFt, representada como um valor numérico (timestamp Unix).
     * @param tpftAmount Quantidade de TPFt a ser negociada.
     * @param unitPrice Preço unitário do TPFt. Incluindo as 8 casas decimais.
     * @param financialValue Calculado pela quantidade de TPFt a ser negociada vezes Preço unitário do TPFt.
     * @param status Status da operação.
     * @param timestamp Valor numérico que indica um ponto específico no tempo fornecido em formato de timestamp Unix.
     * @param noticeNumber Número do comunicado.
     */
    event AuctionOperationEvent(
        uint256 indexed operationId,
        uint256 indexed cnpj8Sender,
        address sender,
        uint256 indexed cnpj8Receiver,
        address receiver,
        ITPFt.TPFtData tpftData,
        uint256 tpftAmount,
        uint256 unitPrice,
        uint256 financialValue,
        string status,
        uint256 timestamp,
        string noticeNumber
    );

    /**
     * Evento emitido quando uma operação de liquidação de oferta pública ou compra e venda envolvendo TPFt é cancelada.
     * @param operationId Número de operação + data vigente no formato yyyyMMdd.
     * @param status Status da operação.
     * @param reason Motivo do cancelamento.
     * @param timestamp Valor numérico que indica um ponto específico no tempo fornecido em formato de timestamp Unix.
     */
    event OperationCancelEvent(uint256 operationId, string status, string reason, uint256 timestamp);
}

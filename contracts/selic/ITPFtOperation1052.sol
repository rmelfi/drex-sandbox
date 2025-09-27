// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import {ITPFt} from "./ITPFt.sol";
import {ITPFtTwoStepOperation} from "./lib/ITPFtTwoStepOperation.sol";
import {RealTokenizado} from "../realdigital/RealTokenizado.sol";
import {CallerPart} from "./lib/TPFtConstants.sol";

/**
 * @title ITPFtOperation1052
 * @author BCB
 * @notice Interface responsável por permitir que participantes cadastrados no
 * Real Digital realizem a operação de compra e venda envolvendo
 * Título Público Federal tokenizado (TPFt) entre si e/ou clientes.
 */
interface ITPFtOperation1052 is ITPFtTwoStepOperation {
    /**
     * Função externa que permite aos participantes realizarem a operação de compra e venda entre
     * si informando os CNPJ8s das partes. O CNPJ8 identifica a carteira default da parte.
     * @param operationId Número de operação + data vigente no formato yyyyMMdd.
     * @param cnpj8Sender CNPJ8 do cedente da operação.
     * @param cnpj8Receiver CNPJ8 do cessionário da operação.
     * @param callerPart Parte que está transmitindo o comando da operação. Se for o cedente deve ser informado CallerPart.TPFtSender, se for o cessionário deve ser informado CallerPart.TPFtReceiver.
     * @param tpftData Estrutura de dados do TPFt, que incluem as seguintes informações: <br />- `acronym`: A sigla do TPFt. <br />- `code`: O código único do TPFt. <br />- `maturityDate`: A data de vencimento do TPFt, representada como um valor numérico (timestamp Unix).
     * @param tpftAmount Quantidade de TPFt a ser negociada. Incluir as 2 casas decimais.
     * @param unitPrice Preço unitário do TPFt. Incluir as 8 casas decimais.
     */
    function trade(uint256 operationId, uint256 cnpj8Sender, uint256 cnpj8Receiver, CallerPart callerPart, ITPFt.TPFtData memory tpftData, uint256 tpftAmount, uint256 unitPrice) external;

    /**
     * Função externa que permite aos participantes realizarem a operação de compra e venda entre si informando os endereços das carteiras das partes.
     * @param operationId Número de operação + data vigente no formato yyyyMMdd.
     * @param sender Endereço da carteira do cedente da operação.
     * @param receiver Endereço da carteira do cessionário da operação.
     * @param callerPart Parte que está transmitindo o comando da operação. Se for o cedente deve ser informado CallerPart.TPFtSender, se for o cessionário deve ser informado CallerPart.TPFtReceiver.
     * @param tpftData Estrutura de dados do TPFt, que incluem as seguintes informações: <br />- `acronym`: A sigla do TPFt. <br />- `code`: O código único do TPFt. <br />- `maturityDate`: A data de vencimento do TPFt, representada como um valor numérico (timestamp Unix).
     * @param tpftAmount Quantidade de TPFt a ser negociada. Incluir as 2 casas decimais.
     * @param unitPrice Preço unitário do TPFt. Incluir as 8 casas decimais.
     */
    function trade(uint256 operationId, address sender, address receiver, CallerPart callerPart, ITPFt.TPFtData memory tpftData, uint256 tpftAmount, uint256 unitPrice) external;

    /**
     * Função externa que permite aos participantes e/ou clientes realizarem a operação de compra e venda entre si
     * informando o endereço das carteiras das partes e do seu Real Tokenizado.
     * @param operationId Número de operação + data vigente no formato yyyyMMdd.
     * @param sender Endereço da carteira do cedente da operação.
     * @param senderToken RealTokenizado do cedente da operação.
     * @param receiver Endereço da carteira do cessionário da operação.
     * @param receiverToken RealTokenizado do cessionário da operação.
     * @param callerPart Parte que está transmitindo o comando da operação. Se for o cedente deve ser informado CallerPart.TPFtSender, se for o cessionário deve ser informado CallerPart.TPFtReceiver.
     * @param tpftData Estrutura de dados do TPFt, que incluem as seguintes informações: <br />- `acronym`: A sigla do TPFt. <br />- `code`: O código único do TPFt. <br />- `maturityDate`: A data de vencimento do TPFt, representada como um valor numérico (timestamp Unix).
     * @param tpftAmount Quantidade de TPFt a ser negociada. Incluir as 2 casas decimais.
     * @param unitPrice Preço unitário do TPFt. Incluir as 8 casas decimais.
     */
    function trade(uint256 operationId, address sender, RealTokenizado senderToken, address receiver, RealTokenizado receiverToken, CallerPart callerPart, ITPFt.TPFtData memory tpftData, uint256 tpftAmount, uint256 unitPrice) external;

    /**
     * Função externa que permite aos participantes e o BACEN realizarem a operação de leilão de definitivas entre
     * si informando os CNPJ8s das partes. O CNPJ8 identifica a carteira default da parte.
     * @param operationId Número de operação + data vigente no formato yyyyMMdd.
     * @param cnpj8Sender CNPJ8 do cedente da operação.
     * @param cnpj8Receiver CNPJ8 do cessionário da operação.
     * @param callerPart Parte que está transmitindo o comando da operação. Se for o cedente deve ser informado CallerPart.TPFtSender, se for o cessionário deve ser informado CallerPart.TPFtReceiver.
     * @param tpftData Estrutura de dados do TPFt, que incluem as seguintes informações: <br />- `acronym`: A sigla do TPFt. <br />- `code`: O código único do TPFt. <br />- `maturityDate`: A data de vencimento do TPFt, representada como um valor numérico (timestamp Unix).
     * @param tpftAmount Quantidade de TPFt a ser negociada. Incluir as 2 casas decimais.
     * @param unitPrice Preço unitário do TPFt. Incluir as 8 casas decimais.
     * @param noticeNumber Número de comunicado.
     */
    function trade(uint256 operationId, uint256 cnpj8Sender, uint256 cnpj8Receiver, CallerPart callerPart, ITPFt.TPFtData memory tpftData, uint256 tpftAmount, uint256 unitPrice, string memory noticeNumber) external;

    /**
     * Função externa que cancela uma operação de compra e venda envolvendo TPFt.
     * @param operationId Número de operação + data vigente no formato yyyyMMdd.
     * @param reason Motivo do cancelamento
     */
    function cancel(uint256 operationId, string calldata reason) external;

    /**
     * Função externa utilizada pela carteira que é detentor da _ROLE_ DEFAULT_ADMIN_ROLE para colocar o contrato em pausa.
     * O contrato em pausa bloqueará a execução de funções, garantindo que o contrato possa ser temporariamente interrompido.
     */
    function pause() external;

    /**
     * Função externa utilizada pela carteira que é detentor da _ROLE_ DEFAULT_ADMIN_ROLE para retirar o contrato de pausa.
     * O contrato retirado de pausa permite a execução normal de todas as funções novamente após ter sido previamente pausado.
     */
    function unpause() external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import {ITPFt} from "./ITPFt.sol";

interface ITPFtOperation1001 {
    /**
     * Evento emitido quando uma operação de emissão de TPFt é realizada.
     * @param operationId Número de operação + data vigente no formato yyyyMMdd.
     * @param receiver Endereço do cessionarário da operação que é a carteira da STN.
     * @param tpftData Estrutura de dados do TPFt, que incluem as seguintes informações: <br />- `acronym`: A sigla do TPFt. <br />- `code`: O código único do TPFt. <br />- `maturityDate`: A data de vencimento do TPFt, representada como um valor numérico (timestamp Unix).
     * @param tpftAmount Quantidade de TPFt a ser negociada.
     * @param status Status da operação.
     * @param timestamp Valor numérico que indica um ponto específico no tempo fornecido em formato de timestamp Unix.
     */
    event OperationMintEvent(uint256 operationId, address receiver, ITPFt.TPFtData tpftData, uint256 tpftAmount, string status, uint256 timestamp);

    /**
     * Função para o Bacen criar um TPFt.
     * @param tpftData Estrutura de dados do TPFt, que incluem as seguintes informações: <br />- `acronym`: A sigla do TPFt. <br />- `code`: O código único do TPFt. <br />- `maturityDate`: A data de vencimento do TPFt, representada como um valor numérico (timestamp Unix).
     */
    function createTPFt(ITPFt.TPFtData memory tpftData) external;

    /**
     * Função para o Bacen emitir TPFt.
     * @param operationId  Número de operação + data vigente no formato yyyyMMdd.
     * @param tpftData Estrutura de dados do TPFt, que incluem as seguintes informações: <br />- `acronym`: A sigla do TPFt. <br />- `code`: O código único do TPFt. <br />- `maturityDate`: A data de vencimento do TPFt, representada como um valor numérico (timestamp Unix).
     * @param tpftAmount Quantidade de TPFt a ser emitido.
     */
    function mint(uint256 operationId, ITPFt.TPFtData memory tpftData, uint256 tpftAmount) external;
}

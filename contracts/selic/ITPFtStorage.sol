// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import {ITPFt} from "./ITPFt.sol";

/**
 * @title ITPFt
 * @author BCB
 * @notice Interface responsável pela criação e emissão de Título Público Federal tokenizado (TPFt).
 */
interface ITPFtStorage is IERC1155 {
    /**
     * Evento emitido quando o saldo de uma carteira é congelado.
     * @param from Endereço da carteira que teve o saldo congelado.
     * @param balance Saldo de ativo congelado.
     */
    event FrozenBalance(address indexed from, uint256 balance);

    /**
     * Função externa que retorna o nome do contrato.
     * @return Retorna uma string contendo o nome do contrato.
     */
    function name() external view returns (string memory);

    /**
     * Função externa que retorna a quantidade de TPFt criados
     * @return Retorna o numero com o total de TPFt criados
     */
    function getTPFtTotals() external view returns (uint256);

    /**
     * Função para criar um novo TPFt.
     * @param tpftData Estrutura de dados do TPFt, que incluem as seguintes informações: <br />- `acronym`: A sigla do TPFt. <br />- `code`: O código único do TPFt. <br />- `maturityDate`: A data de vencimento do TPFt, representada como um valor numérico (timestamp Unix).
     */
    function createTPFt(ITPFt.TPFtData memory tpftData) external;

    /**
     * Função para emitir TPFt.
     * @param receiverAddress Endereço do cessionário da operação. Nesta operação sempre será o endereço da STN.
     * @param tpftId Id do TPFt
     * @param tpftAmount Quantidade de TPFt a ser emitida.
     */
    function mint(address receiverAddress, uint256 tpftId, uint256 tpftAmount, bytes calldata data) external;

    /**
     * Função para obter o ID do título.
     * @param tpftData Estrutura de dados do TPFt, que incluem as seguintes informações: <br />- `acronym`: A sigla do TPFt. <br />- `code`: O código único do TPFt. <br />- `maturityDate`: A data de vencimento do TPFt, representada como um valor numérico (timestamp Unix).
     * @return Retorna o ID do título.
     * Se não existir um TPFt com as informações fornecidas, o valor retornado será 0.
     */
    function getTPFtId(ITPFt.TPFtData memory tpftData) external view returns (uint256);

    /**
     * Função para realizar uma operação de queima de TPFt.
     * @param from Endereço da carteira de origem da operação de queima de TPFts.
     * @param tpftId Id dos TPFts.
     * @param tpftAmount Quantidade de TPFt a ser queimada na operação.
     */
    function burn(address from, uint256 tpftId, uint256 tpftAmount, bytes calldata data) external;

    /**
     * Função para realizar uma operação de queima em lotes de TPFts.
     * @param from Endereço da carteira de origem da operação de queima de TPFt.
     * @param tpftIds Ids dos TPFts.
     * @param tpftAmounts Quantidades de TPFts a serem queimados na operação.
     */
    function burnBatch(address from, uint256[] memory tpftIds, uint256[] memory tpftAmounts, bytes calldata data) external;

    /**
     * Função externa que define ou revoga o status de aprovação para todas as operações de TPFt de um dado endereço.
     * @param originalSender Endereço da carteira dona do TPFt.
     * @param wallet Endereço da carteira para a qual se deseja definir ou revogar o status de aprovação.
     * @param status Estado de aprovação desejado: true para aprovar todas as operações, false para revogar a aprovação.
     */
    function setApprovalForAll(address originalSender, address wallet, bool status) external;

    /**
     * Função externa para obter o número de casas decimais do TPFt.
     * @return Número de casas decimais que para o TPFt será de 2.
     */
    function decimals() external view returns (uint256);

    /**
     * Função para incrementar tokens parcialmente bloqueados de uma carteira. Somente quem possuir FREEZER_ROLE pode executar.
     * @param from Endereço da carteira que os ativos serão bloqueados.
     * @param tpftId ID do TPFt
     * @param tpftAmount Quantidade de TPFt.
     */
    function increaseFrozenBalance(address from, uint256 tpftId, uint256 tpftAmount) external;

    /**
     * Função para decrementar tokens parcialmente bloqueados de uma carteira. Somente quem possuir FREEZER_ROLE pode executar.
     * @param from Endereço da carteira que os ativos serão desbloqueados.
     * @param tpftId ID do TPFt
     * @param tpftAmount Quantidade de TPFt.
     */
    function decreaseFrozenBalance(address from, uint256 tpftId, uint256 tpftAmount) external;

    /**
     * Função externa utilizada pelo Bacen que é detentor da _ROLE_ DEFAULT_ADMIN_ROLE para colocar o contrato em pausa.
     * Apenas o detentor desse papel pode executar essa função, verificado pelo modificador "onlyRole(DEFAULT_ADMIN_ROLE)".
     * O contrato em pausa bloqueará a execução de funções, garantindo que o contrato possa ser temporariamente interrompido.
     */
    function pause() external;

    /**
     * Função externa utilizada pelo Bacen que é detentor da _ROLE_ DEFAULT_ADMIN_ROLE para retirar o contrato de pausa.
     * Apenas o detentor desse papel pode executar essa função, verificado pelo modificador "onlyRole(DEFAULT_ADMIN_ROLE)".
     * O contrato retirado de pausa permite a execução normal de todas as funções novamente após ter sido previamente pausado.
     */
    function unpause() external;

    /**
     * Função externa que permite definir o status de pagamento para um determinado endereço da carteira e ID de TPFt.
     * Apenas contas com a Role REPAYMENT_ROLE têm permissão para utilizar esta função.
     * @param account Endereço da carteira para o qual o status de pagamento será definido.
     * @param tpftId ID do TPFt para o qual o status de pagamento será definido.
     * @param status Status de pagamento a ser definido (verdadeiro para pago, falso para não pago).
     */
    function setPaymentStatus(address account, uint256 tpftId, bool status) external;

    /**
     * Função externa que retorna o status de pagamento para um determinado endereço da carteira e ID de TPFt.
     * @param account Endereço da carteira para a qual o status de pagamento está sendo consultado.
     * @param tpftId ID do TPFt para o qual o status de pagamento está sendo consultado.
     * @return Retorna true se o pagamento foi efetuado, false se não foi.
     */
    function getPaymentStatus(address account, uint256 tpftId) external view returns (bool);

    /**
     * Função externa que permite definir o status de pausa para um determinado ID de TPFt.
     * Apenas contas com a Role REPAYMENT_ROLE têm permissão para utilizar esta função.
     * @param tpftId ID do TPFt para o qual o status de pausa será ajustado.
     * @param status Status de pausa a ser definido (verdadeiro para pausado, falso para não pausado).
     */
    function setTpftIdToPaused(uint256 tpftId, bool status) external;

    /**
     * Função externa que retorna o status de pausa para um determinado ID de TPFt.
     * @param tpftId ID do TPFt para o qual o status de pausa está sendo consultado.
     * @return Retorna true se o TPFt está pausado para operações, false se não está.
     */
    function isTpftIdPaused(uint256 tpftId) external view returns (bool);
}

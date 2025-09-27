// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

/**
 * @title ITPFt
 * @author BCB
 * @notice Interface responsável pela criação e emissão de Título Público Federal tokenizado (TPFt).
 */
interface ITPFt is IAccessControl, IERC1155 {
    /**
     * @param tpftData Estrutura de dados do TPFt, que incluem as seguintes informações: <br />- `acronym`: A sigla do TPFt. <br />- `code`: O código único do TPFt. <br />- `maturityDate`: A data de vencimento do TPFt, representada como um valor numérico (timestamp Unix).
     */
    struct TPFtData {
        string acronym;
        string code;
        uint256 maturityDate;
    }

    /**
     * Erro lançado porque a ação só pode ser realizada pelo contrato de colocação direta de TPFts.
     */
    error OnlyMinterContract();

    /**
     * Erro lançado porque a ação só pode ser realizada pelo contrato de colocação direta de TPFts.
     */
    error OnlyDirectPlacementContract();

    /**
     * Evento que indica uma alteração de status de uma conta no TPFt.
     * @param operator Endereço do operador que efetuou a alteração.
     * @param operatorCnpj8 CNPJ8 do operador que efetuou a alteração.
     * @param account Endereço da carteira que terá o status alterado no TPFt.
     * @param operatorIsCnpj8 Indica se o operador é um CNPJ8.
     * @param isEnabled Indica se a carteira está habilitada para operações.
     */
    event TPFtAccountStatusChanged(address indexed operator, uint256 indexed operatorCnpj8, address indexed account, bool operatorIsCnpj8, bool isEnabled);

    /**
     * Função externa que retorna o nome do token.
     * @return Retorna uma string contendo o nome do token.
     */
    function name() external view returns (string memory);

    /**
     * Função externa que retorna a quantidade de TPFt criados
     * @return Retorna o numero com o total de TPFt criados
     */
    function getTPFtTotals() external view returns (uint256);

    /**
     * Função para obter o ID do título.
     * @param tpftData Estrutura de dados do TPFt, que incluem as seguintes informações: <br />- `acronym`: A sigla do TPFt. <br />- `code`: O código único do TPFt. <br />- `maturityDate`: A data de vencimento do TPFt, representada como um valor numérico (timestamp Unix).
     * @return Retorna o ID do título.
     * Se não existir um TPFt com as informações fornecidas, o valor retornado será 0.
     */
    function getTPFtId(TPFtData memory tpftData) external view returns (uint256);

    /**
     * Função externa que consulta e retorna o total de TPFt disponíveis para um Id de TPFt específico.
     * @param tpftId Id de TPFt para o qual se deseja consultar o total de TPFt disponíveis.
     */
    function totalSupply(uint256 tpftId) external view returns (uint256);

    /**
     * Função para criar um novo TPFt.
     * @param tpftData Estrutura de dados do TPFt, que incluem as seguintes informações: <br />- `acronym`: A sigla do TPFt. <br />- `code`: O código único do TPFt. <br />- `maturityDate`: A data de vencimento do TPFt, representada como um valor numérico (timestamp Unix).
     */
    function createTPFt(TPFtData memory tpftData) external;

    /**
     * Função para emitir TPFt.
     * @param receiverAddress Endereço do cessionário da operação. Nesta operação sempre será o endereço da STN.
     * @param tpftId Id do TPFt
     * @param tpftAmount Quantidade de TPFt a ser emitida.
     */
    function mint(address receiverAddress, uint256 tpftId, uint256 tpftAmount) external;

    /**
     * Função para emitir TPFt.
     * @param receiverAddress Endereço do cessionário da operação. Nesta operação sempre será o endereço da STN.
     * @param tpftData Estrutura de dados do TPFt, que incluem as seguintes informações: <br />- `acronym`: A sigla do TPFt. <br />- `code`: O código único do TPFt. <br />- `maturityDate`: A data de vencimento do TPFt, representada como um valor numérico (timestamp Unix).
     * @param tpftAmount Quantidade de TPFt a ser emitida.
     */
    function mint(address receiverAddress, ITPFt.TPFtData memory tpftData, uint256 tpftAmount) external;

    /**
     * Função para realizar uma operação de colocação direta de TPFt.
     * @param from Endereço da carteira de origem da operação de colocação direta.
     * @param to Endereço da carteira de destino da operação de colocação direta.
     * @param tpftData Estrutura de dados do TPFt, que incluem as seguintes informações: <br />- `acronym`: A sigla do TPFt. <br />- `code`: O código único do TPFt. <br />- `maturityDate`: A data de vencimento do TPFt, representada como um valor numérico (timestamp Unix).
     * @param tpftAmount Quantidade de TPFt a ser enviada na operação de colocação direta.
     */
    function directPlacement(address from, address to, ITPFt.TPFtData memory tpftData, uint256 tpftAmount) external;

    /**
     * Função externa para transferir TPFts.
     * @param from Endereço da carteira de origem da operação de colocação direta.
     * @param to Endereço da carteira de destino da operação de colocação direta.
     * @param tpftData Estrutura de dados do TPFt, que incluem as seguintes informações: <br />- `acronym`: A sigla do TPFt. <br />- `code`: O código único do TPFt. <br />- `maturityDate`: A data de vencimento do TPFt, representada como um valor numérico (timestamp Unix).
     * @param tpftAmount Quantidade de TPFt a ser enviada na operação de colocação direta.
     */
    function safeTransferFrom(address from, address to, ITPFt.TPFtData memory tpftData, uint256 tpftAmount) external;

    /**
     * Função para realizar uma operação de transferência em lotes de TPFts.
     * @param from Endereço da carteira de origem da operação de transfêrencia em lotes de TPFts.
     * @param to Endereço da carteira de destino da operação de transfêrencia em lotes de TPFts.
     * @param tpftDataList Lista de tpftData a serem enviados na operação.
     * @param tpftAmounts Quantidades de TPFts a serem enviada na operação.
     */
    function safeBatchTransferFromForTPFt(address from, address to, ITPFt.TPFtData[] memory tpftDataList, uint256[] memory tpftAmounts, bytes calldata data) external;

    /**
     * Função para realizar uma operação de transferência em lotes de TPFts.
     * @param from Endereço da carteira de origem da operação de transfêrencia em lotes de TPFts.
     * @param to Endereço da carteira de destino da operação de transfêrencia em lotes de TPFts.
     * @param tpftIds Ids dos TPFts.
     * @param tpftAmounts Quantidades de TPFts a serem enviada na operação.
     */
    function safeBatchTransferFrom(address from, address to, uint256[] memory tpftIds, uint256[] memory tpftAmounts, bytes calldata data) external;

    /**
     * Função para realizar a baixa de um TPFt pelo seu ID.
     * @param from Endereço da carteira que será realizada a baixa do TPFt.
     * @param tpftId ID do TPFt.
     * @param tpftAmount Quantidade de TPFt a ser realizada a baixa.
     */
    function burn(address from, uint256 tpftId, uint256 tpftAmount) external;

    /**
     * Função para realizar a baixa de um TPFt pelo TPFtData.
     * @param from Endereço da carteira que será realizada a baixa do TPFt.
     * @param tpftData Estrutura de dados do TPFt, que incluem as seguintes informações: <br />- `acronym`: A sigla do TPFt. <br />- `code`: O código único do TPFt. <br />- `maturityDate`: A data de vencimento do TPFt, representada como um valor numérico (timestamp Unix).
     * @param tpftAmount Quantidade de TPFt a ser realizada a baixa.
     */
    function burn(address from, ITPFt.TPFtData memory tpftData, uint256 tpftAmount) external;

    /**
     * Função para realizar uma operação de queima em lotes de TPFts.
     * @param from Endereço da carteira de origem da operação de queima de TPFt.
     * @param tpftIds Ids dos TPFts.
     * @param tpftAmounts Quantidades de TPFts a serem queimados na operação.
     */
    function burnBatch(address from, uint256[] memory tpftIds, uint256[] memory tpftAmounts) external;

    /**
     * Função externa para obter o número de casas decimais do TPFt.
     * @return Número de casas decimais que para o TPFt será de 2.
     */
    function decimals() external view returns (uint256);

    /**
     * Função para incrementar tokens parcialmente bloqueados de uma carteira. Somente quem possuir FREEZER_ROLE pode executar.
     * @param from Endereço da carteira que os ativos serão bloqueados.
     * @param tpftData Estrutura de dados do TPFt, que incluem as seguintes informações: <br />- `acronym`: A sigla do TPFt. <br />- `code`: O código único do TPFt. <br />- `maturityDate`: A data de vencimento do TPFt, representada como um valor numérico (timestamp Unix).
     * @param tpftAmount Quantidade de TPFt.
     */
    function increaseFrozenBalance(address from, ITPFt.TPFtData memory tpftData, uint256 tpftAmount) external;

    /**
     * Função para decrementar tokens parcialmente bloqueados de uma carteira. Somente quem possuir FREEZER_ROLE pode executar.
     * @param from Endereço da carteira que os ativos serão desbloqueados.
     * @param tpftData Estrutura de dados do TPFt, que incluem as seguintes informações: <br />- `acronym`: A sigla do TPFt. <br />- `code`: O código único do TPFt. <br />- `maturityDate`: A data de vencimento do TPFt, representada como um valor numérico (timestamp Unix).
     * @param tpftAmount Quantidade de TPFt.
     */
    function decreaseFrozenBalance(address from, ITPFt.TPFtData memory tpftData, uint256 tpftAmount) external;

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
   * Função de consulta para verificar condição de pause no storage.
   */
    function isPaused() external returns (bool);

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

    /**
     * Função para validar se um endereço de carteira está habilitado para participar da operação.
     * @param wallet Endereço da carteira que participa da operação.
     * @return Retorna true se o endereço estiver habilitado para participar, caso contrário, false.
     */
    function isEnabledAddress(address wallet) external view returns (bool);

    /**
     * Função para habilitar um endereço de carteira a operar no piloto Real Digital Selic.
     * @param wallet Carteira a ser habilitada
     */
    function enableAddress(address wallet) external;

    /**
     * @notice Habilita um endereço de carteira para participar da operação.
     * @param cnpj8 CNPJ8 do participante que vai habilitar a carteira.
     * @param wallet Endereço da carteira que será habilitada.
     */
    function enableAddress(uint256 cnpj8, address wallet) external;

    /**
     * Função para desabilitar um endereço de carteira a operar no piloto Real Digital Selic.
     * @param wallet Carteira a ser desabilita
     */
    function disableAddress(address wallet) external;

    /**
     * Função externa que retorna o endereço do contrato TPFtOperation1012.
     */
    function getTpft1012OperationContractAddress() external view returns (address);

    /**
     * @notice Retorna uma lista paginada de detentores de um token específico.
     * @param tokenId O ID do token ERC1155.
     * @param offset Índice inicial da paginação.
     * @param limit Número máximo de endereços a serem retornados.
     * @return paginatedHolders Lista paginada de endereços dos detentores do token.
     */
    function getHolders(uint256 tokenId, uint256 offset, uint256 limit) external view returns (address[] memory);

    /**
     * @notice Retorna o número total de detentores de um token.
     * @param tokenId O ID do token ERC1155.
     */
    function getTotalHolders(uint256 tokenId) external view returns (uint256);
}

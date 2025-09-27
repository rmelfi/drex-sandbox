// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import {IERC1155} from "@openzeppelin/contracts/interfaces/IERC1155.sol";
import {IERC165} from "@openzeppelin/contracts/interfaces/IERC165.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {Pausable} from "@openzeppelin/contracts/security/Pausable.sol";
import {ERC1155Supply} from "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import {Counters} from "@openzeppelin/contracts/utils/Counters.sol";
import {ITPFt} from "./ITPFt.sol";
import {ITPFtStorage} from "./ITPFtStorage.sol";
import {ERC1155Custom} from "./lib/ERC1155Custom.sol";

/**
 * @title TPFtStorage
 * @author BCB
 * @notice _Smart Contract_ responsável de armazenar informações de Título Público Federal tokenizado (TPFt).
 */
contract TPFtStorage is ITPFtStorage, Pausable, ERC1155Custom, AccessControl {
    /**
     * @dev Biblioteca que incrementa e decrementa números sequências
     */
    using Counters for Counters.Counter;

    /**
     * _String_ nome do contrato
     */
    string private _name;

    /**
     * _Constant_ Número de casas decimais para o TPFt
     */
    uint8 constant DECIMALS = 2;

    /**
     * _Counter_ total de TPFt
     */
    Counters.Counter private _totalTpft;

    /**
     * _Mapping_ para guardar o id do TPFt
     */
    mapping(bytes32 => uint256) private _tpftMap;

    /**
     * _Mapping_ público que armazena os saldos de ativos bloqueados do TPFt para cada endereço e operação específica.
     */
    mapping(address => mapping(uint256 => uint256)) private frozenBalanceOf;

    /**
     * _Mapping_ privado que registra se um endereço recebeu o pagamento por uma operação de resgate
     * de TPFts.
     * Para cada endereço e ID de TPFt, o valor booleano indica se o pagamento foi efetuado.
     */
    mapping(address => mapping(uint256 => bool)) private paymentStatus;

    /**
     * _Mapping_ privado que registra se um ID de TPFt está pausado para operações de TPFts.
     * Para cada ID de TPFt, o valor booleano indica se o TPFt foi pausado para operações.
     */
    mapping(uint256 => bool) private tpftIdPaused;

    /**
     * Endereço do contrato de lógica do TPFt.
     */
    address private _tpftLogicContract;

    // Mapeamento de IDs de token para listas de endereços de detentores
    mapping(uint256 => address[]) private _holdersAddress;

    // _Mapping_ do ID do token para o endereço do detentor indexado em _holdersAddress
    mapping(uint256 => mapping(address => uint256)) private _holderIndex;

    // Mapeamento de Ids de TPFt para a quantidade de TPFt que será verificada no saldo congelado
    mapping(uint256 => uint256) private uniqueAmountPerIdForCheckFrozenBalance;

    /**
     * @notice Inicializa o contrato TPFtStorage com os endereços fornecidos e configura as permissões iniciais.
     * @param admin_ Endereço da carteira do administrador.
     */
    constructor(address admin_) ERC1155Custom("") {
        _name = "TPFt";
        _totalTpft.reset();
        _setupRole(DEFAULT_ADMIN_ROLE, admin_);
    }

    /**
     * Modificador que verifica se um endereço possui saldo disponivel para realizar a operação.
     */
    modifier checkFrozenBalance(
        address from,
        uint256[] memory ids,
        uint256[] memory tpftAmounts
    ) {
        for (uint256 i = 0; i < ids.length; i++) {
            uniqueAmountPerIdForCheckFrozenBalance[ids[i]] += tpftAmounts[i];
        }

        for (uint256 i = 0; i < ids.length; i++) {
            if (
                frozenBalanceOf[from][ids[i]] > 0 &&
                uniqueAmountPerIdForCheckFrozenBalance[ids[i]] > 0
            ) {
                uint256 amountToBeUsed = uniqueAmountPerIdForCheckFrozenBalance[
                    ids[i]
                ];
                require(
                    balanceOf(from, ids[i]) >=
                        amountToBeUsed + frozenBalanceOf[from][ids[i]],
                    "TPFt: minimum balance reached"
                );
            }
            uniqueAmountPerIdForCheckFrozenBalance[ids[i]] = 0;
        }
        _;
    }

    /**
     * Modificador que permite que apenas o contrato de Lógica do TPFt execute a função decorada.
     * Verifica se o chamador da função é o contrato de Lógica autorizado (_getTPFtLogicAddress()),
     * caso contrário, a transação será revertida com a mensagem "Unauthorized wallet to perform the operation".
     */
    modifier onlyTPFtLogicContract() {
        if (_msgSender() != _getTPFtLogicAddress()) {
            revert("Unauthorized wallet to perform the operation");
        }
        _;
    }

    /**
     * Função pública que verifica se o contrato suporta uma interface específica.
     * @param interfaceId ID da interface a ser verificado.
     */
    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        virtual
        override(ERC1155Custom, AccessControl, IERC165)
        returns (bool)
    {
        return
            ERC1155Custom.supportsInterface(interfaceId) &&
            AccessControl.supportsInterface(interfaceId) &&
            _supportsInterface(interfaceId);
    }

    /**
     * Função interna que verifica se o contrato suporta uma interface específica.
     * @param interfaceId ID da interface a ser verificado.
     */
    function _supportsInterface(
        bytes4 interfaceId
    ) internal pure returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }

    /**
     * Função externa que retorna o nome do token.
     * @return Retorna uma string contendo o nome do token.
     */
    function name()
        external
        view
        override
        onlyTPFtLogicContract
        returns (string memory)
    {
        return _name;
    }

    /**
     * Função externa que retorna a quantidade de TPFt criados
     * @return Retorna o numero com o total de TPFt criados
     */
    function getTPFtTotals()
        external
        view
        override
        onlyTPFtLogicContract
        returns (uint256)
    {
        return _totalTpft.current();
    }

    /**
     * Função externa que para salvar (setar) o Número de operação + data vigente no formato yyyyMMdd do TPFt com base nos dados específicos
     * do TPFts fornecidos como parâmetro (tpftData).
     * @param tpftData Estrutura de dados do TPFt, que incluem as seguintes informações: <br />- `acronym`: A sigla do TPFt. <br />- `code`: O código único do TPFt. <br />- `maturityDate`: A data de vencimento do TPFt, representada como um valor numérico (timestamp Unix).
     */
    function createTPFt(
        ITPFt.TPFtData memory tpftData
    ) external override whenNotPaused onlyTPFtLogicContract {
        _totalTpft.increment();
        _tpftMap[keccak256(abi.encode(tpftData))] = _totalTpft.current();
    }

    /**
     * Função externa para obter o ID do título.
     * @param tpftData Estrutura de dados do TPFt, que incluem as seguintes informações: <br />- `acronym`: A sigla do TPFt. <br />- `code`: O código único do TPFt. <br />- `maturityDate`: A data de vencimento do TPFt, representada como um valor numérico (timestamp Unix).
     * @return Retorna o ID do título.
     *         Se não existir um TPFt com as informações fornecidas, o valor retornado será 0.
     */
    function getTPFtId(
        ITPFt.TPFtData memory tpftData
    ) external view override returns (uint256) {
        return _tpftMap[keccak256(abi.encode(tpftData))];
    }

    /**
     * Função externa para criar um novo TPFt.
     * @param receiverAddress Endereço do cessionarário da operação que é a carteira da STN.
     * @param tpftId Id do TPFt.
     * @param tpftAmount Quantidade de TPFt a ser emitida.
     */
    function mint(
        address receiverAddress,
        uint256 tpftId,
        uint256 tpftAmount,
        bytes memory data
    ) external override onlyTPFtLogicContract {
        _mint(receiverAddress, tpftId, tpftAmount, data);
    }

    /**
     * Função externa para transferir TPFts.
     * @param from Endereço da carteira de origem da operação de colocação direta.
     * @param to Endereço da carteira de destino da operação de colocação direta.
     * @param tpftId Id do TPFt.
     * @param tpftAmount Quantidade de TPFt a ser enviada na operação de colocação direta.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tpftId,
        uint256 tpftAmount,
        bytes memory data
    ) public virtual override(ERC1155Custom, IERC1155) onlyTPFtLogicContract {
        _safeTransferFrom(from, to, tpftId, tpftAmount, data);
    }

    /**
     * Função para realizar uma operação de transferência em lotes de TPFts.
     * @param from Endereço da carteira de origem da operação de transfêrencia em lotes de TPFts.
     * @param to Endereço da carteira de destino da operação de transfêrencia em lotes de TPFts.
     * @param tpftIds Ids dos TPFts.
     * @param tpftAmounts Quantidades de TPFts a serem enviada na operação.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory tpftIds,
        uint256[] memory tpftAmounts,
        bytes memory data
    ) public virtual override(ERC1155Custom, IERC1155) onlyTPFtLogicContract {
        _safeBatchTransferFrom(from, to, tpftIds, tpftAmounts, data);
    }

    /**
     * Função para realizar uma operação de queima de TPFt.
     * @param from Endereço da carteira de origem da operação de queima de TPFts.
     * @param tpftId Id dos TPFts.
     * @param tpftAmount Quantidade de TPFt a ser queimada na operação.
     */
    function burn(
        address from,
        uint256 tpftId,
        uint256 tpftAmount,
        bytes calldata data
    ) external override onlyTPFtLogicContract {
        _burn(from, tpftId, tpftAmount, data);
    }

    /**
     * Função para realizar uma operação de queima em lotes de TPFts.
     * @param from Endereço da carteira de origem da operação de queima de TPFt.
     * @param tpftIds Ids dos TPFts.
     * @param tpftAmounts Quantidades de TPFts a serem queimados na operação.
     */
    function burnBatch(
        address from,
        uint256[] memory tpftIds,
        uint256[] memory tpftAmounts,
        bytes calldata data
    ) external override onlyTPFtLogicContract {
        _burnBatch(from, tpftIds, tpftAmounts, data);
    }

    /**
     * Função externa que define ou revoga o status de aprovação para todas as operações de TPFt de um dado endereço.
     * @param originalSender Endereço da carteira dona do TPFt.
     * @param wallet Endereço da carteira para a qual se deseja definir ou revogar o status de aprovação.
     * @param status Estado de aprovação desejado: true para aprovar todas as operações, false para revogar a aprovação.
     */
    function setApprovalForAll(
        address originalSender,
        address wallet,
        bool status
    ) external override onlyTPFtLogicContract {
        _setApprovalForAll(originalSender, wallet, status);
    }

    /**
     * Função externa para obter o número de casas decimais do TPFt.
     * @return Número de casas decimais que para o TPFt será de 2.
     */
    function decimals()
        external
        view
        override
        onlyTPFtLogicContract
        returns (uint256)
    {
        return DECIMALS;
    }

    /**
     * Função interna que é chamada depois da transferência de TPFt ocorrer.
     * Sua funcionalidade é realizar verificações adicionais depois da transferência.
     * @param operator Endereço do operador que está realizando a transferência.
     * @param from Endereço de origem do TPFt.
     * @param to Endereço de destino do TPFt.
     * @param ids Array com os identificadores dos TPFts a serem transferidos.
     * @param amounts Array com as quantidades dos TPFts a serem transferidos.
     * @param data Conjunto de dados opcionais.
     */
    function _afterTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override {
        super._afterTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            if (from != address(0)) {
                updateHolder(ids[i], from);
            }

            if (to != address(0)) {
                updateHolder(ids[i], to);
            }
        }
    }

    /**
     * Função interna que é chamada antes da transferência de TPFt ocorrer.
     * Sua funcionalidade é realizar verificações adicionais antes da transferência.
     * @param operator Endereço do operador que está realizando a transferência.
     * @param from Endereço de origem do TPFt.
     * @param to Endereço de destino do TPFt.
     * @param ids Array com os identificadores dos TPFts a serem transferidos.
     * @param tpftAmounts Array com as quantidades dos TPFts a serem transferidos.
     * @param data Conjunto de dados opcionais.
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory tpftAmounts,
        bytes memory data
    )
        internal
        override
        whenNotPaused
        checkFrozenBalance(from, ids, tpftAmounts)
    {
        super._beforeTokenTransfer(operator, from, to, ids, tpftAmounts, data);
    }

    /**
     * Função para aumentar o saldo congelado para um endereço específico e um TPFtId específico
     * @param from Endereço da carteira para a qual será aumentado o saldo de ativos bloqueados.
     * @param tpftId ID do TPFt
     * @param tpftAmount Quantidade de TPFt a ser aumentada no saldo de ativos bloqueados.
     */
    function increaseFrozenBalance(
        address from,
        uint256 tpftId,
        uint256 tpftAmount
    ) external override onlyTPFtLogicContract {
        frozenBalanceOf[from][tpftId] += tpftAmount;
        emit FrozenBalance(from, frozenBalanceOf[from][tpftId]);
    }

    /**
     * Função para diminuir o saldo congelado para um endereço específico e um TPFtId específico
     * @param from Endereço da carteira para a qual será aumentado o saldo de ativos bloqueados.
     * @param tpftId ID do TPFt
     * @param tpftAmount Quantidade de TPFt a ser aumentada no saldo de ativos bloqueados.
     */
    function decreaseFrozenBalance(
        address from,
        uint256 tpftId,
        uint256 tpftAmount
    ) external onlyTPFtLogicContract {
        require(
            frozenBalanceOf[from][tpftId] >= tpftAmount,
            "TPFt: Frozen Balance should be greater than 0"
        );
        frozenBalanceOf[from][tpftId] -= tpftAmount;
        emit FrozenBalance(from, frozenBalanceOf[from][tpftId]);
    }

    /**
     * Função externa que permite definir o status de pagamento para um determinado endereço da carteira e ID de TPFt.
     * @param account Endereço da carteira para o qual o status de pagamento será definido.
     * @param tpftId ID do TPFt para o qual o status de pagamento será definido.
     * @param status Status de pagamento a ser definido (verdadeiro para pago, falso para não pago).
     */
    function setPaymentStatus(
        address account,
        uint256 tpftId,
        bool status
    ) external override onlyTPFtLogicContract {
        paymentStatus[account][tpftId] = status;
    }

    /**
     * Função externa que retorna o status de pagamento para um determinado endereço da carteira e ID de TPFt.
     * @param account Endereço da carteira para a qual o status de pagamento está sendo consultado.
     * @param tpftId ID do TPFt para o qual o status de pagamento está sendo consultado.
     * @return Retorna true se o pagamento foi efetuado, false se não foi.
     */
    function getPaymentStatus(
        address account,
        uint256 tpftId
    ) external view override onlyTPFtLogicContract returns (bool) {
        return paymentStatus[account][tpftId];
    }

    /**
     * Função externa que permite definir o status de pausa para um determinado ID de TPFt.
     * @param tpftId ID do TPFt para o qual o status de pausa será ajustado.
     * @param status Status de pausa a ser definido (verdadeiro para pausado, falso para não pausado).
     */
    function setTpftIdToPaused(
        uint256 tpftId,
        bool status
    ) external override onlyTPFtLogicContract {
        tpftIdPaused[tpftId] = status;
    }

    /**
     * Função interna que valida se os IDs de TPFt fornecidos estão pausados para operações.
     * @param ids Array de IDs de TPFt a serem verificados.
     */
    function _validateTPFtIdIsPaused(uint256[] memory ids) internal view {
        uint256 length = ids.length;
        for (uint256 i = 0; i < length; ) {
            require(
                !tpftIdPaused[ids[i]],
                "TPFt: TPFtId is paused for operations"
            );
            unchecked {
                ++i;
            }
        }
    }

    /**
     * Função externa que retorna o status de pausa para um determinado ID de TPFt.
     * @param tpftId ID do TPFt para o qual o status de pausa está sendo consultado.
     * @return Retorna true se o TPFt está pausado para operações, false se não está.
     */
    function isTpftIdPaused(
        uint256 tpftId
    ) external view override onlyTPFtLogicContract returns (bool) {
        return tpftIdPaused[tpftId];
    }

    /**
     * Função externa para atualizar o endereço do contrato de lógica do TPFt
     * @param tpftLogicContract_ Endereço do novo contrato de lógica do TPFt
     */
    function setTPFtLogicContract(
        address tpftLogicContract_
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _tpftLogicContract = tpftLogicContract_;
    }

    /**
     * Função para obter o saldo congelado para um endereço específico e um TPFtId específico
     * @param from Endereço da carteira para a qual será aumentado o saldo de ativos bloqueados.
     * @param tpftId Id do TPFt
     */
    function getFrozenBalance(
        address from,
        uint256 tpftId
    ) external view onlyTPFtLogicContract returns (uint256) {
        return frozenBalanceOf[from][tpftId];
    }

    /**
     * Função externa para colocar o contrato em pausa.
     * Apenas o detentor desse papel pode executar essa função, verificado pelo modificador "onlyTPFtLogicContract".
     * O contrato em pausa bloqueará a execução de funções, garantindo que o contrato possa ser temporariamente interrompido.
     */
    function pause() external onlyTPFtLogicContract {
        _pause();
    }

    /**
     * Função externa para retirar o contrato de pausa.
     * Apenas o detentor desse papel pode executar essa função, verificado pelo modificador "onlyTPFtLogicContract".
     * O contrato retirado de pausa permite a execução normal de todas as funções novamente após ter sido previamente pausado.
     */
    function unpause() external onlyTPFtLogicContract {
        _unpause();
    }

    /**
     * @notice Atualiza a lista de detentores do token verificando seus saldos no contrato de lógica.
     * @param tokenId O ID do token.
     * @param account endereço a ser verificado.
     */
    function updateHolder(uint256 tokenId, address account) internal {
        uint256 balance = balanceOf(account, tokenId);

        if (balance == 0) {
            _removeHolder(tokenId, account);
        } else {
            _addHolder(tokenId, account);
        }
    }

    /**
     * @notice Retorna uma lista paginada de detentores de um token específico.
     * @param tokenId O ID do token ERC1155.
     * @param offset Índice inicial da paginação.
     * @param limit Número máximo de endereços a serem retornados.
     * @return paginatedHolders Lista paginada de endereços dos detentores do token.
     */
    function getHolders(
        uint256 tokenId,
        uint256 offset,
        uint256 limit
    ) external view onlyTPFtLogicContract returns (address[] memory) {
        uint256 totalHolders = _holdersAddress[tokenId].length;

        (offset, limit) = _adjustPagination(offset, limit, totalHolders);

        if (limit == 0) {
            return new address[](0);
        }

        address[] memory paginatedHolders = new address[](limit);

        for (uint256 i = 0; i < limit; ++i) {
            paginatedHolders[i] = _holdersAddress[tokenId][offset + i];
        }

        return paginatedHolders;
    }

    /**
     * @notice Retorna o número total de detentores de um token.
     * @param tokenId O ID do token ERC1155.
     */
    function getTotalHolders(
        uint256 tokenId
    ) external view onlyTPFtLogicContract returns (uint256) {
        return _holdersAddress[tokenId].length;
    }

    /**
     * @notice Adiciona um endereço à lista de detentores de um token, se ainda não estiver presente.
     * @param id O ID do token.
     * @param holder O endereço do detentor.
     */
    function _addHolder(uint256 id, address holder) internal {
        if (!_holderExists(id, holder)) {
            _holderIndex[id][holder] = _holdersAddress[id].length; // Registra o índice do novo holder
            _holdersAddress[id].push(holder); // Adiciona o endereço à lista de detentores
        }
    }

    /**
     * @notice Remove um endereço da lista de detentores de um token.
     * @param id O ID do token.
     * @param holder O endereço a ser removido.
     */
    function _removeHolder(uint256 id, address holder) internal {
        if (_holderExists(id, holder)) {
            uint256 index = _holderIndex[id][holder];
            uint256 lastIndex = _holdersAddress[id].length - 1;
            address lastHolder = _holdersAddress[id][lastIndex];

            _holdersAddress[id][index] = lastHolder;
            _holderIndex[id][lastHolder] = index;

            _holdersAddress[id].pop();
            delete _holderIndex[id][holder];
        }
    }

    /**
     * @dev Ajusta os parâmetros de paginação para se encaixarem dentro dos limites de um array.
     * @param offset O índice inicial para a paginação.
     * @param limit O número máximo de itens a serem incluídos na paginação.
     * @param arrayLength O número total de itens no array.
     * @return Os valores ajustados de offset e limit.
     */
    function _adjustPagination(
        uint256 offset,
        uint256 limit,
        uint256 arrayLength
    ) private pure returns (uint256, uint256) {
        if (offset >= arrayLength) {
            return (arrayLength, 0);
        }
        if (limit > arrayLength - offset) {
            limit = arrayLength - offset;
        }
        return (offset, limit);
    }

    /**
     * @notice Verifica se um endereço já é um detentor registrado do token.
     * @param id O ID do token.
     * @param holder O endereço a ser verificado.
     * @return True se o holder existir, False caso contrário.
     */
    function _holderExists(
        uint256 id,
        address holder
    ) private view returns (bool) {
        return (_holderIndex[id][holder] > 0 ||
            (_holdersAddress[id].length > 0 &&
                _holdersAddress[id][0] == holder));
    }

    /**
     * Função privada que retorna o Número de operação + data vigente no formato yyyyMMdd do TPFt com base nos dados específicos
     * do TPFts fornecidos como parâmetro (tpftData).
     * @param tpftData Estrutura de dados do TPFt, que incluem as seguintes informações: <br />- `acronym`: A sigla do TPFt. <br />- `code`: O código único do TPFt. <br />- `maturityDate`: A data de vencimento do TPFt, representada como um valor numérico (timestamp Unix).
     * @return Retorna o número de operação + data vigente no formato yyyyMMdd do TPFt associado aos dados fornecidos.
     *         Se não existir um TPFt com as informações fornecidas, o valor retornado será 0.
     */
    function _getTPFtId(
        ITPFt.TPFtData memory tpftData
    ) private view returns (uint256) {
        return _tpftMap[keccak256(abi.encode(tpftData))];
    }

    /**
     * Função externa que retorna o endereço do TPFtLogic.
     */
    function _getTPFtLogicAddress() private view returns (address) {
        return _tpftLogicContract;
    }

    /**
     * Função externa que retorna o endereço do TPFtLogic.
     */
    function getTPFtLogicAddress() external view returns (address) {
        return _tpftLogicContract;
    }
}

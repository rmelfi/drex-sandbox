// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import {Initializable} from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";
import {Context} from "@openzeppelin/contracts/utils/Context.sol";
import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import {IERC1155MetadataURI} from "@openzeppelin/contracts/token/ERC1155/extensions/IERC1155MetadataURI.sol";
import {ITPFt} from "./ITPFt.sol";
import {TPFtStorage} from "./TPFtStorage.sol";
import {TPFtAccessControl} from "./access/TPFtAccessControl.sol";
import {FREEZER_ROLE, REPAYMENT_ROLE, REAL_DIGITAL_DEFAULT_ACCOUNT_IDENTIFIER} from "./lib/TPFtConstants.sol";
import {RealDigital} from "../realdigital/RealDigital.sol";
import {AddressDiscoveryUtils} from "./utils/AddressDiscoveryUtils.sol";
import {AddressDiscovery} from "../realdigital/AddressDiscovery.sol";
import {RealDigitalDefaultAccount} from "../realdigital/RealDigitalDefaultAccount.sol";

contract TPFtLogic is ITPFt, Context, Initializable, UUPSUpgradeable {
    using AddressDiscoveryUtils for AddressDiscovery;

    /**
     * Endereço do contrato TPFtStorage.
     */
    address private _tpftStorage;

    /**
     * Endereço do contrato TPFtAccessControl.
     */
    address private _tpftAccessControl;

    /**
     * Variável constante privada para indicar a versão do contrato
     */
    uint8 private constant _version = 1;

    /**
     * Contrato AddressDiscovery.
     */
    AddressDiscovery private _addressDiscovery;

    constructor() {
        _disableInitializers();
    }

    /**
     * Inicializa o contrato com os endereços fornecidos para TPFtStorage e TPFtAccessControl.
     * @param admin_ Endereço do ADMIN do contrato.
     * @param tpftStorage_ Endereço do contrato TPFtStorage.
     * @param tpftAccessControl_ Endereço do contrato TPFtAccessControl.
     * @param addressDiscovery_ Endereço do contrato AddressDiscovery.
     */
    function initialize(
        address admin_,
        address tpftStorage_,
        address tpftAccessControl_,
        address addressDiscovery_
    ) public initializer {
        __tpftLogic_init(
            admin_,
            tpftStorage_,
            tpftAccessControl_,
            addressDiscovery_
        );
    }

    /**
     * Modificador para restringir o acesso apenas ao proprietário do contrato.
     */
    modifier onlyOwner() {
        if (_msgSender() != _getAdmin()) {
            revert("TPFt: Unauthorized wallet to perform update");
        }
        _;
    }

    /**
     * Permite que o proprietário do contrato altere o endereço do administrador.
     * @param newAdmin A carteira do novo administrador.
     */
    function changeAdmin(address newAdmin) external onlyOwner {
        _changeAdmin(newAdmin);
    }

    /**
     * Permite consultar o endereço do administrador.
     */
    function getAdmin() external view returns (address) {
        return _getAdmin();
    }

    /**
     * Função interna para autorizar uma atualização para um novo contrato de implementação TPFtLogic.
     * @param newImplementation Endereço do novo contrato de implementação TPFtLogic.
     */
    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyOwner {}

    /**
     * Inicializa o contrato TPFtLogic com os endereços fornecidos para TPFtStorage e TPFtAccessControl.
     * @param admin_ Endereço da carteira do ADMIN do contrato.
     * @param tpftStorage_ Endereço do contrato TPFtStorage.
     * @param tpftAccessControl_ Endereço do contrato TPFtAccessControl.
     * @param addressDiscovery_ Endereço do contrato AddressDiscovery.
     */
    function __tpftLogic_init(
        address admin_,
        address tpftStorage_,
        address tpftAccessControl_,
        address addressDiscovery_
    ) internal onlyInitializing {
        _tpftStorage = tpftStorage_;
        _tpftAccessControl = tpftAccessControl_;
        _addressDiscovery = AddressDiscovery(addressDiscovery_);
        _changeAdmin(admin_);
    }

    /**
     * Modificador que permite que apenas o contrato de Minter (TPFtOperation1001) do TPFt execute a função decorada.
     * Verifica se o chamador da função é o contrato de Minter autorizado (TPFT_OPERATION_1001_CONTRACT_NAME),
     * caso contrário, a transação será revertida.
     */
    modifier onlyMinterContract() {
        if (
            _msgSender() !=
            _getTPFtAccessControl().getTPFt1001OperationContractAddress()
        ) {
            revert(
                "TPFt: Unauthorized wallet to perform the operation, only minter contract"
            );
        }
        _;
    }

    /**
     * Modificador que permite que apenas o contrato de Minter (TPFtOperation1001) do TPFt execute a função decorada.
     * Verifica se o chamador da função é o contrato de Minter autorizado (TPFT_OPERATION_1001_CONTRACT_NAME),
     * caso contrário, a transação será revertida.
     */
    modifier onlyDvPContract() {
        if (
            _msgSender() != _getTPFtAccessControl().getTPFtDvPContractAddress()
        ) {
            revert(
                "TPFt: Unauthorized wallet to perform the operation, only DvP contract"
            );
        }
        _;
    }

    /**
     * Modificador que permite que apenas o contrato de Colocação Direta (TPFtOperation1070) do TPFt execute a função decorada.
     * Verifica se o chamador da função é o contrato de Colocação Direta autorizado (TPFT_OPERATION_1070_CONTRACT_NAME),
     * caso contrário, a transação será revertida.
     */
    modifier onlyDirectPlacementContract() {
        if (
            _msgSender() !=
            _getTPFtAccessControl().getTPFt1070OperationContractAddress()
        ) {
            revert(
                "TPFt: Unauthorized wallet to perform the operation, only direct placement contract"
            );
        }
        _;
    }

    /**
     * Modificador que permite que apenas o contrato de Resgate (TPFtOperation1012) do TPFt execute a função decorada.
     * Verifica se o chamador da função é o contrato de Resgate autorizado (TPFT_OPERATION_1012_CONTRACT_NAME),
     * caso contrário, a transação será revertida.
     */
    modifier onlyRepaymentContract() {
        if (
            _msgSender() !=
            _getTPFtAccessControl().getTPFt1012OperationContractAddress()
        ) {
            revert(
                "TPFt: Unauthorized wallet to perform the operation, only repayment contract"
            );
        }
        _;
    }

    /**
     * Modificador que valida se o storage foi pausado, só permite prosseguir caso o storage não esteja paused.
     */
    modifier whenStorageNotPaused() {
        if (_getTPFtStorage().paused()) {
            revert("TPFt: TPFt storage is paused");
        }
        _;
    }

    /**
     * Função externa que retorna o nome do token.
     * @return Retorna uma string contendo o nome do token.
     */
    function name() external view virtual override returns (string memory) {
        return _getTPFtStorage().name();
    }

    /**
     * Função externa que retorna a quantidade de TPFt criados
     * @return Retorna o numero com o total de TPFt criados
     */
    function getTPFtTotals() external view override returns (uint256) {
        return _getTPFtStorage().getTPFtTotals();
    }

    /**
     * Função externa que consulta e retorna o Id de TPFt associado aos dados de um TPFt específico.
     * @param tpftData Estrutura de dados do TPFt, que incluem as seguintes informações: <br />- `acronym`: A sigla do TPFt. <br />- `code`: O código único do TPFt. <br />- `maturityDate`: A data de vencimento do TPFt, representada como um valor numérico (timestamp Unix).
     */
    function getTPFtId(
        ITPFt.TPFtData memory tpftData
    ) external view override returns (uint256) {
        return _getTPFtStorage().getTPFtId(tpftData);
    }

    /**
     * Função externa que consulta e retorna o total de TPFt disponíveis para um Id de TPFt específico.
     * @param tpftId Id de TPFt para o qual se deseja consultar o total de TPFt disponíveis.
     */
    function totalSupply(
        uint256 tpftId
    ) external view override returns (uint256) {
        return _getTPFtStorage().totalSupply(tpftId);
    }

    /**
     * Função externa utilizada pelo contrato TPFtOperation1001 para criar um novo TPFt.
     * Verifica se o contrato TPFtOperation1001 é o único autorizado a executá-la usando o modificador "onlyMinterContract".
     * O novo TPFt é criado e armazenado no _Mapping_ de TPFt  com um identificador único gerado a partir dos dados fornecidos.
     * Caso o TPFt com os mesmos dados já exista, a transação será revertida com a exceção "TPFtAlreadyExists(tpftData)".
     * O número total de TPFts é incrementado a cada criação bem-sucedida.
     * @param tpftData Estrutura de dados do TPFt, que incluem as seguintes informações: <br />- `acronym`: A sigla do TPFt. <br />- `code`: O código único do TPFt. <br />- `maturityDate`: A data de vencimento do TPFt, representada como um valor numérico (timestamp Unix).
     */
    function createTPFt(
        ITPFt.TPFtData memory tpftData
    ) external override onlyMinterContract whenStorageNotPaused {
        require(
            _getTPFtStorage().getTPFtId(tpftData) == 0,
            "TPFt already exists"
        );
        _getTPFtStorage().createTPFt(tpftData);
    }

    /**
     * Função externa utilizada pelo contrato TPFtOperation1001 para emitir (mint) TPFt a um cessionário.
     * Verifica se o contrato TPFtOperation1001 é o único autorizado a executá-la usando o modificador "onlyMinterContract".
     * Verifica também se o TPFt com os mesmos dados (tpftData) já foi criado anteriormente, revertendo com a exceção "TPFtDoesNotExists(tpftData)",
     * caso contrário, o TPFt é emitido.
     * O contrato só pode executar a função quando não estiver em pausa, verificado pelo modificador "whenStorageNotPaused".
     * @param receiverAddress Endereço do cessionarário da operação que é a carteira da STN.
     * @param tpftId Id do TPFt
     * @param tpftAmount Quantidade de TPFt a ser emitida.
     */
    function mint(
        address receiverAddress,
        uint256 tpftId,
        uint256 tpftAmount
    ) external override onlyMinterContract whenStorageNotPaused {
        require(tpftId != 0, "TPFt does not exist");
        bytes memory combinedData = abi.encode(_msgSender());
        _getTPFtStorage().mint(
            receiverAddress,
            tpftId,
            tpftAmount,
            combinedData
        );
    }

    /**
     * Função externa utilizada pelo contrato TPFtOperation1001 para emitir (mint) TPFt a um cessionário.
     * Verifica se o contrato TPFtOperation1001 é o único autorizado a executá-la usando o modificador "onlyMinterContract".
     * Verifica também se o TPFt com os mesmos dados (tpftData) já foi criado anteriormente, revertendo com a exceção "TPFtDoesNotExists(tpftData)",
     * caso contrário, o TPFt é emitido.
     * O contrato só pode executar a função quando não estiver em pausa, verificado pelo modificador "whenStorageNotPaused".
     * @param receiverAddress Endereço do cessionarário da operação que é a carteira da STN.
     * @param tpftData Estrutura de dados do TPFt, que incluem as seguintes informações: <br />- `acronym`: A sigla do TPFt. <br />- `code`: O código único do TPFt. <br />- `maturityDate`: A data de vencimento do TPFt, representada como um valor numérico (timestamp Unix).
     * @param tpftAmount Quantidade de TPFt a ser emitida.
     */
    function mint(
        address receiverAddress,
        ITPFt.TPFtData memory tpftData,
        uint256 tpftAmount
    ) external override onlyMinterContract whenStorageNotPaused {
        require(
            _getTPFtStorage().getTPFtId(tpftData) != 0,
            "TPFt does not exist"
        );
        bytes memory combinedData = abi.encode(_msgSender());
        uint256 tpftId = _getTPFtStorage().getTPFtId(tpftData);
        _getTPFtStorage().mint(
            receiverAddress,
            tpftId,
            tpftAmount,
            combinedData
        );
    }

    /**
     * Função externa  para realizar uma operação de colocação direta de TPFt,
     * transferindo uma determinada quantidade (tpftAmount) de TPFts de um endereço de origem (from)
     * para um endereço de destino (to) com base nos dados do TPFt fornecidos como parâmetro.
     * @param from Endereço da carteira de origem da operação de colocação direta.
     * @param to Endereço da carteira de destino da operação de colocação direta.
     * @param tpftData Estrutura de dados do TPFt, que incluem as seguintes informações: <br />- `acronym`: A sigla do TPFt. <br />- `code`: O código único do TPFt. <br />- `maturityDate`: A data de vencimento do TPFt, representada como um valor numérico (timestamp Unix).
     * @param tpftAmount Quantidade de TPFt a ser enviada na operação de colocação direta.
     */
    function directPlacement(
        address from,
        address to,
        ITPFt.TPFtData memory tpftData,
        uint256 tpftAmount
    ) external override onlyDirectPlacementContract {
        uint256 tpftId = _getTPFtStorage().getTPFtId(tpftData);
        _validateTPFtIdIsPaused(_asSingletonArray(tpftId));
        bytes memory combinedData = abi.encode(_msgSender());
        _getTPFtStorage().safeTransferFrom(
            from,
            to,
            tpftId,
            tpftAmount,
            combinedData
        );
    }

    /**
     * Função externa  para realizar uma operação de colocação direta de TPFt,
     * transferindo uma determinada quantidade (tpftAmount) de TPFts de um endereço de origem (from)
     * para um endereço de destino (to) com base nos dados do TPFt fornecidos como parâmetro.
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
        bytes calldata /*data*/
    ) external override onlyDvPContract {
        require(
            from == _msgSender() ||
                _getTPFtStorage().isApprovedForAll(from, _msgSender()),
            "TPFt: Unauthorized wallet to perform the operation"
        );
        _validateTPFtIdIsPaused(_asSingletonArray(tpftId));
        bytes memory combinedData = abi.encode(_msgSender());
        _getTPFtStorage().safeTransferFrom(
            from,
            to,
            tpftId,
            tpftAmount,
            combinedData
        );
    }

    /**
     * Função externa  para realizar uma operação de colocação direta de TPFt,
     * transferindo uma determinada quantidade (tpftAmount) de TPFts de um endereço de origem (from)
     * para um endereço de destino (to) com base nos dados do TPFt fornecidos como parâmetro.
     * @param from Endereço da carteira de origem da operação de colocação direta.
     * @param to Endereço da carteira de destino da operação de colocação direta.
     * @param tpftData Estrutura de dados do TPFt, que incluem as seguintes informações: <br />- `acronym`: A sigla do TPFt. <br />- `code`: O código único do TPFt. <br />- `maturityDate`: A data de vencimento do TPFt, representada como um valor numérico (timestamp Unix).
     * @param tpftAmount Quantidade de TPFt a ser enviada na operação de colocação direta.
     */
    function safeTransferFrom(
        address from,
        address to,
        ITPFt.TPFtData memory tpftData,
        uint256 tpftAmount
    ) external override onlyDvPContract {
        require(
            from == _msgSender() ||
                _getTPFtStorage().isApprovedForAll(from, _msgSender()),
            "TPFt: Unauthorized wallet to perform the operation"
        );

        uint256 tpftId = _getTPFtStorage().getTPFtId(tpftData);
        _validateTPFtIdIsPaused(_asSingletonArray(tpftId));
        bytes memory combinedData = abi.encode(_msgSender());
        _getTPFtStorage().safeTransferFrom(
            from,
            to,
            tpftId,
            tpftAmount,
            combinedData
        );
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
        bytes calldata data
    ) external override onlyDvPContract {
        require(
            from == _msgSender() ||
                _getTPFtStorage().isApprovedForAll(from, _msgSender()),
            "TPFt: Unauthorized wallet to perform the operation"
        );
        _validateTPFtIdIsPaused(tpftIds);
        bytes memory combinedData = abi.encode(_msgSender(), data);
        _getTPFtStorage().safeBatchTransferFrom(
            from,
            to,
            tpftIds,
            tpftAmounts,
            combinedData
        );
    }

    /**
     * Função para realizar uma operação de transferência em lotes de TPFts.
     * @param from Endereço da carteira de origem da operação de transfêrencia em lotes de TPFts.
     * @param to Endereço da carteira de destino da operação de transfêrencia em lotes de TPFts.
     * @param tpftDataList Lista de tpftData a serem enviados na operação.
     * @param tpftAmounts Quantidades de TPFts a serem enviada na operação.
     */
    function safeBatchTransferFromForTPFt(
        address from,
        address to,
        ITPFt.TPFtData[] memory tpftDataList,
        uint256[] memory tpftAmounts,
        bytes calldata data
    ) external override onlyDvPContract {
        require(
            from == _msgSender() ||
                _getTPFtStorage().isApprovedForAll(from, _msgSender()),
            "TPFt: Unauthorized wallet to perform the operation"
        );
        uint256[] memory tpftIds = new uint256[](tpftDataList.length);
        for (uint256 i = 0; i < tpftDataList.length; ++i) {
            tpftIds[i] = _getTPFtStorage().getTPFtId(tpftDataList[i]);
        }
        _validateTPFtIdIsPaused(tpftIds);
        bytes memory combinedData = abi.encode(_msgSender(), data);
        _getTPFtStorage().safeBatchTransferFrom(
            from,
            to,
            tpftIds,
            tpftAmounts,
            combinedData
        );
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
        uint256 tpftAmount
    ) external override onlyRepaymentContract {
        bytes memory combinedData = abi.encode(_msgSender());
        _getTPFtStorage().burn(from, tpftId, tpftAmount, combinedData);
    }

    /**
     * Função para realizar uma operação de queima de TPFt.
     * @param from Endereço da carteira de origem da operação de queima de TPFts.
     * @param tpftData Estrutura de dados do TPFt, que incluem as seguintes informações: <br />- `acronym`: A sigla do TPFt. <br />- `code`: O código único do TPFt. <br />- `maturityDate`: A data de vencimento do TPFt, representada como um valor numérico (timestamp Unix).
     * @param tpftAmount Quantidade de TPFt a ser queimada na operação.
     */
    function burn(
        address from,
        ITPFt.TPFtData memory tpftData,
        uint256 tpftAmount
    ) external override onlyRepaymentContract {
        uint256 tpftId = _getTPFtStorage().getTPFtId(tpftData);
        bytes memory combinedData = abi.encode(_msgSender());
        _getTPFtStorage().burn(from, tpftId, tpftAmount, combinedData);
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
        uint256[] memory tpftAmounts
    ) external override onlyRepaymentContract {
        _validateTPFtIdIsPaused(tpftIds);
        bytes memory combinedData = abi.encode(_msgSender());
        _getTPFtStorage().burnBatch(from, tpftIds, tpftAmounts, combinedData);
    }

    /**
     * Função externa que define ou revoga o status de aprovação para todas as operações de TPFt de um dado endereço.
     * @param wallet Endereço da carteira para a qual se deseja definir ou revogar o status de aprovação.
     * @param status Estado de aprovação desejado: true para aprovar todas as operações, false para revogar a aprovação.
     */
    function setApprovalForAll(address wallet, bool status) external override {
        _getTPFtStorage().setApprovalForAll(_msgSender(), wallet, status);
    }

    /**
     * Função externa que verifica se um operador está aprovado para realizar todas as operações em nome de uma carteira.
     * @param wallet Carteira que se deseja verificar se tem um operador aprovado para todas as operações.
     * @param operator Operador que se deseja verificar se está aprovado para todas as operações em nome da carteira.
     */
    function isApprovedForAll(
        address wallet,
        address operator
    ) external view override returns (bool) {
        return _getTPFtStorage().isApprovedForAll(wallet, operator);
    }

    /**
     * Função externa que consulta o saldo de uma carteira associado a um determinado Id de TPFt.
     * @param wallet Carteira para o qual se deseja consultar o saldo.
     * @param tpftId Id de TPFt correspondente ao saldo a ser consultado.
     */
    function balanceOf(
        address wallet,
        uint256 tpftId
    ) external view override returns (uint256) {
        return _getTPFtStorage().balanceOf(wallet, tpftId);
    }

    /**
     * Função externa que consulta o saldo em lote de um conjunto de carteiras associadas a um grupo de Id's de TPFt.
     * @param wallets Carteiras para o qual se deseja consultar o saldo.
     * @param tpftIds Id's de TPFt correspondente ao saldo a ser consultado.
     */
    function balanceOfBatch(
        address[] calldata wallets,
        uint256[] calldata tpftIds
    ) external view override returns (uint256[] memory) {
        return _getTPFtStorage().balanceOfBatch(wallets, tpftIds);
    }

    /**
     * Função externa para obter o número de casas decimais do TPFt.
     * @return Número de casas decimais que para o TPFt será de 2.
     */
    function decimals() external view override returns (uint256) {
        return _getTPFtStorage().decimals();
    }

    /**
     * Função pública para aumentar o saldo de ativos bloqueados de um endereço de carteira específico (from)
     * para um determinado TPFt com base nos dados do TPFt fornecido como parâmetro
     * e na quantidade (tpftAmount) de TPFts a ser aumentada.
     * A função pode ser chamada apenas pelos detentores do _ROLE_ "FREEZER_ROLE".
     * @param from Endereço da carteira para a qual será aumentado o saldo de ativos bloqueados.
     * @param tpftData Estrutura de dados do TPFt, que incluem as seguintes informações: <br />- `acronym`: A sigla do TPFt. <br />- `code`: O código único do TPFt. <br />- `maturityDate`: A data de vencimento do TPFt, representada como um valor numérico (timestamp Unix).
     * @param tpftAmount Quantidade de TPFt a ser aumentada no saldo de ativos bloqueados.
     */
    function increaseFrozenBalance(
        address from,
        ITPFt.TPFtData memory tpftData,
        uint256 tpftAmount
    ) external override {
        require(
            _getTPFtAccessControl().hasRole(FREEZER_ROLE, _msgSender()),
            "TPFt: Unauthorized wallet to perform the operation"
        );
        uint256 tpftId = _getTPFtStorage().getTPFtId(tpftData);
        require(from != address(0), "TPFt: address cannot be zero");
        require(tpftId > 0, "TPFt: TPFt does not exists");
        _getTPFtStorage().increaseFrozenBalance(from, tpftId, tpftAmount);
    }

    /**
     * Função pública para diminuir o saldo de ativos bloqueados de um endereço de carteira específico (from)
     * para um determinado TPFt com base nos dados do TPFt fornecido como parâmetro
     * e na quantidade (tpftAmount) de TPFts a ser diminuida.
     * A função pode ser chamada apenas pelos detentores do _ROLE_ "FREEZER_ROLE".
     * @param from Endereço da carteira para a qual será diminuído o saldo de ativos bloqueados.
     * @param tpftData Estrutura de dados do TPFt, que incluem as seguintes informações: <br />- `acronym`: A sigla do TPFt. <br />- `code`: O código único do TPFt. <br />- `maturityDate`: A data de vencimento do TPFt, representada como um valor numérico (timestamp Unix).
     * @param tpftAmount Quantidade de TPFt a ser diminuída do saldo de ativos bloqueados.
     */
    function decreaseFrozenBalance(
        address from,
        ITPFt.TPFtData memory tpftData,
        uint256 tpftAmount
    ) external override {
        require(
            _getTPFtAccessControl().hasRole(FREEZER_ROLE, _msgSender()),
            "TPFt: Unauthorized wallet to perform the operation"
        );
        uint256 tpftId = _getTPFtStorage().getTPFtId(tpftData);
        require(from != address(0), "TPFT: address cannot be zero");
        require(tpftId > 0, "TPFt: TPFt does not exists");
        uint256 frozenBalanceOf = _getTPFtStorage().getFrozenBalance(
            from,
            tpftId
        );
        require(
            frozenBalanceOf >= tpftAmount,
            "RealDigital: Frozen Balance should be greater than 0"
        );
        _getTPFtStorage().decreaseFrozenBalance(from, tpftId, tpftAmount);
    }

    /**
     * Função para obter o saldo congelado para um endereço específico e um TPFtId específico
     * @param from Endereço da carteira para a qual será aumentado o saldo de ativos bloqueados.
     * @param tpftId Id do TPFt
     */
    function getFrozenBalance(
        address from,
        uint256 tpftId
    ) external view returns (uint256) {
        require(
            _getTPFtAccessControl().hasRole(FREEZER_ROLE, _msgSender()),
            "TPFt: Unauthorized wallet to perform the operation"
        );
        return _getTPFtStorage().getFrozenBalance(from, tpftId);
    }

    /**
     * Função externa para colocar o contrato em pausa.
     * Apenas o detentor desse papel pode executar essa função, verificado pelo modificador "onlyRole(DEFAULT_ADMIN_ROLE)".
     * O contrato em pausa bloqueará a execução de funções, garantindo que o contrato possa ser temporariamente interrompido.
     */
    function pause() external override {
        require(
            _getTPFtAccessControl().hasRole(
                _getTPFtAccessControl().DEFAULT_ADMIN_ROLE(),
                _msgSender()
            ),
            "TPFt: Unauthorized wallet to perform the operation"
        );
        _getTPFtStorage().pause();
    }

    /**
     * Função externa para retirar o contrato de pausa.
     * Apenas o detentor desse papel pode executar essa função, verificado pelo modificador "onlyRole(DEFAULT_ADMIN_ROLE)".
     * O contrato retirado de pausa permite a execução normal de todas as funções novamente após ter sido previamente pausado.
     */
    function unpause() external override {
        require(
            _getTPFtAccessControl().hasRole(
                _getTPFtAccessControl().DEFAULT_ADMIN_ROLE(),
                _msgSender()
            ),
            "TPFt: Unauthorized wallet to perform the operation"
        );
        _getTPFtStorage().unpause();
    }

    /**
     * Função de consulta para verificar condição de pause no storage.
     */
    function isPaused() external view override returns (bool) {
        return _getTPFtStorage().paused();
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
    ) external override {
        require(
            _getTPFtAccessControl().hasRole(REPAYMENT_ROLE, _msgSender()),
            "TPFt: Unauthorized wallet to perform the operation"
        );
        _getTPFtStorage().setPaymentStatus(account, tpftId, status);
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
    ) external view override returns (bool) {
        return _getTPFtStorage().getPaymentStatus(account, tpftId);
    }

    /**
     * Função externa que permite definir o status de pausa para um determinado ID de TPFt.
     * @param tpftId ID do TPFt para o qual o status de pausa será ajustado.
     * @param status Status de pausa a ser definido (verdadeiro para pausado, falso para não pausado).
     */
    function setTpftIdToPaused(uint256 tpftId, bool status) external override {
        require(
            _getTPFtAccessControl().hasRole(REPAYMENT_ROLE, _msgSender()),
            "TPFt: Unauthorized wallet to perform the operation"
        );
        _getTPFtStorage().setTpftIdToPaused(tpftId, status);
    }

    /**
     * Função externa que retorna o status de pausa para um determinado ID de TPFt.
     * @param tpftId ID do TPFt para o qual o status de pausa está sendo consultado.
     * @return Retorna true se o TPFt está pausado para operações, false se não está.
     */
    function isTpftIdPaused(
        uint256 tpftId
    ) external view override returns (bool) {
        return _getTPFtStorage().isTpftIdPaused(tpftId);
    }

    /**
     * Função para validar se um endereço de carteira está habilitado para participar da operação.
     * @param wallet Endereço da carteira que participa da operação.
     * @return Retorna true se o endereço estiver habilitado para participar, caso contrário, false.
     */
    function isEnabledAddress(
        address wallet
    ) external view override returns (bool) {
        return _getTPFtAccessControl().isEnabledAddress(wallet);
    }

    /**
     * @notice Habilita um endereço de carteira para participar da operação.
     * @param cnpj8 CNPJ8 do participante que vai habilitar a carteira.
     * @param wallet Endereço da carteira que será habilitada.
     */
    function enableAddress(uint256 cnpj8, address wallet) external override {
        require(wallet != address(0), "TPFt: Invalid wallet address");

        address registeredAccount = _getRealDigitalDefaultAccount()
            .defaultAccount(cnpj8);

        require(_msgSender() == registeredAccount, "TPFt: Invalid caller");

        require(
            _getTPFtAccessControl().isEnabledAddress(_msgSender()) &&
                _getRealDigital().verifyAccount(_msgSender()),
            "TPFt: Unauthorized wallet to perform the operation"
        );

        _getTPFtAccessControl().enableAddress(wallet);

        emit TPFtAccountStatusChanged(_msgSender(), cnpj8, wallet, true, true);
    }

    /**
     * Função para habilitar um endereço de carteira para participar da operação.
     * @param wallet Endereço da carteira que participa da operação.
     */
    function enableAddress(address wallet) external override {
        require(
            _getTPFtAccessControl().hasRole(
                _getTPFtAccessControl().DEFAULT_ADMIN_ROLE(),
                _msgSender()
            ),
            "TPFt: Unauthorized wallet to perform the operation"
        );
        _getTPFtAccessControl().enableAddress(wallet);

        emit TPFtAccountStatusChanged(_msgSender(), 0, wallet, false, true);
    }

    /**
     * Desabilita a carteira a operar no piloto Real Digital Selic.
     * @param wallet Carteira a ser desabilita
     */
    function disableAddress(address wallet) external override {
        require(
            _getTPFtAccessControl().hasRole(
                _getTPFtAccessControl().DEFAULT_ADMIN_ROLE(),
                _msgSender()
            ),
            "TPFt: Unauthorized wallet to perform the operation"
        );
        _getTPFtAccessControl().disableAddress(wallet);
    }

    /**
     * Função para conceder uma permissão específica (_ROLE_) a uma carteira.
     * @param role O tipo de permissão (_ROLE_) que será concedido
     * @param wallet Carteira à qual a permissão (_ROLE_) será concedida
     */
    function grantRole(bytes32 role, address wallet) external override {
        require(
            _getTPFtAccessControl().hasRole(
                _getTPFtAccessControl().DEFAULT_ADMIN_ROLE(),
                _msgSender()
            ),
            "TPFt: Unauthorized wallet to perform the operation"
        );
        _getTPFtAccessControl().grantRole(role, wallet);
    }

    /**
     * Função para revogar uma permissão específica (_ROLE_) de uma carteira.
     * @param role O tipo de permissão (_ROLE_) que será revogado
     * @param wallet Carteira à qual a permissão (_ROLE_) será revogada
     */
    function revokeRole(bytes32 role, address wallet) external override {
        require(
            _getTPFtAccessControl().hasRole(
                _getTPFtAccessControl().DEFAULT_ADMIN_ROLE(),
                _msgSender()
            ),
            "TPFt: Unauthorized wallet to perform the operation"
        );
        _getTPFtAccessControl().revokeRole(role, wallet);
    }

    /**
     * Função externa que verifica se uma carteira possui uma _ROLE_ específico.
     * @param role O tipo de permissão (_ROLE_) que se deseja verificar.
     * @param wallet Carteira que se deseja verificar se possui a _ROLE_ especificada
     */
    function hasRole(
        bytes32 role,
        address wallet
    ) external view override returns (bool) {
        return _getTPFtAccessControl().hasRole(role, wallet);
    }

    /**
     * Recupera a __ROLE__ de administrador
     * @param role A __ROLE__ cujo papel de administrador deve ser recuperado.
     */
    function getRoleAdmin(
        bytes32 role
    ) external view override returns (bytes32) {
        return _getTPFtAccessControl().getRoleAdmin(role);
    }

    /**
     * Revoga uma __ROLE__ de uma carteira especificada
     * @param role A __ROLE__ a ser revogada
     * @param wallet Carteira da qual a __ROLE__ será revogada
     */
    function renounceRole(bytes32 role, address wallet) external override {
        _getTPFtAccessControl().renounceRole(role, wallet);
    }

    /**
     * Função externa que retorna o endereço do contrato TPFtOperation1012.
     */
    function getTpft1012OperationContractAddress()
        external
        view
        override
        returns (address)
    {
        return _getTPFtAccessControl().getTPFt1012OperationContractAddress();
    }

    /**
     * Função externa que define/atualiza o endereço do contrato TPFtOperation1001.
     * @param tpftOperation1001ContractAddress_ Novo endereço do contrato TPFtOperation1001.
     */
    function setTpft1001OperationContractAddress(
        address tpftOperation1001ContractAddress_
    ) external {
        require(
            _getTPFtAccessControl().hasRole(
                _getTPFtAccessControl().DEFAULT_ADMIN_ROLE(),
                _msgSender()
            ),
            "Unauthorized wallet to perform the operation -"
        );
        _getTPFtAccessControl().setTPFt1001OperationContractAddress(
            tpftOperation1001ContractAddress_
        );
    }

    /**
     * Função externa que define/atualiza o endereço do contrato TPFtOperation1012.
     * @param tpftOperation1012ContractAddress_ Novo endereço do contrato TPFtOperation1012.
     */
    function setTpft1012OperationContractAddress(
        address tpftOperation1012ContractAddress_
    ) external {
        require(
            _getTPFtAccessControl().hasRole(
                _getTPFtAccessControl().DEFAULT_ADMIN_ROLE(),
                _msgSender()
            ),
            "Unauthorized wallet to perform the operation"
        );
        _getTPFtAccessControl().setTPFt1012OperationContractAddress(
            tpftOperation1012ContractAddress_
        );
    }

    /**
     * Função externa que define/atualiza o endereço do contrato TPFtOperation1070.
     * @param tpftOperation1070ContractAddress_ Novo endereço do contrato TPFtOperation1070.
     */
    function setTpft1070OperationContractAddress(
        address tpftOperation1070ContractAddress_
    ) external {
        require(
            _getTPFtAccessControl().hasRole(
                _getTPFtAccessControl().DEFAULT_ADMIN_ROLE(),
                _msgSender()
            ),
            "Unauthorized wallet to perform the operation"
        );
        _getTPFtAccessControl().setTPFt1070OperationContractAddress(
            tpftOperation1070ContractAddress_
        );
    }

    /**
     * Função externa que define/atualiza o endereço do contrato TPFtDvP.
     * @param tpftDvPContractAddress_ Novo endereço do contrato TPFtDvP.
     */
    function setTPFtDvPContractAddress(
        address tpftDvPContractAddress_
    ) external {
        require(
            _getTPFtAccessControl().hasRole(
                _getTPFtAccessControl().DEFAULT_ADMIN_ROLE(),
                _msgSender()
            ),
            "Unauthorized wallet to perform the operation"
        );
        _getTPFtAccessControl().setTPFtDvPContractAddress(
            tpftDvPContractAddress_
        );
    }

    /**
                _msgSender()
            ),
            "Unauthorized wallet to perform the operation"
        );
        _getTPFtAccessControl().setTPFtDvPContractAddress(
            tpftDvPContractAddress_
        );
    }

    /**
     * Função externa que define/atualiza o endereço do contrato AddressDiscovery.
     * @param addressDiscovery_ Novo endereço do contrato TPFtAccessControl.
     */
    function setAddressDiscovery(AddressDiscovery addressDiscovery_) external {
        require(
            _getTPFtAccessControl().hasRole(
                _getTPFtAccessControl().DEFAULT_ADMIN_ROLE(),
                _msgSender()
            ),
            "Unauthorized wallet to perform the operation"
        );

        _addressDiscovery = addressDiscovery_;
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
    ) external view returns (address[] memory) {
        return _getTPFtStorage().getHolders(tokenId, offset, limit);
    }

    /**
     * @notice Retorna o número total de detentores de um token.
     * @param tokenId O ID do token ERC1155.
     */
    function getTotalHolders(uint256 tokenId) external view returns (uint256) {
        return _getTPFtStorage().getTotalHolders(tokenId);
    }

    /**
     * Função interna que retorna o contrato TPFtStorage.
     */
    function _getTPFtStorage() internal view virtual returns (TPFtStorage) {
        return TPFtStorage(_tpftStorage);
    }

    /**
     * Função interna que retorna o contrato RealDigital.
     */
    function _getRealDigital() internal view virtual returns (RealDigital) {
        return _addressDiscovery.getRealDigital();
    }

    /**
     * Função interna que retorna o contrato TPFtAccessControl.
     */
    function _getTPFtAccessControl()
        internal
        view
        virtual
        returns (TPFtAccessControl)
    {
        return TPFtAccessControl(_tpftAccessControl);
    }

    /**
     * Função interna que retorna o contrato RealDigitalDefaultAccount.
     */
    function _getRealDigitalDefaultAccount()
        internal
        view
        virtual
        returns (RealDigitalDefaultAccount)
    {
        return
            RealDigitalDefaultAccount(
                _addressDiscovery.addressDiscovery(
                    REAL_DIGITAL_DEFAULT_ACCOUNT_IDENTIFIER
                )
            );
    }

    /**
     * Função externa que retorna a versão do contrato de lógica do TPFt
     */
    function getVersion() external pure virtual returns (uint8) {
        return _version;
    }

    /**
     * Função interna que valida se os IDs de TPFt fornecidos estão pausados para operações.
     * @param ids Array de IDs de TPFt a serem verificados.
     */
    function _validateTPFtIdIsPaused(uint256[] memory ids) internal view {
        uint256 length = ids.length;
        for (uint256 i = 0; i < length; ) {
            require(
                !_getTPFtStorage().isTpftIdPaused(ids[i]),
                "TPFt: TPFtId is paused for operations"
            );
            unchecked {
                ++i;
            }
        }
    }

    /**
     * Função que converte um elemento em um array de tamanho único.
     * @param element Elemento a ser convertido em um array.
     */
    function _asSingletonArray(
        uint256 element
    ) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override returns (bool) {
        return
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC1155MetadataURI).interfaceId ||
            interfaceId == type(ITPFt).interfaceId ||
            interfaceId == type(IAccessControl).interfaceId;
    }

    /**
     * Função externa que retorna o contrato TPFtStorage.
     */
    function getTPFtStorage() external view returns (TPFtStorage) {
        return _getTPFtStorage();
    }

    /**
     * Função externa que retorna o contrato TPFtAccessControl.
     */
    function getTPFtAccessControl() external view returns (TPFtAccessControl) {
        return _getTPFtAccessControl();
    }
}

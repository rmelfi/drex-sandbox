// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

/**
 * @title TPFtAccessControl
 * @author BCB
 * @notice _Smart Contract_ responsável pela camada de controle de acesso para as operações envolvendo Título Público Federal tokenizado (TPFt).
 *
 * Suas principais funcionalidades são:
 * - Determinar quais carteiras podem criar e emitir TPFt,
 * - Controlar quais carteiras tem acesso as operações envolvendo TPFt.
 */
contract TPFtAccessControl is AccessControl {
    /**
     * _Mapping_ das contas autorizadas
     */
    mapping(address => bool) private _enabledAddress;

    /**
     * Endereço do contrato TPFtOperation1001.
     */
    address private _tpftOperation1001ContractAddress;

    /**
     * Endereço do contrato TPFtOperation1012.
     */
    address private _tpftOperation1012ContractAddress;

    /**
     * Endereço do contrato TPFtOperation1070.
     */
    address private _tpftOperation1070ContractAddress;


    /**
     * Endereço do contrato TPFtDvP.
     */
    address private _tpftDvPContractAddress;

    /**
     * Evento emitido para indicar a ativação ou desativação de uma carteira no contrato TPFt.
     * @param member Endereço da carteira afetada.
     * @param msgSender Endereço do remetente que ativou/desativou a conta.
     * @param isEnabled  Booleano que indica se a conta foi ativada (True) ou desativada (False).
     */
    event WalletActivationChanged(
        address indexed member,
        address indexed msgSender,
        bool isEnabled
    );

    /**
     * Endereço do contrato TPFt de Lógica.
     */
    address private _tpftLogicContract;

    /**
     * Constrói uma instância do contrato e permite a carteira conceder ou revogar
     * as roles para os participantes.
     * @param admin_ Endereço da carteira que concede ou revoga as roles.
     */
    constructor(address admin_) {
        _setupRole(DEFAULT_ADMIN_ROLE, admin_);
    }

    /**
     * Modificador que permite que apenas o contrato de Lógica do TPFt execute a função decorada.
     * Verifica se o chamador da função é o contrato de Lógica autorizado (_getTPFtLogicAddress()),
     * caso contrário, a transação será revertida com a mensagem "Unauthorized wallet to perform the operation".
     */
    modifier onlyTPFtLogicContract() {
        if (_msgSender() != _getTPFtLogicContract()) {
            revert(
                "TPFtAccessControl: Unauthorized wallet to perform the operation"
            );
        }
        _;
    }

    /**
     * Função externa que retorna o endereço do TPFtLogic.
     */
    function _getTPFtLogicContract() private view returns (address) {
        return _tpftLogicContract;
    }

    /**
     * Função externa para atualizar o endereço do contrato de lógica TPFt
     * @param tpftLogicContract_ Endereço do novo contrato de lógica TPFt
     */
    function setTPFtLogicContract(address tpftLogicContract_) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()));
        _tpftLogicContract = tpftLogicContract_;
    }

    /**
     * Função externa para atualizar o endereço do contrato de dvp TPFt
     * @param tpftDvPContract_ Endereço do novo contrato de dvp TPFt
     */
    function setTPFtDvPContractAddress(
        address tpftDvPContract_
    ) external onlyTPFtLogicContract {
        _tpftDvPContractAddress = tpftDvPContract_;
    }

    /**
     * Habilita a carteira a operar no piloto Real Digital Selic.
     * @param member Carteira a ser habilitada
     */
    function enableAddress(address member) external onlyTPFtLogicContract {
        _enabledAddress[member] = true;
        emit WalletActivationChanged(member, _msgSender(), true);
    }

    /**
     * Desabilita a carteira a operar no piloto Real Digital Selic.
     * @param member Carteira a ser desabilita
     */
    function disableAddress(address member) external onlyTPFtLogicContract {
        _enabledAddress[member] = false;
        emit WalletActivationChanged(member, _msgSender(), false);
    }

    /**
     * Verifica se a carteira está habilitada a operar no piloto Real Digital Selic.
     * @param member Carteira a ser verificada
     * @return Retorna um valor booleano que indica se a carteira está habilitada a operar no piloto Real Digital Selic.
     */
    function isEnabledAddress(address member) external view returns (bool) {
        return _enabledAddress[member];
    }

    /**
     * Função para conceder uma permissão específica (_ROLE_) a uma carteira.
     * @param role O tipo de permissão (_ROLE_) que será concedido
     * @param wallet Carteira à qual a permissão (_ROLE_) será concedida
     */
    function grantRole(
        bytes32 role,
        address wallet
    ) public virtual override onlyTPFtLogicContract {
        _grantRole(role, wallet);
    }

    /**
     * Função para revogar uma permissão específica (_ROLE_) de uma carteira.
     * @param role O tipo de permissão (_ROLE_) que será revogado
     * @param wallet Carteira à qual a permissão (_ROLE_) será revogada
     */
    function revokeRole(
        bytes32 role,
        address wallet
    ) public virtual override onlyTPFtLogicContract {
        _revokeRole(role, wallet);
    }

    /**
     * Função externa que retorna o endereço do contrato TPFtOperation1001.
     * @return Retorna o endereço do contrato TPFtOperation1001.
     */
    function getTPFt1001OperationContractAddress()
        external
        view
        returns (address)
    {
        return _getTPFt1001OperationContractAddress();
    }

    /**
     * Função interna que retorna o endereço do contrato TPFtOperation1001.
     * @return Retorna o endereço do contrato TPFtOperation1001.
     */
    function _getTPFt1001OperationContractAddress()
        private
        view
        returns (address)
    {
        return _tpftOperation1001ContractAddress;
    }

    /**
     * Função externa que retorna o endereço do contrato TPFtOperation1012.
     * @return Retorna o endereço do contrato TPFtOperation1012.
     */
    function getTPFt1012OperationContractAddress()
        external
        view
        returns (address)
    {
        return _getTPFt1012OperationContractAddress();
    }

    /**
     * Função interna que retorna o endereço do contrato TPFtOperation1012.
     * @return Retorna o endereço do contrato TPFtOperation1012.
     */
    function _getTPFt1012OperationContractAddress()
        private
        view
        returns (address)
    {
        return _tpftOperation1012ContractAddress;
    }

    /**
     * Função externa que retorna o endereço do contrato TPFtOperation1070.
     * @return Retorna o endereço do contrato TPFtOperation1070.
     */
    function getTPFt1070OperationContractAddress()
        external
        view
        returns (address)
    {
        return _getTPFt1070OperationContractAddress();
    }

    /**
     * Função interna que retorna o endereço do contrato TPFtOperation1070.
     * @return Retorna o endereço do contrato TPFtOperation1070.
     */
    function _getTPFt1070OperationContractAddress()
        private
        view
        returns (address)
    {
        return _tpftOperation1070ContractAddress;
    }

    /**
     * Função externa que retorna o endereço do contrato TPFtDvP.
     * @return Retorna o endereço do contrato TPFtDvP.
     */
    function getTPFtDvPContractAddress() external view returns (address) {
        return _tpftDvPContractAddress;
    }

    /**
     * Função externa que define/atualiza o endereço do contrato TPFtOperation1001.
     * @param tpftOperation1001ContractAddress_ Novo endereço do contrato TPFtOperation1001.
     */
    function setTPFt1001OperationContractAddress(
        address tpftOperation1001ContractAddress_
    ) external onlyTPFtLogicContract {
        _tpftOperation1001ContractAddress = tpftOperation1001ContractAddress_;
    }

    /**
     * Função externa que define/atualiza o endereço do contrato TPFtOperation1012.
     * @param tpftOperation1012ContractAddress_ Novo endereço do contrato TPFtOperation1012.
     */
    function setTPFt1012OperationContractAddress(
        address tpftOperation1012ContractAddress_
    ) external onlyTPFtLogicContract {
        _tpftOperation1012ContractAddress = tpftOperation1012ContractAddress_;
    }

    /**
     * Função externa que define/atualiza o endereço do contrato TPFtOperation1070.
     * @param tpftOperation1070ContractAddress_ Novo endereço do contrato TPFtOperation1070.
     */
    function setTPFt1070OperationContractAddress(
        address tpftOperation1070ContractAddress_
    ) external onlyTPFtLogicContract {
        _tpftOperation1070ContractAddress = tpftOperation1070ContractAddress_;
    }
}

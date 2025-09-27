// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import {ITPFt} from "./ITPFt.sol";
import {ITPFtOperation1001} from "./ITPFtOperation1001.sol";
import {TPFtOperation} from "./lib/TPFtOperation.sol";
import {TPFtOperationId} from "./lib/TPFtOperationId.sol";
import {AddressDiscovery} from "../realdigital/AddressDiscovery.sol";
import {RealDigitalDefaultAccount} from "../realdigital/RealDigitalDefaultAccount.sol";
import {STN_CNPJ8, MINTER_ROLE} from "./lib/TPFtConstants.sol";

/**
 * @title TPFtOperation1001
 * @author BCB
 * @notice _Smart Contract_ responsável pela criação e emissão de Título Público Federais Tokenizado tokenizado (TPFt) na carteira da STN.
 */
contract TPFtOperation1001 is ITPFtOperation1001, TPFtOperation {

    /**
     * Inicializa o contrato TPFtOperation, concedendo acesso às funções utilitárias para operações relacionadas a TPFts.
     * @param admin_ Endereço da carteira do administrador.
     * @param addressDiscovery_ Endereço do contrato que facilita a descoberta dos demais endereços de contratos.
     * @param tpftFacadeContract_ Contrato TPFtFacade.
     * @param tpftOperationIdContract_ Contrato TPFtOperationId para utilidades relacionadas a TPFts.
     */
    constructor(address admin_, AddressDiscovery addressDiscovery_, ITPFt tpftFacadeContract_, TPFtOperationId tpftOperationIdContract_) TPFtOperation(addressDiscovery_, tpftFacadeContract_, tpftOperationIdContract_) {
        _grantRole(MINTER_ROLE, admin_);
        _grantRole(DEFAULT_ADMIN_ROLE, admin_);
    }

    /**
     * Função para o Bacen criar um TPFt.
     * @param tpftData Estrutura de dados do TPFt, que incluem as seguintes informações: <br />- `acronym`: A sigla do TPFt. <br />- `code`: O código único do TPFt. <br />- `maturityDate`: A data de vencimento do TPFt, representada como um valor numérico (timestamp Unix).
     */
    function createTPFt(ITPFt.TPFtData memory tpftData) external {
        require(hasRole(MINTER_ROLE, msg.sender), "TPFtOperation1001: Unauthorized wallet to perform the operation");
        require(_validateExpirationDate(tpftData.maturityDate), "TPFtExpired");
        ITPFt(_getTPFtFacadeContract()).createTPFt(tpftData);
    }

    /**
     * Função para o Bacen emitir TPFt.
     * @param operationId Número de operação + data vigente no formato yyyyMMdd.
     * @param tpftData Estrutura de dados do TPFt, que incluem as seguintes informações: <br />- `acronym`: A sigla do TPFt. <br />- `code`: O código único do TPFt. <br />- `maturityDate`: A data de vencimento do TPFt, representada como um valor numérico (timestamp Unix).
     * @param tpftAmount Quantidade de TPFt a ser emitido.
     */
    function mint(uint256 operationId, ITPFt.TPFtData memory tpftData, uint256 tpftAmount) external {
        require(hasRole(MINTER_ROLE, msg.sender), "TPFtOperation1001: Unauthorized wallet to perform the operation");
        require(_validateExpirationDate(tpftData.maturityDate), "TPFtExpired");
        require(_getTPFtOperationIdContract().validOperationId(operationId), "OperationIdAlreadyInUse");

        RealDigitalDefaultAccount defaultAccount = _getRealDigitalDefaultAccount();

        address receiverAddress = defaultAccount.defaultAccount(STN_CNPJ8);

        uint256 tpftId = ITPFt(_getTPFtFacadeContract()).getTPFtId(tpftData);

        require(tpftId != 0, "TPFtOperation1001: TPFt ID cannot be zero");

        ITPFt(_getTPFtFacadeContract()).mint(receiverAddress, tpftId, tpftAmount);

        emit OperationMintEvent(operationId, receiverAddress, tpftData, tpftAmount, "ATU", block.timestamp);
    }

    /**
     * Função que atualiza o endereço do contrato AddressDiscovery
     * @param newAddressDiscovery novo endereço do AddressDiscovery
     */
    function updateAddressDiscovery(AddressDiscovery newAddressDiscovery) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _updateAddressDiscovery(newAddressDiscovery);
    }

    /**
     * Função que atualiza o endereço do contrato TPFtFacade
     * @param newTPFtFacadeContract novo endereço do TPFtFacade
     */
    function updateTpftFacadeContract(address newTPFtFacadeContract) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _updateTpftFacadeContract(newTPFtFacadeContract);
    }

    /**
     * Função que atualiza o endereço do contrato TPFtOperationId
     * @param newTpftOperationIdContract novo endereço do TPFtOperationId
     */
    function updateTpftOperationId(TPFtOperationId newTpftOperationIdContract) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _updateTpftOperationId(newTpftOperationIdContract);
    }
}

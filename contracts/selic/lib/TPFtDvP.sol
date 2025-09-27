// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {ITPFt} from "../ITPFt.sol";
import {ITPFtDvP} from "./ITPFtDvP.sol";
import {AddressDiscovery} from "../../realdigital/AddressDiscovery.sol";
import {RealDigital} from "../../realdigital/RealDigital.sol";
import {RealTokenizado} from "../../realdigital/RealTokenizado.sol";
import {SwapOneStepFrom} from "../../realdigital/SwapOneStepFrom.sol";
import {ReentrancyGuard} from "../utils/ReentrancyGuard.sol";
import {REAL_DIGITAL_CONTRACT_NAME, SWAP_ONE_STEP_FROM_CONTRACT_NAME, DEFAULT_ADMIN_ROLE, OPERATOR_ROLE, OperationType} from "./TPFtConstants.sol";

/**
 * @title TPFtDvP
 * @author BCB
 * @notice _Smart Contract_ responsável por permitir transações de DvP (Entrega contra Pagamento)
 * entre participantes e entre clientes.
 */
contract TPFtDvP is ITPFtDvP, AccessControl, ReentrancyGuard {
    using SafeERC20 for RealDigital;

    /**
     * _AddressDiscovery_ Endereço do contrato que facilita a descoberta dos demais endereços de contratos.
     */
    AddressDiscovery private _addressDiscovery;

    /**
     * _TPFt_ Endereço do contrato TPFt.
     */
    ITPFt private _tpft;

    /**
     * _Mapping_ que armazena as operações de DvP.
     */
    mapping(uint256 => DvPOperation) private _dvpOperations;

    /**
     * _Counter_ que mantém o total de transações DvP registradas no contrato.
     */
    uint256 private _totalDvPs;

    /**
     * Constrói uma instância do contrato com o endereço do contrato de descoberta de endereços e reseta o contador de transações DvP.
     * @param addressDiscovery_ Endereço do contrato que facilita a descoberta dos demais endereços de contratos.
     * @param tpft_ Endereço do contrato TPFt.
     * @param admin_ Endereço da carteira do administrador.
     */
    constructor(address admin_, AddressDiscovery addressDiscovery_, ITPFt tpft_) {
        _addressDiscovery = addressDiscovery_;
        _tpft = tpft_;
        _grantRole(DEFAULT_ADMIN_ROLE, admin_);
        _grantRole(OPERATOR_ROLE, admin_);
    }

    /**
     * Realiza operação de DvP (Entrega contra Pagamento) entre Participantes.
     * @param dvpId Identificador da operação DvP a ser executada.
     * @param buyer Endereço da carteira do comprador.
     * @param seller Endereço da carteira do vendedor.
     * @param tpftData Estrutura de dados do TPFt, que incluem as seguintes informações: <br />- `acronym`: A sigla do TPFt. <br />- `code`: O código único do TPFt. <br />- `maturityDate`: A data de vencimento do TPFt, representada como um valor numérico (timestamp Unix).
     * @param tpftAmount Quantidade de TPFt a ser negociada.
     * @param unitPrice Preço unitário do TPFt. Incluir as 8 casas decimais.
     * @param financialValue Quantidade de Real Digital a ser negociada.
     * @param operationType Tipo de operação. Se for compra deve ser informado OperationType.BUY, se for venda deve ser informado OperationType.SELL.
     * @return Retorna o número total de operações de DvP realizadas após a execução desta função.
     * @param extraData Dados adicionais da operação DvP.
     */
    function dvpParticipant(
        uint256 dvpId,
        address buyer,
        address seller,
        ITPFt.TPFtData memory tpftData,
        uint256 tpftAmount,
        uint256 unitPrice,
        uint256 financialValue,
        OperationType operationType,
        bytes memory extraData
    ) external noReentrant onlyRole(OPERATOR_ROLE) returns (uint256) {
        return _dvp(dvpId, buyer, seller, RealTokenizado(address(0)), RealTokenizado(address(0)), tpftData, tpftAmount, unitPrice, financialValue, operationType, extraData);
    }

    /**
     * Realiza operação de DvP (Entrega contra Pagamento) entre Clientes.
     * @param dvpId Identificador da operação DvP a ser executada.
     * @param buyer Endereço da carteira do comprador.
     * @param buyerToken Real Tokenizado do comprador.
     * @param seller Endereço da carteira do vendedor.
     * @param sellerToken Real Tokenizado do vendedor.
     * @param tpftData Estrutura de dados do TPFt, que incluem as seguintes informações: <br />- `acronym`: A sigla do TPFt. <br />- `code`: O código único do TPFt. <br />- `maturityDate`: A data de vencimento do TPFt, representada como um valor numérico (timestamp Unix).
     * @param tpftAmount Quantidade de TPFt a ser negociada.
     * @param unitPrice Preço unitário do TPFt. Incluir as 8 casas decimais.
     * @param financialValue Quantidade de Real Tokenizado a ser negociada.
     * @param operationType Tipo de operação. Se for compra deve ser informado OperationType.BUY, se for venda deve ser informado OperationType.SELL.
     * @return Retorna o número total de operações de DvP realizadas após a execução desta função.
     * @param extraData Dados adicionais da operação DvP.
     */
    function dvpClients(
        uint256 dvpId,
        address buyer,
        RealTokenizado buyerToken,
        address seller,
        RealTokenizado sellerToken,
        ITPFt.TPFtData memory tpftData,
        uint256 tpftAmount,
        uint256 unitPrice,
        uint256 financialValue,
        OperationType operationType,
        bytes memory extraData
    ) external noReentrant onlyRole(OPERATOR_ROLE) returns (uint256) {
        return _dvp(dvpId, buyer, seller, buyerToken, sellerToken, tpftData, tpftAmount, unitPrice, financialValue, operationType, extraData);
    }

    /**
     * Cancela uma operação DvP com o identificador dvpId.
     * @param dvpId Identificador da operação DvP.
     */
    function cancelDvP(uint256 dvpId) external onlyRole(OPERATOR_ROLE) {
        DvPOperation storage dvpOperation = _dvpOperations[dvpId];

        if (dvpId == 0) {
            revert("InvalidOperation");
        }

        if (dvpOperation.dvpId == 0) {
            revert("OperationNotFound");
        }

        if (dvpOperation.executed) {
            revert("OperationExecuted");
        }

        if (dvpOperation.canceled) {
            revert("OperationCanceled");
        }

        dvpOperation.canceled = true;
    }

    /**
     * Atualiza o contrato AddressDiscovery.
     * @param newAddressDiscovery Novo endereço do AddressDiscovery.
     */
    function updateAddressDiscovery(AddressDiscovery newAddressDiscovery) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _addressDiscovery = newAddressDiscovery;
    }

    /**
     * Atualiza o contrato TPFt.
     * @param newTPFt Novo endereço do TPFt.
     */
    function updateTPFt(ITPFt newTPFt) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _tpft = newTPFt;
    }

    /**
     * Executa um DvP (Entrega contra Pagamento) de forma genérica, podendo ser realizada
     * entre participantes, entre clientes, ou entre participante e cliente.
     * Valida os dados da operação e garante a compatibilidade antes de prosseguir com a execução.
     * @param dvpId Identificador da operação DvP a ser executada.
     * @param buyer Endereço da carteira do comprador.
     * @param seller Endereço da carteira do vendedor.
     * @param buyerToken Real Tokenizado do comprador.
     * @param sellerToken Real Tokenizado do vendedor.
     * @param tpftData Estrutura de dados do TPFt, que incluem as seguintes informações: <br />- `acronym`: A sigla do TPFt. <br />- `code`: O código único do TPFt. <br />- `maturityDate`: A data de vencimento do TPFt, representada como um valor numérico (timestamp Unix).
     * @param tpftAmount Quantidade de TPFt a ser negociada.
     * @param unitPrice Preço unitário do TPFt. Incluir as 8 casas decimais.
     * @param financialValue Quantidade de Real Digital / Real Tokenizado a ser negociada.
     * @param operationType Tipo de operação. Se for compra deve ser informado OperationType.BUY, se for venda deve ser informado OperationType.SELL.
     * @return Retorna o número total de operações de DvP realizadas após a execução desta função.
     * @param extraData Dados adicionais da operação DvP.
     */
    function _dvp(
        uint256 dvpId,
        address buyer,
        address seller,
        RealTokenizado buyerToken,
        RealTokenizado sellerToken,
        ITPFt.TPFtData memory tpftData,
        uint256 tpftAmount,
        uint256 unitPrice,
        uint256 financialValue,
        OperationType operationType,
        bytes memory extraData
    ) private returns (uint256) {
        DvPOperation memory compareOperation;
        compareOperation.dvpId = dvpId;
        compareOperation.buyer = buyer;
        compareOperation.seller = seller;
        compareOperation.buyerToken = buyerToken;
        compareOperation.sellerToken = sellerToken;
        compareOperation.tpftData = tpftData;
        compareOperation.tpftAmount = tpftAmount;
        compareOperation.unitPrice = unitPrice;
        compareOperation.financialValue = financialValue;
        compareOperation.extraData = extraData;

        if (dvpId == 0) {
            ++_totalDvPs;
            compareOperation.dvpId = _totalDvPs;
        } else {
            DvPOperation memory operation = _dvpOperations[dvpId];

            _validateOperation(operation.dvpId, operation.canceled, operation.executed, operation.buyerOperation, operation.sellerOperation, operationType);

            if (!_compatibleData(operation, compareOperation)) {
                revert("IncompatibleOperation");
            }

            compareOperation.buyerOperation = operation.buyerOperation;
            compareOperation.sellerOperation = operation.sellerOperation;
        }

        if (operationType == OperationType.BUY) {
            compareOperation.buyerOperation = true;
        } else {
            compareOperation.sellerOperation = true;
        }

        _dvpOperations[compareOperation.dvpId] = compareOperation;

        if (compareOperation.buyerOperation && compareOperation.sellerOperation) {
            _executeOperation(compareOperation.dvpId);
        }

        return compareOperation.dvpId;
    }

    /**
     * Executa a operação DvP.
     * @param dvpId Identificador da operação DvP a ser executada.
     */
    function _executeOperation(uint256 dvpId) private {
        DvPOperation storage operation = _dvpOperations[dvpId];

        operation.executed = true;

        if (operation.buyerToken == operation.sellerToken) {
            RealDigital token = address(operation.buyerToken) == address(0) ? _getRealDigital() : RealDigital(address(operation.buyerToken));

            token.safeTransferFrom(operation.buyer, operation.seller, operation.financialValue);
        } else {
            SwapOneStepFrom swapOneStepFrom = _getSwapOneStepFrom();

            swapOneStepFrom.executeSwapFrom(operation.buyerToken, operation.sellerToken, operation.buyer, operation.seller, operation.financialValue);
        }

        ITPFt tpft = _tpft;

        tpft.safeTransferFrom(operation.seller, operation.buyer, operation.tpftData, operation.tpftAmount);
    }

    /**
     * Valida se a operação DvP é válida e pode ser executada.
     * @param dvpId Identificador da operação DvP.
     * @param canceled Booleano de cancelação.
     * @param executed Booleano de execução.
     * @param buyerOperation Booleano de operação de compra.
     * @param sellerOperation Booleano de operação de venda.
     * @param operationType Tipo de operação DvP a ser validada (compra ou venda).
     */
    function _validateOperation(uint256 dvpId, bool canceled, bool executed, bool buyerOperation, bool sellerOperation, OperationType operationType) private pure {
        if (dvpId == 0) {
            revert("OperationNotFound");
        }

        if (canceled) {
            revert("OperationCanceled");
        }

        if (executed) {
            revert("OperationExecuted");
        }

        if ((operationType == OperationType.BUY && buyerOperation) || (operationType == OperationType.SELL && sellerOperation)) {
            revert("RepeatedOperation");
        }
    }

    /**
     * Verifica se os dados da operação são compatíveis.
     * @param operation Estrutura DvPOperation no primeiro comando.
     * @param compareOperation Estrutura DvPOperation no segundo comando.
     */
    function _compatibleData(DvPOperation memory operation, DvPOperation memory compareOperation) private pure returns (bool) {
        return
            keccak256(
                abi.encode(
                    compareOperation.dvpId,
                    compareOperation.buyer,
                    compareOperation.seller,
                    abi.encode(compareOperation.tpftData),
                    compareOperation.tpftAmount,
                    compareOperation.unitPrice,
                    compareOperation.buyerToken,
                    compareOperation.sellerToken,
                    compareOperation.financialValue,
                    compareOperation.extraData
                )
            ) ==
            keccak256(
                abi.encode(operation.dvpId, operation.buyer, operation.seller, abi.encode(operation.tpftData), operation.tpftAmount, operation.unitPrice, operation.buyerToken, operation.sellerToken, operation.financialValue, operation.extraData)
            );
    }

    /**
     * Retorna o contrato RealDigital por meio do endereço obtido
     * através do contrato AddressDiscovery.
     * @return Retorna o contrato RealDigital.
     */
    function _getRealDigital() private view returns (RealDigital) {
        return RealDigital(_addressDiscovery.addressDiscovery(REAL_DIGITAL_CONTRACT_NAME));
    }

    /**
     * Retorna o contrato SwapOneStepFrom por meio do endereço obtido
     * através do contrato AddressDiscovery.
     * @return Retorna o contrato SwapOneStepFrom.
     */
    function _getSwapOneStepFrom() private view returns (SwapOneStepFrom) {
        return SwapOneStepFrom(_addressDiscovery.addressDiscovery(SWAP_ONE_STEP_FROM_CONTRACT_NAME));
    }

    /**
     * Retorna a operação DvP com o identificador dvpId.
     * @param dvpId Identificador da operação DvP.
     */
    function getDvPOperation(uint256 dvpId) external view returns (DvPOperation memory) {
        return _dvpOperations[dvpId];
    }

    /**
     * Retorna o número total de operações de DvP executadas.
     * @return Retorna o número total de operações de DvP executadas.
     */
    function getTotalDvPs() external view returns (uint256) {
        return _totalDvPs;
    }

    /**
     * Retorna o contrato AddressDiscovery.
     * @return Retorna o contrato AddressDiscovery.
     */
    function getAddressDiscovery() external view returns (AddressDiscovery) {
        return _addressDiscovery;
    }

    /**
     * Retorna o contrato TPFt.
     * @return Retorna o contrato TPFt.
     */
    function getTPFt() external view returns (ITPFt) {
        return _tpft;
    }
}

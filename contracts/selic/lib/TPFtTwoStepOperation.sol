// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import {ITPFt} from "../ITPFt.sol";
import {ITPFtDvP} from "./ITPFtDvP.sol";
import {ITPFtTwoStepOperation} from "./ITPFtTwoStepOperation.sol";
import {TPFtOperation} from "./TPFtOperation.sol";
import {TPFtOperationId} from "./TPFtOperationId.sol";
import {AddressDiscovery} from "../../realdigital/AddressDiscovery.sol";
import {RealTokenizado} from "../../realdigital/RealTokenizado.sol";
import {CallerPart, OperationType, MAX_FINANCIAL_VALUE} from "./TPFtConstants.sol";

/**
 * @title TPFtTwoStepOperation
 * @author BCB
 * @notice _Smart Contract_ que adiciona funcionalidades específicas para operações de dois comandos com TPFt.
 */
abstract contract TPFtTwoStepOperation is TPFtOperation, ITPFtTwoStepOperation {
    /**
     * Estrutura de dados para armazenar os parâmetros utilizados para
     * executar a etapa da operação de dois comandos com TPFt.
     * @param operationId Número de operação + data vigente no formato yyyyMMdd.
     * @param cnpj8Sender CNPJ8 do cedente da operação.
     * @param cnpj8Receiver CNPJ8 do cessionário da operação.
     * @param sender Endereço do cedente da operação.
     * @param receiver Endereço do cessionário da operação.
     * @param senderRealTokenizado RealTokenizado do cedente da operação.
     * @param receiverRealTokenizado RealTokenizado do cessionário da operação.
     * @param callerPart Parte que está transmitindo o comando da operação. Pode ser tanto CallerPart.TPFtSender como CallerPart.TPFtReceiver.
     * @param tpftData Estrutura de dados do TPFt, que incluem as seguintes informações: <br />- `acronym`: A sigla do TPFt. <br />- `code`: O código único do TPFt. <br />- `maturityDate`: A data de vencimento do TPFt, representada como um valor numérico (timestamp Unix).
     * @param tpftAmount Quantidade de TPFt a ser enviada.
     * @param unitPrice Preço unitário do TPFt. Incluir as 8 casas decimais.
     * @param isCNPJ8 Valor booleano que representa uma operação de DvP envolvendo CNPJ8.
     * @param isRealTokenizado Valor booleano que representa uma operação de DvP envolvendo Real Tokenizado.
     * @param extraData Dados adicionais da operação.
     */
    struct OperationStepData {
        uint256 operationId;
        uint256 cnpj8Sender;
        uint256 cnpj8Receiver;
        address sender;
        address receiver;
        RealTokenizado senderRealTokenizado;
        RealTokenizado receiverRealTokenizado;
        CallerPart callerPart;
        ITPFt.TPFtData tpftData;
        uint256 tpftAmount;
        uint256 unitPrice;
        bool isCNPJ8;
        bool isRealTokenizado;
        bool isAuction;
        bytes extraData;
    }

    /**
     * _Mapping_ interno para rastrear os identificadores de operação DvP (Entrega contra Pagamento) associados.
     */
    mapping(uint256 operationId => uint256 dvpId) internal _dvpIds;

    /**
     * _ITPFtDvP_ Endereço do contrato TPFtDvP.
     */
    ITPFtDvP private _tpftDvP;

    /**
     * Estende de TPFtOperation.
     * @param addressDiscovery_ Endereço do contrato que facilita a descoberta dos demais endereços de contratos.
     * @param tpft_ Endereço do contrato TPFt.
     * @param tpftDvP_ Endereço do contrato TPFtDvP.
     * @param tpftOperationId_ Endereço do contrato TPFtOperationId.
     */
    constructor(AddressDiscovery addressDiscovery_, ITPFt tpft_, ITPFtDvP tpftDvP_, TPFtOperationId tpftOperationId_) TPFtOperation(addressDiscovery_, tpft_, tpftOperationId_) {
        _tpftDvP = tpftDvP_;
    }

    /**
     * Modificador para validar autorizações de operações de duplo comando.
     * @param data Conjunto de dados que representa um passo de uma operação.
     */
    modifier validAuthorizations(OperationStepData memory data) {
        _validateAuthorizations(data);
        _;
    }

    /**
     * Função interna que executa a etapa da operação de dois comandos com TPFt.
     * @param data Conjunto de dados que representa um passo de uma operação.
     */
    function _executeOperationStep(OperationStepData memory data) internal {
        _validateTwoStepOperation(data);

        bool isFirstStep = _dvpIds[data.operationId] == 0;

        if (isFirstStep) {
            _processFirstStep(data);
        } else {
            _processSecondStep(data);
        }
    }

    function _processFirstStep(OperationStepData memory data) internal {
        OperationType operationType = _getDvPOperationType(data.callerPart);

        uint256 financialValue = _calculateFinancialValue(data.unitPrice, data.tpftAmount);

        uint256 dvpId;

        if (!data.isRealTokenizado) {
            dvpId = _tpftDvP.dvpParticipant(0, data.receiver, data.sender, data.tpftData, data.tpftAmount, data.unitPrice, financialValue, operationType, data.extraData);
        } else {
            dvpId = _tpftDvP.dvpClients(0, data.receiver, data.receiverRealTokenizado, data.sender, data.senderRealTokenizado, data.tpftData, data.tpftAmount, data.unitPrice, financialValue, operationType, data.extraData);
        }

        _executeDvP(dvpId, data);
    }

    function _processSecondStep(OperationStepData memory data) internal {
        OperationType operationType = _getDvPOperationType(data.callerPart);

        uint256 financialValue = _calculateFinancialValue(data.unitPrice, data.tpftAmount);

        if (!data.isRealTokenizado) {
            try _tpftDvP.dvpParticipant(_dvpIds[data.operationId], data.receiver, data.sender, data.tpftData, data.tpftAmount, data.unitPrice, financialValue, operationType, data.extraData) returns (uint256 dvpId) {
                _executeDvP(dvpId, data);
            } catch Error(string memory error) {
                _processDvPError(error);
            }
        } else {
            try
                _tpftDvP.dvpClients(_dvpIds[data.operationId], data.receiver, data.receiverRealTokenizado, data.sender, data.senderRealTokenizado, data.tpftData, data.tpftAmount, data.unitPrice, financialValue, operationType, data.extraData)
            returns (uint256 dvpId) {
                _executeDvP(dvpId, data);
            } catch Error(string memory error) {
                _processDvPError(error);
            }
        }
    }

    /**
     * Função interna que executa a operação de DvP.
     * @param dvpId Id do DvP.
     * @param data Conjunto de dados que representa um passo de uma operação.
     */
    function _executeDvP(uint256 dvpId, OperationStepData memory data) internal returns (uint256) {
        /**
         * @dev Caso o id que temos guardado seja 0, significa que estamos no primeiro pé da operação, desta forma
         * precisamos armazenar o Id do DvP para quando a próxima perna chegar ela possa utilizar o Id de
         * DvP correto.
         */
        //
        if (_dvpIds[data.operationId] == 0) {
            _dvpIds[data.operationId] = dvpId;
            _processDvPStepSuccess(data);
        } else {
            _processDvPSuccess(data);
        }
        return dvpId;
    }

    /**
     * Função interna que processa com sucesso um passo (primeiro comando) da operação de DvP.
     * Com base no callerPart, é emitido o evento apropriado.
     * Se o callerPart for o TPFtSender, um evento de operação bem-sucedido com o status "LAN" é emitido.
     * Caso contrário, se o callerPart for TPFtReceiver, um evento de operação bem-sucedido com o status "CON" é emitido.
     * @param data Conjunto de dados que representa um passo de uma operação.
     */
    function _processDvPStepSuccess(OperationStepData memory data) internal {
        if (data.callerPart == CallerPart.TPFtSender) {
            _emitSuccessfulOperationEvent(data, "LAN");
        } else {
            _emitSuccessfulOperationEvent(data, "CON");
        }
    }

    /**
     * Função interna que processa com sucesso uma operação de DvP que tem o duplo comando.
     * Se emite um evento de operação bem-sucedida com o status "ATU" quando o DvP foi bem-sucedido.
     * @param data Conjunto de dados que representa um passo de uma operação.
     */
    function _processDvPSuccess(OperationStepData memory data) internal {
        _emitSuccessfulOperationEvent(data, "ATU");
    }

    /**
     * Função interna que valida a operação de dois comandos com TPFt.
     * @param data Conjunto de dados que representa um passo de uma operação.
     */
    function _validateTwoStepOperation(OperationStepData memory data) internal validAuthorizations(data) {
        _customValidOperation(data);

        if (!_validTPFtAmount(data)) {
            revert("AmountEqualToZero");
        }

        if (!_validUnitPrice(data)) {
            revert("InvalidUnitPrice");
        }

        if (!_validFinancialValue(_calculateFinancialValue(data.unitPrice, data.tpftAmount))) {
            revert("FinancialValueEqualToZero");
        }

        if (!_addressEnabled(data.sender)) {
            revert("SenderNotEnabledInTPFt");
        }

        if (!_addressEnabled(data.receiver)) {
            revert("ReceiverNotEnabledInTPFt");
        }

        if (!_validOperationId(data)) {
            revert("OperationIdAlreadyInUse");
        }
    }

    /**
     * Função interna que valida se o Número de operação + data vigente no formato yyyyMMdd é válido.
     * @param data Conjunto de dados que representa um passo de uma operação.
     * @return Retorna true se o identificador de operação for válido, caso contrário, false.
     */
    function _validOperationId(OperationStepData memory data) internal returns (bool) {
        if (_dvpIds[data.operationId] == 0) {
            return _getTPFtOperationIdContract().validOperationId(data.operationId);
        }
        return true;
    }

    /**
     * Função interna que cancela uma operação DvP.
     * @param operationId_ Número de operação + data vigente no formato yyyyMMdd a ser cancelada.
     * @param reason Motivo do cancelamento.
     */
    function _cancelDvP(uint256 operationId_, string calldata reason) internal {
        _getTPFtDvPContract().cancelDvP(_dvpIds[operationId_]);
        emit OperationCancelEvent(operationId_, "CAN", reason, block.timestamp);
    }

    /**
     * Função interna que emite um evento de operação bem-sucedida.
     * @param data Conjunto de dados que representa um passo de uma operação.
     * @param status Status do evento de operação.
     */
    function _emitSuccessfulOperationEvent(OperationStepData memory data, string memory status) internal {
        if (data.isCNPJ8 && !data.isAuction && !data.isRealTokenizado) {
            _emitOperationEvent(data, status);
        } else if (data.isRealTokenizado && !data.isAuction && !data.isCNPJ8) {
            _emitOperationClientTradeEvent(data, status);
        } else if (data.isCNPJ8 && data.isAuction && !data.isRealTokenizado) {
            _emitAuctionOperationEvent(data, status);
        } else if (!data.isCNPJ8 && !data.isAuction && !data.isRealTokenizado) {
            _emitOperationTradeEvent(data, status);
        } else {
            revert("InvalidEventOperationType");
        }
    }

    /**
     * Função interna que emite um evento de operação.
     * @param data Conjunto de dados que representa um passo de uma operação.
     * @param status Status do evento de operação.
     */
    function _emitOperationEvent(OperationStepData memory data, string memory status) internal {
        emit OperationEvent(data.operationId, data.cnpj8Sender, data.cnpj8Receiver, data.sender, data.receiver, data.tpftData, data.tpftAmount, data.unitPrice, _calculateFinancialValue(data.unitPrice, data.tpftAmount), status, block.timestamp);
    }

    /**
     * Função interna que emite um evento de operação de negociação (trade).
     * @param data Conjunto de dados que representa um passo de uma operação.
     * @param status Status do evento de operação.
     */
    function _emitOperationTradeEvent(OperationStepData memory data, string memory status) internal {
        emit OperationTradeEvent(data.operationId, data.sender, data.receiver, data.tpftData, data.tpftAmount, data.unitPrice, _calculateFinancialValue(data.unitPrice, data.tpftAmount), status, block.timestamp);
    }

    /**
     * Função interna que emite um evento de operação de negociação (trade) entre participantes e/ou clientes.
     * @param data Conjunto de dados que representa um passo de uma operação.
     * @param status Status do evento de operação.
     */
    function _emitOperationClientTradeEvent(OperationStepData memory data, string memory status) internal {
        emit OperationClientTradeEvent(
            data.operationId,
            data.sender,
            data.senderRealTokenizado,
            data.receiver,
            data.receiverRealTokenizado,
            data.tpftData,
            data.tpftAmount,
            data.unitPrice,
            _calculateFinancialValue(data.unitPrice, data.tpftAmount),
            status,
            block.timestamp
        );
    }

    /**
     * Função interna que emite um evento de operação de compra/venda definitiva entre participantes.
     * @param data Conjunto de dados que representa um passo de uma operação.
     * @param status Status do evento de operação.
     */
    function _emitAuctionOperationEvent(OperationStepData memory data, string memory status) internal {
        emit AuctionOperationEvent(
            data.operationId,
            data.cnpj8Sender,
            data.sender,
            data.cnpj8Receiver,
            data.receiver,
            data.tpftData,
            data.tpftAmount,
            data.unitPrice,
            _calculateFinancialValue(data.unitPrice, data.tpftAmount),
            status,
            block.timestamp,
            abi.decode(data.extraData, (string))
        );
    }

    /**
     * Função interna que valida o cedente da operação.
     * @param callerPart Parte que está transmitindo o comando da operação onde será verificado se é de tipo CallerPart.TPFtSender.
     * @param sender Endereço da carteira do cedente.
     * @return Booleano que indica se o cedente (sender) da operação é válido de acordo com as regras específicas implementadas na função concreta que herda essa função abstrata.
     *         Se o cedente for válido, a função deve retornar true; caso contrário, deve retornar false.
     */
    function _validSender(CallerPart callerPart, address sender) internal virtual returns (bool);

    /**
     * Função interna que valida o cessionário da operação.
     * @param callerPart Parte que está transmitindo o comando da operação onde será verificado se é de tipo CallerPart.TPFtSender.
     * @param receiver Endereço da carteira do cessionário.
     * @return Booleano que indica se o cessionário (receiver) da operação é quem está enviando a transação.
     *         Se o cessionário for válido, a função deve retornar true; caso contrário, deve retornar false.
     */
    function _validReceiver(CallerPart callerPart, address receiver) internal virtual returns (bool) {
        if (callerPart == CallerPart.TPFtReceiver) return msg.sender == receiver;
        return true;
    }

    /**
     * Função interna que realiza validações personalizadas.
     * @param data Conjunto de dados que representa um passo de uma operação.
     */
    function _customValidOperation(OperationStepData memory data) internal virtual;

    /**
     * Função interna que valida as autorizações de operações de duplo comando.
     * Avalia se o remetente (sender) e o receptor (receiver) são válidos de acordo
     * com o callerPart. Se qualquer uma dessas verificações falhar,
     * a função reverte a transação com a mensagem de erro indicando que
     * a carteira não está autorizada a realizar a operação.
     * @param data Conjunto de dados que representa um passo de uma operação.
     */
    function _validateAuthorizations(OperationStepData memory data) internal virtual {
        if (!_validSender(data.callerPart, data.sender) || !_validReceiver(data.callerPart, data.receiver)) {
            revert("Unauthorized wallet to perform the operation");
        }
    }

    /**
     * Função interna que atualiza o contrato TPFtDvP.
     * @param newTPFtDvP Novo contrato TPFtDvP.
     */
    function _updateTpftDvPContract(ITPFtDvP newTPFtDvP) internal virtual {
        _tpftDvP = newTPFtDvP;
    }

    /**
     * Função interna que valida o Id da operação DvP.
     * @param operationId_ Id da operação DvP.
     */
    function _validateOperationDvPId(uint256 operationId_) internal virtual {
        if (_dvpIds[operationId_] == 0) {
            revert("Nonexistent Operation ID");
        }
    }

    /**
     * Função interna que valida se a quantidade de TPFt (tpftAmount) é igual a zero.
     * @param data Conjunto de dados que representa um passo de uma operação.
     * @return Booleano que indica se a quantidade de TPFt (tpftAmount) for valida.
     */
    function _validTPFtAmount(OperationStepData memory data) internal pure returns (bool) {
        return data.tpftAmount != 0;
    }

    /**
     * Função interna que valida o preço unitário.
     * @param data Conjunto de dados que representa um passo de uma operação.
     * @return Booleano que indica se o preço unitário (unitPrice) for valido.
     */
    function _validUnitPrice(OperationStepData memory data) internal pure returns (bool) {
        return data.unitPrice != 0 && data.unitPrice <= MAX_FINANCIAL_VALUE;
    }

    /**
     * Função interna que valida se o valor financeiro calculado é igual a zero.
     * @param financialValue Calculado pela quantidade de TPFt a ser negociada vezes preço unitário do TPFt.
     * @return Booleano que indica se o valor financeiro for valido.
     */
    function _validFinancialValue(uint256 financialValue) internal pure returns (bool) {
        return financialValue != 0;
    }

    /**
     * Função interna que obtem o tipo de operação DvP com base na parte chamadora.
     * @param callerPart Parte que está transmitindo o comando da operação. Nesta operação sempre será CallerPart.TPFtSender.
     * @return Tipo de operação (OperationType.SELL se chamado pelo CallerPart.TPFtSender, caso contrario será OperationType.BUY).
     */
    function _getDvPOperationType(CallerPart callerPart) internal pure returns (OperationType) {
        if (callerPart == CallerPart.TPFtSender) {
            return OperationType.SELL;
        }
        return OperationType.BUY;
    }

    /**
     * Função interna que processa o erro de uma operação DvP.
     * @param error Mensagem de erro recebida da operação DvP.
     */
    function _processDvPError(string memory error) internal pure {
        if (keccak256(abi.encode("RepeatedOperation")) == keccak256(abi.encode(error))) {
            revert("OperationIdAlreadyInUse");
        } else if (keccak256(abi.encode("OperationCanceled")) == keccak256(abi.encode(error))) {
            revert("OperationCanceled");
        } else if (keccak256(abi.encode("ERC20: insufficient allowance")) == keccak256(abi.encode(error))) {
            revert("Insufficient financial balance");
        } else if (keccak256(abi.encode("ERC1155: insufficient balance for transfer")) == keccak256(abi.encode(error))) {
            revert("Insufficient TPFt balance");
        } else {
            revert(error);
        }
    }

    /**
     * Função interna que retorna o contrato TPFtDvP.
     * @return Contrato TPFtDvP.
     */
    function _getTPFtDvPContract() internal view virtual returns (ITPFtDvP) {
        return _tpftDvP;
    }

    /**
     * Função interna que valida a parte chamadora.
     * @param buyerOperation Booleano que indica se a parte chamadora é a carteira do comprador.
     * @param buyer Endereço da carteira do comprador.
     * @param seller Endereço da carteira do vendedor.
     */
    function _validateCaller(bool buyerOperation, address buyer, address seller) internal view virtual {
        if (buyerOperation) {
            if (buyer != _msgSender()) {
                revert("Invalid caller");
            }
        } else {
            if (seller != _msgSender()) {
                revert("Invalid caller");
            }
        }
    }

    /**
     * Função interna que valida se um endereço de carteira está habilitado para participar da operação.
     * @param wallet Endereço da carteira que participa da operação.
     * @return Booleano que indica se o endereço de carteira está habilitado para operar no Real Digital Selic.
     */
    function _addressEnabled(address wallet) internal view returns (bool) {
        return _getTPFt().isEnabledAddress(wallet);
    }
}

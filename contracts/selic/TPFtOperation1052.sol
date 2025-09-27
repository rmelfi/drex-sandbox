// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import {Pausable} from "@openzeppelin/contracts/security/Pausable.sol";
import {ITPFt} from "./ITPFt.sol";
import {ITPFtDvP} from "./lib/ITPFtDvP.sol";
import {ITPFtOperation1052} from "./ITPFtOperation1052.sol";
import {TPFtOperationId} from "./lib/TPFtOperationId.sol";
import {TPFtTwoStepOperation} from "./lib/TPFtTwoStepOperation.sol";
import {AddressDiscovery} from "../realdigital/AddressDiscovery.sol";
import {RealDigitalDefaultAccount} from "../realdigital/RealDigitalDefaultAccount.sol";
import {RealTokenizado} from "../realdigital/RealTokenizado.sol";
import {CallerPart, STN_CNPJ8, BACEN_CNPJ8, AUCTION_ROLE} from "./lib/TPFtConstants.sol";

/**
 * @title TPFtOperation1052
 * @author BCB
 * @notice _Smart Contract_ responsável por permitir que participantes cadastrados no Real Digital
 * realizem a operação de compra e venda envolvendo Título Público Federal tokenizado (TPFt)
 * entre si e/ou seus clientes.
 */
contract TPFtOperation1052 is ITPFtOperation1052, TPFtTwoStepOperation, Pausable {
    /**
     * Inicializa o contrato TPFtTwoStepOperation, facilitando operações relacionadas a TPFts em duplo comando.
     * @param addressDiscovery_ Endereço do contrato que facilita a descoberta dos demais endereços de contratos.
     * @param tpft_ Contrato TPFtFacade.
     * @param tpftDvp_ Contrato TPFtDvP para operações de DvP.
     * @param tpftOperationId_ Contrato TPFtOperationId para utilidades relacionadas a TPFts.
     */
    constructor(AddressDiscovery addressDiscovery_, ITPFt tpft_, ITPFtDvP tpftDvp_, TPFtOperationId tpftOperationId_) TPFtTwoStepOperation(addressDiscovery_, tpft_, tpftDvp_, tpftOperationId_) {}

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
    function trade(uint256 operationId, uint256 cnpj8Sender, uint256 cnpj8Receiver, CallerPart callerPart, ITPFt.TPFtData memory tpftData, uint256 tpftAmount, uint256 unitPrice) external whenNotPaused {
        RealDigitalDefaultAccount realDigitalDefaultAccount = _getRealDigitalDefaultAccount();

        address sender = realDigitalDefaultAccount.defaultAccount(cnpj8Sender);
        address receiver = realDigitalDefaultAccount.defaultAccount(cnpj8Receiver);

        OperationStepData memory data = OperationStepData({
            operationId: operationId,
            cnpj8Sender: cnpj8Sender,
            cnpj8Receiver: cnpj8Receiver,
            sender: sender,
            receiver: receiver,
            senderRealTokenizado: RealTokenizado(address(0)),
            receiverRealTokenizado: RealTokenizado(address(0)),
            callerPart: callerPart,
            tpftData: tpftData,
            tpftAmount: tpftAmount,
            unitPrice: unitPrice,
            isCNPJ8: true,
            isRealTokenizado: false,
            isAuction: false,
            extraData: ""
        });

        _executeOperationStep(data);
    }

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
    function trade(uint256 operationId, address sender, address receiver, CallerPart callerPart, ITPFt.TPFtData memory tpftData, uint256 tpftAmount, uint256 unitPrice) external whenNotPaused {
        OperationStepData memory data = OperationStepData({
            operationId: operationId,
            cnpj8Sender: 0,
            cnpj8Receiver: 0,
            sender: sender,
            receiver: receiver,
            senderRealTokenizado: RealTokenizado(address(0)),
            receiverRealTokenizado: RealTokenizado(address(0)),
            callerPart: callerPart,
            tpftData: tpftData,
            tpftAmount: tpftAmount,
            unitPrice: unitPrice,
            isCNPJ8: false,
            isRealTokenizado: false,
            isAuction: false,
            extraData: ""
        });

        _executeOperationStep(data);
    }

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
    function trade(uint256 operationId, address sender, RealTokenizado senderToken, address receiver, RealTokenizado receiverToken, CallerPart callerPart, ITPFt.TPFtData memory tpftData, uint256 tpftAmount, uint256 unitPrice) external whenNotPaused {
        OperationStepData memory data = OperationStepData({
            operationId: operationId,
            cnpj8Sender: 0,
            cnpj8Receiver: 0,
            sender: sender,
            receiver: receiver,
            senderRealTokenizado: senderToken,
            receiverRealTokenizado: receiverToken,
            callerPart: callerPart,
            tpftData: tpftData,
            tpftAmount: tpftAmount,
            unitPrice: unitPrice,
            isCNPJ8: false,
            isRealTokenizado: true,
            isAuction: false,
            extraData: ""
        });

        _executeOperationStep(data);
    }

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
    function trade(uint256 operationId, uint256 cnpj8Sender, uint256 cnpj8Receiver, CallerPart callerPart, ITPFt.TPFtData memory tpftData, uint256 tpftAmount, uint256 unitPrice, string memory noticeNumber) external whenNotPaused {
        RealDigitalDefaultAccount realDigitalDefaultAccount = _getRealDigitalDefaultAccount();

        address sender = realDigitalDefaultAccount.defaultAccount(cnpj8Sender);
        address receiver = realDigitalDefaultAccount.defaultAccount(cnpj8Receiver);

        if (callerPart == CallerPart.TPFtSender) {
            if (cnpj8Sender == BACEN_CNPJ8) {
                if (!hasRole(AUCTION_ROLE, msg.sender)) {
                    revert("TPFtOperation1005: Only BACEN can sell TPFt");
                }
            } else {
                _validateCallerPart(receiver);
                _validateReceiver(receiver, realDigitalDefaultAccount);
            }
        } else if (callerPart == CallerPart.TPFtReceiver) {
            if (cnpj8Sender == BACEN_CNPJ8) {
                _validateCallerPart(sender);
            } else {
                _validateReceiver(receiver, realDigitalDefaultAccount);
            }
        } else {
            revert("Invalid caller");
        }

        OperationStepData memory data = OperationStepData({
            operationId: operationId,
            cnpj8Sender: cnpj8Sender,
            cnpj8Receiver: cnpj8Receiver,
            sender: sender,
            receiver: receiver,
            senderRealTokenizado: RealTokenizado(address(0)),
            receiverRealTokenizado: RealTokenizado(address(0)),
            callerPart: callerPart,
            tpftData: tpftData,
            tpftAmount: tpftAmount,
            unitPrice: unitPrice,
            isCNPJ8: true,
            isRealTokenizado: false,
            isAuction: true,
            extraData: abi.encode(noticeNumber)
        });

        _executeOperationStep(data);
    }

    /**
     * Função externa que cancela uma operação de compra e venda envolvendo TPFt.
     * @param operationId Número de operação + data vigente no formato yyyyMMdd.
     * @param reason Motivo do cancelamento
     */
    function cancel(uint256 operationId, string calldata reason) external {
        _validateOperationDvPId(operationId);

        ITPFtDvP.DvPOperation memory dvpOperation = _getTPFtDvPContract().getDvPOperation(_dvpIds[operationId]);

        if (dvpOperation.dvpId == 0) {
            revert("TPFtOperation1052: OperationIdNotFound");
        }

        _validateCaller(dvpOperation.buyerOperation, dvpOperation.buyer, dvpOperation.seller);

        _cancelDvP(operationId, reason);
    }

    /**
     * Função externa utilizada pela carteira que é detentor da _ROLE_ DEFAULT_ADMIN_ROLE para colocar o contrato em pausa.
     * Apenas o detentor desse papel pode executar essa função, verificado pelo modificador "onlyRole(DEFAULT_ADMIN_ROLE)".
     * O contrato em pausa bloqueará a execução de funções, garantindo que o contrato possa ser temporariamente interrompido.
     */
    function pause() external override onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    /**
     * Função externa utilizada pela carteira que é detentor da _ROLE_ DEFAULT_ADMIN_ROLE para retirar o contrato de pausa.
     * Apenas o detentor desse papel pode executar essa função, verificado pelo modificador "onlyRole(DEFAULT_ADMIN_ROLE)".
     * O contrato retirado de pausa permite a execução normal de todas as funções novamente após ter sido previamente pausado.
     */
    function unpause() external override onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }

    /**
     * Função externa que atualiza o endereço do contrato AddressDiscovery.
     * @param newAddressDiscovery novo endereço do AddressDiscovery.
     */
    function updateAddressDiscovery(AddressDiscovery newAddressDiscovery) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _updateAddressDiscovery(newAddressDiscovery);
    }

    /**
     * Função externa que atualiza o endereço do contrato TPFtFacade.
     * @param newTPFt novo endereço do TPFtFacade.
     */
    function updateTPFt(ITPFt newTPFt) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _updateTPFt(newTPFt);
    }

    /**
     * Função externa que atualiza o endereço do contrato TPFtDvP.
     * @param newTPFtDvP novo endereço do TPFtDvP.
     */
    function updateTPFtDvP(ITPFtDvP newTPFtDvP) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _updateTpftDvPContract(newTPFtDvP);
    }

    /**
     * Função externa que atualiza o endereço do contrato TPFtOperationId.
     * @param newTPFtOperationId novo endereço do TPFtOperationId.
     */
    function updateTPFtOperationId(TPFtOperationId newTPFtOperationId) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _updateTpftOperationId(newTPFtOperationId);
    }

    /**
     * Função interna que valida se a operação foi realizada por cedente válido.
     * @param callerPart Parte que está transmitindo o comando da operação.
     * @param sender Endereço da carteira do cedente da operação.
     * @return Booleano que indica se a operação foi realizada por um cedente válido.
     */
    function _validSender(CallerPart callerPart, address sender) internal view override returns (bool) {
        return !(callerPart == CallerPart.TPFtSender && msg.sender != sender);
    }

    function _getAuthorizedSender(CallerPart callerPart, RealDigitalDefaultAccount realDigitalDefaultAccount) internal view returns (address sender, uint256 cnpj8Sender) {
        sender = realDigitalDefaultAccount.defaultAccount(BACEN_CNPJ8);
        cnpj8Sender = BACEN_CNPJ8;

        if (sender == msg.sender) {
            if (callerPart != CallerPart.TPFtSender) {
                revert("Invalid caller");
            }
        }

        if (callerPart == CallerPart.TPFtSender) {
            if (!hasRole(AUCTION_ROLE, msg.sender)) {
                revert("TPFtOperation1005: Only BACEN can sell TPFt");
            }
            return (sender, cnpj8Sender);
        }
    }

    function _getAuthorizedReceiver(CallerPart callerPart, uint256 cnpj8Receiver, RealDigitalDefaultAccount realDigitalDefaultAccount) internal view returns (address receiver) {
        if (cnpj8Receiver == BACEN_CNPJ8) {
            receiver = realDigitalDefaultAccount.defaultAccount(BACEN_CNPJ8);
        }

        if (cnpj8Receiver == STN_CNPJ8) {
            receiver = realDigitalDefaultAccount.defaultAccount(STN_CNPJ8);
        }

        if (receiver == address(0)) {
            revert("TPFtOperation1006: Just BACEN or STN can buy TPFt");
        }

        if (receiver == msg.sender) {
            if (callerPart != CallerPart.TPFtReceiver) {
                revert("Invalid caller");
            }
        }

        return receiver;
    }

    function _validateReceiver(address receiver, RealDigitalDefaultAccount realDigitalDefaultAccount) internal view {
        if (receiver != realDigitalDefaultAccount.defaultAccount(STN_CNPJ8) && receiver != realDigitalDefaultAccount.defaultAccount(BACEN_CNPJ8)) {
            revert("Auction Operation: Auction not authorized between participants");
        }
    }

    function _validateCallerPart(address wallet) internal view {
        if (wallet == msg.sender) {
            revert("Invalid caller");
        }
    }

    /**
     * Função interna que realiza validações personalizadas.
     */
    function _customValidOperation(OperationStepData memory /*data*/) internal pure override {}

    /**
     * Função externa que retorna o endereço do contrato AddressDiscovery.
     */
    function getAddressDiscovery() public view returns (AddressDiscovery) {
        return _getAddressDiscovery();
    }

    /**
     * Função externa que retorna o endereço do contrato TPFt.
     */
    function getTPFt() public view returns (ITPFt) {
        return _getTPFt();
    }

    /**
     * Função externa que retorna o endereço do contrato TPFtDvP.
     */
    function getTPFtDvP() public view returns (ITPFtDvP) {
        return _getTPFtDvPContract();
    }

    /**
     * Função externa que retorna o endereço do contrato TPFtOperationId.
     */
    function getTPFtOperationId() public view returns (TPFtOperationId) {
        return _getTPFtOperationIdContract();
    }
}

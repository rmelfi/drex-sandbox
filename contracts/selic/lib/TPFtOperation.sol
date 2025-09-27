// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {ITPFt} from "../ITPFt.sol";
import {TPFtOperationId} from "./TPFtOperationId.sol";
import {AddressDiscovery} from "../../realdigital/AddressDiscovery.sol";
import {RealDigitalDefaultAccount} from "../../realdigital/RealDigitalDefaultAccount.sol";
import {REAL_DIGITAL_DEFAULT_ACCOUNT_IDENTIFIER} from "./TPFtConstants.sol";

/**
 * @title TPFtOperation
 * @author BCB
 * @notice _Smart Contract_ que fornece funções utilitárias para operações com TPFts.
 */
abstract contract TPFtOperation is AccessControl {
    /**
     * _Address_ Endereço do contrato que facilita a descoberta dos demais endereços de contratos.
     */
    AddressDiscovery private _addressDiscovery;

    /**
     * _TPFt_ Contrato TPFt.
     */
    ITPFt private _tpft;

    /**
     * _TPFtOperationId_ Contrato TPFtOperationId.
     */
    TPFtOperationId private _tpftOperationId;

    constructor(AddressDiscovery addressDiscovery_, ITPFt tpft_, TPFtOperationId tpftOperationId_) {
        _addressDiscovery = addressDiscovery_;
        _tpft = tpft_;
        _tpftOperationId = tpftOperationId_;
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    /**
     * Valida o número de operação do TPFt.
     * @param operationId Número de operação + data vigente no formato yyyyMMdd.
     */
    function _validateOperationId(uint256 operationId) internal {
        if (!_getTPFtOperationIdContract().validOperationId(operationId)) {
            revert("InvalidOperationId");
        }
    }

    /**
     * Calcula o valor financeiro com base no preço unitário e quantidade de TPFt a ser negociada.
     * @param unitPrice Preço unitário do TPFt.
     * @param tpftAmount Quantidade de TPFt a ser negociada.
     * @return Valor financeiro calculado.
     */
    function _calculateFinancialValue(uint256 unitPrice, uint256 tpftAmount) internal pure returns (uint256) {
        return (unitPrice * tpftAmount) / (10 ** getUnitPriceDecimals());
    }

    /**
     * Atualiza o contrato AddressDiscovery.
     * @param newAddressDiscovery Novo endereço do AddressDiscovery.
     */
    function _updateAddressDiscovery(AddressDiscovery newAddressDiscovery) internal virtual {
        _addressDiscovery = newAddressDiscovery;
    }

    /**
     * Atualiza o contrato TPFt.
     * @param newTPFt Novo endereço do TPFt.
     */
    function _updateTPFt(ITPFt newTPFt) internal virtual {
        _tpft = newTPFt;
    }

    /**
     * Atualiza o endereço do contrato TPFt.
     * @param newTPFt Novo endereço do TPFt.
     */
    function _updateTpftFacadeContract(address newTPFt) internal virtual {
        _tpft = ITPFt(newTPFt);
    }

    /**
     * Atualiza o contrato TPFtOperationId.
     * @param newTpftOperationIdContract Novo endereço do TPFtOperationId.
     */
    function _updateTpftOperationId(TPFtOperationId newTpftOperationIdContract) internal virtual {
        _tpftOperationId = newTpftOperationIdContract;
    }

    /**
     * Retorna o contrato TPFt.
     * @return Retorna o contrato TPFt.
     */
    function _getTPFt() internal view virtual returns (ITPFt) {
        return _tpft;
    }

    /**
     * Retorna o contrato TPFt.
     * @return Retorna o endereço do contrato TPFt.
     */
    function _getTPFtFacadeContract() internal view virtual returns (address) {
        return address(_tpft);
    }

    /**
     * Retorna o contrato RealDigitalDefaultAccount.
     * @return Contrato RealDigitalDefaultAccount.
     */
    function _getRealDigitalDefaultAccount() internal view virtual returns (RealDigitalDefaultAccount) {
        return RealDigitalDefaultAccount(_addressDiscovery.addressDiscovery(REAL_DIGITAL_DEFAULT_ACCOUNT_IDENTIFIER));
    }

    /**
     * Retorna o contrato AddressDiscovery.
     * @return Retorna o contrato AddressDiscovery.
     */
    function _getAddressDiscovery() internal view returns (AddressDiscovery) {
        return _addressDiscovery;
    }

    /**
     * Retorna o contrato TPFtOperationId.
     * @return Retorna o contrato TPFtOperationId.
     */
    function _getTPFtOperationIdContract() internal view returns (TPFtOperationId) {
        return _tpftOperationId;
    }

    /**
     * Valida a data de vencimento do TPFt.
     * @param maturityDate Data de vencimento do TPFt, representada como um valor numérico (timestamp Unix).
     * @return Retorna um booleano que é true se a Data de vencimento do TPFt for igual ou posterior ao timestamp atual do bloco.
     */
    function _validateExpirationDate(uint256 maturityDate) internal view returns (bool) {
        return maturityDate > block.timestamp;
    }

    /**
     * Obtem o número de casas decimais para o preço unitário.
     * @return Número de casas decimais que para o preço unitário será de 8.
     */
    function getUnitPriceDecimals() public pure returns (uint256) {
        return 8;
    }
}

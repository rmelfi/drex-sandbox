// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {RealDigital} from "../../realdigital/RealDigital.sol";
import {RealTokenizado} from "../../realdigital/RealTokenizado.sol";
import {AddressDiscovery} from "../../realdigital/AddressDiscovery.sol";
import {SwapToRetail} from "../../realdigital/SwapToRetail.sol";
import {SwapOneStepFrom} from "../../realdigital/SwapOneStepFrom.sol";
import {KeyDictionary} from "../../realdigital/KeyDictionary.sol";
import {REAL_DIGITAL_CONTRACT_NAME, SWAP_TO_RETAIL, SWAP_ONE_STEP_FROM_CONTRACT_NAME, KEY_DICTIONARY_IDENTIFIER} from "../lib/TPFtConstants.sol";
import {CNPJUtils} from "./CNPJUtils.sol";

library AddressDiscoveryUtils {
    using Strings for uint256;

    /**
     * Função para obter o contrato RealDigital.
     * @param addressDiscovery Endereço do contrato AddressDiscovery.
     */
    function getRealDigital(AddressDiscovery addressDiscovery) internal view returns (RealDigital) {
        return RealDigital(addressDiscovery.addressDiscovery(REAL_DIGITAL_CONTRACT_NAME));
    }

    /**
     * Função para obter o contrato SwapToRetail.
     * @param addressDiscovery Endereço do contrato AddressDiscovery.
     */
    function getSwapToRetail(AddressDiscovery addressDiscovery) internal view returns (SwapToRetail) {
        return SwapToRetail(addressDiscovery.addressDiscovery(SWAP_TO_RETAIL));
    }

    /**
     * Função para obter o contrato KeyDictionary.
     * @param addressDiscovery Endereço do contrato AddressDiscovery.
     */
    function getKeyDictionary(AddressDiscovery addressDiscovery) internal view returns (KeyDictionary) {
        return KeyDictionary(addressDiscovery.addressDiscovery(KEY_DICTIONARY_IDENTIFIER));
    }

    /**
     * Função para obter o contrato RealTokenizado.
     * @param addressDiscovery Endereço do contrato AddressDiscovery.
     * @param cnpj8 CNPJ de 8 digitos do participante.
     * @return Contrato RealTokenizado do participante com cnpj8 passado como parâmetro.
     */
    function getRealTokenizado(AddressDiscovery addressDiscovery, uint256 cnpj8) internal view returns (RealTokenizado) {
        string memory prefix = "RealTokenizado@";
        string memory cnpj8Str = CNPJUtils.padZerosToCNPJ(cnpj8);
        string memory realTokenizadoName = string(abi.encodePacked(prefix, cnpj8Str));
        return RealTokenizado(addressDiscovery.addressDiscovery(keccak256(bytes(realTokenizadoName))));
    }

    function getRealTokenizado(AddressDiscovery addressDiscovery, address wallet) internal view returns (RealTokenizado) {
        if (wallet == address(0)) {
            revert("InvalidWalletAddress");
        }

        KeyDictionary keyDictionary = getKeyDictionary(addressDiscovery);

        if (address(keyDictionary) == address(0)) {
            revert("KeyDictionaryNotFound");
        }

        bytes32 key = keyDictionary.getKey(wallet);

        if (key == bytes32(0)) {
            revert("WalletNotRegisteredInKeyDictionary");
        }

        KeyDictionary.CustomerData memory customerData = keyDictionary.getCustomerData(key);

        RealTokenizado realTokenizado = getRealTokenizado(addressDiscovery, customerData.cnpj8);

        if (address(realTokenizado) == address(0)) {
            revert("RealTokenizadoNotFound");
        }

        if (realTokenizado.reserve() == address(0)) {
            revert("ReserveAccountNotFound");
        }

        RealDigital realDigital = getRealDigital(addressDiscovery);

        if (address(realDigital) == address(0)) {
            revert("RealDigitalNotFound");
        }

        if (!realDigital.verifyAccount(realTokenizado.reserve())) {
            revert("ReserveAccountNotEnabledInRealDigital");
        }

        return realTokenizado;
    }

    function getSwapOneStepFrom(AddressDiscovery addressDiscovery) internal view returns (SwapOneStepFrom) {
        return SwapOneStepFrom(addressDiscovery.addressDiscovery(SWAP_ONE_STEP_FROM_CONTRACT_NAME));
    }
}

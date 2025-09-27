// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

library CNPJUtils {
    using Strings for uint256;

    /**
     * Função para acrescentar zeros a um CNPJ com menos de 8 algarismos.
     * @param cnpj8 CNPJ do participante.
     * @return Retorna o CNPJ com zeros a esquerda.
     */
    function padZerosToCNPJ(uint256 cnpj8) internal pure returns (string memory) {
        if(cnpj8 > 99999999) {
            revert("CPNJUtils: CNPJ must be less than or equal to 8 digits");
        }
        string memory numberStr = cnpj8.toString();
        bytes memory numberBytes = bytes(numberStr);
        bytes memory paddedBytes = new bytes(8);

        uint paddingLength = 8 - numberBytes.length;

        for (uint i = 0; i < paddingLength; i++) {
            paddedBytes[i] = bytes1(uint8(48));
        }

        for (uint i = 0; i < numberBytes.length; i++) {
            paddedBytes[paddingLength + i] = numberBytes[i];
        }

        return string(paddedBytes);
    }
}

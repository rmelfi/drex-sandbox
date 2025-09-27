// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import {Context} from "@openzeppelin/contracts/utils/Context.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

/**
 * @title TPFtFacade
 * @author BCB
 * @notice _Smart Contract_ responsável da fachada para interação com Título Público Federal tokenizado (TPFt).
 */
contract TPFtFacade is ERC1967Proxy {
    /**
     * Seletor de função constante privado para "initialize(address,address,address,address)"
     */
    string private constant FUNC_SELECTOR = "initialize(address,address,address,address)";
    constructor(
        address tpftLogic_,
        address admin_,
        address tpftStorage_,
        address tpftAccessControl_,
        address addressDiscovery_
    ) ERC1967Proxy(tpftLogic_, abi.encodeWithSignature(FUNC_SELECTOR, admin_, tpftStorage_, tpftAccessControl_, addressDiscovery_)) {}

    /**
     * Função externa que consulta o endereço atual do contrato de lógica do TPFt.
     */
    function getTPFtLogicAddress() external view returns (address) {
        return _getImplementation();
    }
}

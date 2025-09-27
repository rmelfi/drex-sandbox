// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

/**
 * @title TPFtOperationId
 * @author BCB
 * @notice _Smart Contract_ que gerencia a validade do número de operação + data vigente no formato yyyyMMdd para evitar sua reutilização.
 */
contract TPFtOperationId {
    mapping(uint256 => bool) private _usedOperationIds;

    /**
     * Verifica se o número de operação + data vigente no formato yyyyMMdd fornecido é válido e pode ser usado.
     * @param operationId Número de operação + data vigente no formato yyyyMMdd a ser validado.
     * @return Retorna um valor booleano indicando se o número de operação + data  vigente no formato yyyyMMdd é válido ou não.
     */
    function validOperationId(uint256 operationId) public returns (bool) {
        if (_usedOperationIds[operationId]) return false;

        _usedOperationIds[operationId] = true;

        return true;
    }
}

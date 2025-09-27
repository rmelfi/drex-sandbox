// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/AccessControl.sol";

/**
 * @title AddressDiscovery
 * @author BCB
 * @notice _Smart Contract_ utilitário para facilitar a descoberta dos demais endereços de contratos na rede do Piloto RD
*/
contract AddressDiscovery is AccessControl {
  /**
   * _Role_ de acesso, pertencente a autoridade do contrato
  */
  bytes32 public constant ACCESS_ROLE = keccak256("ACCESS_ROLE");

  /**
   * _Mapping_ do endereço dos contratos, a chave é o hash keccak256 do nome do contrato
  */
  mapping(bytes32 => address) public addressDiscovery;

  /**
   * Construtor
   * @param _authority Autoridade do contrato, pode atualizar os endereços dos contratos
   * @param _admin Administrador, pode trocar a autoridade
  */
  constructor(address _authority, address _admin) {
    _grantRole(DEFAULT_ADMIN_ROLE, _admin);
    _grantRole(ACCESS_ROLE, _authority);
    _grantRole(ACCESS_ROLE, msg.sender);
  }

  /**
   * Atualiza o endereço de um contrato, permitido apenas para a autoridade
   * @param smartContract Hash keccak256 do nome do contrato
   * @param newAddress Endereço do contrato
  */
  function updateAddress(bytes32 smartContract, address newAddress) public onlyRole(ACCESS_ROLE) {
    addressDiscovery[smartContract] = newAddress;
  }
}
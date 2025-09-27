// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/AccessControl.sol";

/**
 * @title CBDCAccessControl
 * @author BCB
 * @notice _Smart Contract_ responsável pela camada de controle de acesso para o Real Digital/Tokenizado
 * 
 * Suas principais funcionalidades são:
 * - Determinar quais carteiras podem enviar/receber tokens
 * - Controlar os papeis de qual endereço pode emitir/resgatar/congelar saldo de uma carteira
*/
abstract contract CBDCAccessControl is AccessControl {
    /**
     * _Role_ que permite pausar o contrato
    */
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    /**
     * _Role_ que permite fazer o `mint` nos contratos de token
    */
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    /**
     * _Role_ que permite habilitar um endereço
     */
    bytes32 public constant ACCESS_ROLE = keccak256("ACCESS_ROLE");
    /**
     * _Role_ que permite acesso à função `move`, ou seja, transferir o token de outra carteira
    */
    bytes32 public constant MOVER_ROLE = keccak256("MOVER_ROLE");
    /**
     * _Role_ que permite acesso à função `burn`
    */
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");
    /**
     * _Role_ que permite bloquear saldo de uma carteira, por exemplo para o [_swap_ de dois passos](./SwapTwoSteps.md)
    */
    bytes32 public constant FREEZER_ROLE = keccak256("FREEZER_ROLE");

    /**
     * _Mapping_ das contas autorizadas a receber o token
    */
    mapping(address => bool) public authorizedAccounts;
    
    /**
     * Evento de carteira habilitada
     * @param member Carteira habilitada
    */
    event EnabledAccount(address member);
    /**
     * Evento de carteira desabilitada
     * @param member Carteira desabilitada
    */
    event DisabledAccount(address member);

    /**
     * Construtor
     * @param _authority Autoridade do contrato, pode fazer todas as operações com o token
     * @param _admin Administrador do contrato, pode trocar a autoridade do contrato caso seja necessário
    */
    constructor(address _authority, address _admin) {
        _grantRole(DEFAULT_ADMIN_ROLE, _admin);
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, _authority);
        _grantRole(MINTER_ROLE, _authority);
        _grantRole(ACCESS_ROLE, _authority);
        _grantRole(MOVER_ROLE, _authority);
        _grantRole(BURNER_ROLE, _authority);
        _grantRole(FREEZER_ROLE, _authority);       
    }

    /**
     * Modificador que checa se tanto o pagador quanto o recebedor estão habilitados a receber o token
     * @param from Carteira do pagador
     * @param to Carteira do recebedor
    */
    modifier checkAccess(address from, address to) {
        if(from != address(0)) {
            require(authorizedAccounts[from],"BCAccessControl:access denied");
        }

        if(to != address(0)) {
            require(authorizedAccounts[to],"BCAccessControl:access denied");
        }
        _;
    }

    /**
     * Habilita a carteira a receber o token
     * @param member Carteira a ser habilitada
    */
    function enableAccount(address member) public onlyRole(ACCESS_ROLE) {
        require(member!= address(0), "BCAccessControl: address cannot be zero");
        authorizedAccounts[member] = true;
        emit EnabledAccount(member);
    }

    /**
     * Desabilita a carteira
     * @param member Carteira a ser desabilitada
    */
    function disableAccount(address member) public onlyRole(ACCESS_ROLE) {
        require(member!= address(0), "BCAccessControl: address cannot be zero");
        authorizedAccounts[member] = false;
        emit DisabledAccount(member);
    }

    /**
     * Checa se a carteira pode receber o token
     * @param account Carteira a ser checada
    */
    function verifyAccount(address account) public view virtual returns (bool) {
        return authorizedAccounts[account];
    }
}

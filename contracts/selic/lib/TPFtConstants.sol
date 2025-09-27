// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

bytes32 constant REAL_DIGITAL_CONTRACT_NAME = keccak256("RealDigital");
bytes32 constant SWAP_ONE_STEP_FROM_CONTRACT_NAME = keccak256("SwapOneStepFrom");
bytes32 constant SWAP_TO_RETAIL = keccak256("SwapToRetail");
bytes32 constant REAL_DIGITAL_DEFAULT_ACCOUNT_IDENTIFIER = keccak256("RealDigitalDefaultAccount");
bytes32 constant KEY_DICTIONARY_IDENTIFIER = keccak256("KeyDictionary");

uint256 constant STN_CNPJ8 = 394460;
uint256 constant BACEN_CNPJ8 = 38166;

bytes32 constant MINTER_ROLE = keccak256("MINTER_ROLE");
bytes32 constant DIRECT_PLACEMENT_ROLE = keccak256("DIRECT_PLACEMENT_ROLE");
bytes32 constant AUCTION_PLACEMENT_ROLE = keccak256("AUCTION_PLACEMENT_ROLE");
bytes32 constant AUCTION_ROLE = keccak256("AUCTION_ROLE");
bytes32 constant FREEZER_ROLE = keccak256("FREEZER_ROLE");
bytes32 constant REPAYMENT_ROLE = keccak256("REPAYMENT_ROLE");
bytes32 constant DEFAULT_ADMIN_ROLE = 0x00;
bytes32 constant RECOVERY_WITHDRAWER_ROLE = keccak256("RECOVERY_WITHDRAWER_ROLE");
bytes32 constant DEPOSITOR_ROLE = keccak256("DEPOSITOR_ROLE");
bytes32 constant WRITER_ROLE = keccak256("WRITER_ROLE");
bytes32 constant COLLATERAL_DEPOSITOR_ROLE = keccak256("COLLATERAL_DEPOSITOR_ROLE");
bytes32 constant COLLATERAL_RETURN_ROLE = keccak256("COLLATERAL_RETURN_ROLE");
bytes32 constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

uint256 constant MAX_FINANCIAL_VALUE = 99999999999999;

/**
 * _Enum_ que representa o tipo de operação, seja COMPRA ou VENDA
 */
enum OperationType {
    BUY,
    SELL
}

/**
 * _Enum_ Parte que está transmitindo o comando da operação. Se for o cedente deve ser informado CallerPart.TPFtSender, se for o cessionário deve ser informado CallerPart.TPFtReceiver.
 * @dev Somente é utilizado nas operações de duplo comando.
 */
enum CallerPart {
    TPFtSender,
    TPFtReceiver
}

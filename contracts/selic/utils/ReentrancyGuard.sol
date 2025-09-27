// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

abstract contract ReentrancyGuard {
    bool internal locked;

    modifier noReentrant() {
        require(!locked, "No re-entrancy");
        locked = true;
        _;
        locked = false;
    }
}

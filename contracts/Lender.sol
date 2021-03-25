// SPDX-License-Identifier: MIT
pragma solidity ^0.7.2;

abstract contract Lender {

    address public immutable owner;

    constructor(address _owner) {
        owner = _owner;
    }

    modifier onlyOwner {
        _onlyOwner();
        _;
    }

    function _onlyOwner() internal view {
        require(
            msg.sender == owner,
            "Unauthorized"
        );
    }

}
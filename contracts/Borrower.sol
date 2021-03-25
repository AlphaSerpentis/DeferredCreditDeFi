// SPDX-License-Identifier: MIT
pragma solidity ^0.7.2;

import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title Borrower contract
/// @author Amethyst C. (https://github.com/AlphaSerpentis)
/// @notice Smart contract to collateralize the account for the borrower
/// @dev Borrower stores funds to collateralize their account and acts as an abstract contract to inherit to a base smart contract
abstract contract Borrower {
    using SafeMath for uint256;
    struct CurrentDebt {
        uint256 tokenAmountDue;
        uint256 paymentDueAt;
    }
    struct TokenDebt {
        uint256 totalObligations;
        mapping(address => CurrentDebt) currentDebts;
    }
    
    mapping(address => TokenDebt) private tokenObligations;
    address public immutable owner;

    event NewCurrentDebtIssued(address _lender, address _tokenCollateral, uint256 _amountDue);
    event CurrentDebtPartialPay(address _lender, address _tokenCollateral, uint256 _amountPaid);
    event CurrentDebtPaidOff(address _lender, address _tokenCollateral, uint256 _amountRemaining);

    constructor(address _owner) {
        owner = _owner;
    }

    modifier onlyOwner {
        _onlyOwner();
        _;
    }
    modifier onlyLender(address _tokenCollateral) {
        _onlyLender(_tokenCollateral);
        _;
    }

    function payCurrentDebt(
        address _token,
        uint256 _amount,
        address _creditor
    )
        external
        onlyOwner
    {
        require(
            _token != address(0),
            "Zero address"
        );
        TokenDebt storage tokenDebt = tokenObligations[_token];
    }
    function forceRepayment(
        address _token
    )
        external
        onlyLender(_token)
    {
        require(
            _token != address(0),
            "Zero address"
        );
        TokenDebt storage tokenDebt = tokenObligations[_token];
        require(
            block.timestamp >= tokenDebt.currentDebts[msg.sender].paymentDueAt,
            "Payment is not due yet!"
        );
        IERC20 token = IERC20(_token);
        token.transfer(msg.sender, tokenDebt.currentDebts[msg.sender].tokenAmountDue);

        emit CurrentDebtPaidOff(msg.sender, _token, tokenDebt.currentDebts[msg.sender].tokenAmountDue);

        delete tokenDebt.currentDebts[msg.sender];
    }
    function forceRepayment(
        address _token,
        address _recipient
    )
        external
        onlyLender(_token)
    {
        require(
            _token != address(0),
            "Zero address"
        );
        TokenDebt storage tokenDebt = tokenObligations[_token];
        require(
            block.timestamp >= tokenDebt.currentDebts[msg.sender].paymentDueAt,
            "Payment is not due yet!"
        );
        IERC20 token = IERC20(_token);
        token.transfer(_recipient, tokenDebt.currentDebts[msg.sender].tokenAmountDue);

        emit CurrentDebtPaidOff(msg.sender, _token, tokenDebt.currentDebts[msg.sender].tokenAmountDue);

        delete tokenDebt.currentDebts[msg.sender];
    }
    function withdraw(
        address _token,
        uint256 _amount,
        address _recipient
    )
        external
        onlyOwner
    {
        require(
            _token != address(0),
            "Zero address"
        );
        IERC20 token = IERC20(_token);
        require(
            _amount <= token.balanceOf(address(this)) - tokenObligations[_token].totalObligations,
            "Withdrawing too much"
        );

        token.transfer(_recipient, _amount);
    }
    function _onlyOwner() internal view {
        require(
            msg.sender == owner,
            "Unauthorized"
        );
    }
    function _onlyLender(address _tokenCollateral) internal view {
        require(
            tokenObligations[_tokenCollateral].currentDebts[msg.sender].paymentDueAt != 0,
            "Unauthorized (lender)"
        );
    }

}
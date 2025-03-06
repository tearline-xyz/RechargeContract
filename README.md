# RechargeContract

A simple, upgradeable BSC/opBNB smart contract for handling recharges, check-ins, and withdrawals. Built with security and upgradeability in mind using OpenZeppelin's upgradeable contracts and following the UUPS (Universal Upgradeable Proxy Standard) pattern.

# Overview

The RechargeContract allows users to:
Recharge the contract with Ether by providing an orderId.

Check in using a userId.

Withdraw funds as the owner, either partially or entirely.

The contract includes security features like reentrancy protection and is designed to be upgradeable while maintaining ownership control.

# Features

Recharge: Users can send Ether to the contract with an associated orderId. The amount must be greater than zero.

Check-In: Users can check in using a userId (non-zero value required).

Withdraw: The owner can withdraw a specified amount or all funds from the contract.

Upgradeability: Implements the UUPS pattern via OpenZeppelin's UUPSUpgradeable for safe upgrades.

Security: Uses ReentrancyGuardUpgradeable to prevent reentrancy attacks and OwnableUpgradeable for access control.

# Events

Recharge(uint256 orderId, uint256 payableAmount): Emitted when a user recharges the contract.

CheckIn(uint256 userId): Emitted when a user checks in.



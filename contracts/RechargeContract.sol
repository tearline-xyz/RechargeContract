// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";

contract RechargeContract is UUPSUpgradeable, OwnableUpgradeable, ReentrancyGuardUpgradeable {

    // Event to print orderId and payableAmount
    event Recharge(uint256 orderId, uint256 payableAmount);

    function initialize() public initializer {
        // Initialize the contract with the deployer as the owner
        __Ownable_init(msg.sender);
        __ReentrancyGuard_init();
    }

    function recharge(uint256 orderId) public payable nonReentrant {
        // Check if the payableAmount is greater than 0
        require(msg.value > 0, "Recharge amount must be greater than zero");

        // Emit event to print orderId and payableAmount
        emit Recharge(orderId, msg.value);
    }

    function checkIn(uint256 userId) public {
        // Prevent special value (like 0) for userId
        require(userId != 0, "Invalid User ID"); 
        emit CheckIn(userId);
    }

    // Event emitted when a user checks in
    event CheckIn(uint256 userId);

    function withdraw(uint256 amount) public onlyOwner nonReentrant {
        // Check if the withdrawal amount is positive
        require(amount > 0, "Withdraw amount must be greater than zero");
        // Ensure the contract has enough balance for withdrawal
        require(amount <= address(this).balance, "Insufficient balance in contract");
        (bool success, ) = payable(owner()).call{value: amount}("");
        require(success, "Withdraw failed");
    }

    // New function to withdraw all balance
    function withdrawAll() public onlyOwner nonReentrant {
        uint256 balance = address(this).balance;
        require(balance > 0, "Contract has no balance to withdraw");
        (bool success, ) = payable(owner()).call{value: balance}("");
        require(success, "Withdraw all failed");
    }

    // UUPS upgrade function, callable only by the contract owner
    function _authorizeUpgrade(address) internal override onlyOwner {}
}
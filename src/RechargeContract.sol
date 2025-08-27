// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";

contract RechargeContract is UUPSUpgradeable, OwnableUpgradeable, ReentrancyGuardUpgradeable {

    // Event emitted with orderId and payableAmount
    event Recharge(uint256 orderId, uint256 payableAmount);

    function initialize() public initializer {
    // Initialize the contract, setting the deployer as the owner
        __Ownable_init(msg.sender);
        __ReentrancyGuard_init();
    }

    function recharge(uint256 orderId) public payable nonReentrant {
    // Ensure the payableAmount is greater than 0
        require(msg.value > 0, "Recharge amount must be greater than zero");

    // Emit event with orderId and payableAmount
        emit Recharge(orderId, msg.value);
    }

    function checkIn(uint256 userId) public {
    // Prevent userId from being a special value (such as 0)
        require(userId != 0, "Invalid User ID"); 
        emit CheckIn(userId);
    }

    // Event emitted when a user successfully checks in
    event CheckIn(uint256 userId);

    function withdraw(uint256 amount) public onlyOwner nonReentrant {
    // Ensure the withdrawal amount is positive
        require(amount > 0, "Withdraw amount must be greater than zero");
    // Ensure the contract has sufficient balance for withdrawal
        require(amount <= address(this).balance, "Insufficient balance in contract");
        (bool success, ) = payable(owner()).call{value: amount}("");
        require(success, "Withdraw failed");
    }

    // Function to withdraw the entire contract balance
    function withdrawAll() public onlyOwner nonReentrant {
        uint256 balance = address(this).balance;
    require(balance > 0, "Contract has no balance to withdraw"); // Ensure there is balance to withdraw
        (bool success, ) = payable(owner()).call{value: balance}("");
        require(success, "Withdraw all failed");
    }

    // UUPS upgrade authorization function, callable only by the contract owner
    function _authorizeUpgrade(address) internal override onlyOwner {}
}


// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import {PausableUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract RechargeContract is UUPSUpgradeable, OwnableUpgradeable, ReentrancyGuardUpgradeable, PausableUpgradeable {
    using SafeERC20 for IERC20;

    // Version identifier
    string public constant VERSION = "2.0.0";

    // Event emitted with orderId and payableAmount (keep original event unchanged)
    event Recharge(uint256 orderId, uint256 payableAmount);
    
    // Event emitted for token recharge
    event RechargeByToken(uint256 orderId, address token, uint256 payableAmount);
    
    // Event emitted when a user successfully checks in
    event CheckIn(uint256 userId);

    // Reserve storage slots for future upgrades (important for UUPS)
    uint256[45] private __gap;

    // @dev DEPRECATED: Do not call after V1 deployment. Use initializeV2() for upgrades.
    function initialize() public initializer {
        // Initialize the contract, setting the deployer as the owner
        __Ownable_init(msg.sender);
        __ReentrancyGuard_init();
        __UUPSUpgradeable_init();
    }

    // New initialization function for V2 upgrade
    function initializeV2() public onlyOwner reinitializer(2) {
        // Initialize pausable functionality
        __Pausable_init();
        
        // Add any other V2-specific initialization here
        // Note: Do NOT call __Ownable_init or __ReentrancyGuard_init again
        // These are already initialized in V1
    }

    // Original ETH recharge function (unchanged)
    function recharge(uint256 orderId) public payable nonReentrant whenNotPaused {
        // Ensure the payableAmount is greater than 0
        require(msg.value > 0, "Recharge amount must be greater than zero");

        // Emit event with orderId and payableAmount
        emit Recharge(orderId, msg.value);
    }

    // Token recharge function (renamed to avoid confusion with function overloading)
    function rechargeWithToken(uint256 orderId, address token, uint256 payableAmount) public nonReentrant whenNotPaused {
        require(token != address(0), "Invalid token address");
        require(payableAmount > 0, "Recharge amount must be greater than zero");
        
        // Use SafeERC20 for secure token transfer
        IERC20(token).safeTransferFrom(msg.sender, address(this), payableAmount);
        
        // Emit token recharge event
        emit RechargeByToken(orderId, token, payableAmount);
    }

    function checkIn(uint256 userId) public whenNotPaused {
        // Prevent userId from being a special value (such as 0)
        require(userId != 0, "Invalid User ID"); 
        emit CheckIn(userId);
    }

    // ETH withdrawal function (original functionality unchanged)
    function withdraw(uint256 amount) public onlyOwner nonReentrant {
        // Ensure the withdrawal amount is positive
        require(amount > 0, "Withdraw amount must be greater than zero");
        // Ensure the contract has sufficient balance for withdrawal
        require(amount <= address(this).balance, "Insufficient balance in contract");
        (bool success, ) = payable(owner()).call{value: amount}("");
        require(success, "Withdraw failed");
    }

    // ETH withdraw all function (original functionality unchanged)
    function withdrawAll() public onlyOwner nonReentrant {
        uint256 balance = address(this).balance;
        require(balance > 0, "Contract has no balance to withdraw");
        (bool success, ) = payable(owner()).call{value: balance}("");
        require(success, "Withdraw all failed");
    }

    // Token withdrawal function
    function withdrawToken(address token, uint256 amount) public onlyOwner nonReentrant {
        require(token != address(0), "Invalid token address");
        require(amount > 0, "Withdraw amount must be greater than zero");
        
        IERC20 tokenContract = IERC20(token);
        uint256 contractBalance = tokenContract.balanceOf(address(this));
        // Ensure the contract has sufficient token balance for withdrawal
        require(amount <= contractBalance, "Insufficient token balance in contract");
        
        // Use SafeERC20 for secure token transfer
        tokenContract.safeTransfer(owner(), amount);
    }

    // Token withdraw all function
    function withdrawAllToken(address token) public onlyOwner nonReentrant {
        require(token != address(0), "Invalid token address");
        
        IERC20 tokenContract = IERC20(token);
        uint256 contractBalance = tokenContract.balanceOf(address(this));
        // Ensure the contract has token balance to withdraw
        require(contractBalance > 0, "Contract has no token balance to withdraw");
        
        // Use SafeERC20 for secure token transfer
        tokenContract.safeTransfer(owner(), contractBalance);
    }

    // Emergency pause function
    function pause() public onlyOwner {
        _pause();
    }

    // Unpause function
    function unpause() public onlyOwner {
        _unpause();
    }

    // UUPS upgrade authorization function, callable only by the contract owner
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {
        // Additional upgrade validation can be added here if needed
    }
}

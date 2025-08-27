// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "forge-std/Test.sol";
import {RechargeContract} from "../src/RechargeContract_v2.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

// Mock USDT implemented with OpenZeppelin
contract MockUSDT is ERC20 {
    constructor() ERC20("Mock USDT", "USDT") {
        _mint(msg.sender, 1_000_000e18); // Mint initial tokens to deployer
    }

    // Convenient mint function for testing, mint tokens to other accounts
    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}

error OwnableUnauthorizedAccount(address);
error EnforcedPause();

contract RechargeContractTest is Test {
    RechargeContract public recharge;
    MockUSDT public usdt;

    address public deployer = address(0xAAAA);
    address public owner = address(0xABCD);
    address public user = address(0x1234);

    function setUp() public {
        vm.startPrank(deployer);

        // Deploy contract
        recharge = new RechargeContract();
        recharge.initialize();
        recharge.initializeV2();

        // Transfer ownership to owner
        recharge.transferOwnership(owner);
        
        vm.stopPrank();

        // Deploy MockUSDT
        usdt = new MockUSDT();

        // Mint 100 USDT to user
        usdt.mint(user, 100e18);

        // Fund user account with 10 ETH to avoid OutOfFunds
        vm.deal(user, 10 ether);
    }

    /// @notice Test ERC20 recharge & withdrawal
    function testRechargeAndWithdrawUSDT() public {
        uint256 amount = 1e18; // 1 USDT

        // User approves contract to spend USDT
        vm.startPrank(user);
        usdt.approve(address(recharge), amount);

        // Expect RechargeByToken event
        vm.expectEmit(true, true, true, true);
        emit RechargeContract.RechargeByToken(1, address(usdt), amount);

        // Call recharge function
        recharge.rechargeWithToken(1, address(usdt), amount);
        vm.stopPrank();

        // Verify contract has 1 USDT
        assertEq(usdt.balanceOf(address(recharge)), amount);

        // Owner withdraws
        vm.startPrank(owner);
        recharge.withdrawToken(address(usdt), amount);
        vm.stopPrank();

        assertEq(usdt.balanceOf(owner), amount, "Owner should have 1 USDT");
        assertEq(usdt.balanceOf(address(recharge)), 0, "Contract should be empty");
    }

    /// @notice Test ETH recharge & withdrawal
    function testRechargeAndWithdrawETH() public {
        uint256 amount = 1 ether;

        // Expect Recharge event
        vm.expectEmit(true, true, true, true);
        emit RechargeContract.Recharge(2, amount);

        // User calls recharge to deposit ETH
        vm.prank(user);
        recharge.recharge{value: amount}(2);

        // Contract balance should be 1 ether
        assertEq(address(recharge).balance, amount);

        // Owner withdraws 1 ether
        vm.startPrank(owner);
        recharge.withdraw(amount);
        vm.stopPrank();

        assertEq(address(recharge).balance, 0, "Contract ETH balance should be 0");
    }

    function testRechargeWhilePaused() public {
        // Non-owner cannot pause
        vm.prank(user);
        vm.expectRevert(abi.encodeWithSelector(OwnableUnauthorizedAccount.selector, user));
        recharge.pause();

        // Owner pauses contract
        vm.prank(owner);
        recharge.pause();

        // Try to recharge while paused
        vm.prank(user);
        vm.expectRevert(EnforcedPause.selector);
        recharge.recharge{value: 1 ether}(1);

        // Unpause and try again
        vm.prank(owner);
        recharge.unpause();
        assertFalse(recharge.paused());

        vm.prank(user);

        // Expect Recharge event
        vm.expectEmit(true, true, true, true);
        emit RechargeContract.Recharge(2, 1 ether);
        recharge.recharge{value: 1 ether}(2);
    }    
}

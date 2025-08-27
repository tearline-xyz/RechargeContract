// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script} from "forge-std/Script.sol";
import {console2} from "forge-std/console2.sol";

// Import your contract
import {RechargeContract} from "../src/RechargeContract_v2.sol";

contract UpgradeScript is Script {
    // bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1)
    bytes32 constant IMPLEMENTATION_SLOT =
        0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    address constant PROXY_ADDRESS = 0x502f6503BF4E1b37A63ac6e3f199EedcB988Cd6e;

    // Deploy on devnet
    function run() external {
        // Get previous state
        RechargeContract proxy = RechargeContract(PROXY_ADDRESS);
        address currentOwner = proxy.owner();
        address oldImplementation = getImplementationAddress(PROXY_ADDRESS);
        console2.log("Current proxy address:", PROXY_ADDRESS);
        console2.log("Current contract owner:", currentOwner);        
        console2.log("Current implementation:", oldImplementation);

        // Deploy new implementation contract V2
        uint256 pk = vm.envUint("PRIVATE_KEY");
        console2.log("Using provided private key:", pk);
        console2.log("Deploying new implementation...");
        vm.startBroadcast(pk);
        RechargeContract newImplementation = new RechargeContract();
        console2.log("New implementation (V2) deployed at:", address(newImplementation));
        vm.stopBroadcast(); 

        // Execute upgrade operation
        console2.log("Upgrading to new implementation...");              
        bytes memory initData = abi.encodeWithSignature("initializeV2()");
        vm.prank(currentOwner);
        proxy.upgradeToAndCall(address(newImplementation), initData);

        // Verify if upgrade was successful
        if (getImplementationAddress(PROXY_ADDRESS) == address(newImplementation)) {
            console2.log("Implementation address verified!");
        } else {
            console2.log("Implementation address mismatch!");
            return;
        }

        if (proxy.owner() == currentOwner) {
            console2.log("Owner address verified!");
        } else {
            console2.log("Owner address mismatch!");
            return;
        }

        bool paused = proxy.paused();
        if (paused) {
            console2.log("Contract is paused after upgrade.");
        } else {
            console2.log("Contract is NOT paused after upgrade.");
        }
    }

    function getImplementationAddress(address proxy) internal view returns (address) {
        bytes32 slot = vm.load(proxy, IMPLEMENTATION_SLOT);
        return address(uint160(uint256(slot)));
    }    
}

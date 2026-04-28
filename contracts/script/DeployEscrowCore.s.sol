// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {EscrowCore} from "../src/EscrowCore.sol";

contract DeployEscrowCore is Script {
    
    function run() external returns (EscrowCore escrow) {
        address usdc = _getUSDC();

        vm.startBroadcast();

        escrow = new EscrowCore(usdc);

        console.log("EscrowCore deployed at:", address(escrow));
        console.log("Owner:", escrow.owner());
        console.log("USDC token:", address(escrow.usdc()));
        console.log("Chain ID:", block.chainid);

        vm.stopBroadcast();
    }

    function _getUSDC() internal view returns (address) {
        if (block.chainid == 84532) {
            // Base Sepolia testnet
            return 0x036CbD53842c5426634e7929541eC2318f3dCF7e;
        } else if (block.chainid == 8453) {
            // Base Mainnet
            return 0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913;
        } else {
            revert("DeployEscrowCore: unsupported chain");
        }
    }
}

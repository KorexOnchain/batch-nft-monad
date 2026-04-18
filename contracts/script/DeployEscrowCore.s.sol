// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {EscrowCore} from "../src/EscrowCore.sol";

contract DeployEscrowCore is Script {
    function run() external returns (EscrowCore escrow) {
        vm.startBroadcast();

        escrow = new EscrowCore();

        console.log("EscrowCore deployed at:", address(escrow));
        console.log("Owner:", escrow.owner());
        console.log("Chain ID:", block.chainid);

        vm.stopBroadcast();
    }
}
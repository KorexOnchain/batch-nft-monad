// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/MonadNFT.sol";
import "../src/BatchMinter.sol";

contract Deploy is Script {
    function run() external {
        vm.startBroadcast();

        MonadNFT nft = new MonadNFT();
        console.log("MonadNFT deployed at:", address(nft));

        BatchMinter batchMinter = new BatchMinter(address(nft));
        console.log("BatchMinter deployed at:", address(batchMinter));

        nft.setBatchMinter(address(batchMinter));
        console.log("BatchMinter authorized!");

        console.log("Remaining supply:", batchMinter.remainingSupply());

        vm.stopBroadcast();
    }
}
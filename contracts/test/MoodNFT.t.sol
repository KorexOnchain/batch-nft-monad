// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/MonadNFT.sol";
import "../src/BatchMinter.sol";

contract MonadNFTTest is Test {
    MonadNFT public nft;
    BatchMinter public batchMinter;
    address public owner = address(1);
    address public user = address(2);

    function setUp() public {
        vm.startPrank(owner);
        nft = new MonadNFT();
        batchMinter = new BatchMinter(address(nft));
        nft.setBatchMinter(address(batchMinter));
        vm.stopPrank();
    }

    function test_BatchMint1000() public {
        vm.prank(owner);
        batchMinter.batchMint(owner, 1000);
        assertEq(nft.totalSupply(), 1000);
    }

    function test_PublicMint() public {
        vm.prank(user);
        batchMinter.publicMint();
        assertEq(nft.totalSupply(), 1);
        assertEq(nft.ownerOf(1), user);
    }

    function test_TokenURI() public {
        vm.prank(owner);
        batchMinter.batchMint(owner, 1);
        string memory uri = nft.tokenURI(1);
        assertTrue(bytes(uri).length > 0);
    }

    function test_RemainingSupply() public {
        assertEq(batchMinter.remainingSupply(), 1000);
        vm.prank(owner);
        batchMinter.batchMint(owner, 500);
        assertEq(batchMinter.remainingSupply(), 500);
    }
}
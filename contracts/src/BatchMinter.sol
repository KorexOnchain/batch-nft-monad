// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./MonadNFT.sol";

contract BatchMinter {
    MonadNFT public nftContract;
    address public owner;
    
    uint256 public constant BATCH_SIZE = 2000;

    event BatchMinted(
        address indexed to, 
        uint256 startId, 
        uint256 endId, 
        uint256 count,
        uint256 timeTaken
    );

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    constructor(address _nftContract) {
        nftContract = MonadNFT(_nftContract);
        owner = msg.sender;
    }

    function batchMint(address to, uint256 amount) external onlyOwner {
        require(amount > 0 && amount <= BATCH_SIZE, "Invalid amount");
        require(
            nftContract.totalSupply() + amount <= nftContract.MAX_SUPPLY(),
            "Exceeds max supply"
        );

        uint256 startId = nftContract.totalSupply() + 1;
        uint256 startTime = block.timestamp;

        for (uint256 i = 0; i < amount; i++) {
            nftContract.mint(to, startId + i);
        }

        uint256 timeTaken = block.timestamp - startTime;

        emit BatchMinted(to, startId, startId + amount - 1, amount, timeTaken);
    }

    function publicMint() external {
        require(
            nftContract.totalSupply() < nftContract.MAX_SUPPLY(),
            "Sold out"
        );
        uint256 tokenId = nftContract.totalSupply() + 1;
        nftContract.mint(msg.sender, tokenId);
    }

    function remainingSupply() external view returns (uint256) {
        return nftContract.MAX_SUPPLY() - nftContract.totalSupply();
    }
}
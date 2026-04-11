// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

contract MonadNFT is ERC721, Ownable {
    error MonadNFT__NotBatchMinter();
    error MonadNFT__MaxSupplyReached();
    
    using Strings for uint256;

    uint256 public totalSupply;
    uint256 public constant MAX_SUPPLY = 2000;
    address public batchMinter;

    string[8] private colors = [
        "#836EF9",
        "#200052",
        "#A0FFB5",
        "#FF6B6B",
        "#FFD93D",
        "#4ECDC4",
        "#FF8C00",
        "#00BFFF"
    ];

    constructor() ERC721("MonadBlitz", "MBLITZ") Ownable(msg.sender) {}

    modifier onlyBatchMinter() {
        if (msg.sender != batchMinter) {
            revert MonadNFT__NotBatchMinter();
        }
        _;
    }

    function setBatchMinter(address _batchMinter) external onlyOwner {
        batchMinter = _batchMinter;
    }

    function mint(address to, uint256 tokenId) external onlyBatchMinter {
        if (totalSupply >= MAX_SUPPLY) {
            revert MonadNFT__MaxSupplyReached();
        }
        totalSupply++;
        _safeMint(to, tokenId);
    }

    function generateSVG(uint256 tokenId) internal view returns (string memory) {
        string memory bg = colors[tokenId % 8];
        string memory c1 = colors[(tokenId + 3) % 8];
        string memory c2 = colors[(tokenId + 5) % 8];
        string memory c3 = colors[(tokenId + 7) % 8];

        uint256 r1 = 30 + (tokenId % 50);
        uint256 r2 = 20 + (tokenId % 40);
        uint256 x1 = 80 + (tokenId % 100);
        uint256 y1 = 80 + (tokenId % 80);
        uint256 x2 = 150 + (tokenId % 80);
        uint256 y2 = 150 + (tokenId % 60);
        uint256 rotation = tokenId % 360;

        return string(abi.encodePacked(
            '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 300 300">',
            '<rect width="300" height="300" fill="', bg, '"/>',
            '<circle cx="', x1.toString(), '" cy="', y1.toString(),
            '" r="', r1.toString(), '" fill="', c1, '" opacity="0.85"/>',
            '<rect x="', x2.toString(), '" y="', y2.toString(),
            '" width="', r2.toString(), '" height="', r2.toString(),
            '" fill="', c2, '" opacity="0.75" transform="rotate(',
            rotation.toString(), ' 150 150)"/>',
            '<circle cx="150" cy="150" r="15" fill="', c3, '" opacity="0.9"/>',
            '<text x="150" y="285" text-anchor="middle" fill="white" ',
            'font-size="12" font-family="monospace" opacity="0.9">',
            'MONAD #', tokenId.toString(), '</text>',
            '</svg>'
        ));
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(tokenId <= totalSupply, "Does not exist");

        string memory svg = generateSVG(tokenId);
        string memory json = Base64.encode(bytes(string(abi.encodePacked(
            '{"name": "MonadBlitz #', tokenId.toString(), '",',
            '"description": "1000 unique on-chain NFTs minted in one transaction on Monad.",',
            '"attributes": [{"trait_type": "Token ID", "value": "', tokenId.toString(), '"}],',
            '"image": "data:image/svg+xml;base64,', Base64.encode(bytes(svg)), '"}'
        ))));

        return string(abi.encodePacked("data:application/json;base64,", json));
    }
}
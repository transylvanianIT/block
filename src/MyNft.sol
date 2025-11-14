// SPDX-License-Identifier: MIT

pragma solidity ^0.8.23;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MyNFT is ERC721, Ownable {
    uint256 private _tokenIdCounter = 0;
    mapping(uint256 => string) private _tokenURIs;
    event Minted(address indexed to, uint256 indexed tokenId);

    constructor(address initialOwner) ERC721("My NFT Collection", "MNFT") {
        _transferOwnership(initialOwner);
    }

    function mint(address to) public onlyOwner {
        _tokenIdCounter++;
        _safeMint(to, _tokenIdCounter);
        emit Minted(to, _tokenIdCounter);
    }

    function setTokenURI(uint256 tokenId, string memory uri) public onlyOwner {
        require(_ownerOf(tokenId) != address(0), "Token doesnt exist");
        _tokenURIs[tokenId] = uri;
    }

    function tokenURI(
        uint256 tokenId
    ) public view override returns (string memory) {
        require(_ownerOf(tokenId) != address(0), "token does not exist");
        return _tokenURIs[tokenId];
    }
}

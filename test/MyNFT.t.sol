// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "forge-std/Test.sol";
import "../src/MyNft.sol";

contract MyNFTTest is Test {
    MyNFT public nft;
    address public owner = address(1);
    address public user = address(2);

    function setUp() public {
        nft = new MyNFT(owner);
    }

    function testMint() public {
        vm.prank(owner);
        nft.mint(user);

        assertEq(nft.ownerOf(1), user);
        assertEq(nft.balanceOf(user), 1);
    }

    function testMintFailsForNonOwner() public {
        vm.prank(user);
        vm.expectRevert();
        nft.mint(user);
    }

    function testTokenURI() public {
        vm.prank(owner);
        nft.mint(user);

        vm.prank(owner);
        nft.setTokenURI(1, "https://example.com/1.json");

        assertEq(nft.tokenURI(1), "https://example.com/1.json");
    }

    function testMultipleMints() public {
        vm.prank(owner);
        nft.mint(user);

        vm.prank(owner);
        nft.mint(user);

        vm.prank(owner);
        nft.mint(user);

        assertEq(nft.balanceOf(user), 3);

        assertEq(nft.ownerOf(1), user);

        assertEq(nft.ownerOf(2), user);

        assertEq(nft.ownerOf(3), user);
    }
}

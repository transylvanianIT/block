// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "forge-std/Test.sol";
import "../src/Marketplace.sol";
import "../src/MyToken.sol";

contract MarketplaceTest is Test {
    Marketplace public marketplace;
    MyToken public token;
    address public owner = address(1);
    address public seller = address(2);
    address public buyer = address(3);

    function setUp() public {
        // Deploy token
        token = new MyToken("Test Token", "TEST", owner);

        // Deploy marketplace
        marketplace = new Marketplace(owner);

        // Mint token-uri pentru seller
        vm.prank(owner);
        token.mint(seller, 1000);

        // Seller aprobă marketplace-ul
        vm.prank(seller);
        token.approve(address(marketplace), 1000);
    }

    function testList() public {
        vm.prank(seller);
        marketplace.list(address(token), 100, 1 ether);

        assertEq(marketplace.listingCount(), 1);

        (
            address listingSeller,
            address listingToken,
            uint256 amount,
            uint256 price,
            bool active
        ) = marketplace.listings(1);
        assertEq(listingSeller, seller);
        assertEq(amount, 100);
        assertEq(price, 1 ether);
        assertTrue(active);
    }

    function testBuy() public {
        // Seller listează token-uri
        vm.prank(seller);
        marketplace.list(address(token), 100, 1 ether);

        // Buyer cumpără cu ETH
        vm.deal(buyer, 2 ether);
        vm.prank(buyer);
        marketplace.buy{value: 1 ether}(1);

        // Verifică că buyer-ul are token-urile
        assertEq(token.balanceOf(buyer), 100);

        // Verifică că listing-ul e șters
        (, , , , bool active) = marketplace.listings(1);
        assertFalse(active);
    }

    function testCancel() public {
        // Seller listează token-uri
        vm.prank(seller);
        marketplace.list(address(token), 100, 1 ether);

        // Seller anulează listing-ul
        vm.prank(seller);
        marketplace.cancel(1);

        // Verifică că token-urile sunt returnate
        assertEq(token.balanceOf(seller), 1000);

        // Verifică că listing-ul e șters
        (, , , , bool active) = marketplace.listings(1);
        assertFalse(active);
    }

    function testBuyFailsInsufficientPayment() public {
        vm.prank(seller);
        marketplace.list(address(token), 100, 1 ether);

        vm.deal(buyer, 0.5 ether);
        vm.prank(buyer);
        vm.expectRevert();
        marketplace.buy{value: 0.5 ether}(1);
    }

    function testCancelFailsNotSeller() public {
        vm.prank(seller);
        marketplace.list(address(token), 100, 1 ether);

        vm.prank(buyer);
        vm.expectRevert();
        marketplace.cancel(1);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "forge-std/Test.sol";
import "../src/MyToken.sol";

contract MyTokenTest is Test{
    MyToken public token;
    address public owner = address(1);
    address public user = address(2);

    function setUp() public {
        token = new MyToken("My Token", "MTK", owner);
    }

    function testMint() public{
        vm.prank(owner);
        token.mint(user, 1000);
        assertEq(token.balanceOf(user), 1000);
        assertEq(token.totalSupply(), 1000);
    }

    function testMintFailsForNonOwner() public {
        vm.prank(user);
        vm.expectRevert();
        token.mint(user, 1000);
    }

    function testBurn() public{
        vm.prank(owner);
        token.mint(user, 1000);

        vm.prank(user);
        token.burn(500);
        assertEq(token.balanceOf(user), 500);
        assertEq(token.totalSupply(), 500);
    }

    function testTransfer() public{
        vm.prank(owner);
        token.mint(user, 1000);

        vm.prank(user);
        token.transfer(owner, 300);
        assertEq(token.balanceOf(user), 700);
        assertEq(token.balanceOf(owner), 300);
    }

}
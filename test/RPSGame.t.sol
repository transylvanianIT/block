// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "forge-std/Test.sol";
import "../src/RPSGame.sol";

contract RPSGameTest is Test {
    RPSGame public game;
    address public owner = address(1);
    address public player1 = address(2);
    address public player2 = address(3);
    
    function setUp() public {
        game = new RPSGame(owner);
        vm.deal(player1, 10 ether);
        vm.deal(player2, 10 ether);
    }
    
    function testCreateGame() public {
        vm.prank(player1);
        game.createGame{value: 0.01 ether}();
        
        assertEq(game.gameCounter(), 1);
        (address p1, address p2,,,,,,) = game.getGame(1);
        assertEq(p1, player1);
        assertEq(p2, address(0));
    }
    
    function testJoinGame() public {
        vm.prank(player1);
        game.createGame{value: 0.01 ether}();
        
        vm.prank(player2);
        game.joinGame{value: 0.01 ether}(1);
        
        (address p1, address p2,,,,,,) = game.getGame(1);
        assertEq(p2, player2);
    }
    
    function testPlayGameRockBeatsScissors() public {
        vm.prank(player1);
        game.createGame{value: 0.01 ether}();
        
        vm.prank(player2);
        game.joinGame{value: 0.01 ether}(1);
        
        bytes32 secret1 = keccak256("secret1");
        bytes32 commit1 = keccak256(abi.encodePacked(RPSGame.Move.Rock, secret1, player1));
        
        bytes32 secret2 = keccak256("secret2");
        bytes32 commit2 = keccak256(abi.encodePacked(RPSGame.Move.Scissors, secret2, player2));
        
        vm.prank(player1);
        game.commitMove(1, commit1);
        
        vm.prank(player2);
        game.commitMove(1, commit2);
        
        vm.prank(player1);
        game.revealMove(1, RPSGame.Move.Rock, secret1);
        
        uint256 balanceBefore = player1.balance;
        vm.prank(player2);
        game.revealMove(1, RPSGame.Move.Scissors, secret2);
        
        assertGt(player1.balance, balanceBefore);
    }
    
    function testDraw() public {
        vm.prank(player1);
        game.createGame{value: 0.01 ether}();
        
        vm.prank(player2);
        game.joinGame{value: 0.01 ether}(1);
        
        bytes32 secret1 = keccak256("secret1");
        bytes32 commit1 = keccak256(abi.encodePacked(RPSGame.Move.Rock, secret1, player1));
        
        bytes32 secret2 = keccak256("secret2");
        bytes32 commit2 = keccak256(abi.encodePacked(RPSGame.Move.Rock, secret2, player2));
        
        vm.prank(player1);
        game.commitMove(1, commit1);
        
        vm.prank(player2);
        game.commitMove(1, commit2);
        
        uint256 balance1Before = player1.balance;
        uint256 balance2Before = player2.balance;
        
        vm.prank(player1);
        game.revealMove(1, RPSGame.Move.Rock, secret1);
        
        vm.prank(player2);
        game.revealMove(1, RPSGame.Move.Rock, secret2);
        
        assertEq(player1.balance, balance1Before);
        assertEq(player2.balance, balance2Before);
    }
}


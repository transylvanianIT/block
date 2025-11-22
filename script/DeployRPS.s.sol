// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "forge-std/Script.sol";
import "../src/RPSGame.sol";

contract DeployRPSScript is Script {
    function run() public returns (RPSGame rpsGame) {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address ownerAddress = vm.envAddress("OWNER_ADDRESS");

        vm.startBroadcast(deployerPrivateKey);

        rpsGame = new RPSGame(ownerAddress);

        vm.stopBroadcast();

        console.log("RPSGame deployed at:", address(rpsGame));
    }
}


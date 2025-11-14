// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "forge-std/Script.sol";
import "../src/Marketplace.sol";
import "../src/MyToken.sol";

contract DeployScript is Script {
    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address owner = vm.envAddress("OWNER_ADDRESS");

        vm.startBroadcast(deployerPrivateKey);

        // Deploy MyToken
        MyToken token = new MyToken("My Token", "MTK", owner);
        console.log("MyToken deployed at:", address(token));

        // Deploy Marketplace
        Marketplace marketplace = new Marketplace(owner);
        console.log("Marketplace deployed at:", address(marketplace));

        vm.stopBroadcast();
    }
}

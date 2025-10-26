// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/FriendsMemePoolV2.sol";

contract DeployV2Script is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        FriendsMemePoolV2 pool = new FriendsMemePoolV2();

        console.log("===========================================");
        console.log("FriendsMemePoolV2 deployed to:", address(pool));
        console.log("===========================================");
        console.log("");
        console.log("IMPORTANT: Test on Base Sepolia first!");
        console.log("");
        console.log("Key improvements in V2:");
        console.log("- Fixed WETH wrapping for Uniswap swaps");
        console.log("- All-or-nothing swap execution");
        console.log("- Refund mechanism (24h after deadline)");
        console.log("- Pool cancellation (before deadline)");
        console.log("- Emergency withdrawal (7d after unlock)");
        console.log("- Slippage protection");
        console.log("- Executor rewards (1%)");
        console.log("- Winner bonus (9%)");
        console.log("===========================================");

        vm.stopBroadcast();
    }
}

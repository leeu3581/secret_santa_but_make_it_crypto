// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/FriendsMemePoolV2.sol";

contract FriendsMemePoolV2Test is Test {
    FriendsMemePoolV2 public pool;

    address alice = address(0x1);
    address bob = address(0x2);
    address charlie = address(0x3);

    function setUp() public {
        pool = new FriendsMemePoolV2();

        // Give test accounts ETH
        vm.deal(alice, 10 ether);
        vm.deal(bob, 10 ether);
        vm.deal(charlie, 10 ether);
    }

    function testCreatePool() public {
        address[] memory whitelist = new address[](3);
        whitelist[0] = alice;
        whitelist[1] = bob;
        whitelist[2] = charlie;

        address[] memory memeTokens = new address[](3);
        memeTokens[0] = address(0x100);
        memeTokens[1] = address(0x200);
        memeTokens[2] = address(0x300);

        address[] memory uniswapPools = new address[](3);
        uniswapPools[0] = address(0x1000);
        uniswapPools[1] = address(0x2000);
        uniswapPools[2] = address(0x3000);

        uint256 poolId = pool.createPool(
            "Test Pool",
            whitelist,
            0.01 ether,
            100,  // 1 hour
            200,  // 2 hours
            memeTokens,
            uniswapPools,
            9500  // 5% slippage
        );

        assertEq(poolId, 0);

        (
            string memory name,
            address creator,
            uint256 entryAmount,
            , , , , , , ,
        ) = pool.getPoolInfo(0);

        assertEq(name, "Test Pool");
        assertEq(creator, address(this));
        assertEq(entryAmount, 0.01 ether);
    }

    function testJoinPool() public {
        uint256 poolId = _createTestPool();

        vm.prank(alice);
        pool.joinPool{value: 0.01 ether}(poolId);

        (, , , , , uint256 participantCount, , , , , ) = pool.getPoolInfo(poolId);
        assertEq(participantCount, 1);
    }

    function testCannotJoinTwice() public {
        uint256 poolId = _createTestPool();

        vm.prank(alice);
        pool.joinPool{value: 0.01 ether}(poolId);

        vm.prank(alice);
        vm.expectRevert("Already joined");
        pool.joinPool{value: 0.01 ether}(poolId);
    }

    function testCannotJoinWithWrongAmount() public {
        uint256 poolId = _createTestPool();

        vm.prank(alice);
        vm.expectRevert("Incorrect entry amount");
        pool.joinPool{value: 0.02 ether}(poolId);
    }

    function testCannotJoinIfNotWhitelisted() public {
        uint256 poolId = _createTestPool();

        address dave = address(0x4);
        vm.deal(dave, 1 ether);

        vm.prank(dave);
        vm.expectRevert("Not whitelisted");
        pool.joinPool{value: 0.01 ether}(poolId);
    }

    function testCannotSeeAssignmentsBeforeDeadline() public {
        uint256 poolId = _createTestPool();

        vm.prank(alice);
        pool.joinPool{value: 0.01 ether}(poolId);

        vm.expectRevert("Assignments still hidden");
        pool.getAssignments(poolId);
    }

    function testCanSeeAssignmentsAfterDeadline() public {
        uint256 poolId = _createTestPool();

        vm.prank(alice);
        pool.joinPool{value: 0.01 ether}(poolId);

        // Fast forward past deadline
        vm.warp(block.timestamp + 1 hours + 1);

        (address[] memory participants, ) = pool.getAssignments(poolId);
        assertEq(participants.length, 1);
        assertEq(participants[0], alice);
    }

    function testRefundAfter24Hours() public {
        uint256 poolId = _createTestPool();

        vm.prank(alice);
        pool.joinPool{value: 0.01 ether}(poolId);

        // Fast forward past deadline + 24 hours
        vm.warp(block.timestamp + 1 hours + 24 hours + 1);

        uint256 balanceBefore = alice.balance;

        vm.prank(alice);
        pool.refund(poolId);

        uint256 balanceAfter = alice.balance;
        assertEq(balanceAfter - balanceBefore, 0.01 ether);
    }

    function testCannotRefundBefore24Hours() public {
        uint256 poolId = _createTestPool();

        vm.prank(alice);
        pool.joinPool{value: 0.01 ether}(poolId);

        // Fast forward past deadline but not 24 hours
        vm.warp(block.timestamp + 1 hours + 1);

        vm.prank(alice);
        vm.expectRevert("Wait 24h after deadline");
        pool.refund(poolId);
    }

    function testCancelPool() public {
        uint256 poolId = _createTestPool();

        vm.prank(alice);
        pool.joinPool{value: 0.01 ether}(poolId);

        vm.prank(bob);
        pool.joinPool{value: 0.01 ether}(poolId);

        uint256 aliceBalanceBefore = alice.balance;
        uint256 bobBalanceBefore = bob.balance;

        // Creator cancels
        pool.cancelPool(poolId);

        assertEq(alice.balance - aliceBalanceBefore, 0.01 ether);
        assertEq(bob.balance - bobBalanceBefore, 0.01 ether);

        (, , , , , , , , bool cancelled, , ) = pool.getPoolInfo(poolId);
        assertTrue(cancelled);
    }

    function testCannotCancelAfterDeadline() public {
        uint256 poolId = _createTestPool();

        vm.prank(alice);
        pool.joinPool{value: 0.01 ether}(poolId);

        // Fast forward past deadline
        vm.warp(block.timestamp + 1 hours + 1);

        vm.expectRevert("Too late to cancel");
        pool.cancelPool(poolId);
    }

    function testOnlyCreatorCanCancel() public {
        uint256 poolId = _createTestPool();

        vm.prank(alice);
        pool.joinPool{value: 0.01 ether}(poolId);

        vm.prank(alice);
        vm.expectRevert("Only creator");
        pool.cancelPool(poolId);
    }

    function testEmergencyWithdraw() public {
        uint256 poolId = _createTestPool();

        vm.prank(alice);
        pool.joinPool{value: 0.01 ether}(poolId);

        // Fast forward past unlock + 7 days
        vm.warp(block.timestamp + 2 hours + 7 days + 1);

        uint256 balanceBefore = alice.balance;

        pool.emergencyWithdraw(poolId);

        assertEq(alice.balance - balanceBefore, 0.01 ether);
    }

    function testCannotJoinCancelledPool() public {
        uint256 poolId = _createTestPool();

        pool.cancelPool(poolId);

        vm.prank(alice);
        vm.expectRevert("Pool cancelled");
        pool.joinPool{value: 0.01 ether}(poolId);
    }

    function testSlippageValidation() public {
        address[] memory whitelist = new address[](1);
        whitelist[0] = alice;

        address[] memory memeTokens = new address[](1);
        memeTokens[0] = address(0x100);

        address[] memory uniswapPools = new address[](1);
        uniswapPools[0] = address(0x1000);

        // Too low slippage
        vm.expectRevert("Slippage must be 50-100%");
        pool.createPool(
            "Test",
            whitelist,
            0.01 ether,
            100,
            200,
            memeTokens,
            uniswapPools,
            4999  // 50.01% - too low
        );

        // Too high slippage
        vm.expectRevert("Slippage must be 50-100%");
        pool.createPool(
            "Test",
            whitelist,
            0.01 ether,
            100,
            200,
            memeTokens,
            uniswapPools,
            10001  // Over 100%
        );
    }

    function testUnlockMustBeAfterJoinDeadline() public {
        address[] memory whitelist = new address[](1);
        whitelist[0] = alice;

        address[] memory memeTokens = new address[](1);
        memeTokens[0] = address(0x100);

        address[] memory uniswapPools = new address[](1);
        uniswapPools[0] = address(0x1000);

        vm.expectRevert("Unlock must be after join deadline");
        pool.createPool(
            "Test",
            whitelist,
            0.01 ether,
            200,  // Join deadline
            100,  // Unlock time (before deadline!)
            memeTokens,
            uniswapPools,
            9500
        );
    }

    // Helper function
    function _createTestPool() internal returns (uint256) {
        address[] memory whitelist = new address[](3);
        whitelist[0] = alice;
        whitelist[1] = bob;
        whitelist[2] = charlie;

        address[] memory memeTokens = new address[](3);
        memeTokens[0] = address(0x100);
        memeTokens[1] = address(0x200);
        memeTokens[2] = address(0x300);

        address[] memory uniswapPools = new address[](3);
        uniswapPools[0] = address(0x1000);
        uniswapPools[1] = address(0x2000);
        uniswapPools[2] = address(0x3000);

        return pool.createPool(
            "Test Pool",
            whitelist,
            0.01 ether,
            100,  // 1 hour
            200,  // 2 hours
            memeTokens,
            uniswapPools,
            9500  // 5% slippage
        );
    }
}

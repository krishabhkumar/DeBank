// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

import {Test, console} from "forge-std/Test.sol";
import {DeBank} from "../src/DeBank.sol";

contract TestDeBank is Test {
    DeBank public deBank;
    string name1 = "Rishabh";
    string name2 = "Gurkirat";
    string pan1 = "xyz";
    string pan2 = "abc";
    uint value1 = 0.001 ether;
    uint value2 = 1 ether;
    address user1;
    address user2;
    uint minimumDeposit;

    function setUp() public {
        user1 = address(0x1);
        user2 = address(0x2);
        deBank = new DeBank();
        minimumDeposit = deBank.MINIMUM_DEPOSIT();
        vm.deal(user1, 20 ether);
        vm.deal(user2, 20 ether);
    }

    function testMinimumDeposite() public view {
        assertEq(minimumDeposit, 0.01 ether);
    }

    function testAccountCreationFailsWithInsufficientAmount() public {
        vm.startPrank(user1);
        uint insufficientAmount = minimumDeposit - 1;
        //vm.expectRevert(MinimumDepositNotMet(insufficientAmount, minimumDeposit));
        vm.expectRevert("Minimum deposite not met.");
        deBank.createAccount{value: insufficientAmount}(name1, pan1);
        vm.stopPrank();
    }

    function testDuplicateAccountCreationFails() public {
        vm.startPrank(user1);
        // vm.expectRevert(bytes(""));
        deBank.createAccount{value: minimumDeposit}(name1, pan1);
        vm.stopPrank();

        vm.assertEq(deBank.getTotalBankBalance(), minimumDeposit);
        vm.startPrank(user1);
        vm.expectRevert("Account already exists.");
        deBank.createAccount{value: minimumDeposit}(name1, pan1);
        vm.stopPrank();
        vm.assertEq(deBank.getTotalBankBalance(), minimumDeposit);

    }

    
}

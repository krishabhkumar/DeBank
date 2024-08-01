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
        assertEq(minimumDeposit, 2 ether);
    }

    function testAccountCreationFailsWithInsufficientAmount() public {
        vm.startPrank(user1);
        uint insufficientAmount = minimumDeposit - 1 ether;

        vm.expectRevert(
            abi.encodeWithSelector(
                bytes4(keccak256("MinimumDepositNotMet(uint256,uint256)")),
                insufficientAmount,
                minimumDeposit
            )
        );
        // vm.expectRevert("Minimum deposite not met.");
        deBank.createAccount{value: insufficientAmount}(name1, pan1);
        console.log("insufficient amount:", insufficientAmount);
        console.log("minimum deposit", minimumDeposit);
        vm.stopPrank();
    }

    function testDuplicateAccountCreationFails() public {
        vm.startPrank(user1);
        deBank.createAccount{value: minimumDeposit}(name1, pan1);
        vm.stopPrank();

        vm.assertEq(deBank.getTotalBankBalance(), minimumDeposit);
        vm.startPrank(user1);
        vm.expectRevert(
            abi.encodeWithSelector(
                bytes4(keccak256("AccountAlreadyExists(address)")),
                user1
            )
        );
        deBank.createAccount{value: minimumDeposit}(name1, pan1);
        vm.stopPrank();
        vm.assertEq(deBank.getTotalBankBalance(), minimumDeposit);
    }

    function testDepositToAnotherContract() public {
        vm.startPrank(user1);
        //vm.expectEmit(true, true, abi.encodeWithSignature("AccountCreated(Account)", deBank.accounts[user1]));

        deBank.createAccount{value: minimumDeposit}(name1, pan1);
        vm.stopPrank();
        
        vm.startPrank(user2);
        vm.expectEmit(true, true, abi.encodeWithSignature("Deposited(address, address, uint)", user2, user1, 1 ether));

        deBank.depositToAnotherAccount{value: 1 ether}(user1);
        vm.stopPrank();
    }
}

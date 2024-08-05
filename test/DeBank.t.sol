// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

//import {Test, console} from "forge-std/Test.sol";
import "forge-std/Test.sol";
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

    function testGetTotalBankBalance() public {
        vm.startPrank(user1);
        deBank.createAccount{value: minimumDeposit}(name1, pan1);
        vm.stopPrank();
        assertEq(deBank.getTotalBankBalance(), minimumDeposit);
    }

    function testGetTotalBankBalanceFailIFOwnerIsNotCalling() public {
        vm.startPrank(user1);
        deBank.createAccount{value: minimumDeposit}(name1, pan1);
        //OwnableUnauthorizedAccount(_msgSender())
        vm.expectRevert(
            abi.encodeWithSelector(
                bytes4(keccak256("OwnableUnauthorizedAccount(address)")),
                user1
            )
        );
        deBank.getTotalBankBalance();
        //assertEq(contractBalance, minimumDeposit);
        vm.stopPrank();
    }

    function testGetAccountBalance() public {
        vm.startPrank(user1);
        deBank.createAccount{value: 5 ether}(name1, pan1);
        assertEq(deBank.getAccountBalance(), 5 ether);
        vm.stopPrank();
        //AccountDoesNotExist()
        vm.startPrank(user2);
        vm.expectRevert(
            abi.encodeWithSelector(bytes4(keccak256("AccountDoesNotExist()")))
        );
        deBank.getAccountBalance();
        vm.stopPrank();
    }

    function testDepositToAnotherAccount() public {
        vm.startPrank(user1);
        vm.expectRevert(
            abi.encodeWithSelector(bytes4(keccak256("AccountDoesNotExist()")))
        );
        deBank.depositToAnotherAccount{value: 1 ether}(user2);
        vm.stopPrank();

        vm.prank(user2);
        deBank.createAccount{value: minimumDeposit}(name1, pan1);

        vm.startPrank(user1);
        //vm.recordLogs();
        vm.expectEmit(true, true, false, true);
        //emit Deposited(user1, user2, 1 ether); // this line give us undeclared identifier
        deBank.depositToAnotherAccount{value: 1 ether}(user2);

        // Vm.Log[] memory entries = vm.getRecordedLogs();
        vm.stopPrank();

        // Find the Deposited event and assert its parameters
        //bool depositedEventFound = false;
        // for (uint256 i = 0; i < entries.length; i++) {
        //     if (
        //         entries[i].topics[0] ==
        //         keccak256("Deposited(address,address,uint256)")
        //     ) {
        //         // Decode the event arguments
        //         (address from, address to, uint256 amount) = abi.decode(
        //             entries[i].data,
        //             (address, address, uint256)
        //         );

        //         // Assert the event parameters match expectations
        //         require(
        //             from == user1 && to == user2 && amount == 1 ether,
        //             "Incorrect Deposited event emitted"
        //         );

        //         depositedEventFound = true;
        //         break;
        //     }
        // }
        // require(
        //     depositedEventFound,
        //     "Deposited event not found in transaction logs"
        // );
    }

    function testWithdrawalWithZeroAmount() external {
        vm.startPrank(user1);
        deBank.createAccount{value: 10 ether}(name1, pan1);
        assertEq(deBank.getAccountBalance(), 10 ether);

        vm.expectRevert("This operation cannot be performed.");
        deBank.withdraw(0);
    }

    function testWithdrawalWithNonAccountHolder() external {
        vm.startPrank(user1);
        deBank.createAccount{value: 10 ether}(name1, pan1);
        assertEq(deBank.getAccountBalance(), 10 ether);
        vm.stopPrank();

        vm.startPrank(user2);
        vm.expectRevert(
            abi.encodeWithSelector(bytes4(keccak256("AccountDoesNotExist()")))
        );
        deBank.withdraw(1 ether);
        vm.stopPrank();
    }

    function testWithdrawalWhereMinDepositIsNotMaintained() external {
        vm.startPrank(user1);
        deBank.createAccount{value: 10 ether}(name1, pan1);
        assertEq(deBank.getAccountBalance(), 10 ether);

        // Try to withdraw an amout which will leave less than the minimum deposit or the amount is greater then the account balance
        vm.expectRevert(
            abi.encodeWithSelector(bytes4(keccak256("InsufficientFunds()")))
        );
        deBank.withdraw(15 ether);
        vm.expectRevert(
            abi.encodeWithSelector(bytes4(keccak256("InsufficientFunds()")))
        );
        deBank.withdraw(9 ether);
        vm.stopPrank();
    }

    function testSuccessfulWithdrawal() external {
        vm.startPrank(user1);
        deBank.createAccount{value: 10 ether}(name1, pan1);
        assertEq(deBank.getAccountBalance(), 10 ether);

        vm.expectRevert(
            abi.encodeWithSelector(bytes4(keccak256("InsufficientFunds()")))
        );
        deBank.withdraw(9 ether);
        assertEq(deBank.getAccountBalance(), 10 ether);

        deBank.withdraw(6 ether);
        assertEq(deBank.getAccountBalance(), 4 ether);
        vm.stopPrank();
    }

    function testTransferOwnership() external {
        vm.startPrank(user1);
        vm.expectRevert(abi.encodeWithSelector(bytes4(keccak256("OwnableUnauthorizedAccount(address)")),user1));
        //vm.expectRevert("Ownable: caller is not the owner");
        deBank.transferOwnership(user2);
        vm.stopPrank();

        vm.startPrank(deBank.owner());
        deBank.transferOwnership(user1);
        assertEq(deBank.owner(), user1);
        vm.stopPrank();

        vm.startPrank(user1);
        vm.expectRevert("Invalid address");
        deBank.transferOwnership(address(0));
        vm.stopPrank();
    }

    function testRenounceOwnership() external {
        vm.startPrank(user1);
        vm.expectRevert(abi.encodeWithSelector(bytes4(keccak256("OwnableUnauthorizedAccount(address)")),user1));
        deBank.renounceOwnership();
        vm.stopPrank();
        
        vm.startPrank(deBank.owner());
        deBank.renounceOwnership();
        assertEq(deBank.owner(), address(0));
        vm.stopPrank();

    }
}

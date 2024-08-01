// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

import {Script, console} from "forge-std/Script.sol";
import {DeBank} from "../src/DeBank.sol";
import {Test, console} from "forge-std/Test.sol";

contract DeBankScript is Script {
    DeBank public deBank;

    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        deBank = new DeBank();

        vm.stopBroadcast();
    }
}
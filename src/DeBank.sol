// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract DeBank is Ownable, ReentrancyGuard {
    
    struct Account {
        string name;
        string pan;
        uint256 balance;
        bool exists;
    }

    mapping(address acountNumber => Account) public accounts;
    uint256 private totalContractBalance;

    uint256 public constant MINIMUM_DEPOSIT = 0.01 ether;

    // Events
    event Deposited(address indexed from, address indexed to, uint256 amount);
    event SelfDeposited(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event AccountCreated(Account);

    // Errors
    error MinimumDepositNotMet(uint256 depositAmount, uint256 requiredAmount);
    error AccountDoesNotExist();
    error AccountAlreadyExists(address addr);
    error NotPermittedToCallThisFunction();
    error InsufficientFunds();

    // Modifier
    modifier onlyAccountOwners() {
        if (!accounts[msg.sender].exists) {
            revert AccountDoesNotExist();
        }

        _;
    }

    constructor() Ownable(msg.sender) {}

    function createAccount(
        string memory _name,
        string memory _pan
    ) public payable {
        require(msg.value >= MINIMUM_DEPOSIT, "Minimum deposite not met.");
        // if (msg.value < MINIMUM_DEPOSIT) {
        //     revert MinimumDepositNotMet(msg.value, MINIMUM_DEPOSIT);
        // }
        require(!accounts[msg.sender].exists, "Account already exists.");
        // if (accounts[msg.sender].exists) {
        //     revert AccountAlreadyExists(msg.sender);
        // }
        Account memory newAccount = Account({
            name: _name,
            pan: _pan,
            balance: msg.value,
            exists: true
        });
        accounts[msg.sender] = newAccount;

        emit AccountCreated(newAccount);
    }

    function getTotalBankBalance() public view onlyOwner returns (uint256) {
        return address(this).balance;
    }

    function getAccountBalance() public view returns (uint256) {
        if (!accounts[msg.sender].exists) {
            revert AccountDoesNotExist();
        }

        return accounts[msg.sender].balance;
    }

    function deposit(address _to, uint _amount) internal {
        if (!accounts[_to].exists) {
            revert AccountDoesNotExist();
        }
        require(_amount > 0, "Amount must be greater than zero");

        accounts[_to].balance += _amount;
    }

    function depositToAnotherAccount(address _to) public payable {
        deposit(_to, msg.value);

        emit Deposited(msg.sender, _to, msg.value);
    }

    function selfDeposit() public payable onlyAccountOwners {
        deposit(msg.sender, msg.value);

        emit SelfDeposited(msg.sender, msg.value);
    }

    function withdraw(uint _amount) public onlyAccountOwners {
        if (!accounts[msg.sender].exists) {
            revert AccountDoesNotExist();
        }
        uint amountLeftPostWithdrawl = accounts[msg.sender].balance - _amount;
        if (amountLeftPostWithdrawl < MINIMUM_DEPOSIT) {
            revert InsufficientFunds();
        }
        // require(
        //     amountLeftPostWithdrawl >= MINIMUM_DEPOSIT,
        //     "Minimum balance should be maintained in account."
        // );

        accounts[msg.sender].balance -= _amount;

        (bool sent, ) = payable(msg.sender).call{value: _amount}("");
        require(sent, "Failed to Withdraw");

        emit Withdrawn(msg.sender, _amount);
    }

    function transferOwnership(address _newOwner) public override onlyOwner {
        require(_newOwner != address(0), "Non-zero address");
        _transferOwnership(_newOwner);
    }

    function renounceOwnership() public override onlyOwner {
        _transferOwnership(address(0));
    }

    function closeAccount() public onlyAccountOwners {
        (bool sent, ) = payable(msg.sender).call{
            value: accounts[msg.sender].balance
        }("");
        require(sent, "Failed to Withdraw");

        Account memory account = Account({
            name: "",
            pan: "",
            balance: 0,
            exists: false
        });
        accounts[msg.sender] = account;
    }

    receive() external payable {}

    fallback() external payable {}
}

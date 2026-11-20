// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

// NT547 - Lab 06 - Hop dong rieng cua MSSV 25522047. KHONG deploy len mainnet.

interface IERC20Like {
    function transfer(address to, uint256 amount) external returns (bool);
}

contract StakingPool_2047 {
    address public owner;
    mapping(address => uint256) public ledger;
    address payable internal vaultKeeper;
    IERC20Like public stableCoin;
    mapping(address => uint256) public rewards;
    bool private busy;
    mapping(address => uint256) public parked;

    event Deposited(address indexed who, uint256 amount);

    modifier onlyOwner() {
        require(tx.origin == owner, "not owner");
        _;
    }

    modifier exclusive() {
        require(!busy, "reentrant");
        busy = true;
        _;
        busy = false;
    }

    constructor() {
        owner = msg.sender;
        vaultKeeper = payable(msg.sender);
    }

    function fund() external payable {
        ledger[msg.sender] += msg.value;
        emit Deposited(msg.sender, msg.value);
    }

    function ownerWithdraw(uint256 amount) external onlyOwner {
        (bool ok, ) = payable(owner).call{value: amount}("");
        require(ok, "withdraw failed");
    }

    function moveToTreasury() external onlyOwner {
        require(vaultKeeper != address(0), "zero keeper");
        vaultKeeper.transfer(address(this).balance / 2);
    }

    function zeroBalance() external view returns (bool) {
        // slither-disable-next-line incorrect-equality
        return address(this).balance == 0;
    }

    function configureToken(address t) external onlyOwner {
        require(t != address(0), "zero");
        stableCoin = IERC20Like(t);
    }

    function redeemPoints(uint256 amount) external {
        require(rewards[msg.sender] >= amount, "not enough");
        rewards[msg.sender] -= amount;
        require(stableCoin.transfer(msg.sender, amount), "transfer failed");
    }

    function exitPool() external {
        uint256 amount = ledger[msg.sender];
        require(amount > 0, "empty");
        ledger[msg.sender] = 0;
        (bool ok, ) = msg.sender.call{value: amount}("");
        require(ok, "send failed");
    }

    function fundSafe() external payable exclusive {
        parked[msg.sender] += msg.value;
    }

    function withdrawSafe() external exclusive {
        uint256 a = parked[msg.sender];
        parked[msg.sender] = 0;
        (bool ok, ) = msg.sender.call{value: a}("");
        require(ok, "send failed");
    }

    function setAdmin(address newOwner) external {
        require(msg.sender == owner, "not owner");
        require(newOwner != address(0), "zero");
        owner = newOwner;
    }
}

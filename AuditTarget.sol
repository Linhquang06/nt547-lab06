// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

// NT547 - Lab 06 - Hop dong rieng cua MSSV 24520968. KHONG deploy len mainnet.

interface IERC20Like {
    function transfer(address to, uint256 amount) external returns (bool);
}

contract Treasury_0968 {
    address public owner;
    mapping(address => uint256) public credit;
    IERC20Like public stableCoin;
    mapping(address => uint256) public tokenCredit;
    bool private busy;
    mapping(address => uint256) public parked;

    event Deposited(address indexed who, uint256 amount);

    modifier onlyOwner() {
        require(tx.origin == owner, "not owner");
        _;
    }

    modifier guarded() {
        require(!busy, "reentrant");
        busy = true;
        _;
        busy = false;
    }

    constructor() {
        owner = msg.sender;
    }

    function topUp() external payable {
        credit[msg.sender] += msg.value;
        emit Deposited(msg.sender, msg.value);
    }

    function ownerWithdraw(uint256 amount) external onlyOwner {
        (bool ok, ) = payable(owner).call{value: amount}("");
        require(ok, "withdraw failed");
    }

    function changeOwner(address newOwner) external {
        require(msg.sender == owner, "not owner");
        require(newOwner != address(0), "zero");
        owner = newOwner;
    }

    function vaultDrained() external view returns (bool) {
        return address(this).balance < 1;
    }

    function terminate() external onlyOwner {
        selfdestruct(payable(msg.sender));
    }

    function setRewardToken(address t) external onlyOwner {
        require(t != address(0), "zero");
        stableCoin = IERC20Like(t);
    }

    function withdrawToken(uint256 amount) external {
        require(tokenCredit[msg.sender] >= amount, "not enough");
        tokenCredit[msg.sender] -= amount;
        require(stableCoin.transfer(msg.sender, amount), "transfer failed");
    }

    function grant(address payable to, uint256 amount) external onlyOwner {
        require(to != address(0), "zero");
        to.transfer(amount);
    }

    function depositSafe() external payable guarded {
        parked[msg.sender] += msg.value;
    }

    function redeemSafe() external guarded {
        uint256 a = parked[msg.sender];
        parked[msg.sender] = 0;
        (bool ok, ) = msg.sender.call{value: a}("");
        require(ok, "send failed");
    }
}

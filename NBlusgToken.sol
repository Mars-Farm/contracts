// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./owner/AdminRole.sol";

contract NBlusgToken is ERC20Burnable, AdminRole {
    using SafeMath for uint256;

    mapping(address => uint8) public lockList;
    mapping(address => uint256) public lockAmount;

    constructor(string memory name_, string memory symbol_)
        ERC20(name_, symbol_)
    {
        _mint(0x08de9aFaAF44b453d5Ac7Ce39a9b4CE289121A0b, 996337297995 * 10**13);  

    }

    function transfer(address to, uint256 amount)
        public
        override
        returns (bool)
    {
        if (lockList[msg.sender] == 1) {
            require(
                balanceOf(msg.sender).sub(amount) >= lockAmount[msg.sender],
                "amount locked"
            );
        }
        return super.transfer(to, amount);
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public override returns (bool) {
        if (lockList[from] == 1) {
            require(
                balanceOf(from).sub(amount) >= lockAmount[from],
                "amount locked"
            );
        }
        return super.transferFrom(from, to, amount);
    }

    function setlockList(address _addr, uint8 _lock) public onlyAdmin {
         
        lockList[_addr] = _lock;
    }

    function checkList(address _addr) public view onlyAdmin returns (uint8) {
        return lockList[_addr];
    }

    function setlockAmount(address _addr, uint256 _amount) public onlyAdmin {
        lockAmount[_addr] = _amount;
    }

    function checkAmount(address _addr)
        public
        view
        onlyAdmin
        returns (uint256)
    {
        return lockAmount[_addr];
    }
}

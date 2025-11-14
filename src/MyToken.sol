// SPDX-Identifier: MIT
pragma solidity ^0.8.23;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MyToken is ERC20, Ownable {

    event Mint(address indexed to, uint256 amount);
    event Burn(address indexed from, uint256 amount);

    constructor(
        string memory name,
        string memory symbol,
        address initialOwner
    ) ERC20(name, symbol) Ownable(initialOwner){

    }

    function mint( address to, uint256 amount) public onlyOwner{
        _mint(to, amount);
        emit Mint(to, amount);
    }

    function burn(uint256 amount) public {
        address from = msg.sender;
        _burn(from, amount);
        emit Burn(from, amount);
    }
}
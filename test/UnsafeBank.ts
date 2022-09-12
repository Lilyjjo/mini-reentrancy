import { expect } from "chai";
import { ethers, waffle } from "hardhat";

let victim: any;
let hacker: any;

describe("Attacking Reentrance", function () {
  beforeEach(async () => {
    const Victim = await ethers.getContractFactory("UnsafeBank");

    // deploy the bank with 5 ETH
    victim = await Victim.deploy({ value: 5 });
    const Hacker = await ethers.getContractFactory("Hacker");

    // deploy the attacker with 1 ETH
    hacker = await Hacker.deploy(victim.address, { value: 1 });
  });

  // Hacked!
  it("Succesfully take all the ETH out of the contract", async () => {

    // This line does the whole attack
    await hacker.hackContract();

    const provider = ethers.provider;
    let balance = await provider.getBalance(victim.address);
    expect(balance).to.equal(0);
    balance = await provider.getBalance(hacker.address);
    expect(balance).to.equal(6);
  });
});
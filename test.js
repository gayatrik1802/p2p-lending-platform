const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("P2P Loan flow", function () {
  let factory, owner, borrower, lender1, lender2;

  beforeEach(async () => {
    [owner, borrower, lender1, lender2] = await ethers.getSigners();
    const Factory = await ethers.getContractFactory("LoanFactory");
    factory = await Factory.deploy();
    await factory.deployed();
  });

  it("create, fund, withdraw, repay, claim", async () => {
    const amount = ethers.utils.parseEther("1.0"); // 1 ETH requested
    const interestBPS = 500; // 5%
    const duration = 60 * 60 * 24 * 30; // 30 days

    // borrower creates loan
    await factory.connect(borrower).createLoan(amount, interestBPS, duration);
    const loans = await factory.allLoans();
    const loanAddress = loans[0];
    const Loan = await ethers.getContractAt("Loan", loanAddress);

    // lender1 funds 0.6 ETH
    await lender1.sendTransaction({ to: loanAddress, value: ethers.utils.parseEther("0.6") });
    // lender2 funds 0.4 ETH
    await lender2.sendTransaction({ to: loanAddress, value: ethers.utils.parseEther("0.4") });

    // factory triggers borrower withdraw
    await factory.connect(borrower).borrowerWithdraw(loanAddress);

    // borrower repays principal + interest (1.05 ETH)
    const repayAmount = ethers.utils.parseEther("1.05");
    await borrower.sendTransaction({ to: loanAddress, value: repayAmount });

    // lenders claim
    const beforeBal1 = await ethers.provider.getBalance(lender1.address);
    await Loan.connect(lender1).claim();
    const afterBal1 = await ethers.provider.getBalance(lender1.address);
    expect(afterBal1).to.be.gt(beforeBal1);
  });
});

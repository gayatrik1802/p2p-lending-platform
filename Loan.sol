// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./Loan.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract LoanFactory is Ownable {
    address[] public loans;
    mapping(address => bool) public isLoan;

    event LoanCreated(address indexed loanAddress, address indexed borrower, uint256 amount, uint256 interestBPS, uint256 duration);

    function createLoan(uint256 amountRequested, uint256 interestBPS, uint256 durationSeconds) external returns (address) {
        require(amountRequested > 0, "amount>0");
        require(durationSeconds > 0, "duration>0");

        Loan loan = new Loan(msg.sender, amountRequested, interestBPS, durationSeconds, address(this));
        loans.push(address(loan));
        isLoan[address(loan)] = true;

        emit LoanCreated(address(loan), msg.sender, amountRequested, interestBPS, durationSeconds);
        return address(loan);
    }

    // Called by UI/admin to let borrower withdraw - factory ensures only valid loan triggers
    function borrowerWithdraw(address loanAddress) external {
        require(isLoan[loanAddress], "invalid loan");
        Loan loan = Loan(loanAddress);
        // pull state, then call withdrawToBorrower
        loan.withdrawToBorrower();
    }

    function allLoans() external view returns (address[] memory) {
        return loans;
    }
}

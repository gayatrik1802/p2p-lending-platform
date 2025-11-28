// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract P2PLending {

    struct Loan {
        uint id;
        address payable borrower;
        address payable lender;
        uint amount;
        uint interest; 
        uint totalRepay;
        bool funded;
        bool repaid;
    }

    mapping(uint => Loan) public loans;
    uint public loanCount;

    event LoanCreated(uint loanId, address borrower, uint amount, uint interest);
    event LoanFunded(uint loanId, address lender);
    event LoanRepaid(uint loanId, address borrower);
    event Withdrawal(address lender, uint amount);

    // Create loan request
    function createLoan(uint _interest) external payable {
        require(msg.value > 0, "Loan amount required");

        loanCount++;
        loans[loanCount] = Loan({
            id: loanCount,
            borrower: payable(msg.sender),
            lender: payable(address(0)),
            amount: msg.value,
            interest: _interest,
            totalRepay: msg.value + _interest,
            funded: false,
            repaid: false
        });

        emit LoanCreated(loanCount, msg.sender, msg.value, _interest);
    }

    // Lender funds the loan
    function fundLoan(uint _loanId) external payable {
        Loan storage loan = loans[_loanId];

        require(!loan.funded, "Already funded");
        require(msg.value == loan.amount, "Incorrect amount");

        loan.lender = payable(msg.sender);
        loan.funded = true;

        // Transfer borrower's requested loan amount
        loan.borrower.transfer(loan.amount);

        emit LoanFunded(_loanId, msg.sender);
    }

    // Borrower repays the loan
    function repayLoan(uint _loanId) external payable {
        Loan storage loan = loans[_loanId];

        require(msg.sender == loan.borrower, "Only borrower");
        require(loan.funded, "Loan not funded");
        require(!loan.repaid, "Already repaid");
        require(msg.value == loan.totalRepay, "Repay exact amount");

        loan.repaid = true;

        emit LoanRepaid(_loanId, msg.sender);
    }

    // Lender withdraws repaid funds
    function withdraw(uint _loanId) external {
        Loan storage loan = loans[_loanId];
        require(msg.sender == loan.lender, "Only lender");
        require(loan.repaid, "Loan not repaid");

        uint amount = loan.totalRepay;
        loan.totalRepay = 0;

        loan.lender.transfer(amount);

        emit Withdrawal(msg.sender, amount);
    }
}

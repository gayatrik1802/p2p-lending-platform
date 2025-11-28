// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/// @notice Simple Loan contract used by LoanFactory
contract Loan is ReentrancyGuard {
    enum State { Created, Funded, Active, Repaid, Defaulted }

    address public factory;
    address public borrower;
    uint256 public amountRequested;
    uint256 public amountFunded;
    uint256 public interestBPS; // basis points (100 bps = 1%)
    uint256 public durationSeconds;
    uint256 public fundedAt;
    State public state;
    uint256 public totalRepaid;

    // lenders contributions
    mapping(address => uint256) public contributions;
    address[] public lenders;

    event Funded(address indexed lender, uint256 amount);
    event WithdrawBorrower(address indexed borrower, uint256 amount);
    event Repayment(address indexed payer, uint256 amount);
    event LenderClaim(address indexed lender, uint256 amount);
    event Defaulted();

    modifier onlyFactory() {
        require(msg.sender == factory, "only factory");
        _;
    }

    constructor(
        address _borrower,
        uint256 _amountRequested,
        uint256 _interestBPS,
        uint256 _durationSeconds,
        address _factory
    ) {
        borrower = _borrower;
        amountRequested = _amountRequested;
        interestBPS = _interestBPS;
        durationSeconds = _durationSeconds;
        factory = _factory;
        state = State.Created;
    }

    // lenders send ETH to fund
    receive() external payable {
        fund();
    }

    function fund() public payable nonReentrant {
        require(state == State.Created, "not open for funding");
        require(msg.value > 0, "zero");
        uint256 remaining = amountRequested - amountFunded;
        require(remaining > 0, "already funded");
        uint256 toAdd = msg.value;
        // if overfunding, refund excess to sender
        if (toAdd > remaining) {
            uint256 excess = toAdd - remaining;
            toAdd = remaining;
            // refund excess
            (bool rs, ) = msg.sender.call{value: excess}("");
            require(rs, "refund failed");
        }

        if (contributions[msg.sender] == 0) {
            lenders.push(msg.sender);
        }
        contributions[msg.sender] += toAdd;
        amountFunded += toAdd;
        emit Funded(msg.sender, toAdd);

        if (amountFunded == amountRequested) {
            state = State.Funded;
        }
    }

    // Called by factory to let borrower withdraw when fully funded
    function withdrawToBorrower() external onlyFactory nonReentrant {
        require(state == State.Funded, "not funded");
        state = State.Active;
        fundedAt = block.timestamp;
        (bool sent, ) = borrower.call{value: amountFunded}("");
        require(sent, "transfer failed");
        emit WithdrawBorrower(borrower, amountFunded);
    }

    // Borrower or anyone can repay (send ETH)
    function repay() external payable nonReentrant {
        require(state == State.Active, "not active");
        require(msg.value > 0, "zero");
        totalRepaid += msg.value;
        emit Repayment(msg.sender, msg.value);

        uint256 amountDue = amountRequested + (amountRequested * interestBPS) / 10000;
        if (totalRepaid >= amountDue) {
            state = State.Repaid;
        }
    }

    // Lender claims their pro-rata share after repayment or default resolution
    // For simplicity: after Repaid lenders can claim their principal + interest proportionally.
    function claim() external nonReentrant {
        require(state == State.Repaid, "not repaid");
        uint256 contributed = contributions[msg.sender];
        require(contributed > 0, "no contribution");
        // compute lender share: (contributed / amountRequested) * (amountRequested + interest)
        uint256 amountDue = amountRequested + (amountRequested * interestBPS) / 10000;
        uint256 payout = (amountDue * contributed) / amountRequested;

        // zero out contribution to prevent double-claim
        contributions[msg.sender] = 0;
        // send payout
        (bool sent, ) = msg.sender.call{value: payout}("");
        require(sent, "payout failed");
        emit LenderClaim(msg.sender, payout);
    }

    // Expose lenders count for UI
    function lendersCount() external view returns (uint256) {
        return lenders.length;
    }

    // Anyone can call to mark default if past duration and not repaid
    function checkDefault() external {
        require(state == State.Active, "not active");
        if (block.timestamp > fundedAt + durationSeconds) {
            state = State.Defaulted;
            emit Defaulted();
        }
    }

    // Getter for amount due
    function amountDue() public view returns (uint256) {
        return amountRequested + (amountRequested * interestBPS) / 10000;
    }
}

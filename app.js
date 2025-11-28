let contract;
let accounts;
const contractAddress = "PASTE_DEPLOYED_CONTRACT_ADDRESS";

async function connectWallet() {
    if (window.ethereum) {
        await ethereum.request({ method: "eth_requestAccounts" });
        web3 = new Web3(window.ethereum);

        const abi = await fetch("abi.json").then(res => res.json());

        contract = new web3.eth.Contract(abi, contractAddress);

        accounts = await web3.eth.getAccounts();
        alert("Connected: " + accounts[0]);
    } else {
        alert("Install MetaMask!");
    }
}

async function createLoan() {
    let amount = document.getElementById("loanAmount").value;
    let interest = document.getElementById("loanInterest").value;

    await contract.methods.createLoan(web3.utils.toWei(interest, "ether"))
    .send({ from: accounts[0], value: web3.utils.toWei(amount, "ether") });
}

async function fundLoan() {
    let id = document.getElementById("fundLoanId").value;

    let loan = await contract.methods.loans(id).call();

    await contract.methods.fundLoan(id).send({
        from: accounts[0],
        value: loan.amount
    });
}

async function repayLoan() {
    let id = document.getElementById("repayLoanId").value;

    let loan = await contract.methods.loans(id).call();

    await contract.methods.repayLoan(id).send({
        from: accounts[0],
        value: loan.totalRepay
    });
}

async function withdrawLoan() {
    let id = document.getElementById("withdrawLoanId").value;

    await contract.methods.withdraw(id).send({
        from: accounts[0]
    });
}

// assume React + ethers loaded
import { useState } from "react";
import { ethers } from "ethers";
import LoanFactoryABI from "./abis/LoanFactory.json";
import LoanABI from "./abis/Loan.json";

const FACTORY_ADDRESS = "0x..."; // deployed factory

export default function App() {
  const [provider, setProvider] = useState(null);
  const [signer, setSigner] = useState(null);
  const [factory, setFactory] = useState(null);

  async function connect() {
    const p = new ethers.providers.Web3Provider(window.ethereum);
    await p.send("eth_requestAccounts", []);
    const s = p.getSigner();
    setProvider(p);
    setSigner(s);
    setFactory(new ethers.Contract(FACTORY_ADDRESS, LoanFactoryABI, s));
  }

  async function createLoan(amountEth, interestBPS, durationSec) {
    const amountWei = ethers.utils.parseEther(amountEth.toString());
    const tx = await factory.createLoan(amountWei, interestBPS, durationSec);
    await tx.wait();
    // fetch loan list or listen to event
  }

  async function fundLoan(loanAddress, amountEth) {
    const loanContract = new ethers.Contract(loanAddress, LoanABI, signer);
    const tx = await signer.sendTransaction({ to: loanAddress, value: ethers.utils.parseEther(amountEth.toString()) });
    await tx.wait();
  }

  async function repayLoan(loanAddress, amountEth) {
    const tx = await signer.sendTransaction({ to: loanAddress, value: ethers.utils.parseEther(amountEth.toString()) });
    await tx.wait();
  }

  return (
    <div>
      <button onClick={connect}>Connect Wallet</button>
      {/* UI inputs to create/fund/repay — omitted for brevity */}
    </div>
  );
}

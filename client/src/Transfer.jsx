import { useState } from "react";
import server from "./server";

function Transfer({ address, setBalance }) {
  const [sendAmount, setSendAmount] = useState("");
  const [recipient, setRecipient] = useState("");

  const setValue = (setter) => (evt) => setter(evt.target.value);

  async function transfer(evt) {
    evt.preventDefault();

    try {
      // Validate inputs
      if (!address) {
        alert("Address not loaded yet");
        return;
      }
      
      if (!recipient) {
        alert("Please enter recipient address");
        return;
      }
      if(recipient.length !== 42 || !recipient.startsWith("0x")) {
        alert("Please enter a valid recipient address");
        return;
      }
      
      const amount = parseInt(sendAmount);
      if (!sendAmount || amount <= 0) {
        alert("Please enter valid amount");
        return;
      }
      
      console.log("Starting transfer:", { address, recipient, amount });
      
      // Create structured message to sign: address|recipient|amount
      const msg = `${address}|${recipient}|${amount}`;
      console.log("Message to sign:", msg);
      
      // Call sign function and wait for signature
      console.log("Calling /signMessage...");
      const signResponse = await server.post(`/signMessage`, { msg });
      console.log("Sign response:", signResponse.data);
      
      const { signature } = signResponse.data;
      
      if (!signature) {
        throw new Error("No signature returned from server");
      }
      
      
      // Send transaction with the signature
      console.log("Calling /send...");
      const sendResponse = await server.post(`/send`, {
        signature,
        msg,
        recipient,
        amount
      });
      console.log("Send response:", sendResponse.data);
      
      const { balance } = sendResponse.data;
      setBalance(balance);
      setSendAmount("");
      setRecipient("");
    } catch (ex) {
      console.error("Transfer error:", ex);
      alert(ex.response?.data?.message || ex.message || "Transaction failed");
    }
  }

  return (
    <form className="container transfer" onSubmit={transfer}>
      <h1>Send Transaction</h1>

      <label>
        Send Amount
        <input
          placeholder="1, 2, 3..."
          value={sendAmount}
          onChange={setValue(setSendAmount)}
        />
      </label>

      <label>
        Recipient
        <input
          placeholder="Type an address, for example: 0x2"
          value={recipient}
          onChange={setValue(setRecipient)}
        />
      </label>

      <input type="submit" className="button" value="Transfer" />
    </form>
  );
}

export default Transfer;

import server from "./server";
import { useEffect, useState } from "react";

function Wallet({ address, balance, setBalance }) {
  const [loading, setLoading] = useState(false);
  console.log("Wallet component received address:", address);
  
  useEffect(() => {
    console.log("Wallet useEffect triggered with address:", address);
    fetchData();
  }, [address, setBalance]);

  const fetchData = async () => {
    console.log("fetchData called with address:", address);
    if (address) {
      try {
        console.log("Fetching balance for:", address);
        const {
          data: { balance },
        } = await server.get(`balance/${address}`);
        console.log("Balance fetched:", balance);
        setBalance(balance);
      } catch (error) {
        console.error("Error fetching balance:", error);
        setBalance(0);
      }
    } else {
      console.log("No address provided");
      setBalance(0);
    }
  };

  const addTokens = async () => {
    if (!address) {
      alert("Address not loaded yet");
      return;
    }
    
    setLoading(true);
    console.log("Adding tokens to:", address);
    
    try {
      const {
        data: { balance },
      } = await server.post(`/addToBalance/${address}`);
      console.log("Tokens added, new balance:", balance);
      setBalance(balance);
     
    } catch (error) {
      console.error("Error adding tokens:", error);
      alert("Failed to add tokens: " + (error.response?.data?.message || error.message));
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="container wallet">
      <h1>Your Wallet</h1>

      <label>
        Wallet Address
        <input placeholder="Type an address, for example: 0x1" value={address} readOnly></input>
      </label>

      <div className="balance">Balance: {balance}</div>
      <button 
        onClick={addTokens} 
        className="button" 
        disabled={loading || !address}
        style={{ opacity: loading || !address ? 0.6 : 1, cursor: loading || !address ? "not-allowed" : "pointer" }}
      >
        {loading ? "Adding tokens..." : "Add 20 Tokens"}
      </button>
    </div>
  );
}

export default Wallet;

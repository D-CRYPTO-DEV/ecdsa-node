import Wallet from "./Wallet";
import Transfer from "./Transfer";
import "./App.scss";
import { useState, useEffect } from "react";
import server from "./server";

function App() {
  const [balance, setBalance] = useState(0);
  const [address, setAddress] = useState("");

  useEffect(() => {
    const getPublicKey = async () => {
      try {
        console.log("Fetching public key from /");
        const { data } = await server.get("/");
        console.log("Response data:", data);
        // Format public key to 0x + last 40 chars (42 total)
        let fullKey = data.publicKey;
        console.log("Full key:", fullKey, "Length:", fullKey.length);
        
        // Remove 0x prefix if it exists
        if (fullKey.startsWith('0x')) {
          fullKey = fullKey.slice(2);
        }
        
        // Take last 40 hex chars (20 bytes = 40 hex chars)
        const lastFortyChars = fullKey.slice(-40);
        const formattedAddress = `0x${lastFortyChars}`;
        console.log("Formatted address:", formattedAddress, "Length:", formattedAddress.length);
        setAddress(formattedAddress);
      } catch (error) {
        console.error("Error fetching public key:", error);
      }
    };
    getPublicKey();
  }, []);

  return (
    <div className="app">
      <Wallet
        balance={balance}
        setBalance={setBalance}
        address={address}
      />
      <Transfer setBalance={setBalance} address={address} />
    </div>
  );
}

export default App;

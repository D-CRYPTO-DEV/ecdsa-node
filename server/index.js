import express from "express";
import cors from "cors";
import fs from "fs";

import * as secp from "@noble/secp256k1";

import { keccak256 } from "ethereum-cryptography/keccak.js";
// import { keccak_256 } from '@noble/hashes/sha3.js';
// import { sha256 } from "ethereum-cryptography/sha256.js";
import {
  utf8ToBytes,
  hexToBytes,
  toHex,
  concatBytes,
} from "ethereum-cryptography/utils.js";

import { keyManager } from "./middleware/keyGeneration.js";

const app = express();
const port = 3042;

/* --------------------------------------------------
   🔑 REQUIRED: wire hashes for noble secp256k1
-------------------------------------------------- */
import { hmac } from '@noble/hashes/hmac.js';
import { sha256 } from '@noble/hashes/sha2.js';
secp.hashes.hmacSha256 = (key, msg) => hmac(sha256, key, msg);
secp.hashes.sha256 = sha256;
secp.hashes.sha256 = (...msgs) =>
  sha256(concatBytes(...msgs));


/* --------------------------------------------------
   Middleware
-------------------------------------------------- */
app.use(cors());
app.use(express.json());
// const __dirname = path.resolve();
const PORT = process.env.PORT || 3042;

/* --------------------------------------------------
   In-memory balances
-------------------------------------------------- */
const balances = {};

/* --------------------------------------------------
   Helpers
-------------------------------------------------- */
function setInitialBalance(address) {
  if (!balances[address]) balances[address] = 0;
}

function recoverSender(signature, msgBytes) {
  const msgHash = keccak256(msgBytes);
  console.log("Signature bytes length:", signature);
  
  // const signatureWithRecovery = new Uint8Array(65);

  // Now pass the 65-byte array to the library
  const publicKey = secp.recoverPublicKey(signature, msgHash, { prehash: false });

  const sender = `0x${toHex(publicKey).slice(-40)}`;

  return {
    sender,
    balance: balances[sender] || 0,
  };
}

/* --------------------------------------------------
   Routes
-------------------------------------------------- */
app.get("/", keyManager);

app.post("/addToBalance/:address", (req, res) => {
  const { address } = req.params;
  setInitialBalance(address);
  balances[address] += 20;
  res.send({ balance: balances[address] });
});

app.get("/balance/:address", (req, res) => {
  res.send({ balance: balances[req.params.address] || 0 });
});

/* --------------------------------------------------
   Sign Message
-------------------------------------------------- */
app.post("/signMessage", async (req, res) => {
  try {
    const { msg } = req.body;

    console.log("Incoming msg:", msg);

    const keys = JSON.parse(fs.readFileSync("keys.json", "utf8"));
    const privateKey = Uint8Array.from(Object.values(keys.privateKey));

    console.log("Private key length:", privateKey);

    const msgBytes = utf8ToBytes(msg);
    const msgHash = keccak256(msgBytes);

    console.log("Msg hash length:", msg.length);

    const sig =  secp.sign(msgHash, privateKey, { format: 'recovered', prehash: false });
    console.log("sig:",sig);

  const signatureHex = { ... sig};
  console.log("signatureHex:",signatureHex);
 
  res.status(200).json({
    signature: signatureHex,
    msg
  });

  } catch (err) {
    console.error("SIGN ERROR:", err);
    res.status(500).json({
      error: err.message,
      stack: err.stack,
    });
  }
});



/* --------------------------------------------------
   Send Transaction
-------------------------------------------------- */
app.post("/send", (req, res) => {
  try {
    const { signature, msg, recipient, amount} = req.body;

    const msgBytes = utf8ToBytes(msg);
    const arraySign = Uint8Array.from(Object.values(signature));
    const { sender, balance } =
    recoverSender(arraySign, msgBytes);

    setInitialBalance(sender);
    setInitialBalance(recipient);

    if (balance < amount) {
      return res.status(400).send({ message: "Not enough funds" });
    }

    balances[sender] -= amount;
    balances[recipient] += amount;

    res.send({ balance: balances[sender] });
  } catch (err) {
    console.error("Transaction error:", err);
    res.status(400).send({ error: err.message });
  }
});


// prepare for deployment
// if(process.env.NODE_ENV === "production"){
//     app.use(express.static(path.join(__dirname,"../admin/dist")))

//     app.get("/{*any}", (req, res)=> {
//         res.sendFile(path.join(__dirname, "../admin", "dist", "index.html"))
//     })
// }

/* --------------------------------------------------
   Start Server
-------------------------------------------------- */
app.listen(port, () => {
  console.log(`🚀 Listening on port ${port}`);
});

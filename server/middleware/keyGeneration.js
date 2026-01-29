import * as secp2 from "@noble/secp256k1";
import { toHex } from "ethereum-cryptography/utils.js";
import fs from "fs";

// Generate and save keys if not already present
const generateAndSaveKeys = () => {
   const key = secp2.keygen();
  const { secretKey, publicKey } = key;
  const keys = {
    privateKey: secretKey,
    publicKey: toHex(publicKey),
  };
  fs.writeFileSync("keys.json", JSON.stringify(keys, null, 2));
  return { publicKey: keys.publicKey };
};

// check if keys.json exists
export const keyManager = (req, res, next) => {
  try {
    const keysFile = fs.readFileSync("keys.json");
    const keys = JSON.parse(keysFile);
    console.log("Keys already exist. Skipping key generation.");
    res.json({ publicKey: keys.publicKey });
  } catch (err) {
    const publicKey = generateAndSaveKeys();
    res.json({ publicKey: publicKey.publicKey });
  }
};


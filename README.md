# VerdictToken — Complete User Guide

Welcome to the **VerdictToken** system — a decentralized, burn-based finality protocol deployed on Polygon. This guide will walk you through what VerdictToken is, how to use it, and how to interact with it both as a beginner and an advanced on-chain user.

---

## 🧠 What Is VerdictToken?

VerdictToken is a blockchain-based system that lets users:

* Mint unique token entries (by `name` and `number`)
* Burn them to progress toward **on-chain consensus**
* Track whether a decision has been finalized

It's a cryptographic way to create **irreversible decisions** — and each action is permanent.

---

## 🌐 Where Is It Deployed?

* **Contract Address:** `0xADCdb832D1c4fa4262E64E7b0318695Fcb46c9d9`
* **Chain:** Polygon Mainnet
* **Backend API:** [https://verdict-api.fly.dev/](https://verdict-api.fly.dev/)
* **Deployer:** `0x0F6dbb5B71372aB1d77Ed67D1260083cF9f07476`
* **Oracle:** POL/USD at `0xFE66C0da9c9f6c5D04D3f2B2CB59AB5A1b10a17E`

---

## 🧰 How Does It Work?

### 1. Mint a Verdict

You send a POST request with a name and amount. A fee of **\$0.25 worth of POL** is dynamically calculated from the Chainlink oracle.

### 2. Burn to Reach Consensus

Burning is irreversible. Once enough tokens are burned for a name/number combo, consensus is reached and becomes final.

### 3. Check Finality

Using `hasConsensus("name")` you can ask: Has this name reached finality?

---

## 🟢 Basic Usage (Beginner)

You can interact with VerdictToken through a simple website or cURL commands.

### ✅ Mint

```bash
curl -X POST https://verdict-api.fly.dev/mint \
 -H "Content-Type: application/json" \
 -d '{"name":"TartarLocker", "amount":3}'
```

Returns:

```json
{ "to": "0xADC...d9", "data": "0xabc...", "value": "0x0" }
```

You copy-paste this into MetaMask as a custom transaction.

### ✅ Burn

```bash
curl -X POST https://verdict-api.fly.dev/burn \
 -H "Content-Type: application/json" \
 -d '{"name":"TartarLocker", "amount":1}'
```

### ✅ Check Consensus

```bash
curl -X POST https://verdict-api.fly.dev/status \
 -H "Content-Type: application/json" \
 -d '{"name":"TartarLocker"}'
```

---

## 🧠 Advanced Usage (Developer / On-Chain)

### ✅ Direct JSON-RPC Access

```bash
curl -X POST https://polygon-rpc.com \
 -H "Content-Type: application/json" \
 -d '{
   "jsonrpc": "2.0",
   "id": 1,
   "method": "eth_call",
   "params": [{
     "to": "0xADCdb832D1c4fa4262E64E7b0318695Fcb46c9d9",
     "data": "<ABI-encoded hasConsensus call>"
   }, "latest"]
 }'
```

### 🛑 Caution:

If the name has never been minted, `hasConsensus(...)` will **revert** — not return `false`.

---

## 🛠 Backend Architecture

* **Backend File:** `verdict_server.py`
* **Serves:** All endpoints via HTTP (no Flask or FastAPI)
* **Hosted at:** Fly.io
* **Returns:** Raw txs to be signed by MetaMask
* **No private keys on server**

---

## 🧪 Supported Endpoints

| Method | Endpoint | Usage Example                             |
| ------ | -------- | ----------------------------------------- |
| POST   | /mint    | `{ "name": "TartarLocker", "amount": 3 }` |
| POST   | /burn    | `{ "name": "TartarLocker", "amount": 1 }` |
| POST   | /status  | `{ "name": "TartarLocker" }`              |
| POST   | /supply  | `{ "name": "TartarLocker" }`              |
| POST   | /details | `{ "name": "TartarLocker" }`              |
| POST   | /events  | `{ "name": "TartarLocker" }`              |
| POST   | /tokens  | `{}`                                      |
| GET    | /        | Web homepage with live documentation      |

---

## 🛡 Security Model

* No admin key or owner override
* Minting fee handled via oracle
* Finality is **permanent** once reached
* No proxy or upgradable logic
* All contract state changes are irreversible

---

## 🧰 Debugging & Logs

| Symptom              | Cause                      | Fix                                |
| -------------------- | -------------------------- | ---------------------------------- |
| `execution reverted` | Name not minted            | Call `/mint` before `/status`      |
| 502 error on Fly.io  | Wrong file or port binding | Use `verdict_server.py`, port 8080 |
| Zero tokens shown    | Nothing minted yet         | Mint with `/mint`                  |

---

## 📦 Replication Guide

1. Clone `verdict_server.py`
2. Use `Dockerfile` and `requirements.txt`
3. Deploy via:

```bash
fly launch --name verdict-api
fly deploy
```

4. Confirm at:
   [https://verdict-api.fly.dev/](https://verdict-api.fly.dev/)

---

## 🏁 Final Thought

VerdictToken isn’t just a coin — it’s a decision engine. Once a name reaches consensus, that state is irreversible.

> "No takebacks. Only verdicts."

---

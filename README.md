# Bavani Swap — BA / ETH Liquidity Pool

A minimal Uniswap-style swap app for the **BA** token (your name token) paired against **Sepolia ETH**.

- Token: **Bavani (BA)**, max supply **1,000,000 BA**
- Liquidity pool seeded with **500,000 BA (50% of max supply)** + a small amount of Sepolia ETH
- Simple constant-product AMM (`x * y = k`), same 0.3% fee model as Uniswap
- Plain HTML/JS frontend using ethers.js + MetaMask — no build step needed, styled as a "token passbook" so it doesn't look like a generic swap template
- Built-in Feedback tab that saves tester comments locally (survives a refresh) and exports them as Markdown for your report

Everything below can be done on your own laptop in about 20–30 minutes. **You cannot deploy from inside this chat** — deploying needs your own wallet's private key and a real Sepolia RPC connection, which should never be shared with anyone, including me.

---

## 0. What you need before you start

1. **MetaMask** installed in your browser (metamask.io), with a wallet created.
2. **Sepolia test ETH** in that wallet. Get free testnet ETH from a faucet, e.g.:
   - https://sepoliafaucet.com
   - https://www.alchemy.com/faucets/ethereum-sepolia
   (You need at least ~0.05 Sepolia ETH — a little for gas, a little to seed the pool.)
3. A **Sepolia RPC URL** — free from either:
   - Alchemy: https://www.alchemy.com (create app → Sepolia → copy HTTPS URL)
   - Infura: https://www.infura.io
4. (Optional, for the "verify contract" step) A free **Etherscan API key**: https://etherscan.io/apis

---

## 1. Install dependencies

Unzip the project, then in a terminal:

```bash
cd bavani-swap
npm install
```

## 2. Configure your secrets

```bash
cp .env.example .env
```

Open `.env` and fill in:

```
SEPOLIA_RPC_URL=https://eth-sepolia.g.alchemy.com/v2/YOUR_KEY
PRIVATE_KEY=your_metamask_private_key_without_0x_prefix
ETHERSCAN_API_KEY=your_etherscan_key
```

To export your private key from MetaMask: Account menu → Account details → Show private key.
**Never commit `.env` or share this key with anyone.** `.gitignore` already excludes it.

## 3. Compile the contracts

```bash
npx hardhat compile
```

You should see `Compiled X Solidity files successfully`.

## 4. Deploy to Sepolia + seed the pool

```bash
npx hardhat run scripts/deploy.js --network sepolia
```

This single script:
1. Deploys `BavaniToken` (mints all 1,000,000 BA to you)
2. Deploys `BavaniSwapPool`
3. Approves the pool for 500,000 BA
4. Seeds the pool with 500,000 BA + 0.02 Sepolia ETH (edit `ETH_LIQUIDITY` at the top of `scripts/deploy.js` if you want a different amount)

At the end it prints two addresses and two Etherscan links — **save these**, e.g.:

```
Token (BA) address : 0xAbc123...
Pool address        : 0xDef456...
```

## 5. (Optional but nice for the report) Verify contracts on Etherscan

```bash
npx hardhat verify --network sepolia <TOKEN_ADDRESS>
npx hardhat verify --network sepolia <POOL_ADDRESS> <TOKEN_ADDRESS>
```

This makes the contract source public and readable on Etherscan — good evidence for your report.

## 6. Wire up the frontend

Open `frontend/index.html` and paste your two addresses at the top of the `<script>` block:

```js
const TOKEN_ADDRESS = "0xAbc123...";
const POOL_ADDRESS  = "0xDef456...";
```

Test it locally first:

```bash
npx serve frontend
```

Open the printed `localhost` link, connect MetaMask (make sure MetaMask is on the **Sepolia** network), and try a small swap in each direction.

## 7. Get a public link to share with your friend

Easiest no-signup option:

1. Go to https://app.netlify.com/drop
2. Drag the `frontend` folder onto the page
3. You instantly get a public URL like `https://random-name-123.netlify.app`

Send that link to your friend. They'll need MetaMask + a little Sepolia ETH of their own (send them some from your wallet, or point them to the same faucet) to actually try a swap.

## 8. Collect feedback + write the report

The frontend now has a built-in **Feedback** tab (next to Swap). Ask your friend to:
- Connect their wallet
- Try an ETH → BA swap
- Try a BA → ETH swap
- Open the **Feedback** tab and log their name, which swap they tried, a star rating, and any comments about what was confusing, slow, or broken

Each entry is saved with `localStorage`, so it's tied to that browser/device and **stays there even after a page refresh** — but it's only visible on the device that entered it (there's no shared server), so collect feedback on your friend's own browser or note it down while they test on yours.

When you're ready to write the report, open the Feedback tab and click **Copy for report** — it copies a ready-made Markdown block of every saved entry, formatted to paste straight into the "Feedback Received" section of `FEEDBACK_REPORT.md`. Fill in the rest of the report (addresses, tx hashes, conclusion), then convert it to a Word/PDF if your sir wants a formal document — I can generate that for you once you have the actual feedback.

---

## Project structure

```
bavani-swap/
├── contracts/
│   ├── BavaniToken.sol       ERC20 token: name "Bavani", symbol "BA", 1,000,000 max supply
│   └── BavaniSwapPool.sol    Constant-product AMM pool for BA/ETH
├── scripts/
│   └── deploy.js             Deploys token + pool, seeds 50% liquidity
├── frontend/
│   └── index.html            Swap UI (ethers.js + MetaMask)
├── hardhat.config.js
├── .env.example
└── README.md
```

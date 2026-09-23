const hre = require("hardhat");

// How much ETH to pair against the 50% BA liquidity.
// Edit this if you want to seed the pool with more/less ETH.
const ETH_LIQUIDITY = "0.02"; // 0.02 Sepolia ETH

async function main() {
  const [deployer] = await hre.ethers.getSigners();
  console.log("Deploying with account:", deployer.address);
  console.log(
    "Account balance:",
    hre.ethers.formatEther(await hre.ethers.provider.getBalance(deployer.address)),
    "ETH"
  );

  // 1. Deploy the BA token (mints full 1,000,000 supply to deployer)
  const BavaniToken = await hre.ethers.getContractFactory("BavaniToken");
  const token = await BavaniToken.deploy();
  await token.waitForDeployment();
  const tokenAddress = await token.getAddress();
  console.log("BavaniToken (BA) deployed to:", tokenAddress);

  const maxSupply = await token.MAX_SUPPLY();
  const halfSupply = maxSupply / 2n; // 500,000 BA = 50% of max supply

  // 2. Deploy the swap pool, pointing it at the token
  const BavaniSwapPool = await hre.ethers.getContractFactory("BavaniSwapPool");
  const pool = await BavaniSwapPool.deploy(tokenAddress);
  await pool.waitForDeployment();
  const poolAddress = await pool.getAddress();
  console.log("BavaniSwapPool deployed to:", poolAddress);

  // 3. Approve the pool to pull 50% of supply, then seed liquidity
  console.log(`Approving pool to spend ${hre.ethers.formatEther(halfSupply)} BA...`);
  const approveTx = await token.approve(poolAddress, halfSupply);
  await approveTx.wait();

  console.log(
    `Seeding pool with ${hre.ethers.formatEther(halfSupply)} BA + ${ETH_LIQUIDITY} ETH...`
  );
  const seedTx = await pool.addInitialLiquidity(halfSupply, {
    value: hre.ethers.parseEther(ETH_LIQUIDITY),
  });
  await seedTx.wait();

  console.log("\n=== DEPLOYMENT COMPLETE ===");
  console.log("Token (BA) address :", tokenAddress);
  console.log("Pool address        :", poolAddress);
  console.log("Pool seeded with    :", hre.ethers.formatEther(halfSupply), "BA +", ETH_LIQUIDITY, "ETH");
  console.log("\nSave these two addresses — you'll paste them into frontend/index.html");
  console.log("\nView on Sepolia Etherscan:");
  console.log(`Token: https://sepolia.etherscan.io/address/${tokenAddress}`);
  console.log(`Pool : https://sepolia.etherscan.io/address/${poolAddress}`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});

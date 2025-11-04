// after Airdrop deployed and tokenAddr known
const Reward = await hre.ethers.getContractFactory("Reward");
const reward = await Reward.deploy(tokenAddr);
await reward.waitForDeployment();
const rewardAddr = await reward.getAddress();
console.log("Reward:", rewardAddr);
// fund reward contract (example: 50,000,000 ZEA)
const fundAmount = hre.ethers.parseUnits("50000000", 18); // 50M
await z.transfer(rewardAddr, fundAmount);
console.log("Funded Reward contract:", rewardAddr);

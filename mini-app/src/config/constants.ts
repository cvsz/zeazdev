/**
 * constants.ts
 * Application configuration constants
 */

// API Configuration
export const API_URL = process.env.API_URL || 'http://localhost:3000';
export const RPC_URL = process.env.RPC_URL || 'https://worldchain-mainnet.g.alchemy.com/v2/your-key';

// World ID Configuration
export const WORLD_APP_ID = process.env.WORLD_APP_ID || '';
export const WORLD_ACTION_ID = process.env.WORLD_ACTION_ID || '';

// Contract Addresses (update after deployment)
export const CONTRACTS = {
  ZEA_TOKEN: '0x0000000000000000000000000000000000000000',
  WORLD_ID_REWARDS: '0x0000000000000000000000000000000000000000',
  WLD_TOKEN: '0x0000000000000000000000000000000000000000',
};

// Reward Amounts (in Wei)
export const DAILY_REWARD_AMOUNT = '100000000000000000000'; // 100 ZEA
export const AIRDROP_AMOUNT = '1000000000000000000000'; // 1000 ZEA

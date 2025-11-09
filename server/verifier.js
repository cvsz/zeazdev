/**
 * ============================================================================
 * ZeaZDev - Full Omega Ultimate DevOps Professional Enterprises
 * ============================================================================
 * 
 * Project: ZeaZDev Backend Verifier Service
 * File: verifier.js
 * Version: 1.0.0
 * 
 * Developer: PHIPHAT PHOEMSUK (ZeaZDev)
 * Email: admin@zeaz.dev
 * Website: https://app.zeaz.dev
 * GitHub: https://github.com/ZeaZDev
 * 
 * Description:
 * Backend server for World ID Zero-Knowledge Proof verification and 
 * reward distribution. Acts as a relayer for gasless transactions.
 * 
 * Features:
 * - World ID ZKP verification via World ID API
 * - Smart contract interaction for reward distribution
 * - Gasless transaction relay service
 * - Daily check-in reward system
 * - Airdrop claim processing
 * - User data retrieval
 * 
 * This server:
 * 1. Receives Zero-Knowledge Proofs from frontend
 * 2. Verifies proofs with World ID API
 * 3. Interacts with smart contracts for rewards
 * 4. Acts as a relayer for gasless transactions
 * 5. Manages daily check-in rewards
 * 6. Processes airdrop claims
 * 
 * License: MIT
 * Copyright (c) 2025 PHIPHAT PHOEMSUK
 * 
 * Last Updated: 2025-01-09
 * ============================================================================
 */

const express = require('express');
const cors = require('cors');
const { ethers } = require('ethers');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(express.json());

// Configuration
const WORLD_APP_ID = process.env.WORLD_APP_ID;
const WORLD_APP_API_KEY = process.env.WORLD_APP_API_KEY;
const RPC_URL = process.env.RPC_URL || 'https://worldchain-mainnet.g.alchemy.com/v2/your-key';
const RELAYER_PRIVATE_KEY = process.env.RELAYER_PRIVATE_KEY;
const WORLD_ID_REWARDS_CONTRACT = process.env.WORLD_ID_REWARDS_CONTRACT;

// Initialize provider and relayer wallet
const provider = new ethers.JsonRpcProvider(RPC_URL);
const relayerWallet = new ethers.Wallet(RELAYER_PRIVATE_KEY, provider);

// WorldIDRewards Contract ABI (simplified)
const REWARDS_ABI = [
  'function verifyAndRegister(address signal, uint256 root, uint256 nullifierHash, uint256[8] calldata proof) external',
  'function claimAirdrop() external',
  'function dailyCheckIn() external',
  'function getCheckInStatus(address user) external view returns (bool canCheckIn, uint256 timeUntilNext)',
  'function getUserData(address user) external view returns (bool isVerified, bool hasClaimedAirdrop, uint256 lastCheckIn, uint256 totalRewardsClaimed, uint256 checkInStreak)',
];

const rewardsContract = new ethers.Contract(
  WORLD_ID_REWARDS_CONTRACT,
  REWARDS_ABI,
  relayerWallet
);

/**
 * POST /api/verify-worldid
 * Verify World ID proof and register user
 */
app.post('/api/verify-worldid', async (req, res) => {
  try {
    const { signal, merkle_root, nullifier_hash, proof } = req.body;

    console.log('Verifying World ID proof...');
    console.log('Signal (address):', signal);
    console.log('Nullifier Hash:', nullifier_hash);

    // Step 1: Verify with World ID API
    const worldIdVerification = await verifyWithWorldID({
      merkle_root,
      nullifier_hash,
      proof,
    });

    if (!worldIdVerification.success) {
      return res.status(400).json({
        success: false,
        message: 'World ID verification failed',
      });
    }

    // Step 2: Register on smart contract
    // Convert proof to uint256[8] array format
    const proofArray = parseProof(proof);
    
    const tx = await rewardsContract.verifyAndRegister(
      signal,
      merkle_root,
      nullifier_hash,
      proofArray
    );

    await tx.wait();

    console.log('User registered successfully. TX:', tx.hash);

    res.json({
      success: true,
      verified: true,
      txHash: tx.hash,
      message: 'World ID verified and user registered',
    });
  } catch (error) {
    console.error('Verification error:', error);
    res.status(500).json({
      success: false,
      message: error.message || 'Verification failed',
    });
  }
});

/**
 * GET /api/check-verification/:address
 * Check if user is verified
 */
app.get('/api/check-verification/:address', async (req, res) => {
  try {
    const { address } = req.params;

    const userData = await rewardsContract.getUserData(address);
    const [isVerified] = userData;

    res.json({
      isVerified,
    });
  } catch (error) {
    console.error('Check verification error:', error);
    res.status(500).json({
      isVerified: false,
      error: error.message,
    });
  }
});

/**
 * GET /api/checkin-status/:address
 * Get user's check-in status
 */
app.get('/api/checkin-status/:address', async (req, res) => {
  try {
    const { address } = req.params;

    const [canCheckIn, timeUntilNext] = await rewardsContract.getCheckInStatus(address);
    const userData = await rewardsContract.getUserData(address);
    const [, hasClaimedAirdrop, , totalRewardsClaimed, checkInStreak] = userData;

    res.json({
      canCheckIn,
      timeUntilNext: Number(timeUntilNext),
      hasClaimedAirdrop,
      streak: Number(checkInStreak),
      totalRewards: ethers.formatEther(totalRewardsClaimed),
    });
  } catch (error) {
    console.error('Get check-in status error:', error);
    res.status(500).json({
      error: error.message,
    });
  }
});

/**
 * POST /api/claim-airdrop
 * Claim initial airdrop
 */
app.post('/api/claim-airdrop', async (req, res) => {
  try {
    const { address, nullifierHash } = req.body;

    console.log('Processing airdrop claim for:', address);

    // Execute transaction via relayer (gasless for user)
    const tx = await rewardsContract.claimAirdrop();
    const receipt = await tx.wait();

    console.log('Airdrop claimed. TX:', tx.hash);

    res.json({
      success: true,
      txHash: tx.hash,
      amount: '1000', // Update with actual amount from event
    });
  } catch (error) {
    console.error('Claim airdrop error:', error);
    res.status(500).json({
      success: false,
      error: error.message,
    });
  }
});

/**
 * POST /api/daily-checkin
 * Daily check-in for rewards
 */
app.post('/api/daily-checkin', async (req, res) => {
  try {
    const { address, nullifierHash } = req.body;

    console.log('Processing daily check-in for:', address);

    // Execute transaction via relayer
    const tx = await rewardsContract.dailyCheckIn();
    const receipt = await tx.wait();

    // Parse event to get streak
    // In production, parse the DailyCheckIn event
    const streak = 1; // Mock value

    console.log('Check-in successful. TX:', tx.hash);

    res.json({
      success: true,
      txHash: tx.hash,
      amount: '100', // Update with actual amount
      streak,
    });
  } catch (error) {
    console.error('Daily check-in error:', error);
    res.status(500).json({
      success: false,
      error: error.message,
    });
  }
});

/**
 * POST /api/swap-quote
 * Get swap quote from DEX
 */
app.post('/api/swap-quote', async (req, res) => {
  try {
    const { fromToken, toToken, amount } = req.body;

    // Mock implementation - integrate with actual DEX router
    // e.g., Uniswap V3, Sushiswap
    
    const exchangeRate = '1.05'; // Mock rate
    const outputAmount = (parseFloat(amount) * parseFloat(exchangeRate)).toFixed(4);
    const priceImpact = '0.5';

    res.json({
      outputAmount,
      exchangeRate,
      priceImpact,
      estimatedGas: '0.002',
    });
  } catch (error) {
    console.error('Get swap quote error:', error);
    res.status(500).json({
      error: error.message,
    });
  }
});

/**
 * POST /api/execute-swap
 * Execute token swap
 */
app.post('/api/execute-swap', async (req, res) => {
  try {
    const { userAddress, fromToken, toToken, fromAmount, toAmount, slippage } = req.body;

    console.log('Executing swap:', fromToken, '->', toToken);

    // Mock implementation - integrate with DEX router
    // This would:
    // 1. Approve tokens if needed
    // 2. Call router's swap function
    // 3. Return transaction hash

    res.json({
      success: true,
      txHash: '0x' + '1234567890abcdef'.repeat(4), // Mock tx hash
    });
  } catch (error) {
    console.error('Execute swap error:', error);
    res.status(500).json({
      success: false,
      error: error.message,
    });
  }
});

/**
 * Helper: Verify with World ID API
 */
async function verifyWithWorldID({ merkle_root, nullifier_hash, proof }) {
  try {
    // Call World ID verification API
    // https://developer.worldcoin.org/api/v1/verify
    
    const response = await fetch('https://developer.worldcoin.org/api/v1/verify', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${WORLD_APP_API_KEY}`,
      },
      body: JSON.stringify({
        merkle_root,
        nullifier_hash,
        proof,
        verification_level: 'orb', // or 'device'
        action: process.env.WORLD_ACTION_ID,
      }),
    });

    if (!response.ok) {
      throw new Error('World ID API verification failed');
    }

    const data = await response.json();
    return {
      success: data.success || false,
      verified: data.verified || false,
    };
  } catch (error) {
    console.error('World ID API error:', error);
    return { success: false };
  }
}

/**
 * Helper: Parse proof string to uint256[8] array
 */
function parseProof(proof) {
  // Parse proof format from World ID
  // This depends on the exact format returned by IDKit
  // Mock implementation
  return Array(8).fill('0');
}

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

// Start server
app.listen(PORT, () => {
  console.log(`=================================`);
  console.log(`ZeaZDev Verifier Server`);
  console.log(`=================================`);
  console.log(`Server running on port ${PORT}`);
  console.log(`World App ID: ${WORLD_APP_ID}`);
  console.log(`Contract: ${WORLD_ID_REWARDS_CONTRACT}`);
  console.log(`Relayer: ${relayerWallet.address}`);
  console.log(`=================================`);
});

module.exports = app;

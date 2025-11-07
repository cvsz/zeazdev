/**
 * wallet.ts
 * Wallet service for managing tokens and transactions
 */

import { ethers } from 'ethers';
import { API_URL, RPC_URL } from '../config/constants';

/**
 * Get token balance
 * @param address User's address
 * @param token Token symbol (WLD, GAS, etc.)
 * @returns Balance as string
 */
export async function getBalance(address: string, token: 'WLD' | 'GAS'): Promise<string> {
  try {
    // Mock implementation - replace with actual RPC calls
    const provider = new ethers.JsonRpcProvider(RPC_URL);
    
    if (token === 'GAS') {
      // Get native token balance (ETH/MATIC)
      const balance = await provider.getBalance(address);
      return ethers.formatEther(balance);
    } else {
      // Get ERC-20 token balance (WLD)
      // This would require the token contract address and ABI
      // Mock for demonstration
      return '100.00';
    }
  } catch (error) {
    console.error('Get balance error:', error);
    return '0.00';
  }
}

interface SendTokenParams {
  from: string;
  to: string;
  amount: string;
  token: 'WLD' | 'GAS';
}

interface SendTokenResponse {
  success: boolean;
  txHash?: string;
  error?: string;
}

/**
 * Send tokens to another address
 * @param params Transaction parameters
 * @returns Transaction result
 */
export async function sendToken(params: SendTokenParams): Promise<SendTokenResponse> {
  try {
    // This would normally:
    // 1. Get user's private key from secure storage
    // 2. Create and sign transaction
    // 3. Broadcast to network
    
    // Mock implementation
    console.log('Sending token:', params);
    
    // Simulate API call to relayer for gasless transaction
    const response = await fetch(`${API_URL}/api/send-token`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(params),
    });

    if (!response.ok) {
      throw new Error('Transaction failed');
    }

    const data = await response.json();
    
    return {
      success: true,
      txHash: data.txHash || '0x1234...mock',
    };
  } catch (error: any) {
    console.error('Send token error:', error);
    return {
      success: false,
      error: error.message || 'Failed to send token',
    };
  }
}

/**
 * rewards.ts
 * Reward distribution service
 */

import { API_URL } from '../config/constants';

interface CheckInStatusResponse {
  canCheckIn: boolean;
  timeUntilNext: number;
  hasClaimedAirdrop: boolean;
  streak: number;
  totalRewards: string;
}

/**
 * Get user's check-in status
 * @param address User's address
 * @returns Check-in status
 */
export async function getCheckInStatus(address: string): Promise<CheckInStatusResponse> {
  try {
    const response = await fetch(`${API_URL}/api/checkin-status/${address}`);
    
    if (!response.ok) {
      throw new Error('Failed to get status');
    }

    const data = await response.json();
    return data;
  } catch (error) {
    console.error('Get check-in status error:', error);
    // Return default values
    return {
      canCheckIn: true,
      timeUntilNext: 0,
      hasClaimedAirdrop: false,
      streak: 0,
      totalRewards: '0',
    };
  }
}

interface ClaimResult {
  success: boolean;
  amount?: string;
  txHash?: string;
  streak?: number;
  error?: string;
}

/**
 * Claim initial airdrop
 * @param address User's address
 * @param nullifierHash User's World ID nullifier
 * @returns Claim result
 */
export async function claimAirdrop(
  address: string,
  nullifierHash: string
): Promise<ClaimResult> {
  try {
    const response = await fetch(`${API_URL}/api/claim-airdrop`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ address, nullifierHash }),
    });

    if (!response.ok) {
      const error = await response.json();
      throw new Error(error.message || 'Claim failed');
    }

    const data = await response.json();
    return {
      success: true,
      amount: data.amount,
      txHash: data.txHash,
    };
  } catch (error: any) {
    console.error('Claim airdrop error:', error);
    return {
      success: false,
      error: error.message || 'Failed to claim airdrop',
    };
  }
}

/**
 * Daily check-in to claim rewards
 * @param address User's address
 * @param nullifierHash User's World ID nullifier
 * @returns Check-in result
 */
export async function dailyCheckIn(
  address: string,
  nullifierHash: string
): Promise<ClaimResult> {
  try {
    const response = await fetch(`${API_URL}/api/daily-checkin`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ address, nullifierHash }),
    });

    if (!response.ok) {
      const error = await response.json();
      throw new Error(error.message || 'Check-in failed');
    }

    const data = await response.json();
    return {
      success: true,
      amount: data.amount,
      txHash: data.txHash,
      streak: data.streak,
    };
  } catch (error: any) {
    console.error('Daily check-in error:', error);
    return {
      success: false,
      error: error.message || 'Failed to check in',
    };
  }
}

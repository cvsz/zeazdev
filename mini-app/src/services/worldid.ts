/**
 * worldid.ts
 * World ID verification service
 * Handles Zero-Knowledge Proof verification
 */

import { API_URL } from '../config/constants';

interface VerifyProofParams {
  signal: string;          // User's address
  merkle_root: string;     // Merkle root from World ID
  nullifier_hash: string;  // Unique identifier
  proof: string;          // ZK proof
}

interface VerifyProofResponse {
  success: boolean;
  message?: string;
  verified?: boolean;
}

/**
 * Verify World ID proof with backend
 * @param params Proof data from World ID
 * @returns Verification result
 */
export async function verifyProof(params: VerifyProofParams): Promise<VerifyProofResponse> {
  try {
    const response = await fetch(`${API_URL}/api/verify-worldid`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(params),
    });

    if (!response.ok) {
      throw new Error(`HTTP error! status: ${response.status}`);
    }

    const data = await response.json();
    return data;
  } catch (error: any) {
    console.error('World ID verification error:', error);
    return {
      success: false,
      message: error.message || 'Failed to verify World ID',
    };
  }
}

/**
 * Check if user is already verified
 * @param address User's Ethereum address
 * @returns Verification status
 */
export async function checkVerificationStatus(address: string): Promise<boolean> {
  try {
    const response = await fetch(`${API_URL}/api/check-verification/${address}`);
    
    if (!response.ok) {
      return false;
    }

    const data = await response.json();
    return data.isVerified || false;
  } catch (error) {
    console.error('Check verification error:', error);
    return false;
  }
}

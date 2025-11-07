/**
 * swap.ts
 * Token swap service for DEX integration
 */

import { API_URL } from '../config/constants';

interface SwapQuoteParams {
  fromToken: string;
  toToken: string;
  amount: string;
}

interface SwapQuoteResponse {
  outputAmount: string;
  exchangeRate: string;
  priceImpact: string;
  estimatedGas: string;
}

/**
 * Get swap quote from DEX
 * @param params Quote parameters
 * @returns Quote data
 */
export async function getSwapQuote(params: SwapQuoteParams): Promise<SwapQuoteResponse> {
  try {
    const response = await fetch(`${API_URL}/api/swap-quote`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(params),
    });

    if (!response.ok) {
      throw new Error('Failed to get quote');
    }

    const data = await response.json();
    return data;
  } catch (error) {
    console.error('Get swap quote error:', error);
    // Return mock data for demonstration
    return {
      outputAmount: '0',
      exchangeRate: '0',
      priceImpact: '0',
      estimatedGas: '0.001',
    };
  }
}

interface ExecuteSwapParams {
  userAddress: string;
  fromToken: string;
  toToken: string;
  fromAmount: string;
  toAmount: string;
  slippage: string;
}

interface ExecuteSwapResponse {
  success: boolean;
  txHash?: string;
  error?: string;
}

/**
 * Execute token swap
 * @param params Swap parameters
 * @returns Transaction result
 */
export async function executeSwap(params: ExecuteSwapParams): Promise<ExecuteSwapResponse> {
  try {
    const response = await fetch(`${API_URL}/api/execute-swap`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(params),
    });

    if (!response.ok) {
      const error = await response.json();
      throw new Error(error.message || 'Swap failed');
    }

    const data = await response.json();
    return {
      success: true,
      txHash: data.txHash,
    };
  } catch (error: any) {
    console.error('Execute swap error:', error);
    return {
      success: false,
      error: error.message || 'Failed to execute swap',
    };
  }
}

/**
 * SwapTradeScreen.tsx
 * Token swap interface for DEX integration
 * 
 * Features:
 * - Token swap (e.g., WLD <-> ETH)
 * - Price quotes from DEX
 * - Slippage tolerance
 * - Transaction preview
 */

import React, { useState, useEffect } from 'react';
import {
  View,
  Text,
  StyleSheet,
  TouchableOpacity,
  TextInput,
  ActivityIndicator,
  Alert,
  ScrollView,
} from 'react';
import { getSwapQuote, executeSwap } from '../services/swap';

interface SwapTradeScreenProps {
  userAddress: string;
}

const AVAILABLE_TOKENS = [
  { symbol: 'WLD', name: 'Worldcoin', icon: '🌐' },
  { symbol: 'ETH', name: 'Ethereum', icon: '⟠' },
  { symbol: 'ZEA', name: 'ZeaZDev Token', icon: '💎' },
  { symbol: 'USDC', name: 'USD Coin', icon: '💵' },
];

export default function SwapTradeScreen({ userAddress }: SwapTradeScreenProps) {
  const [fromToken, setFromToken] = useState(AVAILABLE_TOKENS[0]);
  const [toToken, setToToken] = useState(AVAILABLE_TOKENS[1]);
  const [fromAmount, setFromAmount] = useState('');
  const [toAmount, setToAmount] = useState('');
  const [slippage, setSlippage] = useState('0.5');
  
  const [isLoadingQuote, setIsLoadingQuote] = useState(false);
  const [isSwapping, setIsSwapping] = useState(false);
  const [showTokenSelector, setShowTokenSelector] = useState<'from' | 'to' | null>(null);
  
  // Quote data
  const [exchangeRate, setExchangeRate] = useState('0');
  const [priceImpact, setPriceImpact] = useState('0');
  const [estimatedGas, setEstimatedGas] = useState('0');

  useEffect(() => {
    if (fromAmount && parseFloat(fromAmount) > 0) {
      loadQuote();
    } else {
      setToAmount('');
      setExchangeRate('0');
    }
  }, [fromAmount, fromToken, toToken]);

  /**
   * Load swap quote from DEX
   */
  const loadQuote = async () => {
    try {
      setIsLoadingQuote(true);
      
      const quote = await getSwapQuote({
        fromToken: fromToken.symbol,
        toToken: toToken.symbol,
        amount: fromAmount,
      });
      
      setToAmount(quote.outputAmount);
      setExchangeRate(quote.exchangeRate);
      setPriceImpact(quote.priceImpact);
      setEstimatedGas(quote.estimatedGas);
      
    } catch (error) {
      console.error('Error loading quote:', error);
      setToAmount('');
    } finally {
      setIsLoadingQuote(false);
    }
  };

  /**
   * Handle token swap
   */
  const handleSwap = async () => {
    // Validation
    if (!fromAmount || parseFloat(fromAmount) <= 0) {
      Alert.alert('Invalid Amount', 'Please enter an amount to swap');
      return;
    }

    if (!toAmount || parseFloat(toAmount) <= 0) {
      Alert.alert('Invalid Quote', 'Unable to get swap quote. Please try again.');
      return;
    }

    const priceImpactNum = parseFloat(priceImpact);
    if (priceImpactNum > 5) {
      Alert.alert(
        'High Price Impact',
        `Price impact is ${priceImpact}%. This trade may result in significant slippage.`,
        [
          { text: 'Cancel', style: 'cancel' },
          { text: 'Continue Anyway', onPress: confirmSwap },
        ]
      );
      return;
    }

    confirmSwap();
  };

  /**
   * Confirm and execute swap
   */
  const confirmSwap = async () => {
    Alert.alert(
      'Confirm Swap',
      `Swap ${fromAmount} ${fromToken.symbol} for ${toAmount} ${toToken.symbol}?\n\nEstimated Gas: ${estimatedGas} ETH`,
      [
        { text: 'Cancel', style: 'cancel' },
        { text: 'Confirm', onPress: executeSwapTransaction },
      ]
    );
  };

  /**
   * Execute the swap transaction
   */
  const executeSwapTransaction = async () => {
    try {
      setIsSwapping(true);
      
      const result = await executeSwap({
        userAddress,
        fromToken: fromToken.symbol,
        toToken: toToken.symbol,
        fromAmount,
        toAmount,
        slippage,
      });
      
      if (result.success) {
        Alert.alert(
          'Swap Successful! 🎉',
          `Transaction hash:\n${result.txHash}`,
          [
            {
              text: 'OK',
              onPress: () => {
                setFromAmount('');
                setToAmount('');
              },
            },
          ]
        );
      } else {
        throw new Error(result.error || 'Swap failed');
      }
    } catch (error: any) {
      console.error('Swap error:', error);
      Alert.alert('Swap Failed', error.message || 'Failed to execute swap');
    } finally {
      setIsSwapping(false);
    }
  };

  /**
   * Swap from and to tokens
   */
  const swapTokenPositions = () => {
    const temp = fromToken;
    setFromToken(toToken);
    setToToken(temp);
    setFromAmount(toAmount);
    setToAmount('');
  };

  /**
   * Select token from list
   */
  const selectToken = (token: typeof AVAILABLE_TOKENS[0]) => {
    if (showTokenSelector === 'from') {
      if (token.symbol !== toToken.symbol) {
        setFromToken(token);
      }
    } else if (showTokenSelector === 'to') {
      if (token.symbol !== fromToken.symbol) {
        setToToken(token);
      }
    }
    setShowTokenSelector(null);
  };

  return (
    <ScrollView style={styles.container}>
      {/* Header */}
      <View style={styles.header}>
        <Text style={styles.headerTitle}>Swap</Text>
        <TouchableOpacity onPress={() => {}}>
          <Text style={styles.settingsIcon}>⚙️</Text>
        </TouchableOpacity>
      </View>

      {/* Swap Card */}
      <View style={styles.swapCard}>
        {/* From Token */}
        <View style={styles.tokenSection}>
          <Text style={styles.sectionLabel}>From</Text>
          <View style={styles.tokenInputRow}>
            <TouchableOpacity
              style={styles.tokenSelector}
              onPress={() => setShowTokenSelector('from')}
            >
              <Text style={styles.tokenIcon}>{fromToken.icon}</Text>
              <Text style={styles.tokenSymbol}>{fromToken.symbol}</Text>
              <Text style={styles.dropdownIcon}>▼</Text>
            </TouchableOpacity>
            <TextInput
              style={styles.amountInput}
              value={fromAmount}
              onChangeText={setFromAmount}
              placeholder="0.0"
              placeholderTextColor="#64748B"
              keyboardType="decimal-pad"
            />
          </View>
        </View>

        {/* Swap Button */}
        <TouchableOpacity
          style={styles.swapIconButton}
          onPress={swapTokenPositions}
        >
          <Text style={styles.swapIconText}>⇅</Text>
        </TouchableOpacity>

        {/* To Token */}
        <View style={styles.tokenSection}>
          <Text style={styles.sectionLabel}>To (estimated)</Text>
          <View style={styles.tokenInputRow}>
            <TouchableOpacity
              style={styles.tokenSelector}
              onPress={() => setShowTokenSelector('to')}
            >
              <Text style={styles.tokenIcon}>{toToken.icon}</Text>
              <Text style={styles.tokenSymbol}>{toToken.symbol}</Text>
              <Text style={styles.dropdownIcon}>▼</Text>
            </TouchableOpacity>
            <View style={styles.amountDisplay}>
              {isLoadingQuote ? (
                <ActivityIndicator size="small" color="#6366F1" />
              ) : (
                <Text style={styles.amountText}>
                  {toAmount || '0.0'}
                </Text>
              )}
            </View>
          </View>
        </View>

        {/* Exchange Rate */}
        {exchangeRate !== '0' && (
          <View style={styles.rateCard}>
            <Text style={styles.rateLabel}>Exchange Rate</Text>
            <Text style={styles.rateValue}>
              1 {fromToken.symbol} = {exchangeRate} {toToken.symbol}
            </Text>
          </View>
        )}

        {/* Swap Details */}
        {toAmount && (
          <View style={styles.detailsCard}>
            <View style={styles.detailRow}>
              <Text style={styles.detailLabel}>Price Impact</Text>
              <Text
                style={[
                  styles.detailValue,
                  parseFloat(priceImpact) > 3 && styles.detailValueWarning,
                ]}
              >
                {priceImpact}%
              </Text>
            </View>
            <View style={styles.detailRow}>
              <Text style={styles.detailLabel}>Slippage Tolerance</Text>
              <Text style={styles.detailValue}>{slippage}%</Text>
            </View>
            <View style={styles.detailRow}>
              <Text style={styles.detailLabel}>Estimated Gas</Text>
              <Text style={styles.detailValue}>{estimatedGas} ETH</Text>
            </View>
          </View>
        )}

        {/* Swap Button */}
        <TouchableOpacity
          style={[
            styles.swapButton,
            (isSwapping || isLoadingQuote || !toAmount) && styles.swapButtonDisabled,
          ]}
          onPress={handleSwap}
          disabled={isSwapping || isLoadingQuote || !toAmount}
        >
          {isSwapping ? (
            <ActivityIndicator color="#fff" />
          ) : (
            <Text style={styles.swapButtonText}>
              {!fromAmount ? 'Enter amount' : 'Swap'}
            </Text>
          )}
        </TouchableOpacity>
      </View>

      {/* Token Selector Modal */}
      {showTokenSelector && (
        <View style={styles.modalOverlay}>
          <View style={styles.modalContent}>
            <View style={styles.modalHeader}>
              <Text style={styles.modalTitle}>Select Token</Text>
              <TouchableOpacity onPress={() => setShowTokenSelector(null)}>
                <Text style={styles.modalClose}>✕</Text>
              </TouchableOpacity>
            </View>
            {AVAILABLE_TOKENS.map((token) => (
              <TouchableOpacity
                key={token.symbol}
                style={styles.tokenOption}
                onPress={() => selectToken(token)}
              >
                <Text style={styles.tokenOptionIcon}>{token.icon}</Text>
                <View style={styles.tokenOptionInfo}>
                  <Text style={styles.tokenOptionSymbol}>{token.symbol}</Text>
                  <Text style={styles.tokenOptionName}>{token.name}</Text>
                </View>
              </TouchableOpacity>
            ))}
          </View>
        </View>
      )}

      {/* Info Section */}
      <View style={styles.infoSection}>
        <Text style={styles.infoTitle}>Swap Information</Text>
        <Text style={styles.infoText}>
          • Powered by decentralized exchange (DEX) protocols
        </Text>
        <Text style={styles.infoText}>
          • No registration or KYC required
        </Text>
        <Text style={styles.infoText}>
          • You always remain in control of your funds
        </Text>
        <Text style={styles.infoText}>
          • Slippage tolerance can be adjusted in settings
        </Text>
      </View>
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#0F172A',
  },
  header: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    padding: 24,
    paddingTop: 60,
  },
  headerTitle: {
    fontSize: 28,
    fontWeight: 'bold',
    color: '#FFFFFF',
  },
  settingsIcon: {
    fontSize: 20,
  },
  swapCard: {
    backgroundColor: '#1E293B',
    borderRadius: 16,
    padding: 20,
    marginHorizontal: 24,
    marginBottom: 24,
  },
  tokenSection: {
    marginBottom: 12,
  },
  sectionLabel: {
    fontSize: 12,
    color: '#94A3B8',
    marginBottom: 8,
  },
  tokenInputRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 12,
  },
  tokenSelector: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#0F172A',
    borderRadius: 12,
    padding: 12,
    minWidth: 120,
  },
  tokenIcon: {
    fontSize: 24,
    marginRight: 8,
  },
  tokenSymbol: {
    fontSize: 16,
    fontWeight: '600',
    color: '#FFFFFF',
    flex: 1,
  },
  dropdownIcon: {
    fontSize: 10,
    color: '#94A3B8',
  },
  amountInput: {
    flex: 1,
    backgroundColor: '#0F172A',
    borderRadius: 12,
    padding: 12,
    color: '#FFFFFF',
    fontSize: 20,
    textAlign: 'right',
  },
  amountDisplay: {
    flex: 1,
    backgroundColor: '#0F172A',
    borderRadius: 12,
    padding: 12,
    alignItems: 'flex-end',
    justifyContent: 'center',
    minHeight: 48,
  },
  amountText: {
    color: '#FFFFFF',
    fontSize: 20,
  },
  swapIconButton: {
    alignSelf: 'center',
    backgroundColor: '#6366F1',
    width: 40,
    height: 40,
    borderRadius: 20,
    alignItems: 'center',
    justifyContent: 'center',
    marginVertical: 8,
  },
  swapIconText: {
    fontSize: 20,
    color: '#FFFFFF',
  },
  rateCard: {
    backgroundColor: '#0F172A',
    borderRadius: 8,
    padding: 12,
    marginTop: 12,
    alignItems: 'center',
  },
  rateLabel: {
    fontSize: 12,
    color: '#94A3B8',
    marginBottom: 4,
  },
  rateValue: {
    fontSize: 14,
    color: '#FFFFFF',
    fontWeight: '500',
  },
  detailsCard: {
    marginTop: 12,
  },
  detailRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    paddingVertical: 8,
  },
  detailLabel: {
    fontSize: 13,
    color: '#94A3B8',
  },
  detailValue: {
    fontSize: 13,
    color: '#FFFFFF',
    fontWeight: '500',
  },
  detailValueWarning: {
    color: '#F59E0B',
  },
  swapButton: {
    backgroundColor: '#6366F1',
    borderRadius: 12,
    padding: 16,
    alignItems: 'center',
    marginTop: 16,
  },
  swapButtonDisabled: {
    backgroundColor: '#4B5563',
  },
  swapButtonText: {
    color: '#FFFFFF',
    fontSize: 16,
    fontWeight: '600',
  },
  modalOverlay: {
    position: 'absolute',
    top: 0,
    left: 0,
    right: 0,
    bottom: 0,
    backgroundColor: 'rgba(0,0,0,0.7)',
    justifyContent: 'center',
    padding: 24,
  },
  modalContent: {
    backgroundColor: '#1E293B',
    borderRadius: 16,
    padding: 20,
  },
  modalHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 20,
  },
  modalTitle: {
    fontSize: 18,
    fontWeight: '600',
    color: '#FFFFFF',
  },
  modalClose: {
    fontSize: 24,
    color: '#94A3B8',
  },
  tokenOption: {
    flexDirection: 'row',
    alignItems: 'center',
    padding: 16,
    backgroundColor: '#0F172A',
    borderRadius: 12,
    marginBottom: 8,
  },
  tokenOptionIcon: {
    fontSize: 32,
    marginRight: 12,
  },
  tokenOptionInfo: {
    flex: 1,
  },
  tokenOptionSymbol: {
    fontSize: 16,
    fontWeight: '600',
    color: '#FFFFFF',
    marginBottom: 2,
  },
  tokenOptionName: {
    fontSize: 12,
    color: '#94A3B8',
  },
  infoSection: {
    backgroundColor: '#1E293B',
    borderRadius: 16,
    padding: 20,
    marginHorizontal: 24,
    marginBottom: 32,
  },
  infoTitle: {
    fontSize: 16,
    fontWeight: '600',
    color: '#FFFFFF',
    marginBottom: 12,
  },
  infoText: {
    fontSize: 13,
    color: '#CBD5E1',
    marginBottom: 8,
    lineHeight: 18,
  },
});

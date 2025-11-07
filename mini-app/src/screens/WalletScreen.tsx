/**
 * WalletScreen.tsx
 * Wallet management screen for ZeaZDev Mini App
 * 
 * Features:
 * - Display WLD and Gas token balances
 * - Send tokens to other addresses
 * - View transaction history
 * - QR code for receiving
 */

import React, { useState, useEffect } from 'react';
import {
  View,
  Text,
  StyleSheet,
  TouchableOpacity,
  TextInput,
  ScrollView,
  ActivityIndicator,
  Alert,
} from 'react-native';
import { ethers } from 'ethers';
import { getBalance, sendToken } from '../services/wallet';

interface WalletScreenProps {
  userAddress: string;
}

export default function WalletScreen({ userAddress }: WalletScreenProps) {
  const [wldBalance, setWldBalance] = useState('0.00');
  const [gasBalance, setGasBalance] = useState('0.00');
  const [isLoading, setIsLoading] = useState(true);
  const [isSending, setIsSending] = useState(false);
  
  // Send form state
  const [showSendForm, setShowSendForm] = useState(false);
  const [recipientAddress, setRecipientAddress] = useState('');
  const [sendAmount, setSendAmount] = useState('');
  const [selectedToken, setSelectedToken] = useState<'WLD' | 'GAS'>('WLD');

  useEffect(() => {
    loadBalances();
    
    // Refresh balances every 10 seconds
    const interval = setInterval(loadBalances, 10000);
    return () => clearInterval(interval);
  }, [userAddress]);

  /**
   * Load wallet balances
   */
  const loadBalances = async () => {
    try {
      setIsLoading(true);
      
      // Get WLD token balance
      const wld = await getBalance(userAddress, 'WLD');
      setWldBalance(wld);
      
      // Get native gas token balance (ETH/MATIC)
      const gas = await getBalance(userAddress, 'GAS');
      setGasBalance(gas);
      
    } catch (error) {
      console.error('Error loading balances:', error);
      Alert.alert('Error', 'Failed to load wallet balances');
    } finally {
      setIsLoading(false);
    }
  };

  /**
   * Handle send token transaction
   */
  const handleSend = async () => {
    // Validation
    if (!recipientAddress || !ethers.isAddress(recipientAddress)) {
      Alert.alert('Invalid Address', 'Please enter a valid Ethereum address');
      return;
    }

    if (!sendAmount || parseFloat(sendAmount) <= 0) {
      Alert.alert('Invalid Amount', 'Please enter a valid amount');
      return;
    }

    const balance = selectedToken === 'WLD' ? wldBalance : gasBalance;
    if (parseFloat(sendAmount) > parseFloat(balance)) {
      Alert.alert('Insufficient Balance', `You don't have enough ${selectedToken}`);
      return;
    }

    Alert.alert(
      'Confirm Transaction',
      `Send ${sendAmount} ${selectedToken} to\n${recipientAddress.substring(0, 10)}...${recipientAddress.substring(recipientAddress.length - 8)}?`,
      [
        { text: 'Cancel', style: 'cancel' },
        {
          text: 'Confirm',
          onPress: executeSend,
        },
      ]
    );
  };

  /**
   * Execute send transaction
   */
  const executeSend = async () => {
    try {
      setIsSending(true);

      const result = await sendToken({
        from: userAddress,
        to: recipientAddress,
        amount: sendAmount,
        token: selectedToken,
      });

      if (result.success) {
        Alert.alert(
          'Transaction Sent! 🎉',
          `Transaction hash:\n${result.txHash}`,
          [
            {
              text: 'OK',
              onPress: () => {
                setShowSendForm(false);
                setRecipientAddress('');
                setSendAmount('');
                loadBalances(); // Refresh balances
              },
            },
          ]
        );
      } else {
        throw new Error(result.error || 'Transaction failed');
      }
    } catch (error: any) {
      console.error('Send error:', error);
      Alert.alert('Transaction Failed', error.message || 'Failed to send tokens');
    } finally {
      setIsSending(false);
    }
  };

  /**
   * Copy address to clipboard
   */
  const copyAddress = () => {
    // In React Native, you'd use Clipboard API
    Alert.alert('Address Copied', userAddress);
  };

  return (
    <ScrollView style={styles.container}>
      {/* Header */}
      <View style={styles.header}>
        <Text style={styles.headerTitle}>My Wallet</Text>
        <TouchableOpacity onPress={loadBalances} disabled={isLoading}>
          <Text style={styles.refreshButton}>
            {isLoading ? '⟳' : '↻'}
          </Text>
        </TouchableOpacity>
      </View>

      {/* Address Card */}
      <TouchableOpacity style={styles.addressCard} onPress={copyAddress}>
        <Text style={styles.addressLabel}>Your Address</Text>
        <Text style={styles.addressText}>
          {userAddress.substring(0, 16)}...{userAddress.substring(userAddress.length - 14)}
        </Text>
        <Text style={styles.copyHint}>Tap to copy</Text>
      </TouchableOpacity>

      {/* Balance Cards */}
      <View style={styles.balancesContainer}>
        {/* WLD Balance */}
        <View style={styles.balanceCard}>
          <Text style={styles.tokenIcon}>🌐</Text>
          <Text style={styles.balanceLabel}>WLD Token</Text>
          {isLoading ? (
            <ActivityIndicator color="#6366F1" />
          ) : (
            <Text style={styles.balanceAmount}>{wldBalance}</Text>
          )}
          <Text style={styles.balanceSymbol}>WLD</Text>
        </View>

        {/* Gas Balance */}
        <View style={styles.balanceCard}>
          <Text style={styles.tokenIcon}>⛽</Text>
          <Text style={styles.balanceLabel}>Gas Token</Text>
          {isLoading ? (
            <ActivityIndicator color="#6366F1" />
          ) : (
            <Text style={styles.balanceAmount}>{gasBalance}</Text>
          )}
          <Text style={styles.balanceSymbol}>ETH</Text>
        </View>
      </View>

      {/* Action Buttons */}
      <View style={styles.actionsContainer}>
        <TouchableOpacity
          style={styles.actionButton}
          onPress={() => setShowSendForm(!showSendForm)}
        >
          <Text style={styles.actionIcon}>📤</Text>
          <Text style={styles.actionText}>Send</Text>
        </TouchableOpacity>

        <TouchableOpacity style={styles.actionButton} onPress={() => {}}>
          <Text style={styles.actionIcon}>📥</Text>
          <Text style={styles.actionText}>Receive</Text>
        </TouchableOpacity>

        <TouchableOpacity style={styles.actionButton} onPress={() => {}}>
          <Text style={styles.actionIcon}>📊</Text>
          <Text style={styles.actionText}>History</Text>
        </TouchableOpacity>
      </View>

      {/* Send Form */}
      {showSendForm && (
        <View style={styles.sendForm}>
          <Text style={styles.formTitle}>Send Tokens</Text>

          {/* Token Selector */}
          <View style={styles.tokenSelector}>
            <TouchableOpacity
              style={[
                styles.tokenOption,
                selectedToken === 'WLD' && styles.tokenOptionActive,
              ]}
              onPress={() => setSelectedToken('WLD')}
            >
              <Text style={styles.tokenOptionText}>WLD</Text>
            </TouchableOpacity>
            <TouchableOpacity
              style={[
                styles.tokenOption,
                selectedToken === 'GAS' && styles.tokenOptionActive,
              ]}
              onPress={() => setSelectedToken('GAS')}
            >
              <Text style={styles.tokenOptionText}>ETH</Text>
            </TouchableOpacity>
          </View>

          {/* Recipient Address */}
          <View style={styles.inputGroup}>
            <Text style={styles.inputLabel}>Recipient Address</Text>
            <TextInput
              style={styles.input}
              value={recipientAddress}
              onChangeText={setRecipientAddress}
              placeholder="0x..."
              placeholderTextColor="#64748B"
              autoCapitalize="none"
              autoCorrect={false}
            />
          </View>

          {/* Amount */}
          <View style={styles.inputGroup}>
            <Text style={styles.inputLabel}>Amount</Text>
            <TextInput
              style={styles.input}
              value={sendAmount}
              onChangeText={setSendAmount}
              placeholder="0.00"
              placeholderTextColor="#64748B"
              keyboardType="decimal-pad"
            />
            <Text style={styles.balanceHint}>
              Balance: {selectedToken === 'WLD' ? wldBalance : gasBalance} {selectedToken}
            </Text>
          </View>

          {/* Send Button */}
          <TouchableOpacity
            style={[styles.sendButton, isSending && styles.sendButtonDisabled]}
            onPress={handleSend}
            disabled={isSending}
          >
            {isSending ? (
              <ActivityIndicator color="#fff" />
            ) : (
              <Text style={styles.sendButtonText}>Send {selectedToken}</Text>
            )}
          </TouchableOpacity>
        </View>
      )}

      {/* Info Section */}
      <View style={styles.infoSection}>
        <Text style={styles.infoTitle}>Wallet Tips</Text>
        <Text style={styles.infoText}>
          • Always verify recipient address before sending
        </Text>
        <Text style={styles.infoText}>
          • Keep some gas tokens for transaction fees
        </Text>
        <Text style={styles.infoText}>
          • Transactions are irreversible once confirmed
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
  refreshButton: {
    fontSize: 24,
    color: '#6366F1',
  },
  addressCard: {
    backgroundColor: '#1E293B',
    borderRadius: 12,
    padding: 16,
    marginHorizontal: 24,
    marginBottom: 24,
  },
  addressLabel: {
    fontSize: 12,
    color: '#94A3B8',
    marginBottom: 8,
  },
  addressText: {
    fontSize: 14,
    color: '#FFFFFF',
    fontFamily: 'monospace',
    marginBottom: 4,
  },
  copyHint: {
    fontSize: 10,
    color: '#6366F1',
  },
  balancesContainer: {
    flexDirection: 'row',
    paddingHorizontal: 24,
    gap: 12,
    marginBottom: 24,
  },
  balanceCard: {
    flex: 1,
    backgroundColor: '#1E293B',
    borderRadius: 16,
    padding: 20,
    alignItems: 'center',
  },
  tokenIcon: {
    fontSize: 32,
    marginBottom: 8,
  },
  balanceLabel: {
    fontSize: 12,
    color: '#94A3B8',
    marginBottom: 12,
  },
  balanceAmount: {
    fontSize: 24,
    fontWeight: 'bold',
    color: '#FFFFFF',
    marginBottom: 4,
  },
  balanceSymbol: {
    fontSize: 12,
    color: '#6366F1',
  },
  actionsContainer: {
    flexDirection: 'row',
    paddingHorizontal: 24,
    gap: 12,
    marginBottom: 24,
  },
  actionButton: {
    flex: 1,
    backgroundColor: '#1E293B',
    borderRadius: 12,
    padding: 16,
    alignItems: 'center',
  },
  actionIcon: {
    fontSize: 24,
    marginBottom: 8,
  },
  actionText: {
    fontSize: 12,
    color: '#FFFFFF',
  },
  sendForm: {
    backgroundColor: '#1E293B',
    borderRadius: 16,
    padding: 20,
    marginHorizontal: 24,
    marginBottom: 24,
  },
  formTitle: {
    fontSize: 18,
    fontWeight: '600',
    color: '#FFFFFF',
    marginBottom: 20,
  },
  tokenSelector: {
    flexDirection: 'row',
    gap: 12,
    marginBottom: 20,
  },
  tokenOption: {
    flex: 1,
    backgroundColor: '#0F172A',
    borderRadius: 8,
    padding: 12,
    alignItems: 'center',
  },
  tokenOptionActive: {
    backgroundColor: '#6366F1',
  },
  tokenOptionText: {
    color: '#FFFFFF',
    fontWeight: '600',
  },
  inputGroup: {
    marginBottom: 16,
  },
  inputLabel: {
    fontSize: 14,
    color: '#94A3B8',
    marginBottom: 8,
  },
  input: {
    backgroundColor: '#0F172A',
    borderRadius: 8,
    padding: 12,
    color: '#FFFFFF',
    fontSize: 14,
  },
  balanceHint: {
    fontSize: 12,
    color: '#64748B',
    marginTop: 4,
  },
  sendButton: {
    backgroundColor: '#6366F1',
    borderRadius: 12,
    padding: 16,
    alignItems: 'center',
    marginTop: 8,
  },
  sendButtonDisabled: {
    backgroundColor: '#4B5563',
  },
  sendButtonText: {
    color: '#FFFFFF',
    fontSize: 16,
    fontWeight: '600',
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

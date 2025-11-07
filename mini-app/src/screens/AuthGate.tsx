/**
 * AuthGate.tsx
 * World ID Authentication Gate - First screen requiring World ID verification
 * 
 * This component handles Zero-Knowledge Proof (ZKP) verification using World ID
 * Users must verify their humanity before accessing any financial features
 */

import React, { useState, useEffect } from 'react';
import {
  View,
  Text,
  StyleSheet,
  TouchableOpacity,
  ActivityIndicator,
  Alert,
} from 'react-native';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { IDKit, ISuccessResult } from '@worldcoin/idkit-core';
import { verifyProof } from '../services/worldid';
import { ethers } from 'ethers';

interface AuthGateProps {
  onVerified: (address: string, nullifierHash: string) => void;
}

export default function AuthGate({ onVerified }: AuthGateProps) {
  const [isLoading, setIsLoading] = useState(false);
  const [isVerifying, setIsVerifying] = useState(false);
  const [userAddress, setUserAddress] = useState<string | null>(null);

  useEffect(() => {
    checkExistingAuth();
  }, []);

  /**
   * Check if user is already authenticated
   */
  const checkExistingAuth = async () => {
    try {
      const storedAddress = await AsyncStorage.getItem('userAddress');
      const storedNullifier = await AsyncStorage.getItem('nullifierHash');
      
      if (storedAddress && storedNullifier) {
        setUserAddress(storedAddress);
        onVerified(storedAddress, storedNullifier);
      }
    } catch (error) {
      console.error('Error checking auth:', error);
    }
  };

  /**
   * Handle World ID verification success
   */
  const handleVerifySuccess = async (result: ISuccessResult) => {
    try {
      setIsVerifying(true);

      // Extract proof data from World ID
      const { merkle_root, nullifier_hash, proof } = result;
      
      // Generate or get user's Ethereum address
      // In production, this should be from a secure wallet
      let address = userAddress;
      if (!address) {
        const wallet = ethers.Wallet.createRandom();
        address = wallet.address;
        await AsyncStorage.setItem('userAddress', address);
        // Store private key securely (in production, use secure enclave)
        await AsyncStorage.setItem('privateKey', wallet.privateKey);
      }

      console.log('Verifying proof with backend...');
      console.log('Address:', address);
      console.log('Merkle Root:', merkle_root);
      console.log('Nullifier Hash:', nullifier_hash);

      // Send proof to backend for verification
      const verificationResult = await verifyProof({
        signal: address,
        merkle_root,
        nullifier_hash,
        proof,
      });

      if (verificationResult.success) {
        // Store authentication data
        await AsyncStorage.setItem('nullifierHash', nullifier_hash);
        await AsyncStorage.setItem('isVerified', 'true');
        await AsyncStorage.setItem('verifiedAt', new Date().toISOString());

        Alert.alert(
          'Verification Successful! 🎉',
          'You can now access all features of ZeaZDev Mini App',
          [
            {
              text: 'Continue',
              onPress: () => onVerified(address!, nullifier_hash),
            },
          ]
        );
      } else {
        throw new Error(verificationResult.message || 'Verification failed');
      }
    } catch (error: any) {
      console.error('Verification error:', error);
      Alert.alert(
        'Verification Failed',
        error.message || 'Failed to verify your World ID. Please try again.',
        [{ text: 'OK' }]
      );
    } finally {
      setIsVerifying(false);
    }
  };

  /**
   * Handle verification failure
   */
  const handleVerifyFailure = (error: Error) => {
    console.error('World ID verification failed:', error);
    Alert.alert(
      'Verification Failed',
      'World ID verification was not successful. Please try again.',
      [{ text: 'OK' }]
    );
  };

  /**
   * Trigger World ID verification
   */
  const startVerification = () => {
    setIsLoading(true);
    // IDKit will open World App for verification
    // The actual implementation depends on @worldcoin/idkit-core version
  };

  return (
    <View style={styles.container}>
      <View style={styles.content}>
        {/* Header */}
        <View style={styles.header}>
          <Text style={styles.logo}>🌍</Text>
          <Text style={styles.title}>Welcome to ZeaZDev</Text>
          <Text style={styles.subtitle}>
            World ID Verified Mini App
          </Text>
        </View>

        {/* Info Section */}
        <View style={styles.infoBox}>
          <Text style={styles.infoTitle}>Why World ID?</Text>
          <Text style={styles.infoText}>
            • Proof of Personhood - Verify you're a unique human
          </Text>
          <Text style={styles.infoText}>
            • Privacy First - No personal data collected
          </Text>
          <Text style={styles.infoText}>
            • Sybil Resistant - Prevent multiple accounts
          </Text>
          <Text style={styles.infoText}>
            • Secure Rewards - Access exclusive features
          </Text>
        </View>

        {/* Verification Button */}
        <TouchableOpacity
          style={[styles.button, (isLoading || isVerifying) && styles.buttonDisabled]}
          onPress={startVerification}
          disabled={isLoading || isVerifying}
        >
          {isVerifying ? (
            <>
              <ActivityIndicator color="#fff" style={{ marginRight: 10 }} />
              <Text style={styles.buttonText}>Verifying...</Text>
            </>
          ) : (
            <Text style={styles.buttonText}>
              Verify with World ID
            </Text>
          )}
        </TouchableOpacity>

        {/* IDKit Component (simplified for demonstration) */}
        {isLoading && (
          <IDKit
            app_id={process.env.WORLD_APP_ID || ''}
            action={process.env.WORLD_ACTION_ID || ''}
            onSuccess={handleVerifySuccess}
            onError={handleVerifyFailure}
            signal={userAddress || ''}
          />
        )}

        {/* Footer */}
        <View style={styles.footer}>
          <Text style={styles.footerText}>
            By continuing, you agree to our Terms of Service
          </Text>
          <Text style={styles.footerSubtext}>
            ZeaZDev Mini App v1.0
          </Text>
        </View>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#0F172A',
  },
  content: {
    flex: 1,
    padding: 24,
    justifyContent: 'space-between',
  },
  header: {
    alignItems: 'center',
    marginTop: 60,
  },
  logo: {
    fontSize: 64,
    marginBottom: 20,
  },
  title: {
    fontSize: 28,
    fontWeight: 'bold',
    color: '#FFFFFF',
    marginBottom: 8,
  },
  subtitle: {
    fontSize: 16,
    color: '#94A3B8',
  },
  infoBox: {
    backgroundColor: '#1E293B',
    borderRadius: 16,
    padding: 20,
    marginVertical: 32,
  },
  infoTitle: {
    fontSize: 18,
    fontWeight: '600',
    color: '#FFFFFF',
    marginBottom: 16,
  },
  infoText: {
    fontSize: 14,
    color: '#CBD5E1',
    marginBottom: 12,
    lineHeight: 20,
  },
  button: {
    backgroundColor: '#6366F1',
    borderRadius: 12,
    padding: 18,
    alignItems: 'center',
    flexDirection: 'row',
    justifyContent: 'center',
    shadowColor: '#6366F1',
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.3,
    shadowRadius: 8,
    elevation: 5,
  },
  buttonDisabled: {
    backgroundColor: '#4B5563',
    shadowOpacity: 0,
  },
  buttonText: {
    color: '#FFFFFF',
    fontSize: 16,
    fontWeight: '600',
  },
  footer: {
    alignItems: 'center',
    marginTop: 24,
  },
  footerText: {
    fontSize: 12,
    color: '#64748B',
    marginBottom: 8,
  },
  footerSubtext: {
    fontSize: 10,
    color: '#475569',
  },
});

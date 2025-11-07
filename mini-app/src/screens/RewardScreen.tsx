/**
 * RewardScreen.tsx
 * Daily check-in and airdrop claim screen
 * 
 * Features:
 * - Daily check-in for rewards
 * - Airdrop claim (one-time)
 * - Check-in streak tracking
 * - Reward history
 */

import React, { useState, useEffect } from 'react';
import {
  View,
  Text,
  StyleSheet,
  TouchableOpacity,
  ActivityIndicator,
  Alert,
  ScrollView,
} from 'react';
import { claimAirdrop, dailyCheckIn, getCheckInStatus } from '../services/rewards';

interface RewardScreenProps {
  userAddress: string;
  nullifierHash: string;
}

export default function RewardScreen({ userAddress, nullifierHash }: RewardScreenProps) {
  const [isLoadingStatus, setIsLoadingStatus] = useState(true);
  const [isClaimingAirdrop, setIsClaimingAirdrop] = useState(false);
  const [isCheckingIn, setIsCheckingIn] = useState(false);
  
  // User status
  const [hasClaimedAirdrop, setHasClaimedAirdrop] = useState(false);
  const [canCheckIn, setCanCheckIn] = useState(false);
  const [timeUntilNextCheckIn, setTimeUntilNextCheckIn] = useState(0);
  const [checkInStreak, setCheckInStreak] = useState(0);
  const [totalRewards, setTotalRewards] = useState('0');
  
  useEffect(() => {
    loadUserStatus();
    
    // Update countdown every second
    const interval = setInterval(() => {
      if (timeUntilNextCheckIn > 0) {
        setTimeUntilNextCheckIn(prev => Math.max(0, prev - 1));
      }
    }, 1000);
    
    return () => clearInterval(interval);
  }, [userAddress]);

  /**
   * Load user's reward status
   */
  const loadUserStatus = async () => {
    try {
      setIsLoadingStatus(true);
      
      const status = await getCheckInStatus(userAddress);
      
      setHasClaimedAirdrop(status.hasClaimedAirdrop);
      setCanCheckIn(status.canCheckIn);
      setTimeUntilNextCheckIn(status.timeUntilNext);
      setCheckInStreak(status.streak);
      setTotalRewards(status.totalRewards);
      
    } catch (error) {
      console.error('Error loading status:', error);
      Alert.alert('Error', 'Failed to load reward status');
    } finally {
      setIsLoadingStatus(false);
    }
  };

  /**
   * Handle airdrop claim
   */
  const handleClaimAirdrop = async () => {
    Alert.alert(
      'Claim Airdrop',
      'This is a one-time reward. Are you sure you want to claim now?',
      [
        { text: 'Cancel', style: 'cancel' },
        {
          text: 'Claim',
          onPress: executeClaimAirdrop,
        },
      ]
    );
  };

  const executeClaimAirdrop = async () => {
    try {
      setIsClaimingAirdrop(true);
      
      const result = await claimAirdrop(userAddress, nullifierHash);
      
      if (result.success) {
        Alert.alert(
          'Airdrop Claimed! 🎉',
          `You received ${result.amount} ZEA tokens!\nTransaction: ${result.txHash}`,
          [
            {
              text: 'OK',
              onPress: loadUserStatus,
            },
          ]
        );
      } else {
        throw new Error(result.error || 'Claim failed');
      }
    } catch (error: any) {
      console.error('Airdrop claim error:', error);
      Alert.alert('Claim Failed', error.message || 'Failed to claim airdrop');
    } finally {
      setIsClaimingAirdrop(false);
    }
  };

  /**
   * Handle daily check-in
   */
  const handleCheckIn = async () => {
    try {
      setIsCheckingIn(true);
      
      const result = await dailyCheckIn(userAddress, nullifierHash);
      
      if (result.success) {
        Alert.alert(
          'Check-in Successful! ✅',
          `You earned ${result.amount} ZEA tokens!\nStreak: ${result.streak} days`,
          [
            {
              text: 'OK',
              onPress: loadUserStatus,
            },
          ]
        );
      } else {
        throw new Error(result.error || 'Check-in failed');
      }
    } catch (error: any) {
      console.error('Check-in error:', error);
      Alert.alert('Check-in Failed', error.message || 'Failed to check in');
    } finally {
      setIsCheckingIn(false);
    }
  };

  /**
   * Format time until next check-in
   */
  const formatTimeRemaining = (seconds: number): string => {
    if (seconds <= 0) return 'Available now!';
    
    const hours = Math.floor(seconds / 3600);
    const minutes = Math.floor((seconds % 3600) / 60);
    const secs = seconds % 60;
    
    return `${hours}h ${minutes}m ${secs}s`;
  };

  if (isLoadingStatus) {
    return (
      <View style={styles.loadingContainer}>
        <ActivityIndicator size="large" color="#6366F1" />
        <Text style={styles.loadingText}>Loading rewards...</Text>
      </View>
    );
  }

  return (
    <ScrollView style={styles.container}>
      {/* Header */}
      <View style={styles.header}>
        <Text style={styles.headerTitle}>Rewards</Text>
        <TouchableOpacity onPress={loadUserStatus}>
          <Text style={styles.refreshButton}>↻</Text>
        </TouchableOpacity>
      </View>

      {/* Total Rewards Card */}
      <View style={styles.totalCard}>
        <Text style={styles.totalLabel}>Total Rewards Earned</Text>
        <Text style={styles.totalAmount}>{totalRewards}</Text>
        <Text style={styles.totalSymbol}>ZEA Tokens</Text>
      </View>

      {/* Streak Card */}
      <View style={styles.streakCard}>
        <Text style={styles.streakIcon}>🔥</Text>
        <View style={styles.streakInfo}>
          <Text style={styles.streakLabel}>Current Streak</Text>
          <Text style={styles.streakDays}>{checkInStreak} days</Text>
        </View>
      </View>

      {/* Airdrop Section */}
      {!hasClaimedAirdrop && (
        <View style={styles.airdropSection}>
          <View style={styles.sectionHeader}>
            <Text style={styles.sectionIcon}>🎁</Text>
            <Text style={styles.sectionTitle}>Welcome Airdrop</Text>
          </View>
          <Text style={styles.sectionDescription}>
            Claim your one-time welcome bonus! This reward is available to all verified users.
          </Text>
          <TouchableOpacity
            style={[styles.claimButton, isClaimingAirdrop && styles.claimButtonDisabled]}
            onPress={handleClaimAirdrop}
            disabled={isClaimingAirdrop}
          >
            {isClaimingAirdrop ? (
              <ActivityIndicator color="#fff" />
            ) : (
              <Text style={styles.claimButtonText}>Claim Airdrop</Text>
            )}
          </TouchableOpacity>
        </View>
      )}

      {/* Daily Check-in Section */}
      <View style={styles.checkInSection}>
        <View style={styles.sectionHeader}>
          <Text style={styles.sectionIcon}>📅</Text>
          <Text style={styles.sectionTitle}>Daily Check-in</Text>
        </View>
        <Text style={styles.sectionDescription}>
          Check in every day to earn rewards and build your streak!
        </Text>
        
        {canCheckIn ? (
          <TouchableOpacity
            style={[styles.checkInButton, isCheckingIn && styles.checkInButtonDisabled]}
            onPress={handleCheckIn}
            disabled={isCheckingIn}
          >
            {isCheckingIn ? (
              <ActivityIndicator color="#fff" />
            ) : (
              <Text style={styles.checkInButtonText}>Check In Now ✨</Text>
            )}
          </TouchableOpacity>
        ) : (
          <View style={styles.cooldownCard}>
            <Text style={styles.cooldownLabel}>Next check-in available in:</Text>
            <Text style={styles.cooldownTime}>
              {formatTimeRemaining(timeUntilNextCheckIn)}
            </Text>
          </View>
        )}
      </View>

      {/* Rewards Info */}
      <View style={styles.infoSection}>
        <Text style={styles.infoTitle}>How Rewards Work</Text>
        <View style={styles.infoItem}>
          <Text style={styles.infoBullet}>•</Text>
          <Text style={styles.infoText}>
            Check in daily to earn ZEA tokens
          </Text>
        </View>
        <View style={styles.infoItem}>
          <Text style={styles.infoBullet}>•</Text>
          <Text style={styles.infoText}>
            Build streaks for bonus rewards (coming soon)
          </Text>
        </View>
        <View style={styles.infoItem}>
          <Text style={styles.infoBullet}>•</Text>
          <Text style={styles.infoText}>
            All rewards are instantly sent to your wallet
          </Text>
        </View>
        <View style={styles.infoItem}>
          <Text style={styles.infoBullet}>•</Text>
          <Text style={styles.infoText}>
            World ID verification required for all claims
          </Text>
        </View>
      </View>
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#0F172A',
  },
  loadingContainer: {
    flex: 1,
    backgroundColor: '#0F172A',
    justifyContent: 'center',
    alignItems: 'center',
  },
  loadingText: {
    color: '#94A3B8',
    marginTop: 16,
    fontSize: 14,
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
  totalCard: {
    backgroundColor: '#6366F1',
    borderRadius: 16,
    padding: 24,
    marginHorizontal: 24,
    marginBottom: 16,
    alignItems: 'center',
  },
  totalLabel: {
    fontSize: 14,
    color: '#E0E7FF',
    marginBottom: 8,
  },
  totalAmount: {
    fontSize: 36,
    fontWeight: 'bold',
    color: '#FFFFFF',
    marginBottom: 4,
  },
  totalSymbol: {
    fontSize: 14,
    color: '#E0E7FF',
  },
  streakCard: {
    backgroundColor: '#1E293B',
    borderRadius: 12,
    padding: 16,
    marginHorizontal: 24,
    marginBottom: 24,
    flexDirection: 'row',
    alignItems: 'center',
  },
  streakIcon: {
    fontSize: 32,
    marginRight: 16,
  },
  streakInfo: {
    flex: 1,
  },
  streakLabel: {
    fontSize: 14,
    color: '#94A3B8',
    marginBottom: 4,
  },
  streakDays: {
    fontSize: 20,
    fontWeight: 'bold',
    color: '#FFFFFF',
  },
  airdropSection: {
    backgroundColor: '#1E293B',
    borderRadius: 16,
    padding: 20,
    marginHorizontal: 24,
    marginBottom: 16,
  },
  checkInSection: {
    backgroundColor: '#1E293B',
    borderRadius: 16,
    padding: 20,
    marginHorizontal: 24,
    marginBottom: 24,
  },
  sectionHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: 12,
  },
  sectionIcon: {
    fontSize: 24,
    marginRight: 8,
  },
  sectionTitle: {
    fontSize: 18,
    fontWeight: '600',
    color: '#FFFFFF',
  },
  sectionDescription: {
    fontSize: 14,
    color: '#94A3B8',
    lineHeight: 20,
    marginBottom: 16,
  },
  claimButton: {
    backgroundColor: '#10B981',
    borderRadius: 12,
    padding: 16,
    alignItems: 'center',
  },
  claimButtonDisabled: {
    backgroundColor: '#4B5563',
  },
  claimButtonText: {
    color: '#FFFFFF',
    fontSize: 16,
    fontWeight: '600',
  },
  checkInButton: {
    backgroundColor: '#6366F1',
    borderRadius: 12,
    padding: 16,
    alignItems: 'center',
  },
  checkInButtonDisabled: {
    backgroundColor: '#4B5563',
  },
  checkInButtonText: {
    color: '#FFFFFF',
    fontSize: 16,
    fontWeight: '600',
  },
  cooldownCard: {
    backgroundColor: '#0F172A',
    borderRadius: 12,
    padding: 16,
    alignItems: 'center',
  },
  cooldownLabel: {
    fontSize: 14,
    color: '#94A3B8',
    marginBottom: 8,
  },
  cooldownTime: {
    fontSize: 18,
    fontWeight: '600',
    color: '#6366F1',
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
    marginBottom: 16,
  },
  infoItem: {
    flexDirection: 'row',
    marginBottom: 12,
  },
  infoBullet: {
    color: '#6366F1',
    marginRight: 8,
    fontSize: 16,
  },
  infoText: {
    flex: 1,
    fontSize: 13,
    color: '#CBD5E1',
    lineHeight: 18,
  },
});

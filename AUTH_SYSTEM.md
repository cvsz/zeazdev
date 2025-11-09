/**
 * ============================================================================
 * ZeaZDev - Full Omega Ultimate DevOps Professional Enterprises
 * ============================================================================
 * 
 * Project: ZeaZDev Authentication & Authorization System
 * File: AUTH_SYSTEM.md
 * Version: 1.0.0
 * 
 * Developer: PHIPHAT PHOEMSUK (ZeaZDev)
 * Email: admin@zeaz.dev
 * Website: https://app.zeaz.dev
 * GitHub: https://github.com/ZeaZDev
 * 
 * Description:
 * Comprehensive authentication and authorization documentation including
 * wallet-based auth, World ID ZKP verification, JWT, OAuth, and RBAC.
 * 
 * License: MIT
 * Copyright (c) 2025 PHIPHAT PHOEMSUK
 * 
 * Last Updated: 2025-01-09
 * ============================================================================
 */

# 🔐 ZeaZDev Authentication & Authorization System

## 📋 Table of Contents
1. [Authentication Overview](#authentication-overview)
2. [Wallet-Based Authentication](#wallet-based-authentication)
3. [World ID ZKP Verification](#world-id-zkp-verification)
4. [Session Management](#session-management)
5. [Authorization & RBAC](#authorization--rbac)
6. [Multi-Factor Authentication](#multi-factor-authentication)
7. [KYC/AML Integration](#kycaml-integration)
8. [Security Best Practices](#security-best-practices)
9. [API Authentication](#api-authentication)

---

## 🎯 Authentication Overview

### Multi-Layer Auth Strategy

```
┌─────────────────────────────────────────────────────────┐
│                   Authentication Layers                 │
├─────────────────────────────────────────────────────────┤
│ Layer 1: Wallet Connection (MetaMask, WalletConnect)   │
│          ↓                                              │
│ Layer 2: Signature Verification (SIWE - EIP-4361)      │
│          ↓                                              │
│ Layer 3: World ID ZKP Verification (Optional)          │
│          ↓                                              │
│ Layer 4: Session Token (JWT)                           │
│          ↓                                              │
│ Layer 5: 2FA (Optional - TOTP/SMS)                     │
│          ↓                                              │
│ Layer 6: KYC Verification (Tier-based)                 │
└─────────────────────────────────────────────────────────┘
```

### Supported Auth Methods

| Method | Use Case | Security Level | Required |
|--------|----------|----------------|----------|
| Wallet Signature | Primary login | High | ✅ |
| World ID ZKP | Sybil resistance | Very High | ❌ |
| Email/Password | Alternative login | Medium | ❌ |
| OAuth2 (Google, Apple) | Quick signup | Medium | ❌ |
| 2FA (TOTP) | Additional security | High | ❌ |
| KYC | Compliance | High | Tier-based |

---

## 💳 Wallet-Based Authentication

### Sign-In with Ethereum (SIWE) - EIP-4361

**Flow Diagram**:
```
User                    Frontend                Backend              Database
  │                        │                        │                    │
  │ 1. Connect Wallet      │                        │                    │
  ├───────────────────────>│                        │                    │
  │                        │ 2. Request Nonce       │                    │
  │                        ├───────────────────────>│                    │
  │                        │                        │ 3. Generate Nonce  │
  │                        │                        ├───────────────────>│
  │                        │ 4. Return Nonce        │                    │
  │                        │<───────────────────────┤                    │
  │ 5. Sign Message        │                        │                    │
  │<───────────────────────┤                        │                    │
  │ 6. Return Signature    │                        │                    │
  ├───────────────────────>│                        │                    │
  │                        │ 7. Submit Signature    │                    │
  │                        ├───────────────────────>│                    │
  │                        │                        │ 8. Verify Signature│
  │                        │                        │ 9. Create Session  │
  │                        │                        ├───────────────────>│
  │                        │ 10. Return JWT         │                    │
  │                        │<───────────────────────┤                    │
  │ 11. Authenticated      │                        │                    │
  │<───────────────────────┤                        │                    │
```

### Implementation

#### Frontend (React/TypeScript)
```typescript
import { ethers } from 'ethers';
import { SiweMessage } from 'siwe';

// 1. Connect wallet
async function connectWallet() {
  const provider = new ethers.BrowserProvider(window.ethereum);
  const signer = await provider.getSigner();
  const address = await signer.getAddress();
  return { provider, signer, address };
}

// 2. Request nonce from backend
async function getNonce(address: string): Promise<string> {
  const response = await fetch('/api/auth/nonce', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ address })
  });
  const { nonce } = await response.json();
  return nonce;
}

// 3. Create and sign SIWE message
async function signInWithEthereum(
  address: string, 
  signer: ethers.Signer
): Promise<string> {
  const nonce = await getNonce(address);
  
  const message = new SiweMessage({
    domain: window.location.host,
    address: address,
    statement: 'Sign in to ZeaZDev',
    uri: window.location.origin,
    version: '1',
    chainId: await signer.getChainId(),
    nonce: nonce,
    issuedAt: new Date().toISOString(),
  });
  
  const messageString = message.prepareMessage();
  const signature = await signer.signMessage(messageString);
  
  return signature;
}

// 4. Verify and get token
async function authenticate(
  message: SiweMessage, 
  signature: string
): Promise<string> {
  const response = await fetch('/api/auth/verify', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ message, signature })
  });
  
  const { token } = await response.json();
  return token;
}

// Complete flow
async function login() {
  const { signer, address } = await connectWallet();
  const signature = await signInWithEthereum(address, signer);
  const message = new SiweMessage({ ... }); // Same message as signed
  const token = await authenticate(message, signature);
  
  // Store token
  localStorage.setItem('auth_token', token);
  
  return token;
}
```

#### Backend (Node.js/Express)
```typescript
import { ethers } from 'ethers';
import { SiweMessage } from 'siwe';
import jwt from 'jsonwebtoken';
import { randomBytes } from 'crypto';

// Store nonces (use Redis in production)
const nonces = new Map<string, { nonce: string; expires: number }>();

// 1. Generate nonce
app.post('/api/auth/nonce', async (req, res) => {
  const { address } = req.body;
  
  // Validate address
  if (!ethers.isAddress(address)) {
    return res.status(400).json({ error: 'Invalid address' });
  }
  
  // Generate nonce
  const nonce = randomBytes(32).toString('hex');
  const expires = Date.now() + 5 * 60 * 1000; // 5 minutes
  
  // Store nonce
  nonces.set(address.toLowerCase(), { nonce, expires });
  
  res.json({ nonce });
});

// 2. Verify signature
app.post('/api/auth/verify', async (req, res) => {
  const { message, signature } = req.body;
  
  try {
    // Parse SIWE message
    const siweMessage = new SiweMessage(message);
    const address = siweMessage.address.toLowerCase();
    
    // Verify nonce
    const nonceData = nonces.get(address);
    if (!nonceData || nonceData.nonce !== siweMessage.nonce) {
      return res.status(401).json({ error: 'Invalid nonce' });
    }
    
    // Check expiry
    if (Date.now() > nonceData.expires) {
      return res.status(401).json({ error: 'Nonce expired' });
    }
    
    // Verify signature
    await siweMessage.verify({ signature });
    
    // Delete used nonce
    nonces.delete(address);
    
    // Find or create user
    let user = await db.users.findOne({ wallet_address: address });
    if (!user) {
      user = await db.users.create({
        wallet_address: address,
        created_at: new Date()
      });
    }
    
    // Update last login
    await db.users.update(user.id, { last_login_at: new Date() });
    
    // Generate JWT
    const token = jwt.sign(
      { 
        userId: user.id,
        address: address,
        worldIdVerified: user.world_id_verified
      },
      process.env.JWT_SECRET!,
      { expiresIn: '7d' }
    );
    
    res.json({ 
      token,
      user: {
        id: user.id,
        address: user.wallet_address,
        worldIdVerified: user.world_id_verified
      }
    });
    
  } catch (error) {
    console.error('Verification error:', error);
    res.status(401).json({ error: 'Verification failed' });
  }
});

// Middleware: Verify JWT
export const authenticateJWT = (req, res, next) => {
  const authHeader = req.headers.authorization;
  
  if (!authHeader?.startsWith('Bearer ')) {
    return res.status(401).json({ error: 'No token provided' });
  }
  
  const token = authHeader.substring(7);
  
  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET!);
    req.user = decoded;
    next();
  } catch (error) {
    return res.status(401).json({ error: 'Invalid token' });
  }
};
```

---

## 🌍 World ID ZKP Verification

### Zero-Knowledge Proof Authentication

**Purpose**: Prove user is a unique human without revealing identity

**Flow**:
```
User Device          Frontend          Backend           Smart Contract
     │                  │                 │                     │
     │ 1. Click Verify  │                 │                     │
     ├─────────────────>│                 │                     │
     │                  │ 2. Open IDKit   │                     │
     │<─────────────────┤                 │                     │
     │ 3. Scan Orb      │                 │                     │
     │ (World App)      │                 │                     │
     │ 4. Generate ZKP  │                 │                     │
     ├─────────────────>│                 │                     │
     │                  │ 5. Send Proof   │                     │
     │                  ├────────────────>│                     │
     │                  │                 │ 6. Verify w/ API    │
     │                  │                 │ (World ID API)      │
     │                  │                 │ 7. Call Contract    │
     │                  │                 ├────────────────────>│
     │                  │                 │                     │
     │                  │                 │ 8. Verify on-chain  │
     │                  │                 │ 9. Store nullifier  │
     │                  │                 │<────────────────────┤
     │                  │ 10. Success     │                     │
     │                  │<────────────────┤                     │
     │ 11. Verified ✓   │                 │                     │
     │<─────────────────┤                 │                     │
```

### Implementation

#### Frontend (World ID Integration)
```typescript
import { IDKitWidget, VerificationLevel } from '@worldcoin/idkit';

function WorldIDVerification() {
  const handleVerify = async (proof: any) => {
    // Send proof to backend
    const response = await fetch('/api/worldid/verify', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${token}`
      },
      body: JSON.stringify({ proof })
    });
    
    const result = await response.json();
    
    if (result.success) {
      console.log('World ID verified!');
      // Update UI, grant access to features
    }
  };
  
  return (
    <IDKitWidget
      app_id={process.env.NEXT_PUBLIC_WORLD_APP_ID}
      action="verify-humanity"
      verification_level={VerificationLevel.Orb}
      handleVerify={handleVerify}
      onSuccess={() => console.log('Success')}
    >
      {({ open }) => (
        <button onClick={open}>
          Verify with World ID
        </button>
      )}
    </IDKitWidget>
  );
}
```

#### Backend (Verification Service)
```typescript
import { ethers } from 'ethers';

interface WorldIDProof {
  merkle_root: string;
  nullifier_hash: string;
  proof: string;
  verification_level: string;
}

app.post('/api/worldid/verify', authenticateJWT, async (req, res) => {
  const { proof } = req.body;
  const userId = req.user.userId;
  
  try {
    // 1. Verify proof with World ID API
    const verifyResponse = await fetch(
      `https://developer.worldcoin.org/api/v1/verify/${process.env.WORLD_APP_ID}`,
      {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          ...proof,
          action: 'verify-humanity',
          signal: userId
        })
      }
    );
    
    const verifyResult = await verifyResponse.json();
    
    if (!verifyResult.success) {
      return res.status(400).json({ error: 'Proof verification failed' });
    }
    
    // 2. Check if nullifier already used
    const existingUser = await db.users.findOne({
      world_id_hash: proof.nullifier_hash
    });
    
    if (existingUser && existingUser.id !== userId) {
      return res.status(400).json({ 
        error: 'This World ID is already registered' 
      });
    }
    
    // 3. Call smart contract for on-chain verification
    const provider = new ethers.JsonRpcProvider(process.env.RPC_URL);
    const relayer = new ethers.Wallet(process.env.RELAYER_PRIVATE_KEY!, provider);
    const contract = new ethers.Contract(
      process.env.WORLD_ID_REWARDS_CONTRACT!,
      REWARDS_ABI,
      relayer
    );
    
    // Submit verification on-chain
    const tx = await contract.verifyAndRegister(
      proof.merkle_root,
      proof.nullifier_hash,
      proof.proof
    );
    
    await tx.wait();
    
    // 4. Update user in database
    await db.users.update(userId, {
      world_id_hash: proof.nullifier_hash,
      world_id_verified: true,
      world_id_verified_at: new Date()
    });
    
    // 5. Grant welcome airdrop eligibility
    await db.rewards.create({
      user_id: userId,
      reward_type: 'airdrop',
      amount: '1000',
      token_symbol: 'ZEA',
      claimed: false
    });
    
    res.json({ 
      success: true,
      verified: true,
      airdrop_eligible: true
    });
    
  } catch (error) {
    console.error('World ID verification error:', error);
    res.status(500).json({ error: 'Verification failed' });
  }
});
```

---

## 🔑 Session Management

### JWT Token Structure

```typescript
interface JWTPayload {
  userId: string;           // User ID
  address: string;          // Wallet address
  worldIdVerified: boolean; // World ID status
  kycLevel: number;         // KYC tier (0-3)
  roles: string[];          // User roles
  iat: number;              // Issued at
  exp: number;              // Expiry
}
```

### Token Types

| Token Type | Purpose | Expiry | Storage |
|------------|---------|--------|---------|
| Access Token | API authentication | 15 minutes | Memory/State |
| Refresh Token | Renew access token | 7 days | HttpOnly cookie |
| Remember Me Token | Long-term session | 30 days | Encrypted cookie |

### Refresh Token Flow

```typescript
// Generate token pair
function generateTokens(userId: string, data: any) {
  const accessToken = jwt.sign(
    { userId, ...data },
    process.env.JWT_SECRET!,
    { expiresIn: '15m' }
  );
  
  const refreshToken = jwt.sign(
    { userId, type: 'refresh' },
    process.env.JWT_REFRESH_SECRET!,
    { expiresIn: '7d' }
  );
  
  return { accessToken, refreshToken };
}

// Refresh endpoint
app.post('/api/auth/refresh', async (req, res) => {
  const { refreshToken } = req.cookies;
  
  if (!refreshToken) {
    return res.status(401).json({ error: 'No refresh token' });
  }
  
  try {
    const decoded = jwt.verify(
      refreshToken, 
      process.env.JWT_REFRESH_SECRET!
    );
    
    // Generate new access token
    const user = await db.users.findById(decoded.userId);
    const { accessToken } = generateTokens(user.id, {
      address: user.wallet_address,
      worldIdVerified: user.world_id_verified,
      kycLevel: user.kyc_level
    });
    
    res.json({ accessToken });
    
  } catch (error) {
    res.status(401).json({ error: 'Invalid refresh token' });
  }
});
```

### Session Storage

**Redis Session Store**:
```typescript
import Redis from 'ioredis';
import session from 'express-session';
import RedisStore from 'connect-redis';

const redis = new Redis(process.env.REDIS_URL);

app.use(session({
  store: new RedisStore({ client: redis }),
  secret: process.env.SESSION_SECRET!,
  resave: false,
  saveUninitialized: false,
  cookie: {
    secure: process.env.NODE_ENV === 'production',
    httpOnly: true,
    maxAge: 7 * 24 * 60 * 60 * 1000, // 7 days
    sameSite: 'strict'
  }
}));
```

---

## 🛡️ Authorization & RBAC

### Role-Based Access Control (RBAC)

#### Roles Hierarchy
```
┌─────────────────────────────────────┐
│           Role Hierarchy            │
├─────────────────────────────────────┤
│ Super Admin (All permissions)       │
│    ↓                                │
│ Admin (Platform management)         │
│    ↓                                │
│ Moderator (User management)         │
│    ↓                                │
│ VIP User (Premium features)         │
│    ↓                                │
│ Verified User (Basic + verified)    │
│    ↓                                │
│ Basic User (Limited access)         │
└─────────────────────────────────────┘
```

#### Permission Matrix

| Feature | Basic | Verified | VIP | Moderator | Admin | Super Admin |
|---------|-------|----------|-----|-----------|-------|-------------|
| View balance | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Send tokens | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Swap tokens | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Daily check-in | ❌ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Claim airdrop | ❌ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Staking | ❌ | ✅ | ✅ | ✅ | ✅ | ✅ |
| High-limit withdrawals | ❌ | ❌ | ✅ | ✅ | ✅ | ✅ |
| Premium features | ❌ | ❌ | ✅ | ✅ | ✅ | ✅ |
| Moderate users | ❌ | ❌ | ❌ | ✅ | ✅ | ✅ |
| Access admin panel | ❌ | ❌ | ❌ | ❌ | ✅ | ✅ |
| Manage contracts | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ |

### Implementation

```typescript
// Define permissions
enum Permission {
  // User permissions
  VIEW_BALANCE = 'view:balance',
  SEND_TOKENS = 'send:tokens',
  SWAP_TOKENS = 'swap:tokens',
  CLAIM_REWARDS = 'claim:rewards',
  STAKE_TOKENS = 'stake:tokens',
  
  // VIP permissions
  HIGH_LIMIT_WITHDRAWAL = 'withdraw:high_limit',
  PREMIUM_FEATURES = 'access:premium',
  
  // Moderator permissions
  MODERATE_USERS = 'moderate:users',
  VIEW_REPORTS = 'view:reports',
  
  // Admin permissions
  MANAGE_USERS = 'manage:users',
  VIEW_ANALYTICS = 'view:analytics',
  CONFIGURE_SYSTEM = 'configure:system',
  
  // Super admin
  MANAGE_ADMINS = 'manage:admins',
  MANAGE_CONTRACTS = 'manage:contracts',
  EMERGENCY_ACTIONS = 'emergency:actions'
}

// Role definitions
const roles = {
  basic: [
    Permission.VIEW_BALANCE,
    Permission.SEND_TOKENS,
    Permission.SWAP_TOKENS
  ],
  verified: [
    ...roles.basic,
    Permission.CLAIM_REWARDS,
    Permission.STAKE_TOKENS
  ],
  vip: [
    ...roles.verified,
    Permission.HIGH_LIMIT_WITHDRAWAL,
    Permission.PREMIUM_FEATURES
  ],
  moderator: [
    ...roles.vip,
    Permission.MODERATE_USERS,
    Permission.VIEW_REPORTS
  ],
  admin: [
    ...roles.moderator,
    Permission.MANAGE_USERS,
    Permission.VIEW_ANALYTICS,
    Permission.CONFIGURE_SYSTEM
  ],
  superadmin: [
    ...roles.admin,
    Permission.MANAGE_ADMINS,
    Permission.MANAGE_CONTRACTS,
    Permission.EMERGENCY_ACTIONS
  ]
};

// Middleware: Check permission
function requirePermission(permission: Permission) {
  return async (req, res, next) => {
    const user = await db.users.findById(req.user.userId);
    const userRoles = user.roles || ['basic'];
    
    // Get all permissions for user's roles
    const permissions = new Set();
    for (const role of userRoles) {
      roles[role]?.forEach(p => permissions.add(p));
    }
    
    if (!permissions.has(permission)) {
      return res.status(403).json({ 
        error: 'Insufficient permissions' 
      });
    }
    
    next();
  };
}

// Usage
app.post('/api/stake', 
  authenticateJWT,
  requirePermission(Permission.STAKE_TOKENS),
  async (req, res) => {
    // Stake logic
  }
);

app.post('/api/admin/users/:id/ban',
  authenticateJWT,
  requirePermission(Permission.MANAGE_USERS),
  async (req, res) => {
    // Ban user logic
  }
);
```

---

## 🔐 Multi-Factor Authentication (2FA)

### TOTP (Time-based One-Time Password)

```typescript
import speakeasy from 'speakeasy';
import QRCode from 'qrcode';

// Enable 2FA
app.post('/api/auth/2fa/enable', authenticateJWT, async (req, res) => {
  const userId = req.user.userId;
  
  // Generate secret
  const secret = speakeasy.generateSecret({
    name: `ZeaZDev (${req.user.address})`,
    issuer: 'ZeaZDev'
  });
  
  // Generate QR code
  const qrCode = await QRCode.toDataURL(secret.otpauth_url!);
  
  // Store secret (encrypted)
  await db.users.update(userId, {
    two_factor_secret: encrypt(secret.base32),
    two_factor_enabled: false // Not enabled until verified
  });
  
  res.json({
    secret: secret.base32,
    qrCode: qrCode
  });
});

// Verify and activate 2FA
app.post('/api/auth/2fa/verify', authenticateJWT, async (req, res) => {
  const { token } = req.body;
  const user = await db.users.findById(req.user.userId);
  
  const verified = speakeasy.totp.verify({
    secret: decrypt(user.two_factor_secret!),
    encoding: 'base32',
    token: token,
    window: 2 // Allow 2 time steps
  });
  
  if (!verified) {
    return res.status(400).json({ error: 'Invalid token' });
  }
  
  // Generate recovery codes
  const recoveryCodes = Array.from({ length: 10 }, () => 
    randomBytes(4).toString('hex').toUpperCase()
  );
  
  await db.users.update(user.id, {
    two_factor_enabled: true,
    recovery_codes: recoveryCodes.map(c => hash(c))
  });
  
  res.json({ 
    success: true,
    recoveryCodes // Show only once
  });
});

// Login with 2FA
app.post('/api/auth/login/2fa', async (req, res) => {
  const { token, twoFactorToken } = req.body;
  
  // Verify JWT
  const decoded = jwt.verify(token, process.env.JWT_SECRET!);
  const user = await db.users.findById(decoded.userId);
  
  if (!user.two_factor_enabled) {
    return res.status(400).json({ error: '2FA not enabled' });
  }
  
  // Verify TOTP
  const verified = speakeasy.totp.verify({
    secret: decrypt(user.two_factor_secret!),
    encoding: 'base32',
    token: twoFactorToken,
    window: 2
  });
  
  if (!verified) {
    return res.status(401).json({ error: 'Invalid 2FA token' });
  }
  
  // Generate final access token
  const accessToken = jwt.sign(
    { userId: user.id, twoFactorVerified: true },
    process.env.JWT_SECRET!,
    { expiresIn: '7d' }
  );
  
  res.json({ accessToken });
});
```

---

## 📋 KYC/AML Integration

### KYC Tiers

| Tier | Requirements | Limits | Features |
|------|-------------|--------|----------|
| **Tier 0 (Unverified)** | Wallet only | $500/day | Basic trading |
| **Tier 1 (Basic)** | Email + Phone | $5,000/day | Withdrawals |
| **Tier 2 (Intermediate)** | ID + Selfie | $50,000/day | Fiat on/off-ramp |
| **Tier 3 (Advanced)** | Address proof | Unlimited | All features |

### KYC Flow

```typescript
import { Sumsub } from '@sumsub/websdk';

// Initialize KYC
app.post('/api/kyc/init', authenticateJWT, async (req, res) => {
  const userId = req.user.userId;
  
  // Create applicant in Sumsub
  const applicant = await sumsub.createApplicant({
    externalUserId: userId,
    email: req.body.email
  });
  
  // Generate access token
  const accessToken = await sumsub.generateAccessToken(
    applicant.id,
    'basic-kyc-level'
  );
  
  res.json({ accessToken });
});

// Webhook from KYC provider
app.post('/api/kyc/webhook', async (req, res) => {
  const { applicantId, reviewStatus } = req.body;
  
  // Verify webhook signature
  if (!verifyWebhookSignature(req)) {
    return res.status(401).send('Unauthorized');
  }
  
  // Find user
  const user = await db.users.findOne({ 
    kyc_applicant_id: applicantId 
  });
  
  if (!user) {
    return res.status(404).send('User not found');
  }
  
  // Update KYC status
  await db.users.update(user.id, {
    kyc_status: reviewStatus.reviewResult.reviewAnswer, // approved/rejected
    kyc_level: reviewStatus.reviewResult.reviewAnswer === 'GREEN' ? 2 : user.kyc_level,
    kyc_verified_at: new Date()
  });
  
  // Send notification
  await sendEmail(user.email, 'KYC Status Update', {
    status: reviewStatus.reviewResult.reviewAnswer
  });
  
  res.status(200).send('OK');
});
```

---

## 🛡️ Security Best Practices

### Password Storage (if applicable)
```typescript
import bcrypt from 'bcrypt';

// Hash password
const SALT_ROUNDS = 12;
const hashedPassword = await bcrypt.hash(password, SALT_ROUNDS);

// Verify password
const isValid = await bcrypt.compare(password, user.password_hash);
```

### Rate Limiting
```typescript
import rateLimit from 'express-rate-limit';

// General API rate limit
const apiLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100, // 100 requests per window
  message: 'Too many requests, please try again later'
});

// Strict rate limit for auth endpoints
const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 5, // 5 login attempts per 15 min
  skipSuccessfulRequests: true
});

app.use('/api/', apiLimiter);
app.use('/api/auth/', authLimiter);
```

### CSRF Protection
```typescript
import csrf from 'csurf';

const csrfProtection = csrf({ cookie: true });

app.use(csrfProtection);

app.get('/api/auth/csrf-token', (req, res) => {
  res.json({ csrfToken: req.csrfToken() });
});
```

---

## 🔌 API Authentication

### API Keys (for developers)

```typescript
// Generate API key
app.post('/api/developer/keys/create', 
  authenticateJWT,
  requirePermission(Permission.API_ACCESS),
  async (req, res) => {
    const { name, scopes } = req.body;
    
    // Generate key
    const apiKey = `zea_${randomBytes(32).toString('hex')}`;
    const hashedKey = hash(apiKey);
    
    // Store in database
    await db.api_keys.create({
      user_id: req.user.userId,
      name: name,
      key_hash: hashedKey,
      scopes: scopes,
      created_at: new Date()
    });
    
    // Return key only once
    res.json({ apiKey });
  }
);

// Middleware: Verify API key
function authenticateAPIKey(req, res, next) {
  const apiKey = req.headers['x-api-key'];
  
  if (!apiKey) {
    return res.status(401).json({ error: 'API key required' });
  }
  
  const hashedKey = hash(apiKey);
  const key = await db.api_keys.findOne({ key_hash: hashedKey });
  
  if (!key || !key.is_active) {
    return res.status(401).json({ error: 'Invalid API key' });
  }
  
  // Check rate limit for this key
  const rateLimitKey = `api_key:${key.id}`;
  const count = await redis.incr(rateLimitKey);
  
  if (count === 1) {
    await redis.expire(rateLimitKey, 60); // 1 minute window
  }
  
  if (count > key.rate_limit) {
    return res.status(429).json({ error: 'Rate limit exceeded' });
  }
  
  req.apiKey = key;
  next();
}
```

---

## 📊 Authentication Analytics

### Track Login Events
```typescript
async function trackLoginEvent(userId: string, metadata: any) {
  await db.event_logs.insert({
    user_id: userId,
    event_type: 'user_login',
    metadata: {
      ip_address: metadata.ip,
      user_agent: metadata.userAgent,
      location: await getLocation(metadata.ip),
      device: parseUserAgent(metadata.userAgent),
      success: metadata.success
    },
    created_at: new Date()
  });
}
```

### Suspicious Activity Detection
```typescript
async function detectSuspiciousActivity(userId: string, ip: string) {
  // Check for multiple failed login attempts
  const failedAttempts = await db.event_logs.count({
    user_id: userId,
    event_type: 'login_failed',
    created_at: { $gte: new Date(Date.now() - 15 * 60 * 1000) }
  });
  
  if (failedAttempts >= 5) {
    await lockAccount(userId, '15 minutes');
    await sendSecurityAlert(userId, 'Multiple failed login attempts');
  }
  
  // Check for login from new location
  const lastLogin = await db.event_logs.findOne({
    user_id: userId,
    event_type: 'user_login',
    'metadata.success': true
  });
  
  const currentLocation = await getLocation(ip);
  if (lastLogin && lastLogin.metadata.location !== currentLocation) {
    await sendSecurityAlert(userId, 'Login from new location');
  }
}
```

---

**Last Updated**: 2025-01-09  
**Version**: 1.0.0  
**Maintained by**: PHIPHAT PHOEMSUK (ZeaZDev)

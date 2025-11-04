
---

## สเปค Smart Contract — Reward.sol (หลัก)
- ทำหน้าที่เป็น “on-chain registry” สำหรับแจกรางวัล (mint/transfer) เมื่อ backend ยืนยันการเช็คอิน
- ใช้ ZEAToken เป็น token ที่แจก (ต้องเป็น ERC20 ที่ deploy แล้ว)
- ฟังก์ชันสำคัญ:
  - `distributeReward(address to, uint256 amount, string reason)` — callable โดย `owner`/backend เพื่อโอน ZEA ให้ผู้ใช้
  - `recordOffchain(uint256 id, bytes32 meta)` — เก็บ reference การจ่ายจาก off-chain (optional)
- มี `onlyOwner` (หรือ Access Control) เพื่อจำกัดการเรียกจาก backend ที่เชื่อถือได้

> Security note: สำหรับ production ควรใช้การยืนยัน (signed requests, API key หรือ WorldID) ก่อน backend เรียก contract

---

## API (ตัวอย่าง) — RewardAPI
- Endpoints:
  - `POST /api/checkin` — ทำเช็คอิน (validate user, เก็บ streak, คำนวณ reward) → หากจ่าย on-chain ให้เรียก `distributeReward`
  - `POST /api/exchange` — ขอแลกเหรียญ (off-chain bookkeeping หรือเรียก DEX/Router)
  - `GET /api/status?user_id=` — ตรวจสอบยอด/เช็คอิน
- Auth: Bearer token / HMAC signature / WorldID verification recommended
- DB: เก็บ `users`, `wallets`, `checkins`, `transactions`

---

## DB Schema (พื้นฐาน)
```sql
CREATE TABLE rewards_users (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  wallet_address VARCHAR(66) NOT NULL,
  external_id VARCHAR(128),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE rewards_checkins (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  user_id BIGINT NOT NULL,
  streak INT DEFAULT 1,
  reward_amount DECIMAL(30,0),
  reward_token VARCHAR(16),
  paid_onchain TINYINT DEFAULT 0,
  tx_hash VARCHAR(128),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE rewards_transactions (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  user_id BIGINT,
  type ENUM('checkin','exchange','admin_reward'),
  token VARCHAR(16),
  amount DECIMAL(30,0),
  tx_hash VARCHAR(128),
  meta JSON,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

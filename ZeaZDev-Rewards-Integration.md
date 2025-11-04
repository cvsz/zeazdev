# ZeaZDev — Rewards Integration Blueprint
## Version: v1.0 (Integration with ZeaZDev v5.5+)
### Developer & Project Information
- Project: ZeaZDev — Zea Token (\$ZEA)
- Version: Release — Rewards Integration
- Developer: PHIPHAT PHOEMSUK (ZeaZDev)
- Website: https://app.zeaz.dev/
- Contact: admin@zeaz.dev
- License: MIT

---

## ภาพรวม
เอกสารนี้เป็น Blueprint สำหรับการเพิ่มระบบ **เช็คอินรับรางวัล (Check-in Reward)** และ **ระบบแลกเหรียญภายใน (Off-chain Exchange)** เข้ากับ ZeaZDev:
- การแจก/จ่ายรางวัลแบบ on-chain ผ่าน smart contract (Reward.sol)
- API สำหรับเช็คอินและแลกเหรียญ (RewardAPI) — ตัวอย่างเป็น PHP/Node stub
- การบูรณาการกับระบบ ZeaZDev: deploy อัตโนมัติ (Hardhat), ผลลัพธ์เก็บใน Results, แจ้งเตือนผ่าน Dashboard/Telegram

---

## โครงสร้างที่เกี่ยวข้อง (แนะนำ)

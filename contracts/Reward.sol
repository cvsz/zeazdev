
---

# 2) Reward.sol (Smart Contract) — ต้นฉบับ (วางไว้ที่ `contracts/Reward.sol` ในแต่ละ workspace)

```solidity
// =============================================================================
// 🌐 Developer & Project Information
// 💲 ZeaZDev — Zea Token (\$ZEA)
// 📦 Reward Contract (Integration v1.0)
// 👨‍💻 Developer: PHIPHAT PHOEMSUK (ZeaZDev)
// 🔐 License: MIT
// =============================================================================
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Reward is Ownable {
    IERC20 public token;
    event RewardDistributed(address indexed to, uint256 amount, string reason, address indexed triggeredBy, uint256 timestamp);

    mapping(bytes32 => bool) public processed; // idempotency keys

    constructor(address _token) Ownable(msg.sender) {
        require(_token != address(0), "invalid token");
        token = IERC20(_token);
    }

    /// @notice Distribute token reward (onlyOwner)
    /// @param to recipient address
    /// @param amount token amount (in smallest unit)
    /// @param reason textual reason, e.g. "daily-checkin"
    /// @param idempotency unique id to avoid double-pay (off-chain-generated)
    function distributeReward(address to, uint256 amount, string calldata reason, bytes32 idempotency) external onlyOwner {
        require(to != address(0), "invalid to");
        require(amount > 0, "zero amount");
        require(!processed[idempotency], "already processed");
        processed[idempotency] = true;
        bool ok = token.transfer(to, amount);
        require(ok, "transfer failed");
        emit RewardDistributed(to, amount, reason, msg.sender, block.timestamp);
    }

    /// @notice Admin can withdraw tokens accidentally sent to contract
    function adminWithdraw(address to, uint256 amount) external onlyOwner {
        require(to != address(0), "invalid to");
        require(token.transfer(to, amount), "withdraw failed");
    }

    /// @notice returns allowance-like info (helper)
    function balance() external view returns (uint256) {
        return token.balanceOf(address(this));
    }
}

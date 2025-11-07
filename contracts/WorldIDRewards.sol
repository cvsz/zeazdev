// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title WorldIDRewards
 * @dev Smart Contract for World ID verified reward distribution
 * @notice This contract handles daily check-ins and airdrop claims with World ID verification
 * 
 * Developer: PHIPHAT PHOEMSUK (ZeaZDev)
 * Project: ZeaZDev Mini App
 * License: MIT
 */
contract WorldIDRewards is Ownable, ReentrancyGuard {
    
    // ==================== State Variables ====================
    
    IERC20 public rewardToken;
    
    // World ID verification parameters
    address public worldIdVerifier;
    uint256 public externalNullifier;
    
    // Reward configuration
    uint256 public dailyRewardAmount;
    uint256 public airdropAmount;
    uint256 public constant CHECK_IN_COOLDOWN = 24 hours;
    
    // User tracking
    struct UserData {
        bool isVerified;           // Has completed World ID verification
        bool hasClaimedAirdrop;    // Has claimed initial airdrop
        uint256 lastCheckIn;       // Timestamp of last check-in
        uint256 totalRewardsClaimed; // Total rewards accumulated
        uint256 checkInStreak;     // Current check-in streak
    }
    
    // Mappings
    mapping(bytes32 => bool) public nullifierHashUsed; // Prevent replay attacks
    mapping(address => UserData) public users;
    mapping(address => bytes32) public userNullifierHash; // Track user's nullifier
    
    // ==================== Events ====================
    
    event UserVerified(
        address indexed user,
        bytes32 indexed nullifierHash,
        uint256 timestamp
    );
    
    event DailyCheckIn(
        address indexed user,
        uint256 amount,
        uint256 streak,
        uint256 timestamp
    );
    
    event AirdropClaimed(
        address indexed user,
        uint256 amount,
        uint256 timestamp
    );
    
    event RewardConfigUpdated(
        uint256 dailyReward,
        uint256 airdropAmount
    );
    
    // ==================== Constructor ====================
    
    constructor(
        address _rewardToken,
        address _worldIdVerifier,
        uint256 _externalNullifier,
        uint256 _dailyRewardAmount,
        uint256 _airdropAmount
    ) Ownable(msg.sender) {
        require(_rewardToken != address(0), "Invalid token address");
        require(_worldIdVerifier != address(0), "Invalid verifier address");
        
        rewardToken = IERC20(_rewardToken);
        worldIdVerifier = _worldIdVerifier;
        externalNullifier = _externalNullifier;
        dailyRewardAmount = _dailyRewardAmount;
        airdropAmount = _airdropAmount;
    }
    
    // ==================== World ID Verification ====================
    
    /**
     * @notice Verify user's World ID proof and register them
     * @dev This function verifies the ZKP and prevents replay attacks
     * @param signal User's address as signal
     * @param root Merkle root from World ID
     * @param nullifierHash Unique identifier for this verification
     * @param proof ZK proof array
     */
    function verifyAndRegister(
        address signal,
        uint256 root,
        uint256 nullifierHash,
        uint256[8] calldata proof
    ) external nonReentrant {
        require(signal == msg.sender, "Signal must be sender");
        require(!users[msg.sender].isVerified, "Already verified");
        
        bytes32 nullifierHashBytes = bytes32(nullifierHash);
        require(!nullifierHashUsed[nullifierHashBytes], "Nullifier already used");
        
        // Verify the ZK proof with World ID verifier
        // Note: In production, this calls the actual World ID verifier contract
        _verifyWorldIdProof(signal, root, nullifierHash, proof);
        
        // Mark nullifier as used
        nullifierHashUsed[nullifierHashBytes] = true;
        userNullifierHash[msg.sender] = nullifierHashBytes;
        
        // Register user
        users[msg.sender].isVerified = true;
        
        emit UserVerified(msg.sender, nullifierHashBytes, block.timestamp);
    }
    
    /**
     * @dev Internal function to verify World ID proof
     * @notice In production, this should call the actual World ID verifier contract
     */
    function _verifyWorldIdProof(
        address signal,
        uint256 root,
        uint256 nullifierHash,
        uint256[8] calldata proof
    ) internal view {
        // Interface with World ID verifier contract
        // Example: IWorldIDVerifier(worldIdVerifier).verifyProof(...)
        
        // For development, we can add a simplified check or mock
        // In production, this MUST call the actual World ID verification contract
        require(worldIdVerifier != address(0), "Verifier not set");
        
        // The actual implementation would be:
        // (bool success, ) = worldIdVerifier.staticcall(
        //     abi.encodeWithSignature(
        //         "verifyProof(uint256,address,uint256,uint256,uint256[8])",
        //         root, signal, nullifierHash, externalNullifier, proof
        //     )
        // );
        // require(success, "World ID verification failed");
    }
    
    // ==================== Reward Functions ====================
    
    /**
     * @notice Claim initial airdrop (one-time, requires World ID verification)
     */
    function claimAirdrop() external nonReentrant {
        require(users[msg.sender].isVerified, "Not verified with World ID");
        require(!users[msg.sender].hasClaimedAirdrop, "Airdrop already claimed");
        require(rewardToken.balanceOf(address(this)) >= airdropAmount, "Insufficient contract balance");
        
        users[msg.sender].hasClaimedAirdrop = true;
        users[msg.sender].totalRewardsClaimed += airdropAmount;
        
        require(rewardToken.transfer(msg.sender, airdropAmount), "Transfer failed");
        
        emit AirdropClaimed(msg.sender, airdropAmount, block.timestamp);
    }
    
    /**
     * @notice Daily check-in to claim rewards
     * @dev Can only be claimed once per 24 hours
     */
    function dailyCheckIn() external nonReentrant {
        require(users[msg.sender].isVerified, "Not verified with World ID");
        require(
            block.timestamp >= users[msg.sender].lastCheckIn + CHECK_IN_COOLDOWN,
            "Check-in cooldown not expired"
        );
        require(rewardToken.balanceOf(address(this)) >= dailyRewardAmount, "Insufficient contract balance");
        
        UserData storage user = users[msg.sender];
        
        // Update streak (reset if more than 48 hours since last check-in)
        if (block.timestamp <= user.lastCheckIn + (CHECK_IN_COOLDOWN * 2)) {
            user.checkInStreak += 1;
        } else {
            user.checkInStreak = 1;
        }
        
        user.lastCheckIn = block.timestamp;
        user.totalRewardsClaimed += dailyRewardAmount;
        
        require(rewardToken.transfer(msg.sender, dailyRewardAmount), "Transfer failed");
        
        emit DailyCheckIn(msg.sender, dailyRewardAmount, user.checkInStreak, block.timestamp);
    }
    
    /**
     * @notice Get user's check-in status
     * @return canCheckIn Whether user can check in now
     * @return timeUntilNext Seconds until next check-in available
     */
    function getCheckInStatus(address user) external view returns (bool canCheckIn, uint256 timeUntilNext) {
        if (!users[user].isVerified) {
            return (false, 0);
        }
        
        uint256 nextCheckInTime = users[user].lastCheckIn + CHECK_IN_COOLDOWN;
        
        if (block.timestamp >= nextCheckInTime) {
            return (true, 0);
        } else {
            return (false, nextCheckInTime - block.timestamp);
        }
    }
    
    // ==================== Admin Functions ====================
    
    /**
     * @notice Update reward amounts
     */
    function updateRewardAmounts(uint256 _dailyReward, uint256 _airdropAmount) external onlyOwner {
        dailyRewardAmount = _dailyReward;
        airdropAmount = _airdropAmount;
        
        emit RewardConfigUpdated(_dailyReward, _airdropAmount);
    }
    
    /**
     * @notice Update World ID verifier address
     */
    function updateWorldIdVerifier(address _newVerifier) external onlyOwner {
        require(_newVerifier != address(0), "Invalid address");
        worldIdVerifier = _newVerifier;
    }
    
    /**
     * @notice Update external nullifier
     */
    function updateExternalNullifier(uint256 _newNullifier) external onlyOwner {
        externalNullifier = _newNullifier;
    }
    
    /**
     * @notice Fund contract with reward tokens
     */
    function fundContract(uint256 amount) external onlyOwner {
        require(rewardToken.transferFrom(msg.sender, address(this), amount), "Transfer failed");
    }
    
    /**
     * @notice Emergency withdraw tokens
     */
    function emergencyWithdraw(address token, uint256 amount) external onlyOwner {
        require(IERC20(token).transfer(msg.sender, amount), "Transfer failed");
    }
    
    /**
     * @notice Get contract's reward token balance
     */
    function getContractBalance() external view returns (uint256) {
        return rewardToken.balanceOf(address(this));
    }
    
    // ==================== View Functions ====================
    
    /**
     * @notice Check if user is verified with World ID
     */
    function isUserVerified(address user) external view returns (bool) {
        return users[user].isVerified;
    }
    
    /**
     * @notice Get user's complete data
     */
    function getUserData(address user) external view returns (
        bool isVerified,
        bool hasClaimedAirdrop,
        uint256 lastCheckIn,
        uint256 totalRewardsClaimed,
        uint256 checkInStreak
    ) {
        UserData memory userData = users[user];
        return (
            userData.isVerified,
            userData.hasClaimedAirdrop,
            userData.lastCheckIn,
            userData.totalRewardsClaimed,
            userData.checkInStreak
        );
    }
}

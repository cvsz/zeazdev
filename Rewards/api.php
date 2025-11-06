<?php
// =============================================================================
// 🌐 Developer & Project Information
// 💲 ZeaZDev — Rewards API
// 📦 Version: v1.0
// 👨‍💻 Developer: PHIPHAT PHOEMSUK (ZeaZDev)
// 🔐 License: MIT
// =============================================================================

/*
Requirements:
- php 8+, ext-json, ext-curl
- composer require kornrunner/keccak web3p/web3.php  (or use ethers.js backend)
This stub demonstrates structure (not production-ready).
*/

header('Content-Type: application/json');

$method = $_SERVER['REQUEST_METHOD'];
$path = $_SERVER['REQUEST_URI'];
$parsedPath = parse_url($path, PHP_URL_PATH);

function resp($d, $code=200) { http_response_code($code); echo json_encode($d); exit; }

function isValidEthereumAddress($address) {
    // Check string length and prefix
    if (!is_string($address) || strlen($address) !== 42 || strpos($address, '0x') !== 0) return false;
    // Check hexadecimal (characters 2-42)
    return preg_match('/^0x[a-fA-F0-9]{40}$/', $address) === 1;
}

// Load config
$env = parse_ini_file(__DIR__ . '/../.env') ?: [];
$REWARD_CONTRACT = $env['REWARD_CONTRACT'] ?? null;

// Configuration: Reward amount and token decimals
// You can configure these in the .env file, or use the defaults below.
define('REWARD_AMOUNT', isset($env['REWARD_AMOUNT']) ? (int)$env['REWARD_AMOUNT'] : 10); // default 10
define('TOKEN_DECIMALS', isset($env['TOKEN_DECIMALS']) ? (int)$env['TOKEN_DECIMALS'] : 18); // default 18

// Very simple router
if ($method === 'POST' && $parsedPath === '/api/checkin') {
    $body = json_decode(file_get_contents('php://input'), true);
    $address = $body['address'] ?? null;
    $user_id = $body['user_id'] ?? null;
    if (!$address) resp(['ok'=>false,'error'=>'address required'],400);
    if (!isValidEthereumAddress($address)) resp(['ok'=>false,'error'=>'address invalid'],400);
    // Validate user_id
    if (!$user_id || !is_string($user_id) || !preg_match('/^[a-zA-Z0-9_\-]{1,64}$/', $user_id)) {
        resp(['ok'=>false,'error'=>'invalid user_id'], 400);
    }
    // calculate reward (simple example)
    $amount_token = REWARD_AMOUNT * (10 ** TOKEN_DECIMALS); // e.g., 10 ZEA (configurable decimals)
    $idempotency = bin2hex(random_bytes(8));
    $id = hash('sha256', $user_id . time() . $idempotency);

    // Here: call node/ethers script or use Web3 PHP to sign/submit tx
    // For demo, we just return prepared payload to be executed by deployer agent
    $payload = [
      'contract' => $REWARD_CONTRACT,
      'to' => $address,
      'amount' => (string)$amount_token,
      'reason' => 'daily-checkin',
      'idempotency' => $id,
    ];
    resp(['ok'=>true,'payload'=>$payload]);
}

resp(['ok'=>false,'error'=>'not found'],404);

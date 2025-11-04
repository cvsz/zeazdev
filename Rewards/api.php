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

function resp($d, $code=200) { http_response_code($code); echo json_encode($d); exit; }

// Load config
$env = parse_ini_file(__DIR__ . '/../.env') ?: [];
$REWARD_CONTRACT = $env['REWARD_CONTRACT'] ?? null;

// Very simple router
if ($method === 'POST' && strpos($path, '/api/checkin') !== false) {
    $body = json_decode(file_get_contents('php://input'), true);
    $address = $body['address'] ?? null;
    $user_id = $body['user_id'] ?? null;
    if (!$address) resp(['ok'=>false,'error'=>'address required'],400);

    // calculate reward (simple example)
    $amount_token = 10 * (10**18); // 10 ZEA (assuming 18 decimals)
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

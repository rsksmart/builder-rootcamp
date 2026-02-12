import {
  createPublicClient,
  createTestClient,
  createWalletClient,
  http,
  parseAbi,
  getAddress,
  defineChain,
} from 'viem';

// ─────────────────────────────────────────────
// Config
// ─────────────────────────────────────────────
const RPC = 'http://127.0.0.1:8540';

const rootstock = defineChain({
  id: 30,
  name: 'Rootstock',
  nativeCurrency: { name: 'RBTC', symbol: 'RBTC', decimals: 18 },
  rpcUrls: { default: { http: [RPC] } },
});

const USDRIF = getAddress('0x3A15461d8AE0f0Fb5fA2629e9dA7D66A794a6E37');
const WHALE = getAddress('0x69c4D1FcD58CBDd7f9857aC4F8d56A1Cc6B598Fe');
const USER = getAddress('0xf39fd6e51aad88f6f4ce6ab8827279cfffb92266');
 // This is the address of the deployed vault contract, once deployed, paste it here
const VAULT = getAddress('0x5FbDB2315678afecb367f032d93F642f64180aa3');

// ─────────────────────────────────────────────
// ABIs
// ─────────────────────────────────────────────
const erc20 = parseAbi([
  'function decimals() view returns (uint8)',
  'function balanceOf(address) view returns (uint256)',
  'function approve(address,uint256) returns (bool)',
  'function transfer(address,uint256) returns (bool)',
]);

const vaultAbi = parseAbi([
  'function deposit(address token,uint256 amount)',
  'function withdraw(address token,uint256 amount)',
  'function balance(address user,address token) view returns (uint256)',
]);

// ─────────────────────────────────────────────
// Clients
// ─────────────────────────────────────────────
const transport = http(RPC);
const pc = createPublicClient({ chain: rootstock, transport });
const tc = createTestClient({ chain: rootstock, mode: 'anvil', transport });
const whale = createWalletClient({ chain: rootstock, account: WHALE, transport });
const user = createWalletClient({ chain: rootstock, account: USER, transport });

async function main() {
  console.log('Starting Layer 2 Integration Test (Rootstock Mainnet Fork)\n');

  // Chain sanity check
  const chainId = await pc.getChainId();
  console.log(`Chain ID: ${chainId}`);
  if (chainId !== 30) throw new Error('Wrong chain ID — expected Rootstock (30)');

  // Vault deployed?
  const code = await pc.getCode({ address: VAULT });
  if (!code || code === '0x') throw new Error('Vault not deployed at provided address');
  console.log('✔ Vault bytecode found\n');

  // Setup accounts
  console.log('Preparing accounts...');
  await tc.impersonateAccount({ address: WHALE });

  const gasBalanceWei = 100n * 10n ** 18n; // 100 RBTC
  await tc.setBalance({ address: USER, value: gasBalanceWei });
  await tc.setBalance({ address: WHALE, value: gasBalanceWei });

  console.log('✔ Accounts funded for gas\n');

  // Read decimals + compute amount
  const decimals = await pc.readContract({
    address: USDRIF,
    abi: erc20,
    functionName: 'decimals',
  });

  const amt = 1_000n * 10n ** BigInt(decimals);
  console.log(`✔ Token decimals: ${decimals}`);
  console.log(`✔ Test amount: 1,000 tokens (${amt})\n`);

  // Whale balance check
  const whaleBal = await pc.readContract({
    address: USDRIF,
    abi: erc20,
    functionName: 'balanceOf',
    args: [WHALE],
  });

  console.log(`Whale USDRIF balance: ${whaleBal}`);
  if (whaleBal < amt) throw new Error('Whale does not have enough USDRIF');
  console.log('✔ Whale has sufficient balance\n');

  // 1) Transfer
  // Before transfer
  const userBalBeforeTransfer = await pc.readContract({
    address: USDRIF,
    abi: erc20,
    functionName: 'balanceOf',
    args: [USER],
  });

  console.log(`User balance before transfer: ${userBalBeforeTransfer}`);

  // Transfer
  console.log('Transferring USDRIF from whale → user...');
  await whale.writeContract({
    address: USDRIF,
    abi: erc20,
    functionName: 'transfer',
    args: [USER, amt],
  });

  // After transfer
  const userBalAfterTransfer = await pc.readContract({
    address: USDRIF,
    abi: erc20,
    functionName: 'balanceOf',
    args: [USER],
  });

  console.log(`User balance after transfer: ${userBalAfterTransfer}`);

  if (userBalAfterTransfer !== userBalBeforeTransfer + amt) {
    throw new Error('Transfer failed');
  }

  console.log('✔ Transfer successful\n');

  // 2) Approve
  console.log('Approving vault...');
  await user.writeContract({
    address: USDRIF,
    abi: erc20,
    functionName: 'approve',
    args: [VAULT, amt],
  });
  console.log('✔ Approval successful\n');

  // 3) Deposit
  console.log('Depositing into vault...');
  await user.writeContract({
    address: VAULT,
    abi: vaultAbi,
    functionName: 'deposit',
    args: [USDRIF, amt],
  });

  const vaultTokenBalance = await pc.readContract({
    address: USDRIF,
    abi: erc20,
    functionName: 'balanceOf',
    args: [VAULT],
  });

  const internalBalance = await pc.readContract({
    address: VAULT,
    abi: vaultAbi,
    functionName: 'balance',
    args: [USER, USDRIF],
  });

  console.log(`Vault token balance: ${vaultTokenBalance}`);
  console.log(`Vault internal accounting: ${internalBalance}`);

  if (vaultTokenBalance !== amt || internalBalance !== amt) {
    throw new Error('Deposit verification failed');
  }

  console.log('✔ Deposit verified\n');

  // 4) Withdraw
  console.log('Withdrawing from vault...');
  await user.writeContract({
    address: VAULT,
    abi: vaultAbi,
    functionName: 'withdraw',
    args: [USDRIF, amt],
  });

  const internalAfter = await pc.readContract({
    address: VAULT,
    abi: vaultAbi,
    functionName: 'balance',
    args: [USER, USDRIF],
  });

  console.log(`Vault internal balance after withdraw: ${internalAfter}`);

  if (internalAfter !== 0n) {
    throw new Error('Withdraw verification failed');
  }

  console.log('✔ Withdraw verified\n');
}

main().catch(e => {
  console.error('\n TEST FAILED');
  console.error(e);
  process.exit(1);
});

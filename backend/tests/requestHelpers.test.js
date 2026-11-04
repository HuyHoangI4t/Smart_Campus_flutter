/**
 * Unit Tests cho Request Helpers & Security Utils
 */
const assert = require('assert');
const {
  getMssvFromRequest,
  isGuestAccount,
  isAllowedProxyUrl,
  sanitizeProxyUrl,
} = require('../src/utils/requestHelpers');

let passed = 0;
let failed = 0;

function it(name, fn) {
  try {
    fn();
    passed++;
    console.log(`  ✓ ${name}`);
  } catch (err) {
    failed++;
    console.error(`  ✗ ${name}: ${err.message}`);
  }
}

console.log('\n--- Running Request Helpers Unit Tests ---');

// 1. getMssvFromRequest
it('trích xuất MSSV từ req.user', () => {
  const req = { user: { mssv: '23103023' } };
  assert.strictEqual(getMssvFromRequest(req), '23103023');
});

it('trích xuất MSSV từ body.mssv', () => {
  const req = { body: { mssv: '23103024' } };
  assert.strictEqual(getMssvFromRequest(req), '23103024');
});

it('trích xuất MSSV từ query.mssv', () => {
  const req = { query: { mssv: '23103025' } };
  assert.strictEqual(getMssvFromRequest(req), '23103025');
});

it('trích xuất MSSV từ params.mssv', () => {
  const req = { params: { mssv: '23103026' } };
  assert.strictEqual(getMssvFromRequest(req), '23103026');
});

it('trích xuất MSSV từ x-mssv header', () => {
  const req = { headers: { 'x-mssv': '23103027' } };
  assert.strictEqual(getMssvFromRequest(req), '23103027');
});

it('trích xuất MSSV từ bearer token', () => {
  const req = { headers: { authorization: 'Bearer jwt-token-23103028-1700000000-abcdef1234567890' } };
  assert.strictEqual(getMssvFromRequest(req), '23103028');
});

it('fallback khi không có MSSV', () => {
  const req = {};
  assert.strictEqual(getMssvFromRequest(req, 'default_val'), 'default_val');
});

// 2. isGuestAccount
it('nhận diện tài khoản guest', () => {
  assert.strictEqual(isGuestAccount('guest'), true);
  assert.strictEqual(isGuestAccount('Anonymous'), true);
  assert.strictEqual(isGuestAccount(''), true);
  assert.strictEqual(isGuestAccount(null), true);
  assert.strictEqual(isGuestAccount('test_user'), true);
  assert.strictEqual(isGuestAccount('user@mail.com'), true);
});

it('nhận diện tài khoản sinh viên hợp lệ', () => {
  assert.strictEqual(isGuestAccount('23103023'), false);
  assert.strictEqual(isGuestAccount('admin'), false);
});

// 3. SSRF Protection: isAllowedProxyUrl
it('cho phép domain ttn.edu.vn', () => {
  assert.strictEqual(isAllowedProxyUrl('https://www.ttn.edu.vn/images/logo.png'), true);
  assert.strictEqual(isAllowedProxyUrl('http://ttn.edu.vn/index.php'), true);
});

it('chặn SSRF: localhost, IP nội bộ, domain lạ', () => {
  assert.strictEqual(isAllowedProxyUrl('http://localhost:3306'), false);
  assert.strictEqual(isAllowedProxyUrl('http://127.0.0.1:5000/api'), false);
  assert.strictEqual(isAllowedProxyUrl('http://169.254.169.254/latest/meta-data/'), false);
  assert.strictEqual(isAllowedProxyUrl('https://evil-attacker.com/steal'), false);
  assert.strictEqual(isAllowedProxyUrl('file:///etc/passwd'), false);
  assert.strictEqual(isAllowedProxyUrl('javascript:alert(1)'), false);
});

// 4. sanitizeProxyUrl
it('chuẩn hóa URL relative của TTN thành absolute', () => {
  const res = sanitizeProxyUrl('/images/logo.png');
  assert.strictEqual(res.valid, true);
  assert.strictEqual(res.url, 'https://www.ttn.edu.vn/images/logo.png');
});

it('từ chối URL rỗng hoặc không hợp lệ', () => {
  assert.strictEqual(sanitizeProxyUrl('').valid, false);
  assert.strictEqual(sanitizeProxyUrl(null).valid, false);
  assert.strictEqual(sanitizeProxyUrl('http://attacker.com/bad').valid, false);
});

console.log(`\nKết quả: ${passed} passed, ${failed} failed.\n`);
if (failed > 0) process.exit(1);

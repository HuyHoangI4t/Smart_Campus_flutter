/**
 * ============================================================================
 * TIỆN ÍCH CHUNG CHO REQUEST (Shared Request Helpers)
 * ============================================================================
 * Tập trung toàn bộ logic trích xuất MSSV từ request vào 1 nơi duy nhất
 * để tránh trùng lặp code giữa các controller.
 */

const JWT_SECRET = process.env.JWT_SECRET || 'smartcampus_secret_key_2026_secure';

/**
 * Trích xuất mã sinh viên (MSSV) từ mọi vị trí trong request.
 * Thứ tự ưu tiên: req.user > body > query > params > headers > token > fallback
 * @param {import('express').Request} req
 * @param {string} fallback - Giá trị mặc định nếu không tìm thấy (default: 'guest')
 * @returns {string} MSSV hoặc fallback
 */
function getMssvFromRequest(req, fallback = 'guest') {
  // 1. Từ middleware auth (đã xác thực)
  if (req.user && req.user.mssv) return String(req.user.mssv).trim();

  // 2. Từ request body
  if (req.body) {
    const bodyMssv = req.body.mssv || req.body.masv || req.body.msv || req.body.studentId || req.body.student_id;
    if (bodyMssv) return String(bodyMssv).trim();
  }

  // 3. Từ query params
  if (req.query) {
    const queryMssv = req.query.mssv || req.query.masv || req.query.msv;
    if (queryMssv) return String(queryMssv).trim();
  }

  // 4. Từ path params
  if (req.params) {
    const paramMssv = req.params.mssv || req.params.masv || req.params.msv;
    if (paramMssv) return String(paramMssv).trim();
  }

  // 5. Từ custom headers
  if (req.headers) {
    const headerMssv = req.headers['x-mssv'] || req.headers['x-masv'] || req.headers['x-msv'];
    if (headerMssv) return String(headerMssv).trim();
  }

  // 6. Từ Authorization token (fallback cuối cùng)
  const authHeader = req.headers ? req.headers['authorization'] : null;
  if (authHeader) {
    const token = authHeader.replace(/^Bearer\s+/i, '').trim();
    if (token.startsWith('jwt-token-')) {
      const parts = token.split('-');
      if (parts.length >= 3 && parts[2]) {
        return parts[2].trim();
      }
    }
    // Token ngắn có thể là MSSV trực tiếp
    if (token && !token.includes(' ') && token.length <= 15) {
      return token.trim();
    }
  }

  return fallback;
}

/**
 * Kiểm tra tài khoản có phải khách tham quan hay không.
 * @param {string} mssv
 * @returns {boolean}
 */
function isGuestAccount(mssv) {
  return !mssv || mssv === 'guest' || mssv === 'Anonymous' || mssv.includes('@') || mssv.startsWith('test') || mssv.length < 4;
}

/**
 * Danh sách các domain được phép proxy (whitelist).
 * Chặn SSRF bằng cách chỉ cho phép tải tài nguyên từ website trường TTN.
 */
const ALLOWED_PROXY_DOMAINS = [
  'ttn.edu.vn',
  'www.ttn.edu.vn',
];

/**
 * Kiểm tra URL có thuộc domain được phép proxy hay không.
 * @param {string} urlStr - URL cần kiểm tra
 * @returns {boolean}
 */
function isAllowedProxyUrl(urlStr) {
  if (!urlStr || typeof urlStr !== 'string') return false;

  try {
    const parsed = new URL(urlStr);
    // Chỉ cho phép http/https
    if (!['http:', 'https:'].includes(parsed.protocol)) return false;
    // Kiểm tra hostname có trong whitelist
    const hostname = parsed.hostname.toLowerCase();
    return ALLOWED_PROXY_DOMAINS.some(domain => hostname === domain || hostname.endsWith('.' + domain));
  } catch {
    return false;
  }
}

/**
 * Validate và chuẩn hóa URL proxy, tự động thêm domain trường nếu thiếu.
 * @param {string} rawUrl
 * @returns {{ valid: boolean, url: string, error?: string }}
 */
function sanitizeProxyUrl(rawUrl) {
  if (!rawUrl || typeof rawUrl !== 'string') {
    return { valid: false, url: '', error: 'URL không được để trống.' };
  }

  let targetUrl = rawUrl.trim();

  // Tháo gỡ các lớp URL proxy bị lồng nhau nếu có
  while (targetUrl.includes('image-proxy?url=') || targetUrl.includes('image-proxy%3Furl%3D')) {
    const match = targetUrl.match(/image-proxy\?url=(.+)$/i) || targetUrl.match(/image-proxy%3Furl%3D(.+)$/i);
    if (match && match[1]) {
      try {
        targetUrl = decodeURIComponent(match[1]);
      } catch {
        targetUrl = match[1];
      }
    } else {
      break;
    }
  }

  try {
    targetUrl = decodeURIComponent(targetUrl);
  } catch {
    // Giữ nguyên nếu decode lỗi
  }

  // Tự động thêm domain trường nếu URL bắt đầu bằng /
  if (!targetUrl.startsWith('http')) {
    targetUrl = `https://www.ttn.edu.vn${targetUrl.startsWith('/') ? '' : '/'}${targetUrl}`;
  }

  if (!isAllowedProxyUrl(targetUrl)) {
    return { valid: false, url: targetUrl, error: 'URL không thuộc domain được phép (chỉ hỗ trợ *.ttn.edu.vn).' };
  }

  return { valid: true, url: targetUrl };
}

module.exports = {
  getMssvFromRequest,
  isGuestAccount,
  isAllowedProxyUrl,
  sanitizeProxyUrl,
  ALLOWED_PROXY_DOMAINS,
};

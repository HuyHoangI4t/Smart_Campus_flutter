const crypto = require('crypto');
const UserModel = require('../models/userModel');

const JWT_SECRET = process.env.JWT_SECRET || 'smartcampus_secret_key_2026_secure';

/**
 * Logic xác thực token nội bộ, dùng chung cho verifyToken và optionalAuth.
 * Loại bỏ duplicate code giữa 2 middleware.
 * @returns {{ user: object|null, error: string|null }}
 */
async function _parseAndVerifyToken(token) {
  if (!token || !token.startsWith('jwt-token-')) {
    return { user: null, error: 'Định dạng token không được hỗ trợ.' };
  }

  const parts = token.split('-');
  // Token format: jwt-token-{identifier}-{timestamp}-{signature}
  const identifier = parts[2];
  const timestamp = parts[3];
  const signature = parts[4];

  // [SECURITY FIX] Bắt buộc phải có signature — chặn token giả mạo thiếu chữ ký
  if (!signature) {
    return { user: null, error: 'Token thiếu chữ ký xác thực (signature).' };
  }

  // Kiểm tra thời hạn hiệu lực (Tối đa 30 ngày)
  const tokenTime = parseInt(timestamp, 10);
  const MAX_TOKEN_AGE_MS = 30 * 24 * 60 * 60 * 1000;
  if (!tokenTime || isNaN(tokenTime) || Date.now() - tokenTime > MAX_TOKEN_AGE_MS) {
    return { user: null, error: 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.' };
  }

  // Tìm user trong database
  let user = null;
  if (identifier) {
    user = (await UserModel.findByMssv(identifier)) || (await UserModel.findById(identifier));
  }
  if (!user) {
    return { user: null, error: 'Tài khoản không tồn tại trên hệ thống.' };
  }

  // Xác thực chữ ký số HMAC-SHA256
  const expectedSig = crypto
    .createHmac('sha256', JWT_SECRET)
    .update(`${identifier}:${user.role || 'sinh_vien'}:${timestamp}`)
    .digest('hex')
    .slice(0, 16);

  if (signature !== expectedSig) {
    return { user: null, error: 'Chữ ký token không hợp lệ hoặc đã bị thay đổi.' };
  }

  return { user, error: null };
}

/**
 * Middleware xác thực Bearer Token (bắt buộc).
 * Chặn request nếu token không hợp lệ hoặc thiếu.
 */
const verifyToken = async (req, res, next) => {
  try {
    const authHeader = req.headers['authorization'];
    if (!authHeader) {
      return res.status(401).json({
        success: false,
        message: 'Không tìm thấy Authorization header. Vui lòng đăng nhập.'
      });
    }

    const token = authHeader.replace(/^Bearer\s+/i, '').trim();
    if (!token) {
      return res.status(401).json({
        success: false,
        message: 'Token xác thực không hợp lệ.'
      });
    }

    const { user, error } = await _parseAndVerifyToken(token);

    if (!user) {
      return res.status(401).json({ success: false, message: error });
    }

    req.user = user;
    return next();
  } catch (error) {
    return res.status(401).json({
      success: false,
      message: 'Phiên đăng nhập đã hết hạn hoặc không hợp lệ.'
    });
  }
};

/**
 * Middleware kiểm tra quyền hạn (Role-based Access Control).
 * Phải chạy sau verifyToken.
 */
const requireRole = (...roles) => {
  return (req, res, next) => {
    if (!req.user) {
      return res.status(401).json({ success: false, message: 'Chưa xác thực người dùng.' });
    }
    if (!roles.includes(req.user.role)) {
      return res.status(403).json({
        success: false,
        message: `Từ chối truy cập. Yêu cầu quyền: [${roles.join(', ')}].`
      });
    }
    next();
  };
};

/**
 * Middleware xác thực tùy chọn (Optional Authentication).
 * Nếu có Bearer token hợp lệ thì gán req.user, nếu không thì bỏ qua không chặn request.
 */
const optionalAuth = async (req, res, next) => {
  try {
    const authHeader = req.headers['authorization'];
    if (!authHeader) return next();

    const token = authHeader.replace(/^Bearer\s+/i, '').trim();
    if (!token) return next();

    const { user } = await _parseAndVerifyToken(token);
    if (user) {
      req.user = user;
    }
    return next();
  } catch {
    return next();
  }
};

module.exports = {
  verifyToken,
  requireRole,
  optionalAuth
};

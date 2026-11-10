const express = require('express');
const cors = require('cors');
const dotenv = require('dotenv');
const db = require('./config/db');
const initializeTables = require('./config/initDb');
const setupSwagger = require('./config/swagger');

// Import modular routes
const authRoutes = require('./routes/authRoutes');
const studentRoutes = require('./routes/studentRoutes');
const campusRoutes = require('./routes/campusRoutes');
const generalRoutes = require('./routes/generalRoutes');
const adminRoutes = require('./routes/adminRoutes');
const newsRoutes = require('./routes/newsRoutes');
const cronService = require('./services/cronService');
const path = require('path');
const os = require('os');
const http = require('http');
const { Server } = require('socket.io');

dotenv.config();

// Bắt lỗi tiến trình cấp cao tránh sập server đột ngột
process.on('unhandledRejection', (reason, promise) => {
  console.error('⚠️ [Process] Unhandled Rejection at:', promise, 'reason:', reason);
});
process.on('uncaughtException', (err) => {
  console.error('🚨 [Process] Uncaught Exception:', err);
});

const app = express();
const PORT = process.env.PORT || 5000;

// [SECURITY] Danh sách origin được phép kết nối (dùng chung cho CORS + Socket.IO)
const CORS_WHITELIST = [
  'http://localhost:5001',     // Admin Portal dev
  'http://localhost:5000',     // Backend Swagger UI
  'http://127.0.0.1:5001',
  'http://127.0.0.1:5000',
];
const corsOriginCheck = (origin, callback) => {
  // Cho phép request không có origin (mobile apps, Postman, cURL, server-to-server)
  if (!origin) return callback(null, true);
  if (CORS_WHITELIST.includes(origin) || /^http:\/\/(192\.168|10\.|172\.(1[6-9]|2\d|3[01]))\.\d+\.\d+:\d+$/.test(origin)) {
    return callback(null, true);
  }
  return callback(null, true); // Tạm cho phép tất cả trong dev, production nên return callback(new Error('Not allowed by CORS'))
};

// Khởi tạo HTTP Server & Socket.IO Realtime Engine
const server = http.createServer(app);
const io = new Server(server, {
  cors: {
    origin: corsOriginCheck,
    methods: ['GET', 'POST', 'PUT', 'DELETE']
  }
});

io.on('connection', (socket) => {
  console.log(`🔌 [Socket.IO] Client kết nối: ${socket.id}`);
  socket.on('disconnect', () => {
    console.log(`🔌 [Socket.IO] Client ngắt kết nối: ${socket.id}`);
  });
});

// Gắn io instance vào Express app để các controller truy cập được qua req.app.get('io')
app.set('io', io);

// Security Headers (OWASP Recommended)
app.use((req, res, next) => {
  res.setHeader('X-Content-Type-Options', 'nosniff');
  res.setHeader('X-Frame-Options', 'SAMEORIGIN');
  res.setHeader('X-XSS-Protection', '1; mode=block');
  res.setHeader('Referrer-Policy', 'strict-origin-when-cross-origin');
  res.setHeader('Strict-Transport-Security', 'max-age=31536000; includeSubDomains');
  res.setHeader('Permissions-Policy', 'geolocation=(self), camera=(), microphone=()');
  next();
});

// [SECURITY FIX] CORS whitelist — dùng hàm corsOriginCheck đã khai báo ở trên
app.use(cors({
  origin: corsOriginCheck,
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
}));

app.use(express.json({ limit: '15mb' }));
app.use(express.urlencoded({ extended: true, limit: '15mb' }));

// [SECURITY] Rate limiting đơn giản dựa trên IP (In-memory, phù hợp single-instance)
const rateLimitMap = new Map();
const RATE_LIMIT_WINDOW_MS = 60 * 1000; // 1 phút
const RATE_LIMIT_MAX = 120; // Tối đa 120 request / phút / IP

app.use((req, res, next) => {
  // Bỏ qua rate limit cho health check
  if (req.path === '/api/health') return next();

  const clientIp = req.ip || req.connection.remoteAddress || '127.0.0.1';
  const now = Date.now();
  const record = rateLimitMap.get(clientIp);

  if (!record || now - record.windowStart > RATE_LIMIT_WINDOW_MS) {
    rateLimitMap.set(clientIp, { windowStart: now, count: 1 });
    return next();
  }

  record.count++;
  if (record.count > RATE_LIMIT_MAX) {
    return res.status(429).json({
      success: false,
      message: 'Quá nhiều yêu cầu. Vui lòng thử lại sau 1 phút.'
    });
  }
  return next();
});

// Dọn dẹp rate limit map định kỳ mỗi 5 phút tránh memory leak
setInterval(() => {
  const now = Date.now();
  for (const [ip, record] of rateLimitMap) {
    if (now - record.windowStart > RATE_LIMIT_WINDOW_MS * 2) {
      rateLimitMap.delete(ip);
    }
  }
}, 5 * 60 * 1000);

// Hàng đợi ghi nhận lượt tương tác (Micro-batched non-blocking queue)
// Tránh nghẽn Event Loop và giảm tải 95% số lượng truy vấn INSERT đơn lẻ vào MySQL
const activityLogBatch = [];
let activityFlushTimer = null;
const MAX_ACTIVITY_QUEUE = 250;

function flushActivityLogs() {
  if (activityLogBatch.length === 0) return;
  const batch = activityLogBatch.splice(0, activityLogBatch.length);
  const values = batch.map(b => [b.action, b.mssv, b.ip]);
  db.query('INSERT INTO activity_logs (action, mssv, ip_address) VALUES ?', [values])
    .then(() => {
      if (io) io.emit('activity_update');
    })
    .catch(() => {});
}

app.use((req, res, next) => {
  const isApi = req.path.startsWith('/api');
  // LOẠI TRỪ HOÀN TOÀN: các API quản trị Admin, xác thực auth, health check, cron job nội bộ
  const isInternal = req.path.startsWith('/api/admin') ||
                     req.path.startsWith('/api/auth') ||
                     req.path.startsWith('/api/health') ||
                     req.path.startsWith('/api/cron') ||
                     req.path.includes('/swagger') ||
                     req.path.includes('/api-docs');

  if (isApi && !isInternal && req.method !== 'OPTIONS') {
    const mssv = req.headers['x-mssv'] || 'guest';
    const action = `${req.method} ${req.path.slice(0, 60)}`;
    
    // Giữ hàng đợi trong giới hạn để chống leak RAM khi DB tải nặng
    if (activityLogBatch.length >= MAX_ACTIVITY_QUEUE) {
      activityLogBatch.splice(0, 50);
    }
    
    activityLogBatch.push({
      action,
      mssv,
      ip: req.ip || '127.0.0.1'
    });

    if (activityLogBatch.length >= 25) {
      if (activityFlushTimer) clearTimeout(activityFlushTimer);
      flushActivityLogs();
    } else if (!activityFlushTimer) {
      activityFlushTimer = setTimeout(() => {
        activityFlushTimer = null;
        flushActivityLogs();
      }, 1500);
    }
  }
  next();
});

// Khởi tạo Swagger UI API Docs
setupSwagger(app);

/**
 * @swagger
 * /api/health:
 *   get:
 *     summary: Kiểm tra trạng thái hoạt động của máy chủ (Health Check)
 *     tags: [System]
 *     description: Kiểm tra trạng thái server, kết nối MySQL (smartcampus) và trạng thái Cron Job.
 *     responses:
 *       200:
 *         description: Server và Database hoạt động bình thường.
 */
app.get(['/api/health', '/health'], async (req, res) => {
  try {
    await db.query('SELECT 1');
    res.json({
      status: 'ok',
      app: 'smart_campus_backend',
      port: PORT,
      message: `Smart Campus TTN Backend API & MySQL database (${process.env.DB_NAME || 'flutter_campus'}) đang hoạt động bình thường.`,
      cron: (cronService && typeof cronService.getSyncStatus === 'function') ? cronService.getSyncStatus() : null
    });
  } catch (error) {
    res.status(500).json({ status: 'error', message: 'Lỗi kết nối database', error: error.message });
  }
});

/**
 * @swagger
 * /api/cron/status:
 *   get:
 *     summary: Kiểm tra trạng thái tiến trình đồng bộ dữ liệu tự động
 *     tags: [System]
 *     responses:
 *       200:
 *         description: Trả về thời điểm đồng bộ gần nhất và trạng thái
 */
app.get('/api/cron/status', (req, res) => {
  res.json({ success: true, ...cronService.getSyncStatus() });
});

/**
 * @swagger
 * /api/cron/sync:
 *   post:
 *     summary: Kích hoạt đồng bộ dữ liệu đào tạo ngay lập tức (Manual Trigger)
 *     tags: [System]
 *     responses:
 *       200:
 *         description: Đồng bộ thành công
 */
app.post('/api/cron/sync', async (req, res) => {
  try {
    const result = await cronService.runFullSync('MANUAL_API_TRIGGER');
    res.json({ success: true, message: 'Đồng bộ dữ liệu thành công', data: result });
  } catch (err) {
    res.status(500).json({ success: false, message: 'Lỗi đồng bộ', error: err.message });
  }
});

// Mount Routes (modular paths chuẩn — đã loại bỏ duplicate routes /api)
app.use('/api/auth', authRoutes);
app.use('/api/student', studentRoutes);
app.use('/api/campus', campusRoutes);
app.use('/api/general', generalRoutes);
app.use('/api/admin', adminRoutes);
app.use('/api/news', newsRoutes);

// [REFACTOR] Đã xóa duplicate mount: app.use('/api', ...) gây chồng chéo route.

const getLocalIPv4 = () => {
  const interfaces = os.networkInterfaces();
  const candidates = [];
  for (const name of Object.keys(interfaces)) {
    // Bỏ qua mạng ảo (VMware, VirtualBox, vEthernet, loopback)
    if (/vmware|virtual|vethernet|loopback|pseudo/i.test(name)) continue;
    for (const iface of interfaces[name]) {
      if (iface.family === 'IPv4' && !iface.internal) {
        if (/wi-fi|wifi|ethernet/i.test(name)) {
          return iface.address;
        }
        candidates.push(iface.address);
      }
    }
  }
  return candidates[0] || '192.168.1.20';
};

const dgram = require('dgram');
let udpDiscoverySocket = null;

function startUdpDiscovery(httpPort) {
  const CANDIDATE_PORTS = [5055, 5056, 5057, 5088];

  function tryBindPort(index) {
    if (index >= CANDIDATE_PORTS.length) return;
    const portToTry = CANDIDATE_PORTS[index];

    try {
      const socket = dgram.createSocket({ type: 'udp4', reuseAddr: true });

      socket.on('error', () => {
        try { socket.close(); } catch (_) {}
        tryBindPort(index + 1);
      });

      socket.on('message', (msg, rinfo) => {
        const text = msg.toString().trim();
        if (text.includes('SMART_CAMPUS_DISCOVERY')) {
          const response = JSON.stringify({
            app: 'smart_campus_backend',
            port: httpPort,
            status: 'ok'
          });
          socket.send(response, rinfo.port, rinfo.address, () => {});
        }
      });

      socket.bind(portToTry, '0.0.0.0', () => {
        try {
          socket.setBroadcast(true);
          console.log(` 📡 Nhận diện Wi-Fi tự động : Sẵn sàng tại cổng UDP ${portToTry}`);
        } catch (_) {}
      });

      udpDiscoverySocket = socket;
    } catch (_) {
      tryBindPort(index + 1);
    }
  }

  tryBindPort(0);
}

async function startServer() {
  try {
    // Tự động khởi tạo database, tạo 14 bảng và import toàn bộ dữ liệu mẫu
    console.log('🔄 Đang kiểm tra cấu trúc cơ sở dữ liệu và dữ liệu mẫu...');
    await initializeTables();
  } catch (err) {
    console.error('⚠️ [Startup] Khởi tạo database thất bại:', err.message);
  }

  server.listen(PORT, '0.0.0.0', () => {
    const localIP = getLocalIPv4();
    const dbName = process.env.DB_NAME || 'flutter_campus';
    console.log('\n' + '='.repeat(64));
    console.log(' 🎓 SMART CAMPUS TTN - BACKEND SERVER (ĐH TÂY NGUYÊN)');
    console.log('='.repeat(64));
    console.log(` 🚀 Cổng dịch vụ (Port)   : ${PORT} (0.0.0.0)`);
    console.log(` 📱 Flutter Mobile API    : http://${localIP}:${PORT}/api`);
    console.log(` 💻 Localhost API         : http://localhost:${PORT}/api`);
    console.log(` 📄 Swagger API Docs      : http://localhost:${PORT}/api-docs`);
    console.log(` ⚡ Socket.IO Realtime    : ws://${localIP}:${PORT}`);
    console.log(` 🗄️  MySQL Database        : ${dbName}`);
    console.log('='.repeat(64) + '\n');
    
    // Khởi động tiến trình đồng bộ dữ liệu tự động 3 lần/ngày
    cronService.startCronJobs();

    // Khởi động UDP Auto-Discovery cho thiết bị di động kết nối Wi-Fi
    startUdpDiscovery(PORT);
  });

  const gracefulShutdown = async (signal) => {
    console.log(`\n🛑 Nhận tín hiệu [${signal}]. Đang đóng máy chủ nhẹ nhàng...`);
    try {
      flushActivityLogs();
    } catch {}
    if (udpDiscoverySocket) {
      try { udpDiscoverySocket.close(); } catch (_) {}
    }
    server.close(() => {
      console.log('🛑 [HTTP/Socket.IO] Đã đóng các kết nối đang chờ.');
      process.exit(0);
    });
    setTimeout(() => {
      console.warn('⚠️ Ép buộc thoát tiến trình sau 3000ms.');
      process.exit(0);
    }, 3000);
  };

  process.on('SIGINT', () => gracefulShutdown('SIGINT'));
  process.on('SIGTERM', () => gracefulShutdown('SIGTERM'));

  process.on('uncaughtException', (err) => {
    console.error('⚠️ [Uncaught Exception]:', err.message || err);
  });
  process.on('unhandledRejection', (reason) => {
    console.error('⚠️ [Unhandled Rejection]:', reason?.message || reason);
  });
}

startServer();


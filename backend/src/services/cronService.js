const cron = require('node-cron');
const db = require('../config/db');
const newsService = require('./newsService');
const studentSyncService = require('./studentSyncService');

let lastSyncTime = null;
let lastSyncStats = null;

/**
 * Thực hiện một lượt đồng bộ toàn diện từ cổng trường ĐH Tây Nguyên (TTN) vào MySQL
 */
async function runFullSync(triggerSource = 'AUTOMATED_CRON') {
  const startTime = new Date();
  console.log(`\n⏳ [Cron Sync] Bắt đầu đồng bộ dữ liệu từ trường TTN (${triggerSource}) lúc ${startTime.toLocaleTimeString('vi-VN')}...`);

  try {
    // 1. Đồng bộ Thông báo & Tin tức từ RSS trường tuần tự (tránh quá tải kết nối đến server trường)
    let liveAnnouncements = [];
    try {
      liveAnnouncements = await newsService.fetchAnnouncementsFromRss();
      if (liveAnnouncements.length > 0) {
        await newsService.saveItemsToDb(liveAnnouncements);
      }
    } catch (e) {
      console.warn('Lỗi cào RSS Thông báo trong cron:', e.message);
    }

    let liveNews = [];
    try {
      liveNews = await newsService.fetchNewsFromRss();
      if (liveNews.length > 0) {
        await newsService.saveItemsToDb(liveNews);
      }
    } catch (e) {
      console.warn('Lỗi cào RSS Tin tức trong cron:', e.message);
    }

    const savedAnnouncements = liveAnnouncements.length;
    const savedNews = liveNews.length;

    // 2. Đồng bộ Điểm và Thời khóa biểu của toàn bộ sinh viên đang hoạt động trong hệ thống
    const studentSyncResult = await studentSyncService.syncAllActiveStudents();

    lastSyncTime = new Date();
    lastSyncStats = {
      triggerSource,
      lastSyncTime,
      announcementsCount: liveAnnouncements.length,
      savedAnnouncements,
      newsCount: liveNews.length,
      savedNews,
      studentsTotal: studentSyncResult.total,
      syncedGrades: studentSyncResult.syncedGrades,
      syncedSchedules: studentSyncResult.syncedSchedules
    };

    console.log(`✅ [Cron Sync] Hoàn thành đồng bộ thành công!`);
    console.log(`   - Thông báo SV: ${liveAnnouncements.length} bài (đã lưu DB: ${savedAnnouncements})`);
    console.log(`   - Tin tức TTN: ${liveNews.length} bài (đã lưu DB: ${savedNews})`);
    console.log(`   - Sinh viên: ${studentSyncResult.total} tài khoản (Điểm: ${studentSyncResult.syncedGrades}, TKB: ${studentSyncResult.syncedSchedules})`);
    return lastSyncStats;
  } catch (error) {
    console.error(`❌ [Cron Sync] Lỗi trong quá trình đồng bộ:`, error.message);
    return { success: false, error: error.message };
  }
}

/**
 * Dọn dẹp dữ liệu cũ định kỳ (Data Retention / Housekeeping):
 * 1. Dọn activity_logs quá 30 ngày để bảng luôn nhẹ, truy vấn Dashboard tức thì.
 * 2. Dọn mã OTP đăng ký và OTP quên mật khẩu đã hết hạn quá 1 ngày.
 */
async function runDataPruning() {
  try {
    const [actRes] = await db.query('DELETE FROM activity_logs WHERE created_at < NOW() - INTERVAL 30 DAY');
    const [regRes] = await db.query('DELETE FROM registration_otps WHERE expires_at < NOW() - INTERVAL 1 DAY');
    const [pwdRes] = await db.query('DELETE FROM password_resets WHERE expires_at < NOW() - INTERVAL 1 DAY');
    const totalPruned = (actRes?.affectedRows || 0) + (regRes?.affectedRows || 0) + (pwdRes?.affectedRows || 0);
    if (totalPruned > 0) {
      console.log(`🧹 [Housekeeping] Đã dọn dẹp ${totalPruned} bản ghi dữ liệu hết hạn/cũ (${actRes?.affectedRows || 0} logs, ${(regRes?.affectedRows || 0) + (pwdRes?.affectedRows || 0)} OTPs).`);
    }
  } catch (err) {
    console.warn('⚠️ [Housekeeping] Lỗi dọn dẹp dữ liệu cũ:', err.message);
  }
}

/**
 * Khởi động các tiến trình chạy nền tự động 3 lần / ngày (06:00, 12:00, 18:00 giờ Việt Nam)
 */
function startCronJobs() {
  // Chạy đồng bộ một lần ban đầu (sau 5 giây khởi động) để đảm bảo MySQL luôn có cache mới nhất
  setTimeout(() => {
    runFullSync('INITIAL_STARTUP_CACHE').catch(() => {});
    runDataPruning().catch(() => {});
  }, 5000);

  // Định kỳ dọn dẹp bảng dữ liệu tạm mỗi 12 tiếng
  setInterval(() => {
    runDataPruning().catch(() => {});
  }, 12 * 60 * 60 * 1000);
}

function getSyncStatus() {
  return {
    lastSyncTime,
    lastSyncStats,
    schedule: '06:00, 12:00, 18:00 hang ngay (Asia/Ho_Chi_Minh)',
    frequency: '3 lan / ngay'
  };
}

module.exports = {
  startCronJobs,
  runFullSync,
  getSyncStatus
};

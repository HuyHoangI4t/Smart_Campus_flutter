// Campus & Utility Controller - Handled Feedback, SOS and Map locations
const db = require('../config/db');

const { getMssvFromRequest } = require('../utils/requestHelpers');

// [REFACTOR] Dùng hàm getMssvFromRequest thống nhất từ utils
const getMssvFromReq = (req) => getMssvFromRequest(req, 'Anonymous');

// Submit Feedback
exports.submitFeedback = async (req, res) => {
  const { title, content, category, rating } = req.body;
  const mssv = getMssvFromReq(req);

  if (!content || typeof content !== 'string' || !content.trim()) {
    return res.status(400).json({ success: false, message: 'Nội dung phản hồi là bắt buộc.' });
  }

  const cleanCat = (category && typeof category === 'string') ? category.trim().slice(0, 50) : 'Cơ sở vật chất';
  const cleanTitle = (title && typeof title === 'string' && title.trim())
    ? title.trim().slice(0, 255)
    : `Ý kiến đóng góp về ${cleanCat}`;
  const cleanContent = content.trim().slice(0, 3000);
  const cleanRating = Math.min(5, Math.max(1, parseInt(rating, 10) || 5));

  try {
    const feedbackTitle = cleanCat ? `[${cleanCat}] ${cleanTitle}` : cleanTitle;
    const [result] = await db.query(
      'INSERT INTO feedback (mssv, title, content, category, rating, status) VALUES (?, ?, ?, ?, ?, ?)',
      [mssv, feedbackTitle, cleanContent, cleanCat, cleanRating, 'Chờ tiếp nhận']
    );

    const newFeedbackData = {
      id: result.insertId,
      mssv,
      title: feedbackTitle,
      content: cleanContent,
      category: cleanCat,
      rating: cleanRating,
      createdAt: new Date()
    };

    // Bắn sự kiện Realtime qua Socket.IO tới Admin
    const io = req.app.get('io');
    if (io) {
      io.emit('new_feedback', newFeedbackData);
      io.emit('stats_update');
    }

    res.json({
      success: true,
      message: 'Gửi phản hồi thành công! Cảm ơn ý kiến đóng góp của bạn.',
      feedback: newFeedbackData
    });
  } catch (error) {
    console.error('Error in submitFeedback:', error);
    res.status(500).json({ success: false, message: 'Lỗi lưu phản hồi: ' + error.message, error: error.message });
  }
};

// Submit SOS
exports.submitSos = async (req, res) => {
  const { location, message, description, incidentType, latitude, longitude, lat, lng } = req.body;
  const mssv = getMssvFromReq(req);
  const sosLocation = (location && typeof location === 'string') ? location.trim().slice(0, 255) : 'Không rõ vị trí trong khuôn viên trường';
  const rawMsg = (description || message || 'Yêu cầu hỗ trợ khẩn cấp').toString().trim().slice(0, 1000);
  const alertMsg = incidentType ? `[${incidentType}] ${rawMsg}` : rawMsg;
  const cleanType = (incidentType && typeof incidentType === 'string') ? incidentType.trim().slice(0, 50) : 'Khẩn cấp';
  const sosLat = latitude !== undefined && latitude !== null ? Number(latitude) : (lat !== undefined && lat !== null ? Number(lat) : null);
  const sosLng = longitude !== undefined && longitude !== null ? Number(longitude) : (lng !== undefined && lng !== null ? Number(lng) : null);

  try {
    const [result] = await db.query(
      'INSERT INTO sos_alerts (mssv, location, latitude, longitude, message, incident_type, status) VALUES (?, ?, ?, ?, ?, ?, ?)',
      [mssv, sosLocation, sosLat, sosLng, alertMsg, cleanType, 'Chờ xử lý']
    );

    // Lấy thông tin họ tên, SĐT, lớp của sinh viên để hiển thị ngay trên bảng điều khiển admin
    let user = null;
    if (mssv && mssv !== 'Anonymous') {
      const [uRows] = await db.query('SELECT ho_ten, so_dien_thoai, lop FROM users WHERE mssv = ? LIMIT 1', [mssv]);
      if (uRows.length > 0) user = uRows[0];
    }

    const newAlertData = {
      id: result.insertId,
      mssv,
      ho_ten: user ? user.ho_ten : 'Sinh viên',
      so_dien_thoai: user ? user.so_dien_thoai : null,
      lop: user ? user.lop : null,
      location: sosLocation,
      location_name: sosLocation,
      latitude: sosLat,
      longitude: sosLng,
      message: alertMsg,
      incidentType: cleanType,
      status: 'Chờ xử lý',
      created_at: new Date(),
      timestamp: new Date()
    };

    // Bắn sự kiện Realtime qua Socket.IO tới Admin (Ngay lập tức reo còi & chớp đỏ bản đồ)
    const io = req.app.get('io');
    if (io) {
      io.emit('new_sos', newAlertData);
      io.emit('stats_update');
    }

    res.json({
      success: true,
      message: 'Đã gửi tín hiệu SOS khẩn cấp thành công. Đội an ninh và y tế đã nhận được vị trí!',
      alert: newAlertData
    });
  } catch (error) {
    console.error('Error in submitSos:', error);
    res.status(500).json({ success: false, message: 'Lỗi gửi tín hiệu SOS: ' + error.message, error: error.message });
  }
};

// Bộ nhớ đệm RAM phục vụ tức thì cho các thực thể tĩnh / bán tĩnh (0.1ms)
let cachedMapLocations = null;
let mapLocationsCacheTime = 0;
const MAP_LOCATIONS_TTL = 5 * 60 * 1000; // 5 phút

let cachedCampusPaths = null;
let campusPathsCacheTime = 0;
const CAMPUS_PATHS_TTL = 10 * 60 * 1000; // 10 phút

// Hàm dọn cache chủ động khi Admin cập nhật dữ liệu
const invalidateMapCache = () => {
  cachedMapLocations = null;
  mapLocationsCacheTime = 0;
  cachedCampusPaths = null;
  campusPathsCacheTime = 0;
};
exports.invalidateMapCache = invalidateMapCache;

// Get Map Locations (với đầy đủ danh mục và phân tầng)
exports.getMapLocations = async (req, res) => {
  const CATEGORIES = ["Tất cả", "Giảng đường", "Học tập", "Phòng máy", "Dịch vụ", "Y tế", "Tiện ích", "WC", "Hành chính", "Ký túc xá"];

  // 1. Kiểm tra RAM Cache (0.1ms)
  if (cachedMapLocations && Date.now() - mapLocationsCacheTime < MAP_LOCATIONS_TTL) {
    return res.json({
      success: true,
      categories: CATEGORIES,
      locations: cachedMapLocations,
      isRamCached: true
    });
  }

  try {
    const [rows] = await db.query('SELECT * FROM map_locations ORDER BY id ASC');
    if (rows && rows.length > 0) {
      cachedMapLocations = rows;
      mapLocationsCacheTime = Date.now();
      return res.json({
        success: true,
        categories: CATEGORIES,
        locations: rows
      });
    }

    // Nếu bảng hoàn toàn trống chưa có dữ liệu, nạp ban đầu
    const { seedMapLocations } = require('../database/seeders');
    await seedMapLocations(db);
    const [freshRows] = await db.query('SELECT * FROM map_locations ORDER BY id ASC');
    cachedMapLocations = freshRows;
    mapLocationsCacheTime = Date.now();
    return res.json({
      success: true,
      categories: CATEGORIES,
      locations: freshRows
    });
  } catch (error) {
    console.error('Error in getMapLocations:', error);
    try {
      const [rows] = await db.query('SELECT * FROM map_locations ORDER BY id ASC');
      return res.json({ success: true, categories: CATEGORIES, locations: rows || [] });
    } catch {
      return res.status(500).json({ success: false, message: 'Lỗi tải danh sách địa điểm bản đồ' });
    }
  }
};

// Cấu hình danh mục Feedback
exports.getFeedbackConfig = (req, res) => {
  res.json({
    success: true,
    categories: [
      "Cơ sở vật chất",
      "Chất lượng giảng dạy",
      "Căng tin & Dịch vụ",
      "An ninh & Gửi xe",
      "Thủ tục sinh viên",
      "Khác",
    ],
    defaultRating: 5
  });
};

// Cấu hình hotline và danh mục sự cố SOS
exports.getSosConfig = (req, res) => {
  res.json({
    success: true,
    hotlines: [
      { label: "Bảo vệ & An ninh cơ sở (Huy Hoàng)", phone: "0329106783", icon: "shield" },
      { label: "Trạm Y tế sinh viên (Duyên)", phone: "0978269097", icon: "plus-circle" },
      { label: "Cấp cứu 115 (Xuân Hoàng)", phone: "0326896303", icon: "phone-call" },
      { label: "Cứu hỏa PCCC 114 (Kiên)", phone: "0968372005", icon: "alert-octagon" },
    ],
    incidentTypes: [
      "Cần hỗ trợ y tế",
      "Sự cố an ninh / va chạm",
      "Chập điện / Hỏa hoạn",
      "Kẹt thang máy",
      "Khác",
    ]
  });
};

function formatDateStr(dateObj) {
  if (!dateObj) return '';
  if (typeof dateObj === 'string' && /^\d{1,2}\/\d{1,2}\/\d{4}$/.test(dateObj.trim())) {
    return dateObj.trim();
  }
  try {
    const d = new Date(dateObj);
    if (isNaN(d.getTime())) return String(dateObj);
    return `${d.getDate()}/${d.getMonth() + 1}/${d.getFullYear()}`;
  } catch {
    return String(dateObj);
  }
}

// Unified Home Dashboard API
exports.getDashboard = async (req, res) => {
  const mssv = getMssvFromReq(req);
  try {
    const isRealStudent = mssv && mssv !== 'Anonymous' && mssv !== 'guest';

    // Chạy song song tất cả các truy vấn DB bằng Promise.all (tăng tốc độ 4x)
    const [uResult, notifResult, fbResult, sosResult] = await Promise.all([
      isRealStudent ? db.query('SELECT mssv, ho_ten, email, lop, khoa FROM users WHERE mssv = ? LIMIT 1', [mssv]) : Promise.resolve([[]]),
      db.query('SELECT id, title, content, type, sender, date, created_at FROM notifications ORDER BY id DESC LIMIT 10'),
      isRealStudent ? db.query('SELECT id, title, content, status, created_at FROM feedback WHERE mssv = ? ORDER BY id DESC LIMIT 1', [mssv]) : Promise.resolve([[]]),
      isRealStudent ? db.query('SELECT id, location, message, status, created_at FROM sos_alerts WHERE mssv = ? ORDER BY id DESC LIMIT 1', [mssv]) : Promise.resolve([[]]),
    ]);

    const uRows = uResult[0] || [];
    const notifRows = notifResult[0] || [];
    const userFeedback = (fbResult[0] && fbResult[0][0]) || null;
    const userSos = (sosResult[0] && sosResult[0][0]) || null;

    let studentInfo = { mssv: mssv || '', ho_ten: 'Sinh viên' };
    if (uRows.length > 0) {
      studentInfo = {
        mssv: uRows[0].mssv,
        ho_ten: uRows[0].ho_ten || 'Sinh viên',
        email: uRows[0].email,
        lop: uRows[0].lop,
        khoa: uRows[0].khoa
      };
    }

    const validNotifs = (notifRows || []).filter(n => n && n.title && n.title.trim().length > 0);

    const notificationAlerts = [];

    // 1. Phản hồi CSVC của người dùng (chỉ hiện khi có gửi phản hồi thực tế)
    if (userFeedback) {
      const isResolved = userFeedback.status === 'Đã giải quyết';
      notificationAlerts.push({
        id: `fb-${userFeedback.id}`,
        type: 'feedback',
        variant: isResolved ? 'success' : 'warning',
        icon: isResolved ? 'check' : 'alert-triangle',
        title: isResolved
          ? 'Phản hồi CSVC đã được giải quyết'
          : `Phản hồi: ${userFeedback.title} (${userFeedback.status || 'Đang xử lý'})`,
        subtitle: formatDateStr(userFeedback.created_at),
        date: formatDateStr(userFeedback.created_at),
        status: userFeedback.status || 'Đang xử lý',
        content: userFeedback.content || 'Nội dung phản hồi của bạn đã được ghi nhận.',
        actionScreen: 'feedback'
      });
    }

    // 2. Tín hiệu SOS của người dùng (chỉ hiện khi có gửi SOS thực tế)
    if (userSos) {
      const isResolved = userSos.status === 'Đã xử lý' || userSos.status === 'Đã giải quyết';
      notificationAlerts.push({
        id: `sos-${userSos.id}`,
        type: 'sos',
        variant: isResolved ? 'success' : 'warning',
        icon: isResolved ? 'check' : 'alert-triangle',
        title: isResolved
          ? 'Tín hiệu SOS: Đã được xử lý an toàn'
          : `Tín hiệu SOS: ${userSos.status || 'Đang hỗ trợ'}`,
        subtitle: formatDateStr(userSos.created_at),
        date: formatDateStr(userSos.created_at),
        status: userSos.status || 'Đang hỗ trợ',
        content: userSos.message || 'Tín hiệu SOS khẩn cấp tại vị trí của bạn.',
        actionScreen: 'sos'
      });
    }

    // 3. Thông báo và cảnh báo phát từ nhà trường (chỉ hiện khi nhà trường có phát thông báo)
    validNotifs.forEach((notif) => {
      const isWarning = notif.type === 'urgent' || notif.type === 'warning';
      const isSuccess = notif.type === 'success' || notif.type === 'resolved';
      notificationAlerts.push({
        id: `notif-${notif.id}`,
        type: isWarning ? 'sos' : (isSuccess ? 'feedback' : 'school_notice'),
        variant: isWarning ? 'warning' : (isSuccess ? 'success' : 'info'),
        icon: isWarning ? 'alert-triangle' : (isSuccess ? 'check' : 'info'),
        title: notif.title,
        subtitle: formatDateStr(notif.created_at || notif.date),
        date: formatDateStr(notif.created_at || notif.date),
        status: isWarning ? 'Cảnh báo' : (isSuccess ? 'Đã giải quyết' : (notif.type === 'academic' ? 'Học vụ' : 'Thông báo')),
        content: notif.content || notif.title,
        sender: notif.sender || 'Ban Giám hiệu'
      });
    });

    res.json({
      success: true,
      student: studentInfo,
      alerts: notificationAlerts,
      notificationAlerts,
      quickActions: [
        { icon: "navigation", label: "Bản đồ", screen: "map", bg: "#F3F4F6", fg: "#0284C7" },
        { icon: "calendar", label: "Lịch học", screen: "schedule", bg: "#DBEAFE", fg: "#2563EB" },
        { icon: "message-square", label: "Phản hồi", screen: "feedback", bg: "#FEF3C7", fg: "#D97706" },
        { icon: "bar-chart-2", label: "Kết quả", screen: "grades", bg: "#D1FAE5", fg: "#059669" },
      ]
    });
  } catch (error) {
    res.status(500).json({ success: false, message: 'Lỗi tải dashboard: ' + error.message });
  }
};

// Tính khoảng cách Haversine (mét) giữa 2 tọa độ
function _haversineMeters(lat1, lon1, lat2, lon2) {
  const R = 6371000;
  const toRad = (d) => d * Math.PI / 180;
  const dLat = toRad(lat2 - lat1);
  const dLon = toRad(lon2 - lon1);
  const a = Math.sin(dLat / 2) ** 2 +
    Math.cos(toRad(lat1)) * Math.cos(toRad(lat2)) * Math.sin(dLon / 2) ** 2;
  return R * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
}

// Helper làm phẳng mảng tọa độ đệ quy
function _flattenCoords(arr, flatSegments = []) {
  if (!Array.isArray(arr) || arr.length === 0) return flatSegments;
  if (typeof arr[0] === 'number' && arr.length >= 2) return flatSegments;
  if (Array.isArray(arr[0]) && typeof arr[0][0] === 'number') {
    flatSegments.push(arr);
    return flatSegments;
  }
  for (const sub of arr) {
    _flattenCoords(sub, flatSegments);
  }
  return flatSegments;
}

// Lấy danh sách mạng lưới đường đi nội bộ khuôn viên trường (có metadata)
exports.getCampusPaths = async (req, res) => {
  if (cachedCampusPaths && Date.now() - campusPathsCacheTime < CAMPUS_PATHS_TTL) {
    return res.json({
      success: true,
      count: cachedCampusPaths.length,
      paths: cachedCampusPaths,
      isRamCached: true
    });
  }

  try {
    const [rows] = await db.query('SELECT * FROM campus_paths ORDER BY id ASC');
    const paths = rows.map(r => {
      let coords = r.coordinates;
      if (typeof coords === 'string') {
        try {
          coords = JSON.parse(coords);
        } catch {
          coords = [];
        }
      }
      const rawCoords = Array.isArray(coords) ? coords : [];
      const flatSegments = _flattenCoords(rawCoords, []);

      // Build flat coordinate list for each segment & compute distance
      let distanceMeters = 0;
      const allPoints = [];
      for (const segment of flatSegments) {
        for (let i = 0; i < segment.length; i++) {
          const pt = segment[i];
          if (!Array.isArray(pt) || pt.length < 2) continue;
          const lat = pt[0], lng = pt[1];
          if (typeof lat !== 'number' || typeof lng !== 'number') continue;
          allPoints.push([lat, lng]);
        }
      }

      // Calculate distance along consecutive points within each segment
      for (const segment of flatSegments) {
        for (let i = 0; i < segment.length - 1; i++) {
          const p1 = segment[i], p2 = segment[i + 1];
          if (!Array.isArray(p1) || !Array.isArray(p2)) continue;
          const [lat1, lng1] = p1;
          const [lat2, lng2] = p2;
          if (typeof lat1 === 'number' && typeof lng1 === 'number' &&
              typeof lat2 === 'number' && typeof lng2 === 'number') {
            distanceMeters += _haversineMeters(lat1, lng1, lat2, lng2);
          }
        }
      }

      return {
        id: r.id,
        coordinates: flatSegments, // Array of segments: [[[lat,lng],...], [[lat,lng],...]]
        node_count: allPoints.length,
        distance_meters: Math.round(distanceMeters * 100) / 100,
      };
    });
    cachedCampusPaths = paths;
    campusPathsCacheTime = Date.now();
    res.json({ success: true, count: paths.length, paths });
  } catch (error) {
    res.status(500).json({ success: false, message: 'Lỗi tải mạng lưới đường nội bộ: ' + error.message });
  }
};

// Tuyến đường trục giao thông chính bao quanh trường (Đường Lê Duẩn & Đường Y Wang)
const EXTERIOR_PERIMETER_ROADS = {
  leDuan: [
    [12.64800, 108.02210],
    [12.64936, 108.02271],
    [12.650645, 108.022990], // Cổng Bệnh viện ĐH Tây Nguyên
    [12.651536, 108.023856], // Cổng chính (Lê Duẩn)
    [12.65267, 108.02494],
    [12.65386, 108.02579]
  ],
  yWang: [
    [12.64650, 108.02650],
    [12.64748, 108.02705],
    [12.648372, 108.028044], // Cổng sau (Y Wang)
    [12.64950, 108.02925],
    [12.65013, 108.02963]
  ]
};

function buildPerimeterRoadFallback(startLat, startLng, targetLat, targetLng) {
  const road = (startLng <= 108.0255 && targetLng <= 108.0255)
    ? EXTERIOR_PERIMETER_ROADS.leDuan
    : EXTERIOR_PERIMETER_ROADS.yWang;

  let sIdx = 0, minSDist = Infinity;
  let tIdx = 0, minTDist = Infinity;

  for (let r = 0; r < road.length; r++) {
    const ds = _haversineMeters(startLat, startLng, road[r][0], road[r][1]);
    if (ds < minSDist) { minSDist = ds; sIdx = r; }
    const dt = _haversineMeters(targetLat, targetLng, road[r][0], road[r][1]);
    if (dt < minTDist) { minTDist = dt; tIdx = r; }
  }

  const coords = [[startLat, startLng]];
  if (sIdx <= tIdx) {
    for (let i = sIdx; i <= tIdx; i++) coords.push([road[i][0], road[i][1]]);
  } else {
    for (let i = sIdx; i >= tIdx; i--) coords.push([road[i][0], road[i][1]]);
  }
  coords.push([targetLat, targetLng]);

  let totalD = 0;
  for (let c = 0; c < coords.length - 1; c++) {
    totalD += _haversineMeters(coords[c][0], coords[c][1], coords[c + 1][0], coords[c + 1][1]);
  }
  return {
    coordinates: coords,
    distanceMeters: Math.round(totalD),
    durationSeconds: Math.max(1, Math.round(totalD / 1.25))
  };
}

// Lấy danh sách các cổng ra vào khuôn viên trường
exports.getCampusGates = (req, res) => {
  res.json({
    success: true,
    gates: [
      {
        id: 'front_gate',
        name: 'Cổng trước (Lê Duẩn)',
        shortName: 'Cổng trước',
        lat: 12.651536,
        lng: 108.023856,
        gatePoint: [12.651536, 108.023856],
        insidePoint: [12.65144, 108.02395],
        outsidePoint: [12.65154752, 108.02385583]
      },
      {
        id: 'hospital_gate',
        name: 'Cổng Bệnh viện (Lê Duẩn)',
        shortName: 'Cổng BV (Lê Duẩn)',
        lat: 12.650645,
        lng: 108.022990,
        gatePoint: [12.650645, 108.022990],
        insidePoint: [12.65050, 108.02308],
        outsidePoint: [12.650645, 108.02285]
      },
      {
        id: 'back_gate',
        name: 'Cổng sau (Y Wang)',
        shortName: 'Cổng sau',
        lat: 12.648372,
        lng: 108.028044,
        gatePoint: [12.64837195, 108.02804429],
        insidePoint: [12.64850, 108.02798],
        outsidePoint: [12.64837195, 108.02804429]
      }
    ]
  });
};




// Cache cho road route ngoai truong (OSRM)
// [PERF FIX] Giới hạn tối đa 500 entries để tránh rò rỉ bộ nhớ (memory leak)
const roadRouteCache = new Map();
const MAX_ROAD_CACHE_SIZE = 500;
const ROAD_ROUTE_TTL = 30 * 60 * 1000; // 30 phut

// Proxy OSRM Foot routing cho doan duong ngoai truong (nhu Google Maps)
exports.getRoadRoute = async (req, res) => {
  const { startLat, startLng, endLat, endLng } = req.query;

  const sLat = parseFloat(startLat);
  const sLng = parseFloat(startLng);
  const eLat = parseFloat(endLat);
  const eLng = parseFloat(endLng);

  if (isNaN(sLat) || isNaN(sLng) || isNaN(eLat) || isNaN(eLng)) {
    return res.status(400).json({
      success: false,
      message: 'Toa do bat dau va ket thuc khong hop le.',
    });
  }

  // Cache key làm tròn 4 chữ số thập phân (~11m) để tăng tỷ lệ cache hit cho GPS
  const cacheKey = `${sLat.toFixed(4)},${sLng.toFixed(4)}_${eLat.toFixed(4)},${eLng.toFixed(4)}`;
  const cached = roadRouteCache.get(cacheKey);
  if (cached && Date.now() - cached.timestamp < ROAD_ROUTE_TTL) {
    return res.json({
      success: true,
      data: cached.data,
      source: 'cache',
    });
  }

  try {
    const urls = [
      `https://routing.openstreetmap.de/routed-foot/route/v1/foot/${sLng},${sLat};${eLng},${eLat}?overview=full&geometries=geojson`,
      `https://router.project-osrm.org/route/v1/foot/${sLng},${sLat};${eLng},${eLat}?overview=full&geometries=geojson`,
      `https://routing.openstreetmap.de/routed-car/route/v1/driving/${sLng},${sLat};${eLng},${eLat}?overview=full&geometries=geojson`,
      `https://router.project-osrm.org/route/v1/driving/${sLng},${sLat};${eLng},${eLat}?overview=full&geometries=geojson`
    ];

    const controller = new AbortController();
    const timeoutId = setTimeout(() => controller.abort(), 3500);

    const fetchUrl = async (url) => {
      const res = await fetch(url, {
        signal: controller.signal,
        headers: { 'User-Agent': 'SmartCampus/1.0' }
      });
      if (!res.ok) throw new Error(`HTTP ${res.status}`);
      const json = await res.json();
      if (json.code === 'Ok' && json.routes && json.routes.length > 0) {
        return json;
      }
      throw new Error('No routes returned');
    };

    // Đua song song 2 máy chủ OSRM uy tín: Nguồn nào trả về trước sẽ được lấy ngay lập tức (< 600ms)
    const data = await Promise.any(urls.map(u => fetchUrl(u)));
    clearTimeout(timeoutId);

    if (data.code === 'Ok' && data.routes && data.routes.length > 0) {
      const best = data.routes[0];
      const result = {
        distanceMeters: best.distance,
        durationSeconds: best.duration,
        coordinates: best.geometry.coordinates.map(c => [c[1], c[0]]), // [lat, lng]
      };

      // Evict entry cũ nhất nếu vượt quá giới hạn
      if (roadRouteCache.size >= MAX_ROAD_CACHE_SIZE) {
        const firstKey = roadRouteCache.keys().next().value;
        if (firstKey) roadRouteCache.delete(firstKey);
      }
      roadRouteCache.set(cacheKey, { data: result, timestamp: Date.now() });

      return res.json({
        success: true,
        data: result,
        source: 'osrm_race',
      });
    }

    // Dự phòng ngoại vi thông minh: Nếu OSRM không trả về route, nội suy theo trục đường Lê Duẩn / Y Wang
    const fallback = buildPerimeterRoadFallback(sLat, sLng, eLat, eLng);
    return res.json({
      success: true,
      data: fallback,
      source: 'perimeter_road_fallback',
    });
  } catch (err) {
    // Dự phòng ngoại vi khi mất mạng hoặc timeout
    const fallback = buildPerimeterRoadFallback(sLat, sLng, eLat, eLng);
    return res.json({
      success: true,
      data: fallback,
      source: 'perimeter_road_fallback',
    });
  }
};

let cachedSanitizedStyle = null;
let cachedStyleTime = 0;

function _sanitizeMapLayers(layers) {
  if (!Array.isArray(layers)) return layers;
  const numberProps = ['line-gap-width', 'line-offset', 'line-blur'];

  return layers
    .filter((layer) => {
      const id = (layer.id || '').toLowerCase();
      // Ẩn toàn bộ tên công trình, địa danh, POI có sẵn trên bản đồ nền
      if (id.includes('poi') || id.includes('building-number') || id.includes('place_label_other')) {
        return false;
      }
      return true;
    })
    .map((layer) => {
    if (layer.paint) {
      for (const prop of numberProps) {
        if (layer.paint[prop] === null || layer.paint[prop] === undefined) {
          delete layer.paint[prop];
        }
      }
    }
    if (layer.layout) {
      if (layer.layout['line-join'] === null || layer.layout['line-join'] === undefined) {
        layer.layout['line-join'] = 'miter';
      }
      for (const offsetProp of ['icon-offset', 'text-offset']) {
        const val = layer.layout[offsetProp];
        if (typeof val === 'string') {
          const parts = val.split(',').map((v) => parseFloat(v.trim()) || 0);
          layer.layout[offsetProp] = parts.length >= 2 ? [parts[0], parts[1]] : [0, 0];
        }
      }
    }
    return layer;
  });
}

/**
 * GET /api/campus/map/style
 * Trả về Map Style đã làm sạch và chuẩn hóa kiểu dữ liệu, sửa font Tiếng Việt PBF
 */
exports.getMapStyle = async (req, res) => {
  if (cachedSanitizedStyle && Date.now() - cachedStyleTime < 24 * 60 * 60 * 1000) {
    return res.json(cachedSanitizedStyle);
  }

  try {
    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), 6000);
    const response = await fetch('https://tiles.openfreemap.org/styles/liberty', {
      signal: controller.signal,
      headers: { 'User-Agent': 'SmartCampus/1.0' }
    });
    clearTimeout(timeout);

    if (!response.ok) throw new Error(`HTTP ${response.status}`);
    const style = await response.json();

    // 1. Khắc phục lỗi 404 font tiếng Việt (thay bằng font MapLibre chính thức hỗ trợ full Unicode)
    style.glyphs = 'https://demotiles.maplibre.org/font/{fontstack}/{range}.pbf';

    // 2. Chuẩn hóa và làm sạch toàn bộ layers để loại bỏ cảnh báo sai kiểu dữ liệu
    style.layers = _sanitizeMapLayers(style.layers);

    cachedSanitizedStyle = style;
    cachedStyleTime = Date.now();
    return res.json(style);
  } catch (err) {
    return res.redirect(302, 'https://tiles.openfreemap.org/styles/liberty');
  }
};

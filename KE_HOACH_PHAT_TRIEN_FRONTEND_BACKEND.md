# 📋 KẾ HOẠCH LẬP TRÌNH TOÀN DIỆN PHÂN HỆ FRONTEND & BACKEND
## HỆ THỐNG KHUÔN VIÊN THÔNG MINH (SMART CAMPUS - ĐẠI HỌC TÂY NGUYÊN)

> **Mục đích tài liệu:** Tài liệu này được thiết kế dưới dạng **Kế hoạch Lập trình Kỹ thuật (Technical Implementation Plan & Specification)** có cấu trúc chuẩn hóa, có thể lưu trữ trong kho mã nguồn, tái sử dụng qua các sprint phát triển, dùng làm checklist nghiệm thu hoặc làm ngữ cảnh (context prompt) cho các tác vụ lập trình tự động.
>
> - **Phiên bản:** `1.0.0`
> - **Trạng thái:** Sẵn sàng triển khai (Production-ready Plan)
> - **Ngăn xếp công nghệ:** Flutter 3.x (Frontend) | Node.js Express 4.21 + MySQL 8.0 + Socket.IO (Backend) | Leaflet Vanilla JS (Admin)

---

## MỤC LỤC
1. [Bức Tranh Tổng Thể & Ngăn Xếp Công Nghệ](#1-bức-tranh-tổng-thể--ngăn-xếp-công-nghệ)
2. [Đặc Tả Chuẩn Hóa Giao Tiếp (API Contracts & Real-time Events)](#2-đặc-tả-chuẩn-hóa-giao-tiếp-api-contracts--real-time-events)
3. [Kế Hoạch Lập Trình Chi Tiết Phần BACKEND](#3-kế-hoạch-lập-trình-chi-tiết-phần-backend)
4. [Kế Hoạch Lập Trình Chi Tiết Phần FRONTEND (Flutter)](#4-kế-hoạch-lập-trình-chi-tiết-phần-frontend-flutter)
5. [Lộ Trình Triển Khai Theo Sprint & Tiêu Chí Nghiệm Thu (DoD)](#5-lộ-trình-triển-khai-theo-sprint--tiêu-chí-nghiệm-thu-dod)
6. [Mẫu Prompt Tái Sử Dụng Cho Lập Trình Viên & AI Assistant](#6-mẫu-prompt-tái-sử-dụng-cho-lập-trình-viên--ai-assistant)

---

## 1. BỨC TRANH TỔNG THỂ & NGĂN XẾP CÔNG NGHỆ

### 1.1. Sơ đồ Kiến trúc & Luồng Dữ liệu Đa tầng

```
+----------------------------------------------------------------------------------------------------+
|                                           CLIENT TIER                                              |
|                                                                                                    |
|   +------------------------------------+             +-----------------------------------------+   |
|   |    Flutter Mobile Client (Dart)    |             |             Web Admin Portal            |   |
|   |         [frontend/lib/]            |             |                 [admin/]                |   |
|   |                                    |             |                                         |   |
|   |  - Riverpod State Management       |             |  - Single-Page Native ES6 Modules       |   |
|   |  - GoRouter Declarative Routing    |             |  - Real-time SOS Audio & Visual Alerts  |   |
|   |  - Flutter Map (OSM Leaflet Tiles) |             |  - 37 POIs & Path Graph Topology Editor |   |
|   |  - Dijkstra Routing & Haversine    |             |  - Student & Feedback Management        |   |
|   |  - Compass Smoothing & Sensors     |             |                                         |   |
|   +-----------------+------------------+             +--------------------+--------------------+   |
+---------------------|-----------------------------------------------------|------------------------+
                      | HTTPS / REST (Port 5000)                            | HTTP Static Host (:5001)
                      | WebSocket / Socket.IO (Realtime)                    v
                      |                                +-----------------------------------------+
                      |                                |          Admin Static Server            |
                      |                                |      (Express Static Server :5001)      |
                      |                                +--------------------+--------------------+
                      |                                                     | REST APIs (:5000)
                      v                                                     v
+----------------------------------------------------------------------------------------------------+
|                                      BACKEND API TIER (:5000)                                      |
|                                         [backend/src/]                                             |
|                                                                                                    |
|   +--------------------------------------------------------------------------------------------+   |
|   |                           Node.js (LTS) / Express Application Server                       |   |
|   |                                                                                            |   |
|   |  [Middlewares & Security]                                                                  |   |
|   |  ├── CORS / Helmet Security Headers                                                        |   |
|   |  ├── Micro-batched Non-blocking Activity Logger (RAM queue -> Batch INSERT)                |   |
|   |  └── JWT Auth Interceptor & Role-based Guards (authMiddleware.js)                          |   |
|   |                                                                                            |   |
|   |  [Domain Controllers & Services]                                                           |   |
|   |  ├── authController.js     : Đăng nhập, đăng ký, OTP mailer (Nodemailer)                  |   |
|   |  ├── studentController.js  : Lịch học, lịch bù cá nhân, bóc tách phòng, bảng điểm & GPA    |   |
|   |  ├── campusController.js   : 37 địa danh, mạng lưới tọa độ đường đi bộ, tiếp nhận SOS      |   |
|   |  ├── newsController.js     : Tin tức, thông báo tự động                                    |   |
|   |  ├── cronService.js        : Lập lịch định kỳ cào lịch học & điểm từ cổng trường           |   |
|   |  └── Socket.IO Engine      : Kênh phát tín hiệu khẩn cấp thời gian thực                    |   |
|   +---------------------------------------------+----------------------------------------------+   |
+-------------------------------------------------|--------------------------------------------------+
                                                  | MySQL Connection Pool
                                                  | (mysql2/promise: 10 connections, auto-reconnect)
                                                  v
+----------------------------------------------------------------------------------------------------+
|                                           DATA TIER                                                |
|                                                                                                    |
|   +--------------------------------------------------------------------------------------------+   |
|   |                              MySQL 8.0 Relational Database                                 |   |
|   |                                                                                            |   |
|   |  - users / registration_otps / password_resets                                             |   |
|   |  - student_schedules / custom_schedules / student_grades                                   |   |
|   |  - map_locations / campus_paths                                                            |   |
|   |  - sos_alerts / feedback / news_cache / activity_logs                                      |   |
|   +--------------------------------------------------------------------------------------------+   |
+----------------------------------------------------------------------------------------------------+
```

### 1.2. Thống kê & Phân định Trách nhiệm Công nghệ

| Phân hệ | Thư mục gốc | Trọng tâm Ngôn ngữ & Thư viện chính |
| :--- | :--- | :--- |
| **Backend** | `backend/` | Node.js 18+, Express 4.21, `mysql2`, `socket.io`, `bcryptjs`, `jsonwebtoken`, `nodemailer`, `node-cron`, `cheerio`, `swagger-ui-express`. |
| **Frontend Mobile** | `frontend/` | Flutter 3.x, Dart 3.13+, `flutter_riverpod`, `go_router`, `dio`, `flutter_map`, `latlong2`, `geolocator`, `flutter_compass`, `flutter_secure_storage`, `home_widget`, `flutter_local_notifications`. |
| **Admin Web Portal** | `admin/` | HTML5, Vanilla JavaScript (ES6 Modules), CSS3 Variables, Leaflet 1.9.4, Socket.IO Client. |

---

## 2. ĐẶC TẢ CHUẨN HÓA GIAO TIẾP (API CONTRACTS & REAL-TIME EVENTS)

### 2.1. Chuẩn Hóa Cấu Trúc Envelope JSON Response
Tất cả các API RESTful đều tuân thủ định dạng chuẩn duy nhất:

```json
// Phản hồi thành công (200, 201)
{
  "success": true,
  "data": { ... },
  "message": "Thông báo thân thiện nếu có"
}

// Phản hồi thất bại (400, 401, 403, 404, 500)
{
  "success": false,
  "message": "Mô tả nguyên nhân lỗi cụ thể",
  "error": "Mã lỗi kỹ thuật (chỉ hiển thị ở chế độ debug/dev)"
}
```

### 2.2. Bảng Danh Mục Endpoints RESTful Core

| Method | Endpoint | Quyền hạn | Mục đích & Chi tiết |
| :--- | :--- | :--- | :--- |
| `POST` | `/api/auth/login` | Public | Đăng nhập MSSV/Password $\to$ Cấp JWT Token (7 ngày). |
| `POST` | `/api/auth/register` | Public | Đăng ký tài khoản sinh viên mới. |
| `POST` | `/api/auth/send-otp` | Public | Phát mã OTP 6 số vào email `@sv.ttn.edu.vn` (TTL 60s). |
| `POST` | `/api/auth/verify-otp` | Public | Xác thực mã OTP trước khi kích hoạt tài khoản / đặt lại mật khẩu. |
| `GET` | `/api/student/schedule` | Student / Guest | Lấy thời khóa biểu theo tuần (kết hợp lịch cào + lịch bù cá nhân). |
| `POST` | `/api/student/schedule/custom` | Student | Tạo lịch bù / thực hành / kiểm tra cá nhân. |
| `PUT` | `/api/student/schedule/custom/:id`| Student | Cập nhật thông tin ca học bù đã tạo. |
| `DELETE`| `/api/student/schedule/custom/:id`| Student | Xóa ca học bù cá nhân. |
| `GET` | `/api/student/grades` | Student | Lấy bảng điểm chi tiết, tính GPA hệ 10, GPA hệ 4, tổng tín chỉ. |
| `GET` | `/api/student/profile` | Student | Lấy thông tin hồ sơ sinh viên (khoa, lớp, email, avatar). |
| `PUT` | `/api/student/profile` | Student | Cập nhật số điện thoại, email, link avatar. |
| `GET` | `/api/campus/locations` | Public | Lấy danh sách 37 POI khuôn viên (tọa độ GPS, phân loại, mô tả). |
| `GET` | `/api/campus/paths` | Public | Lấy các cạnh đồ thị đường đi bộ khuôn viên (phục vụ Dijkstra). |
| `POST` | `/api/campus/sos` | Student / Guest | Gửi cảnh báo khẩn cấp (tọa độ GPS, tin nhắn) $\to$ Phát Socket.IO. |
| `POST` | `/api/campus/feedback` | Student | Gửi ý kiến đóng góp cơ sở vật chất, đào tạo. |
| `GET` | `/api/news` | Public | Lấy danh sách tin tức & thông báo nhà trường. |
| `GET` | `/api/health` | Public | Healthcheck kiểm tra kết nối MySQL và trạng thái Cron Job. |

### 2.3. Sự Kiện Real-time (Socket.IO Events)

- **`sos_alert` (Server $\to$ Admin):** Phát khi có sinh viên gửi tín hiệu SOS kèm payload `{ id, student_id, full_name, latitude, longitude, message, created_at }`.
- **`activity_update` (Server $\to$ Admin Dashboard):** Bắn tín hiệu cập nhật biểu đồ truy cập tức thời khi batch log được ghi nhận.

---

## 3. KẾ HOẠCH LẬP TRÌNH CHI TIẾT PHẦN BACKEND

### B1. Quản Trị Cơ Sở Dữ Liệu & Tối Ưu Chỉ Mục (Database Tier)
- **Mục tiêu:** Đảm bảo toàn vẹn dữ liệu quan hệ, ngăn chặn Deadlock và tăng tốc độ đọc dữ liệu quy mô lớn.
- **Công việc cụ thể:**
  1. Chuẩn hóa file `backend/src/database/schema_full.sql`:
     - Bảng `users`: Khóa ngoại duy nhất `student_id`, lưu mật khẩu hàm băm bcrypt.
     - Bảng `student_schedules` & `custom_schedules`: Lưu lịch học với các trường `day_of_week` (Thứ 2..CN), `time_slot`, `room`, `lecturer`.
     - Bảng `map_locations`: Lưu trữ 37 điểm địa lý với `DECIMAL(10,8)` cho vĩ độ và `DECIMAL(11,8)` cho kinh độ.
     - Bảng `campus_paths`: Lưu trữ đồ thị đường đi gồm `from_node_id`, `to_node_id`, `distance_meters`, `path_type`.
     - Bảng `sos_alerts`: Lưu trạng thái `ENUM('pending', 'resolved', 'dismissed')`.
  2. Thiết lập Index chiến lược:
     - `CREATE INDEX idx_sched_lookup ON student_schedules(student_id, day_of_week);`
     - `CREATE INDEX idx_grades_lookup ON student_grades(student_id);`
     - `CREATE INDEX idx_sos_status ON sos_alerts(status, created_at DESC);`
  3. Xây dựng scripts Seed dữ liệu tự động: `backend/src/database/init_campus_paths.js` để nạp 37 đỉnh và danh sách các đoạn đường khuôn viên.

### B2. Xác Thực & Phân Quyền (Auth & Security Module)
- **Mục tiêu:** Xác thực phiên làm việc an toàn, chống Brute-force và bảo vệ API nhạy cảm.
- **Công việc cụ thể:**
  1. `backend/src/controllers/authController.js`:
     - Hàm `login`: Tìm kiếm sinh viên theo `student_id`, so khớp mật khẩu bằng `bcrypt.compare()`, tạo JWT Token có thời hạn 7 ngày.
     - Hàm `register`: Kiểm tra tồn tại MSSV, băm mật khẩu với salt 10, lưu vào MySQL.
     - Hàm `sendOtp`: Sinh ngẫu nhiên 6 chữ số, lưu vào bảng `registration_otps` với thời gian hết hạn `NOW() + INTERVAL 60 SECOND`, gửi mail bằng `nodemailer`.
     - Hàm `verifyOtp`: Kiểm tra mã OTP còn hiệu lực và đúng MSSV.
  2. `backend/src/middlewares/authMiddleware.js`:
     - Trích xuất `Authorization: Bearer <token>`, giải mã với `process.env.JWT_SECRET`.
     - Gán thông tin người dùng vào `req.user`. Nếu không hợp lệ trả về `401 Unauthorized`.
     - Cho phép bypass qua route công khai (Guest Mode).

### B3. Nghiệp Vụ Sinh Viên Lõi: Lịch Học & Chỉ Dẫn Phòng (Schedule & Room Parser)
- **Mục tiêu:** Gom nhóm lịch học linh hoạt và tự động sinh hướng dẫn đường đi lên phòng học.
- **Công việc cụ thể:**
  1. `backend/src/services/scheduleService.js`:
     - Truy vấn song song lịch học chính quy (`student_schedules`) và lịch bù cá nhân (`custom_schedules`).
     - Gom nhóm theo thứ trong tuần: `Thứ 2`, `Thứ 3`, ..., `Chủ nhật`.
     - Sắp xếp các tiết học theo thứ tự thời gian bắt đầu `startTime`.
  2. Xây dựng thuật toán bóc tách phòng học (`Room Parser Engine`):
     - Phân tích cú pháp chuỗi phòng (ví dụ: `A1.203`, `B2.105`, `Hội trường A`):
       - Trích xuất: Tòa nhà = `A`, Tầng = `2`, Số phòng = `203`.
       - Sinh tự động danh sách các bước chỉ đường (`guide_steps`):
         1. *Đến cửa chính Tòa nhà A*.
         2. *Di chuyển bằng cầu thang bộ lên Tầng 2*.
         3. *Rẽ phải, phòng A1.203 nằm ở dãy giữa*.

### B4. Nghiệp Vụ Điểm Số & Tính Toán GPA (Grades Calculation Engine)
- **Mục tiêu:** Cung cấp bảng điểm đa chiều và tính GPA chuẩn mực theo quy chế đào tạo tín chỉ.
- **Công việc cụ thể:**
  1. `backend/src/services/gradeService.js`:
     - Quy đổi điểm hệ 10 sang điểm chữ và thang điểm 4:
       - 8.5 – 10.0 $\to$ Điểm A (Hệ 4: 4.0)
       - 7.0 – 8.4 $\to$ Điểm B (Hệ 4: 3.0)
       - 5.5 – 6.9 $\to$ Điểm C (Hệ 4: 2.0)
       - 4.0 – 5.4 $\to$ Điểm D (Hệ 4: 1.0)
       - < 4.0 $\to$ Điểm F (Hệ 4: 0.0)
     - Công thức tính GPA: $\text{GPA} = \frac{\sum (\text{Điểm Hệ 4} \times \text{Số Tín Chỉ})}{\sum \text{Số Tín Chỉ}}$.
     - Trả về điểm trung bình toàn khóa, điểm trung bình từng học kỳ và tổng số tín chỉ tích lũy đạt.

### B5. Không Gian Số & Đồ Thị Định Tuyến Khuôn Viên (Campus GIS Module)
- **Mục tiêu:** Quản lý tọa độ 37 địa danh và cung cấp mạng lưới cạnh đồ thị cho thuật toán tìm đường.
- **Công việc cụ thể:**
  1. `backend/src/controllers/campusController.js`:
     - `getMapLocations`: Trả về danh sách POI kèm phân loại (`academic`, `service`, `parking`, `dormitory`, `canteen`).
     - `getCampusPaths`: Trả về danh sách các đoạn đường nội bộ và khoảng cách vật lý (mét).
     - Hỗ trợ lưu trữ bộ nhớ đệm (In-memory cache) cho dữ liệu bản đồ để giảm tải tối đa cho MySQL.

### B6. Báo Động Khẩn Cấp Real-time & Góp Ý Sinh Viên (SOS & Feedback)
- **Mục tiêu:** Tiếp nhận phản ánh cơ sở vật chất và xử lý ứng cứu khẩn cấp.
- **Công việc cụ thể:**
  1. `submitSos`:
     - Nhận tọa độ GPS (`latitude`, `longitude`), `mssv`, và ghi chú từ client.
     - Ghi nhận vào bảng `sos_alerts` với trạng thái `pending`.
     - Kích hoạt sự kiện Socket.IO: `req.app.get('io').emit('sos_alert', alertData)`.
  2. `submitFeedback`:
     - Tiếp nhận tiêu đề, nội dung, danh mục phản ánh và lưu vào bảng `feedback`.

### B7. Dịch Vụ Cào Dữ Liệu Tự Động (Cronjob & Scraper Service)
- **Mục tiêu:** Tự động giữ cho dữ liệu lịch học và tin tức luôn mới nhất.
- **Công việc cụ thể:**
  1. `backend/src/services/cronService.js`:
     - Dùng `node-cron` thiết lập lịch chạy tự động:
       - Cào tin tức nhà trường mỗi 2 giờ qua Cheerio (`newsService.js`).
       - Đồng bộ lịch học toàn trường vào lúc 02:00 sáng mỗi ngày.
     - Cung cấp API thủ công `POST /api/cron/sync` có kiểm tra secret token cho quản trị viên kích hoạt ngay lập tức.

### B8. Tối Ưu Hiệu Năng & Bảo Mật Máy Chủ (Hardening Tier)
- **Mục tiêu:** Chịu tải đồng thời từ 1,000 – 10,000 sinh viên truy cập mùa thi.
- **Công việc cụ thể:**
  1. Triển khai hàng đợi Micro-batched Non-blocking Activity Logger trong `server.js`:
     - Tích lũy các lượt request vào mảng RAM `activityLogBatch`.
     - Flush hàng loạt qua cú pháp `INSERT INTO activity_logs (action, mssv, ip_address) VALUES ?` mỗi 25 lượt hoặc sau 1.5 giây.
  2. Bổ sung các Header bảo mật chuẩn OWASP: `X-Content-Type-Options`, `X-Frame-Options`, `X-XSS-Protection`.
  3. Hoàn thiện tài liệu Swagger UI tự động tại `/api-docs` qua `swagger-ui-express`.

---

## 4. KẾ HOẠCH LẬP TRÌNH CHI TIẾT PHẦN FRONTEND (FLUTTER)

### F1. Tầng Nền Tảng & Quản Lý Trạng Thái (Foundation & State Layer)
- **Mục tiêu:** Cấu trúc ứng dụng rõ ràng theo mô hình Feature-first, đồng bộ trạng thái mượt mà bằng Riverpod.
- **Công việc cụ thể:**
  1. `frontend/lib/core/network/api_client.dart`:
     - Khởi tạo Dio Client với cấu hình timeouts (connect: 20s, receive: 20s).
     - Thiết lập Interceptors: Tự động gắn Bearer Token và header `x-mssv`. Bắt lỗi 401 để kích hoạt logout tự động.
     - `ServerUrlNotifier`: Lưu và đọc URL máy chủ linh hoạt từ `SharedPreferences`, cho phép đổi IP backend mà không cần build lại app.
  2. `frontend/lib/app/router.dart`:
     - Cấu hình GoRouter với `ShellRoute` cho Bottom Navigation Bar 4 tab:
       - `/home` (Trang chủ)
       - `/schedule` (Thời khóa biểu)
       - `/map` (Bản đồ số)
       - `/profile` (Cá nhân)
     - Cấu hình các route phụ: `/login`, `/register`, `/otp-verify`, `/grades`, `/news-detail`, `/sos`.
  3. `frontend/lib/core/theme/`:
     - Chuẩn hóa Token màu sắc theo `AppColors` (Primary `#0052CC`, Background `#F4F5F7`, Surface `#FFFFFF`, Error/SOS `#DE350B`).

### F2. Phân Hệ Xác Thực & Định Danh (Authentication Feature)
- **Mục tiêu:** Quy trình đăng nhập nhanh chóng, hỗ trợ sinh viên chưa kịp tạo tài khoản vẫn dùng được các tiện ích công cộng.
- **Công việc cụ thể:**
  1. `frontend/lib/features/auth/screens/login_screen.dart`:
     - Form nhập MSSV và Mật khẩu với validation đầy đủ.
     - Nút "Trải nghiệm Khách": Cho phép lưu cờ `isGuest = true` và chuyển thẳng vào ứng dụng.
     - Nút "Cài đặt Máy chủ" (ServerConfigDialog) phục vụ đổi IP dễ dàng khi demo qua Wi-Fi cục bộ.
  2. `frontend/lib/features/auth/screens/register_screen.dart` & `otp_verify_screen.dart`:
     - Đăng ký tài khoản với email `@sv.ttn.edu.vn`.
     - Màn hình nhập 6 ô OTP tự động nhảy focus, đếm ngược thời gian chờ 60s để gửi lại.

### F3. Phân Hệ Trang Chủ Thông Minh (Home Dashboard Feature)
- **Mục tiêu:** Cung cấp mọi thông tin thiết yếu trong nháy mắt, loại bỏ tình trạng giật giao diện (Zero Layout Shift).
- **Công việc cụ thể:**
  1. Thẻ "Tiết học Kế tiếp" (`home_next_class_card.dart`):
     - Tự động quét danh sách môn học của ngày hôm nay.
     - Lập trình bộ đếm thời gian thực: Hiển thị trạng thái "Đang diễn ra", "Bắt đầu sau ... phút", hoặc "Đã hết ca học hôm nay".
     - Nút bấm "Chỉ đường đến phòng": Trích xuất mã tòa nhà và kích hoạt điều hướng sang tab Bản đồ kèm tham số tòa nhà đích.
  2. Thẻ "Kết quả Học tập Nhanh" (`home_gpa_card.dart`):
     - Hiển thị GPA hệ 10 và hệ 4, thanh tiến trình tín chỉ tích lũy.
  3. Bảng Tin tức & Tiện ích Tác vụ (`news_screen.dart`):
     - Hiển thị tin tức nhà trường dạng thẻ hình ảnh vuốt ngang, các nút thao tác nhanh (Gửi góp ý, Tra cứu phòng trống).

### F4. Phân Hệ Thời Khóa Biểu Thông Minh (Smart Schedule Feature)
- **Mục tiêu:** Xem lịch học tiện lợi, đồng bộ nhanh và chủ động thêm các ca học cá nhân.
- **Công việc cụ thể:**
  1. Giao diện Thời khóa biểu (`schedule_screen.dart`):
     - Thanh cuộn ngang chọn các ngày trong tuần (Thứ 2 đến Chủ nhật) với badge đếm số tiết học trong ngày.
     - Kéo xuống để đồng bộ lại lịch học (Pull-to-Refresh) từ backend.
     - Thẻ ca học hiển thị trực quan: Giờ học, tên môn, giảng viên, phòng học có màu sắc nhận diện.
  2. Hộp thoại Thêm Lịch học Bù / Thực hành (`schedule_add_custom_modal.dart`):
     - Modal tiện ích cho phép sinh viên chọn thứ, nhập tên môn học, chọn phòng và chọn tiết học (1-3, 4-6, 7-9, 10-12) bằng danh sách chip tiện dụng.
  3. Hộp thoại Hướng dẫn Lên Phòng Học (`schedule_room_direction_modal.dart`):
     - Tích hợp `room_parser.dart`: Phân rã mã phòng thành tòa nhà, tầng lầu, và các bước hướng dẫn cụ thể kèm hình ảnh minh họa vị trí cầu thang/hành lang.

### F5. Phân Hệ Bản Đồ Số & Dẫn Đường Nội Bộ (Campus Map & Navigation Feature)
- **Mục tiêu:** Tìm đường đi bộ tối ưu trong trường bằng thuật toán Dijkstra chạy tức thời ngay trên máy người dùng, tích hợp la bàn định hướng.
- **Công việc cụ thể:**
  1. Tích hợp Flutter Map (`campus_map_screen.dart`):
     - Cấu hình bản đồ ngoại tuyến / trực tuyến sử dụng tile OpenStreetMap của khuôn viên Đại học Tây Nguyên.
     - Render 37 POI với các icon đánh dấu tòa nhà, thư viện, bãi giữ xe, ký túc xá.
  2. Thuật toán Tìm đường Dijkstra & Haversine Client-side:
     - `core/utils/haversine.dart`: Tính khoảng cách trắc địa chính xác giữa 2 điểm GPS trên mặt cầu Trái Đất.
     - `core/utils/dijkstra.dart`: Duyệt đồ thị danh sách kề lưu sẵn trong app để tìm đường đi ngắn nhất giữa điểm xuất phát và đích đến trong thời gian < 5ms.
     - Tự động gắn (snap) tọa độ GPS thực tế của người dùng vào nút giao đường đi bộ gần nhất.
     - Vẽ đường Polyline dạ quang trên bản đồ hướng dẫn di chuyển.
  3. Cảm Biến La Bàn & Làm Mịn Hướng Nhìn (Compass Smoothing):
     - Lắng nghe cảm biến la bàn (`flutter_compass`) và GPS (`geolocator`).
     - Hiển thị con trỏ tam giác xoay theo hướng mặt người dùng.
     - Thuật toán chống rung lắc (Bearing filter): Chỉ cập nhật góc xoay khi độ lệch $\ge 8^\circ$ và tần suất tối thiểu 450ms, giúp tiết kiệm pin tối đa.
  4. Thanh Trạng Thái Dẫn Đường (`map_navigation_bar.dart`):
     - Tự động ẩn thanh Bottom Tabs khi bắt đầu dẫn đường.
     - Hiển thị khoảng cách còn lại (mét), thời gian đi bộ (phút), nút chọn đổi cổng vào trường (Cổng chính Lê Duẩn, Cổng phụ).

### F6. Phân Hệ Kết Quả Học Tập (Grades Feature)
- **Mục tiêu:** Tra cứu bảng điểm chi tiết, minh bạch từng cột điểm thành phần.
- **Công việc cụ thể:**
  1. Màn hình Bảng điểm (`grades_screen.dart`):
     - Bộ lọc học kỳ linh hoạt (Học kỳ 1, 2, Học kỳ Hè, Tất cả).
     - Danh sách môn học kèm điểm quá trình, chuyên cần, thực hành, thi lần 1, thi lần 2 và điểm chữ.
  2. Màn hình Phân tích Điểm môn học (`grades_detail_screen.dart`):
     - Chi tiết cách tính điểm học phần và điều kiện đạt/rớt môn.

### F7. Phân Hệ Cá Nhân & Tiện Ích Trợ Giúp (Profile & Utilities Feature)
- **Mục tiêu:** Quản lý thông tin tài khoản và an toàn sinh viên.
- **Công việc cụ thể:**
  1. Quản lý Hồ sơ (`profile_screen.dart`):
     - Cập nhật số điện thoại, email liên hệ.
     - Đổi ảnh đại diện (chụp ảnh qua camera, chọn từ bộ sưu tập ảnh máy hoặc nhập URL ảnh).
     - Đổi mật khẩu tài khoản và đăng xuất an toàn khỏi thiết bị.
  2. Màn hình Khẩn cấp SOS (`sos_screen.dart`):
     - Nút bấm lớn giữ 2 giây để gửi tín hiệu SOS khẩn cấp kèm tọa độ GPS trực tiếp đến ban an ninh trường.
     - Danh bạ khẩn cấp: Bấm để gọi ngay Trạm Y tế trường hoặc Đội Bảo vệ qua `url_launcher`.
  3. Màn hình Góp ý Phản hồi (`feedback_screen.dart`):
     - Gửi biểu mẫu đóng góp ý kiến về cơ sở vật chất, thái độ phục vụ hoặc phòng học hư hỏng.

### F8. Tiện Ích Nền & Widget Màn Hình Khóa (Background & Integration)
- **Mục tiêu:** Nhắc lịch học thông minh không cần mở ứng dụng.
- **Công việc cụ thể:**
  1. Thông báo cục bộ (`notification_service.dart`):
     - Tích hợp `flutter_local_notifications` kết hợp thư viện `timezone`.
     - Tự động quét lịch học hàng ngày và đặt lịch báo thức nhắc nhở trước 15 phút và 30 phút trước khi tiết học bắt đầu.
  2. Widget Ngoài Màn hình Chính (`home_widget_service.dart`):
     - Sử dụng `home_widget` để đồng bộ thông tin môn học kế tiếp ra màn hình khóa và màn hình chính của hệ điều hành Android/iOS.

---

## 5. LỘ TRÌNH TRIỂN KHAI THEO SPRINT & TIÊU CHÍ NGHIỆM THU (DOD)

```
[Sprint 1: Base & Auth] ──> [Sprint 2: Student Core] ──> [Sprint 3: GIS & Map] ──> [Sprint 4: Realtime & Admin] ──> [Sprint 5: Testing & Release]
```

### 🗓️ SPRINT 1: NỀN TẢNG, CƠ SỞ DỮ LIỆU & XÁC THỰC (Tuần 1)
- **Công việc Backend:**
  - [ ] Khởi chạy MySQL, import file `schema_full.sql`.
  - [ ] Hoàn thiện kết nối DB Pool trong `backend/src/config/db.js`.
  - [ ] Viết API `/api/auth/login`, `/api/auth/register`, `/api/auth/send-otp`, `/api/auth/verify-otp`.
  - [ ] Viết `authMiddleware.js` bảo vệ endpoint với Bearer Token.
- **Công việc Frontend:**
  - [ ] Khởi tạo Dio Client trong `api_client.dart` với xử lý token tự động.
  - [ ] Dựng luồng màn hình Auth: `login_screen.dart`, `register_screen.dart`, `otp_verify_screen.dart`.
  - [ ] Hỗ trợ chế độ Đăng nhập Khách (Guest Mode) lưu vào Secure Storage.
- **Tiêu chí nghiệm thu (DoD):**
  - Đăng nhập thành công trả về JWT. Đăng nhập sai trả về lỗi rõ ràng.
  - Sinh viên dùng thử được các tính năng cơ bản bằng nút Khách mà không bị chặn.

---

### 🗓️ SPRINT 2: NGHIỆP VỤ SINH VIÊN (LỊCH HỌC, ĐIỂM & GPA) (Tuần 2)
- **Công việc Backend:**
  - [ ] Viết API `/api/student/schedule` (kết hợp lịch chính quy và lịch bù).
  - [ ] Viết API `/api/student/schedule/custom` (CRUD lịch học cá nhân).
  - [ ] Viết hàm bóc tách tên phòng (`Room Parser Engine`).
  - [ ] Viết API `/api/student/grades` tự động tính GPA hệ 10 và hệ 4.
- **Công việc Frontend:**
  - [ ] Xây dựng màn hình `schedule_screen.dart` chọn thứ trong tuần.
  - [ ] Dựng Modal thêm ca học bù `schedule_add_custom_modal.dart`.
  - [ ] Dựng Thẻ Tiết học Kế tiếp trên `home_screen.dart` với đồng hồ đếm ngược thời gian thực.
  - [ ] Xây dựng màn hình tra cứu điểm `grades_screen.dart`.
- **Tiêu chí nghiệm thu (DoD):**
  - Đồng hồ đếm ngược trên Trang chủ nhảy đúng từng giây đến giờ vào lớp.
  - Thêm một ca học bù thành công và hiển thị ngay trên danh sách thời khóa biểu.
  - GPA hệ 10 và hệ 4 tính toán chính xác 100% theo số tín chỉ.

---

### 🗓️ SPRINT 3: BẢN ĐỒ SỐ & TÌM ĐƯỜNG ĐI BỘ DIJKSTRA (Tuần 3)
- **Công việc Backend:**
  - [ ] Nạp dữ liệu 37 địa danh vào bảng `map_locations`.
  - [ ] Nạp mạng lưới đỉnh và đoạn đường vào bảng `campus_paths`.
  - [ ] Cung cấp API `/api/campus/locations` và `/api/campus/paths`.
- **Công việc Frontend:**
  - [ ] Tích hợp Flutter Map hiển thị bản đồ khuôn viên với các marker địa điểm.
  - [ ] Lập trình thuật toán Dijkstra trên mảng đỉnh đồ thị local (`dijkstra.dart`).
  - [ ] Lập trình bắt cảm biến la bàn (`flutter_compass`) và làm mịn góc xoay con trỏ.
  - [ ] Nối nút "Chỉ đường đến phòng" từ Thời khóa biểu sang Bản đồ để tự động vẽ tuyến đường đi bộ.
- **Tiêu chí nghiệm thu (DoD):**
  - Thuật toán Dijkstra tìm được đường đi ngắn nhất giữa 2 điểm bất kỳ trong trường trong thời gian < 10ms.
  - Polyline hiển thị rõ nét trên bản đồ, xoay bản đồ theo hướng nhìn mượt mà, không giật lắc.

---

### 🗓️ SPRINT 4: TIỆN ÍCH SOS REAL-TIME, CỔNG ADMIN & CRONJOB (Tuần 4)
- **Công việc Backend:**
  - [ ] Tích hợp Socket.IO server trong `server.js`.
  - [ ] Viết API tiếp nhận SOS `/api/campus/sos` và bắn socket tới Admin.
  - [ ] Cài đặt `node-cron` tự động cào tin tức và đồng bộ lịch học.
  - [ ] Hoàn thiện các API phục vụ Admin (`/api/admin/*`).
- **Công việc Frontend:**
  - [ ] Hoàn thiện màn hình phát tín hiệu `sos_screen.dart`.
  - [ ] Tích hợp `flutter_local_notifications` nhắc lịch học trước giờ vào lớp.
  - [ ] Cấu hình `home_widget` hiển thị môn học kế tiếp ra màn hình khóa.
- **Công việc Admin:**
  - [ ] Kiểm thử trang giám sát SOS trên Web Admin (`admin/sos.js`): Nhận cảnh báo tức thì, phát âm thanh báo động và hiển thị vị trí sinh viên lên bản đồ Leaflet.
- **Tiêu chí nghiệm thu (DoD):**
  - Nhấn nút SOS trên điện thoại $\to$ Cổng Admin web nhận được tọa độ và phát chuông cảnh báo trong vòng < 500ms.

---

### 🗓️ SPRINT 5: TỐI ƯU HIỆU NĂNG, KIỂM THỬ TỔNG THỂ & ĐÓNG GÓI (Tuần 5)
- **Công việc Chung:**
  - [ ] Kích hoạt cơ chế Micro-batched Logger cho `activity_logs` trên Backend.
  - [ ] Kiểm tra rò rỉ bộ nhớ (Memory Leak) với Flutter DevTools; đảm bảo widget đạt chuẩn 60 FPS.
  - [ ] Cập nhật toàn bộ tài liệu Swagger API tại `/api-docs`.
  - [ ] Đóng gói ứng dụng di động: Tạo file APK Release / App Bundle và file chạy khởi động 1 chạm `start_all.bat`.
- **Tiêu chí nghiệm thu (DoD):**
  - Không có lỗi crash ứng dụng.
  - API Backend phản hồi trung bình < 100ms trên mạng LAN nội bộ.
  - Ứng dụng hoạt động trơn tru trên cả hệ điều hành Android và iOS.

---

## 6. MẪU PROMPT TÁI SỬ DỤNG CHO LẬP TRÌNH VIÊN & AI ASSISTANT

Để tăng tốc độ lập trình khi sử dụng trợ lý AI (như Antigravity/Cursor/Copilot), bạn có thể sao chép trực tiếp các mẫu prompt ngữ cảnh dưới đây:

### 🎯 Mẫu Prompt 1: Viết hoặc tối ưu API Backend
```markdown
Ngữ cảnh: Dự án Smart Campus (Node.js Express + MySQL).
Hãy viết controller và service cho chức năng [Tên chức năng, ví dụ: Thêm lịch học bù cá nhân].
Yêu cầu kỹ thuật:
1. Sử dụng kết nối mysql2/promise từ `src/config/db.js`.
2. Trả về đúng định dạng chuẩn: { success: true, data: ..., message: ... }.
3. Bắt lỗi try/catch đầy đủ và trả mã lỗi HTTP phù hợp (400, 401, 500).
4. Viết kèm Swagger JSDoc annotation chuẩn xác cho endpoint này.
```

### 🎯 Mẫu Prompt 2: Viết hoặc cải tiến Màn hình / Widget Flutter
```markdown
Ngữ cảnh: Dự án Smart Campus Mobile App (Flutter 3.x, Flutter Riverpod, GoRouter).
Hãy viết màn hình/widget [Tên Widget, ví dụ: Thẻ đếm ngược môn học kế tiếp HomeNextClassCard].
Yêu cầu kỹ thuật:
1. Sử dụng StateNotifierProvider hoặc AsyncNotifier từ `flutter_riverpod`.
2. Sử dụng đúng bộ màu hệ thống trong `core/constants/app_colors.dart`.
3. Đảm bảo giao diện hiện đại Material 3 (bo góc thẻ Card 20-24, nút bấm dạng viên thuốc).
4. Xử lý đầy đủ 3 trạng thái: Loading (Shimmer), Error (thông báo có nút tải lại), và Data.
```

### 🎯 Mẫu Prompt 3: Kiểm tra và gỡ lỗi Luồng Dẫn đường Dijkstra
```markdown
Ngữ cảnh: Thuật toán tìm đường đi bộ trong khuôn viên Đại học Tây Nguyên.
Kiểm tra file `frontend/lib/core/utils/dijkstra.dart` và `frontend/lib/features/map/screens/campus_map_screen.dart`.
Yêu cầu:
1. Đảm bảo thuật toán ánh xạ đúng tọa độ thực tế (Haversine min distance) vào đỉnh gần nhất.
2. Kiểm tra không để xảy ra vòng lặp vô tận khi không tìm thấy đường đi.
3. Tối ưu hóa việc vẽ Polyline trên Flutter Map để duy trì tốc độ khung hình 60 FPS.
```

---
*Tài liệu được lưu trữ trực tiếp tại:* `e:\Smart_Campus\KE_HOACH_PHAT_TRIEN_FRONTEND_BACKEND.md`  
*Có thể chỉnh sửa hoặc mở rộng bất cứ lúc nào trong suốt chu kỳ phát triển của dự án.*

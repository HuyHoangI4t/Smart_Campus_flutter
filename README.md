# 🎓 SMART CAMPUS - ĐẠI HỌC TÂY NGUYÊN (TTN)
> Hệ sinh thái số toàn diện hỗ trợ sinh viên, giảng viên và ban quản trị trường Đại học Tây Nguyên.

---

## 📌 1. Giới thiệu tổng quan

Hệ thống **Smart Campus** gồm 3 phân hệ chính được tích hợp liền mạch:
1. **Frontend Mobile App (`/frontend`)**: Ứng dụng di động xây dựng bằng Flutter (Android, iOS, Web).
2. **Backend API Server (`/backend`)**: Máy chủ RESTful API & Realtime Socket.IO xây dựng bằng Node.js + Express + MySQL 8.0.
3. **Web Admin Portal (`/admin`)**: Cổng điều hành và giám sát dành cho Ban Quản trị nhà trường (Express + Vanilla JS Single Page Application).

---

## 🏗️ 2. Kiến trúc hệ thống

```text
┌────────────────────────────────────────────────────────────────────────┐
│                        SMART CAMPUS ECOSYSTEM                          │
├──────────────────┬───────────────────────┬─────────────────────────────┤
│   Mobile App     │      Web Admin        │      Backend Server         │
│   (Flutter)      │      (HTML/JS)        │      (Node.js/Express)      │
│   Port: Mobile   │      Port: 5001       │      Port: 5000             │
│                  │                       │                             │
│ • Riverpod State │ • Thống kê tương tác  │ • RESTful API & Swagger     │
│ • GoRouter Nav   │ • Quản lý người dùng  │ • Socket.IO Engine          │
│ • Dijkstra Nav   │ • Bản đồ 37 địa điểm  │ • Tự động khởi tạo 12 bảng  │
│ • Dio HTTP       │ • Cảnh báo khẩn cấp   │ • Rate Limit & SSRF Guard   │
└────────┬─────────┴───────────┬───────────┴──────────────┬──────────────┘
         │                     │                          │
         └─────────────────────┼──────────────────────────┘
                               │
                      ┌────────▼────────┐
                      │    MySQL 8.0    │
                      │ 12 Tables, UTF8 │
                      └─────────────────┘
```

---

## 📁 3. Cấu trúc thư mục dự án

```text
Smart_Campus/
├── backend/                   # Máy chủ Backend API (Node.js/Express)
│   ├── src/
│   │   ├── config/            # Kết nối MySQL, Swagger OpenAPI
│   │   ├── controllers/       # Điều khiển logic nghiệp vụ
│   │   ├── database/          # DDL Schemas, Seeders ban đầu
│   │   ├── middlewares/       # Xác thực Token, Phân quyền RBAC
│   │   ├── models/            # Mô hình dữ liệu người dùng
│   │   ├── routes/            # Khai báo đường dẫn API chuẩn hóa
│   │   ├── services/          # Xử lý điểm, TKB, cào tin RSS, Cron
│   │   ├── utils/             # Request helpers, SSRF protection
│   │   └── server.js          # Điểm khởi chạy máy chủ Express
│   ├── tests/                 # Bộ kiểm thử Unit Test Backend
│   └── package.json
│
├── frontend/                  # Ứng dụng di động Flutter
│   ├── lib/
│   │   ├── app/               # Định tuyến GoRouter, Shell Navigation
│   │   ├── core/              # Theme, mạng (Dio), lưu trữ an toàn
│   │   └── features/          # Phân hệ theo Feature-Driven Architecture
│   │       ├── auth/          # Đăng nhập, đăng ký, khôi phục OTP
│   │       ├── home/          # Trang chủ, tin tức RSS từ trường
│   │       ├── schedule/      # Thời khóa biểu, lịch học bù tự tạo
│   │       ├── map/           # Bản đồ số 37 địa điểm, dẫn đường Dijkstra
---

## 🚀 4. Hướng dẫn cài đặt & Khởi chạy

### Bước 1: Khởi động Cơ sở dữ liệu MySQL
1. Khởi chạy MySQL Server (thông qua XAMPP, Laragon, Docker hoặc dịch vụ MySQL độc lập).
2. Mặc định hệ thống tự động tạo Database `flutter_campus` ngay khi Backend khởi động.

### Bước 2: Khởi động Backend Server (`:5000`)
```bash
cd backend
npm install
npm run dev
```
* **REST API:** `http://localhost:5000/api`
* **Swagger UI:** `http://localhost:5000/api-docs`
* Tự động khởi tạo schema 12 bảng và nạp sẵn 37 địa điểm khuôn viên.

### Bước 3: Khởi động Admin Portal (`:5001`)
```bash
cd admin
npm install
npm run dev
```
* **Truy cập:** `http://localhost:5001`
* **Tài khoản quản trị mặc định:**
  - MSSV: `admin`
  - Mật khẩu: `123456`

### Bước 4: Khởi chạy Ứng dụng di động Flutter
```bash
cd frontend
flutter pub get
flutter run
```
* Hỗ trợ thiết bị Android, iOS, Chrome (Web) và Windows Desktop.

---

## 🧪 5. Kiểm thử hệ thống (Automated Testing)

Hệ thống duy trì toàn vẹn bộ kiểm thử tự động cho cả Backend và Frontend:

### 5.1 Kiểm thử Backend API (Node.js)
```bash
cd backend
npm test
```
* **13 kịch bản kiểm thử (100% Passed):**
  - Trích xuất định danh MSSV từ Token, Headers, Query, Body, Params, Fallback
  - Nhận diện phân loại tài khoản Khách (Guest) và Sinh viên
  - Kiểm định cơ chế chống SSRF đối với ảnh và tài liệu cào từ website trường
  - Chuẩn hóa đường dẫn tương đối thành tuyệt đối hợp lệ

### 5.2 Kiểm thử Frontend Mobile (Flutter)
```bash
cd frontend
flutter test
```
* **9 kịch bản kiểm thử (100% Passed):**
  - Dẫn đường thuật toán Dijkstra trên đồ thị khuôn viên trường
  - Bộ lọc làm mượt cảm biến la bàn định hướng (Compass Smoother)
  - Serialization & Deserialization dữ liệu lịch học tùy chỉnh
  - Chuyển đổi tab điều hướng Stateful Shell qua GoRouter
  - Khởi chạy Smoke Test ứng dụng chính

---

## 🔐 6. Các tính năng bảo mật nổi bật

- **Xác thực chữ ký số:** Token đăng nhập sử dụng cơ chế băm HMAC-SHA256, bắt buộc có chữ ký hợp lệ để ngăn ngừa giả mạo.
- **Chống SSRF:** API proxy tải ảnh và tệp đính kèm được bảo vệ nghiêm ngặt bằng danh sách Whitelist domain trường (`*.ttn.edu.vn`).
- **Rate Limiting:** Tự động giới hạn tần suất yêu cầu trên từng địa chỉ IP để chống brute-force và DDoS mức ứng dụng.
- **Phân quyền RBAC:** Toàn bộ API Quản trị viên (`/api/admin/*`) yêu cầu Bearer Token và quyền `admin`.
- **An toàn trình duyệt:** Tích hợp tiêu chuẩn OWASP Headers (`HSTS`, `X-Content-Type-Options`, `X-Frame-Options`, `Permissions-Policy`).

│   │       ├── grades/        # Kết quả học tập, GPA thang 10 & 4
│   │       ├── profile/       # Thông tin cá nhân, đổi mật khẩu
│   │       ├── feedback/      # Đóng góp ý kiến cơ sở vật chất
│   │       └── sos/           # Phát tín hiệu cấp cứu khẩn cấp
│   ├── test/                  # Bộ kiểm thử Unit & Widget Test Flutter
│   └── pubspec.yaml
│
├── admin/                     # Cổng thông tin Quản trị viên
│   ├── public/                # Giao diện Web tĩnh (CSS, JS, Assets)
│   ├── server.js              # Máy chủ Express phục vụ cổng 5001
│   └── package.json
│
└── README.md                  # Tài liệu tổng quan dự án
```

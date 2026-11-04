@echo off
chcp 65001 >nul
title 🎓 Smart Campus TTN - Trình khởi động toàn hệ thống

echo ===================================================================
echo   🎓 SMART CAMPUS ĐẠI HỌC TÂY NGUYÊN (TTN) - KHỞI ĐỘNG HỆ THỐNG
echo ===================================================================
echo.

:: 1. Khởi động Backend API Server (:5000)
echo [1/2] Đang khởi chạy Backend API Server trên cổng 5000...
start "Smart Campus - Backend (:5000)" cmd /k "cd /d %~dp0backend && npm run dev"

:: Đợi 3 giây để Backend sẵn sàng
timeout /t 3 /nobreak >nul

:: 2. Khởi động Web Admin Portal (:5001)
echo [2/2] Đang khởi chạy Admin Portal trên cổng 5001...
start "Smart Campus - Admin Portal (:5001)" cmd /k "cd /d %~dp0admin && npm run dev"

:: Đợi 2 giây
timeout /t 2 /nobreak >nul

echo.
echo ===================================================================
echo   ✅ HỆ THỐNG ĐÃ KHỞI CHẠY THÀNH CÔNG!
echo   ---------------------------------------------------------------
echo   🌐 Web Admin Portal : http://localhost:5001
echo   🔗 Backend REST API : http://localhost:5000/api
echo   📄 Swagger API Docs : http://localhost:5000/api-docs
echo   ⚡ Socket.IO Realtime: ws://localhost:5000
echo   📱 Mobile Flutter   : Mở terminal chạy 'cd frontend && flutter run'
echo ===================================================================
echo.

:: Tự động mở trình duyệt truy cập Admin Portal
start http://localhost:5001

pause

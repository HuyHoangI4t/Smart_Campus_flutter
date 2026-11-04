@echo off
chcp 65001 >nul
title 🎓 Smart Campus - Backend Server (:5000)
cd /d %~dp0backend
echo Đang khởi chạy máy chủ Backend tại http://localhost:5000 ...
npm run dev

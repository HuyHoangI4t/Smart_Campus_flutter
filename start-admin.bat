@echo off
chcp 65001 >nul
title 🛡️ Smart Campus - Admin Portal (:5001)
cd /d %~dp0admin
echo Đang khởi chạy Web Admin Portal tại http://localhost:5001 ...
npm run dev

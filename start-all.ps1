# PowerShell Script khởi chạy hệ sinh thái Smart Campus TTN
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

Write-Host "===================================================================" -ForegroundColor Cyan
Write-Host "  🎓 SMART CAMPUS ĐẠI HỌC TÂY NGUYÊN - KHỞI ĐỘNG HỆ THỐNG" -ForegroundColor Yellow
Write-Host "===================================================================" -ForegroundColor Cyan
Write-Host ""

$baseDir = $PSScriptRoot

# 1. Kiểm tra kết nối MySQL
Write-Host "🔍 [1/3] Đang kiểm tra cổng kết nối MySQL (3306)..." -ForegroundColor Gray
$mysqlCheck = Test-NetConnection -ComputerName 127.0.0.1 -Port 3306 -InformationLevel Quiet
if ($mysqlCheck) {
    Write-Host "✅ MySQL Server đang chạy sẵn sàng." -ForegroundColor Green
} else {
    Write-Host "⚠️ Không thấy cổng MySQL 3306. Vui lòng bật XAMPP/Laragon/MySQL Service trước!" -ForegroundColor Yellow
}

# 2. Khởi chạy Backend Server
Write-Host "🚀 [2/3] Đang khởi chạy Backend API Server (:5000)..." -ForegroundColor Cyan
Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd '$baseDir\backend'; npm run dev"

Start-Sleep -Seconds 3

# 3. Khởi chạy Admin Portal
Write-Host "🛡️ [3/3] Đang khởi chạy Web Admin Portal (:5001)..." -ForegroundColor Cyan
Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd '$baseDir\admin'; npm run dev"

Start-Sleep -Seconds 2

# 4. Tự động nhận diện thiết bị cắm dây USB (ADB reverse)
$adbPath = "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe"
if (Test-Path $adbPath) {
    try {
        $adbDevices = & $adbPath devices
        if ($adbDevices -match "device\b") {
            & $adbPath reverse tcp:5000 tcp:5000 | Out-Null
            Write-Host "📱 [USB Cắm Dây] Đã tự động kích hoạt: adb reverse tcp:5000 tcp:5000" -ForegroundColor Green
        }
    } catch {}
}

Write-Host ""
Write-Host "===================================================================" -ForegroundColor Green
Write-Host "  🎉 HỆ SINH THÁI ĐÃ KHỞI CHẠY THÀNH CÔNG!" -ForegroundColor Green
Write-Host "  🌐 Web Admin Portal : http://localhost:5001" -ForegroundColor White
Write-Host "  🔗 Backend REST API : http://localhost:5000/api" -ForegroundColor White
Write-Host "  📄 Swagger API Docs : http://localhost:5000/api-docs" -ForegroundColor White
Write-Host "  📱 Flutter Mobile   : Mở terminal mới chạy: cd frontend; flutter run" -ForegroundColor Yellow
Write-Host "===================================================================" -ForegroundColor Green
Write-Host ""

# Mở trình duyệt Web
Start-Process "http://localhost:5001"

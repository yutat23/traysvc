Write-Host "すべてのアーキテクチャでタスクトレイアプリケーションをビルド中..." -ForegroundColor Green

# amd64ビルド
Write-Host "`n=== amd64アーキテクチャのビルド ===" -ForegroundColor Cyan
$env:GOOS = "windows"
$env:GOARCH = "amd64"

go build -ldflags="-H windowsgui -s -w" -o dist/traysvc-amd64.exe main.go icon.go

if ($LASTEXITCODE -eq 0) {
    Write-Host "amd64ビルド成功: dist/traysvc-amd64.exe" -ForegroundColor Green
    
    Write-Host "amd64用マニフェストファイルを適用中..." -ForegroundColor Yellow
    rsrc -manifest manifest.xml -o rsrc.syso
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "amd64マニフェスト適用成功" -ForegroundColor Green
        go build -ldflags="-H windowsgui -s -w" -o dist/traysvc-amd64.exe main.go icon.go
        Remove-Item rsrc.syso -ErrorAction SilentlyContinue
        Write-Host "amd64最終ビルド完了: dist/traysvc-amd64.exe" -ForegroundColor Green
    } else {
        Write-Host "amd64マニフェスト適用失敗" -ForegroundColor Red
    }
} else {
    Write-Host "amd64ビルド失敗" -ForegroundColor Red
}

# ARM64ビルド
Write-Host "`n=== ARM64アーキテクチャのビルド ===" -ForegroundColor Cyan
$env:GOOS = "windows"
$env:GOARCH = "arm64"

go build -ldflags="-H windowsgui -s -w" -o dist/traysvc-arm64.exe main.go icon.go

if ($LASTEXITCODE -eq 0) {
    Write-Host "ARM64ビルド成功: dist/traysvc-arm64.exe" -ForegroundColor Green
    
    Write-Host "ARM64用マニフェストファイルを適用中..." -ForegroundColor Yellow
    rsrc -manifest manifest.xml -o rsrc.syso
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "ARM64マニフェスト適用成功" -ForegroundColor Green
        go build -ldflags="-H windowsgui -s -w" -o dist/traysvc-arm64.exe main.go icon.go
        Remove-Item rsrc.syso -ErrorAction SilentlyContinue
        Write-Host "ARM64最終ビルド完了: dist/traysvc-arm64.exe" -ForegroundColor Green
    } else {
        Write-Host "ARM64マニフェスト適用失敗" -ForegroundColor Red
    }
} else {
    Write-Host "ARM64ビルド失敗" -ForegroundColor Red
}

# config.jsonをdistフォルダにコピー
Write-Host "`n=== 設定ファイルのコピー ===" -ForegroundColor Cyan
if (Test-Path "config.json") {
    Copy-Item "config.json" "dist/config.json" -Force
    Write-Host "✓ config.jsonをdistフォルダにコピーしました" -ForegroundColor Green
} else {
    Write-Host "✗ config.jsonが見つかりません" -ForegroundColor Red
}

# スタートアップ管理batファイルをdistフォルダにコピー
Write-Host "`n=== スタートアップ管理ファイルのコピー ===" -ForegroundColor Cyan
$batFiles = @("add-to-startup.bat", "remove-from-startup.bat", "check-startup.bat")
foreach ($batFile in $batFiles) {
    if (Test-Path $batFile) {
        Copy-Item $batFile "dist/$batFile" -Force
        Write-Host "✓ $batFileをdistフォルダにコピーしました" -ForegroundColor Green
    } else {
        Write-Host "✗ $batFileが見つかりません" -ForegroundColor Red
    }
}

Write-Host "`n=== ビルド結果 ===" -ForegroundColor Cyan
if (Test-Path "dist/traysvc-amd64.exe") {
    Write-Host "✓ dist/traysvc-amd64.exe (amd64)" -ForegroundColor Green
} else {
    Write-Host "✗ dist/traysvc-amd64.exe (amd64) - ビルド失敗" -ForegroundColor Red
}

if (Test-Path "dist/traysvc-arm64.exe") {
    Write-Host "✓ dist/traysvc-arm64.exe (ARM64)" -ForegroundColor Green
} else {
    Write-Host "✗ dist/traysvc-arm64.exe (ARM64) - ビルド失敗" -ForegroundColor Red
}

Write-Host "`nビルド完了" -ForegroundColor Green
Read-Host "Enterキーを押して終了" 
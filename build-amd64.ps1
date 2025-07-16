Write-Host "AMD64アーキテクチャでタスクトレイアプリケーションをビルド中..." -ForegroundColor Green

# 環境変数を設定してAMD64でビルド
$env:GOOS = "windows"
$env:GOARCH = "amd64"

go build -ldflags="-H windowsgui -s -w" -o dist/traysvc-amd64.exe main.go icon.go

if ($LASTEXITCODE -eq 0) {
    Write-Host "AMD64ビルド成功: dist/traysvc-amd64.exe" -ForegroundColor Green
    
    Write-Host "マニフェストファイルを適用中..." -ForegroundColor Yellow
    rsrc -manifest manifest.xml -o rsrc.syso
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "マニフェスト適用成功" -ForegroundColor Green
        go build -ldflags="-H windowsgui -s -w" -o dist/traysvc-amd64.exe main.go icon.go
        Remove-Item rsrc.syso -ErrorAction SilentlyContinue
        Write-Host "AMD64最終ビルド完了: dist/traysvc-amd64.exe" -ForegroundColor Green
        
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
    } else {
        Write-Host "マニフェスト適用失敗" -ForegroundColor Red
        Write-Host "rsrcツールがインストールされていない可能性があります" -ForegroundColor Yellow
        Write-Host "インストール方法: go install github.com/akavel/rsrc@latest" -ForegroundColor Yellow
    }
} else {
    Write-Host "AMD64ビルド失敗" -ForegroundColor Red
    Read-Host "Enterキーを押して終了"
} 
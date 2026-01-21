@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

echo ========================================
echo Windowsサービス監視ツール - スタートアップ登録
echo ========================================
echo.

:: 管理者権限チェック
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo 管理者権限が必要です。
    echo このスクリプトを管理者として実行してください。
    echo.
    pause
    exit /b 1
)

:: 現在のディレクトリを取得
set "CURRENT_DIR=%~dp0"

:: 実行ファイルの存在確認（複数の可能性をチェック）
set "EXE_PATH=%CURRENT_DIR%traysvc.exe"
set "EXE_PATH_AMD64=%CURRENT_DIR%traysvc-amd64.exe"
set "EXE_PATH_ARM64=%CURRENT_DIR%traysvc-arm64.exe"

if exist "%EXE_PATH%" (
    set "SELECTED_EXE=%EXE_PATH%"
    set "EXE_NAME=traysvc.exe"
) else if exist "%EXE_PATH_AMD64%" (
    set "SELECTED_EXE=%EXE_PATH_AMD64%"
    set "EXE_NAME=traysvc-amd64.exe"
) else if exist "%EXE_PATH_ARM64%" (
    set "SELECTED_EXE=%EXE_PATH_ARM64%"
    set "EXE_NAME=traysvc-arm64.exe"
) else (
    echo エラー: 実行ファイルが見つかりません。
    echo 現在のディレクトリ: %CURRENT_DIR%
    echo 確認したファイル:
    echo - %EXE_PATH%
    echo - %EXE_PATH_AMD64%
    echo - %EXE_PATH_ARM64%
    echo.
    echo このbatファイルは実行ファイルと同じディレクトリに配置してください。
    echo.
    pause
    exit /b 1
)

:: 設定ファイルの存在確認
set "CONFIG_PATH=%CURRENT_DIR%config.json"
if not exist "%CONFIG_PATH%" (
    echo 警告: config.json が見つかりません。
    echo デフォルト設定でアプリケーションが起動します。
    echo.
)

echo アプリケーション情報:
echo - 実行ファイル: %SELECTED_EXE% (%EXE_NAME%)
echo - 設定ファイル: %CONFIG_PATH%
echo.

:: スタートアップ登録
echo スタートアップに登録しています...

:: レジストリキーに登録
reg add "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Run" /v "TraySvc" /t REG_SZ /d "\"%SELECTED_EXE%\"" /f

if %errorLevel% equ 0 (
    echo ✓ スタートアップ登録が完了しました。
    echo.
    echo 登録内容:
    echo - キー: HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Run
    echo - 値名: TraySvc
    echo - 値: "%SELECTED_EXE%"
    echo.
    echo 次回のWindows起動時に自動的にアプリケーションが起動します。
    echo.
    echo 今すぐアプリケーションを起動しますか？ (Y/N)
    set /p "START_NOW="
    if /i "!START_NOW!"=="Y" (
        echo アプリケーションを起動しています...
        start "" "%SELECTED_EXE%"
    )
) else (
    echo ✗ スタートアップ登録に失敗しました。
    echo エラーコード: %errorLevel%
    echo.
    pause
    exit /b 1
)

echo.
echo スタートアップ登録が正常に完了しました。
echo.
pause 
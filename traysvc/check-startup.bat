@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

echo ========================================
echo Windowsサービス監視ツール - スタートアップ状態確認
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

echo スタートアップ登録状態を確認しています...
echo.

:: レジストリから値を取得
for /f "tokens=3" %%i in ('reg query "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Run" /v "TraySvc" 2^>nul') do set "REG_VALUE=%%i"

if defined REG_VALUE (
    echo ✓ スタートアップに登録されています。
    echo.
    echo 登録情報:
    echo - キー: HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Run
    echo - 値名: TraySvc
    echo - 値: %REG_VALUE%
    echo.
    
    :: 実行ファイルの存在確認
    set "EXE_PATH=%REG_VALUE%"
    set "EXE_PATH=!EXE_PATH:"=!"
    
    if exist "!EXE_PATH!" (
        echo ✓ 実行ファイルが存在します: !EXE_PATH!
    ) else (
        echo ✗ 実行ファイルが見つかりません: !EXE_PATH!
        echo.
        echo 警告: スタートアップに登録されていますが、実行ファイルが存在しません。
        echo 次回のWindows起動時にエラーが発生する可能性があります。
    )
    
    :: 実行中のプロセス確認
    tasklist /FI "IMAGENAME eq traysvc.exe" 2>NUL | find /I /N "traysvc.exe">NUL
    if "%ERRORLEVEL%"=="0" (
        echo ✓ アプリケーションが実行中です (traysvc.exe)
    ) else (
        tasklist /FI "IMAGENAME eq traysvc-amd64.exe" 2>NUL | find /I /N "traysvc-amd64.exe">NUL
        if "%ERRORLEVEL%"=="0" (
            echo ✓ アプリケーションが実行中です (traysvc-amd64.exe)
        ) else (
            tasklist /FI "IMAGENAME eq traysvc-arm64.exe" 2>NUL | find /I /N "traysvc-arm64.exe">NUL
            if "%ERRORLEVEL%"=="0" (
                echo ✓ アプリケーションが実行中です (traysvc-arm64.exe)
            ) else (
                echo - アプリケーションは実行中ではありません。
            )
        )
    )
    
) else (
    echo ✗ スタートアップに登録されていません。
    echo.
    echo 登録するには add-to-startup.bat を実行してください。
)

echo.
echo 現在のディレクトリのファイル確認:
echo.

:: 現在のディレクトリのファイル確認
set "CURRENT_DIR=%~dp0"
set "EXE_PATH=%CURRENT_DIR%traysvc.exe"
set "EXE_PATH_AMD64=%CURRENT_DIR%traysvc-amd64.exe"
set "EXE_PATH_ARM64=%CURRENT_DIR%traysvc-arm64.exe"
set "CONFIG_PATH=%CURRENT_DIR%config.json"

if exist "%EXE_PATH%" (
    echo ✓ traysvc.exe: 存在します
) else (
    echo - traysvc.exe: 見つかりません
)

if exist "%EXE_PATH_AMD64%" (
    echo ✓ traysvc-amd64.exe: 存在します
) else (
    echo - traysvc-amd64.exe: 見つかりません
)

if exist "%EXE_PATH_ARM64%" (
    echo ✓ traysvc-arm64.exe: 存在します
) else (
    echo - traysvc-arm64.exe: 見つかりません
)

if exist "%CONFIG_PATH%" (
    echo ✓ config.json: 存在します
) else (
    echo - config.json: 見つかりません（デフォルト設定で動作）
)

echo.
echo 操作メニュー:
echo 1. スタートアップに登録 (add-to-startup.bat)
echo 2. スタートアップから削除 (remove-from-startup.bat)
echo 3. 今すぐアプリケーションを起動
echo 4. 終了
echo.
set /p "CHOICE=選択してください (1-4): "

if "!CHOICE!"=="1" (
    call add-to-startup.bat
) else if "!CHOICE!"=="2" (
    call remove-from-startup.bat
) else if "!CHOICE!"=="3" (
    if exist "%EXE_PATH%" (
        echo アプリケーションを起動しています...
        start "" "%EXE_PATH%"
    ) else if exist "%EXE_PATH_AMD64%" (
        echo アプリケーションを起動しています...
        start "" "%EXE_PATH_AMD64%"
    ) else if exist "%EXE_PATH_ARM64%" (
        echo アプリケーションを起動しています...
        start "" "%EXE_PATH_ARM64%"
    ) else (
        echo エラー: 実行ファイルが見つかりません。
    )
) else if "!CHOICE!"=="4" (
    echo 終了します。
) else (
    echo 無効な選択です。
)

echo.
pause 
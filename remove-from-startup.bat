@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

echo ========================================
echo Windowsサービス監視ツール - スタートアップ削除
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

echo スタートアップから削除しています...

:: レジストリキーから削除
reg delete "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Run" /v "TraySvc" /f

if %errorLevel% equ 0 (
    echo ✓ スタートアップから削除されました。
    echo.
    echo 削除内容:
    echo - キー: HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Run
    echo - 値名: TraySvc
    echo.
    echo 次回のWindows起動時にアプリケーションは自動起動しません。
    echo.
    
    :: 実行中のプロセスを確認
    tasklist /FI "IMAGENAME eq traysvc.exe" 2>NUL | find /I /N "traysvc.exe">NUL
    if "%ERRORLEVEL%"=="0" (
        echo 実行中のアプリケーションを停止しますか？ (Y/N)
        set /p "STOP_NOW="
        if /i "!STOP_NOW!"=="Y" (
            echo アプリケーションを停止しています...
            taskkill /F /IM traysvc.exe >nul 2>&1
            if %errorLevel% equ 0 (
                echo ✓ アプリケーションが停止されました。
            ) else (
                echo ✗ アプリケーションの停止に失敗しました。
            )
        )
    ) else (
        tasklist /FI "IMAGENAME eq traysvc-amd64.exe" 2>NUL | find /I /N "traysvc-amd64.exe">NUL
        if "%ERRORLEVEL%"=="0" (
            echo 実行中のアプリケーションを停止しますか？ (Y/N)
            set /p "STOP_NOW="
            if /i "!STOP_NOW!"=="Y" (
                echo アプリケーションを停止しています...
                taskkill /F /IM traysvc-amd64.exe >nul 2>&1
                if %errorLevel% equ 0 (
                    echo ✓ アプリケーションが停止されました。
                ) else (
                    echo ✗ アプリケーションの停止に失敗しました。
                )
            )
        ) else (
            tasklist /FI "IMAGENAME eq traysvc-arm64.exe" 2>NUL | find /I /N "traysvc-arm64.exe">NUL
            if "%ERRORLEVEL%"=="0" (
                echo 実行中のアプリケーションを停止しますか？ (Y/N)
                set /p "STOP_NOW="
                if /i "!STOP_NOW!"=="Y" (
                    echo アプリケーションを停止しています...
                    taskkill /F /IM traysvc-arm64.exe >nul 2>&1
                    if %errorLevel% equ 0 (
                        echo ✓ アプリケーションが停止されました。
                    ) else (
                        echo ✗ アプリケーションの停止に失敗しました。
                    )
                )
            )
        )
    )
) else (
    echo ✗ スタートアップからの削除に失敗しました。
    echo エラーコード: %errorLevel%
    echo.
    echo 既に削除されているか、登録されていない可能性があります。
    echo.
    pause
    exit /b 1
)

echo.
echo スタートアップ削除が正常に完了しました。
echo.
pause 